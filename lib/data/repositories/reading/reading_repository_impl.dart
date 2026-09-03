/// Opening a book out of the local replica and the local blob store.
library;

import 'dart:typed_data';

import '../../../domain/models/ebook.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../../utils/streams.dart';
import '../../model/row_mappers.dart';
import '../../services/epub/epub_host.dart';
import '../../services/local/dao/identity_dao.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/database.dart';
import '../../services/local/dao/reading_dao.dart';
import '../../services/sync/author.dart';
import '../../services/sync/delta.dart';
import '../../services/storage/blob_store.dart';
import 'reading_repository.dart';

final _log = loggerFor('data/reading');

/// The operation a failure here reports under.
const String opOpenBook = 'reading: open';

/// How large a book this build will hand to the engine.
///
/// epub.js needs the whole file, so opening one costs its length in memory —
/// twice for a moment on the hosts that hand it over as base64. A limit is
/// therefore not tidiness: a reader who imported a two-gigabyte scanned volume
/// should be told this build will not open it, rather than watching the
/// application be killed by the operating system with nothing said.
///
/// Two hundred megabytes is far above any reflowable EPUB and well below what
/// a phone will refuse.
const int readableSizeLimit = 200 * 1024 * 1024;

/// One book, opened from what this device holds.
final class ReadingRepositoryImpl implements ReadingRepository {
  /// The repository over [library], reading bytes from [blobs] and writing
  /// through [author].
  const ReadingRepositoryImpl({
    required this.library,
    required this.places,
    required this.identity,
    required this.blobs,
    required this.author,
  });

  /// The rows.
  final LibraryDao library;

  /// Which device this one is, which is what marks a reading place as *here*.
  ///
  /// It is injected rather than reached through `library.attachedDatabase`:
  /// one DAO walking back to the database to borrow another is a dependency
  /// that no signature declares and no test can substitute.
  final IdentityDao identity;

  /// Where reading got to, on every device.
  final ReadingDao places;

  /// Where the file is.
  final BlobStore blobs;

  /// Where a change to a replicable record goes. There is no other way out of
  /// this repository, and C21 is why: `UpdateReadingProgress` writes the node's
  /// table and appends nothing to its log, so a position sent that way reaches
  /// the reader's other devices never.
  final OperationAuthor author;

  @override
  Future<Result<EpubBook>> openBook(String ebookId) async {
    try {
      final row = await library.readEbook(ebookId);

      if (row == null || row.deleted) {
        // A work another device deleted while this one was listing it. The
        // tombstone is the answer and there is nothing to open.
        return Result<EpubBook>.error(
          AppException(
            kind: ErrorKind.notFound,
            message: 'this device does not hold the work $ebookId',
            code: codeEbookNotFound,
            op: opOpenBook,
          ),
        );
      }

      final work = ebookOfRow(row);

      if (work.format != EbookFormat.epub) {
        // Not a failure of this device and not something to retry. The other
        // four formats import, list, synchronize and show a percentage, and
        // saying so is the promise the roadmap actually made.
        return Result<EpubBook>.error(
          AppException(
            kind: ErrorKind.unimplemented,
            message: 'this build opens EPUB and not ${work.format ?? 'that'}',
            code: codeFormatNotReadable,
            op: opOpenBook,
          ),
        );
      }

      if (!await blobs.contains(work.contentHash)) {
        // The ordinary state of a book that has not been downloaded, and in a
        // browser the ordinary state of every book the reader has not asked to
        // keep. The screen offers to fetch it.
        return Result<EpubBook>.error(
          AppException(
            kind: ErrorKind.failedPrecondition,
            message: 'the file of $ebookId is not on this device',
            code: codeContentNotOnDevice,
            op: opOpenBook,
          ),
        );
      }

      final int? size = await blobs.sizeOf(work.contentHash);

      if (size != null && size > readableSizeLimit) {
        return Result<EpubBook>.error(
          AppException(
            kind: ErrorKind.resourceExhausted,
            message: 'the file of $ebookId is too large for this build to open',
            code: codeEbookTooLarge,
            op: opOpenBook,
          ),
        );
      }

      final Uint8List bytes = await collectBook(blobs.read(work.contentHash));

      _log.fine('opened $ebookId, ${bytes.length} bytes');

      return Result<EpubBook>.ok(
        EpubBook(ebookId: work.id, bytes: bytes, title: work.title),
      );
    } on Object catch (error) {
      _log.warning('$ebookId could not be opened', error);

      return Result<EpubBook>.error(_failure(error));
    }
  }

  @override
  Future<Result<void>> saveProgress({
    required String ebookId,
    required String locator,
    double? percent,
  }) async {
    try {
      await author.write(
        Change.position(
          ebookId: ebookId,
          delta: <String, Object?>{
            fieldLocator: locator,
            // Claimed even when it is null, which clears a percentage a
            // previous version of this app could compute and this one cannot.
            // A field the delta does not name keeps whatever wrote it last,
            // and a stale percentage beside a fresh locator is worse than none.
            fieldPercent: percent,
          },
        ),
      );

      return const Result<void>.ok(null);
    } on Object catch (error) {
      // A position that could not be written is worth a line and is not worth
      // interrupting a reader over: they are reading, the page is on screen,
      // and the next turn will try again.
      _log.warning('the position in $ebookId could not be written', error);

      return Result<void>.error(_failure(error));
    }
  }

  @override
  Stream<Result<List<ReadingPlace>>> watchContinueReading({int limit = 20}) =>
      places
          .watchPlaces(limit: limit)
          .asyncMap(_placesOf)
          .asResults(opOpenBook);

  @override
  Stream<Result<List<ReadingPlace>>> watchPlacesIn(String ebookId) => places
      .watchPlacesIn(ebookId)
      .asyncMap((List<ProgressRow> rows) async {
        final row = await library.readEbook(ebookId);

        if (row == null) {
          return const <ReadingPlace>[];
        }

        final Ebook work = ebookOfRow(row);
        final String? here = await identity.deviceId();

        return <ReadingPlace>[
          for (final ProgressRow position in rows)
            _placeOf(position, work, here),
        ];
      })
      .asResults(opOpenBook);

  /// The places [rows] describe, with this device's own marked.
  Future<List<ReadingPlace>> _placesOf(List<ReadingPlaceRow> rows) async {
    // Asked once per emission and not once per row: the identity of this
    // device does not change while a list is being built, and twenty queries
    // to learn one answer would be twenty.
    final String? here = await identity.deviceId();

    return <ReadingPlace>[
      for (final ReadingPlaceRow row in rows)
        _placeOf(row.position, ebookOfRow(row.work), here),
    ];
  }

  ReadingPlace _placeOf(ProgressRow position, Ebook work, String? here) =>
      ReadingPlace(
        work: work,
        locator: position.locator,
        percent: position.percent,
        updatedAt: position.updatedAt,
        onThisDevice: here != null && position.deviceId == here,
      );

  @override
  Future<Result<Ebook?>> ebook(String ebookId) async {
    try {
      final row = await library.readEbook(ebookId);

      return Result<Ebook?>.ok(row == null ? null : ebookOfRow(row));
    } on Object catch (error) {
      _log.warning('$ebookId could not be read', error);

      return Result<Ebook?>.error(_failure(error));
    }
  }

  /// [error] as something a screen can show.
  ///
  /// An `AppException` is already that and is passed through, so a code this
  /// repository chose deliberately — the format, the missing file — is not
  /// flattened into an internal error on its way out.
  Exception _failure(Object error) => error is AppException
      ? error
      : AppException(
          kind: ErrorKind.internal,
          message: 'the book could not be opened',
          code: 'open_failed',
          op: opOpenBook,
          cause: error,
        );
}

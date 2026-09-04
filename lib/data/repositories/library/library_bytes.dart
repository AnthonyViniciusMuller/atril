/// The bytes half of [LibraryRepository]: importing a file, fetching one,
/// keeping one and letting one go.
///
/// It is a mixin over the same class rather than a second repository, because
/// what it does is one feature of one interface — a reader importing a book is
/// not doing something to a different thing than a reader renaming it. What it
/// is *not* is the record half, and that is why it is a separate file: the two
/// share the DAO and the author and share nothing else, and one file holding
/// both had grown to a thousand lines in which the transfer of a file sat
/// between two methods about titles.
///
/// Everything here is about a *digest*. A work names one, the store is keyed by
/// it, the queue is keyed by it and the reader's decision to keep a book is
/// recorded against it — so two works imported from one file are one file, one
/// transfer and one decision, everywhere in this file.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart' show StreamGroup;

import '../../../domain/models/ebook.dart';
import '../../../domain/models/operation.dart';
import '../../../utils/cancellation.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../../utils/streams.dart';
import '../../model/row_mappers.dart';
import '../../services/api/errors.dart';
import '../../services/content/content_downloader.dart';
import '../../services/content/upload_queue.dart';
import '../../services/epub/epub_metadata.dart';
import '../../services/files/file_kind.dart';
import '../../services/files/file_source.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/dao/transfers_dao.dart';
import '../../services/local/database.dart';
import '../../services/storage/blob_storage.dart';
import '../../services/sync/author.dart';
import '../../services/sync/delta.dart';
import 'library_repository.dart';

final _log = loggerFor('data/library');

/// The operation an import reports under.
const String opImport = 'library/collection: import';

/// The operation a download reports under.
const String opDownload = 'library/content: download';

/// The operation keeping and releasing report under.
const String opKeep = 'library/content: keep';

/// What a work's file costs this device, and what it takes to get one.
///
/// The members it needs are declared here and provided by the class that mixes
/// it in, which is what keeps the two halves one repository without either of
/// them reaching into the other's fields by name.
mixin LibraryBytes implements LibraryRepository {
  /// The rows.
  LibraryDao get library;

  /// Where a change to a replicable record goes.
  OperationAuthor get author;

  /// Where the bytes go.
  BlobStore get blobs;

  /// What the node is owed, and what eventually pays it.
  UploadQueue get uploads;

  /// What brings a file the other way.
  ContentDownloader get downloads;

  /// What is owed, and what the reader decided to keep.
  TransfersDao get transfers;

  /// What the store holds and may hold, asked of the platform.
  Future<StorageBudget> Function(BlobStore blobs) get budget;

  /// Whether a book arrives kept.
  bool get keepsByDefault;

  /// The identifier a fresh work is named by.
  String Function() get mintIdentity;

  /// What stamps an import.
  DateTime Function() get now;

  /// Who has been told that a cover was extracted.
  ///
  /// It is a field of the mixin and not something the class provides, because
  /// extracting a cover is what this half does: the record half has nothing to
  /// announce. It is never closed, and that is deliberate rather than an
  /// oversight — the composition root builds one repository for the life of
  /// the app, and it outlives every tile that listens to it.
  final StreamController<String> _extracted =
      StreamController<String>.broadcast();

  @override
  Stream<String> get coversExtracted => _extracted.stream;

  @override
  Future<Result<Ebook>> importEbook(FileSource file) async {
    try {
      final kind = describeFile(file.name);

      if (kind == null) {
        // Refused before a byte is copied. The node records what it is told
        // the bytes are and never opens them, so a format guessed here is a
        // format nothing downstream can correct.
        throw AppException(
          kind: ErrorKind.invalidArgument,
          message: 'this app cannot tell what ${file.name} is',
          code: codeUnsupportedFormat,
          op: opImport,
        ).withField('format', 'the name carries no extension this app knows');
      }

      // The bytes first, and the record after them. A device interrupted
      // between the two has a file nothing names, which the next import of the
      // same book adopts for free — the store is keyed by the digest. The
      // other order would leave a work whose file this device never had, which
      // reads to a reader as a book that will not open.
      final stored = await blobs.store(file.openRead());

      _log.fine('imported ${file.name} as $stored');

      // Read back out of the store rather than off the source. The source is a
      // stream that cannot be replayed — a browser's file input is consumed —
      // and the store is the one place the bytes are now certain to be.
      final described = await _describe(kind.format, stored);

      final id = mintIdentity();
      final claims = DeltaWriter()
        // What the file said, and the file name where it said nothing. A field
        // the OPF did not carry is not claimed at all, which is the difference
        // between *unknown* and *empty*: the first keeps whatever another
        // device wrote there and the second says there is none.
        ..text(fieldTitle, described?.title ?? titleFromFileName(file.name))
        ..text(fieldFormat, kind.format.wireName)
        ..id(fieldContentHash, stored.contentHash)
        ..integer(fieldSizeBytes, stored.sizeBytes)
        ..instant(fieldImportedAt, now().toUtc());

      if (described?.author != null) {
        claims.text(fieldAuthor, described!.author);
      }

      if (described?.publisher != null) {
        claims.text(fieldPublisher, described!.publisher);
      }

      if (described?.language != null) {
        claims.text(fieldLanguage, described!.language);
      }

      if (described != null && described.extra.isNotEmpty) {
        claims.object(fieldExtraMetadata, described.extra);
      }

      // The record, its cover and the debt are one transaction. The author
      // commits one of its own and drift nests it as a savepoint, so a failure
      // in either step after it takes the work down too — a work the node is
      // never owed is a book with no upload, a duplicate on the retry, and a
      // release that removes the only copy there is. The bytes stay: they were
      // stored first and a file nothing names is what the retry adopts.
      await library.transaction(() async {
        await author.write(
          Change.insert(TargetEntity.ebook, id, claims.fields),
        );

        // After the work exists, because the row references it and is deleted
        // with it. A cover saved first would be a row pointing at nothing, and
        // the foreign key would refuse it.
        if (described?.cover case final EpubCover cover) {
          await library.saveCover(
            ebookId: id,
            mediaType: cover.mediaType,
            bytes: cover.bytes,
          );
        }

        // The node is owed the file from here on, and the queue is a table: an
        // import made on a train is a transfer that survives closing the app.
        // It is queued and not sent — C16 refuses an upload for a digest no
        // work of the reader's names, and the work reaches the node with the
        // log, so the first attempt of a fresh import is a *not yet* by
        // construction.
        await uploads.owe(
          contentHash: stored.contentHash,
          mediaType: kind.mediaType,
          sizeBytes: stored.sizeBytes,
        );
      });

      final imported = await library.readEbook(id);

      // The row is read back rather than built here. What a work *is* after a
      // change is the reconciler's answer, and a repository that assembled its
      // own copy would be a second one to keep in step.
      return Result<Ebook>.ok(ebookOfRow(imported!));
    } on Object catch (error, stackTrace) {
      _log.warning('${file.name} could not be imported', error, stackTrace);

      return Result<Ebook>.error(failureFrom(error, op: opImport));
    }
  }

  @override
  Future<Result<EbookContent>> downloadEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null || work.deleted) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opDownload,
        );
      }

      final content = await downloads.download(
        ebookId: ebookId,
        // The digest the *work* names, and not whatever arrives. It is what
        // the transfer is checked against, so that a node sending something
        // else is caught here rather than by a reader opening gibberish.
        expectedHash: work.contentHash,
        cancel: cancel,
        onProgress: onProgress,
      );

      // The file is here now, so a cover can be read out of it — which is the
      // whole reason a cover is derived per device rather than replicated. A
      // work downloaded on a second device gets its own.
      await _keepCoverOf(work);

      return Result<EbookContent>.ok(content);
    } on Object catch (error, stackTrace) {
      _log.warning('the file of $ebookId did not arrive', error, stackTrace);

      return Result<EbookContent>.error(failureFrom(error, op: opDownload));
    }
  }

  @override
  Stream<Result<ContentState>> watchContent(String ebookId) =>
      // It follows the *work* and not the digest, because a work whose row
      // arrives by synchronization before its file is the ordinary case and the
      // screen has to stop saying *not here* the moment the bytes land. The
      // transfer is watched under it, so that a queue draining while the reader
      // is looking at the book is something they see happen.
      library
          .watchEbook(ebookId)
          .asyncExpand((row) {
            if (row == null) {
              return Stream<ContentState>.value(
                const ContentState(onThisDevice: false, kept: false),
              );
            }

            final contentHash = row.contentHash;

            // Three things move the answer and none of them is the row: the
            // transfer, the reader's decision, and the store itself. A download
            // writes to the store and to no table, so a watch that woke only on the
            // two tables kept saying *not here* after the bytes had landed. The
            // three are merged as wake-ups and the state is re-read whole on each,
            // rather than combined as latest values: a read is two point queries,
            // and it cannot pair a file's state with a decision about another
            // moment.
            return StreamGroup.merge<void>(<Stream<void>>[
              transfers.watchTransfer(contentHash).map((_) {}),
              transfers.watchDecision(contentHash).map((_) {}),
              blobs.changes
                  .where((digest) => digest == contentHash)
                  .map((_) {}),
            ]).asyncMap((_) => _contentOf(contentHash));
          })
          .asResults(opReadLibrary);

  /// The state of the file [contentHash] names, read now.
  Future<ContentState> _contentOf(String contentHash) async {
    final transfer = await transfers.transfer(contentHash);
    final decision = await transfers.decision(contentHash);

    return ContentState(
      onThisDevice: await blobs.contains(contentHash),
      kept: decision ?? keepsByDefault,
      owedBytes: transfer?.sizeBytes,
      sentBytes: transfer?.sentBytes ?? 0,
    );
  }

  @override
  Future<Result<void>> keepEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opKeep,
        );
      }

      // The decision first, so that a download interrupted half way through
      // leaves a device that still intends to keep the book — and a later
      // pass finishes it — rather than one that has forgotten it was asked.
      await transfers.decide(
        contentHash: work.contentHash,
        kept: true,
        at: now(),
      );

      if (!await blobs.contains(work.contentHash)) {
        final result = await downloadEbook(
          ebookId,
          cancel: cancel,
          onProgress: onProgress,
        );

        if (result case Error<EbookContent>(:final error)) {
          return Result<void>.error(error);
        }
      }

      return const Result<void>.ok(null);
    } on Object catch (error) {
      _log.warning('$ebookId could not be kept', error);

      return Result<void>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Future<Result<void>> releaseEbook(String ebookId) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opKeep,
        );
      }

      // Nothing in this app destroys the only copy of a book. A file still in
      // the queue is on this device and nowhere else, and releasing it would
      // be the one gesture here that loses something the reader cannot get
      // back — so it is refused until the node has it.
      if (await transfers.transfer(work.contentHash) != null) {
        throw AppException(
          kind: ErrorKind.failedPrecondition,
          message:
              'the file of $ebookId has not reached the node and is only here',
          code: codeNotYetSent,
          op: opKeep,
        );
      }

      await transfers.decide(
        contentHash: work.contentHash,
        kept: false,
        at: now(),
      );

      // Two works naming one file are one file. Releasing it releases both,
      // which is not a compromise: they are the same bytes.
      await blobs.remove(work.contentHash);

      _log.fine('released ${work.contentHash}');

      return const Result<void>.ok(null);
    } on Object catch (error) {
      _log.warning('$ebookId could not be released', error);

      return Result<void>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Future<Result<StorageBudget>> storage() async {
    try {
      return Result<StorageBudget>.ok(await budget(blobs));
    } on Object catch (error) {
      _log.warning('the storage budget could not be read', error);

      return Result<StorageBudget>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Stream<Result<List<Ebook>>> watchKeptEbooks() =>
      // Woken by the rows and by the store, for the reason `watchContent` is: a
      // file that arrives or goes changes this list and changes no row.
      StreamGroup.merge<void>(<Stream<void>>[
            library.watchEbooks().map((_) {}),
            blobs.changes.map((_) {}),
          ])
          .asyncMap((_) async {
            final rows = await library.readEbooks();
            final held = (await blobs.digests()).toSet();

            return <Ebook>[
              for (final row in rows)
                if (held.contains(row.contentHash)) ebookOfRow(row),
            ]..sort((a, b) => b.importedAt.compareTo(a.importedAt));
          })
          .asResults(opReadLibrary);

  @override
  Future<Result<int>> reclaimBytes() async {
    try {
      var reclaimed = 0;

      for (final digest in await blobs.digests()) {
        // A digest no work names at all is not this pass's business: an import
        // stores the bytes before it writes the record, so that is what an
        // interrupted one leaves and what its retry adopts through the digest.
        if (!await library.holdsContent(digest)) {
          continue;
        }

        // Some work still names it. Two works sharing one file is one file,
        // so one of them surviving keeps the bytes for both.
        if ((await library.readWorksNaming(digest)).isNotEmpty) {
          continue;
        }

        // Still owed. It is `releaseEbook`'s rule and the same argument: a
        // file the node has not received is on this device and nowhere else,
        // and this is the one pass in the app that removes something without
        // the reader asking for it by name.
        if (await transfers.transfer(digest) != null) {
          continue;
        }

        if (await blobs.remove(digest)) {
          reclaimed++;
        }
      }

      if (reclaimed > 0) {
        _log.info('$reclaimed file(s) of deleted works were reclaimed');
      }

      return Result<int>.ok(reclaimed);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'the deleted works\' files were not reclaimed',
        error,
        stackTrace,
      );

      return Result<int>.error(failureFrom(error, op: opKeep));
    }
  }

  /// Extracts and keeps the cover of [work], if this device can read one.
  ///
  /// It never throws: the file is on the device either way, and failing a
  /// download over a picture would throw away the thing the reader asked for.
  Future<void> _keepCoverOf(EbookRow work) async {
    if (await library.readCover(work.id) != null) {
      return;
    }

    final format = EbookFormat.parse(work.format);

    // The store is asked how long the file is, and the row is not. A work that
    // arrived by synchronization may carry no size at all, and passing that
    // absence as zero read as *under the limit* — which is a book of unknown
    // length read whole into memory on a phone. A file the store does not
    // hold has no cover to extract either.
    final size = await blobs.sizeOf(work.contentHash);

    if (format == null || size == null) {
      return;
    }

    final described = await _describe(
      format,
      StoredBlob(contentHash: work.contentHash, sizeBytes: size),
    );

    if (described?.cover case final EpubCover cover) {
      await library.saveCover(
        ebookId: work.id,
        mediaType: cover.mediaType,
        bytes: cover.bytes,
      );

      // The one place a cover appears *after* the row it belongs to, which is
      // the ordinary case on a device that was seeded: the shelf asked while
      // the file was still coming and was told there was none. An import needs
      // no announcement — the cover is written in the same transaction as the
      // work, so nothing can have asked yet.
      _extracted.add(work.id);
    }
  }

  @override
  Future<Result<EpubCover?>> cover(String ebookId) async {
    try {
      final row = await library.readCover(ebookId);

      return Result<EpubCover?>.ok(
        row == null
            ? null
            : EpubCover(mediaType: row.mediaType, bytes: row.bytes),
      );
    } on Object catch (error) {
      _log.warning('the cover of $ebookId could not be read', error);

      return Result<EpubCover?>.error(failureFrom(error, op: opReadLibrary));
    }
  }

  /// What the stored file says about itself, or `null` where nothing can.
  ///
  /// Only an EPUB, because it is the only format in the contract whose
  /// metadata this app reads — a PDF's is a different specification and a CBZ
  /// has none — and only under [metadataSizeLimit], because the archive is
  /// held in memory to be read.
  Future<EpubMetadata?> _describe(EbookFormat format, StoredBlob stored) async {
    if (format != EbookFormat.epub || stored.sizeBytes > metadataSizeLimit) {
      return null;
    }

    try {
      final bytes = BytesBuilder(copy: false);

      await for (final chunk in blobs.read(stored.contentHash)) {
        bytes.add(chunk);
      }

      return readEpubMetadata(bytes.takeBytes());
    } on Object catch (error) {
      // The book is already in the library at this point. Failing the import
      // because its cover could not be read would throw away a file the reader
      // has, over a picture.
      _log.fine('${stored.contentHash} could not be described', error);

      return null;
    }
  }
}

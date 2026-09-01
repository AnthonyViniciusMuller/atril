/// Opening a book, and the four ways it does not open.
///
/// Three of the four are not failures of this application and the reader is
/// owed a different sentence for each: the work is gone, the file is not on
/// this device, the format is one this build does not render. Only the fourth —
/// a store that could not be read — is an apology. This is where the codes
/// those sentences are chosen by are pinned, because a screen that switched on
/// a message string would be a screen that breaks when somebody edits the ARB.
library;

import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository_impl.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/blob_store.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/storage/memory_blob_store.dart';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

String _hashOf(int seed) => seed.toRadixString(16).padLeft(64, '0');

/// A UUID-shaped identifier from a short name.
///
/// The schema constrains an identifier to thirty-six characters, because that
/// is what every replica in the federation mints — so a test that used `'a'`
/// would be a test against a table this application does not have.
String _id(String name) =>
    '${name.padRight(8, '0')}-1111-4111-8111-111111111111';

/// The device the seeded rows are attributed to.
const String _device = '11111111-1111-4111-8111-111111111111';

AtrilDatabase _open() {
  final AtrilDatabase database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

/// A work in the replica, with [bytes] in the store if it is given any.
Future<void> _seed(
  AtrilDatabase database,
  MemoryBlobStore blobs, {
  required String id,
  String format = 'epub',
  List<int>? bytes,
  bool deleted = false,
  String title = 'Os Sertões',
}) async {
  final String hash = _hashOf(id.hashCode.abs());

  await database
      .into(database.ebooks)
      .insert(
        EbooksCompanion.insert(
          id: _id(id),
          title: title,
          format: format,
          contentHash: hash,
          importedAt: _at,
          vectorClock: VectorClock.of(<String, int>{_device: 1}),
          updatedAt: _at,
          deviceId: _device,
          deleted: Value<bool>(deleted),
        ),
      );

  if (bytes != null) {
    await blobs.put(hash, Stream<List<int>>.value(bytes));
  }
}

void main() {
  late AtrilDatabase database;
  late MemoryBlobStore blobs;
  late ReadingRepository reading;

  setUp(() {
    database = _open();
    blobs = MemoryBlobStore();
    reading = ReadingRepositoryImpl(library: database.libraryDao, blobs: blobs);
  });

  /// The code a refusal carries, or `null` where it succeeded.
  String? codeOf(Result<Object?> result) => switch (result) {
    Error<Object?>(:final Exception error) when error is AppException =>
      error.code,
    _ => null,
  };

  group('opening a book that is here', () {
    test('hands over the bytes and the record\'s own title', () async {
      // The record's title and not the one inside the file: the reader may
      // have corrected it, and RF05 is what let them.
      await _seed(
        database,
        blobs,
        id: 'a',
        bytes: <int>[1, 2, 3, 4],
        title: 'Grande Sertão: Veredas',
      );

      final Result<EpubBook> opened = await reading.openBook(_id('a'));

      expect(opened, isA<Ok<EpubBook>>());

      final EpubBook book = (opened as Ok<EpubBook>).value;

      expect(book.ebookId, _id('a'));
      expect(book.title, 'Grande Sertão: Veredas');
      expect(book.bytes, Uint8List.fromList(<int>[1, 2, 3, 4]));
    });

    test('reads the file whole, however the store hands it over', () async {
      // The store answers with a stream and epub.js reads a zip by seeking in
      // it, so a caller that took the first chunk would hand the engine a
      // truncated archive — which fails inside the engine, a long way from
      // here.
      final List<int> long = List<int>.generate(40000, (int i) => i % 251);

      await _seed(database, blobs, id: 'b', bytes: long);

      final Result<EpubBook> opened = await reading.openBook(_id('b'));

      expect((opened as Ok<EpubBook>).value.bytes, hasLength(long.length));
      expect(opened.value.bytes.last, long.last);
    });
  });

  group('opening a book that does not open', () {
    test('a work this device does not hold is not found', () async {
      expect(codeOf(await reading.openBook(_id('missing'))), 'ebook_not_found');
    });

    test('a work another device deleted is gone, not empty', () async {
      // The tombstone is the answer. A reader who followed a stale link should
      // be told the book was deleted rather than shown a reader that never
      // fills in.
      await _seed(database, blobs, id: 'c', bytes: <int>[1], deleted: true);

      expect(codeOf(await reading.openBook(_id('c'))), 'ebook_not_found');
    });

    test('a format this build does not render says so', () async {
      // Not a failure and not something to retry. The other four formats
      // import, list, synchronize and carry a percentage.
      await _seed(database, blobs, id: 'd', format: 'pdf', bytes: <int>[1]);

      expect(codeOf(await reading.openBook(_id('d'))), codeFormatNotReadable);
    });

    test('the format is checked before the file is', () async {
      // A PDF that is also not downloaded should be reported as a PDF: the
      // download is an offer the reader would accept and then be told the
      // format cannot be opened anyway, which is two refusals for one book.
      await _seed(database, blobs, id: 'e', format: 'djvu');

      expect(codeOf(await reading.openBook(_id('e'))), codeFormatNotReadable);
    });

    test('a work whose bytes are elsewhere is a not-yet', () async {
      // The ordinary state of a book that has not been downloaded, and in a
      // browser the ordinary state of every book the reader has not kept.
      await _seed(database, blobs, id: 'f');

      expect(codeOf(await reading.openBook(_id('f'))), codeContentNotOnDevice);
    });

    test(
      'a file larger than this build will open says so before reading it',
      () async {
        // Opening costs the file's length in memory, twice for a moment on the
        // hosts that hand it over as base64. A reader who imported something
        // enormous should be told, rather than watching the application be
        // killed with nothing said.
        await _seed(database, blobs, id: 'g', bytes: List<int>.filled(16, 0));

        final ReadingRepository small = ReadingRepositoryImpl(
          library: database.libraryDao,
          blobs: _CapaciousStore(blobs, reported: readableSizeLimit + 1),
        );

        expect(codeOf(await small.openBook(_id('g'))), 'ebook_too_large');
      },
    );
  });

  group('the record behind the chrome', () {
    test(
      'is read, and a work that is gone is null rather than an error',
      () async {
        await _seed(database, blobs, id: 'h', bytes: <int>[1]);

        expect(
          ((await reading.ebook(_id('h'))) as Ok<Object?>).value,
          isNotNull,
        );
        expect(
          ((await reading.ebook(_id('nope'))) as Ok<Object?>).value,
          isNull,
        );
      },
    );
  });
}

/// A store that reports a size of its own.
///
/// It exists to reach the size limit without putting two hundred megabytes
/// through a test, which is the only way that branch could otherwise be shown
/// to work.
final class _CapaciousStore implements BlobStore {
  _CapaciousStore(this._inner, {required this.reported});

  final MemoryBlobStore _inner;
  final int reported;

  @override
  Future<int?> sizeOf(String contentHash) async => reported;

  @override
  Future<bool> contains(String contentHash) => _inner.contains(contentHash);

  @override
  Stream<Uint8List> read(String contentHash, {int from = 0}) =>
      _inner.read(contentHash, from: from);

  @override
  Future<BlobWrite> beginWrite() => _inner.beginWrite();

  @override
  Future<bool> remove(String contentHash) => _inner.remove(contentHash);

  @override
  Future<List<String>> digests() => _inner.digests();

  @override
  Future<int> usedBytes() => _inner.usedBytes();
}

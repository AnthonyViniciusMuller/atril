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
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/models/operation.dart';
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

int _minted = 0;

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

  late OperationAuthor author;

  setUp(() async {
    database = _open();
    blobs = MemoryBlobStore();

    // Bound, because the author refuses to write on a device that has no
    // identity: an operation carrying no author is a clock entry nothing could
    // attribute.
    await database.identityDao.bindDevice(
      id: _device,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );

    final HybridClock clock = HybridClock(wall: () => _at);

    author = OperationAuthor(
      database: database,
      clock: clock,
      reconciler: Reconciler(database, clock),
      mint: () => _id('p${++_minted}'),
    );
    reading = ReadingRepositoryImpl(
      library: database.libraryDao,
      places: database.readingDao,
      blobs: blobs,
      author: author,
    );
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
          places: database.readingDao,
          blobs: _CapaciousStore(blobs, reported: readableSizeLimit + 1),
          author: author,
        );

        expect(codeOf(await small.openBook(_id('g'))), 'ebook_too_large');
      },
    );
  });

  group('recording where this device stopped', () {
    test('authors an operation rather than calling the node', () async {
      // C21. A position written through `UpdateReadingProgress` writes the
      // node's table and appends nothing to its log, so it reaches the
      // reader's other devices never. Every write in this application is an
      // operation, and this checks the log rather than the row.
      await _seed(database, blobs, id: 'a', bytes: <int>[1]);

      await reading.saveProgress(
        ebookId: _id('a'),
        locator: 'epubcfi(/6/4[ch1]!/4/2/2/1:0)',
        percent: 12.5,
      );

      // The log this device owes a node, which is where an authored change
      // lands and where a change made through the API never would.
      final List<Operation> owed = await database.syncDao.pending();

      expect(owed, hasLength(1));
      expect(owed.single.entity, TargetEntity.readingProgress);
      expect(owed.single.deviceId, _device);
    });

    test('the row carries the locator byte for byte', () async {
      // The invariant the whole phase rests on, at the point where a locator
      // stops being a value in memory and becomes a row that replicates.
      const String cfi =
          'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05],/2/1:1,/3:4)';

      await _seed(database, blobs, id: 'b', bytes: <int>[1]);
      await reading.saveProgress(ebookId: _id('b'), locator: cfi, percent: 40);

      final ProgressRow row = await (database.select(
        database.progress,
      )..where((t) => t.ebookId.equals(_id('b')))).getSingle();

      expect(row.locator, cfi);
      expect(row.percent, 40);
      expect(row.deviceId, _device);
    });

    test(
      'writing again updates the one row rather than appending another',
      () async {
        // C05 and the grain Quadro 21 specifies: one row per work and device.
        // A second row would be this device disagreeing with itself about where
        // it stopped.
        await _seed(database, blobs, id: 'c', bytes: <int>[1]);

        await reading.saveProgress(
          ebookId: _id('c'),
          locator: 'epubcfi(/6/4!/4/2/2)',
          percent: 10,
        );
        await reading.saveProgress(
          ebookId: _id('c'),
          locator: 'epubcfi(/6/8!/4/2/2)',
          percent: 60,
        );

        final List<ProgressRow> rows = await database
            .select(database.progress)
            .get();

        expect(rows, hasLength(1));
        expect(rows.single.locator, 'epubcfi(/6/8!/4/2/2)');
        expect(rows.single.percent, 60);
      },
    );

    test('the second write supersedes the first rather than tying with it', () async {
      // A position has exactly one writer, so its versions are totally ordered
      // by that device's own counter and can never be concurrent (C05). The
      // clock ticking is what makes the second write win on every replica and
      // not only on this one.
      await _seed(database, blobs, id: 'd', bytes: <int>[1]);

      await reading.saveProgress(
        ebookId: _id('d'),
        locator: 'epubcfi(/6/4!/4/2/2)',
      );

      final ProgressRow first = await database
          .select(database.progress)
          .getSingle();

      await reading.saveProgress(
        ebookId: _id('d'),
        locator: 'epubcfi(/6/8!/4/2/2)',
      );

      final ProgressRow second = await database
          .select(database.progress)
          .getSingle();

      expect(
        second.vectorClock[_device],
        greaterThan(first.vectorClock[_device]),
      );
      // The same row, kept: the identifier this device minted is provenance
      // and is reused, which is the half of C18 that matters on every write.
      expect(second.id, first.id);
    });

    test(
      'a percentage nothing could compute is cleared, not left stale',
      () async {
        // A field the delta does not name keeps whatever wrote it last, so an
        // absent percentage has to be claimed as null — a stale percentage
        // beside a fresh locator is worse than none.
        await _seed(database, blobs, id: 'e', bytes: <int>[1]);

        await reading.saveProgress(
          ebookId: _id('e'),
          locator: 'epubcfi(/6/4!/4/2/2)',
          percent: 30,
        );
        await reading.saveProgress(
          ebookId: _id('e'),
          locator: 'epubcfi(/6/8!/4/2/2)',
        );

        final ProgressRow row = await database
            .select(database.progress)
            .getSingle();

        expect(row.percent, isNull);
      },
    );
  });

  group('where the reader got to, across devices', () {
    /// A position written directly, as another device's operation would land.
    Future<void> seedPlace(
      String work,
      String device, {
      required double percent,
      required DateTime at,
      String locator = 'epubcfi(/6/4!/4/2/2)',
    }) => database
        .into(database.progress)
        .insert(
          ProgressCompanion.insert(
            id: _id('r${++_minted}'),
            ebookId: _id(work),
            deviceId: device,
            locator: locator,
            percent: Value<double?>(percent),
            vectorClock: VectorClock.of(<String, int>{device: 1}),
            updatedAt: at,
          ),
        );

    test('answers one row per device and does not collapse them', () async {
      // RN01, and C05 is what makes it correct: a phone and a desktop
      // disagreeing about where the reader is are not in conflict, they are two
      // true statements. Collapsing them here would be this application
      // deciding which of a reader's devices counts.
      const String other = '22222222-2222-4222-8222-222222222222';

      await _seed(database, blobs, id: 'a', bytes: <int>[1]);
      await seedPlace('a', _device, percent: 20, at: _at);
      await seedPlace(
        'a',
        other,
        percent: 80,
        at: _at.add(const Duration(hours: 1)),
      );

      final List<ReadingPlace> places = await reading
          .watchContinueReading()
          .map(
            (Result<List<ReadingPlace>> r) =>
                (r as Ok<List<ReadingPlace>>).value,
          )
          .first;

      expect(places, hasLength(2));
      expect(places.map((ReadingPlace p) => p.percent), <double>[80, 20]);
    });

    test(
      'says which one is this device, and nothing more about the others',
      () async {
        // `ListDevices` is in the contract and phase 12 is what calls it, so
        // until then *another device* is the whole honest answer.
        const String other = '22222222-2222-4222-8222-222222222222';

        await _seed(database, blobs, id: 'b', bytes: <int>[1]);
        await seedPlace('b', _device, percent: 20, at: _at);
        await seedPlace(
          'b',
          other,
          percent: 80,
          at: _at.add(const Duration(hours: 1)),
        );

        final List<ReadingPlace> places = await reading
            .watchContinueReading()
            .map(
              (Result<List<ReadingPlace>> r) =>
                  (r as Ok<List<ReadingPlace>>).value,
            )
            .first;

        expect(places.first.onThisDevice, isFalse);
        expect(places.last.onThisDevice, isTrue);
      },
    );

    test('is ordered by when it was written, most recent first', () async {
      await _seed(database, blobs, id: 'c', bytes: <int>[1]);
      await _seed(database, blobs, id: 'd', bytes: <int>[1]);
      await seedPlace('c', _device, percent: 10, at: _at);
      await seedPlace(
        'd',
        _device,
        percent: 90,
        at: _at.add(const Duration(days: 1)),
      );

      final List<ReadingPlace> places = await reading
          .watchContinueReading()
          .map(
            (Result<List<ReadingPlace>> r) =>
                (r as Ok<List<ReadingPlace>>).value,
          )
          .first;

      expect(places.first.work.id, _id('d'));
    });

    test('leaves out a work the reader deleted', () async {
      // A reader who deleted a book has said they are not reading it, and a
      // *continue reading* row for it would be the deletion not having
      // happened.
      await _seed(database, blobs, id: 'e', bytes: <int>[1], deleted: true);
      await seedPlace('e', _device, percent: 50, at: _at);

      final List<ReadingPlace> places = await reading
          .watchContinueReading()
          .map(
            (Result<List<ReadingPlace>> r) =>
                (r as Ok<List<ReadingPlace>>).value,
          )
          .first;

      expect(places, isEmpty);
    });

    test('carries the work, so a screen can render what it is given', () async {
      // A position with no work to show is nothing a screen can render, which
      // is why the two are read together rather than handed over separately.
      await _seed(database, blobs, id: 'f', bytes: <int>[1], title: 'Iracema');
      await seedPlace('f', _device, percent: 5, at: _at);

      final ReadingPlace place =
          (await reading
                  .watchContinueReading()
                  .map(
                    (Result<List<ReadingPlace>> r) =>
                        (r as Ok<List<ReadingPlace>>).value,
                  )
                  .first)
              .single;

      expect(place.work.title, 'Iracema');
      expect(place.fraction, closeTo(0.05, 1e-9));
    });

    test(
      'a position this app wrote comes back through the same stream',
      () async {
        // The round trip that matters for the feature: what `saveProgress`
        // authors is what *continue reading* reads back, through the reconciler
        // rather than around it.
        await _seed(database, blobs, id: 'g', bytes: <int>[1]);

        await reading.saveProgress(
          ebookId: _id('g'),
          locator: 'epubcfi(/6/16[ch8]!/4/2/44/1:12)',
          percent: 63.5,
        );

        final ReadingPlace place =
            (await reading
                    .watchContinueReading()
                    .map(
                      (Result<List<ReadingPlace>> r) =>
                          (r as Ok<List<ReadingPlace>>).value,
                    )
                    .first)
                .single;

        expect(place.locator, 'epubcfi(/6/16[ch8]!/4/2/44/1:12)');
        expect(place.percent, 63.5);
        expect(place.onThisDevice, isTrue);
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

  @override
  Stream<String> get changes => _inner.changes;
}

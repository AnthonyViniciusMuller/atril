@TestOn('vm')
/// Seeding a freshly bound device: what is asked for, what is written, and
/// what a pull does to it afterwards.
library;

import 'dart:io';

import 'package:atril/data/services/api/generated/quire/v1/common.pb.dart'
    as common;
import 'package:atril/data/services/api/generated/quire/v1/library.pbgrpc.dart'
    as pblib;
import 'package:atril/data/services/api/generated/quire/v1/reading.pbgrpc.dart'
    as pbread;
import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/reading_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/seed.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/record_key.dart';
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

import 'fake_library_service.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _other = '22222222-2222-4222-8222-222222222222';
const String _work = '33333333-3333-4333-8333-333333333333';
const String _shelf = '44444444-4444-4444-8444-444444444444';
const String _mark = '55555555-5555-4555-8555-555555555555';
const String _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// A revision the node would have sent: one event, seen from [device].
common.Revision _revision(String device, {int counter = 3}) => common.Revision(
  vectorClock: common.VectorClock(
    entries: <String, Int64>{device: Int64(counter)}.entries,
  ),
  updatedAt: common.HybridTimestamp(unixMicros: Int64(1700000000000000)),
  deviceId: device,
);

pblib.Ebook _ebook({String id = _work, String title = 'Grande Sertão'}) =>
    pblib.Ebook(
      id: id,
      title: title,
      format: pblib.EbookFormat.EBOOK_FORMAT_EPUB,
      contentHash: _hash,
      importedAt: Timestamp.fromDateTime(DateTime.utc(2026)),
      revision: _revision(_other),
    );

void main() {
  late FakeLibraryService library;
  late FakeReadingService reading;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late AtrilDatabase database;
  late ReplicaSeeder seeder;
  var minted = 0;

  setUp(() async {
    library = FakeLibraryService();
    reading = FakeReadingService();
    server = Server.create(services: <Service>[library, reading]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    session = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => throw StateError('a seed needs no refresh'),
    );
    database = AtrilDatabase(NativeDatabase.memory());
    minted = 0;

    seeder = ReplicaSeeder(
      database: database,
      library: LibraryApi(connection: connection, session: session),
      reading: ReadingApi(connection: connection, session: session),
      mint: () {
        minted++;

        return '666666${minted.toString().padLeft(2, '0')}-'
            '6666-4666-8666-666666666666';
      },
    );
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
  });

  test('an empty node leaves an empty replica', () async {
    final summary = await seeder.seed(deviceId: _device);

    expect(summary.ebooks, 0);
    expect(await database.select(database.ebooks).get(), isEmpty);
  });

  test('writes the works with the causal metadata the node holds', () async {
    library.ebooks.add(_ebook());

    await seeder.seed(deviceId: _device);

    final work = (await database.select(database.ebooks).get()).single;

    expect(work.id, _work);
    expect(work.title, 'Grande Sertão');
    // Not a fabricated version: what is stored is what the node said, so the
    // record reconciles from here exactly as if it had been pulled.
    expect(work.deviceId, _other);
    expect(work.vectorClock[_other], 3);

    // And the causal state a later change is stamped against.
    expect(
      await database.recordsDao.clockOf(
        RecordKey.record(TargetEntity.ebook, _work),
      ),
      work.vectorClock,
    );
  });

  test('follows the pages rather than asking for one', () async {
    library.pageSize = 2;
    for (var index = 0; index < 5; index++) {
      library.ebooks.add(
        _ebook(id: '3333333$index-3333-4333-8333-333333333333'),
      );
    }

    final summary = await seeder.seed(deviceId: _device);

    expect(summary.ebooks, 5);
    expect(await database.select(database.ebooks).get(), hasLength(5));
  });

  test('skips a work in a format this build cannot name', () async {
    // What a node running a later version of the contract legitimately sends,
    // and what the schema refuses to hold. The honest answer is to leave it
    // out rather than to write a row claiming the file is something else.
    library.ebooks.add(
      _ebook()..format = pblib.EbookFormat.EBOOK_FORMAT_UNSPECIFIED,
    );

    final summary = await seeder.seed(deviceId: _device);

    expect(summary.ebooks, 0);
    expect(await database.select(database.ebooks).get(), isEmpty);
  });

  test('files the works under the shelves they belong to', () async {
    library.ebooks.add(_ebook());
    library.collections.add(
      pblib.Collection(
        id: _shelf,
        name: 'Modernismo',
        kind: pblib.CollectionKind.COLLECTION_KIND_COLLECTION,
        createdAt: Timestamp.fromDateTime(DateTime.utc(2026)),
        revision: _revision(_other),
      ),
    );
    library.filings[_shelf] = <String>[_work];

    final summary = await seeder.seed(deviceId: _device);

    expect(summary.filings, 1);

    final filing =
        (await database.select(database.ebookCollections).get()).single;

    expect(filing.ebookId, _work);
    expect(filing.collectionId, _shelf);
    // No causal history at all, because the contract publishes none for a
    // filing: the first operation about it supersedes this row.
    expect(filing.vectorClock.isEmpty, isTrue);
    // The surrogate identifier is this replica's own, which is what C18 says a
    // replica must mint for itself.
    expect(minted, 1);
    expect(filing.deviceId, _device);
  });

  test('writes every device position and only remembers its own', () async {
    library.ebooks.add(_ebook());
    reading.progress[_work] = <pbread.ReadingProgress>[
      pbread.ReadingProgress(
        ebookId: _work,
        deviceId: _device,
        locator: 'epubcfi(/6/4!/4/2)',
        percent: 12.5,
        vectorClock: common.VectorClock(
          entries: <String, Int64>{_device: Int64(2)}.entries,
        ),
        updatedAt: common.HybridTimestamp(unixMicros: Int64(1700000000000000)),
      ),
      pbread.ReadingProgress(
        ebookId: _work,
        deviceId: _other,
        locator: 'epubcfi(/6/8!/4/2)',
        vectorClock: common.VectorClock(
          entries: <String, Int64>{_other: Int64(9)}.entries,
        ),
        updatedAt: common.HybridTimestamp(unixMicros: Int64(1700000000000001)),
      ),
    ];

    final summary = await seeder.seed(deviceId: _device);

    // Both, because a reader who opens a book on a new phone should be offered
    // where they stopped on the tablet.
    expect(summary.positions, 2);
    expect(await database.select(database.progress).get(), hasLength(2));

    // One version, because a position has exactly one writer (C05) and the
    // only one this device may write is its own.
    final versions = await database.recordsDao.versions();
    final positions = versions.where(
      (row) => row.entity == TargetEntity.readingProgress.wireName,
    );

    expect(positions, hasLength(1));
    expect(positions.single.vectorClock[_device], 2);
  });

  test('writes the marks of every work it seeded', () async {
    library.ebooks.add(_ebook());
    reading.annotations[_work] = <pbread.Annotation>[
      pbread.Annotation(
        id: _mark,
        ebookId: _work,
        kind: pbread.AnnotationKind.ANNOTATION_KIND_HIGHLIGHT,
        locator: 'epubcfi(/6/4!/4/2)',
        revision: _revision(_other),
      ),
    ];

    final summary = await seeder.seed(deviceId: _device);

    expect(summary.annotations, 1);
    expect(
      (await database.select(database.annotations).get()).single.id,
      _mark,
    );
  });

  test('is safe to run twice', () async {
    // A seed is a great many rows over a network that may be a phone's, so it
    // is not one transaction: what makes an interrupted one safe is that every
    // write is an upsert keyed by an identifier the node chose.
    library.ebooks.add(_ebook());
    library.collections.add(
      pblib.Collection(
        id: _shelf,
        name: 'Modernismo',
        kind: pblib.CollectionKind.COLLECTION_KIND_COLLECTION,
        createdAt: Timestamp.fromDateTime(DateTime.utc(2026)),
        revision: _revision(_other),
      ),
    );
    library.filings[_shelf] = <String>[_work];

    await seeder.seed(deviceId: _device);
    await seeder.seed(deviceId: _device);

    expect(await database.select(database.ebooks).get(), hasLength(1));
    expect(
      await database.select(database.ebookCollections).get(),
      hasLength(1),
    );
    // And the filing kept the identifier the first run minted, rather than
    // getting a second name for one record.
    expect(minted, 1);
  });

  test('calls no write rpc', () async {
    // The fake answers every write with UNIMPLEMENTED, so a seed that touched
    // one would fail here rather than in phase 7's walk over `lib/`.
    library.ebooks.add(_ebook());
    library.collections.add(
      pblib.Collection(
        id: _shelf,
        name: 'Modernismo',
        kind: pblib.CollectionKind.COLLECTION_KIND_COLLECTION,
        createdAt: Timestamp.fromDateTime(DateTime.utc(2026)),
        revision: _revision(_other),
      ),
    );
    library.filings[_shelf] = <String>[_work];
    reading.annotations[_work] = <pbread.Annotation>[
      pbread.Annotation(
        id: _mark,
        ebookId: _work,
        kind: pbread.AnnotationKind.ANNOTATION_KIND_NOTE,
        text: 'a note',
        locator: 'epubcfi(/6/4!/4/2)',
        revision: _revision(_other),
      ),
    ];

    await expectLater(seeder.seed(deviceId: _device), completes);
  });
}

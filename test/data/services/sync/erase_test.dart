@TestOn('vm')
/// Emptying the replica of a device that has changed hands.
library;

import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/sync/erase.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/memory_blob_store.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _reader = '22222222-2222-4222-8222-222222222222';
const String _work = '33333333-3333-4333-8333-333333333333';
const String _shelf = '44444444-4444-4444-8444-444444444444';
const String _mark = '55555555-5555-4555-8555-555555555555';
const String _position = '66666666-6666-4666-8666-666666666666';
const String _filing = '77777777-7777-4777-8777-777777777777';
const String _operation = '88888888-8888-4888-8888-888888888888';
const String _refused = '99999999-9999-4999-8999-999999999999';
const String _hash =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const String _domain = 'quire-a.example';
const String _locator = 'epubcfi(/6/4[chap01]!/4/2/2[p1]:0)';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

/// The three tables that are not the reader's to lose.
///
/// The device's own binding, the directory of nodes it can reach, and the floor
/// its clock resumes from. Everything else in the schema belongs to whoever was
/// signed in, and the assertion below is written the other way round on
/// purpose: a table added later and forgotten by the eraser fails this test
/// rather than passing it quietly.
const Set<String> _kept = <String>{
  'bound_device',
  'known_servers',
  'clock_floor',
};

void main() {
  late AtrilDatabase database;
  late MemoryBlobStore blobs;
  late ReplicaEraser eraser;

  setUp(() async {
    database = AtrilDatabase(NativeDatabase.memory());
    blobs = MemoryBlobStore();
    eraser = ReplicaEraser(database: database, blobs: blobs);

    await _fill(database);
    blobs.objects[_hash] = Uint8List.fromList(<int>[1, 2, 3]);
  });

  tearDown(() => database.close());

  test('leaves no row of the reader this device was signed in as', () async {
    // Every table holds something before the erasure, so that a table this
    // test finds empty afterwards is one that was emptied.
    for (final table in database.allTables) {
      expect(
        await _count(database, table.actualTableName),
        isPositive,
        reason: '${table.actualTableName} was not filled',
      );
    }

    await eraser.erase();

    for (final table in database.allTables) {
      final name = table.actualTableName;

      expect(
        await _count(database, name),
        _kept.contains(name) ? isPositive : isZero,
        reason: name,
      );
    }
  });

  test(
    'takes the books themselves and not only the rows naming them',
    () async {
      // The bytes outlive the rows that name them: nothing in the replica
      // references a digest once the works are gone, so a file left here would
      // be an unreachable copy of somebody else's book.
      await eraser.erase();

      expect(await blobs.digests(), isEmpty);
    },
  );

  test('is one unit of work', () async {
    // A replica half emptied is worse than either end of it — some of the
    // previous reader's shelves and none of the operations that explain them —
    // so the tables go together or not at all.
    final failing = ReplicaEraser(database: database, blobs: _BrokenStore());

    await expectLater(failing.erase(), throwsA(anything));

    expect(await _count(database, 'ebooks'), isZero);
    expect(await _count(database, 'pending_operations'), isZero);
  });
}

/// How many rows [table] holds.
Future<int> _count(AtrilDatabase database, String table) async {
  final row = await database
      .customSelect('SELECT count(*) AS n FROM $table')
      .getSingle();

  return row.read<int>('n');
}

/// Puts a row in every table of the schema.
Future<void> _fill(AtrilDatabase database) async {
  await database
      .into(database.knownServers)
      .insert(
        KnownServersCompanion.insert(
          domain: _domain,
          baseUrl: 'https://$_domain',
          isOrigin: const Value<bool>(true),
        ),
      );

  await database.identityDao.bindDevice(
    id: _device,
    name: 'the reading tablet',
    platform: 'linux',
    at: _at,
  );

  await database.identityDao.saveClockFloor(_at);

  await database.identityDao.rememberReader(
    id: _reader,
    localName: 'reader',
    displayName: 'A leitora',
    originServerDomain: _domain,
    federatedId: '@reader:$_domain',
    createdAt: _at,
  );

  await database
      .into(database.ebooks)
      .insert(
        EbooksCompanion.insert(
          id: _work,
          title: 'Grande Sertão: Veredas',
          format: 'epub',
          contentHash: _hash,
          importedAt: _at,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  await database
      .into(database.collections)
      .insert(
        CollectionsCompanion.insert(
          id: _shelf,
          name: 'Para reler',
          createdAt: _at,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  await database
      .into(database.ebookCollections)
      .insert(
        EbookCollectionsCompanion.insert(
          id: _filing,
          ebookId: _work,
          collectionId: _shelf,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  await database.libraryDao.saveCover(
    ebookId: _work,
    mediaType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[4, 5, 6]),
  );

  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: _mark,
          ebookId: _work,
          kind: 'highlight',
          locator: _locator,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  await database
      .into(database.progress)
      .insert(
        ProgressCompanion.insert(
          id: _position,
          ebookId: _work,
          deviceId: _device,
          locator: _locator,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
        ),
      );

  await database
      .into(database.pendingOperations)
      .insert(
        PendingOperationsCompanion.insert(
          id: _operation,
          deviceId: _device,
          targetEntity: 'ebook',
          targetId: _work,
          operation: 'update',
          delta: '{}',
          vectorClock: VectorClock.empty.tick(_device),
          createdAt: _at,
        ),
      );

  await database
      .into(database.pendingOperations)
      .insert(
        PendingOperationsCompanion.insert(
          id: _refused,
          deviceId: _device,
          targetEntity: 'ebook',
          targetId: _work,
          operation: 'update',
          delta: '{}',
          vectorClock: VectorClock.empty.tick(_device),
          createdAt: _at,
        ),
      );

  await database
      .into(database.refusedOperations)
      .insert(RefusedOperationsCompanion.insert(id: _refused, refusedAt: _at));

  await database
      .into(database.appliedOperations)
      .insert(
        AppliedOperationsCompanion.insert(id: _operation, appliedAt: _at),
      );

  await database
      .into(database.recordVersions)
      .insert(
        RecordVersionsCompanion.insert(
          entity: 'ebook',
          identity: _work,
          recordId: _work,
          vectorClock: VectorClock.empty.tick(_device),
        ),
      );

  await database.syncDao.advanceCursor(_domain, 12, at: _at);

  await database.transfersDao.enqueue(
    contentHash: _hash,
    mediaType: 'application/epub+zip',
    sizeBytes: 3,
    at: _at,
  );

  await database.transfersDao.decide(contentHash: _hash, kept: true, at: _at);
}

/// A store that cannot say what it holds.
///
/// It is what stands in for the erasure failing after the tables have gone,
/// which is the one order this can fail in: the rows are deleted first, and a
/// store that throws is how a test reaches the state where they are gone and
/// the files are not.
final class _BrokenStore implements BlobStore {
  @override
  Future<List<String>> digests() async => throw StateError('no store here');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:atril/data/services/local/dao/sync_dao.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _node = 'quire.example';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26, 535, 897);

AtrilDatabase open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

Operation _operation({
  required String id,
  OperationKind kind = OperationKind.insert,
  TargetEntity entity = TargetEntity.ebook,
  Map<String, Object?> delta = const <String, Object?>{'title': 'Sagarana'},
  int counter = 1,
}) => Operation(
  id: id,
  deviceId: _device,
  entity: entity,
  targetId: _work,
  kind: kind,
  delta: delta,
  vectorClock: VectorClock.of(<String, int>{_device: counter}),
  createdAt: _at.add(Duration(microseconds: counter)),
);

String _id(int n) => '$n$n$n$n$n$n$n$n-1111-4111-8111-111111111111';

void main() {
  group('the operation log', () {
    test('comes back in the order it was authored', () async {
      final sync = open().syncDao;

      await sync.appendAll(<Operation>[
        _operation(id: _id(1), counter: 1),
        _operation(id: _id(2), kind: OperationKind.update, counter: 2),
        _operation(id: _id(3), kind: OperationKind.delete, counter: 3),
      ]);

      expect((await sync.pending()).map((operation) => operation.id), <String>[
        _id(1),
        _id(2),
        _id(3),
      ]);
      expect(await sync.pendingCount(), 3);
    });

    test(
      'keeps a field the change cleared apart from one it never named',
      () async {
        final sync = open().syncDao;

        await sync.append(
          _operation(
            id: _id(1),
            kind: OperationKind.update,
            delta: const <String, Object?>{'author': null},
          ),
        );

        final stored = (await sync.pending()).single;

        expect(stored.claims('author'), isTrue);
        expect(stored.delta['author'], isNull);
        expect(stored.claims('title'), isFalse);
      },
    );

    test(
      'round-trips the causal version and the instant it was stamped at',
      () async {
        final sync = open().syncDao;

        await sync.append(_operation(id: _id(1), counter: 7));

        final stored = (await sync.pending()).single;

        expect(stored.vectorClock, VectorClock.of(<String, int>{_device: 7}));
        expect(stored.createdAt, _at.add(const Duration(microseconds: 7)));
        expect(stored.revision.deleted, isFalse);
      },
    );

    test('marks a deletion as the tombstone it is', () async {
      final sync = open().syncDao;

      await sync.append(_operation(id: _id(1), kind: OperationKind.delete));

      expect((await sync.pending()).single.revision.deleted, isTrue);
    });

    test('refuses the same operation twice', () async {
      final sync = open().syncDao;

      await sync.append(_operation(id: _id(1)));

      await expectLater(
        sync.append(_operation(id: _id(1))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('retires what a node has answered for, and nothing else', () async {
      final sync = open().syncDao;

      await sync.appendAll(<Operation>[
        _operation(id: _id(1), counter: 1),
        _operation(id: _id(2), counter: 2),
      ]);

      expect(await sync.retire(<String>[_id(1)]), 1);
      expect((await sync.pending()).single.id, _id(2));
    });
  });

  group('the operations it has applied', () {
    test('forgets what it applied before the window', () async {
      // The table makes a redelivery free rather than safe — applying twice is
      // harmless, because the merge is idempotent — so a row older than any
      // redelivery the cursor does not guard is dead weight, and a table that
      // grew by one row per operation for ever is a replica that never
      // shrinks.
      final sync = open().syncDao;

      await sync.markApplied(
        _id(1),
        at: _at.subtract(const Duration(days: 40)),
      );
      await sync.markApplied(_id(2), at: _at.subtract(const Duration(days: 2)));

      final forgotten = await sync.pruneApplied(
        before: _at.subtract(appliedOperationsWindow),
      );

      expect(forgotten, 1);
      expect(await sync.hasApplied(_id(1)), isFalse);
      expect(await sync.hasApplied(_id(2)), isTrue);
    });
  });

  group('a node cursor', () {
    Future<SyncDao> openWithNode() async {
      final database = open();

      await database.identityDao.rememberServer(
        ServerRow(
          domain: 'quire.example',
          baseUrl: 'https://quire.example',
          isOrigin: true,
          active: true,
        ),
      );

      return database.syncDao;
    }

    test('is zero for a node this device has never pulled from', () async {
      expect(await (await openWithNode()).cursor(_node), 0);
    });

    test('advances as a batch is committed', () async {
      final sync = await openWithNode();

      await sync.advanceCursor(_node, 12, at: _at);

      expect(await sync.cursor(_node), 12);
      expect((await sync.cursors()).single.pulledAt, _at);
    });

    test('never moves backwards', () async {
      final sync = await openWithNode();

      await sync.advanceCursor(_node, 12, at: _at);
      await sync.advanceCursor(_node, 4, at: _at);

      expect(await sync.cursor(_node), 12);
    });
  });
}

@TestOn('vm')
/// Draining the outbox: the order it goes in, and what each verdict does to it.
library;

import 'dart:io';

import 'package:atril/data/services/api/generated/quire/v1/sync.pb.dart' as pb;
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/push.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/utils/errors.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import 'fake_sync_service.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

String _id(int n) =>
    '${n.toString().padLeft(8, '0')}-1111-4111-8111-111111111111';

Operation _operation(int n) => Operation(
  id: _id(n),
  deviceId: _device,
  entity: TargetEntity.ebook,
  targetId: _work,
  kind: n == 1 ? OperationKind.insert : OperationKind.update,
  delta: <String, Object?>{'title': 'Sagarana $n'},
  vectorClock: VectorClock.of(<String, int>{_device: n}),
  createdAt: _at.add(Duration(microseconds: n)),
);

void main() {
  late FakeSyncService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late AtrilDatabase database;
  late OperationPusher pusher;

  /// Puts [count] changes in the outbox, in the order they were authored.
  Future<void> owe(int count) => database.syncDao.appendAll(<Operation>[
    for (var n = 1; n <= count; n++) _operation(n),
  ]);

  setUp(() async {
    node = FakeSyncService();
    server = Server.create(services: <Service>[node]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    session = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => throw StateError('a push needs no refresh'),
    );
    database = AtrilDatabase(NativeDatabase.memory());
    pusher = OperationPusher(
      database: database,
      api: SyncApi(connection: connection, session: session),
    );
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
    await node.heads.close();
  });

  test('hands over the log and stops owing it', () async {
    await owe(3);

    final run = await pusher.run();

    expect(run.applied, 3);
    expect(run.lastPosition, 3);
    expect(await database.syncDao.pendingCount(), 0);
  });

  test('offers it in the order it was authored', () async {
    // The whole of the correctness of a drain. A log whose updates arrive
    // before their inserts is a log the node refuses half of, and the outbox
    // is ordered by the sequence sqlite assigned rather than by anything this
    // file decides.
    await owe(5);

    await pusher.run(batchSize: 2);

    expect(node.pushes, <List<String>>[
      <String>[_id(1), _id(2)],
      <String>[_id(3), _id(4)],
      <String>[_id(5)],
    ]);
  });

  test('retires a duplicate, because the node has it', () async {
    // An operation reaching a node twice — from an earlier push whose reply
    // this device never saw, or from a peer that also replicates the reader —
    // is the normal shape of a federation and not a fault.
    await owe(1);

    node.record(pb.Operation(id: _id(1)));

    final run = await pusher.run();

    expect(run.duplicate, 1);
    expect(run.applied, 0);
    expect(await database.syncDao.pendingCount(), 0);
  });

  test('retires a superseded change and leaves the replica alone', () async {
    // The node stored it and it lost the merge there. That is a verdict on a
    // merge this device would have reached the same way, so nothing is written
    // back and the operation stops being owed.
    await owe(1);

    node.verdicts[_id(1)] = pb.OperationOutcome.OPERATION_OUTCOME_SUPERSEDED;

    final run = await pusher.run();

    expect(run.superseded, 1);
    expect(run.handedOver, 1);
    expect(await database.syncDao.pendingCount(), 0);
  });

  test('quarantines a refused change, with what the node said', () async {
    // The one outcome that reaches a reader. The local write stays exactly as
    // it landed; what changes is that this device stops offering the change
    // and starts saying so.
    await owe(1);

    node.refusing[_id(1)] = 'the work names a format this node does not admit';

    final run = await pusher.run();

    expect(run.refused, 1);
    expect(run.handedOver, 0);

    final refused = await database.syncDao.refused();

    expect(refused, hasLength(1));
    expect(refused.single.$1.id, _id(1));
    expect(
      refused.single.$2.reason,
      'the work names a format this node does not admit',
    );
  });

  test('stops offering a change that was refused', () async {
    // Without this the head of the outbox is offered for ever and nothing
    // behind it is offered at all.
    await owe(1);

    node.refusing[_id(1)] = 'no';

    await pusher.run();
    await pusher.run();

    expect(node.pushes, hasLength(1));
    expect(await database.syncDao.pendingCount(), 0);
  });

  test('goes on to the changes behind a refused one', () async {
    // The whole point of quarantining rather than leaving it queued: one
    // refusal must not stop a reader's other work from reaching anybody.
    await owe(3);

    node.refusing[_id(1)] = 'no';

    final run = await pusher.run(batchSize: 1);

    expect(run.refused, 1);
    expect(run.applied, 2);
    expect(node.pushes, <List<String>>[
      <String>[_id(1)],
      <String>[_id(2)],
      <String>[_id(3)],
    ]);
  });

  test('forgets a refused change and its refusal together', () async {
    await owe(1);

    node.refusing[_id(1)] = 'no';

    await pusher.run();

    expect(await database.syncDao.discard(_id(1)), 1);
    expect(await database.syncDao.refused(), isEmpty);
  });

  test('keeps a verdict this build cannot name', () async {
    // A node running a later contract may answer with a fifth outcome, and the
    // one thing that is certainly wrong is to guess. The operation stays owed,
    // where the worst that happens is a duplicate.
    await owe(1);

    node.verdicts[_id(1)] = pb.OperationOutcome.OPERATION_OUTCOME_UNSPECIFIED;

    final run = await pusher.run();

    expect(run.unanswered, 1);
    expect(await database.syncDao.pendingCount(), 1);
  });

  test(
    'keeps what a failure left behind and loses nothing before it',
    () async {
      // A pass that fails half way has still made half the progress: each batch
      // is answered for and retired before the next is read.
      await owe(4);

      await server.shutdown();

      await expectLater(pusher.run(), throwsA(isA<AppException>()));
      expect(await database.syncDao.pendingCount(), 4);
      expect(pusher.isRunning, isFalse);
    },
  );

  test('does nothing while a pass is already running', () async {
    await owe(1);

    final first = pusher.run();
    final second = await pusher.run();

    expect(second.isEmpty, isTrue);
    expect((await first).applied, 1);
  });
}

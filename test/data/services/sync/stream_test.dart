@TestOn('vm')
/// The stream held open: the cursor it starts from, what it offers, and when it
/// acknowledges.
library;

import 'dart:async';
import 'dart:io';

import 'package:atril/data/model/operation_mapper.dart';
import 'package:atril/data/services/api/generated/quire/v1/sync.pbgrpc.dart'
    as pb;
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/data/services/sync/stream.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import 'fake_sync_service.dart';

const String _here = '11111111-1111-4111-8111-111111111111';
const String _there = '22222222-2222-4222-8222-222222222222';
const String _node = 'quire.example';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

String _id(String half, int n) =>
    '${n.toString().padLeft(8, '0')}-$half-4111-8111-111111111111';

String _work(int n) =>
    'aaaaaaaa-${n.toString().padLeft(4, '0')}-4111-8111-111111111111';

/// A work created somewhere, as an operation.
Operation _import(int n, {required String device, required String half}) =>
    Operation(
      id: _id(half, n),
      deviceId: device,
      entity: TargetEntity.ebook,
      targetId: _work(n),
      kind: OperationKind.insert,
      delta: <String, Object?>{
        fieldTitle: 'Sagarana $n',
        fieldFormat: 'epub',
        fieldContentHash: _hash,
      },
      vectorClock: VectorClock.of(<String, int>{device: n}),
      createdAt: _at.add(Duration(microseconds: n)),
    );

/// A node that holds the bidirectional stream open.
///
/// It reproduces the three things the client is written against: the first
/// message must be the cursor, a push is answered with its verdicts, and the
/// node does not send past its window until the device has confirmed what it
/// already has.
///
/// The real node does not drain inside the push handler — the write announces
/// itself through a hub and this stream is one of the listeners it wakes — but
/// what a device sees is a page after a push either way, so that is what this
/// does.
final class _StreamingNode extends FakeSyncService {
  /// How many positions this node sends ahead of a confirmation.
  int window = 1000;

  /// How many operations one delivered batch holds.
  int batchSize = 100;

  /// Every position a device confirmed.
  final List<int> acks = <int>[];

  /// What the cursor was when a confirmation arrived, asked of the device's
  /// own database. It is how *after the write commits* is made observable.
  void Function(int position)? onAck;

  @override
  Stream<pb.SyncResponse> sync(
    ServiceCall call,
    Stream<pb.SyncRequest> request,
  ) {
    final out = StreamController<pb.SyncResponse>();

    var started = false;
    var sent = 0;
    var acked = 0;

    void drain() {
      while (sent - acked < window) {
        final answer = page(sent, limit: batchSize);

        if (answer.operations.isEmpty) {
          return;
        }

        out.add(
          pb.SyncResponse(
            operations: pb.OperationBatch(operations: answer.operations),
          ),
        );

        sent = answer.lastPosition.toInt();

        if (!answer.hasMore) {
          return;
        }
      }
    }

    final subscription = request.listen(
      (pb.SyncRequest message) {
        if (message.hasStart()) {
          if (started) {
            out.addError(GrpcError.invalidArgument('the stream has begun'));

            return;
          }

          started = true;
          sent = acked = message.start.afterPosition.toInt();

          drain();

          return;
        }

        if (!started) {
          out.addError(
            GrpcError.invalidArgument('the stream must begin with its cursor'),
          );

          return;
        }

        if (message.hasPush()) {
          out.add(
            pb.SyncResponse(
              pushResult: pb.SyncPushResult(
                results: accept(message.push.operations),
              ),
            ),
          );

          drain();

          return;
        }

        final position = message.ack.position.toInt();

        acks.add(position);
        onAck?.call(position);

        if (position > acked && position <= sent) {
          acked = position;
        }

        drain();
      },
      onError: out.addError,
      onDone: out.close,
    );

    out.onCancel = subscription.cancel;

    return out.stream;
  }
}

void main() {
  late _StreamingNode node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late AtrilDatabase database;
  late SyncStream stream;

  /// Puts [count] changes another device made into the node's log.
  void logged(int count) {
    for (var n = 1; n <= count; n++) {
      node.record(wireOperation(_import(n, device: _there, half: '2222')));
    }
  }

  /// Puts [count] changes this device made into the outbox.
  Future<void> owe(int count) => database.syncDao.appendAll(<Operation>[
    for (var n = 1; n <= count; n++)
      _import(n, device: _here, half: '1111'),
  ]);

  setUp(() async {
    node = _StreamingNode();
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
      refresher: () => throw StateError('a stream needs no refresh'),
    );
    database = AtrilDatabase(NativeDatabase.memory());

    await database.identityDao.rememberServer(
      ServerRow(
        domain: _node,
        baseUrl: 'https://$_node',
        isOrigin: true,
        active: true,
      ),
    );
    await database.identityDao.bindDevice(
      id: _here,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );

    stream = SyncStream(
      database: database,
      api: SyncApi(connection: connection, session: session),
      reconciler: Reconciler(database, HybridClock(wall: () => _at)),
      now: () => _at,
    );
  });

  tearDown(() async {
    await stream.close();
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
    await node.heads.close();
  });

  /// Waits until [ready] holds, or gives up. The stream is asynchronous in both
  /// directions and there is no moment it declares itself finished.
  Future<void> until(Future<bool> Function() ready) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (await ready()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    fail('the stream did not reach the state the test was waiting for');
  }

  test('drains the backlog it opens onto', () async {
    // UC11: a reconnection is a backlog and then an ordinary stream.
    logged(3);

    unawaited(stream.open());

    await until(() async => (await database.libraryDao.readEbooks()).length == 3);

    expect(await database.syncDao.cursor(_node), 3);
  });

  test('acknowledges only what is already on disk', () async {
    // The whole of what SyncAck means in this contract. The node advances the
    // device's cursor on the confirmation and not on what it sent, so a
    // confirmation of something not yet written is a device that will come
    // back to the wrong place.
    logged(2);

    final seen = <int, int>{};

    node.onAck = (int position) async =>
        seen[position] = await database.syncDao.cursor(_node);

    unawaited(stream.open());

    await until(() async => seen.containsKey(2));

    expect(seen[2], 2);
  });

  test('starts from the cursor it was left at', () async {
    logged(3);

    await database.syncDao.advanceCursor(_node, 2, at: _at);

    unawaited(stream.open());

    await until(() async => (await database.libraryDao.readEbooks()).length == 1);

    // Only the third arrived: the start carried the cursor and the node sent
    // what is after it.
    expect(await database.syncDao.cursor(_node), 3);
  });

  test('offers what this device owes on the stream it leaves open', () async {
    await owe(2);

    unawaited(stream.open());

    await until(() async => await database.syncDao.pendingCount() == 0);

    expect(node.pushes.first, hasLength(2));
  });

  test('offers one batch at a time', () async {
    // The stream is not a queue this device can fill. A batch goes out, its
    // verdicts come back, and what they retired decides whether another
    // follows.
    await owe(5);

    unawaited(stream.open());

    await until(() async => await database.syncDao.pendingCount() == 0);

    expect(node.pushes.map((List<String> batch) => batch.length), everyElement(5));
  });

  test('stops offering when a batch retires nothing', () async {
    // The head of the outbox was refused, so the next batch would be the same
    // one and offering it again is offering it for ever.
    await owe(1);

    node.refusing[_id('1111', 1)] = 'no';

    unawaited(stream.open());

    await until(() async => node.pushes.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(node.pushes, hasLength(1));
    expect(await database.syncDao.pendingCount(), 1);
  });

  test('offers a change authored while it is open', () async {
    unawaited(stream.open());

    await until(() async => stream.isOpen);
    await owe(1);
    await stream.offer();
    await until(() async => await database.syncDao.pendingCount() == 0);

    expect(node.pushes, hasLength(1));
  });

  test('ends when it is closed, and says nothing went wrong', () async {
    final ended = stream.open();

    await until(() async => stream.isOpen);
    await stream.close();

    await expectLater(ended, completes);
    expect(stream.isOpen, isFalse);
  });

  test('carries what ended it', () async {
    final ended = stream.open();

    await until(() async => stream.isOpen);
    await server.shutdown();

    await expectLater(ended, throwsA(isA<Exception>()));
    expect(stream.isOpen, isFalse);
  });
}

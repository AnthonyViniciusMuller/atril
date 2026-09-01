@TestOn('vm')
/// The web's live channel: a notification, a comparison, and a pull.
library;

import 'dart:async';
import 'dart:io';

import 'package:atril/data/model/operation_mapper.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/pull.dart';
import 'package:atril/data/services/sync/push.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/data/services/sync/watch.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
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

void main() {
  late FakeSyncService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late AtrilDatabase database;
  late WatchChannel watch;

  void logged(int count) {
    for (var n = 1; n <= count; n++) {
      node.record(wireOperation(_import(n, device: _there, half: '2222')));
    }
  }

  Future<void> owe(int count) => database.syncDao.appendAll(<Operation>[
    for (var n = 1; n <= count; n++) _import(n, device: _here, half: '1111'),
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
      refresher: () => throw StateError('a watch needs no refresh'),
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
      name: 'o navegador',
      platform: 'web',
      at: _at,
    );

    final api = SyncApi(connection: connection, session: session);

    watch = WatchChannel(
      database: database,
      api: api,
      puller: OperationPuller(
        database: database,
        api: api,
        reconciler: Reconciler(database, HybridClock(wall: () => _at)),
        now: () => _at,
      ),
      pusher: OperationPusher(database: database, api: api),
    );
  });

  tearDown(() async {
    await watch.close();
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
    await node.heads.close();
  });

  Future<void> until(Future<bool> Function() ready) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (await ready()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    fail('the watch did not reach the state the test was waiting for');
  }

  test('pulls what a notification says exists', () async {
    unawaited(watch.open());

    await until(() async => watch.isOpen);

    logged(2);
    node.heads.add(Int64(2));

    await until(
      () async => (await database.libraryDao.readEbooks()).length == 2,
    );

    expect(await database.syncDao.cursor(_node), 2);
  });

  test('is answered at once when it opens behind', () async {
    // The node answers a caller whose cursor is behind its head immediately,
    // which is what makes a browser that has just been bound catch up without
    // waiting for the next change anybody makes.
    logged(3);

    unawaited(watch.open());

    await until(
      () async => (await database.libraryDao.readEbooks()).length == 3,
    );
  });

  test('does nothing for a position it already holds', () async {
    // A notification that crossed a pull. It is not a fault and it is not a
    // reason to ask the node for a page it has already handed over.
    logged(1);

    unawaited(watch.open());

    await until(() async => (await database.libraryDao.readEbooks()).length == 1);

    final asked = node.pulls.length;

    node.heads.add(Int64(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(node.pulls, hasLength(asked));
  });

  test('hands over what this device owes when it opens', () async {
    // The web's push is a call of its own rather than a message on a stream,
    // which is the whole difference between the two channels.
    await owe(2);

    unawaited(watch.open());

    await until(() async => await database.syncDao.pendingCount() == 0);

    expect(node.pushes.first, hasLength(2));
  });

  test('hands over a change authored while it is open', () async {
    unawaited(watch.open());

    await until(() async => watch.isOpen);
    await owe(1);
    await watch.offer();

    expect(await database.syncDao.pendingCount(), 0);
  });

  test('hands over nothing while it is closed', () async {
    await owe(1);
    await watch.offer();

    expect(await database.syncDao.pendingCount(), 1);
  });

  test('ends when it is closed, and says nothing went wrong', () async {
    final ended = watch.open();

    await until(() async => watch.isOpen);
    await watch.close();

    await expectLater(ended, completes);
    expect(watch.isOpen, isFalse);
  });

  test('carries what ended it', () async {
    final ended = watch.open();

    await until(() async => watch.isOpen);
    await server.shutdown();

    await expectLater(ended, throwsA(isA<Exception>()));
    expect(watch.isOpen, isFalse);
  });
}

@TestOn('vm')
/// Collecting a node's log: the pages, the cursor, and when it moves.
library;

import 'dart:io';

import 'package:atril/data/model/operation_mapper.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/pull.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/utils/errors.dart';
import 'package:drift/drift.dart' show Value;
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

String _id(int n) =>
    '${n.toString().padLeft(8, '0')}-1111-4111-8111-111111111111';

String _work(int n) =>
    'aaaaaaaa-${n.toString().padLeft(4, '0')}-4111-8111-111111111111';

/// A work created on the reader's other device, as it arrives.
Operation _import(int n) => Operation(
  id: _id(n),
  deviceId: _there,
  entity: TargetEntity.ebook,
  targetId: _work(n),
  kind: OperationKind.insert,
  delta: <String, Object?>{
    fieldTitle: 'Sagarana $n',
    fieldFormat: 'epub',
    fieldContentHash: _hash,
  },
  vectorClock: VectorClock.of(<String, int>{_there: n}),
  createdAt: _at.add(Duration(microseconds: n)),
);

void main() {
  late FakeSyncService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late AtrilDatabase database;
  late OperationPuller puller;

  /// Puts [count] changes another device made into the node's log.
  void logged(int count) {
    for (var n = 1; n <= count; n++) {
      node.record(wireOperation(_import(n)));
    }
  }

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
      refresher: () => throw StateError('a pull needs no refresh'),
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

    puller = OperationPuller(
      database: database,
      api: SyncApi(connection: connection, session: session),
      reconciler: Reconciler(database, HybridClock(wall: () => _at)),
      now: () => _at,
    );
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
    await node.heads.close();
  });

  test('applies what the node holds and moves the cursor', () async {
    logged(3);

    final run = await puller.run();

    expect(run.applied, 3);
    expect(run.cursor, 3);
    expect(await database.syncDao.cursor(_node), 3);
    expect(await database.libraryDao.readEbooks(), hasLength(3));
  });

  test('loops over the pages rather than recursing', () async {
    // A device that has been away for a month asks for as many pages as the
    // log grew by, and the cursor it sends is the one the last page ended at.
    logged(5);

    final run = await puller.run(pageSize: 2);

    expect(run.received, 5);
    expect(node.pulls, <int>[0, 2, 4]);
  });

  test('moves the cursor once per page, not once per pass', () async {
    // The cursor is written after each batch is committed. A device that dies
    // between two pages comes back to the page boundary and not to zero.
    logged(4);

    await puller.run(pageSize: 2);

    expect(await database.syncDao.cursor(_node), 4);
  });

  test('starts from the cursor it was left at', () async {
    logged(2);

    await puller.run();
    logged(1);

    // The third work was recorded after the first pass, so the node holds it
    // at position three and this pass asks from two.
    final run = await puller.run();

    expect(node.pulls, <int>[0, 2]);
    expect(run.received, 1);
  });

  test('applies an operation delivered twice exactly once', () async {
    // What makes advancing the cursor after the batch safe rather than merely
    // careful. The same operation reaching this replica twice — from the node
    // it was pulled from, and again from a peer that also replicates the
    // reader — is recognized by the identifier its author minted.
    logged(1);
    node.record(wireOperation(_import(1)));

    final run = await puller.run();

    expect(run.received, 2);
    expect(run.applied, 1);
    expect(run.duplicate, 1);
    expect(await database.libraryDao.readEbooks(), hasLength(1));
  });

  test('does not ask again for a page that did not move the cursor', () async {
    // A node this build cannot follow, rather than a log it has caught up
    // with. Asking again would ask for the same page for ever.
    logged(2);

    node.log[1].position = node.log[0].position;

    final run = await puller.run(pageSize: 2);

    expect(node.pulls, hasLength(1));
    expect(run.received, 2);
  });

  test('says so when this device is signed in nowhere', () async {
    await (database.update(database.knownServers)).write(
      const KnownServersCompanion(isOrigin: Value<bool>(false)),
    );

    await expectLater(
      puller.run(),
      throwsA(
        isA<AppException>().having(
          (AppException failure) => failure.code,
          'code',
          'no_origin_server',
        ),
      ),
    );
  });

  test('does nothing while a pass is already running', () async {
    logged(1);

    final first = puller.run();
    final second = await puller.run();

    expect(second.isEmpty, isTrue);
    expect((await first).received, 1);
  });
}

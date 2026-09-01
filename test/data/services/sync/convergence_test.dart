@TestOn('vm')
/// Two devices, one node, and the write that wins.
///
/// This is Quire's own end-to-end reconciliation test written from the client's
/// side, and it is the claim the whole application rests on: a reader with two
/// devices ends up with one library, and which version survives is decided the
/// same way on both.
///
/// **Nothing here is a synthetic log.** `reconciler_convergence_test.dart`
/// shuffles operations into a reconciler and proves the merge; this drives two
/// whole replicas through the parts that surround it — the operation author
/// stamping a version, the outbox, `PushOperations`, `PullOperations`, the
/// cursor — against a node that keeps the log the way a node does. What it
/// therefore catches is what that file cannot: a version stamped against the
/// wrong predecessor, a cursor that skips, an outbox drained out of order. Each
/// of those is a divergence that no amount of correctness in the merge repairs.
///
/// **The later write is pushed first**, deliberately. A federation has no
/// global order and the node's positions are the order things *arrived*, not the
/// order they happened; a client that let arrival decide would converge on
/// whichever device had the better connection. So the device that wrote second
/// pushes first, and the device that wrote first pushes after it, and both
/// replicas still land on the second write — because `(updated_at, device_id)`
/// is what settles a concurrent pair and it is a property of the writes rather
/// than of the wire.
library;

import 'dart:io';

import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/pull.dart';
import 'package:atril/data/services/sync/push.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import 'fake_sync_service.dart';

/// The two devices, named so that `_first` sorts below `_second` as text —
/// which is the order the tie-break uses when two instants are equal.
const String _first = '11111111-1111-4111-8111-111111111111';
const String _second = '22222222-2222-4222-8222-222222222222';

const String _node = 'quire.example';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

final DateTime _origin = DateTime.utc(2026, 3, 14, 15);

/// A device's wall clock, which each test moves by hand.
///
/// The hybrid clock is `max(wall, observed + 1µs)`, so a device that has seen a
/// change stamps after it whatever this says — which is exactly the guarantee
/// being leaned on, and the reason a test can set two walls and know which
/// write is later.
final class _Wall {
  _Wall(this.at);

  DateTime at;

  DateTime read() => at;
}

/// One reader's device: its own replica, its own clock, its own outbox.
final class _Device {
  _Device({
    required this.id,
    required this.database,
    required this.wall,
    required this.author,
    required this.pusher,
    required this.puller,
  });

  final String id;
  final AtrilDatabase database;
  final _Wall wall;
  final OperationAuthor author;
  final OperationPusher pusher;
  final OperationPuller puller;

  /// Hands the node what this device owes, then takes what it does not have.
  ///
  /// The order is the one every channel in this app uses, and it matters here:
  /// a device that pulled first would apply the other's write, stamp its own
  /// above it, and never have been concurrent at all.
  Future<void> exchange() async {
    await pusher.run();
    await puller.run();
  }

  /// The title this device currently holds for the work.
  Future<String?> title() async =>
      (await database.libraryDao.readEbook(_work))?.title;
}

void main() {
  late FakeSyncService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late _Device one;
  late _Device two;

  Future<_Device> device(String id) async {
    final database = AtrilDatabase(NativeDatabase.memory());

    addTearDown(database.close);

    await database.identityDao.rememberServer(
      ServerRow(
        domain: _node,
        baseUrl: 'https://$_node',
        isOrigin: true,
        active: true,
      ),
    );
    await database.identityDao.bindDevice(
      id: id,
      name: id,
      platform: 'android',
      at: _origin,
    );

    final wall = _Wall(_origin);
    final clock = HybridClock(wall: wall.read);
    final reconciler = Reconciler(database, clock);
    final api = SyncApi(connection: connection, session: session);

    return _Device(
      id: id,
      database: database,
      wall: wall,
      author: OperationAuthor(
        database: database,
        clock: clock,
        reconciler: reconciler,
      ),
      pusher: OperationPusher(database: database, api: api),
      puller: OperationPuller(
        database: database,
        api: api,
        reconciler: reconciler,
        now: () => _origin,
      ),
    );
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
      refresher: () => throw StateError('a sync needs no refresh'),
    );

    one = await device(_first);
    two = await device(_second);
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await node.heads.close();
  });

  /// Puts one work on both devices, so that what follows is two edits to a
  /// record they agree about.
  Future<void> shareAWork() async {
    await one.author.write(
      Change.insert(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'Sagarana',
        fieldFormat: 'epub',
        fieldContentHash: _hash,
      }),
    );

    await one.exchange();
    await two.exchange();

    expect(await two.title(), 'Sagarana');
  }

  test('the later of two concurrent writes wins on both devices', () async {
    await shareAWork();

    // Neither has heard from the other since, so the two versions that follow
    // are concurrent: one clock ticks its own entry, the other adds a second.
    one.wall.at = _origin.add(const Duration(minutes: 1));
    two.wall.at = _origin.add(const Duration(minutes: 2));

    await one.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'Sagarana, primeira edição',
      }),
    );
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'Sagarana, segunda edição',
      }),
    );

    // The later write reaches the node first, which is the case a client that
    // let arrival decide would get wrong.
    await two.exchange();
    await one.exchange();
    await two.exchange();

    expect(await one.title(), 'Sagarana, segunda edição');
    expect(await two.title(), 'Sagarana, segunda edição');
  });

  test('the earlier write pushed first reaches the same state', () async {
    await shareAWork();

    one.wall.at = _origin.add(const Duration(minutes: 1));
    two.wall.at = _origin.add(const Duration(minutes: 2));

    await one.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'Sagarana, primeira edição',
      }),
    );
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'Sagarana, segunda edição',
      }),
    );

    await one.exchange();
    await two.exchange();
    await one.exchange();

    expect(await one.title(), 'Sagarana, segunda edição');
    expect(await two.title(), 'Sagarana, segunda edição');
  });

  test('the device settles two writes stamped at the same instant', () async {
    // C01's tie-break has a second half, and it exists because two devices can
    // legitimately stamp the same microsecond. The identifiers are compared as
    // canonical text, which orders exactly as the bytes behind them.
    await shareAWork();

    final together = _origin.add(const Duration(minutes: 1));

    one.wall.at = together;
    two.wall.at = together;

    await one.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'do primeiro aparelho',
      }),
    );
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'do segundo aparelho',
      }),
    );

    await one.exchange();
    await two.exchange();
    await one.exchange();

    // The higher identifier wins, and both devices agree that it did.
    expect(await one.title(), 'do segundo aparelho');
    expect(await two.title(), 'do segundo aparelho');
  });

  test('a deletion is a write and reconciles as one', () async {
    // A tombstone is not a separate mechanism: it travels as a delta like any
    // other change and settles by the same rule, so a later edit beats an
    // earlier deletion and both devices see the work again.
    await shareAWork();

    one.wall.at = _origin.add(const Duration(minutes: 1));
    two.wall.at = _origin.add(const Duration(minutes: 2));

    await one.author.write(Change.delete(TargetEntity.ebook, _work));
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'ainda aqui',
      }),
    );

    await one.exchange();
    await two.exchange();
    await one.exchange();

    expect(await one.title(), 'ainda aqui');
    expect(
      (await one.database.libraryDao.readEbook(_work))?.deleted,
      isFalse,
    );
    expect(
      (await two.database.libraryDao.readEbook(_work))?.deleted,
      isFalse,
    );
  });

  test('both devices end with the same causal state', () async {
    // Converging on the record is not enough. The next change either device
    // authors is stamped on top of what it thinks the current version is, so
    // two replicas holding the same row under different clocks would diverge
    // on the write after this one rather than on this one.
    await shareAWork();

    one.wall.at = _origin.add(const Duration(minutes: 1));
    two.wall.at = _origin.add(const Duration(minutes: 2));

    await one.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'de um',
      }),
    );
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'de dois',
      }),
    );

    await two.exchange();
    await one.exchange();
    await two.exchange();

    final here = await one.database.libraryDao.readEbook(_work);
    final there = await two.database.libraryDao.readEbook(_work);

    expect(here?.vectorClock, there?.vectorClock);
    expect(here?.updatedAt, there?.updatedAt);
    expect(here?.deviceId, there?.deviceId);
  });

  test('neither device owes the node anything afterwards', () async {
    await shareAWork();

    one.wall.at = _origin.add(const Duration(minutes: 1));
    two.wall.at = _origin.add(const Duration(minutes: 2));

    await one.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'de um',
      }),
    );
    await two.author.write(
      Change.update(TargetEntity.ebook, _work, <String, Object?>{
        fieldTitle: 'de dois',
      }),
    );

    await two.exchange();
    await one.exchange();
    await two.exchange();

    // The write that lost is retired and not retried: the node stored it and
    // it lost the merge there, which is a verdict rather than a failure to
    // deliver.
    expect(await one.database.syncDao.pendingCount(), 0);
    expect(await two.database.syncDao.pendingCount(), 0);
    expect(await one.database.syncDao.refused(), isEmpty);
    expect(await two.database.syncDao.refused(), isEmpty);
  });
}

@TestOn('vm')
/// When this device talks to its node: the three conditions, the backoff, and
/// what clears it.
library;

import 'dart:async';

import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/reachability.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/content/upload_queue.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/live_channel.dart';
import 'package:atril/data/services/sync/scheduler.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/utils/errors.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/memory_blob_store.dart';

const String _node = 'quire.example';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

/// One change in the outbox, as the operation author would have left it.
Operation _change() => Operation(
  id: '00000001-1111-4111-8111-111111111111',
  deviceId: '11111111-1111-4111-8111-111111111111',
  entity: TargetEntity.ebook,
  targetId: 'aaaaaaaa-1111-4111-8111-111111111111',
  kind: OperationKind.insert,
  delta: const <String, Object?>{'title': 'Sagarana'},
  vectorClock: VectorClock.of(const <String, int>{
    '11111111-1111-4111-8111-111111111111': 1,
  }),
  createdAt: _at,
);

/// A channel that opens when it is told to and ends when it is told to.
///
/// It stands in for both real ones, which is what having a port is worth: the
/// loop above them cares about three events — it opened, it ended, it was asked
/// to hand something over — and nothing else about either transport reaches it.
final class _FakeChannel implements SyncChannel {
  /// How many times it was opened.
  int opens = 0;

  /// How many times it was asked to hand something over.
  int offers = 0;

  /// What opening throws, where a test wants a node that cannot be reached.
  Object? refusesToOpen;

  Completer<void>? _done;

  @override
  bool get isOpen => _done != null;

  @override
  Future<void> open() async {
    opens++;

    final refusal = refusesToOpen;

    if (refusal != null) {
      throw refusal;
    }

    _done = Completer<void>();
  }

  @override
  Future<void> get done => _done?.future ?? Future<void>.value();

  @override
  Future<void> offer() async {
    offers++;
  }

  @override
  Future<void> close() async {
    final done = _done;

    _done = null;

    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  /// Ends the open channel with [error], as a node hanging up would.
  void endWith(Object error) {
    final done = _done;

    _done = null;
    done?.completeError(error);
  }
}

void main() {
  late AtrilDatabase database;
  late SessionHolder session;
  late NodeReachability reachability;
  late StreamController<bool> radio;
  late StreamController<bool> foreground;
  late _FakeChannel channel;
  late SyncScheduler scheduler;
  late NodeConnection connection;

  /// A holder that already carries a credential, so that `isSignedIn` is true
  /// without a node behind it.
  SessionHolder signedIn() => SessionHolder(
    store: MemorySessionStore(
      SessionCredential(
        refreshToken: 'a-refresh-token',
        expiresAt: _at.add(const Duration(days: 30)),
      ),
    ),
    refresher: () => throw StateError('the loop refreshes nothing'),
    clock: () => _at,
  );

  setUp(() async {
    database = AtrilDatabase(NativeDatabase.memory());
    session = signedIn();
    radio = StreamController<bool>.broadcast();
    reachability = NodeReachability(radio: radio.stream);
    foreground = StreamController<bool>.broadcast();
    channel = _FakeChannel();
    connection = NodeConnection(
      NodeEndpoint(authority: '127.0.0.1:1', transportSecurity: false),
    );

    scheduler = SyncScheduler(
      database: database,
      channel: channel,
      session: session,
      reachability: reachability,
      uploads: UploadQueue(
        database: database,
        // Nothing is owed in these tests, so the pass is one query and the
        // uploader is never reached.
        uploader: ContentUploader(
          api: LibraryApi(connection: connection, session: session),
          blobs: MemoryBlobStore(),
        ),
      ),
      foreground: foreground.stream,
      firstDelay: const Duration(milliseconds: 20),
      longestDelay: const Duration(milliseconds: 80),
      settledFor: const Duration(milliseconds: 200),
      now: () => _at,
    );
  });

  tearDown(() async {
    await scheduler.dispose();
    await reachability.dispose();
    await radio.close();
    await foreground.close();
    await connection.shutdown();
    await session.dispose();
    await database.close();
  });

  Future<void> until(bool Function() ready, {String? what}) async {
    for (var attempt = 0; attempt < 400; attempt++) {
      if (ready()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    fail(what ?? 'the loop did not reach the state the test was waiting for');
  }

  test('opens a channel when it starts', () async {
    await scheduler.start();

    await until(() => channel.isOpen);

    expect(scheduler.status.activity, SyncActivity.live);
  });

  test('opens none while the device is signed out', () async {
    final signedOut = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => throw StateError('the loop refreshes nothing'),
    );

    addTearDown(signedOut.dispose);

    final loop = SyncScheduler(
      database: database,
      channel: channel,
      session: signedOut,
      reachability: reachability,
      uploads: UploadQueue(
        database: database,
        uploader: ContentUploader(
          api: LibraryApi(connection: connection, session: signedOut),
          blobs: MemoryBlobStore(),
        ),
      ),
      foreground: foreground.stream,
      now: () => _at,
    );

    addTearDown(loop.dispose);

    await loop.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(channel.opens, 0);
    expect(loop.status.activity, SyncActivity.idle);
  });

  test('closes the channel when the app goes into the background', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    foreground.add(false);

    await until(() => !channel.isOpen);

    expect(scheduler.status.activity, SyncActivity.idle);
  });

  test('opens again when the app comes back', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    foreground.add(false);
    await until(() => !channel.isOpen);

    foreground.add(true);
    await until(() => channel.isOpen);

    expect(channel.opens, 2);
  });

  test('keeps its channel when the node is believed unreachable', () async {
    // Reachability is a hint and not a gate. Whatever concluded the node was
    // not answering was a call that failed, the channel ends on its own, and a
    // loop that stood down here could never learn it was wrong — nothing would
    // call, so nothing would conclude.
    await scheduler.start();
    await until(() => channel.isOpen);

    radio.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(channel.isOpen, isTrue);
  });

  test('closes it when the session ends', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    await session.end();

    await until(() => !channel.isOpen);
  });

  test('waits, and waits longer, after a channel that did not last', () async {
    // The backoff is bounded and doubles. Nothing here is dressed up as a
    // conclusion about the node: how long a channel lasted is the only
    // evidence this layer has.
    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await scheduler.start();

    await until(() => channel.opens >= 1);
    await until(() => scheduler.status.activity == SyncActivity.waiting);

    final first = scheduler.status.retryIn;

    await until(() => channel.opens >= 2);
    await until(
      () =>
          scheduler.status.activity == SyncActivity.waiting &&
          scheduler.status.retryIn != first,
    );

    expect(scheduler.status.retryIn, greaterThan(first!));
    expect(scheduler.status.failure?.kind, ErrorKind.unavailable);
  });

  test('never waits longer than the bound', () async {
    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await scheduler.start();

    await until(() => channel.opens >= 6);
    await until(() => scheduler.status.activity == SyncActivity.waiting);

    expect(
      scheduler.status.retryIn,
      lessThanOrEqualTo(const Duration(milliseconds: 80)),
    );
  });

  test('tries at once when an interface appears', () async {
    // A retry hint is not proof of a route. It is the moment trying stopped
    // being pointless, which is exactly what a device coming out of a tunnel
    // needs and what it would otherwise wait out the backoff for.
    //
    // The wait is a minute here so that *at once* is not something the test
    // could have got by accident.
    final loop = SyncScheduler(
      database: database,
      channel: channel,
      session: session,
      reachability: reachability,
      uploads: UploadQueue(
        database: database,
        uploader: ContentUploader(
          api: LibraryApi(connection: connection, session: session),
          blobs: MemoryBlobStore(),
        ),
      ),
      foreground: foreground.stream,
      firstDelay: const Duration(minutes: 1),
      longestDelay: const Duration(minutes: 1),
      now: () => _at,
    );

    addTearDown(loop.dispose);

    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await loop.start();
    await until(() => loop.status.activity == SyncActivity.waiting);

    channel.refusesToOpen = null;

    // The radio going down and coming back up is what produces the hint: it
    // fires when an interface appears while the node is believed unreachable,
    // which is the only state it is honest about.
    radio.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    radio.add(true);

    await until(() => channel.isOpen);
  });

  test('reopens after a channel the node ended', () async {
    await scheduler.start();
    await until(() => scheduler.status.activity == SyncActivity.live);

    final opened = channel.opens;

    channel.endWith(
      const AppException(kind: ErrorKind.unavailable, message: 'hung up'),
    );

    await until(() => channel.opens > opened);
  });

  test('hands over a change nobody told it about', () async {
    // A change authored anywhere in the app lands in the outbox, and this loop
    // watches the table rather than waiting to be called. A caller that had to
    // remember to announce a write would be a caller that eventually did not.
    await scheduler.start();
    await until(() => scheduler.status.activity == SyncActivity.live);

    final offered = channel.offers;

    await database.syncDao.appendAll(<Operation>[_change()]);

    await until(() => channel.offers > offered);
  });

  test('hands a change over on the open channel', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    final offered = channel.offers;

    await scheduler.nudge();

    expect(channel.offers, offered + 1);
  });

  test('does not jump a backoff for a change authored here', () async {
    // A reader writing a note does not make an unreachable node reachable.
    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await scheduler.start();
    await until(() => scheduler.status.activity == SyncActivity.waiting);

    final opened = channel.opens;

    await scheduler.nudge();

    expect(channel.opens, opened);
  });

  test('records that it reached the node', () async {
    // What a reader is shown, and what a pull alone would not move on a log
    // that has not grown.
    await database.identityDao.rememberServer(
      ServerRow(
        domain: _node,
        baseUrl: 'https://$_node',
        isOrigin: true,
        active: true,
      ),
    );

    await scheduler.start();

    for (var attempt = 0; attempt < 100; attempt++) {
      if (await database.syncDao.lastExchangeWith(_node) != null) {
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(await database.syncDao.lastExchangeWith(_node), isNotNull);
  });

  test('stops, and closes what it had open', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    await scheduler.stop();

    expect(channel.isOpen, isFalse);
    expect(scheduler.status.activity, SyncActivity.idle);
  });
}

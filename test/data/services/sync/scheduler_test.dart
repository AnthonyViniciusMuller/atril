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
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/utils/errors.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/memory_blob_store.dart';

const String _node = 'quire.example';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

/// A wall clock the test moves by hand.
///
/// The loop reads it to decide how long a channel lasted, which is the only
/// evidence this layer has that a node was on the other end of one, so a test
/// about lasting has to be able to say how long.
final class _Clock {
  DateTime at = _at;

  DateTime read() => at;
}

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

  /// What handing something over throws. On the web an offer is a call of its
  /// own, so it can fail while the channel is open.
  Object? refusesToOffer;

  /// Held by a test that wants an open which has not finished yet, which is
  /// the window a lifecycle or session event can arrive in.
  Completer<void>? opening;

  /// What the channel ends with while it is still opening, which is a
  /// transport that failed before anybody had asked what would end it.
  Object? endsWhileOpening;

  Completer<void>? _done;

  @override
  bool get isOpen => _done != null;

  @override
  Future<void> open() async {
    opens++;

    await opening?.future;

    final refusal = refusesToOpen;

    if (refusal != null) {
      throw refusal;
    }

    final done = Completer<void>();

    _done = done;

    // As both real channels do, and for the reason they do it: nothing is
    // listening between here and the loop's own subscription, and a future
    // completed with an error and no listener is an unhandled error.
    unawaited(done.future.catchError((Object _) {}));

    final ending = endsWhileOpening;

    if (ending != null) {
      done.completeError(ending);
    }
  }

  @override
  Future<void> get done => _done?.future ?? Future<void>.value();

  @override
  Future<void> offer() async {
    offers++;

    final refusal = refusesToOffer;

    if (refusal != null) {
      throw refusal;
    }
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
  late _Clock clock;

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
    clock = _Clock();
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
      now: clock.read,
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

  /// Remembers the node this device is signed in at, which is what an exchange
  /// is recorded against.
  Future<void> knownNode() => database.identityDao.rememberServer(
    ServerRow(
      domain: _node,
      baseUrl: 'https://$_node',
      isOrigin: true,
      active: true,
    ),
  );

  /// Waits until [held] no longer holds, for a row the loop deletes.
  Future<void> untilGone(Future<bool> Function() held) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (!await held()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    fail('the loop did not forget what the test was waiting for');
  }

  /// Waits until [read] answers with something, for the facts that land in the
  /// database rather than in the loop's own state.
  Future<void> untilStored(Future<Object?> Function() read) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (await read() != null) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    fail('the loop did not write what the test was waiting for');
  }

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

  /// A digest nothing in this test holds the bytes of.
  const String owedHash =
      '0000000000000000000000000000000000000000000000000000000000000001';

  /// Tells the loop that the node is owed a file, as an import would.
  Future<void> oweAFile() => database.transfersDao.enqueue(
    contentHash: owedHash,
    mediaType: 'application/epub+zip',
    sizeBytes: 8,
    at: _at,
  );

  /// Whether the file is still owed.
  Future<bool> stillOwed() async =>
      await database.transfersDao.transfer(owedHash) != null;

  test('sends a file imported while the channel was already up', () async {
    // The bug this is written against: the queue was driven at connection time
    // and nowhere else, so a book imported during a live session was owed for
    // ever — the channel that would have carried it never reopened, and the
    // pass that ran when it opened ran before the push it depends on.
    await scheduler.start();
    await until(() => scheduler.status.activity == SyncActivity.live);

    // The import: a change in the outbox and a file owed, both after the
    // connection-time pass has already come and gone.
    await database.syncDao.appendAll(<Operation>[_change()]);
    await oweAFile();

    expect(await stillOwed(), isTrue);

    // The node takes the operation, which this device learns as its outbox
    // shrinking. C16 stops refusing the bytes here and at no earlier moment.
    await database.syncDao.retire(<String>[_change().id]);

    // Nothing holds the bytes, so the pass retires the row as hopeless — which
    // is what makes *a pass ran* observable with no node to send to. Before
    // the fix the row sat there until the process ended.
    await untilGone(stillOwed);
  });

  test('sends the files when a reader asks to synchronize now', () async {
    // *Synchronize now* is one word to a reader, and it handed over the
    // records and not the bytes: the one control the app offers for a book
    // that has not arrived did nothing about the book.
    await scheduler.start();
    await until(() => channel.isOpen);

    await oweAFile();

    expect(await stillOwed(), isTrue);

    await scheduler.syncNow();

    expect(await stillOwed(), isFalse);
  });

  test('hands a change over on the open channel', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    final offered = channel.offers;

    await scheduler.nudge();

    expect(channel.offers, offered + 1);
  });

  test('watches the lifecycle again after it was let go', () async {
    // The controller behind `appForeground` is a broadcast one, so `onListen`
    // runs again for the subscription that follows a cancelled one — and the
    // listener it assigned was a `late final`. A loop stopped and started
    // again is that case, and it threw where nothing could report it.
    TestWidgetsFlutterBinding.ensureInitialized();

    final foreground = appForeground();
    final seen = <bool>[];

    await foreground.listen(seen.add).cancel();

    final second = foreground.listen(seen.add);

    addTearDown(second.cancel);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter/lifecycle',
          const StringCodec().encodeMessage('AppLifecycleState.inactive'),
          (ByteData? _) {},
        );

    expect(seen, <bool>[true]);
  });

  test('stands down a channel that was still opening', () async {
    // Closing a channel that has not opened closes nothing, so an event
    // arriving in that window left the loop going on to publish *live* and
    // wait on a channel nobody wanted — in an app that had gone into the
    // background.
    final opening = Completer<void>();

    channel.opening = opening;

    await scheduler.start();
    await until(() => channel.opens == 1);

    foreground.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // And now the open finishes, after the stand-down that could not close it.
    opening.complete();

    await until(() => !channel.isOpen);

    expect(scheduler.status.activity, SyncActivity.idle);
  });

  test('keeps an offer that failed to the status', () async {
    // On the web an offer is a push call of its own and can fail while the
    // channel it belongs to is open. A reader who asked for it is owed the
    // reason rather than an exception out of a future nobody is holding.
    await scheduler.start();
    await until(() => channel.isOpen);

    channel.refusesToOffer = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await scheduler.syncNow();

    expect(scheduler.status.failure?.kind, ErrorKind.unavailable);
  });

  test('keeps an offer nobody is awaiting to the status', () async {
    // The path that has no caller at all: a change lands in the outbox, the
    // loop notices the table grew, and what it hands over is handed over from
    // a stream listener. A failure there is an unhandled error.
    await scheduler.start();
    await until(() => channel.isOpen);

    channel.refusesToOffer = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await database.syncDao.appendAll(<Operation>[_change()]);

    await until(() => scheduler.status.failure != null);

    expect(scheduler.status.failure?.kind, ErrorKind.unavailable);
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

  test('records nothing for a channel that only opened', () async {
    // Opening does not reach the node. gRPC dials lazily and the stream's own
    // open only reads the cursor out of the database, so a device whose node
    // had been down for a week would otherwise be told it synchronized just
    // now — which is the one thing this column is asked.
    await knownNode();

    await scheduler.start();
    await until(() => channel.isOpen);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(await database.syncDao.lastExchangeWith(_node), isNull);
  });

  test('records that it reached the node when a channel lasted', () async {
    // The evidence this layer can see for itself. What ended the channel is
    // not the node refusing to be reached: it was there for a minute.
    await knownNode();

    await scheduler.start();
    await until(() => channel.isOpen);

    clock.at = _at.add(const Duration(minutes: 1));

    channel.endWith(
      const AppException(kind: ErrorKind.unavailable, message: 'hung up'),
    );

    await untilStored(() => database.syncDao.lastExchangeWith(_node));

    expect(await database.syncDao.lastExchangeWith(_node), clock.at);
  });

  test('forgets what it applied long ago when a channel settles', () async {
    // The housekeeping of a replica belongs to a moment this device is
    // connected and idle, rather than to a launch or a timer of its own. The
    // table grows by a row for every operation this device ever receives and
    // nothing else deletes one.
    await database.syncDao.markApplied(
      '00000009-1111-4111-8111-111111111111',
      at: _at.subtract(const Duration(days: 40)),
    );

    await scheduler.start();
    await until(() => channel.isOpen);

    clock.at = _at.add(const Duration(minutes: 1));

    channel.endWith(
      const AppException(kind: ErrorKind.unavailable, message: 'hung up'),
    );

    await untilGone(
      () => database.syncDao.hasApplied('00000009-1111-4111-8111-111111111111'),
    );

    expect(
      await database.syncDao.hasApplied('00000009-1111-4111-8111-111111111111'),
      isFalse,
    );
  });

  test('forgets the backoff after a channel that lasted', () async {
    // The backoff is reset by a channel that *lasted*, not by one that opened:
    // gRPC dials lazily, so a stream that failed before the node ever answered
    // and one that opened and was closed a moment later are the same two
    // events in the same order, and how long it stayed up is the only evidence
    // this layer has.
    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await scheduler.start();
    await until(
      () =>
          scheduler.status.activity == SyncActivity.waiting &&
          scheduler.status.attempt >= 2,
    );

    expect(scheduler.status.retryIn, greaterThan(scheduler.firstDelay));

    channel.refusesToOpen = null;

    await until(() => channel.isOpen);

    // It stayed up for a minute, and then the node hung up.
    clock.at = _at.add(const Duration(minutes: 1));

    channel.endWith(
      const AppException(kind: ErrorKind.unavailable, message: 'hung up'),
    );

    await until(
      () =>
          scheduler.status.activity == SyncActivity.waiting &&
          scheduler.status.retryIn == scheduler.firstDelay,
      what: 'the backoff was not forgotten by a channel that lasted',
    );

    expect(scheduler.status.attempt, 1);
  });

  test('clears a running backoff when a reader asks', () async {
    // The one way `syncNow` differs from `nudge`, and it is the right one: a
    // reader tapping *synchronize now* is telling this device something it
    // could not have known, and making them wait out the backoff anyway would
    // be the app disbelieving them. The wait is a minute here so that *at
    // once* is not something the test could have got by accident.
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
      now: clock.read,
    );

    addTearDown(loop.dispose);

    channel.refusesToOpen = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node is not answering',
    );

    await loop.start();
    await until(() => loop.status.activity == SyncActivity.waiting);

    channel.refusesToOpen = null;

    await loop.syncNow();

    await until(
      () => channel.isOpen,
      what: 'the reader asked and the loop waited out the backoff anyway',
    );
  });

  test('reports a channel that failed while it was opening', () async {
    // The open returns and the channel is already over: a transport that
    // failed before the loop had subscribed to what would end it. The loop
    // has to read that as a failure rather than as a channel it is serving.
    channel.endsWhileOpening = const AppException(
      kind: ErrorKind.unavailable,
      message: 'the node hung up while dialling',
    );

    await scheduler.start();

    await until(() => scheduler.status.failure != null);

    expect(scheduler.status.failure?.kind, ErrorKind.unavailable);

    // And it goes on trying, rather than sitting on a channel that is gone.
    await until(() => channel.opens >= 2);
  });

  test('stops, and closes what it had open', () async {
    await scheduler.start();
    await until(() => channel.isOpen);

    await scheduler.stop();

    expect(channel.isOpen, isFalse);
    expect(scheduler.status.activity, SyncActivity.idle);
  });
}

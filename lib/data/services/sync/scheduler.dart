/// When this device talks to its node.
///
/// Everything below decides *how* to synchronize. This decides when, and it is
/// the one file in the phase whose correctness is a matter of judgement rather
/// than of the contract.
///
/// **Two conditions gate it, and a third only hurries it.** A live channel is
/// opened while this device is signed in and in the foreground; either going
/// false closes it, and either coming back is a reason to try at once rather
/// than at the next tick.
///
/// Reachability is deliberately **not** the third gate, and the roadmap's *the
/// stream while the app is in the foreground and reachable* is corrected here
/// rather than implemented. `NodeReachability` concludes that a node is
/// answering only from a call that answered, so a loop that refused to connect
/// while it believed otherwise could never learn it was wrong: nothing would
/// call, so nothing would conclude, and the only way out would be an interface
/// physically disappearing and coming back. That is a deadlock on every device
/// whose network never changed — the node was simply down for a minute. So an
/// unreachable node is what the backoff is *for*, and reachability contributes
/// the one thing it can honestly contribute: a hint that clears the wait.
///
/// **Foreground only, on all six targets.** The roadmap's own decision table
/// says so and this file is where it is honoured: a background policy is four
/// different mechanisms — `WorkManager`, `BGTaskScheduler`, a service worker,
/// and nothing at all on the three desktops — and it is a phase of its own
/// rather than a line in this one. What RNF09's periodic reconstruction asks
/// for is met in the foreground: on launch, on resume, and while the app is
/// open. The roadmap said *and a policy for the background on each platform
/// that has one*, which contradicted its own decision table; the table is the
/// later and more considered of the two, and the checkbox has been corrected to
/// match rather than left to be discovered.
///
/// **The backoff is bounded and is reset by evidence, not by hope.** A channel
/// that ended is followed by a wait that doubles up to [longestDelay], and the
/// counter goes back to zero when a channel *lasted* — [settledFor] is the
/// threshold. That is a heuristic and is deliberately not dressed up as
/// anything else: gRPC dials lazily, so a stream that failed before the node
/// ever answered and one that opened and was closed a moment later are the same
/// two events in the same order, and no signal at this layer separates them.
/// How long it stayed up is the only evidence there is.
///
/// **A retry hint jumps the queue.** `NodeReachability` reports the moment an
/// interface appears while the node is believed unreachable, which is not proof
/// of a route but is exactly the moment trying stopped being pointless. It
/// clears the backoff and reconnects, which is what a device coming out of a
/// tunnel needs and what it would otherwise wait five minutes for.
///
/// **Nothing has to remember to tell it.** A change authored anywhere in the
/// app lands in `pending_operations`, and this loop watches that table grow
/// rather than being called by whoever wrote to it. The argument is
/// `ApiClient`'s about reachability, one layer up: a caller that had to
/// remember to announce a write would be a caller that eventually did not, and
/// the one that gets forgotten is always the one added last.
///
/// **It drives the upload queue too.** `upload_queue.dart` says its passes are
/// this loop's to schedule, and this is where that happens: a launch, a
/// reconnection and every reopening run one. C16 is why it matters here rather
/// than at the import — the bytes of a freshly imported book are refused until
/// the operation that created the work has been pushed, and the push and the
/// pass are one connection apart.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../api/reachability.dart';
import '../api/session.dart';
import '../content/upload_queue.dart';
import '../local/database.dart';
import 'live_channel.dart';

final _log = loggerFor('data/sync');

/// Whether this app is in front of the reader.
///
/// It is a plain `Stream<bool>` for the reason `NodeReachability.radio` is one:
/// nothing under `data/` should depend on the framework's lifecycle types, and
/// a test needs to be able to hand this a controller.
///
/// *Inactive* counts as the foreground. It is what a phone call, an app
/// switcher or a system dialog looks like, and closing a stream for the two
/// seconds a reader spends in the switcher would be closing it because they
/// looked away.
Stream<bool> appForeground() {
  late final StreamController<bool> lifecycle;
  late final AppLifecycleListener listener;

  lifecycle = StreamController<bool>.broadcast(
    onListen: () {
      listener = AppLifecycleListener(
        onStateChange: (AppLifecycleState state) => lifecycle.add(
          state == AppLifecycleState.resumed ||
              state == AppLifecycleState.inactive,
        ),
      );
    },
    onCancel: () => listener.dispose(),
  );

  return lifecycle.stream;
}

/// What the loop is doing.
enum SyncActivity {
  /// Not trying, and not waiting to: signed out, in the background, or
  /// stopped.
  idle('idle'),

  /// Opening a channel.
  connecting('connecting'),

  /// A channel is open. It is not a promise that the node has answered — see
  /// the note on the backoff — but it is the state in which anything authored
  /// here goes out at once.
  live('live'),

  /// A channel ended and the next attempt is waiting out its backoff.
  waiting('waiting');

  const SyncActivity(this.label);

  /// The name of the state, for a log line and a failing test.
  final String label;

  @override
  String toString() => label;
}

/// Where the loop stands.
final class SyncStatus {
  /// The state, with what ended the last attempt and how long until the next.
  const SyncStatus({
    required this.activity,
    this.failure,
    this.retryIn,
    this.attempt = 0,
  });

  /// What the loop is doing.
  final SyncActivity activity;

  /// What ended the last attempt, or `null` where nothing has gone wrong.
  ///
  /// It survives into [SyncActivity.live], so that a screen can say *it is
  /// working now, and this is what was wrong before*. It is cleared by a
  /// channel that settled.
  final AppException? failure;

  /// How long until the next attempt, while [activity] is
  /// [SyncActivity.waiting].
  final Duration? retryIn;

  /// How many attempts have ended without one lasting.
  final int attempt;

  @override
  String toString() =>
      'SyncStatus($activity${failure == null ? '' : ', $failure'}'
      '${retryIn == null ? '' : ', retrying in $retryIn'})';
}

/// The loop that opens a channel, keeps it open, and reopens it.
final class SyncScheduler {
  /// The loop over [channel], watching [session], [reachability] and
  /// [foreground], and driving [uploads] beside it.
  SyncScheduler({
    required this.database,
    required this.channel,
    required this.session,
    required this.reachability,
    required this.uploads,
    Stream<bool>? foreground,
    this.firstDelay = const Duration(seconds: 2),
    this.longestDelay = const Duration(minutes: 5),
    this.settledFor = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _foreground = foreground ?? appForeground(),
       _now = now ?? DateTime.now;

  /// Where the cursor and the outbox live.
  final AtrilDatabase database;

  /// The live channel this build uses, which is the bidirectional stream on
  /// the five native targets and the watch in a browser.
  final SyncChannel channel;

  /// Whether this device holds a credential it could still exchange.
  final SessionHolder session;

  /// Whether the node is believed to be answering.
  final NodeReachability reachability;

  /// The files this device still owes, which this loop is what drives.
  final UploadQueue uploads;

  /// The first wait after a channel ends.
  final Duration firstDelay;

  /// The longest one it grows to.
  final Duration longestDelay;

  /// How long a channel must last for the backoff to be forgotten.
  final Duration settledFor;

  final Stream<bool> _foreground;
  final DateTime Function() _now;

  final StreamController<SyncStatus> _statuses =
      StreamController<SyncStatus>.broadcast();

  StreamSubscription<bool>? _foregroundEvents;
  StreamSubscription<bool>? _reachabilityEvents;
  StreamSubscription<void>? _hints;
  StreamSubscription<bool>? _sessionEvents;
  StreamSubscription<int>? _outbox;
  Timer? _retry;

  bool _started = false;
  bool _inForeground = true;
  bool _reachable = true;
  bool _signedIn = false;
  bool _connecting = false;
  int _attempt = 0;
  int _owed = 0;

  SyncStatus _status = const SyncStatus(activity: SyncActivity.idle);

  /// Where the loop stands, now.
  SyncStatus get status => _status;

  /// Where the loop stands, now and whenever it changes.
  ///
  /// Each listener is given the current value first, as
  /// [NodeReachability.changes] is and for the same reason: a screen built
  /// after the fact has something to show rather than a blank until the state
  /// next moves.
  Stream<SyncStatus> get statuses =>
      Stream<SyncStatus>.multi((MultiStreamController<SyncStatus> listener) {
        listener.add(_status);

        final subscription = _statuses.stream.listen(
          listener.add,
          onDone: listener.close,
        );

        listener.onCancel = subscription.cancel;
      });

  /// Starts the loop.
  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    _signedIn = await session.isSignedIn;

    _foregroundEvents = _foreground.listen(_onForeground);
    _reachabilityEvents = reachability.changes.listen(_onReachable);
    _sessionEvents = session.signedIn.listen(_onSession);
    _hints = reachability.retryHints.listen((void _) => _retryNow());
    _outbox = database.syncDao.watchPendingCount().listen(_onOwed);

    _log.info('the sync loop has started');

    _consider();
  }

  /// Stops it, and closes whatever is open.
  Future<void> stop() async {
    if (!_started) {
      return;
    }

    _started = false;
    _retry?.cancel();
    _retry = null;

    await _foregroundEvents?.cancel();
    await _reachabilityEvents?.cancel();
    await _sessionEvents?.cancel();
    await _hints?.cancel();
    await _outbox?.cancel();
    await channel.close();

    _publish(const SyncStatus(activity: SyncActivity.idle));

    _log.info('the sync loop has stopped');
  }

  /// Releases the loop and its status stream.
  Future<void> dispose() async {
    await stop();
    await _statuses.close();
  }

  /// Records that the outbox holds [owed] changes.
  ///
  /// It hands over only when the number went *up*. A count that fell is this
  /// loop's own push retiring what it just delivered, and answering that with
  /// another push would be a device talking to itself.
  void _onOwed(int owed) {
    final grew = owed > _owed;

    _owed = owed;

    if (grew) {
      unawaited(nudge());
    }
  }

  /// Hands over a change that has just been authored here.
  ///
  /// A channel that is open takes it now. One that is not is a reason to try
  /// connecting, and never a reason to skip a backoff that is already running:
  /// a reader writing a note does not make an unreachable node reachable.
  Future<void> nudge() async {
    if (channel.isOpen) {
      await channel.offer();

      return;
    }

    _consider();
  }

  /// Whether the two conditions hold. Reachability is not among them — see the
  /// note at the top of this file.
  bool get _mayConnect => _started && _signedIn && _inForeground;

  void _consider() {
    if (!_mayConnect || _connecting || channel.isOpen || _retry != null) {
      return;
    }

    unawaited(_connect());
  }

  Future<void> _connect() async {
    _connecting = true;
    _publish(SyncStatus(activity: SyncActivity.connecting, attempt: _attempt));

    final openedAt = _now();

    try {
      await channel.open();

      // What ended the channel is caught *here*, on the line after it opened,
      // and read after the writes below. A future completed with an error and
      // not yet listened to is an unhandled error in Dart, and the two writes
      // between opening and awaiting are long enough for a node that hangs up
      // at once to land in that gap.
      Object? ending;
      StackTrace? endingTrace;

      final ended = channel.done.then<void>(
        (void _) {},
        onError: (Object error, StackTrace trace) {
          ending = error;
          endingTrace = trace;
        },
      );

      _publish(
        SyncStatus(
          activity: SyncActivity.live,
          failure: _status.failure,
          attempt: _attempt,
        ),
      );

      // The two things a connection is worth beyond the channel itself: the
      // files this device owes, which C16 refuses until the record has been
      // pushed, and the note that this device reached its node — which is what
      // a reader is shown and what a pull alone would not move on a log that
      // has not grown.
      await uploads.run();
      await _recordExchange();

      await ended;

      final failure = ending;

      if (failure != null) {
        _log.info('the sync channel ended: $failure', failure, endingTrace);
        _publish(
          SyncStatus(activity: _status.activity, failure: _failureOf(failure)),
        );
      } else {
        _publish(SyncStatus(activity: _status.activity, attempt: _attempt));
      }
    } on Object catch (error, trace) {
      final failure = _failureOf(error);

      _log.info('the sync channel could not be opened: $failure', error, trace);
      _publish(SyncStatus(activity: _status.activity, failure: failure));
    } finally {
      _connecting = false;

      await channel.close();

      _reschedule(lasted: _now().difference(openedAt));
    }
  }

  /// Waits before the next attempt, or goes idle where it may not make one.
  void _reschedule({required Duration lasted}) {
    if (!_mayConnect) {
      _publish(
        SyncStatus(activity: SyncActivity.idle, failure: _status.failure),
      );

      return;
    }

    if (lasted >= settledFor) {
      // It lasted. Whatever ended it is not the node refusing to be reached,
      // and the next failure starts counting from one again.
      _attempt = 0;
    }

    final delay = _delayFor(_attempt);

    _attempt++;

    _publish(
      SyncStatus(
        activity: SyncActivity.waiting,
        failure: _status.failure,
        retryIn: delay,
        attempt: _attempt,
      ),
    );

    _retry = Timer(delay, () {
      _retry = null;

      _consider();
    });
  }

  /// The wait after [attempt] endings, doubling and bounded.
  Duration _delayFor(int attempt) {
    var delay = firstDelay;

    for (var doubled = 0; doubled < attempt; doubled++) {
      delay *= 2;

      if (delay >= longestDelay) {
        return longestDelay;
      }
    }

    return delay;
  }

  /// Tries now, whatever the backoff had decided.
  ///
  /// It does not consult reachability, which is the point of it: a hint fires
  /// exactly while the node is believed unreachable, and a retry that waited
  /// for that belief to change would wait for a call that nobody is making.
  void _retryNow() {
    if (!_mayConnect || channel.isOpen || _connecting) {
      return;
    }

    _log.fine('a retry hint arrived; the backoff is cleared');

    _retry?.cancel();
    _retry = null;
    _attempt = 0;

    _consider();
  }

  void _onForeground(bool present) {
    if (_inForeground == present) {
      return;
    }

    _inForeground = present;

    if (present) {
      // Coming back is a reason to try at once. A reader who reopens the app
      // to look at their notes should not be looking at a backoff that started
      // while it was closed.
      _retryNow();

      return;
    }

    unawaited(_stand(down: 'the app went into the background'));
  }

  /// Records what the reachability state now says.
  ///
  /// A node that stopped answering closes nothing and stops nothing: whatever
  /// concluded that was a call that failed, the channel is ending on its own,
  /// and the backoff below is the whole of the right response. A node that
  /// started answering is worth trying at once.
  void _onReachable(bool reachable) {
    if (_reachable == reachable) {
      return;
    }

    _reachable = reachable;

    if (reachable) {
      _retryNow();
    }
  }

  void _onSession(bool signedIn) {
    if (_signedIn == signedIn) {
      return;
    }

    _signedIn = signedIn;

    if (signedIn) {
      _retryNow();

      return;
    }

    unawaited(_stand(down: 'the session ended'));
  }

  /// Closes the channel and stops waiting, because a condition went false.
  Future<void> _stand({required String down}) async {
    _log.fine('the sync loop is standing down: $down');

    _retry?.cancel();
    _retry = null;

    await channel.close();

    _publish(SyncStatus(activity: SyncActivity.idle, failure: _status.failure));
  }

  Future<void> _recordExchange() async {
    final origin = await database.identityDao.originServer();

    if (origin == null) {
      return;
    }

    await database.syncDao.recordExchange(origin.domain, at: _now());
  }

  AppException _failureOf(Object error) => error is AppException
      ? error
      : AppException(kind: ErrorKind.unknown, message: '$error');

  void _publish(SyncStatus status) {
    _status = status;

    if (!_statuses.isClosed) {
      _statuses.add(status);
    }
  }
}

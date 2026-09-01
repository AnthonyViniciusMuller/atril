/// The live channel of the five native targets: `Sync`, held open.
///
/// It is the same push and pull the two unary calls serve, kept open, so that a
/// change made on one device reaches the reader's others as it happens rather
/// than at the next poll — and so that a device which has just reconnected
/// drains its backlog through the stream it then leaves open. UC10 and UC11 in
/// one call.
///
/// **The acknowledgement is sent after the write commits.** That is the whole
/// of what `SyncAck` means in this contract and the one thing a client can get
/// wrong without noticing: the node keeps at most one page in flight and
/// advances the device's cursor on the confirmation rather than on what it
/// sent, because an operation written to a socket is not an operation written
/// to disk and a device that dies between the two must come back to the same
/// place. So the order here is reconcile, move the cursor, *then* acknowledge,
/// and never any other.
///
/// A client that never acknowledged would receive one page and then only what
/// its own pushes provoked. That is not a bug the node would report; it is a
/// device that silently stops hearing from the reader's other ones.
///
/// **One batch is offered at a time.** The stream is not a queue this device
/// can fill: a batch goes out, its verdicts come back, and whether they moved
/// the head of the outbox decides whether another follows. A batch that moved
/// nothing stops the pump, for the same reason the unary drain stops — the next
/// read would return the same operations, and offering them again is offering
/// them for ever.
///
/// **It is not reachable from a browser**, because gRPC-Web carries a unary
/// call and a server stream and neither of the other two. `watch.dart` is what
/// answers it there, and which of the two a build uses is decided where the
/// graph is composed. Nothing in this file is web-specific and nothing in it
/// fails to compile for the web; what fails is the call, at run time, which is
/// why the choice is made once rather than discovered per install.
library;

import 'dart:async';

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../api/sync_api.dart';
import '../local/database.dart';
import 'live_channel.dart';
import 'push.dart';
import 'reconciler.dart';

final _log = loggerFor('data/sync');

/// The operation the stream reports a missing precondition under.
const String opStreamOpen = 'sync/stream: open';

/// How long a close waits for the node to end the stream before hanging up.
///
/// Half-closing and hanging up in the same breath is a device saying it has
/// stopped talking and then cutting the line before the node has finished
/// hearing it — and what a node does with the frames still in the air is
/// discard the stream they belonged to, including an acknowledgement that had
/// already been earned. So the outbound half is closed, the node is given this
/// long to end the stream itself, and the hang-up is what happens when it does
/// not.
const Duration streamCloseGrace = Duration(seconds: 2);

/// One open `Sync` stream, and the cursor it maintains.
final class SyncStream implements SyncChannel {
  /// The stream over [database], talking to [api] and applying through
  /// [reconciler].
  SyncStream({
    required this.database,
    required this.api,
    required this.reconciler,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Where the replica, the outbox and the cursor live.
  final AtrilDatabase database;

  /// The node this stream is held against.
  final SyncApi api;

  /// What applies an operation, exactly as it is applied on every other
  /// replica.
  final Reconciler reconciler;

  final DateTime Function() _now;

  StreamController<SyncCommand>? _commands;
  StreamSubscription<SyncEvent>? _events;
  Completer<void>? _ended;
  Completer<void>? _settled;
  String _node = '';
  int _cursor = 0;
  final Set<String> _offered = <String>{};

  @override
  bool get isOpen => _commands != null;

  /// Where this device's cursor into the node's log stands.
  int get cursor => _cursor;

  /// Opens the stream, sends the cursor, and hands over what this device owes.
  ///
  /// It completes there. Serving the stream is what happens afterwards, and
  /// [done] is what says when that stopped and why.
  @override
  Future<void> open() async {
    if (isOpen) {
      _log.fine('a sync stream is already open');

      return;
    }

    _node = await _originDomain();
    _cursor = await database.syncDao.cursor(_node);

    final commands = StreamController<SyncCommand>();
    final ended = Completer<void>();
    final settled = Completer<void>();

    _commands = commands;
    _ended = ended;
    _settled = settled;
    _offered.clear();

    // The cursor, first and exactly once. A stream that began with a push
    // would be a device asking the node to store changes without saying where
    // it had got to.
    commands.add(SyncStart(afterPosition: _cursor));

    _events = api
        .sync(commands.stream)
        .listen(
          _receive,
          onError: (Object error, StackTrace trace) {
            _settle(settled);
            _end(error: error, trace: trace);
          },
          onDone: () {
            _settle(settled);
            _end();
          },
          cancelOnError: true,
        );

    _log.fine('a sync stream is open on $_node from $_cursor');

    // What this device already owes goes out on the stream it then leaves
    // open, which is the whole of UC11: a reconnection is a backlog and then
    // an ordinary stream.
    await offer();
  }

  @override
  Future<void> get done => _ended?.future ?? Future<void>.value();

  /// Offers the next batch this device owes, if the stream is idle.
  ///
  /// The scheduler calls it when a change is authored. It does nothing while a
  /// batch is in flight: the verdicts for that one are what decide whether
  /// another follows, and two batches in flight would be this device guessing
  /// at an order the node has not confirmed.
  @override
  Future<void> offer() async {
    final commands = _commands;

    if (commands == null || _offered.isNotEmpty) {
      return;
    }

    final batch = await database.syncDao.pending(limit: pushBatchSize);

    if (batch.isEmpty) {
      return;
    }

    if (commands.isClosed) {
      return;
    }

    _offered.addAll(batch.map((operation) => operation.id));

    commands.add(SyncPush(batch));
  }

  /// Ends the stream.
  ///
  /// The state is released *before* the outbound half is closed, and the order
  /// is not cosmetic: a delivery may still be part way through being applied,
  /// and it ends by acknowledging. Releasing first is what turns that
  /// acknowledgement into a no-op instead of a write to a closed sink.
  ///
  /// The state is released first, then the outbound half is closed, then the
  /// node is given [streamCloseGrace] to end the stream itself. Only after that
  /// is the call hung up. The order is the whole of what makes a close graceful
  /// rather than a discarded acknowledgement — see [streamCloseGrace].
  @override
  Future<void> close() async {
    final commands = _commands;
    final events = _events;
    final settled = _settled;

    if (commands == null) {
      return;
    }

    _end();

    await commands.close();
    await settled?.future.timeout(
      streamCloseGrace,
      onTimeout: () => _log.info('the node did not end the stream; hanging up'),
    );
    await events?.cancel();
  }

  void _settle(Completer<void> settled) {
    if (!settled.isCompleted) {
      settled.complete();
    }
  }

  void _receive(SyncEvent event) {
    // The handler writes to the database, and the events behind it must wait:
    // an acknowledgement is a promise about a commit, and two deliveries
    // applied at once would let the second one's promise be made before the
    // first one's write. Pausing the subscription is what makes the stream
    // sequential without a queue of its own.
    _events?.pause(
      _handle(event).catchError(
        (Object error, StackTrace trace) => _end(error: error, trace: trace),
      ),
    );
  }

  Future<void> _handle(SyncEvent event) async {
    switch (event) {
      case SyncDelivery(:final operations, :final lastPosition):
        await reconciler.reconcileAll(operations);

        if (lastPosition > _cursor) {
          _cursor = lastPosition;

          await database.syncDao.advanceCursor(_node, _cursor, at: _now());
        }

        // Last, and only now. Everything above is on disk, and this is what
        // says so.
        _send(SyncAck(position: _cursor));

      case SyncVerdicts(:final results):
        final settlement = await settle(database, results);

        _offered.clear();

        if (!settlement.movedTheQueue) {
          // The head of the outbox did not move, so the next batch would be
          // the same one. A refusal does move it — the change is quarantined
          // and stops being offered — so what reaches here is a batch answered
          // entirely with verdicts this build cannot name.
          _log.warning('a batch of ${results.length} moved nothing');

          return;
        }

        await offer();
    }
  }

  /// Sends [command] if the stream is still open.
  ///
  /// Everything outbound goes through here because everything outbound is sent
  /// after an await: a stream that ended while a delivery was being applied is
  /// the ordinary case and not a failure to report.
  void _send(SyncCommand command) {
    final commands = _commands;

    if (commands == null || commands.isClosed) {
      return;
    }

    commands.add(command);
  }

  void _end({Object? error, StackTrace? trace}) {
    final ended = _ended;

    _commands = null;
    _ended = null;
    _offered.clear();

    if (ended == null || ended.isCompleted) {
      return;
    }

    if (error == null) {
      _log.fine('the sync stream ended');
      ended.complete();

      return;
    }

    _log.info('the sync stream ended: $error');
    ended.completeError(error, trace ?? StackTrace.current);
  }

  /// The node whose log this stream is held against.
  Future<String> _originDomain() async {
    final origin = await database.identityDao.originServer();

    if (origin == null) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'this device is not signed in at any node and cannot sync',
        code: 'no_origin_server',
        op: opStreamOpen,
      );
    }

    return origin.domain;
  }
}

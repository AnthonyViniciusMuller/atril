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

  // The two halves of the call, and whether it is still being served. They
  // are separate because they are released at different moments: ending the
  // channel stops it being served, and only a close hangs it up — a delivery
  // that failed does the first and cannot do the second, and a close that
  // asked *is there still a sink* would find one already released and leave
  // the call open behind it.
  StreamController<SyncCommand>? _commands;
  StreamSubscription<SyncEvent>? _events;
  bool _live = false;
  Completer<void>? _ended;
  Completer<void>? _settled;
  String _node = '';
  int _cursor = 0;
  final Set<String> _offered = <String>{};

  @override
  bool get isOpen => _live;

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
    _live = true;
    _ended = ended;

    // Nobody is listening yet, and the channel can end before anybody is: the
    // scheduler subscribes on the line after `open()` returns. A future
    // completed with an error and no listener is an unhandled error in Dart,
    // so one is attached here and the real listener still receives what ended
    // it when it arrives.
    unawaited(ended.future.catchError((Object _) {}));

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

  /// Completes when the channel ends, carrying whatever ended it.
  ///
  /// The completer **survives the end and is replaced by the next [open]**.
  /// One that was cleared as it completed would answer every caller that
  /// arrived afterwards with a channel that ended cleanly, and a transport
  /// that failed while this device was still opening is exactly that caller's
  /// case: the loop above asks on the line after the open returns.
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

    if (!_live || commands == null || _offered.isNotEmpty) {
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
  ///
  /// **What it asks is whether anything is still held**, and never whether the
  /// channel is still being served. A delivery that failed ends the channel
  /// and stops it being served while the call is still open, and a close that
  /// read that as *already closed* would leave the subscription subscribed and
  /// the node holding a stream nobody is on the other end of.
  @override
  Future<void> close() async {
    final commands = _commands;
    final events = _events;
    final settled = _settled;

    if (commands == null && events == null) {
      return;
    }

    _end();

    _commands = null;
    _events = null;

    // The half-close is sent and not waited on. What it has to do is reach the
    // node, and what says it arrived is the node ending the stream — which is
    // the wait below. Waiting on the sink itself would hang a close whose
    // transport had already failed, because a request stream nobody is reading
    // any more never finishes closing.
    unawaited(commands?.close());

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
    // Anything arriving on the stream is the node answering, and that is what
    // *last reached the node* is a fact about. Opening is not: gRPC dials
    // lazily, so a channel this device has set up is not a channel anybody has
    // replied on.
    await database.syncDao.recordExchange(_node, at: _now());

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

    if (!_live || commands == null || commands.isClosed) {
      return;
    }

    commands.add(command);
  }

  void _end({Object? error, StackTrace? trace}) {
    final ended = _ended;

    // What ends here is the *serving* of the channel. The call itself is hung
    // up by [close], which is the only place that releases either half, and
    // the completer stays until the next open so that a caller arriving after
    // the fact is told what ended it.
    _live = false;
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

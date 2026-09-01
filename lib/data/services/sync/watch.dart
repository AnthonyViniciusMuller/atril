/// The live channel of the web: `WatchOperations`, and the two unary calls
/// beside it.
///
/// gRPC-Web carries a unary call and a server stream and neither of the other
/// two, so `Sync` is unreachable from a browser. The node grew a replacement
/// rather than leaving the web target degraded, and the replacement is a
/// different *kind* of thing, which is the whole of what this file has to get
/// right.
///
/// **It is a notification and not a delivery.** Each response carries the
/// node's head position and never an operation. So the handler does one thing:
/// compare that number against this device's cursor, and pull if it is behind.
/// There is no acknowledgement to send, because the node holds nothing in
/// flight for this caller — it is reporting a number it would report again on
/// the next notification — and a notification that is missed costs a poll
/// rather than an operation.
///
/// **A quiet stream is not a broken one.** gRPC sends no response headers until
/// the handler sends its first message, and `WatchOperations` sends nothing
/// while the head has not moved past the caller's cursor. A browser watching a
/// quiet log therefore has a fetch that has not resolved — indistinguishable,
/// in any client API, from a stream that is open and idle. Reconnecting on a
/// timer would be reconnecting because nothing has happened. Asking from the
/// cursor is what makes a node that *is* ahead answer at once, and on a freshly
/// bound device that cursor is zero, which is the case the node's own comment
/// is written about.
///
/// **Closing needs no ceremony.** The stream has one direction, so there is
/// nothing in the air to lose and no half-close to order against a hang-up —
/// which is the one thing that is simpler here than on the bidirectional
/// stream.
library;

import 'dart:async';

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../api/sync_api.dart';
import '../local/database.dart';
import 'live_channel.dart';
import 'pull.dart';
import 'push.dart';

final _log = loggerFor('data/sync');

/// The operation the watch reports a missing precondition under.
const String opWatchOpen = 'sync/watch: open';

/// The web's live channel: a watch, a pull behind it, and a unary push.
final class WatchChannel implements SyncChannel {
  /// The channel over [database], watching [api], reading through [puller] and
  /// handing over through [pusher].
  WatchChannel({
    required this.database,
    required this.api,
    required this.puller,
    required this.pusher,
  });

  /// Where the cursor lives.
  final AtrilDatabase database;

  /// The node being watched.
  final SyncApi api;

  /// What collects the operations a notification says exist.
  final OperationPuller puller;

  /// What hands over the operations this device owes. It is a separate call
  /// here and a message on the native stream, which is the whole difference
  /// between the two channels.
  final OperationPusher pusher;

  StreamSubscription<int>? _events;
  Completer<void>? _ended;
  String _node = '';

  @override
  bool get isOpen => _ended != null;

  /// Opens the watch and hands over what this device owes.
  ///
  /// It completes there. [done] is what says when the watch stopped and why.
  @override
  Future<void> open() async {
    if (isOpen) {
      _log.fine('a watch is already open');

      return;
    }

    _node = await _originDomain();

    final cursor = await database.syncDao.cursor(_node);

    _ended = Completer<void>();

    _events = api
        .watch(afterPosition: cursor)
        .listen(
          _notified,
          onError: (Object error, StackTrace trace) =>
              _end(error: error, trace: trace),
          onDone: _end,
          cancelOnError: true,
        );

    _log.fine('a watch is open on $_node from $cursor');

    // What this device already owes goes over before it starts listening for
    // what it is missing, which is the same order the bidirectional stream
    // sends its first push in.
    await offer();
  }

  @override
  Future<void> get done => _ended?.future ?? Future<void>.value();

  @override
  Future<void> offer() async {
    if (!isOpen) {
      return;
    }

    await pusher.run();
  }

  @override
  Future<void> close() async {
    final events = _events;

    if (events == null) {
      return;
    }

    _end();

    await events.cancel();
  }

  void _notified(int head) {
    // The pull writes to the database and the notifications behind it must
    // wait: two catch-ups at once would be two passes over one cursor.
    _events?.pause(
      _catchUp(head).catchError(
        (Object error, StackTrace trace) => _end(error: error, trace: trace),
      ),
    );
  }

  /// Pulls if [head] is past where this device has read to.
  ///
  /// A catch-up that fails ends the channel rather than being swallowed. The
  /// node notifies when its log grows and not otherwise, so a failure kept
  /// quiet here is a device that stays behind until something else happens to
  /// be written — and the scheduler above reopens, which asks from the cursor
  /// and is answered at once.
  Future<void> _catchUp(int head) async {
    if (head <= await database.syncDao.cursor(_node)) {
      // The node is telling this device about a position it already holds,
      // which is what a notification that crossed a pull looks like.
      return;
    }

    await puller.run();
  }

  void _end({Object? error, StackTrace? trace}) {
    final ended = _ended;

    _ended = null;

    if (ended == null || ended.isCompleted) {
      return;
    }

    if (error == null) {
      _log.fine('the watch ended');
      ended.complete();

      return;
    }

    _log.info('the watch ended: $error');
    ended.completeError(error, trace ?? StackTrace.current);
  }

  /// The node whose log this device is watching.
  Future<String> _originDomain() async {
    final origin = await database.identityDao.originServer();

    if (origin == null) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'this device is not signed in at any node and cannot watch',
        code: 'no_origin_server',
        op: opWatchOpen,
      );
    }

    return origin.domain;
  }
}

/// Collecting from a node everything this device has not seen.
///
/// This is the inbound half of UC09 and the whole of RN06: everything after the
/// cursor, in order, through the reconciler, and then the cursor moved.
///
/// **The cursor is advanced after the batch is committed and not after it is
/// received.** An operation read from a socket is not an operation written to
/// disk, and a device that dies between the two must come back to the same
/// place. That is why the write below is the last thing a page does and why it
/// is not folded into the loop that reads the next one.
///
/// Re-reading a page this device has already applied costs a decode and nothing
/// else: `applied_operations` recognizes every operation by the identifier its
/// author minted, so the whole page comes back `duplicate` and the replica is
/// untouched. That is what makes the ordering above safe rather than merely
/// careful.
///
/// **`has_more` is a loop and not a recursion.** A device that has been away
/// for a month asks for as many pages as the log has grown by, and a recursion
/// over that is a stack whose depth is somebody else's writing habits.
///
/// **The cursor is keyed by the node.** A position is *that node's* order for
/// the reader's log, so a device that pulls from its origin and from a replica
/// keeps two numbers with nothing to do with each other. The one this file uses
/// is the origin's, because that is the only node this app dials until phase
/// 12 gives it more.
library;

import '../../../utils/logging.dart';
import '../api/sync_api.dart';
import '../local/database.dart';
import 'origin.dart';
import 'reconciler.dart';

final _log = loggerFor('data/sync');

/// The operation a pull reports a missing precondition under.
const String opPullRun = 'sync/pull: run';

/// How many operations one page asks for.
///
/// The node's own page is five hundred; this is smaller for the reason the
/// seed's page is smaller than the node's, and it is the same reason: a device
/// filling a replica over a mobile connection loses less to a page it has to
/// ask for twice.
const int pullPageSize = 100;

/// What one pass over a node's log did here.
final class PullRun {
  /// A pass that received [received] operations, of which [applied],
  /// [duplicate], [superseded] and [refused], leaving the cursor at [cursor].
  const PullRun({
    this.received = 0,
    this.applied = 0,
    this.duplicate = 0,
    this.superseded = 0,
    this.refused = 0,
    this.cursor = 0,
  });

  /// How many operations the node handed over.
  final int received;

  /// How many changed a record here.
  final int applied;

  /// How many this device had already applied, by identifier.
  final int duplicate;

  /// How many lost the merge against a version this replica already held.
  final int superseded;

  /// How many this replica could not hold. The detail is in the log; a
  /// refusal here is a fault in this build or a record from a version of the
  /// contract it does not know, and neither is a reader's to act on.
  final int refused;

  /// Where this device's cursor into that node's log now stands.
  final int cursor;

  /// Whether the pass brought anything back.
  bool get isEmpty => received == 0;

  @override
  String toString() =>
      'PullRun($received received: $applied applied, $duplicate duplicate, '
      '$superseded superseded, $refused refused, cursor $cursor)';
}

/// Reads a node's log into the replica.
final class OperationPuller {
  /// The pull over [database], asking [api] and applying through
  /// [reconciler].
  OperationPuller({
    required this.database,
    required this.api,
    required this.reconciler,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Where the replica and the cursor live.
  final AtrilDatabase database;

  /// The node being read.
  final SyncApi api;

  /// What applies an operation, exactly as it is applied on every other
  /// replica.
  final Reconciler reconciler;

  final DateTime Function() _now;

  bool _running = false;

  /// Whether a pass is in flight.
  bool get isRunning => _running;

  /// Reads everything after this device's cursor, a page at a time.
  ///
  /// It throws what the call threw, and a pass that fails part way keeps every
  /// page it committed: the cursor moved after each of them.
  Future<PullRun> run({int pageSize = pullPageSize}) async {
    if (_running) {
      _log.fine('a pull is already running');

      return const PullRun();
    }

    _running = true;

    try {
      final node = await database.originDomain(op: opPullRun);

      var cursor = await database.syncDao.cursor(node);
      var received = 0;
      var applied = 0;
      var duplicate = 0;
      var superseded = 0;
      var refused = 0;

      while (true) {
        final page = await api.pull(afterPosition: cursor, limit: pageSize);

        if (page.operations.isEmpty) {
          break;
        }

        for (final verdict in await reconciler.reconcileAll(page.operations)) {
          received++;

          switch (verdict.outcome) {
            case ReconcileOutcome.applied:
              applied++;
            case ReconcileOutcome.duplicate:
              duplicate++;
            case ReconcileOutcome.superseded:
              superseded++;
            case ReconcileOutcome.rejected:
              refused++;
          }
        }

        if (page.lastPosition <= cursor) {
          // The page carried operations and did not move the cursor past them,
          // so asking again would ask for the same page. It is a node this
          // build cannot follow rather than a log it has caught up with, and
          // saying so is better than spinning.
          _log.warning(
            'a page of ${page.operations.length} left the cursor at $cursor',
          );

          break;
        }

        cursor = page.lastPosition;

        // Last, and outside nothing: the operations above are on disk, and the
        // cursor is what says so.
        await database.syncDao.advanceCursor(node, cursor, at: _now());

        if (!page.hasMore) {
          break;
        }
      }

      final run = PullRun(
        received: received,
        applied: applied,
        duplicate: duplicate,
        superseded: superseded,
        refused: refused,
        cursor: cursor,
      );

      if (!run.isEmpty) {
        _log.info('$run');
      }

      return run;
    } finally {
      _running = false;
    }
  }
}

/// Handing a node the changes this device authored.
///
/// This is the outbound half of UC09 and the whole of what C21 makes
/// necessary. Every screen in this app writes through the operation author,
/// which appends to `pending_operations`; nothing else ever reaches a node.
/// This file is what drains that table, in the order it was written, and it is
/// deliberately the only thing that does.
///
/// **The order is the whole of the correctness here.** The outbox is ordered by
/// the sequence sqlite assigned, which is the order this device authored in, and
/// a log whose updates arrive before their inserts is a log the node refuses
/// half of. So a batch is offered as it comes out of the table and the next one
/// is only read after the first has been answered for.
///
/// **The four outcomes are handled distinctly, and three of them retire the
/// operation.** *Applied* is the ordinary one. *Duplicate* means the node
/// already had it — from an earlier push whose reply this device never saw, or
/// from a peer that also replicates the reader — and it is the normal shape of
/// a federation rather than a fault. *Superseded* means the node stored it and
/// it lost the merge there; the replica is left exactly as it is, because a
/// change that lost on the node lost on the same rule this device would apply
/// and re-applying anything would be undoing a merge that already happened.
/// Only *rejected* stays, and phase 11's quarantine is what stops it being
/// offered again for ever.
///
/// **An outcome this build cannot name retires nothing.** A node running a
/// later version of the contract may answer with a fifth verdict, and the one
/// thing that is certainly wrong is to guess: the operation stays in the outbox
/// and is offered again, where the worst that happens is a `duplicate`.
///
/// It never decides *when* to run. That is the scheduler's, and the callers
/// until it lands are a test and the sync surface's *try again*.
library;

import '../../../domain/models/operation.dart';
import '../../../utils/logging.dart';
import '../api/sync_api.dart';
import '../local/database.dart';

final _log = loggerFor('data/sync');

/// How many operations one push offers.
///
/// The node's own page is five hundred, and this is smaller on purpose: it is
/// what a device on the network RNF01 is written about has to get across in one
/// call before anything is retired, and a batch it has to send twice costs less
/// when it is small.
const int pushBatchSize = 100;

/// What a set of verdicts came to, and what it retired.
final class Settlement {
  /// The tally.
  const Settlement({
    required this.applied,
    required this.duplicate,
    required this.superseded,
    required this.refused,
    required this.retired,
  });

  /// Stored by the node, and it changed the record there.
  final int applied;

  /// Already in the node's log, by identifier.
  final int duplicate;

  /// Stored, and it lost the merge there.
  final int superseded;

  /// Refused, and therefore still owed.
  final int refused;

  /// How many operations left the outbox.
  final int retired;

  /// How many verdicts this build could name.
  int get answered => applied + duplicate + superseded + refused;
}

/// Retires what [results] says a node has, and tallies the four outcomes.
///
/// It is shared by the unary push and by the bidirectional stream, because the
/// verdicts mean the same thing on both and a second reading of them would be a
/// second set of rules for when this device stops owing a change. Only the
/// stream's arrive without the batch that provoked them, which is why this
/// counts what it was told about rather than what was offered.
Future<Settlement> settle(
  AtrilDatabase database,
  Iterable<OperationResult> results,
) async {
  var applied = 0;
  var duplicate = 0;
  var superseded = 0;
  var refused = 0;

  final retiring = <String>[];

  for (final result in results) {
    switch (result.outcome) {
      case OperationOutcome.applied:
        applied++;
        retiring.add(result.operationId);
      case OperationOutcome.duplicate:
        duplicate++;
        retiring.add(result.operationId);
      case OperationOutcome.superseded:
        // Nothing is written back. The node kept the operation and the record
        // there already held a version this one does not beat, which is a
        // verdict on a merge and not a correction to make here.
        superseded++;
        retiring.add(result.operationId);
      case OperationOutcome.rejected:
        refused++;
      case null:
        // A verdict this build cannot name retires nothing. A node running a
        // later contract may answer with a fifth, and the one thing that is
        // certainly wrong is to guess.
        _log.warning('a node answered $result');
    }
  }

  return Settlement(
    applied: applied,
    duplicate: duplicate,
    superseded: superseded,
    refused: refused,
    retired: await database.syncDao.retire(retiring),
  );
}

/// What one pass over the outbox did.
final class PushRun {
  /// A pass with [applied], [duplicate] and [superseded] retired, [refused]
  /// left behind, and the node's head at [lastPosition].
  const PushRun({
    this.applied = 0,
    this.duplicate = 0,
    this.superseded = 0,
    this.refused = 0,
    this.unanswered = 0,
    this.lastPosition = 0,
  });

  /// Stored by the node, and it changed the record there.
  final int applied;

  /// Already in the node's log, by the identifier this device minted.
  final int duplicate;

  /// Stored, and it lost the merge on the node.
  final int superseded;

  /// Refused. The one outcome a reader is told about.
  final int refused;

  /// Offered and not answered for, or answered with a verdict this build
  /// cannot name. They stay in the outbox and are offered again.
  final int unanswered;

  /// The node's head position for the reader after the last batch, which is
  /// how a device that has just pushed learns whether there is anything to pull
  /// without asking.
  final int lastPosition;

  /// How many operations the node now holds because of this pass.
  int get handedOver => applied + duplicate + superseded;

  /// Whether the pass moved anything at all.
  bool get isEmpty => handedOver == 0 && refused == 0 && unanswered == 0;

  @override
  String toString() =>
      'PushRun($applied applied, $duplicate duplicate, $superseded superseded, '
      '$refused refused, $unanswered unanswered, head $lastPosition)';
}

/// Drains the outbox into a node.
final class OperationPusher {
  /// The push over [database]'s outbox, offering through [api].
  OperationPusher({required this.database, required this.api});

  /// Where the outbox lives.
  final AtrilDatabase database;

  /// The node this device is handing changes to.
  final SyncApi api;

  bool _running = false;

  /// Whether a pass is in flight.
  bool get isRunning => _running;

  /// Offers everything this device owes, oldest first.
  ///
  /// It throws what the call threw. A transport failure is the scheduler's to
  /// back off from, and it is not a reason to lose what earlier batches already
  /// retired: each batch is answered for and retired before the next is read,
  /// so a pass that fails half way has still made half the progress.
  ///
  /// A pass while one is already running does nothing and says so. The caller
  /// that would have been queued is a launch, a resume or a reader tapping
  /// *try again*, and by the time the first pass ends it will have offered what
  /// the second was going to.
  Future<PushRun> run({int batchSize = pushBatchSize}) async {
    if (_running) {
      _log.fine('a push is already running');

      return const PushRun();
    }

    _running = true;

    try {
      var applied = 0;
      var duplicate = 0;
      var superseded = 0;
      var refused = 0;
      var unanswered = 0;
      var head = 0;

      while (true) {
        final batch = await database.syncDao.pending(limit: batchSize);

        if (batch.isEmpty) {
          break;
        }

        final answer = await api.push(batch);
        final settlement = await settle(database, answer.results);

        head = answer.lastPosition;
        applied += settlement.applied;
        duplicate += settlement.duplicate;
        superseded += settlement.superseded;
        refused += settlement.refused;
        unanswered += batch.length - settlement.answered;

        if (settlement.retired == 0) {
          // Nothing left the outbox, so the next read would return this same
          // batch and offer it again for ever. Every operation in it was
          // refused or unanswered, and both are states the pass reports rather
          // than states it can push past.
          _log.warning('a batch of ${batch.length} retired nothing');

          break;
        }
      }

      final run = PushRun(
        applied: applied,
        duplicate: duplicate,
        superseded: superseded,
        refused: refused,
        unanswered: unanswered,
        lastPosition: head,
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

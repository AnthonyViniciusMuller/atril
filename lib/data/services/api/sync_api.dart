/// `SyncService`: the log of changes, how this device hands over its own, and
/// how it collects everybody else's.
///
/// Three properties of the node's log shape every method here.
///
/// **An operation's identifier is minted by its author** and is the same on
/// every node that ever sees it, so receiving is idempotent and a retry is
/// free. **An operation's position is node-local** — one node's order for one
/// reader's log — so a device that pulls from two nodes keeps two cursors and
/// never compares them. **The log is append-only**: what changes is who has
/// received an operation, and that is recorded elsewhere.
///
/// One call in the service is deliberately not here. `ReplicateOperations` is
/// the one RPC in the contract whose caller is a peer node proving itself with
/// a certificate, and a reader's device is never it.
///
/// `Sync` is here and is the only method that carries a vocabulary of its own.
/// The two directions of a bidirectional stream are two `oneof`s, and a caller
/// that had to pattern-match a generated message would be a caller holding one
/// — which is the rule `data/model` exists to keep. So the stream speaks
/// [SyncCommand] and [SyncEvent], and what it is *worth* is decided one layer
/// up: the acknowledgement means the cursor moved on a durable write and not on
/// a read, and only the loop that holds the cursor can promise that.
library;

import 'package:fixnum/fixnum.dart';

import '../../../domain/models/operation.dart';
import '../../model/operation_mapper.dart';
import 'api_client.dart';
import 'generated/quire/v1/sync.pbgrpc.dart' as pb;

/// The operation a push reports under.
const String opPush = 'sync/operations: push';

/// The operation a pull reports under.
const String opPull = 'sync/operations: pull';

/// The operation a watch reports under.
const String opWatch = 'sync/operations: watch';

/// The operation the bidirectional stream reports under.
const String opSync = 'sync/operations: stream';

/// What a device says on the bidirectional stream.
///
/// Three messages and no more, which is the contract's own `SyncRequest`: the
/// cursor, once, first; changes this device authored, at any point after it;
/// and the confirmation that what arrived is on disk.
sealed class SyncCommand {
  const SyncCommand();
}

/// The cursor, sent exactly once as the first message.
///
/// A stream that began with a push would be a device asking a node to store
/// changes without saying where it had got to, and the node would have nothing
/// to send back. It is refused, and the refusal is the node's own.
final class SyncStart extends SyncCommand {
  /// Begins the stream from [afterPosition].
  const SyncStart({required this.afterPosition});

  /// This device's position in that node's log. Zero asks from the beginning.
  final int afterPosition;
}

/// Changes this device authored.
final class SyncPush extends SyncCommand {
  /// Offers [operations], in the order they were authored.
  const SyncPush(this.operations);

  /// The batch, oldest first.
  final List<Operation> operations;
}

/// The confirmation that everything up to a position is stored here.
///
/// The node keeps at most one page in flight and does not send again until it
/// arrives, so a device that never acknowledges receives one page and then only
/// what its own pushes provoke. It is not a formality: an operation written to
/// a socket is not an operation written to disk.
final class SyncAck extends SyncCommand {
  /// Confirms everything up to and including [position].
  const SyncAck({required this.position});

  /// The position this device has durably stored up to.
  final int position;
}

/// What a node says on the bidirectional stream.
sealed class SyncEvent {
  const SyncEvent();
}

/// Changes this device has not seen.
final class SyncDelivery extends SyncEvent {
  /// The batch [operations], ending at [lastPosition] in that node's log.
  const SyncDelivery({required this.operations, required this.lastPosition});

  /// In ascending position order, as a pull's page is.
  final List<Operation> operations;

  /// The position of the last operation in the batch, which is what the
  /// acknowledgement carries once they are stored.
  ///
  /// It is read off the wire here and nowhere else. The domain [Operation] has
  /// no position — it is one node's order for one reader's log — so the number
  /// travels with the *batch*, which is the thing the cursor is about.
  final int lastPosition;
}

/// The verdicts on a batch this device offered.
final class SyncVerdicts extends SyncEvent {
  /// One result per operation offered, in the order they were offered.
  const SyncVerdicts(this.results);

  /// The verdicts, which mean exactly what a unary push's mean.
  final List<OperationResult> results;
}

/// What a node did with a batch this device offered.
final class PushResult {
  /// One verdict per operation offered, and the node's head afterwards.
  const PushResult({required this.results, required this.lastPosition});

  /// One result per operation, in the order they were offered.
  final List<OperationResult> results;

  /// This node's head position for the reader after the push, which is how a
  /// device that has just pushed learns whether there is anything to pull
  /// without asking.
  final int lastPosition;
}

/// What a node handed over.
final class PullResult {
  /// The operations, the cursor to send next time, and whether more remain.
  const PullResult({
    required this.operations,
    required this.lastPosition,
    required this.hasMore,
  });

  /// In ascending position order. A reader that has seen position N has
  /// necessarily seen every position below it, which is what allocating the
  /// number inside the writing transaction buys and what lets a cursor be one
  /// number rather than a set.
  final List<Operation> operations;

  /// The position of the last operation returned, and the cursor to send next
  /// time. It is not the node's head: with [hasMore] there is more behind it.
  final int lastPosition;

  /// Whether the node has more after [lastPosition].
  final bool hasMore;
}

/// `SyncService`, as this app calls it.
final class SyncApi extends ApiClient {
  /// The client over the channel this node is dialled on.
  SyncApi({
    required super.connection,
    required super.session,
    super.reachability,
  });

  pb.SyncServiceClient get _stub =>
      pb.SyncServiceClient(channel, interceptors: interceptors);

  /// UC09, outbound. Hands this node the changes this device authored.
  ///
  /// RN10: every operation must declare the device making the call. A batch
  /// containing one that does not fails whole, with `PERMISSION_DENIED`,
  /// rather than reporting a per-operation rejection — a batch with a forged
  /// author in it is not a batch any of which should be trusted.
  Future<PushResult> push(List<Operation> operations) => call(opPush, () async {
    final answer = await _stub.pushOperations(
      pb.PushOperationsRequest(
        operations: <pb.Operation>[
          for (final operation in operations) wireOperation(operation),
        ],
      ),
    );

    return PushResult(
      results: <OperationResult>[
        for (final result in answer.results) operationResultOf(result),
      ],
      lastPosition: answer.lastPosition.toInt(),
    );
  });

  /// UC09, inbound, and the whole of RN06: everything after the cursor.
  ///
  /// The cursor is a position and not a timestamp, and C08 sets out why it
  /// cannot be one — an operation stamped early and committed late is skipped
  /// by a cursor that has already moved past it, and it is not delayed, it is
  /// lost.
  ///
  /// Zero asks from the beginning, which is what a freshly bound device sends.
  Future<PullResult> pull({int afterPosition = 0, int limit = 0}) =>
      call(opPull, () async {
        final answer = await _stub.pullOperations(
          pb.PullOperationsRequest(
            afterPosition: Int64(afterPosition),
            limit: limit,
          ),
        );

        return PullResult(
          operations: <Operation>[
            for (final operation in answer.operations) operationOf(operation),
          ],
          lastPosition: answer.lastPosition.toInt(),
          hasMore: answer.hasMore,
        );
      });

  /// UC10 and UC11 in one call: the same push and pull, kept open.
  ///
  /// It is the five native targets' live channel and is unreachable from a
  /// browser, because gRPC-Web carries a unary call and a server stream and
  /// neither of the other two. Which of the two a build uses is decided where
  /// the graph is composed, as the reader's host and the file saver are, and
  /// not by a conditional export — both sides compile everywhere and the
  /// question is about the platform rather than about the language.
  ///
  /// Nothing here decides what to send or when. [commands] is somebody else's
  /// stream and the events are handed back unwrapped, because the two things
  /// that make this call correct — the cursor the start carries, and an
  /// acknowledgement sent only after the write commits — are properties of
  /// state this layer does not hold.
  Stream<SyncEvent> sync(Stream<SyncCommand> commands) => listen(
    opSync,
    _stub
        .sync(commands.map(_requestOf))
        .map(_eventOf)
        .where((SyncEvent? event) => event != null)
        .cast<SyncEvent>(),
  );

  /// UC10. Learns when this node's log has grown past what the caller has
  /// seen.
  ///
  /// It is a notification and not a delivery: each response carries the node's
  /// head position and never an operation, so the handler compares it against
  /// this node's cursor and pulls if it is behind. There is no acknowledgement
  /// to send, because the node holds nothing in flight for this caller — a
  /// notification that is missed costs a poll rather than an operation.
  ///
  /// The stream is quiet by design, and that is the one thing a caller must
  /// not mistake for a failure. gRPC sends no response headers until the
  /// handler sends its first message, so a watch on a log that has not moved
  /// is a request that has not resolved — indistinguishable, in any client
  /// API, from a stream that is open and idle. Reconnecting on a timer would
  /// be reconnecting because nothing has happened. Asking from a position
  /// known to be behind is what makes it answer at once, and asking from zero
  /// on the first connection does exactly that.
  Stream<int> watch({int afterPosition = 0}) => listen(
    opWatch,
    _stub
        .watchOperations(
          pb.WatchOperationsRequest(afterPosition: Int64(afterPosition)),
        )
        .map(
          (pb.WatchOperationsResponse response) =>
              response.lastPosition.toInt(),
        ),
  );

  pb.SyncRequest _requestOf(SyncCommand command) => switch (command) {
    SyncStart(:final afterPosition) => pb.SyncRequest(
      start: pb.SyncStart(afterPosition: Int64(afterPosition)),
    ),
    SyncPush(:final operations) => pb.SyncRequest(
      push: pb.OperationBatch(
        operations: <pb.Operation>[
          for (final operation in operations) wireOperation(operation),
        ],
      ),
    ),
    SyncAck(:final position) => pb.SyncRequest(
      ack: pb.SyncAck(position: Int64(position)),
    ),
  };

  /// The event [response] carries, or `null` for a payload this build cannot
  /// name.
  ///
  /// A node running a later contract may grow a third one, and ignoring it is
  /// the only safe answer: the two this build does know still arrive, and the
  /// cursor is what makes anything missed a latency rather than a loss.
  SyncEvent? _eventOf(pb.SyncResponse response) {
    if (response.hasOperations()) {
      final delivered = response.operations.operations;

      return SyncDelivery(
        operations: <Operation>[
          for (final operation in delivered) operationOf(operation),
        ],
        lastPosition: delivered.isEmpty ? 0 : delivered.last.position.toInt(),
      );
    }

    if (response.hasPushResult()) {
      return SyncVerdicts(<OperationResult>[
        for (final result in response.pushResult.results)
          operationResultOf(result),
      ]);
    }

    return null;
  }
}

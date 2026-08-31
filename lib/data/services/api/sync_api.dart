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
/// Two calls in the service are deliberately not here. `Sync`, the
/// bidirectional stream, is unreachable from a browser and its acknowledgement
/// has semantics — the cursor advances on a durable write and not on a read —
/// that belong with the loop that maintains it, in phase 11.
/// `ReplicateOperations` is the one RPC in the contract whose caller is a peer
/// node proving itself with a certificate, and a reader's device is never it.
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
  SyncApi({required super.channel, required super.session});

  late final pb.SyncServiceClient _stub = pb.SyncServiceClient(
    channel,
    interceptors: interceptors,
  );

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
}

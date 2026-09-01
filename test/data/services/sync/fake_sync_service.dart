/// A node that keeps one reader's operation log in a list.
///
/// It is the node the push, the pull, the two live channels and the scheduler
/// are all tested against, which is why it lives beside them rather than inside
/// one of their files. What it reproduces is the behaviour those four are
/// written against and nothing else:
///
/// * an operation is recognized by the identifier its author minted, so
///   offering the same one twice answers `duplicate` and stores nothing;
/// * a position is allocated by *this* node, inside the write, which is what
///   lets a cursor be one number rather than a set;
/// * a pull answers a page at a time and says whether more is behind it.
///
/// Two things a test can arrange. [refusing] holds the identifiers this node
/// refuses, with the reason it gives, which is the one outcome that reaches a
/// reader. [verdicts] forces the answer for an identifier outright, so that
/// `superseded` — which a node reaches by merging and this fake does not merge
/// — can still be put in front of the code that has to handle it.
///
/// It is `base` rather than `final` so that the stream tests can extend it with
/// the bidirectional call.
library;

import 'dart:async';

import 'package:atril/data/services/api/generated/quire/v1/sync.pbgrpc.dart'
    as pb;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

/// The node's `SyncService`, as far as a device is concerned.
base class FakeSyncService extends pb.SyncServiceBase {
  /// The reader's log, in the order this node stored it. The position of an
  /// entry is its index plus one.
  final List<pb.Operation> log = <pb.Operation>[];

  /// Every batch this node was offered, in the order it was offered, by the
  /// identifiers it carried. It is what a test asserts the *order* of a drain
  /// against.
  final List<List<String>> pushes = <List<String>>[];

  /// Every cursor a pull asked from.
  final List<int> pulls = <int>[];

  /// The identifiers this node refuses, and why.
  final Map<String, String> refusing = <String, String>{};

  /// The verdict this node gives an identifier, whatever it would have decided.
  final Map<String, pb.OperationOutcome> verdicts =
      <String, pb.OperationOutcome>{};

  /// What this node tells a watcher, as it decides to.
  final StreamController<Int64> heads = StreamController<Int64>.broadcast();

  /// How many operations a pull answers with when the caller names no limit.
  int pageSize = 100;

  /// This node's head position for the reader.
  int get head => log.length;

  /// Stores [operation] as another device's change would arrive, and answers
  /// with the position it was given.
  int record(pb.Operation operation) {
    log.add(operation.clone()..position = Int64(log.length + 1));

    return log.length;
  }

  @override
  Future<pb.PushOperationsResponse> pushOperations(
    ServiceCall call,
    pb.PushOperationsRequest request,
  ) async => pb.PushOperationsResponse(
    results: accept(request.operations),
    lastPosition: Int64(log.length),
  );

  /// Stores what was offered and answers for each, which is what the unary
  /// push and the stream's push both do.
  List<pb.OperationResult> accept(List<pb.Operation> offered) {
    pushes.add(<String>[for (final operation in offered) operation.id]);

    final results = <pb.OperationResult>[];

    for (final operation in offered) {
      final refusal = refusing[operation.id];

      if (refusal != null) {
        results.add(
          pb.OperationResult(
            operationId: operation.id,
            outcome: pb.OperationOutcome.OPERATION_OUTCOME_REJECTED,
            detail: refusal,
          ),
        );

        continue;
      }

      final forced = verdicts[operation.id];

      if (forced != null) {
        // A forced verdict still stores, except where the node would not have:
        // `duplicate` is the node saying it already holds the operation.
        if (forced != pb.OperationOutcome.OPERATION_OUTCOME_DUPLICATE) {
          record(operation);
        }

        results.add(
          pb.OperationResult(operationId: operation.id, outcome: forced),
        );

        continue;
      }

      final known = log.any((pb.Operation held) => held.id == operation.id);

      if (!known) {
        record(operation);
      }

      results.add(
        pb.OperationResult(
          operationId: operation.id,
          outcome: known
              ? pb.OperationOutcome.OPERATION_OUTCOME_DUPLICATE
              : pb.OperationOutcome.OPERATION_OUTCOME_APPLIED,
        ),
      );
    }

    return results;
  }

  @override
  Future<pb.PullOperationsResponse> pullOperations(
    ServiceCall call,
    pb.PullOperationsRequest request,
  ) async {
    final after = request.afterPosition.toInt();

    pulls.add(after);

    return page(after, limit: request.limit == 0 ? pageSize : request.limit);
  }

  /// The page after [after], which the unary pull and the stream both send.
  pb.PullOperationsResponse page(int after, {int? limit}) {
    final remaining = log.skip(after).toList();
    final size = limit ?? pageSize;
    final sent = remaining.take(size).toList();

    return pb.PullOperationsResponse(
      operations: sent,
      lastPosition: Int64(sent.isEmpty ? after : sent.last.position.toInt()),
      hasMore: remaining.length > sent.length,
    );
  }

  /// The bidirectional stream, which the five native targets use and which
  /// `stream_test.dart` overrides this with.
  ///
  /// It is refused here rather than left to the generated base, so that a test
  /// reaching it by accident says so instead of hanging on a stream nobody
  /// serves.
  @override
  Stream<pb.SyncResponse> sync(
    ServiceCall call,
    Stream<pb.SyncRequest> request,
  ) => Stream<pb.SyncResponse>.error(
    GrpcError.unimplemented('this node does not hold a stream open'),
  );

  /// The one call in the contract whose caller is a peer node proving itself
  /// with a certificate. A reader's device is never it, and this refusal is an
  /// assertion as much as any test here.
  @override
  Future<pb.ReplicateOperationsResponse> replicateOperations(
    ServiceCall call,
    pb.ReplicateOperationsRequest request,
  ) async => throw GrpcError.unimplemented('a device is not a peer');

  @override
  Stream<pb.WatchOperationsResponse> watchOperations(
    ServiceCall call,
    pb.WatchOperationsRequest request,
  ) async* {
    // Asking from a position this node is already past is answered at once,
    // which is what a caller opening a watch on a log it is behind depends on.
    if (log.length > request.afterPosition.toInt()) {
      yield pb.WatchOperationsResponse(lastPosition: Int64(log.length));
    }

    yield* heads.stream.map(
      (Int64 position) => pb.WatchOperationsResponse(lastPosition: position),
    );
  }
}

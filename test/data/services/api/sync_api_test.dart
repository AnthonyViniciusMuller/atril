@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:atril/data/services/api/generated/quire/v1/sync.pbgrpc.dart'
    as pb;
import 'package:atril/data/services/api/reachability.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/sync_api.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/utils/errors.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide ClientChannel;
import 'package:grpc/service_api.dart' show ClientChannel;

/// A node that keeps one reader's log in a list.
///
/// It answers the three calls this client makes and nothing else. The two it
/// does not — the bidirectional `Sync` and the peer-facing
/// `ReplicateOperations` — are the two `SyncApi` deliberately leaves to phase
/// 11 and to a peer node.
final class _FakeSyncService extends pb.SyncServiceBase {
  final List<pb.Operation> log = <pb.Operation>[];

  /// What the node has decided to tell a watcher about, in order.
  final StreamController<Int64> heads = StreamController<Int64>.broadcast();

  /// The credential every call presented.
  final List<String?> presented = <String?>[];

  @override
  Future<pb.PushOperationsResponse> pushOperations(
    ServiceCall call,
    pb.PushOperationsRequest request,
  ) async {
    presented.add(call.clientMetadata?['authorization']);

    final results = <pb.OperationResult>[];

    for (final operation in request.operations) {
      final known = log.any((pb.Operation held) => held.id == operation.id);

      if (!known) {
        // The position is allocated by the node, inside the write, which is
        // what makes a cursor one number rather than a set.
        log.add(operation.clone()..position = Int64(log.length + 1));
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

    return pb.PushOperationsResponse(
      results: results,
      lastPosition: Int64(log.length),
    );
  }

  @override
  Future<pb.PullOperationsResponse> pullOperations(
    ServiceCall call,
    pb.PullOperationsRequest request,
  ) async {
    presented.add(call.clientMetadata?['authorization']);

    final after = request.afterPosition.toInt();
    final limit = request.limit == 0 ? 2 : request.limit;
    final pending = log.skip(after).toList();
    final page = pending.take(limit).toList();

    return pb.PullOperationsResponse(
      operations: page,
      lastPosition: page.isEmpty ? Int64(after) : page.last.position,
      hasMore: pending.length > page.length,
    );
  }

  @override
  Stream<pb.WatchOperationsResponse> watchOperations(
    ServiceCall call,
    pb.WatchOperationsRequest request,
  ) async* {
    presented.add(call.clientMetadata?['authorization']);

    await for (final head in heads.stream) {
      yield pb.WatchOperationsResponse(lastPosition: head);
    }
  }

  @override
  Stream<pb.SyncResponse> sync(
    ServiceCall call,
    Stream<pb.SyncRequest> request,
  ) => throw GrpcError.unimplemented('phase 11 opens this one');

  @override
  Future<pb.ReplicateOperationsResponse> replicateOperations(
    ServiceCall call,
    pb.ReplicateOperationsRequest request,
  ) async => throw GrpcError.unimplemented('a device is never the caller');
}

Operation operation(String id, int counter) => Operation(
  id: id,
  deviceId: 'd-1',
  entity: TargetEntity.ebook,
  targetId: 'e-1',
  kind: OperationKind.update,
  delta: <String, Object?>{'title': 'a title for $id', 'author': null},
  vectorClock: VectorClock.of(<String, int>{'d-1': counter}),
  createdAt: DateTime.fromMicrosecondsSinceEpoch(
    1700000000000000 + counter,
    isUtc: true,
  ),
);

void main() {
  late _FakeSyncService service;
  late Server server;
  late ClientChannel channel;
  late NodeReachability reachability;
  late SyncApi api;

  setUp(() async {
    service = _FakeSyncService();
    server = Server.create(services: <Service>[service]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    final holder = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => throw StateError('nothing should refresh here'),
    );
    await holder.begin(
      Session(
        accessToken: 'access-1',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(hours: 1),
        ),
        refreshToken: 'refresh-1',
        refreshTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(days: 30),
        ),
      ),
    );

    channel = openChannel(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    reachability = NodeReachability();
    api = SyncApi(
      channel: channel,
      session: holder,
      reachability: reachability,
    );
  });

  tearDown(() async {
    await reachability.dispose();
    await service.heads.close();
    await channel.shutdown();
    await server.shutdown();
  });

  test(
    'a push carries the credential and comes back with a verdict each',
    () async {
      final answer = await api.push(<Operation>[
        operation('op-1', 1),
        operation('op-2', 2),
      ]);

      expect(service.presented.last, 'Bearer access-1');
      expect(answer.results.map((r) => r.operationId), <String>[
        'op-1',
        'op-2',
      ]);
      expect(
        answer.results.map((r) => r.outcome),
        everyElement(OperationOutcome.applied),
      );
      expect(answer.lastPosition, 2);
    },
  );

  test('an operation offered twice is a duplicate and not a fault', () async {
    await api.push(<Operation>[operation('op-1', 1)]);

    final answer = await api.push(<Operation>[operation('op-1', 1)]);

    // Receiving is idempotent by operation id, which is what makes a retry
    // free: an operation reaching a node twice by two routes is the normal
    // shape of a federation.
    expect(answer.results.single.outcome, OperationOutcome.duplicate);
    expect(answer.results.single.outcome!.retiresTheOperation, isTrue);
  });

  test('a pull walks the log a page at a time', () async {
    await api.push(<Operation>[
      operation('op-1', 1),
      operation('op-2', 2),
      operation('op-3', 3),
    ]);

    final first = await api.pull();

    expect(first.operations.map((o) => o.id), <String>['op-1', 'op-2']);
    expect(first.lastPosition, 2);
    expect(first.hasMore, isTrue);

    final second = await api.pull(afterPosition: first.lastPosition);

    expect(second.operations.single.id, 'op-3');
    expect(second.hasMore, isFalse);

    // The delta survived the round trip, including the difference between a
    // field left unnamed and one named as null.
    expect(second.operations.single.delta['author'], isNull);
    expect(second.operations.single.claims('author'), isTrue);
    expect(second.operations.single.claims('publisher'), isFalse);
  });

  test(
    'a pull from the head answers with nothing and the same cursor',
    () async {
      await api.push(<Operation>[operation('op-1', 1)]);

      final answer = await api.pull(afterPosition: 1);

      expect(answer.operations, isEmpty);
      expect(answer.lastPosition, 1);
      expect(answer.hasMore, isFalse);
    },
  );

  test('a watch reports the head and never an operation', () async {
    final heads = <int>[];
    final watching = api.watch().listen(heads.add);

    // The stream stays open with nothing to say while the log has not moved,
    // and that quiet is not a failure: gRPC sends no headers until the handler
    // sends its first message.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(heads, isEmpty);

    service.heads.add(Int64(3));
    service.heads.add(Int64(7));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(heads, <int>[3, 7]);

    await watching.cancel();
  });

  test('a failed call arrives in the error vocabulary', () async {
    await server.shutdown();

    await expectLater(
      api.pull(),
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', ErrorKind.unavailable)
            .having((e) => e.op, 'op', opPull)
            .having((e) => e.isRetryable, 'is retryable', isTrue),
      ),
    );
  });

  test('every call is evidence about whether the node is there', () async {
    await api.pull();

    expect(reachability.isReachable, isTrue);

    await server.shutdown();

    await expectLater(api.pull(), throwsA(isA<AppException>()));

    // The signal is the call itself, which is why nothing had to remember to
    // report: it is wired at the one place every call passes through.
    expect(reachability.isReachable, isFalse);
  });
}

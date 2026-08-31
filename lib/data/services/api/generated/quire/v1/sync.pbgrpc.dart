// This is a generated file - do not edit.
//
// Generated from quire/v1/sync.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sync.pb.dart' as $0;

export 'sync.pb.dart';

@$pb.GrpcServiceName('quire.v1.SyncService')
class SyncServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SyncServiceClient(super.channel, {super.options, super.interceptors});

  /// UC09, outbound. Hands this node the changes a device authored, typically
  /// while it was disconnected (UC11).
  ///
  /// RN10: every operation must declare the device that is making the call.
  /// A batch containing one that does not fails whole, with PermissionDenied,
  /// rather than reporting a per-operation rejection — a batch with a forged
  /// author in it is not a batch any of which should be trusted.
  $grpc.ResponseFuture<$0.PushOperationsResponse> pushOperations(
    $0.PushOperationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pushOperations, request, options: options);
  }

  /// UC09, inbound, and the whole of RN06: everything after the cursor, which
  /// is a position and not a timestamp. C08 in docs/tcc-corrections.md sets out
  /// why it cannot be a timestamp — an operation stamped early and committed
  /// late is skipped by a cursor that has already moved past it, and it is not
  /// delayed, it is lost.
  $grpc.ResponseFuture<$0.PullOperationsResponse> pullOperations(
    $0.PullOperationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pullOperations, request, options: options);
  }

  /// UC10 and UC11 in one call: the same push and pull, kept open, so that a
  /// change made on one device reaches the reader's other devices as it happens
  /// rather than at the next poll. A device that has just reconnected drains its
  /// backlog through the same stream it then leaves open.
  $grpc.ResponseStream<$0.SyncResponse> sync(
    $async.Stream<$0.SyncRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$sync, request, options: options);
  }

  /// UC10 for a caller that cannot hold Sync open.
  ///
  /// A browser is the case it exists for. gRPC-Web carries a unary call and a
  /// server stream and neither of the other two, so Sync is unreachable from
  /// one — D10 in docs/tcc-corrections.md is what that costs and why it is
  /// recorded rather than worked around. What a browser can do is push with
  /// PushOperations, pull with PullOperations and be told when to.
  ///
  /// It is a notification and not a delivery, and the difference is the point.
  /// It carries a position, never an operation: the caller learns that this
  /// node's log has grown past what it has seen, and answers with
  /// PullOperations like any other caller. Nothing about durability changes,
  /// because nothing is delivered here — the cursor stays with the caller,
  /// where the unary pair already keeps it, and a notification that was missed
  /// costs a poll rather than an operation.
  ///
  /// That is also why there is no acknowledgement to match SyncAck. The node
  /// holds nothing in flight for this caller and has nothing to hold: it is
  /// reporting a number it would report again on the next notification.
  $grpc.ResponseStream<$0.WatchOperationsResponse> watchOperations(
    $0.WatchOperationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchOperations, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// UC09 between nodes rather than between a device and its node.
  ///
  /// This is the only RPC in the contract whose caller is a peer node and not a
  /// reader's device, and it is authenticated differently for that reason: by
  /// the certificate fingerprint learned during discovery (RNF08), not by a JWT
  /// (RNF11). It names the reader explicitly, because a peer replicates many and
  /// the certificate identifies the node rather than any one of them.
  ///
  /// There is no peer-facing pull to match it. Replication is driven from the
  /// side that owes the data: the origin holds a delivery row per operation and
  /// destination, retries it with backoff until the destination confirms, and a
  /// peer that was unreachable for a week is caught up by that queue rather than
  /// by asking.
  $grpc.ResponseFuture<$0.ReplicateOperationsResponse> replicateOperations(
    $0.ReplicateOperationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$replicateOperations, request, options: options);
  }

  // method descriptors

  static final _$pushOperations =
      $grpc.ClientMethod<$0.PushOperationsRequest, $0.PushOperationsResponse>(
          '/quire.v1.SyncService/PushOperations',
          ($0.PushOperationsRequest value) => value.writeToBuffer(),
          $0.PushOperationsResponse.fromBuffer);
  static final _$pullOperations =
      $grpc.ClientMethod<$0.PullOperationsRequest, $0.PullOperationsResponse>(
          '/quire.v1.SyncService/PullOperations',
          ($0.PullOperationsRequest value) => value.writeToBuffer(),
          $0.PullOperationsResponse.fromBuffer);
  static final _$sync = $grpc.ClientMethod<$0.SyncRequest, $0.SyncResponse>(
      '/quire.v1.SyncService/Sync',
      ($0.SyncRequest value) => value.writeToBuffer(),
      $0.SyncResponse.fromBuffer);
  static final _$watchOperations =
      $grpc.ClientMethod<$0.WatchOperationsRequest, $0.WatchOperationsResponse>(
          '/quire.v1.SyncService/WatchOperations',
          ($0.WatchOperationsRequest value) => value.writeToBuffer(),
          $0.WatchOperationsResponse.fromBuffer);
  static final _$replicateOperations = $grpc.ClientMethod<
          $0.ReplicateOperationsRequest, $0.ReplicateOperationsResponse>(
      '/quire.v1.SyncService/ReplicateOperations',
      ($0.ReplicateOperationsRequest value) => value.writeToBuffer(),
      $0.ReplicateOperationsResponse.fromBuffer);
}

@$pb.GrpcServiceName('quire.v1.SyncService')
abstract class SyncServiceBase extends $grpc.Service {
  $core.String get $name => 'quire.v1.SyncService';

  SyncServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PushOperationsRequest,
            $0.PushOperationsResponse>(
        'PushOperations',
        pushOperations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PushOperationsRequest.fromBuffer(value),
        ($0.PushOperationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PullOperationsRequest,
            $0.PullOperationsResponse>(
        'PullOperations',
        pullOperations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PullOperationsRequest.fromBuffer(value),
        ($0.PullOperationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SyncRequest, $0.SyncResponse>(
        'Sync',
        sync,
        true,
        true,
        ($core.List<$core.int> value) => $0.SyncRequest.fromBuffer(value),
        ($0.SyncResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchOperationsRequest,
            $0.WatchOperationsResponse>(
        'WatchOperations',
        watchOperations_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchOperationsRequest.fromBuffer(value),
        ($0.WatchOperationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReplicateOperationsRequest,
            $0.ReplicateOperationsResponse>(
        'ReplicateOperations',
        replicateOperations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReplicateOperationsRequest.fromBuffer(value),
        ($0.ReplicateOperationsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.PushOperationsResponse> pushOperations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PushOperationsRequest> $request) async {
    return pushOperations($call, await $request);
  }

  $async.Future<$0.PushOperationsResponse> pushOperations(
      $grpc.ServiceCall call, $0.PushOperationsRequest request);

  $async.Future<$0.PullOperationsResponse> pullOperations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PullOperationsRequest> $request) async {
    return pullOperations($call, await $request);
  }

  $async.Future<$0.PullOperationsResponse> pullOperations(
      $grpc.ServiceCall call, $0.PullOperationsRequest request);

  $async.Stream<$0.SyncResponse> sync(
      $grpc.ServiceCall call, $async.Stream<$0.SyncRequest> request);

  $async.Stream<$0.WatchOperationsResponse> watchOperations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchOperationsRequest> $request) async* {
    yield* watchOperations($call, await $request);
  }

  $async.Stream<$0.WatchOperationsResponse> watchOperations(
      $grpc.ServiceCall call, $0.WatchOperationsRequest request);

  $async.Future<$0.ReplicateOperationsResponse> replicateOperations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReplicateOperationsRequest> $request) async {
    return replicateOperations($call, await $request);
  }

  $async.Future<$0.ReplicateOperationsResponse> replicateOperations(
      $grpc.ServiceCall call, $0.ReplicateOperationsRequest request);
}

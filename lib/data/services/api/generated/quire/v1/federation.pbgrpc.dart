// This is a generated file - do not edit.
//
// Generated from quire/v1/federation.proto.

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

import 'federation.pb.dart' as $0;

export 'federation.pb.dart';

@$pb.GrpcServiceName('quire.v1.FederationService')
class FederationServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  FederationServiceClient(super.channel, {super.options, super.interceptors});

  /// UC13, RF14. Resolves a domain to the services it exposes, over
  /// /.well-known as RFC 8615 establishes, and returns what it found without
  /// storing anything. It is the lookup UC14 includes when a reader is choosing
  /// where to register, and the first half of adding a node to the catalogue.
  $grpc.ResponseFuture<$0.DiscoverServerResponse> discoverServer(
    $0.DiscoverServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$discoverServer, request, options: options);
  }

  /// UC12, create. Discovers the domain and records the result, pinning the
  /// certificate fingerprint that node-to-node mTLS will be checked against
  /// (RNF08). Peers belong to different operators and share no root of trust,
  /// so that fingerprint is the trust anchor and this call is where it is
  /// established.
  $grpc.ResponseFuture<$0.AddKnownServerResponse> addKnownServer(
    $0.AddKnownServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addKnownServer, request, options: options);
  }

  /// UC12, read.
  $grpc.ResponseFuture<$0.GetKnownServerResponse> getKnownServer(
    $0.GetKnownServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getKnownServer, request, options: options);
  }

  /// UC12, read.
  $grpc.ResponseFuture<$0.ListKnownServersResponse> listKnownServers(
    $0.ListKnownServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listKnownServers, request, options: options);
  }

  /// UC12, update. Only whether the node takes part is editable: everything else
  /// in the record was learned from the node itself and is refreshed rather than
  /// typed.
  $grpc.ResponseFuture<$0.UpdateKnownServerResponse> updateKnownServer(
    $0.UpdateKnownServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateKnownServer, request, options: options);
  }

  /// UC12, update — the half that re-runs discovery. It is the only way a pinned
  /// fingerprint changes, and it is a deliberate act by the reader precisely
  /// because a node that re-pinned on its own would have no pin at all: an
  /// attacker able to answer for the domain would be accepted on the strength of
  /// answering for the domain.
  $grpc.ResponseFuture<$0.RefreshKnownServerResponse> refreshKnownServer(
    $0.RefreshKnownServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshKnownServer, request, options: options);
  }

  /// UC12, delete. Refused while an active authorization names the node:
  /// forgetting a peer that still holds a copy would leave the reader unable to
  /// revoke it, and RN03 is the promise that they can.
  $grpc.ResponseFuture<$0.RemoveKnownServerResponse> removeKnownServer(
    $0.RemoveKnownServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeKnownServer, request, options: options);
  }

  /// UC15, RF16. Allows a known node to hold a copy of this reader's data, with
  /// or without their files.
  $grpc.ResponseFuture<$0.AuthorizeReplicaResponse> authorizeReplica(
    $0.AuthorizeReplicaRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$authorizeReplica, request, options: options);
  }

  /// UC15, RF16. Withdraws that permission. The authorization is deactivated
  /// and kept, because the record that it once existed is what explains why a
  /// peer still holds data — revoking stops the replication, it does not reach
  /// into another operator's database.
  $grpc.ResponseFuture<$0.RevokeReplicaResponse> revokeReplica(
    $0.RevokeReplicaRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeReplica, request, options: options);
  }

  /// UC15, read. Which nodes hold a copy, which of them hold the files, and
  /// which used to.
  $grpc.ResponseFuture<$0.ListReplicaAuthorizationsResponse>
      listReplicaAuthorizations(
    $0.ListReplicaAuthorizationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listReplicaAuthorizations, request,
        options: options);
  }

  /// UC16, RF17. Addressed to the node the reader is moving *to*, by a device
  /// that already holds the whole collection locally — which is what lets the
  /// migration proceed without the previous node's cooperation or availability.
  ///
  /// The call adopts the reader's devices with the ids they already have, and
  /// C11 in docs/tcc-corrections.md is why it has to: every operation names its
  /// authoring device and every vector clock is keyed by a device id, so a node
  /// that minted fresh ones would hold a history naming devices that do not
  /// exist, and two devices that had been in sync would read as concurrent for
  /// ever.
  ///
  /// It creates the reader and returns a session, and the devices then push
  /// their local log through SyncService like any other backlog. What it cannot
  /// do is prove the previous identity: a node that needs nothing from the
  /// previous server has nothing to check the claim with, so the identifier
  /// changes and the replicas are authorized again. Also C11.
  $grpc.ResponseFuture<$0.MigrateHomeServerResponse> migrateHomeServer(
    $0.MigrateHomeServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$migrateHomeServer, request, options: options);
  }

  // method descriptors

  static final _$discoverServer =
      $grpc.ClientMethod<$0.DiscoverServerRequest, $0.DiscoverServerResponse>(
          '/quire.v1.FederationService/DiscoverServer',
          ($0.DiscoverServerRequest value) => value.writeToBuffer(),
          $0.DiscoverServerResponse.fromBuffer);
  static final _$addKnownServer =
      $grpc.ClientMethod<$0.AddKnownServerRequest, $0.AddKnownServerResponse>(
          '/quire.v1.FederationService/AddKnownServer',
          ($0.AddKnownServerRequest value) => value.writeToBuffer(),
          $0.AddKnownServerResponse.fromBuffer);
  static final _$getKnownServer =
      $grpc.ClientMethod<$0.GetKnownServerRequest, $0.GetKnownServerResponse>(
          '/quire.v1.FederationService/GetKnownServer',
          ($0.GetKnownServerRequest value) => value.writeToBuffer(),
          $0.GetKnownServerResponse.fromBuffer);
  static final _$listKnownServers = $grpc.ClientMethod<
          $0.ListKnownServersRequest, $0.ListKnownServersResponse>(
      '/quire.v1.FederationService/ListKnownServers',
      ($0.ListKnownServersRequest value) => value.writeToBuffer(),
      $0.ListKnownServersResponse.fromBuffer);
  static final _$updateKnownServer = $grpc.ClientMethod<
          $0.UpdateKnownServerRequest, $0.UpdateKnownServerResponse>(
      '/quire.v1.FederationService/UpdateKnownServer',
      ($0.UpdateKnownServerRequest value) => value.writeToBuffer(),
      $0.UpdateKnownServerResponse.fromBuffer);
  static final _$refreshKnownServer = $grpc.ClientMethod<
          $0.RefreshKnownServerRequest, $0.RefreshKnownServerResponse>(
      '/quire.v1.FederationService/RefreshKnownServer',
      ($0.RefreshKnownServerRequest value) => value.writeToBuffer(),
      $0.RefreshKnownServerResponse.fromBuffer);
  static final _$removeKnownServer = $grpc.ClientMethod<
          $0.RemoveKnownServerRequest, $0.RemoveKnownServerResponse>(
      '/quire.v1.FederationService/RemoveKnownServer',
      ($0.RemoveKnownServerRequest value) => value.writeToBuffer(),
      $0.RemoveKnownServerResponse.fromBuffer);
  static final _$authorizeReplica = $grpc.ClientMethod<
          $0.AuthorizeReplicaRequest, $0.AuthorizeReplicaResponse>(
      '/quire.v1.FederationService/AuthorizeReplica',
      ($0.AuthorizeReplicaRequest value) => value.writeToBuffer(),
      $0.AuthorizeReplicaResponse.fromBuffer);
  static final _$revokeReplica =
      $grpc.ClientMethod<$0.RevokeReplicaRequest, $0.RevokeReplicaResponse>(
          '/quire.v1.FederationService/RevokeReplica',
          ($0.RevokeReplicaRequest value) => value.writeToBuffer(),
          $0.RevokeReplicaResponse.fromBuffer);
  static final _$listReplicaAuthorizations = $grpc.ClientMethod<
          $0.ListReplicaAuthorizationsRequest,
          $0.ListReplicaAuthorizationsResponse>(
      '/quire.v1.FederationService/ListReplicaAuthorizations',
      ($0.ListReplicaAuthorizationsRequest value) => value.writeToBuffer(),
      $0.ListReplicaAuthorizationsResponse.fromBuffer);
  static final _$migrateHomeServer = $grpc.ClientMethod<
          $0.MigrateHomeServerRequest, $0.MigrateHomeServerResponse>(
      '/quire.v1.FederationService/MigrateHomeServer',
      ($0.MigrateHomeServerRequest value) => value.writeToBuffer(),
      $0.MigrateHomeServerResponse.fromBuffer);
}

@$pb.GrpcServiceName('quire.v1.FederationService')
abstract class FederationServiceBase extends $grpc.Service {
  $core.String get $name => 'quire.v1.FederationService';

  FederationServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.DiscoverServerRequest,
            $0.DiscoverServerResponse>(
        'DiscoverServer',
        discoverServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DiscoverServerRequest.fromBuffer(value),
        ($0.DiscoverServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddKnownServerRequest,
            $0.AddKnownServerResponse>(
        'AddKnownServer',
        addKnownServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddKnownServerRequest.fromBuffer(value),
        ($0.AddKnownServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetKnownServerRequest,
            $0.GetKnownServerResponse>(
        'GetKnownServer',
        getKnownServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetKnownServerRequest.fromBuffer(value),
        ($0.GetKnownServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListKnownServersRequest,
            $0.ListKnownServersResponse>(
        'ListKnownServers',
        listKnownServers_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListKnownServersRequest.fromBuffer(value),
        ($0.ListKnownServersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateKnownServerRequest,
            $0.UpdateKnownServerResponse>(
        'UpdateKnownServer',
        updateKnownServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateKnownServerRequest.fromBuffer(value),
        ($0.UpdateKnownServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RefreshKnownServerRequest,
            $0.RefreshKnownServerResponse>(
        'RefreshKnownServer',
        refreshKnownServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RefreshKnownServerRequest.fromBuffer(value),
        ($0.RefreshKnownServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveKnownServerRequest,
            $0.RemoveKnownServerResponse>(
        'RemoveKnownServer',
        removeKnownServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RemoveKnownServerRequest.fromBuffer(value),
        ($0.RemoveKnownServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AuthorizeReplicaRequest,
            $0.AuthorizeReplicaResponse>(
        'AuthorizeReplica',
        authorizeReplica_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AuthorizeReplicaRequest.fromBuffer(value),
        ($0.AuthorizeReplicaResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RevokeReplicaRequest, $0.RevokeReplicaResponse>(
            'RevokeReplica',
            revokeReplica_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RevokeReplicaRequest.fromBuffer(value),
            ($0.RevokeReplicaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListReplicaAuthorizationsRequest,
            $0.ListReplicaAuthorizationsResponse>(
        'ListReplicaAuthorizations',
        listReplicaAuthorizations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListReplicaAuthorizationsRequest.fromBuffer(value),
        ($0.ListReplicaAuthorizationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MigrateHomeServerRequest,
            $0.MigrateHomeServerResponse>(
        'MigrateHomeServer',
        migrateHomeServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.MigrateHomeServerRequest.fromBuffer(value),
        ($0.MigrateHomeServerResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.DiscoverServerResponse> discoverServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiscoverServerRequest> $request) async {
    return discoverServer($call, await $request);
  }

  $async.Future<$0.DiscoverServerResponse> discoverServer(
      $grpc.ServiceCall call, $0.DiscoverServerRequest request);

  $async.Future<$0.AddKnownServerResponse> addKnownServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AddKnownServerRequest> $request) async {
    return addKnownServer($call, await $request);
  }

  $async.Future<$0.AddKnownServerResponse> addKnownServer(
      $grpc.ServiceCall call, $0.AddKnownServerRequest request);

  $async.Future<$0.GetKnownServerResponse> getKnownServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetKnownServerRequest> $request) async {
    return getKnownServer($call, await $request);
  }

  $async.Future<$0.GetKnownServerResponse> getKnownServer(
      $grpc.ServiceCall call, $0.GetKnownServerRequest request);

  $async.Future<$0.ListKnownServersResponse> listKnownServers_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListKnownServersRequest> $request) async {
    return listKnownServers($call, await $request);
  }

  $async.Future<$0.ListKnownServersResponse> listKnownServers(
      $grpc.ServiceCall call, $0.ListKnownServersRequest request);

  $async.Future<$0.UpdateKnownServerResponse> updateKnownServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateKnownServerRequest> $request) async {
    return updateKnownServer($call, await $request);
  }

  $async.Future<$0.UpdateKnownServerResponse> updateKnownServer(
      $grpc.ServiceCall call, $0.UpdateKnownServerRequest request);

  $async.Future<$0.RefreshKnownServerResponse> refreshKnownServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshKnownServerRequest> $request) async {
    return refreshKnownServer($call, await $request);
  }

  $async.Future<$0.RefreshKnownServerResponse> refreshKnownServer(
      $grpc.ServiceCall call, $0.RefreshKnownServerRequest request);

  $async.Future<$0.RemoveKnownServerResponse> removeKnownServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RemoveKnownServerRequest> $request) async {
    return removeKnownServer($call, await $request);
  }

  $async.Future<$0.RemoveKnownServerResponse> removeKnownServer(
      $grpc.ServiceCall call, $0.RemoveKnownServerRequest request);

  $async.Future<$0.AuthorizeReplicaResponse> authorizeReplica_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AuthorizeReplicaRequest> $request) async {
    return authorizeReplica($call, await $request);
  }

  $async.Future<$0.AuthorizeReplicaResponse> authorizeReplica(
      $grpc.ServiceCall call, $0.AuthorizeReplicaRequest request);

  $async.Future<$0.RevokeReplicaResponse> revokeReplica_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RevokeReplicaRequest> $request) async {
    return revokeReplica($call, await $request);
  }

  $async.Future<$0.RevokeReplicaResponse> revokeReplica(
      $grpc.ServiceCall call, $0.RevokeReplicaRequest request);

  $async.Future<$0.ListReplicaAuthorizationsResponse>
      listReplicaAuthorizations_Pre($grpc.ServiceCall $call,
          $async.Future<$0.ListReplicaAuthorizationsRequest> $request) async {
    return listReplicaAuthorizations($call, await $request);
  }

  $async.Future<$0.ListReplicaAuthorizationsResponse> listReplicaAuthorizations(
      $grpc.ServiceCall call, $0.ListReplicaAuthorizationsRequest request);

  $async.Future<$0.MigrateHomeServerResponse> migrateHomeServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.MigrateHomeServerRequest> $request) async {
    return migrateHomeServer($call, await $request);
  }

  $async.Future<$0.MigrateHomeServerResponse> migrateHomeServer(
      $grpc.ServiceCall call, $0.MigrateHomeServerRequest request);
}

// This is a generated file - do not edit.
//
// Generated from quire/v1/federation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/field_mask.pb.dart'
    as $2;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'auth.pb.dart' as $3;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// What a node publishes about itself, as discovery returns it.
class ServerDescriptor extends $pb.GeneratedMessage {
  factory ServerDescriptor({
    $core.String? domain,
    $core.String? baseUrl,
    $core.String? jwksUri,
    $core.String? certificateFingerprint,
    $core.String? grpc,
  }) {
    final result = create();
    if (domain != null) result.domain = domain;
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (jwksUri != null) result.jwksUri = jwksUri;
    if (certificateFingerprint != null)
      result.certificateFingerprint = certificateFingerprint;
    if (grpc != null) result.grpc = grpc;
    return result;
  }

  ServerDescriptor._();

  factory ServerDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerDescriptor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'domain')
    ..aOS(2, _omitFieldNames ? '' : 'baseUrl')
    ..aOS(3, _omitFieldNames ? '' : 'jwksUri')
    ..aOS(4, _omitFieldNames ? '' : 'certificateFingerprint')
    ..aOS(5, _omitFieldNames ? '' : 'grpc')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerDescriptor copyWith(void Function(ServerDescriptor) updates) =>
      super.copyWith((message) => updates(message as ServerDescriptor))
          as ServerDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerDescriptor create() => ServerDescriptor._();
  @$core.override
  ServerDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerDescriptor>(create);
  static ServerDescriptor? _defaultInstance;

  /// The authority the lookup was addressed to, and the second half of every
  /// federated identifier hosted there.
  @$pb.TagNumber(1)
  $core.String get domain => $_getSZ(0);
  @$pb.TagNumber(1)
  set domain($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDomain() => $_has(0);
  @$pb.TagNumber(1)
  void clearDomain() => $_clearField(1);

  /// Where the node actually answers. Separate from the domain on purpose: a
  /// node may be identified by one host and served from another.
  @$pb.TagNumber(2)
  $core.String get baseUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set baseUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBaseUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearBaseUrl() => $_clearField(2);

  /// Where it publishes the public keys its tokens are signed with, so that a
  /// peer can verify them without sharing a secret (RNF11).
  @$pb.TagNumber(3)
  $core.String get jwksUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set jwksUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasJwksUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearJwksUri() => $_clearField(3);

  /// The certificate to pin for node-to-node mTLS (RNF08). It is a digest of
  /// the public key and not of the certificate — see C12 in
  /// docs/tcc-corrections.md — and its form says so: spki-sha256:<base64>.
  @$pb.TagNumber(4)
  $core.String get certificateFingerprint => $_getSZ(3);
  @$pb.TagNumber(4)
  set certificateFingerprint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCertificateFingerprint() => $_has(3);
  @$pb.TagNumber(4)
  void clearCertificateFingerprint() => $_clearField(4);

  /// The authority to dial for gRPC, as host:port.
  ///
  /// It is published separately from the base URL because the two are only the
  /// same address where a gateway happens to collapse them: the .well-known
  /// documents are plain HTTP because RFC 8615 requires it, and the API is
  /// gRPC, so without a mesh in front the two listen on different ports. A peer
  /// that learned only the base URL would have nowhere to dial for replication.
  /// D06 in docs/tcc-corrections.md.
  ///
  /// Absent on a node whose document publishes none, which is a node this
  /// instance can record and cannot replicate to.
  @$pb.TagNumber(5)
  $core.String get grpc => $_getSZ(4);
  @$pb.TagNumber(5)
  set grpc($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGrpc() => $_has(4);
  @$pb.TagNumber(5)
  void clearGrpc() => $_clearField(5);
}

/// A node in this reader's catalogue.
class Server extends $pb.GeneratedMessage {
  factory Server({
    $core.String? id,
    ServerDescriptor? descriptor,
    $core.bool? isLocal,
    $1.Timestamp? discoveredAt,
    $core.bool? active,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (descriptor != null) result.descriptor = descriptor;
    if (isLocal != null) result.isLocal = isLocal;
    if (discoveredAt != null) result.discoveredAt = discoveredAt;
    if (active != null) result.active = active;
    return result;
  }

  Server._();

  factory Server.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Server.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Server',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<ServerDescriptor>(2, _omitFieldNames ? '' : 'descriptor',
        subBuilder: ServerDescriptor.create)
    ..aOB(3, _omitFieldNames ? '' : 'isLocal')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'discoveredAt',
        subBuilder: $1.Timestamp.create)
    ..aOB(5, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server copyWith(void Function(Server) updates) =>
      super.copyWith((message) => updates(message as Server)) as Server;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Server create() => Server._();
  @$core.override
  Server createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Server getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Server>(create);
  static Server? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ServerDescriptor get descriptor => $_getN(1);
  @$pb.TagNumber(2)
  set descriptor(ServerDescriptor value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDescriptor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescriptor() => $_clearField(2);
  @$pb.TagNumber(2)
  ServerDescriptor ensureDescriptor() => $_ensure(1);

  /// Whether this row is the node answering the call. Every node stores its own
  /// entry, because a reader points at their origin server whether it is local
  /// or remote, and at most one row may claim it.
  @$pb.TagNumber(3)
  $core.bool get isLocal => $_getBF(2);
  @$pb.TagNumber(3)
  set isLocal($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsLocal() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsLocal() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get discoveredAt => $_getN(3);
  @$pb.TagNumber(4)
  set discoveredAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDiscoveredAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearDiscoveredAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureDiscoveredAt() => $_ensure(3);

  /// Whether the node takes part in replication. Clearing it stops the traffic
  /// without losing what discovery already learned.
  @$pb.TagNumber(5)
  $core.bool get active => $_getBF(4);
  @$pb.TagNumber(5)
  set active($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearActive() => $_clearField(5);
}

/// A reader's permission for one node to hold a copy of their data.
class ReplicaAuthorization extends $pb.GeneratedMessage {
  factory ReplicaAuthorization({
    $core.String? id,
    $core.String? serverId,
    $core.String? serverDomain,
    $1.Timestamp? authorizedAt,
    $core.bool? replicatesFiles,
    $core.bool? active,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (serverId != null) result.serverId = serverId;
    if (serverDomain != null) result.serverDomain = serverDomain;
    if (authorizedAt != null) result.authorizedAt = authorizedAt;
    if (replicatesFiles != null) result.replicatesFiles = replicatesFiles;
    if (active != null) result.active = active;
    return result;
  }

  ReplicaAuthorization._();

  factory ReplicaAuthorization.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplicaAuthorization.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplicaAuthorization',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'serverDomain')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'authorizedAt',
        subBuilder: $1.Timestamp.create)
    ..aOB(5, _omitFieldNames ? '' : 'replicatesFiles')
    ..aOB(6, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicaAuthorization clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicaAuthorization copyWith(void Function(ReplicaAuthorization) updates) =>
      super.copyWith((message) => updates(message as ReplicaAuthorization))
          as ReplicaAuthorization;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplicaAuthorization create() => ReplicaAuthorization._();
  @$core.override
  ReplicaAuthorization createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplicaAuthorization getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplicaAuthorization>(create);
  static ReplicaAuthorization? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  /// Carried alongside the id so that a client can name the node without a
  /// second call.
  @$pb.TagNumber(3)
  $core.String get serverDomain => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverDomain($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerDomain() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerDomain() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get authorizedAt => $_getN(3);
  @$pb.TagNumber(4)
  set authorizedAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthorizedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthorizedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureAuthorizedAt() => $_ensure(3);

  /// Whether the permission covers the e-book files as well as the metadata.
  /// Metadata without the files is the cheap replica a reader is most likely to
  /// want on a node they do not own — and it is why library.ebooks does not
  /// reference the stored objects (D02).
  @$pb.TagNumber(5)
  $core.bool get replicatesFiles => $_getBF(4);
  @$pb.TagNumber(5)
  set replicatesFiles($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReplicatesFiles() => $_has(4);
  @$pb.TagNumber(5)
  void clearReplicatesFiles() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get active => $_getBF(5);
  @$pb.TagNumber(6)
  set active($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearActive() => $_clearField(6);
}

class DiscoverServerRequest extends $pb.GeneratedMessage {
  factory DiscoverServerRequest({
    $core.String? domain,
  }) {
    final result = create();
    if (domain != null) result.domain = domain;
    return result;
  }

  DiscoverServerRequest._();

  factory DiscoverServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscoverServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscoverServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'domain')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverServerRequest copyWith(
          void Function(DiscoverServerRequest) updates) =>
      super.copyWith((message) => updates(message as DiscoverServerRequest))
          as DiscoverServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscoverServerRequest create() => DiscoverServerRequest._();
  @$core.override
  DiscoverServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscoverServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscoverServerRequest>(create);
  static DiscoverServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get domain => $_getSZ(0);
  @$pb.TagNumber(1)
  set domain($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDomain() => $_has(0);
  @$pb.TagNumber(1)
  void clearDomain() => $_clearField(1);
}

class DiscoverServerResponse extends $pb.GeneratedMessage {
  factory DiscoverServerResponse({
    ServerDescriptor? descriptor,
  }) {
    final result = create();
    if (descriptor != null) result.descriptor = descriptor;
    return result;
  }

  DiscoverServerResponse._();

  factory DiscoverServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscoverServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscoverServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<ServerDescriptor>(1, _omitFieldNames ? '' : 'descriptor',
        subBuilder: ServerDescriptor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverServerResponse copyWith(
          void Function(DiscoverServerResponse) updates) =>
      super.copyWith((message) => updates(message as DiscoverServerResponse))
          as DiscoverServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscoverServerResponse create() => DiscoverServerResponse._();
  @$core.override
  DiscoverServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscoverServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscoverServerResponse>(create);
  static DiscoverServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ServerDescriptor get descriptor => $_getN(0);
  @$pb.TagNumber(1)
  set descriptor(ServerDescriptor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDescriptor() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescriptor() => $_clearField(1);
  @$pb.TagNumber(1)
  ServerDescriptor ensureDescriptor() => $_ensure(0);
}

class AddKnownServerRequest extends $pb.GeneratedMessage {
  factory AddKnownServerRequest({
    $core.String? domain,
  }) {
    final result = create();
    if (domain != null) result.domain = domain;
    return result;
  }

  AddKnownServerRequest._();

  factory AddKnownServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddKnownServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddKnownServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'domain')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddKnownServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddKnownServerRequest copyWith(
          void Function(AddKnownServerRequest) updates) =>
      super.copyWith((message) => updates(message as AddKnownServerRequest))
          as AddKnownServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddKnownServerRequest create() => AddKnownServerRequest._();
  @$core.override
  AddKnownServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddKnownServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddKnownServerRequest>(create);
  static AddKnownServerRequest? _defaultInstance;

  /// The domain to discover. The rest of the record is what the node says about
  /// itself: a reader who could type the base URL or the fingerprint by hand
  /// could also pin the wrong one.
  @$pb.TagNumber(1)
  $core.String get domain => $_getSZ(0);
  @$pb.TagNumber(1)
  set domain($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDomain() => $_has(0);
  @$pb.TagNumber(1)
  void clearDomain() => $_clearField(1);
}

class AddKnownServerResponse extends $pb.GeneratedMessage {
  factory AddKnownServerResponse({
    Server? server,
  }) {
    final result = create();
    if (server != null) result.server = server;
    return result;
  }

  AddKnownServerResponse._();

  factory AddKnownServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddKnownServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddKnownServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Server>(1, _omitFieldNames ? '' : 'server', subBuilder: Server.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddKnownServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddKnownServerResponse copyWith(
          void Function(AddKnownServerResponse) updates) =>
      super.copyWith((message) => updates(message as AddKnownServerResponse))
          as AddKnownServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddKnownServerResponse create() => AddKnownServerResponse._();
  @$core.override
  AddKnownServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddKnownServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddKnownServerResponse>(create);
  static AddKnownServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Server get server => $_getN(0);
  @$pb.TagNumber(1)
  set server(Server value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  Server ensureServer() => $_ensure(0);
}

class GetKnownServerRequest extends $pb.GeneratedMessage {
  factory GetKnownServerRequest({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  GetKnownServerRequest._();

  factory GetKnownServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetKnownServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKnownServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKnownServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKnownServerRequest copyWith(
          void Function(GetKnownServerRequest) updates) =>
      super.copyWith((message) => updates(message as GetKnownServerRequest))
          as GetKnownServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetKnownServerRequest create() => GetKnownServerRequest._();
  @$core.override
  GetKnownServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetKnownServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKnownServerRequest>(create);
  static GetKnownServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class GetKnownServerResponse extends $pb.GeneratedMessage {
  factory GetKnownServerResponse({
    Server? server,
  }) {
    final result = create();
    if (server != null) result.server = server;
    return result;
  }

  GetKnownServerResponse._();

  factory GetKnownServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetKnownServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKnownServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Server>(1, _omitFieldNames ? '' : 'server', subBuilder: Server.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKnownServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKnownServerResponse copyWith(
          void Function(GetKnownServerResponse) updates) =>
      super.copyWith((message) => updates(message as GetKnownServerResponse))
          as GetKnownServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetKnownServerResponse create() => GetKnownServerResponse._();
  @$core.override
  GetKnownServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetKnownServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKnownServerResponse>(create);
  static GetKnownServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Server get server => $_getN(0);
  @$pb.TagNumber(1)
  set server(Server value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  Server ensureServer() => $_ensure(0);
}

class ListKnownServersRequest extends $pb.GeneratedMessage {
  factory ListKnownServersRequest({
    $core.bool? includeInactive,
  }) {
    final result = create();
    if (includeInactive != null) result.includeInactive = includeInactive;
    return result;
  }

  ListKnownServersRequest._();

  factory ListKnownServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKnownServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKnownServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includeInactive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKnownServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKnownServersRequest copyWith(
          void Function(ListKnownServersRequest) updates) =>
      super.copyWith((message) => updates(message as ListKnownServersRequest))
          as ListKnownServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKnownServersRequest create() => ListKnownServersRequest._();
  @$core.override
  ListKnownServersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKnownServersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKnownServersRequest>(create);
  static ListKnownServersRequest? _defaultInstance;

  /// Nodes the reader has deactivated are hidden by default.
  @$pb.TagNumber(1)
  $core.bool get includeInactive => $_getBF(0);
  @$pb.TagNumber(1)
  set includeInactive($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIncludeInactive() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeInactive() => $_clearField(1);
}

/// Not paginated. A reader's federation is the handful of nodes they chose.
class ListKnownServersResponse extends $pb.GeneratedMessage {
  factory ListKnownServersResponse({
    $core.Iterable<Server>? servers,
  }) {
    final result = create();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  ListKnownServersResponse._();

  factory ListKnownServersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKnownServersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKnownServersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Server>(1, _omitFieldNames ? '' : 'servers',
        subBuilder: Server.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKnownServersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKnownServersResponse copyWith(
          void Function(ListKnownServersResponse) updates) =>
      super.copyWith((message) => updates(message as ListKnownServersResponse))
          as ListKnownServersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKnownServersResponse create() => ListKnownServersResponse._();
  @$core.override
  ListKnownServersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKnownServersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKnownServersResponse>(create);
  static ListKnownServersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Server> get servers => $_getList(0);
}

class UpdateKnownServerRequest extends $pb.GeneratedMessage {
  factory UpdateKnownServerRequest({
    $core.String? serverId,
    Server? server,
    $2.FieldMask? updateMask,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (server != null) result.server = server;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateKnownServerRequest._();

  factory UpdateKnownServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateKnownServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateKnownServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOM<Server>(2, _omitFieldNames ? '' : 'server', subBuilder: Server.create)
    ..aOM<$2.FieldMask>(3, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $2.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateKnownServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateKnownServerRequest copyWith(
          void Function(UpdateKnownServerRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateKnownServerRequest))
          as UpdateKnownServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateKnownServerRequest create() => UpdateKnownServerRequest._();
  @$core.override
  UpdateKnownServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateKnownServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateKnownServerRequest>(create);
  static UpdateKnownServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  Server get server => $_getN(1);
  @$pb.TagNumber(2)
  set server(Server value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);
  @$pb.TagNumber(2)
  Server ensureServer() => $_ensure(1);

  /// Only `active` may be named.
  @$pb.TagNumber(3)
  $2.FieldMask get updateMask => $_getN(2);
  @$pb.TagNumber(3)
  set updateMask($2.FieldMask value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdateMask() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateMask() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.FieldMask ensureUpdateMask() => $_ensure(2);
}

class UpdateKnownServerResponse extends $pb.GeneratedMessage {
  factory UpdateKnownServerResponse({
    Server? server,
  }) {
    final result = create();
    if (server != null) result.server = server;
    return result;
  }

  UpdateKnownServerResponse._();

  factory UpdateKnownServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateKnownServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateKnownServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Server>(1, _omitFieldNames ? '' : 'server', subBuilder: Server.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateKnownServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateKnownServerResponse copyWith(
          void Function(UpdateKnownServerResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateKnownServerResponse))
          as UpdateKnownServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateKnownServerResponse create() => UpdateKnownServerResponse._();
  @$core.override
  UpdateKnownServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateKnownServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateKnownServerResponse>(create);
  static UpdateKnownServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Server get server => $_getN(0);
  @$pb.TagNumber(1)
  set server(Server value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  Server ensureServer() => $_ensure(0);
}

class RefreshKnownServerRequest extends $pb.GeneratedMessage {
  factory RefreshKnownServerRequest({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  RefreshKnownServerRequest._();

  factory RefreshKnownServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshKnownServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshKnownServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshKnownServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshKnownServerRequest copyWith(
          void Function(RefreshKnownServerRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshKnownServerRequest))
          as RefreshKnownServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshKnownServerRequest create() => RefreshKnownServerRequest._();
  @$core.override
  RefreshKnownServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshKnownServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshKnownServerRequest>(create);
  static RefreshKnownServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class RefreshKnownServerResponse extends $pb.GeneratedMessage {
  factory RefreshKnownServerResponse({
    Server? server,
    $core.bool? certificateFingerprintChanged,
  }) {
    final result = create();
    if (server != null) result.server = server;
    if (certificateFingerprintChanged != null)
      result.certificateFingerprintChanged = certificateFingerprintChanged;
    return result;
  }

  RefreshKnownServerResponse._();

  factory RefreshKnownServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshKnownServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshKnownServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Server>(1, _omitFieldNames ? '' : 'server', subBuilder: Server.create)
    ..aOB(2, _omitFieldNames ? '' : 'certificateFingerprintChanged')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshKnownServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshKnownServerResponse copyWith(
          void Function(RefreshKnownServerResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RefreshKnownServerResponse))
          as RefreshKnownServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshKnownServerResponse create() => RefreshKnownServerResponse._();
  @$core.override
  RefreshKnownServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshKnownServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshKnownServerResponse>(create);
  static RefreshKnownServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Server get server => $_getN(0);
  @$pb.TagNumber(1)
  set server(Server value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  Server ensureServer() => $_ensure(0);

  /// True when the node now presents a different certificate from the one on
  /// record. It is reported rather than applied silently: a rotation and an
  /// interception look identical from here, and the reader is the only party
  /// that can tell them apart.
  @$pb.TagNumber(2)
  $core.bool get certificateFingerprintChanged => $_getBF(1);
  @$pb.TagNumber(2)
  set certificateFingerprintChanged($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCertificateFingerprintChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearCertificateFingerprintChanged() => $_clearField(2);
}

class RemoveKnownServerRequest extends $pb.GeneratedMessage {
  factory RemoveKnownServerRequest({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  RemoveKnownServerRequest._();

  factory RemoveKnownServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveKnownServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveKnownServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveKnownServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveKnownServerRequest copyWith(
          void Function(RemoveKnownServerRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveKnownServerRequest))
          as RemoveKnownServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveKnownServerRequest create() => RemoveKnownServerRequest._();
  @$core.override
  RemoveKnownServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveKnownServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveKnownServerRequest>(create);
  static RemoveKnownServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class RemoveKnownServerResponse extends $pb.GeneratedMessage {
  factory RemoveKnownServerResponse() => create();

  RemoveKnownServerResponse._();

  factory RemoveKnownServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveKnownServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveKnownServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveKnownServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveKnownServerResponse copyWith(
          void Function(RemoveKnownServerResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveKnownServerResponse))
          as RemoveKnownServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveKnownServerResponse create() => RemoveKnownServerResponse._();
  @$core.override
  RemoveKnownServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveKnownServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveKnownServerResponse>(create);
  static RemoveKnownServerResponse? _defaultInstance;
}

class AuthorizeReplicaRequest extends $pb.GeneratedMessage {
  factory AuthorizeReplicaRequest({
    $core.String? serverId,
    $core.bool? replicatesFiles,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (replicatesFiles != null) result.replicatesFiles = replicatesFiles;
    return result;
  }

  AuthorizeReplicaRequest._();

  factory AuthorizeReplicaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthorizeReplicaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthorizeReplicaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOB(2, _omitFieldNames ? '' : 'replicatesFiles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReplicaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReplicaRequest copyWith(
          void Function(AuthorizeReplicaRequest) updates) =>
      super.copyWith((message) => updates(message as AuthorizeReplicaRequest))
          as AuthorizeReplicaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthorizeReplicaRequest create() => AuthorizeReplicaRequest._();
  @$core.override
  AuthorizeReplicaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthorizeReplicaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthorizeReplicaRequest>(create);
  static AuthorizeReplicaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get replicatesFiles => $_getBF(1);
  @$pb.TagNumber(2)
  set replicatesFiles($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReplicatesFiles() => $_has(1);
  @$pb.TagNumber(2)
  void clearReplicatesFiles() => $_clearField(2);
}

class AuthorizeReplicaResponse extends $pb.GeneratedMessage {
  factory AuthorizeReplicaResponse({
    ReplicaAuthorization? authorization,
  }) {
    final result = create();
    if (authorization != null) result.authorization = authorization;
    return result;
  }

  AuthorizeReplicaResponse._();

  factory AuthorizeReplicaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthorizeReplicaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthorizeReplicaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<ReplicaAuthorization>(1, _omitFieldNames ? '' : 'authorization',
        subBuilder: ReplicaAuthorization.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReplicaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReplicaResponse copyWith(
          void Function(AuthorizeReplicaResponse) updates) =>
      super.copyWith((message) => updates(message as AuthorizeReplicaResponse))
          as AuthorizeReplicaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthorizeReplicaResponse create() => AuthorizeReplicaResponse._();
  @$core.override
  AuthorizeReplicaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthorizeReplicaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthorizeReplicaResponse>(create);
  static AuthorizeReplicaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ReplicaAuthorization get authorization => $_getN(0);
  @$pb.TagNumber(1)
  set authorization(ReplicaAuthorization value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAuthorization() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuthorization() => $_clearField(1);
  @$pb.TagNumber(1)
  ReplicaAuthorization ensureAuthorization() => $_ensure(0);
}

class RevokeReplicaRequest extends $pb.GeneratedMessage {
  factory RevokeReplicaRequest({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  RevokeReplicaRequest._();

  factory RevokeReplicaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeReplicaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeReplicaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeReplicaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeReplicaRequest copyWith(void Function(RevokeReplicaRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeReplicaRequest))
          as RevokeReplicaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeReplicaRequest create() => RevokeReplicaRequest._();
  @$core.override
  RevokeReplicaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeReplicaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeReplicaRequest>(create);
  static RevokeReplicaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class RevokeReplicaResponse extends $pb.GeneratedMessage {
  factory RevokeReplicaResponse() => create();

  RevokeReplicaResponse._();

  factory RevokeReplicaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeReplicaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeReplicaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeReplicaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeReplicaResponse copyWith(
          void Function(RevokeReplicaResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeReplicaResponse))
          as RevokeReplicaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeReplicaResponse create() => RevokeReplicaResponse._();
  @$core.override
  RevokeReplicaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeReplicaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeReplicaResponse>(create);
  static RevokeReplicaResponse? _defaultInstance;
}

class ListReplicaAuthorizationsRequest extends $pb.GeneratedMessage {
  factory ListReplicaAuthorizationsRequest({
    $core.bool? includeInactive,
  }) {
    final result = create();
    if (includeInactive != null) result.includeInactive = includeInactive;
    return result;
  }

  ListReplicaAuthorizationsRequest._();

  factory ListReplicaAuthorizationsRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReplicaAuthorizationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReplicaAuthorizationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includeInactive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplicaAuthorizationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplicaAuthorizationsRequest copyWith(
          void Function(ListReplicaAuthorizationsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListReplicaAuthorizationsRequest))
          as ListReplicaAuthorizationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReplicaAuthorizationsRequest create() =>
      ListReplicaAuthorizationsRequest._();
  @$core.override
  ListReplicaAuthorizationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReplicaAuthorizationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReplicaAuthorizationsRequest>(
          create);
  static ListReplicaAuthorizationsRequest? _defaultInstance;

  /// Revoked authorizations are hidden by default, and are what explains a peer
  /// that still holds data.
  @$pb.TagNumber(1)
  $core.bool get includeInactive => $_getBF(0);
  @$pb.TagNumber(1)
  set includeInactive($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIncludeInactive() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeInactive() => $_clearField(1);
}

class ListReplicaAuthorizationsResponse extends $pb.GeneratedMessage {
  factory ListReplicaAuthorizationsResponse({
    $core.Iterable<ReplicaAuthorization>? authorizations,
  }) {
    final result = create();
    if (authorizations != null) result.authorizations.addAll(authorizations);
    return result;
  }

  ListReplicaAuthorizationsResponse._();

  factory ListReplicaAuthorizationsResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReplicaAuthorizationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReplicaAuthorizationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<ReplicaAuthorization>(1, _omitFieldNames ? '' : 'authorizations',
        subBuilder: ReplicaAuthorization.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplicaAuthorizationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplicaAuthorizationsResponse copyWith(
          void Function(ListReplicaAuthorizationsResponse) updates) =>
      super.copyWith((message) =>
              updates(message as ListReplicaAuthorizationsResponse))
          as ListReplicaAuthorizationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReplicaAuthorizationsResponse create() =>
      ListReplicaAuthorizationsResponse._();
  @$core.override
  ListReplicaAuthorizationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReplicaAuthorizationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReplicaAuthorizationsResponse>(
          create);
  static ListReplicaAuthorizationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReplicaAuthorization> get authorizations => $_getList(0);
}

class MigrateHomeServerRequest extends $pb.GeneratedMessage {
  factory MigrateHomeServerRequest({
    $core.String? localName,
    $core.String? displayName,
    $core.String? email,
    $core.String? password,
    $core.String? previousFederatedId,
    $core.Iterable<$3.Device>? devices,
  }) {
    final result = create();
    if (localName != null) result.localName = localName;
    if (displayName != null) result.displayName = displayName;
    if (email != null) result.email = email;
    if (password != null) result.password = password;
    if (previousFederatedId != null)
      result.previousFederatedId = previousFederatedId;
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  MigrateHomeServerRequest._();

  factory MigrateHomeServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateHomeServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateHomeServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'localName')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'password')
    ..aOS(5, _omitFieldNames ? '' : 'previousFederatedId')
    ..pPM<$3.Device>(6, _omitFieldNames ? '' : 'devices',
        subBuilder: $3.Device.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateHomeServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateHomeServerRequest copyWith(
          void Function(MigrateHomeServerRequest) updates) =>
      super.copyWith((message) => updates(message as MigrateHomeServerRequest))
          as MigrateHomeServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateHomeServerRequest create() => MigrateHomeServerRequest._();
  @$core.override
  MigrateHomeServerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateHomeServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateHomeServerRequest>(create);
  static MigrateHomeServerRequest? _defaultInstance;

  /// The account as it will exist on this node. The local name may be the one
  /// the reader had, if it is free here; the domain half is this node, so the
  /// identifier changes either way.
  @$pb.TagNumber(1)
  $core.String get localName => $_getSZ(0);
  @$pb.TagNumber(1)
  set localName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLocalName() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocalName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => $_clearField(4);

  /// The identifier the reader is arriving from, recorded as provenance. This
  /// node cannot verify it — see C11 — and must not treat it as authenticated.
  @$pb.TagNumber(5)
  $core.String get previousFederatedId => $_getSZ(4);
  @$pb.TagNumber(5)
  set previousFederatedId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPreviousFederatedId() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreviousFederatedId() => $_clearField(5);

  /// The devices to adopt, with the ids they already hold. Sending a device
  /// twice is not an error; omitting one is, and the omission surfaces later as
  /// a log this node cannot insert.
  @$pb.TagNumber(6)
  $pb.PbList<$3.Device> get devices => $_getList(5);
}

class MigrateHomeServerResponse extends $pb.GeneratedMessage {
  factory MigrateHomeServerResponse({
    $3.User? user,
    $core.Iterable<$3.Device>? devices,
    $3.Session? session,
  }) {
    final result = create();
    if (user != null) result.user = user;
    if (devices != null) result.devices.addAll(devices);
    if (session != null) result.session = session;
    return result;
  }

  MigrateHomeServerResponse._();

  factory MigrateHomeServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateHomeServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateHomeServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<$3.User>(1, _omitFieldNames ? '' : 'user', subBuilder: $3.User.create)
    ..pPM<$3.Device>(2, _omitFieldNames ? '' : 'devices',
        subBuilder: $3.Device.create)
    ..aOM<$3.Session>(3, _omitFieldNames ? '' : 'session',
        subBuilder: $3.Session.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateHomeServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateHomeServerResponse copyWith(
          void Function(MigrateHomeServerResponse) updates) =>
      super.copyWith((message) => updates(message as MigrateHomeServerResponse))
          as MigrateHomeServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateHomeServerResponse create() => MigrateHomeServerResponse._();
  @$core.override
  MigrateHomeServerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateHomeServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateHomeServerResponse>(create);
  static MigrateHomeServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $3.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($3.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.User ensureUser() => $_ensure(0);

  /// The devices as adopted, which a client should compare against what it sent
  /// before pushing anything.
  @$pb.TagNumber(2)
  $pb.PbList<$3.Device> get devices => $_getList(1);

  /// For the calling device, so that it can begin pushing its local log
  /// immediately. The other devices log in as they normally would.
  @$pb.TagNumber(3)
  $3.Session get session => $_getN(2);
  @$pb.TagNumber(3)
  set session($3.Session value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSession() => $_has(2);
  @$pb.TagNumber(3)
  void clearSession() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.Session ensureSession() => $_ensure(2);
}

/// A reader as a replica holds them: the identifier every table of theirs
/// hangs off, and the two names. No address and no password, which is what
/// makes a replicated reader one this node does not authenticate (C03, RN08).
class ReplicatedReader extends $pb.GeneratedMessage {
  factory ReplicatedReader({
    $core.String? id,
    $core.String? localName,
    $core.String? displayName,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (localName != null) result.localName = localName;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  ReplicatedReader._();

  factory ReplicatedReader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplicatedReader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplicatedReader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'localName')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicatedReader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicatedReader copyWith(void Function(ReplicatedReader) updates) =>
      super.copyWith((message) => updates(message as ReplicatedReader))
          as ReplicatedReader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplicatedReader create() => ReplicatedReader._();
  @$core.override
  ReplicatedReader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplicatedReader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplicatedReader>(create);
  static ReplicatedReader? _defaultInstance;

  /// The reader's identifier on the origin, kept as it is. Every operation
  /// and every row of the reader's names it, so a replica that minted another
  /// would hold a history about somebody it cannot find.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The first half of @local_name:domain. The domain is the origin's, which
  /// the destination knows from its own catalogue.
  @$pb.TagNumber(2)
  $core.String get localName => $_getSZ(1);
  @$pb.TagNumber(2)
  set localName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalName() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);
}

/// A device as a replica holds it: the identifier every vector clock entry is
/// keyed by, and what the reader called it. C11 is why the identifier travels
/// rather than being minted afresh.
class ReplicatedDevice extends $pb.GeneratedMessage {
  factory ReplicatedDevice({
    $core.String? id,
    $core.String? name,
    $core.String? platform,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    return result;
  }

  ReplicatedDevice._();

  factory ReplicatedDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplicatedDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplicatedDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'platform')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicatedDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicatedDevice copyWith(void Function(ReplicatedDevice) updates) =>
      super.copyWith((message) => updates(message as ReplicatedDevice))
          as ReplicatedDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplicatedDevice create() => ReplicatedDevice._();
  @$core.override
  ReplicatedDevice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplicatedDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplicatedDevice>(create);
  static ReplicatedDevice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get platform => $_getSZ(2);
  @$pb.TagNumber(3)
  set platform($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);
}

class AdmitReplicaRequest extends $pb.GeneratedMessage {
  factory AdmitReplicaRequest({
    ReplicatedReader? reader,
    $core.Iterable<ReplicatedDevice>? devices,
    $core.bool? replicatesFiles,
  }) {
    final result = create();
    if (reader != null) result.reader = reader;
    if (devices != null) result.devices.addAll(devices);
    if (replicatesFiles != null) result.replicatesFiles = replicatesFiles;
    return result;
  }

  AdmitReplicaRequest._();

  factory AdmitReplicaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdmitReplicaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdmitReplicaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<ReplicatedReader>(1, _omitFieldNames ? '' : 'reader',
        subBuilder: ReplicatedReader.create)
    ..pPM<ReplicatedDevice>(2, _omitFieldNames ? '' : 'devices',
        subBuilder: ReplicatedDevice.create)
    ..aOB(3, _omitFieldNames ? '' : 'replicatesFiles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdmitReplicaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdmitReplicaRequest copyWith(void Function(AdmitReplicaRequest) updates) =>
      super.copyWith((message) => updates(message as AdmitReplicaRequest))
          as AdmitReplicaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdmitReplicaRequest create() => AdmitReplicaRequest._();
  @$core.override
  AdmitReplicaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdmitReplicaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdmitReplicaRequest>(create);
  static AdmitReplicaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ReplicatedReader get reader => $_getN(0);
  @$pb.TagNumber(1)
  set reader(ReplicatedReader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReader() => $_has(0);
  @$pb.TagNumber(1)
  void clearReader() => $_clearField(1);
  @$pb.TagNumber(1)
  ReplicatedReader ensureReader() => $_ensure(0);

  /// Every device the reader has bound, active or not: an operation authored
  /// by a device since unbound is still an operation the replica has to be
  /// able to attribute.
  @$pb.TagNumber(2)
  $pb.PbList<ReplicatedDevice> get devices => $_getList(1);

  /// Whether the permission covers the e-book files as well as the metadata,
  /// as the reader granted it.
  @$pb.TagNumber(3)
  $core.bool get replicatesFiles => $_getBF(2);
  @$pb.TagNumber(3)
  set replicatesFiles($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplicatesFiles() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplicatesFiles() => $_clearField(3);
}

class AdmitReplicaResponse extends $pb.GeneratedMessage {
  factory AdmitReplicaResponse() => create();

  AdmitReplicaResponse._();

  factory AdmitReplicaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdmitReplicaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdmitReplicaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdmitReplicaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdmitReplicaResponse copyWith(void Function(AdmitReplicaResponse) updates) =>
      super.copyWith((message) => updates(message as AdmitReplicaResponse))
          as AdmitReplicaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdmitReplicaResponse create() => AdmitReplicaResponse._();
  @$core.override
  AdmitReplicaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdmitReplicaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdmitReplicaResponse>(create);
  static AdmitReplicaResponse? _defaultInstance;
}

class WithdrawReplicaRequest extends $pb.GeneratedMessage {
  factory WithdrawReplicaRequest({
    $core.String? userId,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    return result;
  }

  WithdrawReplicaRequest._();

  factory WithdrawReplicaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WithdrawReplicaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WithdrawReplicaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WithdrawReplicaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WithdrawReplicaRequest copyWith(
          void Function(WithdrawReplicaRequest) updates) =>
      super.copyWith((message) => updates(message as WithdrawReplicaRequest))
          as WithdrawReplicaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WithdrawReplicaRequest create() => WithdrawReplicaRequest._();
  @$core.override
  WithdrawReplicaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WithdrawReplicaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WithdrawReplicaRequest>(create);
  static WithdrawReplicaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

class WithdrawReplicaResponse extends $pb.GeneratedMessage {
  factory WithdrawReplicaResponse() => create();

  WithdrawReplicaResponse._();

  factory WithdrawReplicaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WithdrawReplicaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WithdrawReplicaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WithdrawReplicaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WithdrawReplicaResponse copyWith(
          void Function(WithdrawReplicaResponse) updates) =>
      super.copyWith((message) => updates(message as WithdrawReplicaResponse))
          as WithdrawReplicaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WithdrawReplicaResponse create() => WithdrawReplicaResponse._();
  @$core.override
  WithdrawReplicaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WithdrawReplicaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WithdrawReplicaResponse>(create);
  static WithdrawReplicaResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

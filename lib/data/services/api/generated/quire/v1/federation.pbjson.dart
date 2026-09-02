// This is a generated file - do not edit.
//
// Generated from quire/v1/federation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use serverDescriptorDescriptor instead')
const ServerDescriptor$json = {
  '1': 'ServerDescriptor',
  '2': [
    {'1': 'domain', '3': 1, '4': 1, '5': 9, '10': 'domain'},
    {'1': 'base_url', '3': 2, '4': 1, '5': 9, '10': 'baseUrl'},
    {
      '1': 'jwks_uri',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'jwksUri',
      '17': true
    },
    {
      '1': 'certificate_fingerprint',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'certificateFingerprint',
      '17': true
    },
    {'1': 'grpc', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'grpc', '17': true},
  ],
  '8': [
    {'1': '_jwks_uri'},
    {'1': '_certificate_fingerprint'},
    {'1': '_grpc'},
  ],
};

/// Descriptor for `ServerDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverDescriptorDescriptor = $convert.base64Decode(
    'ChBTZXJ2ZXJEZXNjcmlwdG9yEhYKBmRvbWFpbhgBIAEoCVIGZG9tYWluEhkKCGJhc2VfdXJsGA'
    'IgASgJUgdiYXNlVXJsEh4KCGp3a3NfdXJpGAMgASgJSABSB2p3a3NVcmmIAQESPAoXY2VydGlm'
    'aWNhdGVfZmluZ2VycHJpbnQYBCABKAlIAVIWY2VydGlmaWNhdGVGaW5nZXJwcmludIgBARIXCg'
    'RncnBjGAUgASgJSAJSBGdycGOIAQFCCwoJX2p3a3NfdXJpQhoKGF9jZXJ0aWZpY2F0ZV9maW5n'
    'ZXJwcmludEIHCgVfZ3JwYw==');

@$core.Deprecated('Use serverDescriptor instead')
const Server$json = {
  '1': 'Server',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'descriptor',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.ServerDescriptor',
      '10': 'descriptor'
    },
    {'1': 'is_local', '3': 3, '4': 1, '5': 8, '10': 'isLocal'},
    {
      '1': 'discovered_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '9': 0,
      '10': 'discoveredAt',
      '17': true
    },
    {'1': 'active', '3': 5, '4': 1, '5': 8, '10': 'active'},
  ],
  '8': [
    {'1': '_discovered_at'},
  ],
};

/// Descriptor for `Server`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverDescriptor = $convert.base64Decode(
    'CgZTZXJ2ZXISDgoCaWQYASABKAlSAmlkEjoKCmRlc2NyaXB0b3IYAiABKAsyGi5xdWlyZS52MS'
    '5TZXJ2ZXJEZXNjcmlwdG9yUgpkZXNjcmlwdG9yEhkKCGlzX2xvY2FsGAMgASgIUgdpc0xvY2Fs'
    'EkQKDWRpc2NvdmVyZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSDG'
    'Rpc2NvdmVyZWRBdIgBARIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZUIQCg5fZGlzY292ZXJlZF9h'
    'dA==');

@$core.Deprecated('Use replicaAuthorizationDescriptor instead')
const ReplicaAuthorization$json = {
  '1': 'ReplicaAuthorization',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'server_domain', '3': 3, '4': 1, '5': 9, '10': 'serverDomain'},
    {
      '1': 'authorized_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'authorizedAt'
    },
    {'1': 'replicates_files', '3': 5, '4': 1, '5': 8, '10': 'replicatesFiles'},
    {'1': 'active', '3': 6, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `ReplicaAuthorization`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replicaAuthorizationDescriptor = $convert.base64Decode(
    'ChRSZXBsaWNhQXV0aG9yaXphdGlvbhIOCgJpZBgBIAEoCVICaWQSGwoJc2VydmVyX2lkGAIgAS'
    'gJUghzZXJ2ZXJJZBIjCg1zZXJ2ZXJfZG9tYWluGAMgASgJUgxzZXJ2ZXJEb21haW4SPwoNYXV0'
    'aG9yaXplZF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDGF1dGhvcml6ZW'
    'RBdBIpChByZXBsaWNhdGVzX2ZpbGVzGAUgASgIUg9yZXBsaWNhdGVzRmlsZXMSFgoGYWN0aXZl'
    'GAYgASgIUgZhY3RpdmU=');

@$core.Deprecated('Use discoverServerRequestDescriptor instead')
const DiscoverServerRequest$json = {
  '1': 'DiscoverServerRequest',
  '2': [
    {'1': 'domain', '3': 1, '4': 1, '5': 9, '10': 'domain'},
  ],
};

/// Descriptor for `DiscoverServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoverServerRequestDescriptor =
    $convert.base64Decode(
        'ChVEaXNjb3ZlclNlcnZlclJlcXVlc3QSFgoGZG9tYWluGAEgASgJUgZkb21haW4=');

@$core.Deprecated('Use discoverServerResponseDescriptor instead')
const DiscoverServerResponse$json = {
  '1': 'DiscoverServerResponse',
  '2': [
    {
      '1': 'descriptor',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.ServerDescriptor',
      '10': 'descriptor'
    },
  ],
};

/// Descriptor for `DiscoverServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoverServerResponseDescriptor =
    $convert.base64Decode(
        'ChZEaXNjb3ZlclNlcnZlclJlc3BvbnNlEjoKCmRlc2NyaXB0b3IYASABKAsyGi5xdWlyZS52MS'
        '5TZXJ2ZXJEZXNjcmlwdG9yUgpkZXNjcmlwdG9y');

@$core.Deprecated('Use addKnownServerRequestDescriptor instead')
const AddKnownServerRequest$json = {
  '1': 'AddKnownServerRequest',
  '2': [
    {'1': 'domain', '3': 1, '4': 1, '5': 9, '10': 'domain'},
  ],
};

/// Descriptor for `AddKnownServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addKnownServerRequestDescriptor =
    $convert.base64Decode(
        'ChVBZGRLbm93blNlcnZlclJlcXVlc3QSFgoGZG9tYWluGAEgASgJUgZkb21haW4=');

@$core.Deprecated('Use addKnownServerResponseDescriptor instead')
const AddKnownServerResponse$json = {
  '1': 'AddKnownServerResponse',
  '2': [
    {
      '1': 'server',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'server'
    },
  ],
};

/// Descriptor for `AddKnownServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addKnownServerResponseDescriptor =
    $convert.base64Decode(
        'ChZBZGRLbm93blNlcnZlclJlc3BvbnNlEigKBnNlcnZlchgBIAEoCzIQLnF1aXJlLnYxLlNlcn'
        'ZlclIGc2VydmVy');

@$core.Deprecated('Use getKnownServerRequestDescriptor instead')
const GetKnownServerRequest$json = {
  '1': 'GetKnownServerRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `GetKnownServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKnownServerRequestDescriptor = $convert.base64Decode(
    'ChVHZXRLbm93blNlcnZlclJlcXVlc3QSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZA==');

@$core.Deprecated('Use getKnownServerResponseDescriptor instead')
const GetKnownServerResponse$json = {
  '1': 'GetKnownServerResponse',
  '2': [
    {
      '1': 'server',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'server'
    },
  ],
};

/// Descriptor for `GetKnownServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKnownServerResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXRLbm93blNlcnZlclJlc3BvbnNlEigKBnNlcnZlchgBIAEoCzIQLnF1aXJlLnYxLlNlcn'
        'ZlclIGc2VydmVy');

@$core.Deprecated('Use listKnownServersRequestDescriptor instead')
const ListKnownServersRequest$json = {
  '1': 'ListKnownServersRequest',
  '2': [
    {'1': 'include_inactive', '3': 1, '4': 1, '5': 8, '10': 'includeInactive'},
  ],
};

/// Descriptor for `ListKnownServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKnownServersRequestDescriptor =
    $convert.base64Decode(
        'ChdMaXN0S25vd25TZXJ2ZXJzUmVxdWVzdBIpChBpbmNsdWRlX2luYWN0aXZlGAEgASgIUg9pbm'
        'NsdWRlSW5hY3RpdmU=');

@$core.Deprecated('Use listKnownServersResponseDescriptor instead')
const ListKnownServersResponse$json = {
  '1': 'ListKnownServersResponse',
  '2': [
    {
      '1': 'servers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'servers'
    },
  ],
};

/// Descriptor for `ListKnownServersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKnownServersResponseDescriptor =
    $convert.base64Decode(
        'ChhMaXN0S25vd25TZXJ2ZXJzUmVzcG9uc2USKgoHc2VydmVycxgBIAMoCzIQLnF1aXJlLnYxLl'
        'NlcnZlclIHc2VydmVycw==');

@$core.Deprecated('Use updateKnownServerRequestDescriptor instead')
const UpdateKnownServerRequest$json = {
  '1': 'UpdateKnownServerRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {
      '1': 'server',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'server'
    },
    {
      '1': 'update_mask',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '10': 'updateMask'
    },
  ],
};

/// Descriptor for `UpdateKnownServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateKnownServerRequestDescriptor = $convert.base64Decode(
    'ChhVcGRhdGVLbm93blNlcnZlclJlcXVlc3QSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZB'
    'IoCgZzZXJ2ZXIYAiABKAsyEC5xdWlyZS52MS5TZXJ2ZXJSBnNlcnZlchI7Cgt1cGRhdGVfbWFz'
    'axgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2s=');

@$core.Deprecated('Use updateKnownServerResponseDescriptor instead')
const UpdateKnownServerResponse$json = {
  '1': 'UpdateKnownServerResponse',
  '2': [
    {
      '1': 'server',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'server'
    },
  ],
};

/// Descriptor for `UpdateKnownServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateKnownServerResponseDescriptor =
    $convert.base64Decode(
        'ChlVcGRhdGVLbm93blNlcnZlclJlc3BvbnNlEigKBnNlcnZlchgBIAEoCzIQLnF1aXJlLnYxLl'
        'NlcnZlclIGc2VydmVy');

@$core.Deprecated('Use refreshKnownServerRequestDescriptor instead')
const RefreshKnownServerRequest$json = {
  '1': 'RefreshKnownServerRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `RefreshKnownServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshKnownServerRequestDescriptor =
    $convert.base64Decode(
        'ChlSZWZyZXNoS25vd25TZXJ2ZXJSZXF1ZXN0EhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySW'
        'Q=');

@$core.Deprecated('Use refreshKnownServerResponseDescriptor instead')
const RefreshKnownServerResponse$json = {
  '1': 'RefreshKnownServerResponse',
  '2': [
    {
      '1': 'server',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Server',
      '10': 'server'
    },
    {
      '1': 'certificate_fingerprint_changed',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'certificateFingerprintChanged'
    },
  ],
};

/// Descriptor for `RefreshKnownServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshKnownServerResponseDescriptor =
    $convert.base64Decode(
        'ChpSZWZyZXNoS25vd25TZXJ2ZXJSZXNwb25zZRIoCgZzZXJ2ZXIYASABKAsyEC5xdWlyZS52MS'
        '5TZXJ2ZXJSBnNlcnZlchJGCh9jZXJ0aWZpY2F0ZV9maW5nZXJwcmludF9jaGFuZ2VkGAIgASgI'
        'Uh1jZXJ0aWZpY2F0ZUZpbmdlcnByaW50Q2hhbmdlZA==');

@$core.Deprecated('Use removeKnownServerRequestDescriptor instead')
const RemoveKnownServerRequest$json = {
  '1': 'RemoveKnownServerRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `RemoveKnownServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeKnownServerRequestDescriptor =
    $convert.base64Decode(
        'ChhSZW1vdmVLbm93blNlcnZlclJlcXVlc3QSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZA'
        '==');

@$core.Deprecated('Use removeKnownServerResponseDescriptor instead')
const RemoveKnownServerResponse$json = {
  '1': 'RemoveKnownServerResponse',
};

/// Descriptor for `RemoveKnownServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeKnownServerResponseDescriptor =
    $convert.base64Decode('ChlSZW1vdmVLbm93blNlcnZlclJlc3BvbnNl');

@$core.Deprecated('Use authorizeReplicaRequestDescriptor instead')
const AuthorizeReplicaRequest$json = {
  '1': 'AuthorizeReplicaRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'replicates_files', '3': 2, '4': 1, '5': 8, '10': 'replicatesFiles'},
  ],
};

/// Descriptor for `AuthorizeReplicaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorizeReplicaRequestDescriptor =
    $convert.base64Decode(
        'ChdBdXRob3JpemVSZXBsaWNhUmVxdWVzdBIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklkEi'
        'kKEHJlcGxpY2F0ZXNfZmlsZXMYAiABKAhSD3JlcGxpY2F0ZXNGaWxlcw==');

@$core.Deprecated('Use authorizeReplicaResponseDescriptor instead')
const AuthorizeReplicaResponse$json = {
  '1': 'AuthorizeReplicaResponse',
  '2': [
    {
      '1': 'authorization',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.ReplicaAuthorization',
      '10': 'authorization'
    },
  ],
};

/// Descriptor for `AuthorizeReplicaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorizeReplicaResponseDescriptor =
    $convert.base64Decode(
        'ChhBdXRob3JpemVSZXBsaWNhUmVzcG9uc2USRAoNYXV0aG9yaXphdGlvbhgBIAEoCzIeLnF1aX'
        'JlLnYxLlJlcGxpY2FBdXRob3JpemF0aW9uUg1hdXRob3JpemF0aW9u');

@$core.Deprecated('Use revokeReplicaRequestDescriptor instead')
const RevokeReplicaRequest$json = {
  '1': 'RevokeReplicaRequest',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `RevokeReplicaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeReplicaRequestDescriptor =
    $convert.base64Decode(
        'ChRSZXZva2VSZXBsaWNhUmVxdWVzdBIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklk');

@$core.Deprecated('Use revokeReplicaResponseDescriptor instead')
const RevokeReplicaResponse$json = {
  '1': 'RevokeReplicaResponse',
};

/// Descriptor for `RevokeReplicaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeReplicaResponseDescriptor =
    $convert.base64Decode('ChVSZXZva2VSZXBsaWNhUmVzcG9uc2U=');

@$core.Deprecated('Use listReplicaAuthorizationsRequestDescriptor instead')
const ListReplicaAuthorizationsRequest$json = {
  '1': 'ListReplicaAuthorizationsRequest',
  '2': [
    {'1': 'include_inactive', '3': 1, '4': 1, '5': 8, '10': 'includeInactive'},
  ],
};

/// Descriptor for `ListReplicaAuthorizationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReplicaAuthorizationsRequestDescriptor =
    $convert.base64Decode(
        'CiBMaXN0UmVwbGljYUF1dGhvcml6YXRpb25zUmVxdWVzdBIpChBpbmNsdWRlX2luYWN0aXZlGA'
        'EgASgIUg9pbmNsdWRlSW5hY3RpdmU=');

@$core.Deprecated('Use listReplicaAuthorizationsResponseDescriptor instead')
const ListReplicaAuthorizationsResponse$json = {
  '1': 'ListReplicaAuthorizationsResponse',
  '2': [
    {
      '1': 'authorizations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.ReplicaAuthorization',
      '10': 'authorizations'
    },
  ],
};

/// Descriptor for `ListReplicaAuthorizationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReplicaAuthorizationsResponseDescriptor =
    $convert.base64Decode(
        'CiFMaXN0UmVwbGljYUF1dGhvcml6YXRpb25zUmVzcG9uc2USRgoOYXV0aG9yaXphdGlvbnMYAS'
        'ADKAsyHi5xdWlyZS52MS5SZXBsaWNhQXV0aG9yaXphdGlvblIOYXV0aG9yaXphdGlvbnM=');

@$core.Deprecated('Use migrateHomeServerRequestDescriptor instead')
const MigrateHomeServerRequest$json = {
  '1': 'MigrateHomeServerRequest',
  '2': [
    {'1': 'local_name', '3': 1, '4': 1, '5': 9, '10': 'localName'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 4, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'previous_federated_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'previousFederatedId'
    },
    {
      '1': 'devices',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'devices'
    },
  ],
};

/// Descriptor for `MigrateHomeServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateHomeServerRequestDescriptor = $convert.base64Decode(
    'ChhNaWdyYXRlSG9tZVNlcnZlclJlcXVlc3QSHQoKbG9jYWxfbmFtZRgBIAEoCVIJbG9jYWxOYW'
    '1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSFAoFZW1haWwYAyABKAlSBWVt'
    'YWlsEhoKCHBhc3N3b3JkGAQgASgJUghwYXNzd29yZBIyChVwcmV2aW91c19mZWRlcmF0ZWRfaW'
    'QYBSABKAlSE3ByZXZpb3VzRmVkZXJhdGVkSWQSKgoHZGV2aWNlcxgGIAMoCzIQLnF1aXJlLnYx'
    'LkRldmljZVIHZGV2aWNlcw==');

@$core.Deprecated('Use migrateHomeServerResponseDescriptor instead')
const MigrateHomeServerResponse$json = {
  '1': 'MigrateHomeServerResponse',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
    {
      '1': 'devices',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'devices'
    },
    {
      '1': 'session',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `MigrateHomeServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateHomeServerResponseDescriptor = $convert.base64Decode(
    'ChlNaWdyYXRlSG9tZVNlcnZlclJlc3BvbnNlEiIKBHVzZXIYASABKAsyDi5xdWlyZS52MS5Vc2'
    'VyUgR1c2VyEioKB2RldmljZXMYAiADKAsyEC5xdWlyZS52MS5EZXZpY2VSB2RldmljZXMSKwoH'
    'c2Vzc2lvbhgDIAEoCzIRLnF1aXJlLnYxLlNlc3Npb25SB3Nlc3Npb24=');

@$core.Deprecated('Use replicatedReaderDescriptor instead')
const ReplicatedReader$json = {
  '1': 'ReplicatedReader',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'local_name', '3': 2, '4': 1, '5': 9, '10': 'localName'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `ReplicatedReader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replicatedReaderDescriptor = $convert.base64Decode(
    'ChBSZXBsaWNhdGVkUmVhZGVyEg4KAmlkGAEgASgJUgJpZBIdCgpsb2NhbF9uYW1lGAIgASgJUg'
    'lsb2NhbE5hbWUSIQoMZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZQ==');

@$core.Deprecated('Use replicatedDeviceDescriptor instead')
const ReplicatedDevice$json = {
  '1': 'ReplicatedDevice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'platform', '3': 3, '4': 1, '5': 9, '10': 'platform'},
  ],
};

/// Descriptor for `ReplicatedDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replicatedDeviceDescriptor = $convert.base64Decode(
    'ChBSZXBsaWNhdGVkRGV2aWNlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEh'
    'oKCHBsYXRmb3JtGAMgASgJUghwbGF0Zm9ybQ==');

@$core.Deprecated('Use admitReplicaRequestDescriptor instead')
const AdmitReplicaRequest$json = {
  '1': 'AdmitReplicaRequest',
  '2': [
    {
      '1': 'reader',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.ReplicatedReader',
      '10': 'reader'
    },
    {
      '1': 'devices',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.ReplicatedDevice',
      '10': 'devices'
    },
    {'1': 'replicates_files', '3': 3, '4': 1, '5': 8, '10': 'replicatesFiles'},
  ],
};

/// Descriptor for `AdmitReplicaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List admitReplicaRequestDescriptor = $convert.base64Decode(
    'ChNBZG1pdFJlcGxpY2FSZXF1ZXN0EjIKBnJlYWRlchgBIAEoCzIaLnF1aXJlLnYxLlJlcGxpY2'
    'F0ZWRSZWFkZXJSBnJlYWRlchI0CgdkZXZpY2VzGAIgAygLMhoucXVpcmUudjEuUmVwbGljYXRl'
    'ZERldmljZVIHZGV2aWNlcxIpChByZXBsaWNhdGVzX2ZpbGVzGAMgASgIUg9yZXBsaWNhdGVzRm'
    'lsZXM=');

@$core.Deprecated('Use admitReplicaResponseDescriptor instead')
const AdmitReplicaResponse$json = {
  '1': 'AdmitReplicaResponse',
};

/// Descriptor for `AdmitReplicaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List admitReplicaResponseDescriptor =
    $convert.base64Decode('ChRBZG1pdFJlcGxpY2FSZXNwb25zZQ==');

@$core.Deprecated('Use withdrawReplicaRequestDescriptor instead')
const WithdrawReplicaRequest$json = {
  '1': 'WithdrawReplicaRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `WithdrawReplicaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List withdrawReplicaRequestDescriptor =
    $convert.base64Decode(
        'ChZXaXRoZHJhd1JlcGxpY2FSZXF1ZXN0EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZA==');

@$core.Deprecated('Use withdrawReplicaResponseDescriptor instead')
const WithdrawReplicaResponse$json = {
  '1': 'WithdrawReplicaResponse',
};

/// Descriptor for `WithdrawReplicaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List withdrawReplicaResponseDescriptor =
    $convert.base64Decode('ChdXaXRoZHJhd1JlcGxpY2FSZXNwb25zZQ==');

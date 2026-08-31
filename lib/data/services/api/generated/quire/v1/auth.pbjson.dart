// This is a generated file - do not edit.
//
// Generated from quire/v1/auth.proto.

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

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'local_name', '3': 2, '4': 1, '5': 9, '10': 'localName'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'origin_server_domain',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'originServerDomain'
    },
    {'1': 'federated_id', '3': 5, '4': 1, '5': 9, '10': 'federatedId'},
    {'1': 'email', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'email', '17': true},
    {
      '1': 'created_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
  '8': [
    {'1': '_email'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIdCgpsb2NhbF9uYW1lGAIgASgJUglsb2NhbE5hbWUSIQ'
    'oMZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZRIwChRvcmlnaW5fc2VydmVyX2RvbWFp'
    'bhgEIAEoCVISb3JpZ2luU2VydmVyRG9tYWluEiEKDGZlZGVyYXRlZF9pZBgFIAEoCVILZmVkZX'
    'JhdGVkSWQSGQoFZW1haWwYBiABKAlIAFIFZW1haWyIAQESOQoKY3JlYXRlZF9hdBgHIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdEIICgZfZW1haWw=');

@$core.Deprecated('Use deviceDescriptor instead')
const Device$json = {
  '1': 'Device',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'platform', '3': 3, '4': 1, '5': 9, '10': 'platform'},
    {
      '1': 'last_synced_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '9': 0,
      '10': 'lastSyncedAt',
      '17': true
    },
    {'1': 'active', '3': 5, '4': 1, '5': 8, '10': 'active'},
  ],
  '8': [
    {'1': '_last_synced_at'},
  ],
};

/// Descriptor for `Device`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceDescriptor = $convert.base64Decode(
    'CgZEZXZpY2USDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGgoIcGxhdGZvcm'
    '0YAyABKAlSCHBsYXRmb3JtEkUKDmxhc3Rfc3luY2VkX2F0GAQgASgLMhouZ29vZ2xlLnByb3Rv'
    'YnVmLlRpbWVzdGFtcEgAUgxsYXN0U3luY2VkQXSIAQESFgoGYWN0aXZlGAUgASgIUgZhY3Rpdm'
    'VCEQoPX2xhc3Rfc3luY2VkX2F0');

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
    {
      '1': 'access_token_expires_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'accessTokenExpiresAt'
    },
    {'1': 'refresh_token', '3': 3, '4': 1, '5': 9, '10': 'refreshToken'},
    {
      '1': 'refresh_token_expires_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'refreshTokenExpiresAt'
    },
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEiEKDGFjY2Vzc190b2tlbhgBIAEoCVILYWNjZXNzVG9rZW4SUQoXYWNjZXNzX3'
    'Rva2VuX2V4cGlyZXNfYXQYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhRhY2Nl'
    'c3NUb2tlbkV4cGlyZXNBdBIjCg1yZWZyZXNoX3Rva2VuGAMgASgJUgxyZWZyZXNoVG9rZW4SUw'
    'oYcmVmcmVzaF90b2tlbl9leHBpcmVzX2F0GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcFIVcmVmcmVzaFRva2VuRXhwaXJlc0F0');

@$core.Deprecated('Use deviceBindingDescriptor instead')
const DeviceBinding$json = {
  '1': 'DeviceBinding',
  '2': [
    {
      '1': 'device_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deviceId',
      '17': true
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'platform', '3': 3, '4': 1, '5': 9, '10': 'platform'},
  ],
  '8': [
    {'1': '_device_id'},
  ],
};

/// Descriptor for `DeviceBinding`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceBindingDescriptor = $convert.base64Decode(
    'Cg1EZXZpY2VCaW5kaW5nEiAKCWRldmljZV9pZBgBIAEoCUgAUghkZXZpY2VJZIgBARISCgRuYW'
    '1lGAIgASgJUgRuYW1lEhoKCHBsYXRmb3JtGAMgASgJUghwbGF0Zm9ybUIMCgpfZGV2aWNlX2lk');

@$core.Deprecated('Use registerUserRequestDescriptor instead')
const RegisterUserRequest$json = {
  '1': 'RegisterUserRequest',
  '2': [
    {'1': 'local_name', '3': 1, '4': 1, '5': 9, '10': 'localName'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 4, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `RegisterUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerUserRequestDescriptor = $convert.base64Decode(
    'ChNSZWdpc3RlclVzZXJSZXF1ZXN0Eh0KCmxvY2FsX25hbWUYASABKAlSCWxvY2FsTmFtZRIhCg'
    'xkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEhQKBWVtYWlsGAMgASgJUgVlbWFpbBIa'
    'CghwYXNzd29yZBgEIAEoCVIIcGFzc3dvcmQ=');

@$core.Deprecated('Use registerUserResponseDescriptor instead')
const RegisterUserResponse$json = {
  '1': 'RegisterUserResponse',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
  ],
};

/// Descriptor for `RegisterUserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerUserResponseDescriptor = $convert.base64Decode(
    'ChRSZWdpc3RlclVzZXJSZXNwb25zZRIiCgR1c2VyGAEgASgLMg4ucXVpcmUudjEuVXNlclIEdX'
    'Nlcg==');

@$core.Deprecated('Use getUserRequestDescriptor instead')
const GetUserRequest$json = {
  '1': 'GetUserRequest',
};

/// Descriptor for `GetUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserRequestDescriptor =
    $convert.base64Decode('Cg5HZXRVc2VyUmVxdWVzdA==');

@$core.Deprecated('Use getUserResponseDescriptor instead')
const GetUserResponse$json = {
  '1': 'GetUserResponse',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
  ],
};

/// Descriptor for `GetUserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRVc2VyUmVzcG9uc2USIgoEdXNlchgBIAEoCzIOLnF1aXJlLnYxLlVzZXJSBHVzZXI=');

@$core.Deprecated('Use updateUserRequestDescriptor instead')
const UpdateUserRequest$json = {
  '1': 'UpdateUserRequest',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
    {
      '1': 'update_mask',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '10': 'updateMask'
    },
  ],
};

/// Descriptor for `UpdateUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVVc2VyUmVxdWVzdBIiCgR1c2VyGAEgASgLMg4ucXVpcmUudjEuVXNlclIEdXNlch'
    'I7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0'
    'ZU1hc2s=');

@$core.Deprecated('Use updateUserResponseDescriptor instead')
const UpdateUserResponse$json = {
  '1': 'UpdateUserResponse',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
  ],
};

/// Descriptor for `UpdateUserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserResponseDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVVc2VyUmVzcG9uc2USIgoEdXNlchgBIAEoCzIOLnF1aXJlLnYxLlVzZXJSBHVzZX'
    'I=');

@$core.Deprecated('Use changePasswordRequestDescriptor instead')
const ChangePasswordRequest$json = {
  '1': 'ChangePasswordRequest',
  '2': [
    {'1': 'current_password', '3': 1, '4': 1, '5': 9, '10': 'currentPassword'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
  ],
};

/// Descriptor for `ChangePasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordRequestDescriptor = $convert.base64Decode(
    'ChVDaGFuZ2VQYXNzd29yZFJlcXVlc3QSKQoQY3VycmVudF9wYXNzd29yZBgBIAEoCVIPY3Vycm'
    'VudFBhc3N3b3JkEiEKDG5ld19wYXNzd29yZBgCIAEoCVILbmV3UGFzc3dvcmQ=');

@$core.Deprecated('Use changePasswordResponseDescriptor instead')
const ChangePasswordResponse$json = {
  '1': 'ChangePasswordResponse',
};

/// Descriptor for `ChangePasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordResponseDescriptor =
    $convert.base64Decode('ChZDaGFuZ2VQYXNzd29yZFJlc3BvbnNl');

@$core.Deprecated('Use changeEmailRequestDescriptor instead')
const ChangeEmailRequest$json = {
  '1': 'ChangeEmailRequest',
  '2': [
    {'1': 'password', '3': 1, '4': 1, '5': 9, '10': 'password'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `ChangeEmailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeEmailRequestDescriptor = $convert.base64Decode(
    'ChJDaGFuZ2VFbWFpbFJlcXVlc3QSGgoIcGFzc3dvcmQYASABKAlSCHBhc3N3b3JkEhQKBWVtYW'
    'lsGAIgASgJUgVlbWFpbA==');

@$core.Deprecated('Use changeEmailResponseDescriptor instead')
const ChangeEmailResponse$json = {
  '1': 'ChangeEmailResponse',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
  ],
};

/// Descriptor for `ChangeEmailResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeEmailResponseDescriptor = $convert.base64Decode(
    'ChNDaGFuZ2VFbWFpbFJlc3BvbnNlEiIKBHVzZXIYASABKAsyDi5xdWlyZS52MS5Vc2VyUgR1c2'
    'Vy');

@$core.Deprecated('Use deleteUserRequestDescriptor instead')
const DeleteUserRequest$json = {
  '1': 'DeleteUserRequest',
  '2': [
    {'1': 'password', '3': 1, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `DeleteUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteUserRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVVc2VyUmVxdWVzdBIaCghwYXNzd29yZBgBIAEoCVIIcGFzc3dvcmQ=');

@$core.Deprecated('Use deleteUserResponseDescriptor instead')
const DeleteUserResponse$json = {
  '1': 'DeleteUserResponse',
};

/// Descriptor for `DeleteUserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteUserResponseDescriptor =
    $convert.base64Decode('ChJEZWxldGVVc2VyUmVzcG9uc2U=');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'local_name', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'localName'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'email'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'device',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.DeviceBinding',
      '10': 'device'
    },
  ],
  '8': [
    {'1': 'login_id'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSHwoKbG9jYWxfbmFtZRgBIAEoCUgAUglsb2NhbE5hbWUSFgoFZW1haW'
    'wYAiABKAlIAFIFZW1haWwSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3JkEi8KBmRldmljZRgE'
    'IAEoCzIXLnF1aXJlLnYxLkRldmljZUJpbmRpbmdSBmRldmljZUIKCghsb2dpbl9pZA==');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Session',
      '10': 'session'
    },
    {'1': 'user', '3': 2, '4': 1, '5': 11, '6': '.quire.v1.User', '10': 'user'},
    {
      '1': 'device',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'device'
    },
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEisKB3Nlc3Npb24YASABKAsyES5xdWlyZS52MS5TZXNzaW9uUgdzZX'
    'NzaW9uEiIKBHVzZXIYAiABKAsyDi5xdWlyZS52MS5Vc2VyUgR1c2VyEigKBmRldmljZRgDIAEo'
    'CzIQLnF1aXJlLnYxLkRldmljZVIGZGV2aWNl');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor = $convert.base64Decode(
    'Cg1Mb2dvdXRSZXF1ZXN0EiMKDXJlZnJlc2hfdG9rZW4YASABKAlSDHJlZnJlc2hUb2tlbg==');

@$core.Deprecated('Use logoutResponseDescriptor instead')
const LogoutResponse$json = {
  '1': 'LogoutResponse',
};

/// Descriptor for `LogoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutResponseDescriptor =
    $convert.base64Decode('Cg5Mb2dvdXRSZXNwb25zZQ==');

@$core.Deprecated('Use refreshSessionRequestDescriptor instead')
const RefreshSessionRequest$json = {
  '1': 'RefreshSessionRequest',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `RefreshSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSessionRequestDescriptor = $convert.base64Decode(
    'ChVSZWZyZXNoU2Vzc2lvblJlcXVlc3QSIwoNcmVmcmVzaF90b2tlbhgBIAEoCVIMcmVmcmVzaF'
    'Rva2Vu');

@$core.Deprecated('Use refreshSessionResponseDescriptor instead')
const RefreshSessionResponse$json = {
  '1': 'RefreshSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `RefreshSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSessionResponseDescriptor =
    $convert.base64Decode(
        'ChZSZWZyZXNoU2Vzc2lvblJlc3BvbnNlEisKB3Nlc3Npb24YASABKAsyES5xdWlyZS52MS5TZX'
        'NzaW9uUgdzZXNzaW9u');

@$core.Deprecated('Use requestPasswordRecoveryRequestDescriptor instead')
const RequestPasswordRecoveryRequest$json = {
  '1': 'RequestPasswordRecoveryRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `RequestPasswordRecoveryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestPasswordRecoveryRequestDescriptor =
    $convert.base64Decode(
        'Ch5SZXF1ZXN0UGFzc3dvcmRSZWNvdmVyeVJlcXVlc3QSFAoFZW1haWwYASABKAlSBWVtYWls');

@$core.Deprecated('Use requestPasswordRecoveryResponseDescriptor instead')
const RequestPasswordRecoveryResponse$json = {
  '1': 'RequestPasswordRecoveryResponse',
};

/// Descriptor for `RequestPasswordRecoveryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestPasswordRecoveryResponseDescriptor =
    $convert.base64Decode('Ch9SZXF1ZXN0UGFzc3dvcmRSZWNvdmVyeVJlc3BvbnNl');

@$core.Deprecated('Use resetPasswordRequestDescriptor instead')
const ResetPasswordRequest$json = {
  '1': 'ResetPasswordRequest',
  '2': [
    {'1': 'recovery_token', '3': 1, '4': 1, '5': 9, '10': 'recoveryToken'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
  ],
};

/// Descriptor for `ResetPasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordRequestDescriptor = $convert.base64Decode(
    'ChRSZXNldFBhc3N3b3JkUmVxdWVzdBIlCg5yZWNvdmVyeV90b2tlbhgBIAEoCVINcmVjb3Zlcn'
    'lUb2tlbhIhCgxuZXdfcGFzc3dvcmQYAiABKAlSC25ld1Bhc3N3b3Jk');

@$core.Deprecated('Use resetPasswordResponseDescriptor instead')
const ResetPasswordResponse$json = {
  '1': 'ResetPasswordResponse',
};

/// Descriptor for `ResetPasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordResponseDescriptor =
    $convert.base64Decode('ChVSZXNldFBhc3N3b3JkUmVzcG9uc2U=');

@$core.Deprecated('Use registerDeviceRequestDescriptor instead')
const RegisterDeviceRequest$json = {
  '1': 'RegisterDeviceRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'platform', '3': 2, '4': 1, '5': 9, '10': 'platform'},
  ],
};

/// Descriptor for `RegisterDeviceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerDeviceRequestDescriptor = $convert.base64Decode(
    'ChVSZWdpc3RlckRldmljZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIaCghwbGF0Zm9ybR'
    'gCIAEoCVIIcGxhdGZvcm0=');

@$core.Deprecated('Use registerDeviceResponseDescriptor instead')
const RegisterDeviceResponse$json = {
  '1': 'RegisterDeviceResponse',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'device'
    },
  ],
};

/// Descriptor for `RegisterDeviceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerDeviceResponseDescriptor =
    $convert.base64Decode(
        'ChZSZWdpc3RlckRldmljZVJlc3BvbnNlEigKBmRldmljZRgBIAEoCzIQLnF1aXJlLnYxLkRldm'
        'ljZVIGZGV2aWNl');

@$core.Deprecated('Use listDevicesRequestDescriptor instead')
const ListDevicesRequest$json = {
  '1': 'ListDevicesRequest',
  '2': [
    {'1': 'include_inactive', '3': 1, '4': 1, '5': 8, '10': 'includeInactive'},
  ],
};

/// Descriptor for `ListDevicesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDevicesRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0RGV2aWNlc1JlcXVlc3QSKQoQaW5jbHVkZV9pbmFjdGl2ZRgBIAEoCFIPaW5jbHVkZU'
    'luYWN0aXZl');

@$core.Deprecated('Use listDevicesResponseDescriptor instead')
const ListDevicesResponse$json = {
  '1': 'ListDevicesResponse',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'devices'
    },
  ],
};

/// Descriptor for `ListDevicesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDevicesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0RGV2aWNlc1Jlc3BvbnNlEioKB2RldmljZXMYASADKAsyEC5xdWlyZS52MS5EZXZpY2'
    'VSB2RldmljZXM=');

@$core.Deprecated('Use updateDeviceRequestDescriptor instead')
const UpdateDeviceRequest$json = {
  '1': 'UpdateDeviceRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'device',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'device'
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

/// Descriptor for `UpdateDeviceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateDeviceRequestDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVEZXZpY2VSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQSKAoGZG'
    'V2aWNlGAIgASgLMhAucXVpcmUudjEuRGV2aWNlUgZkZXZpY2USOwoLdXBkYXRlX21hc2sYAyAB'
    'KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNr');

@$core.Deprecated('Use updateDeviceResponseDescriptor instead')
const UpdateDeviceResponse$json = {
  '1': 'UpdateDeviceResponse',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Device',
      '10': 'device'
    },
  ],
};

/// Descriptor for `UpdateDeviceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateDeviceResponseDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVEZXZpY2VSZXNwb25zZRIoCgZkZXZpY2UYASABKAsyEC5xdWlyZS52MS5EZXZpY2'
    'VSBmRldmljZQ==');

@$core.Deprecated('Use revokeDeviceRequestDescriptor instead')
const RevokeDeviceRequest$json = {
  '1': 'RevokeDeviceRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `RevokeDeviceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceRequestDescriptor =
    $convert.base64Decode(
        'ChNSZXZva2VEZXZpY2VSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQ=');

@$core.Deprecated('Use revokeDeviceResponseDescriptor instead')
const RevokeDeviceResponse$json = {
  '1': 'RevokeDeviceResponse',
};

/// Descriptor for `RevokeDeviceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceResponseDescriptor =
    $convert.base64Decode('ChRSZXZva2VEZXZpY2VSZXNwb25zZQ==');

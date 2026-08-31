// This is a generated file - do not edit.
//
// Generated from quire/v1/common.proto.

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

@$core.Deprecated('Use vectorClockDescriptor instead')
const VectorClock$json = {
  '1': 'VectorClock',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.VectorClock.EntriesEntry',
      '10': 'entries'
    },
  ],
  '3': [VectorClock_EntriesEntry$json],
};

@$core.Deprecated('Use vectorClockDescriptor instead')
const VectorClock_EntriesEntry$json = {
  '1': 'EntriesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 4, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `VectorClock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vectorClockDescriptor = $convert.base64Decode(
    'CgtWZWN0b3JDbG9jaxI8CgdlbnRyaWVzGAEgAygLMiIucXVpcmUudjEuVmVjdG9yQ2xvY2suRW'
    '50cmllc0VudHJ5UgdlbnRyaWVzGjoKDEVudHJpZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIU'
    'CgV2YWx1ZRgCIAEoBFIFdmFsdWU6AjgB');

@$core.Deprecated('Use hybridTimestampDescriptor instead')
const HybridTimestamp$json = {
  '1': 'HybridTimestamp',
  '2': [
    {'1': 'unix_micros', '3': 1, '4': 1, '5': 3, '10': 'unixMicros'},
  ],
};

/// Descriptor for `HybridTimestamp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hybridTimestampDescriptor = $convert.base64Decode(
    'Cg9IeWJyaWRUaW1lc3RhbXASHwoLdW5peF9taWNyb3MYASABKANSCnVuaXhNaWNyb3M=');

@$core.Deprecated('Use revisionDescriptor instead')
const Revision$json = {
  '1': 'Revision',
  '2': [
    {
      '1': 'vector_clock',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.VectorClock',
      '10': 'vectorClock'
    },
    {
      '1': 'updated_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.HybridTimestamp',
      '10': 'updatedAt'
    },
    {'1': 'device_id', '3': 3, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'deleted', '3': 4, '4': 1, '5': 8, '10': 'deleted'},
  ],
};

/// Descriptor for `Revision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revisionDescriptor = $convert.base64Decode(
    'CghSZXZpc2lvbhI4Cgx2ZWN0b3JfY2xvY2sYASABKAsyFS5xdWlyZS52MS5WZWN0b3JDbG9ja1'
    'ILdmVjdG9yQ2xvY2sSOAoKdXBkYXRlZF9hdBgCIAEoCzIZLnF1aXJlLnYxLkh5YnJpZFRpbWVz'
    'dGFtcFIJdXBkYXRlZEF0EhsKCWRldmljZV9pZBgDIAEoCVIIZGV2aWNlSWQSGAoHZGVsZXRlZB'
    'gEIAEoCFIHZGVsZXRlZA==');

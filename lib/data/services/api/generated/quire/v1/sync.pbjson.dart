// This is a generated file - do not edit.
//
// Generated from quire/v1/sync.proto.

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

@$core.Deprecated('Use targetEntityDescriptor instead')
const TargetEntity$json = {
  '1': 'TargetEntity',
  '2': [
    {'1': 'TARGET_ENTITY_UNSPECIFIED', '2': 0},
    {'1': 'TARGET_ENTITY_EBOOK', '2': 1},
    {'1': 'TARGET_ENTITY_COLLECTION', '2': 2},
    {'1': 'TARGET_ENTITY_EBOOK_COLLECTION', '2': 3},
    {'1': 'TARGET_ENTITY_READING_PROGRESS', '2': 4},
    {'1': 'TARGET_ENTITY_ANNOTATION', '2': 5},
  ],
};

/// Descriptor for `TargetEntity`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List targetEntityDescriptor = $convert.base64Decode(
    'CgxUYXJnZXRFbnRpdHkSHQoZVEFSR0VUX0VOVElUWV9VTlNQRUNJRklFRBAAEhcKE1RBUkdFVF'
    '9FTlRJVFlfRUJPT0sQARIcChhUQVJHRVRfRU5USVRZX0NPTExFQ1RJT04QAhIiCh5UQVJHRVRf'
    'RU5USVRZX0VCT09LX0NPTExFQ1RJT04QAxIiCh5UQVJHRVRfRU5USVRZX1JFQURJTkdfUFJPR1'
    'JFU1MQBBIcChhUQVJHRVRfRU5USVRZX0FOTk9UQVRJT04QBQ==');

@$core.Deprecated('Use operationKindDescriptor instead')
const OperationKind$json = {
  '1': 'OperationKind',
  '2': [
    {'1': 'OPERATION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'OPERATION_KIND_INSERT', '2': 1},
    {'1': 'OPERATION_KIND_UPDATE', '2': 2},
    {'1': 'OPERATION_KIND_DELETE', '2': 3},
  ],
};

/// Descriptor for `OperationKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List operationKindDescriptor = $convert.base64Decode(
    'Cg1PcGVyYXRpb25LaW5kEh4KGk9QRVJBVElPTl9LSU5EX1VOU1BFQ0lGSUVEEAASGQoVT1BFUk'
    'FUSU9OX0tJTkRfSU5TRVJUEAESGQoVT1BFUkFUSU9OX0tJTkRfVVBEQVRFEAISGQoVT1BFUkFU'
    'SU9OX0tJTkRfREVMRVRFEAM=');

@$core.Deprecated('Use operationOutcomeDescriptor instead')
const OperationOutcome$json = {
  '1': 'OperationOutcome',
  '2': [
    {'1': 'OPERATION_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'OPERATION_OUTCOME_APPLIED', '2': 1},
    {'1': 'OPERATION_OUTCOME_DUPLICATE', '2': 2},
    {'1': 'OPERATION_OUTCOME_SUPERSEDED', '2': 3},
    {'1': 'OPERATION_OUTCOME_REJECTED', '2': 4},
  ],
};

/// Descriptor for `OperationOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List operationOutcomeDescriptor = $convert.base64Decode(
    'ChBPcGVyYXRpb25PdXRjb21lEiEKHU9QRVJBVElPTl9PVVRDT01FX1VOU1BFQ0lGSUVEEAASHQ'
    'oZT1BFUkFUSU9OX09VVENPTUVfQVBQTElFRBABEh8KG09QRVJBVElPTl9PVVRDT01FX0RVUExJ'
    'Q0FURRACEiAKHE9QRVJBVElPTl9PVVRDT01FX1NVUEVSU0VERUQQAxIeChpPUEVSQVRJT05fT1'
    'VUQ09NRV9SRUpFQ1RFRBAE');

@$core.Deprecated('Use operationDescriptor instead')
const Operation$json = {
  '1': 'Operation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'target_entity',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.TargetEntity',
      '10': 'targetEntity'
    },
    {'1': 'target_id', '3': 4, '4': 1, '5': 9, '10': 'targetId'},
    {
      '1': 'operation',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.OperationKind',
      '10': 'operation'
    },
    {
      '1': 'delta',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'delta'
    },
    {
      '1': 'vector_clock',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.VectorClock',
      '10': 'vectorClock'
    },
    {
      '1': 'created_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.HybridTimestamp',
      '10': 'createdAt'
    },
    {'1': 'position', '3': 9, '4': 1, '5': 3, '10': 'position'},
  ],
};

/// Descriptor for `Operation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationDescriptor = $convert.base64Decode(
    'CglPcGVyYXRpb24SDgoCaWQYASABKAlSAmlkEhsKCWRldmljZV9pZBgCIAEoCVIIZGV2aWNlSW'
    'QSOwoNdGFyZ2V0X2VudGl0eRgDIAEoDjIWLnF1aXJlLnYxLlRhcmdldEVudGl0eVIMdGFyZ2V0'
    'RW50aXR5EhsKCXRhcmdldF9pZBgEIAEoCVIIdGFyZ2V0SWQSNQoJb3BlcmF0aW9uGAUgASgOMh'
    'cucXVpcmUudjEuT3BlcmF0aW9uS2luZFIJb3BlcmF0aW9uEi0KBWRlbHRhGAYgASgLMhcuZ29v'
    'Z2xlLnByb3RvYnVmLlN0cnVjdFIFZGVsdGESOAoMdmVjdG9yX2Nsb2NrGAcgASgLMhUucXVpcm'
    'UudjEuVmVjdG9yQ2xvY2tSC3ZlY3RvckNsb2NrEjgKCmNyZWF0ZWRfYXQYCCABKAsyGS5xdWly'
    'ZS52MS5IeWJyaWRUaW1lc3RhbXBSCWNyZWF0ZWRBdBIaCghwb3NpdGlvbhgJIAEoA1IIcG9zaX'
    'Rpb24=');

@$core.Deprecated('Use operationResultDescriptor instead')
const OperationResult$json = {
  '1': 'OperationResult',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'outcome',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.OperationOutcome',
      '10': 'outcome'
    },
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `OperationResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationResultDescriptor = $convert.base64Decode(
    'Cg9PcGVyYXRpb25SZXN1bHQSIQoMb3BlcmF0aW9uX2lkGAEgASgJUgtvcGVyYXRpb25JZBI0Cg'
    'dvdXRjb21lGAIgASgOMhoucXVpcmUudjEuT3BlcmF0aW9uT3V0Y29tZVIHb3V0Y29tZRIWCgZk'
    'ZXRhaWwYAyABKAlSBmRldGFpbA==');

@$core.Deprecated('Use operationBatchDescriptor instead')
const OperationBatch$json = {
  '1': 'OperationBatch',
  '2': [
    {
      '1': 'operations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Operation',
      '10': 'operations'
    },
  ],
};

/// Descriptor for `OperationBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationBatchDescriptor = $convert.base64Decode(
    'Cg5PcGVyYXRpb25CYXRjaBIzCgpvcGVyYXRpb25zGAEgAygLMhMucXVpcmUudjEuT3BlcmF0aW'
    '9uUgpvcGVyYXRpb25z');

@$core.Deprecated('Use pushOperationsRequestDescriptor instead')
const PushOperationsRequest$json = {
  '1': 'PushOperationsRequest',
  '2': [
    {
      '1': 'operations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Operation',
      '10': 'operations'
    },
  ],
};

/// Descriptor for `PushOperationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushOperationsRequestDescriptor = $convert.base64Decode(
    'ChVQdXNoT3BlcmF0aW9uc1JlcXVlc3QSMwoKb3BlcmF0aW9ucxgBIAMoCzITLnF1aXJlLnYxLk'
    '9wZXJhdGlvblIKb3BlcmF0aW9ucw==');

@$core.Deprecated('Use pushOperationsResponseDescriptor instead')
const PushOperationsResponse$json = {
  '1': 'PushOperationsResponse',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.OperationResult',
      '10': 'results'
    },
    {'1': 'last_position', '3': 2, '4': 1, '5': 3, '10': 'lastPosition'},
  ],
};

/// Descriptor for `PushOperationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushOperationsResponseDescriptor = $convert.base64Decode(
    'ChZQdXNoT3BlcmF0aW9uc1Jlc3BvbnNlEjMKB3Jlc3VsdHMYASADKAsyGS5xdWlyZS52MS5PcG'
    'VyYXRpb25SZXN1bHRSB3Jlc3VsdHMSIwoNbGFzdF9wb3NpdGlvbhgCIAEoA1IMbGFzdFBvc2l0'
    'aW9u');

@$core.Deprecated('Use pullOperationsRequestDescriptor instead')
const PullOperationsRequest$json = {
  '1': 'PullOperationsRequest',
  '2': [
    {'1': 'after_position', '3': 1, '4': 1, '5': 3, '10': 'afterPosition'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `PullOperationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pullOperationsRequestDescriptor = $convert.base64Decode(
    'ChVQdWxsT3BlcmF0aW9uc1JlcXVlc3QSJQoOYWZ0ZXJfcG9zaXRpb24YASABKANSDWFmdGVyUG'
    '9zaXRpb24SFAoFbGltaXQYAiABKAVSBWxpbWl0');

@$core.Deprecated('Use pullOperationsResponseDescriptor instead')
const PullOperationsResponse$json = {
  '1': 'PullOperationsResponse',
  '2': [
    {
      '1': 'operations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Operation',
      '10': 'operations'
    },
    {'1': 'last_position', '3': 2, '4': 1, '5': 3, '10': 'lastPosition'},
    {'1': 'has_more', '3': 3, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `PullOperationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pullOperationsResponseDescriptor = $convert.base64Decode(
    'ChZQdWxsT3BlcmF0aW9uc1Jlc3BvbnNlEjMKCm9wZXJhdGlvbnMYASADKAsyEy5xdWlyZS52MS'
    '5PcGVyYXRpb25SCm9wZXJhdGlvbnMSIwoNbGFzdF9wb3NpdGlvbhgCIAEoA1IMbGFzdFBvc2l0'
    'aW9uEhkKCGhhc19tb3JlGAMgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use syncRequestDescriptor instead')
const SyncRequest$json = {
  '1': 'SyncRequest',
  '2': [
    {
      '1': 'start',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.SyncStart',
      '9': 0,
      '10': 'start'
    },
    {
      '1': 'push',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.OperationBatch',
      '9': 0,
      '10': 'push'
    },
    {
      '1': 'ack',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.SyncAck',
      '9': 0,
      '10': 'ack'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `SyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncRequestDescriptor = $convert.base64Decode(
    'CgtTeW5jUmVxdWVzdBIrCgVzdGFydBgBIAEoCzITLnF1aXJlLnYxLlN5bmNTdGFydEgAUgVzdG'
    'FydBIuCgRwdXNoGAIgASgLMhgucXVpcmUudjEuT3BlcmF0aW9uQmF0Y2hIAFIEcHVzaBIlCgNh'
    'Y2sYAyABKAsyES5xdWlyZS52MS5TeW5jQWNrSABSA2Fja0IJCgdwYXlsb2Fk');

@$core.Deprecated('Use syncResponseDescriptor instead')
const SyncResponse$json = {
  '1': 'SyncResponse',
  '2': [
    {
      '1': 'operations',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.OperationBatch',
      '9': 0,
      '10': 'operations'
    },
    {
      '1': 'push_result',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.SyncPushResult',
      '9': 0,
      '10': 'pushResult'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `SyncResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncResponseDescriptor = $convert.base64Decode(
    'CgxTeW5jUmVzcG9uc2USOgoKb3BlcmF0aW9ucxgBIAEoCzIYLnF1aXJlLnYxLk9wZXJhdGlvbk'
    'JhdGNoSABSCm9wZXJhdGlvbnMSOwoLcHVzaF9yZXN1bHQYAiABKAsyGC5xdWlyZS52MS5TeW5j'
    'UHVzaFJlc3VsdEgAUgpwdXNoUmVzdWx0QgkKB3BheWxvYWQ=');

@$core.Deprecated('Use syncStartDescriptor instead')
const SyncStart$json = {
  '1': 'SyncStart',
  '2': [
    {'1': 'after_position', '3': 1, '4': 1, '5': 3, '10': 'afterPosition'},
  ],
};

/// Descriptor for `SyncStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStartDescriptor = $convert.base64Decode(
    'CglTeW5jU3RhcnQSJQoOYWZ0ZXJfcG9zaXRpb24YASABKANSDWFmdGVyUG9zaXRpb24=');

@$core.Deprecated('Use syncAckDescriptor instead')
const SyncAck$json = {
  '1': 'SyncAck',
  '2': [
    {'1': 'position', '3': 1, '4': 1, '5': 3, '10': 'position'},
  ],
};

/// Descriptor for `SyncAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncAckDescriptor = $convert
    .base64Decode('CgdTeW5jQWNrEhoKCHBvc2l0aW9uGAEgASgDUghwb3NpdGlvbg==');

@$core.Deprecated('Use syncPushResultDescriptor instead')
const SyncPushResult$json = {
  '1': 'SyncPushResult',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.OperationResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `SyncPushResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncPushResultDescriptor = $convert.base64Decode(
    'Cg5TeW5jUHVzaFJlc3VsdBIzCgdyZXN1bHRzGAEgAygLMhkucXVpcmUudjEuT3BlcmF0aW9uUm'
    'VzdWx0UgdyZXN1bHRz');

@$core.Deprecated('Use watchOperationsRequestDescriptor instead')
const WatchOperationsRequest$json = {
  '1': 'WatchOperationsRequest',
  '2': [
    {'1': 'after_position', '3': 1, '4': 1, '5': 3, '10': 'afterPosition'},
  ],
};

/// Descriptor for `WatchOperationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchOperationsRequestDescriptor =
    $convert.base64Decode(
        'ChZXYXRjaE9wZXJhdGlvbnNSZXF1ZXN0EiUKDmFmdGVyX3Bvc2l0aW9uGAEgASgDUg1hZnRlcl'
        'Bvc2l0aW9u');

@$core.Deprecated('Use watchOperationsResponseDescriptor instead')
const WatchOperationsResponse$json = {
  '1': 'WatchOperationsResponse',
  '2': [
    {'1': 'last_position', '3': 1, '4': 1, '5': 3, '10': 'lastPosition'},
  ],
};

/// Descriptor for `WatchOperationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchOperationsResponseDescriptor =
    $convert.base64Decode(
        'ChdXYXRjaE9wZXJhdGlvbnNSZXNwb25zZRIjCg1sYXN0X3Bvc2l0aW9uGAEgASgDUgxsYXN0UG'
        '9zaXRpb24=');

@$core.Deprecated('Use replicateOperationsRequestDescriptor instead')
const ReplicateOperationsRequest$json = {
  '1': 'ReplicateOperationsRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'operations',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Operation',
      '10': 'operations'
    },
  ],
};

/// Descriptor for `ReplicateOperationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replicateOperationsRequestDescriptor =
    $convert.base64Decode(
        'ChpSZXBsaWNhdGVPcGVyYXRpb25zUmVxdWVzdBIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSMw'
        'oKb3BlcmF0aW9ucxgCIAMoCzITLnF1aXJlLnYxLk9wZXJhdGlvblIKb3BlcmF0aW9ucw==');

@$core.Deprecated('Use replicateOperationsResponseDescriptor instead')
const ReplicateOperationsResponse$json = {
  '1': 'ReplicateOperationsResponse',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.OperationResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `ReplicateOperationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replicateOperationsResponseDescriptor =
    $convert.base64Decode(
        'ChtSZXBsaWNhdGVPcGVyYXRpb25zUmVzcG9uc2USMwoHcmVzdWx0cxgBIAMoCzIZLnF1aXJlLn'
        'YxLk9wZXJhdGlvblJlc3VsdFIHcmVzdWx0cw==');

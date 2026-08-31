// This is a generated file - do not edit.
//
// Generated from quire/v1/reading.proto.

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

@$core.Deprecated('Use annotationKindDescriptor instead')
const AnnotationKind$json = {
  '1': 'AnnotationKind',
  '2': [
    {'1': 'ANNOTATION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'ANNOTATION_KIND_NOTE', '2': 1},
    {'1': 'ANNOTATION_KIND_HIGHLIGHT', '2': 2},
    {'1': 'ANNOTATION_KIND_BOOKMARK', '2': 3},
  ],
};

/// Descriptor for `AnnotationKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List annotationKindDescriptor = $convert.base64Decode(
    'Cg5Bbm5vdGF0aW9uS2luZBIfChtBTk5PVEFUSU9OX0tJTkRfVU5TUEVDSUZJRUQQABIYChRBTk'
    '5PVEFUSU9OX0tJTkRfTk9URRABEh0KGUFOTk9UQVRJT05fS0lORF9ISUdITElHSFQQAhIcChhB'
    'Tk5PVEFUSU9OX0tJTkRfQk9PS01BUksQAw==');

@$core.Deprecated('Use annotationDescriptor instead')
const Annotation$json = {
  '1': 'Annotation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'ebook_id', '3': 2, '4': 1, '5': 9, '10': 'ebookId'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.AnnotationKind',
      '10': 'kind'
    },
    {'1': 'text', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'text', '17': true},
    {'1': 'locator', '3': 5, '4': 1, '5': 9, '10': 'locator'},
    {
      '1': 'revision',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Revision',
      '10': 'revision'
    },
  ],
  '8': [
    {'1': '_text'},
  ],
};

/// Descriptor for `Annotation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List annotationDescriptor = $convert.base64Decode(
    'CgpBbm5vdGF0aW9uEg4KAmlkGAEgASgJUgJpZBIZCghlYm9va19pZBgCIAEoCVIHZWJvb2tJZB'
    'IsCgRraW5kGAMgASgOMhgucXVpcmUudjEuQW5ub3RhdGlvbktpbmRSBGtpbmQSFwoEdGV4dBgE'
    'IAEoCUgAUgR0ZXh0iAEBEhgKB2xvY2F0b3IYBSABKAlSB2xvY2F0b3ISLgoIcmV2aXNpb24YBi'
    'ABKAsyEi5xdWlyZS52MS5SZXZpc2lvblIIcmV2aXNpb25CBwoFX3RleHQ=');

@$core.Deprecated('Use readingProgressDescriptor instead')
const ReadingProgress$json = {
  '1': 'ReadingProgress',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'locator', '3': 3, '4': 1, '5': 9, '10': 'locator'},
    {
      '1': 'percent',
      '3': 4,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'percent',
      '17': true
    },
    {
      '1': 'vector_clock',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.VectorClock',
      '10': 'vectorClock'
    },
    {
      '1': 'updated_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.HybridTimestamp',
      '10': 'updatedAt'
    },
  ],
  '8': [
    {'1': '_percent'},
  ],
};

/// Descriptor for `ReadingProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readingProgressDescriptor = $convert.base64Decode(
    'Cg9SZWFkaW5nUHJvZ3Jlc3MSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSWQSGwoJZGV2aWNlX2'
    'lkGAIgASgJUghkZXZpY2VJZBIYCgdsb2NhdG9yGAMgASgJUgdsb2NhdG9yEh0KB3BlcmNlbnQY'
    'BCABKAFIAFIHcGVyY2VudIgBARI4Cgx2ZWN0b3JfY2xvY2sYBSABKAsyFS5xdWlyZS52MS5WZW'
    'N0b3JDbG9ja1ILdmVjdG9yQ2xvY2sSOAoKdXBkYXRlZF9hdBgGIAEoCzIZLnF1aXJlLnYxLkh5'
    'YnJpZFRpbWVzdGFtcFIJdXBkYXRlZEF0QgoKCF9wZXJjZW50');

@$core.Deprecated('Use createAnnotationRequestDescriptor instead')
const CreateAnnotationRequest$json = {
  '1': 'CreateAnnotationRequest',
  '2': [
    {
      '1': 'annotation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotation'
    },
  ],
};

/// Descriptor for `CreateAnnotationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAnnotationRequestDescriptor =
    $convert.base64Decode(
        'ChdDcmVhdGVBbm5vdGF0aW9uUmVxdWVzdBI0Cgphbm5vdGF0aW9uGAEgASgLMhQucXVpcmUudj'
        'EuQW5ub3RhdGlvblIKYW5ub3RhdGlvbg==');

@$core.Deprecated('Use createAnnotationResponseDescriptor instead')
const CreateAnnotationResponse$json = {
  '1': 'CreateAnnotationResponse',
  '2': [
    {
      '1': 'annotation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotation'
    },
  ],
};

/// Descriptor for `CreateAnnotationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAnnotationResponseDescriptor =
    $convert.base64Decode(
        'ChhDcmVhdGVBbm5vdGF0aW9uUmVzcG9uc2USNAoKYW5ub3RhdGlvbhgBIAEoCzIULnF1aXJlLn'
        'YxLkFubm90YXRpb25SCmFubm90YXRpb24=');

@$core.Deprecated('Use getAnnotationRequestDescriptor instead')
const GetAnnotationRequest$json = {
  '1': 'GetAnnotationRequest',
  '2': [
    {'1': 'annotation_id', '3': 1, '4': 1, '5': 9, '10': 'annotationId'},
  ],
};

/// Descriptor for `GetAnnotationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAnnotationRequestDescriptor = $convert.base64Decode(
    'ChRHZXRBbm5vdGF0aW9uUmVxdWVzdBIjCg1hbm5vdGF0aW9uX2lkGAEgASgJUgxhbm5vdGF0aW'
    '9uSWQ=');

@$core.Deprecated('Use getAnnotationResponseDescriptor instead')
const GetAnnotationResponse$json = {
  '1': 'GetAnnotationResponse',
  '2': [
    {
      '1': 'annotation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotation'
    },
  ],
};

/// Descriptor for `GetAnnotationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAnnotationResponseDescriptor = $convert.base64Decode(
    'ChVHZXRBbm5vdGF0aW9uUmVzcG9uc2USNAoKYW5ub3RhdGlvbhgBIAEoCzIULnF1aXJlLnYxLk'
    'Fubm90YXRpb25SCmFubm90YXRpb24=');

@$core.Deprecated('Use listAnnotationsRequestDescriptor instead')
const ListAnnotationsRequest$json = {
  '1': 'ListAnnotationsRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListAnnotationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listAnnotationsRequestDescriptor = $convert.base64Decode(
    'ChZMaXN0QW5ub3RhdGlvbnNSZXF1ZXN0EhkKCGVib29rX2lkGAEgASgJUgdlYm9va0lkEhsKCX'
    'BhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu');

@$core.Deprecated('Use listAnnotationsResponseDescriptor instead')
const ListAnnotationsResponse$json = {
  '1': 'ListAnnotationsResponse',
  '2': [
    {
      '1': 'annotations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotations'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListAnnotationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listAnnotationsResponseDescriptor = $convert.base64Decode(
    'ChdMaXN0QW5ub3RhdGlvbnNSZXNwb25zZRI2Cgthbm5vdGF0aW9ucxgBIAMoCzIULnF1aXJlLn'
    'YxLkFubm90YXRpb25SC2Fubm90YXRpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4'
    'dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use updateAnnotationRequestDescriptor instead')
const UpdateAnnotationRequest$json = {
  '1': 'UpdateAnnotationRequest',
  '2': [
    {'1': 'annotation_id', '3': 1, '4': 1, '5': 9, '10': 'annotationId'},
    {
      '1': 'annotation',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotation'
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

/// Descriptor for `UpdateAnnotationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAnnotationRequestDescriptor = $convert.base64Decode(
    'ChdVcGRhdGVBbm5vdGF0aW9uUmVxdWVzdBIjCg1hbm5vdGF0aW9uX2lkGAEgASgJUgxhbm5vdG'
    'F0aW9uSWQSNAoKYW5ub3RhdGlvbhgCIAEoCzIULnF1aXJlLnYxLkFubm90YXRpb25SCmFubm90'
    'YXRpb24SOwoLdXBkYXRlX21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUg'
    'p1cGRhdGVNYXNr');

@$core.Deprecated('Use updateAnnotationResponseDescriptor instead')
const UpdateAnnotationResponse$json = {
  '1': 'UpdateAnnotationResponse',
  '2': [
    {
      '1': 'annotation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Annotation',
      '10': 'annotation'
    },
  ],
};

/// Descriptor for `UpdateAnnotationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAnnotationResponseDescriptor =
    $convert.base64Decode(
        'ChhVcGRhdGVBbm5vdGF0aW9uUmVzcG9uc2USNAoKYW5ub3RhdGlvbhgBIAEoCzIULnF1aXJlLn'
        'YxLkFubm90YXRpb25SCmFubm90YXRpb24=');

@$core.Deprecated('Use deleteAnnotationRequestDescriptor instead')
const DeleteAnnotationRequest$json = {
  '1': 'DeleteAnnotationRequest',
  '2': [
    {'1': 'annotation_id', '3': 1, '4': 1, '5': 9, '10': 'annotationId'},
  ],
};

/// Descriptor for `DeleteAnnotationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAnnotationRequestDescriptor =
    $convert.base64Decode(
        'ChdEZWxldGVBbm5vdGF0aW9uUmVxdWVzdBIjCg1hbm5vdGF0aW9uX2lkGAEgASgJUgxhbm5vdG'
        'F0aW9uSWQ=');

@$core.Deprecated('Use deleteAnnotationResponseDescriptor instead')
const DeleteAnnotationResponse$json = {
  '1': 'DeleteAnnotationResponse',
};

/// Descriptor for `DeleteAnnotationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAnnotationResponseDescriptor =
    $convert.base64Decode('ChhEZWxldGVBbm5vdGF0aW9uUmVzcG9uc2U=');

@$core.Deprecated('Use updateReadingProgressRequestDescriptor instead')
const UpdateReadingProgressRequest$json = {
  '1': 'UpdateReadingProgressRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {'1': 'locator', '3': 2, '4': 1, '5': 9, '10': 'locator'},
    {
      '1': 'percent',
      '3': 3,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'percent',
      '17': true
    },
  ],
  '8': [
    {'1': '_percent'},
  ],
};

/// Descriptor for `UpdateReadingProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateReadingProgressRequestDescriptor =
    $convert.base64Decode(
        'ChxVcGRhdGVSZWFkaW5nUHJvZ3Jlc3NSZXF1ZXN0EhkKCGVib29rX2lkGAEgASgJUgdlYm9va0'
        'lkEhgKB2xvY2F0b3IYAiABKAlSB2xvY2F0b3ISHQoHcGVyY2VudBgDIAEoAUgAUgdwZXJjZW50'
        'iAEBQgoKCF9wZXJjZW50');

@$core.Deprecated('Use updateReadingProgressResponseDescriptor instead')
const UpdateReadingProgressResponse$json = {
  '1': 'UpdateReadingProgressResponse',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.ReadingProgress',
      '10': 'progress'
    },
  ],
};

/// Descriptor for `UpdateReadingProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateReadingProgressResponseDescriptor =
    $convert.base64Decode(
        'Ch1VcGRhdGVSZWFkaW5nUHJvZ3Jlc3NSZXNwb25zZRI1Cghwcm9ncmVzcxgBIAEoCzIZLnF1aX'
        'JlLnYxLlJlYWRpbmdQcm9ncmVzc1IIcHJvZ3Jlc3M=');

@$core.Deprecated('Use listReadingProgressRequestDescriptor instead')
const ListReadingProgressRequest$json = {
  '1': 'ListReadingProgressRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
  ],
};

/// Descriptor for `ListReadingProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReadingProgressRequestDescriptor =
    $convert.base64Decode(
        'ChpMaXN0UmVhZGluZ1Byb2dyZXNzUmVxdWVzdBIZCghlYm9va19pZBgBIAEoCVIHZWJvb2tJZA'
        '==');

@$core.Deprecated('Use listReadingProgressResponseDescriptor instead')
const ListReadingProgressResponse$json = {
  '1': 'ListReadingProgressResponse',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.ReadingProgress',
      '10': 'progress'
    },
  ],
};

/// Descriptor for `ListReadingProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReadingProgressResponseDescriptor =
    $convert.base64Decode(
        'ChtMaXN0UmVhZGluZ1Byb2dyZXNzUmVzcG9uc2USNQoIcHJvZ3Jlc3MYASADKAsyGS5xdWlyZS'
        '52MS5SZWFkaW5nUHJvZ3Jlc3NSCHByb2dyZXNz');

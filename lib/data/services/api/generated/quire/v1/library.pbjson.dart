// This is a generated file - do not edit.
//
// Generated from quire/v1/library.proto.

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

@$core.Deprecated('Use ebookFormatDescriptor instead')
const EbookFormat$json = {
  '1': 'EbookFormat',
  '2': [
    {'1': 'EBOOK_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'EBOOK_FORMAT_EPUB', '2': 1},
    {'1': 'EBOOK_FORMAT_PDF', '2': 2},
    {'1': 'EBOOK_FORMAT_MOBI', '2': 3},
    {'1': 'EBOOK_FORMAT_DJVU', '2': 4},
    {'1': 'EBOOK_FORMAT_CBZ', '2': 5},
  ],
};

/// Descriptor for `EbookFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List ebookFormatDescriptor = $convert.base64Decode(
    'CgtFYm9va0Zvcm1hdBIcChhFQk9PS19GT1JNQVRfVU5TUEVDSUZJRUQQABIVChFFQk9PS19GT1'
    'JNQVRfRVBVQhABEhQKEEVCT09LX0ZPUk1BVF9QREYQAhIVChFFQk9PS19GT1JNQVRfTU9CSRAD'
    'EhUKEUVCT09LX0ZPUk1BVF9ESlZVEAQSFAoQRUJPT0tfRk9STUFUX0NCWhAF');

@$core.Deprecated('Use collectionKindDescriptor instead')
const CollectionKind$json = {
  '1': 'CollectionKind',
  '2': [
    {'1': 'COLLECTION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'COLLECTION_KIND_COLLECTION', '2': 1},
    {'1': 'COLLECTION_KIND_CATEGORY', '2': 2},
  ],
};

/// Descriptor for `CollectionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List collectionKindDescriptor = $convert.base64Decode(
    'Cg5Db2xsZWN0aW9uS2luZBIfChtDT0xMRUNUSU9OX0tJTkRfVU5TUEVDSUZJRUQQABIeChpDT0'
    'xMRUNUSU9OX0tJTkRfQ09MTEVDVElPThABEhwKGENPTExFQ1RJT05fS0lORF9DQVRFR09SWRAC');

@$core.Deprecated('Use ebookDescriptor instead')
const Ebook$json = {
  '1': 'Ebook',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'author', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'author', '17': true},
    {
      '1': 'publisher',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'publisher',
      '17': true
    },
    {
      '1': 'language',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'language',
      '17': true
    },
    {
      '1': 'format',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.EbookFormat',
      '10': 'format'
    },
    {'1': 'content_hash', '3': 7, '4': 1, '5': 9, '10': 'contentHash'},
    {
      '1': 'size_bytes',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 3,
      '10': 'sizeBytes',
      '17': true
    },
    {
      '1': 'extra_metadata',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'extraMetadata'
    },
    {
      '1': 'imported_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'importedAt'
    },
    {
      '1': 'revision',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Revision',
      '10': 'revision'
    },
  ],
  '8': [
    {'1': '_author'},
    {'1': '_publisher'},
    {'1': '_language'},
    {'1': '_size_bytes'},
  ],
};

/// Descriptor for `Ebook`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ebookDescriptor = $convert.base64Decode(
    'CgVFYm9vaxIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhsKBmF1dGhvch'
    'gDIAEoCUgAUgZhdXRob3KIAQESIQoJcHVibGlzaGVyGAQgASgJSAFSCXB1Ymxpc2hlcogBARIf'
    'CghsYW5ndWFnZRgFIAEoCUgCUghsYW5ndWFnZYgBARItCgZmb3JtYXQYBiABKA4yFS5xdWlyZS'
    '52MS5FYm9va0Zvcm1hdFIGZm9ybWF0EiEKDGNvbnRlbnRfaGFzaBgHIAEoCVILY29udGVudEhh'
    'c2gSIgoKc2l6ZV9ieXRlcxgIIAEoA0gDUglzaXplQnl0ZXOIAQESPgoOZXh0cmFfbWV0YWRhdG'
    'EYCSABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ug1leHRyYU1ldGFkYXRhEjsKC2ltcG9y'
    'dGVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKaW1wb3J0ZWRBdBIuCg'
    'hyZXZpc2lvbhgLIAEoCzISLnF1aXJlLnYxLlJldmlzaW9uUghyZXZpc2lvbkIJCgdfYXV0aG9y'
    'QgwKCl9wdWJsaXNoZXJCCwoJX2xhbmd1YWdlQg0KC19zaXplX2J5dGVz');

@$core.Deprecated('Use collectionDescriptor instead')
const Collection$json = {
  '1': 'Collection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.quire.v1.CollectionKind',
      '10': 'kind'
    },
    {
      '1': 'description',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {
      '1': 'created_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
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
    {'1': '_description'},
  ],
};

/// Descriptor for `Collection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List collectionDescriptor = $convert.base64Decode(
    'CgpDb2xsZWN0aW9uEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEiwKBGtpbm'
    'QYAyABKA4yGC5xdWlyZS52MS5Db2xsZWN0aW9uS2luZFIEa2luZBIlCgtkZXNjcmlwdGlvbhgE'
    'IAEoCUgAUgtkZXNjcmlwdGlvbogBARI5CgpjcmVhdGVkX2F0GAUgASgLMhouZ29vZ2xlLnByb3'
    'RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0Ei4KCHJldmlzaW9uGAYgASgLMhIucXVpcmUudjEu'
    'UmV2aXNpb25SCHJldmlzaW9uQg4KDF9kZXNjcmlwdGlvbg==');

@$core.Deprecated('Use ebookContentDescriptor instead')
const EbookContent$json = {
  '1': 'EbookContent',
  '2': [
    {'1': 'content_hash', '3': 1, '4': 1, '5': 9, '10': 'contentHash'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'media_type', '3': 3, '4': 1, '5': 9, '10': 'mediaType'},
  ],
};

/// Descriptor for `EbookContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ebookContentDescriptor = $convert.base64Decode(
    'CgxFYm9va0NvbnRlbnQSIQoMY29udGVudF9oYXNoGAEgASgJUgtjb250ZW50SGFzaBIdCgpzaX'
    'plX2J5dGVzGAIgASgDUglzaXplQnl0ZXMSHQoKbWVkaWFfdHlwZRgDIAEoCVIJbWVkaWFUeXBl');

@$core.Deprecated('Use createEbookRequestDescriptor instead')
const CreateEbookRequest$json = {
  '1': 'CreateEbookRequest',
  '2': [
    {
      '1': 'ebook',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebook'
    },
  ],
};

/// Descriptor for `CreateEbookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createEbookRequestDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVFYm9va1JlcXVlc3QSJQoFZWJvb2sYASABKAsyDy5xdWlyZS52MS5FYm9va1IFZW'
    'Jvb2s=');

@$core.Deprecated('Use createEbookResponseDescriptor instead')
const CreateEbookResponse$json = {
  '1': 'CreateEbookResponse',
  '2': [
    {
      '1': 'ebook',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebook'
    },
    {'1': 'content_missing', '3': 2, '4': 1, '5': 8, '10': 'contentMissing'},
  ],
};

/// Descriptor for `CreateEbookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createEbookResponseDescriptor = $convert.base64Decode(
    'ChNDcmVhdGVFYm9va1Jlc3BvbnNlEiUKBWVib29rGAEgASgLMg8ucXVpcmUudjEuRWJvb2tSBW'
    'Vib29rEicKD2NvbnRlbnRfbWlzc2luZxgCIAEoCFIOY29udGVudE1pc3Npbmc=');

@$core.Deprecated('Use getEbookRequestDescriptor instead')
const GetEbookRequest$json = {
  '1': 'GetEbookRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
  ],
};

/// Descriptor for `GetEbookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEbookRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRFYm9va1JlcXVlc3QSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSWQ=');

@$core.Deprecated('Use getEbookResponseDescriptor instead')
const GetEbookResponse$json = {
  '1': 'GetEbookResponse',
  '2': [
    {
      '1': 'ebook',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebook'
    },
  ],
};

/// Descriptor for `GetEbookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEbookResponseDescriptor = $convert.base64Decode(
    'ChBHZXRFYm9va1Jlc3BvbnNlEiUKBWVib29rGAEgASgLMg8ucXVpcmUudjEuRWJvb2tSBWVib2'
    '9r');

@$core.Deprecated('Use listEbooksRequestDescriptor instead')
const ListEbooksRequest$json = {
  '1': 'ListEbooksRequest',
  '2': [
    {'1': 'page_size', '3': 1, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 2, '4': 1, '5': 9, '10': 'pageToken'},
    {
      '1': 'collection_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'collectionId',
      '17': true
    },
  ],
  '8': [
    {'1': '_collection_id'},
  ],
};

/// Descriptor for `ListEbooksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEbooksRequestDescriptor = $convert.base64Decode(
    'ChFMaXN0RWJvb2tzUmVxdWVzdBIbCglwYWdlX3NpemUYASABKAVSCHBhZ2VTaXplEh0KCnBhZ2'
    'VfdG9rZW4YAiABKAlSCXBhZ2VUb2tlbhIoCg1jb2xsZWN0aW9uX2lkGAMgASgJSABSDGNvbGxl'
    'Y3Rpb25JZIgBAUIQCg5fY29sbGVjdGlvbl9pZA==');

@$core.Deprecated('Use listEbooksResponseDescriptor instead')
const ListEbooksResponse$json = {
  '1': 'ListEbooksResponse',
  '2': [
    {
      '1': 'ebooks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebooks'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListEbooksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEbooksResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0RWJvb2tzUmVzcG9uc2USJwoGZWJvb2tzGAEgAygLMg8ucXVpcmUudjEuRWJvb2tSBm'
    'Vib29rcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4=');

@$core.Deprecated('Use updateEbookRequestDescriptor instead')
const UpdateEbookRequest$json = {
  '1': 'UpdateEbookRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {
      '1': 'ebook',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebook'
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

/// Descriptor for `UpdateEbookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateEbookRequestDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVFYm9va1JlcXVlc3QSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSWQSJQoFZWJvb2'
    'sYAiABKAsyDy5xdWlyZS52MS5FYm9va1IFZWJvb2sSOwoLdXBkYXRlX21hc2sYAyABKAsyGi5n'
    'b29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNr');

@$core.Deprecated('Use updateEbookResponseDescriptor instead')
const UpdateEbookResponse$json = {
  '1': 'UpdateEbookResponse',
  '2': [
    {
      '1': 'ebook',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Ebook',
      '10': 'ebook'
    },
  ],
};

/// Descriptor for `UpdateEbookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateEbookResponseDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVFYm9va1Jlc3BvbnNlEiUKBWVib29rGAEgASgLMg8ucXVpcmUudjEuRWJvb2tSBW'
    'Vib29r');

@$core.Deprecated('Use deleteEbookRequestDescriptor instead')
const DeleteEbookRequest$json = {
  '1': 'DeleteEbookRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
  ],
};

/// Descriptor for `DeleteEbookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEbookRequestDescriptor =
    $convert.base64Decode(
        'ChJEZWxldGVFYm9va1JlcXVlc3QSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSWQ=');

@$core.Deprecated('Use deleteEbookResponseDescriptor instead')
const DeleteEbookResponse$json = {
  '1': 'DeleteEbookResponse',
};

/// Descriptor for `DeleteEbookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEbookResponseDescriptor =
    $convert.base64Decode('ChNEZWxldGVFYm9va1Jlc3BvbnNl');

@$core.Deprecated('Use uploadEbookContentRequestDescriptor instead')
const UploadEbookContentRequest$json = {
  '1': 'UploadEbookContentRequest',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '9': 0,
      '10': 'content'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `UploadEbookContentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadEbookContentRequestDescriptor = $convert.base64Decode(
    'ChlVcGxvYWRFYm9va0NvbnRlbnRSZXF1ZXN0EjIKB2NvbnRlbnQYASABKAsyFi5xdWlyZS52MS'
    '5FYm9va0NvbnRlbnRIAFIHY29udGVudBIWCgVjaHVuaxgCIAEoDEgAUgVjaHVua0IJCgdwYXls'
    'b2Fk');

@$core.Deprecated('Use uploadEbookContentResponseDescriptor instead')
const UploadEbookContentResponse$json = {
  '1': 'UploadEbookContentResponse',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '10': 'content'
    },
  ],
};

/// Descriptor for `UploadEbookContentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadEbookContentResponseDescriptor =
    $convert.base64Decode(
        'ChpVcGxvYWRFYm9va0NvbnRlbnRSZXNwb25zZRIwCgdjb250ZW50GAEgASgLMhYucXVpcmUudj'
        'EuRWJvb2tDb250ZW50Ugdjb250ZW50');

@$core.Deprecated('Use beginEbookUploadRequestDescriptor instead')
const BeginEbookUploadRequest$json = {
  '1': 'BeginEbookUploadRequest',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '10': 'content'
    },
  ],
};

/// Descriptor for `BeginEbookUploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List beginEbookUploadRequestDescriptor =
    $convert.base64Decode(
        'ChdCZWdpbkVib29rVXBsb2FkUmVxdWVzdBIwCgdjb250ZW50GAEgASgLMhYucXVpcmUudjEuRW'
        'Jvb2tDb250ZW50Ugdjb250ZW50');

@$core.Deprecated('Use beginEbookUploadResponseDescriptor instead')
const BeginEbookUploadResponse$json = {
  '1': 'BeginEbookUploadResponse',
  '2': [
    {'1': 'upload_id', '3': 1, '4': 1, '5': 9, '10': 'uploadId'},
    {'1': 'already_held', '3': 2, '4': 1, '5': 8, '10': 'alreadyHeld'},
    {
      '1': 'content',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '10': 'content'
    },
  ],
};

/// Descriptor for `BeginEbookUploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List beginEbookUploadResponseDescriptor = $convert.base64Decode(
    'ChhCZWdpbkVib29rVXBsb2FkUmVzcG9uc2USGwoJdXBsb2FkX2lkGAEgASgJUgh1cGxvYWRJZB'
    'IhCgxhbHJlYWR5X2hlbGQYAiABKAhSC2FscmVhZHlIZWxkEjAKB2NvbnRlbnQYAyABKAsyFi5x'
    'dWlyZS52MS5FYm9va0NvbnRlbnRSB2NvbnRlbnQ=');

@$core.Deprecated('Use putEbookChunkRequestDescriptor instead')
const PutEbookChunkRequest$json = {
  '1': 'PutEbookChunkRequest',
  '2': [
    {'1': 'upload_id', '3': 1, '4': 1, '5': 9, '10': 'uploadId'},
    {'1': 'offset', '3': 2, '4': 1, '5': 3, '10': 'offset'},
    {'1': 'chunk', '3': 3, '4': 1, '5': 12, '10': 'chunk'},
  ],
};

/// Descriptor for `PutEbookChunkRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putEbookChunkRequestDescriptor = $convert.base64Decode(
    'ChRQdXRFYm9va0NodW5rUmVxdWVzdBIbCgl1cGxvYWRfaWQYASABKAlSCHVwbG9hZElkEhYKBm'
    '9mZnNldBgCIAEoA1IGb2Zmc2V0EhQKBWNodW5rGAMgASgMUgVjaHVuaw==');

@$core.Deprecated('Use putEbookChunkResponseDescriptor instead')
const PutEbookChunkResponse$json = {
  '1': 'PutEbookChunkResponse',
  '2': [
    {'1': 'received_bytes', '3': 1, '4': 1, '5': 3, '10': 'receivedBytes'},
  ],
};

/// Descriptor for `PutEbookChunkResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putEbookChunkResponseDescriptor = $convert.base64Decode(
    'ChVQdXRFYm9va0NodW5rUmVzcG9uc2USJQoOcmVjZWl2ZWRfYnl0ZXMYASABKANSDXJlY2Vpdm'
    'VkQnl0ZXM=');

@$core.Deprecated('Use finishEbookUploadRequestDescriptor instead')
const FinishEbookUploadRequest$json = {
  '1': 'FinishEbookUploadRequest',
  '2': [
    {'1': 'upload_id', '3': 1, '4': 1, '5': 9, '10': 'uploadId'},
  ],
};

/// Descriptor for `FinishEbookUploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List finishEbookUploadRequestDescriptor =
    $convert.base64Decode(
        'ChhGaW5pc2hFYm9va1VwbG9hZFJlcXVlc3QSGwoJdXBsb2FkX2lkGAEgASgJUgh1cGxvYWRJZA'
        '==');

@$core.Deprecated('Use finishEbookUploadResponseDescriptor instead')
const FinishEbookUploadResponse$json = {
  '1': 'FinishEbookUploadResponse',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '10': 'content'
    },
    {'1': 'already_held', '3': 2, '4': 1, '5': 8, '10': 'alreadyHeld'},
  ],
};

/// Descriptor for `FinishEbookUploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List finishEbookUploadResponseDescriptor = $convert.base64Decode(
    'ChlGaW5pc2hFYm9va1VwbG9hZFJlc3BvbnNlEjAKB2NvbnRlbnQYASABKAsyFi5xdWlyZS52MS'
    '5FYm9va0NvbnRlbnRSB2NvbnRlbnQSIQoMYWxyZWFkeV9oZWxkGAIgASgIUgthbHJlYWR5SGVs'
    'ZA==');

@$core.Deprecated('Use discardEbookUploadRequestDescriptor instead')
const DiscardEbookUploadRequest$json = {
  '1': 'DiscardEbookUploadRequest',
  '2': [
    {'1': 'upload_id', '3': 1, '4': 1, '5': 9, '10': 'uploadId'},
  ],
};

/// Descriptor for `DiscardEbookUploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discardEbookUploadRequestDescriptor =
    $convert.base64Decode(
        'ChlEaXNjYXJkRWJvb2tVcGxvYWRSZXF1ZXN0EhsKCXVwbG9hZF9pZBgBIAEoCVIIdXBsb2FkSW'
        'Q=');

@$core.Deprecated('Use discardEbookUploadResponseDescriptor instead')
const DiscardEbookUploadResponse$json = {
  '1': 'DiscardEbookUploadResponse',
};

/// Descriptor for `DiscardEbookUploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discardEbookUploadResponseDescriptor =
    $convert.base64Decode('ChpEaXNjYXJkRWJvb2tVcGxvYWRSZXNwb25zZQ==');

@$core.Deprecated('Use downloadEbookContentRequestDescriptor instead')
const DownloadEbookContentRequest$json = {
  '1': 'DownloadEbookContentRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
  ],
};

/// Descriptor for `DownloadEbookContentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadEbookContentRequestDescriptor =
    $convert.base64Decode(
        'ChtEb3dubG9hZEVib29rQ29udGVudFJlcXVlc3QSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSW'
        'Q=');

@$core.Deprecated('Use downloadEbookContentResponseDescriptor instead')
const DownloadEbookContentResponse$json = {
  '1': 'DownloadEbookContentResponse',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.EbookContent',
      '9': 0,
      '10': 'content'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `DownloadEbookContentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadEbookContentResponseDescriptor =
    $convert.base64Decode(
        'ChxEb3dubG9hZEVib29rQ29udGVudFJlc3BvbnNlEjIKB2NvbnRlbnQYASABKAsyFi5xdWlyZS'
        '52MS5FYm9va0NvbnRlbnRIAFIHY29udGVudBIWCgVjaHVuaxgCIAEoDEgAUgVjaHVua0IJCgdw'
        'YXlsb2Fk');

@$core.Deprecated('Use createCollectionRequestDescriptor instead')
const CreateCollectionRequest$json = {
  '1': 'CreateCollectionRequest',
  '2': [
    {
      '1': 'collection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collection'
    },
  ],
};

/// Descriptor for `CreateCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createCollectionRequestDescriptor =
    $convert.base64Decode(
        'ChdDcmVhdGVDb2xsZWN0aW9uUmVxdWVzdBI0Cgpjb2xsZWN0aW9uGAEgASgLMhQucXVpcmUudj'
        'EuQ29sbGVjdGlvblIKY29sbGVjdGlvbg==');

@$core.Deprecated('Use createCollectionResponseDescriptor instead')
const CreateCollectionResponse$json = {
  '1': 'CreateCollectionResponse',
  '2': [
    {
      '1': 'collection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collection'
    },
  ],
};

/// Descriptor for `CreateCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createCollectionResponseDescriptor =
    $convert.base64Decode(
        'ChhDcmVhdGVDb2xsZWN0aW9uUmVzcG9uc2USNAoKY29sbGVjdGlvbhgBIAEoCzIULnF1aXJlLn'
        'YxLkNvbGxlY3Rpb25SCmNvbGxlY3Rpb24=');

@$core.Deprecated('Use getCollectionRequestDescriptor instead')
const GetCollectionRequest$json = {
  '1': 'GetCollectionRequest',
  '2': [
    {'1': 'collection_id', '3': 1, '4': 1, '5': 9, '10': 'collectionId'},
  ],
};

/// Descriptor for `GetCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCollectionRequestDescriptor = $convert.base64Decode(
    'ChRHZXRDb2xsZWN0aW9uUmVxdWVzdBIjCg1jb2xsZWN0aW9uX2lkGAEgASgJUgxjb2xsZWN0aW'
    '9uSWQ=');

@$core.Deprecated('Use getCollectionResponseDescriptor instead')
const GetCollectionResponse$json = {
  '1': 'GetCollectionResponse',
  '2': [
    {
      '1': 'collection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collection'
    },
  ],
};

/// Descriptor for `GetCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCollectionResponseDescriptor = $convert.base64Decode(
    'ChVHZXRDb2xsZWN0aW9uUmVzcG9uc2USNAoKY29sbGVjdGlvbhgBIAEoCzIULnF1aXJlLnYxLk'
    'NvbGxlY3Rpb25SCmNvbGxlY3Rpb24=');

@$core.Deprecated('Use listCollectionsRequestDescriptor instead')
const ListCollectionsRequest$json = {
  '1': 'ListCollectionsRequest',
  '2': [
    {
      '1': 'ebook_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'ebookId',
      '17': true
    },
  ],
  '8': [
    {'1': '_ebook_id'},
  ],
};

/// Descriptor for `ListCollectionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCollectionsRequestDescriptor =
    $convert.base64Decode(
        'ChZMaXN0Q29sbGVjdGlvbnNSZXF1ZXN0Eh4KCGVib29rX2lkGAEgASgJSABSB2Vib29rSWSIAQ'
        'FCCwoJX2Vib29rX2lk');

@$core.Deprecated('Use listCollectionsResponseDescriptor instead')
const ListCollectionsResponse$json = {
  '1': 'ListCollectionsResponse',
  '2': [
    {
      '1': 'collections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collections'
    },
  ],
};

/// Descriptor for `ListCollectionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCollectionsResponseDescriptor =
    $convert.base64Decode(
        'ChdMaXN0Q29sbGVjdGlvbnNSZXNwb25zZRI2Cgtjb2xsZWN0aW9ucxgBIAMoCzIULnF1aXJlLn'
        'YxLkNvbGxlY3Rpb25SC2NvbGxlY3Rpb25z');

@$core.Deprecated('Use updateCollectionRequestDescriptor instead')
const UpdateCollectionRequest$json = {
  '1': 'UpdateCollectionRequest',
  '2': [
    {'1': 'collection_id', '3': 1, '4': 1, '5': 9, '10': 'collectionId'},
    {
      '1': 'collection',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collection'
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

/// Descriptor for `UpdateCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateCollectionRequestDescriptor = $convert.base64Decode(
    'ChdVcGRhdGVDb2xsZWN0aW9uUmVxdWVzdBIjCg1jb2xsZWN0aW9uX2lkGAEgASgJUgxjb2xsZW'
    'N0aW9uSWQSNAoKY29sbGVjdGlvbhgCIAEoCzIULnF1aXJlLnYxLkNvbGxlY3Rpb25SCmNvbGxl'
    'Y3Rpb24SOwoLdXBkYXRlX21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUg'
    'p1cGRhdGVNYXNr');

@$core.Deprecated('Use updateCollectionResponseDescriptor instead')
const UpdateCollectionResponse$json = {
  '1': 'UpdateCollectionResponse',
  '2': [
    {
      '1': 'collection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.quire.v1.Collection',
      '10': 'collection'
    },
  ],
};

/// Descriptor for `UpdateCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateCollectionResponseDescriptor =
    $convert.base64Decode(
        'ChhVcGRhdGVDb2xsZWN0aW9uUmVzcG9uc2USNAoKY29sbGVjdGlvbhgBIAEoCzIULnF1aXJlLn'
        'YxLkNvbGxlY3Rpb25SCmNvbGxlY3Rpb24=');

@$core.Deprecated('Use deleteCollectionRequestDescriptor instead')
const DeleteCollectionRequest$json = {
  '1': 'DeleteCollectionRequest',
  '2': [
    {'1': 'collection_id', '3': 1, '4': 1, '5': 9, '10': 'collectionId'},
  ],
};

/// Descriptor for `DeleteCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteCollectionRequestDescriptor =
    $convert.base64Decode(
        'ChdEZWxldGVDb2xsZWN0aW9uUmVxdWVzdBIjCg1jb2xsZWN0aW9uX2lkGAEgASgJUgxjb2xsZW'
        'N0aW9uSWQ=');

@$core.Deprecated('Use deleteCollectionResponseDescriptor instead')
const DeleteCollectionResponse$json = {
  '1': 'DeleteCollectionResponse',
};

/// Descriptor for `DeleteCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteCollectionResponseDescriptor =
    $convert.base64Decode('ChhEZWxldGVDb2xsZWN0aW9uUmVzcG9uc2U=');

@$core.Deprecated('Use addEbookToCollectionRequestDescriptor instead')
const AddEbookToCollectionRequest$json = {
  '1': 'AddEbookToCollectionRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {'1': 'collection_id', '3': 2, '4': 1, '5': 9, '10': 'collectionId'},
  ],
};

/// Descriptor for `AddEbookToCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addEbookToCollectionRequestDescriptor =
    $convert.base64Decode(
        'ChtBZGRFYm9va1RvQ29sbGVjdGlvblJlcXVlc3QSGQoIZWJvb2tfaWQYASABKAlSB2Vib29rSW'
        'QSIwoNY29sbGVjdGlvbl9pZBgCIAEoCVIMY29sbGVjdGlvbklk');

@$core.Deprecated('Use addEbookToCollectionResponseDescriptor instead')
const AddEbookToCollectionResponse$json = {
  '1': 'AddEbookToCollectionResponse',
};

/// Descriptor for `AddEbookToCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addEbookToCollectionResponseDescriptor =
    $convert.base64Decode('ChxBZGRFYm9va1RvQ29sbGVjdGlvblJlc3BvbnNl');

@$core.Deprecated('Use removeEbookFromCollectionRequestDescriptor instead')
const RemoveEbookFromCollectionRequest$json = {
  '1': 'RemoveEbookFromCollectionRequest',
  '2': [
    {'1': 'ebook_id', '3': 1, '4': 1, '5': 9, '10': 'ebookId'},
    {'1': 'collection_id', '3': 2, '4': 1, '5': 9, '10': 'collectionId'},
  ],
};

/// Descriptor for `RemoveEbookFromCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeEbookFromCollectionRequestDescriptor =
    $convert.base64Decode(
        'CiBSZW1vdmVFYm9va0Zyb21Db2xsZWN0aW9uUmVxdWVzdBIZCghlYm9va19pZBgBIAEoCVIHZW'
        'Jvb2tJZBIjCg1jb2xsZWN0aW9uX2lkGAIgASgJUgxjb2xsZWN0aW9uSWQ=');

@$core.Deprecated('Use removeEbookFromCollectionResponseDescriptor instead')
const RemoveEbookFromCollectionResponse$json = {
  '1': 'RemoveEbookFromCollectionResponse',
};

/// Descriptor for `RemoveEbookFromCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeEbookFromCollectionResponseDescriptor =
    $convert.base64Decode('CiFSZW1vdmVFYm9va0Zyb21Db2xsZWN0aW9uUmVzcG9uc2U=');

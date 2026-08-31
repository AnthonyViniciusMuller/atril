// This is a generated file - do not edit.
//
// Generated from quire/v1/reading.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What kind of mark the reader left. A note is text the reader wrote; a
/// highlight and a bookmark are about the passage and carry text only if they
/// were given one.
class AnnotationKind extends $pb.ProtobufEnum {
  static const AnnotationKind ANNOTATION_KIND_UNSPECIFIED =
      AnnotationKind._(0, _omitEnumNames ? '' : 'ANNOTATION_KIND_UNSPECIFIED');
  static const AnnotationKind ANNOTATION_KIND_NOTE =
      AnnotationKind._(1, _omitEnumNames ? '' : 'ANNOTATION_KIND_NOTE');
  static const AnnotationKind ANNOTATION_KIND_HIGHLIGHT =
      AnnotationKind._(2, _omitEnumNames ? '' : 'ANNOTATION_KIND_HIGHLIGHT');
  static const AnnotationKind ANNOTATION_KIND_BOOKMARK =
      AnnotationKind._(3, _omitEnumNames ? '' : 'ANNOTATION_KIND_BOOKMARK');

  static const $core.List<AnnotationKind> values = <AnnotationKind>[
    ANNOTATION_KIND_UNSPECIFIED,
    ANNOTATION_KIND_NOTE,
    ANNOTATION_KIND_HIGHLIGHT,
    ANNOTATION_KIND_BOOKMARK,
  ];

  static final $core.List<AnnotationKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AnnotationKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AnnotationKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

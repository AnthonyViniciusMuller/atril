// This is a generated file - do not edit.
//
// Generated from quire/v1/sync.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Which record an operation changed. Named logically rather than by table, so
/// that the same name travels in this contract, in the node's schema and in the
/// SQLite schema on the device.
class TargetEntity extends $pb.ProtobufEnum {
  static const TargetEntity TARGET_ENTITY_UNSPECIFIED =
      TargetEntity._(0, _omitEnumNames ? '' : 'TARGET_ENTITY_UNSPECIFIED');
  static const TargetEntity TARGET_ENTITY_EBOOK =
      TargetEntity._(1, _omitEnumNames ? '' : 'TARGET_ENTITY_EBOOK');
  static const TargetEntity TARGET_ENTITY_COLLECTION =
      TargetEntity._(2, _omitEnumNames ? '' : 'TARGET_ENTITY_COLLECTION');
  static const TargetEntity TARGET_ENTITY_EBOOK_COLLECTION =
      TargetEntity._(3, _omitEnumNames ? '' : 'TARGET_ENTITY_EBOOK_COLLECTION');
  static const TargetEntity TARGET_ENTITY_READING_PROGRESS =
      TargetEntity._(4, _omitEnumNames ? '' : 'TARGET_ENTITY_READING_PROGRESS');
  static const TargetEntity TARGET_ENTITY_ANNOTATION =
      TargetEntity._(5, _omitEnumNames ? '' : 'TARGET_ENTITY_ANNOTATION');

  static const $core.List<TargetEntity> values = <TargetEntity>[
    TARGET_ENTITY_UNSPECIFIED,
    TARGET_ENTITY_EBOOK,
    TARGET_ENTITY_COLLECTION,
    TARGET_ENTITY_EBOOK_COLLECTION,
    TARGET_ENTITY_READING_PROGRESS,
    TARGET_ENTITY_ANNOTATION,
  ];

  static final $core.List<TargetEntity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static TargetEntity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TargetEntity._(super.value, super.name);
}

/// What the operation did to that record. Deletion is a write like any other:
/// it sets the tombstone, and reconciles against a concurrent edit by the same
/// rule everything else does.
class OperationKind extends $pb.ProtobufEnum {
  static const OperationKind OPERATION_KIND_UNSPECIFIED =
      OperationKind._(0, _omitEnumNames ? '' : 'OPERATION_KIND_UNSPECIFIED');
  static const OperationKind OPERATION_KIND_INSERT =
      OperationKind._(1, _omitEnumNames ? '' : 'OPERATION_KIND_INSERT');
  static const OperationKind OPERATION_KIND_UPDATE =
      OperationKind._(2, _omitEnumNames ? '' : 'OPERATION_KIND_UPDATE');
  static const OperationKind OPERATION_KIND_DELETE =
      OperationKind._(3, _omitEnumNames ? '' : 'OPERATION_KIND_DELETE');

  static const $core.List<OperationKind> values = <OperationKind>[
    OPERATION_KIND_UNSPECIFIED,
    OPERATION_KIND_INSERT,
    OPERATION_KIND_UPDATE,
    OPERATION_KIND_DELETE,
  ];

  static final $core.List<OperationKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static OperationKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OperationKind._(super.value, super.name);
}

/// What became of one operation the caller offered.
class OperationOutcome extends $pb.ProtobufEnum {
  static const OperationOutcome OPERATION_OUTCOME_UNSPECIFIED =
      OperationOutcome._(
          0, _omitEnumNames ? '' : 'OPERATION_OUTCOME_UNSPECIFIED');

  /// Stored, and it changed the record.
  static const OperationOutcome OPERATION_OUTCOME_APPLIED =
      OperationOutcome._(1, _omitEnumNames ? '' : 'OPERATION_OUTCOME_APPLIED');

  /// Already in this node's log, by id. Nothing was done, and nothing is wrong:
  /// an operation reaching a node twice by two routes is the normal shape of a
  /// federation, not a fault.
  static const OperationOutcome OPERATION_OUTCOME_DUPLICATE =
      OperationOutcome._(
          2, _omitEnumNames ? '' : 'OPERATION_OUTCOME_DUPLICATE');

  /// Stored, and it lost the merge. The record already held a version that this
  /// one does not causally precede and does not beat on the tie-break, so the
  /// operation is kept in the log — a later node must reach the same conclusion
  /// from the same history — and the record is unchanged.
  static const OperationOutcome OPERATION_OUTCOME_SUPERSEDED =
      OperationOutcome._(
          3, _omitEnumNames ? '' : 'OPERATION_OUTCOME_SUPERSEDED');

  /// Refused. The detail says why: a target that no longer exists, an entity
  /// name this node does not know. A caller cannot fix most of these by
  /// retrying.
  static const OperationOutcome OPERATION_OUTCOME_REJECTED =
      OperationOutcome._(4, _omitEnumNames ? '' : 'OPERATION_OUTCOME_REJECTED');

  static const $core.List<OperationOutcome> values = <OperationOutcome>[
    OPERATION_OUTCOME_UNSPECIFIED,
    OPERATION_OUTCOME_APPLIED,
    OPERATION_OUTCOME_DUPLICATE,
    OPERATION_OUTCOME_SUPERSEDED,
    OPERATION_OUTCOME_REJECTED,
  ];

  static final $core.List<OperationOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static OperationOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OperationOutcome._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

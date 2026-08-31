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
import 'package:protobuf/well_known_types/google/protobuf/field_mask.pb.dart'
    as $2;

import 'common.pb.dart' as $1;
import 'reading.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'reading.pbenum.dart';

/// Something the reader wrote, and the passage it is attached to.
class Annotation extends $pb.GeneratedMessage {
  factory Annotation({
    $core.String? id,
    $core.String? ebookId,
    AnnotationKind? kind,
    $core.String? text,
    $core.String? locator,
    $1.Revision? revision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (ebookId != null) result.ebookId = ebookId;
    if (kind != null) result.kind = kind;
    if (text != null) result.text = text;
    if (locator != null) result.locator = locator;
    if (revision != null) result.revision = revision;
    return result;
  }

  Annotation._();

  factory Annotation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Annotation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Annotation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'ebookId')
    ..aE<AnnotationKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: AnnotationKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aOS(5, _omitFieldNames ? '' : 'locator')
    ..aOM<$1.Revision>(6, _omitFieldNames ? '' : 'revision',
        subBuilder: $1.Revision.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Annotation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Annotation copyWith(void Function(Annotation) updates) =>
      super.copyWith((message) => updates(message as Annotation)) as Annotation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Annotation create() => Annotation._();
  @$core.override
  Annotation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Annotation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Annotation>(create);
  static Annotation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get ebookId => $_getSZ(1);
  @$pb.TagNumber(2)
  set ebookId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEbookId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEbookId() => $_clearField(2);

  @$pb.TagNumber(3)
  AnnotationKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(AnnotationKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// Required for a note, which is otherwise an empty note; optional on the
  /// other two.
  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  /// The passage, expressed so that it survives the format: a CFI in an EPUB, a
  /// page in a PDF. The same form a reading position uses, because the two
  /// answer the same question about the same document.
  @$pb.TagNumber(5)
  $core.String get locator => $_getSZ(4);
  @$pb.TagNumber(5)
  set locator($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLocator() => $_has(4);
  @$pb.TagNumber(5)
  void clearLocator() => $_clearField(5);

  @$pb.TagNumber(6)
  $1.Revision get revision => $_getN(5);
  @$pb.TagNumber(6)
  set revision($1.Revision value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRevision() => $_has(5);
  @$pb.TagNumber(6)
  void clearRevision() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Revision ensureRevision() => $_ensure(5);
}

/// Where one device stopped in one work.
class ReadingProgress extends $pb.GeneratedMessage {
  factory ReadingProgress({
    $core.String? ebookId,
    $core.String? deviceId,
    $core.String? locator,
    $core.double? percent,
    $1.VectorClock? vectorClock,
    $1.HybridTimestamp? updatedAt,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (deviceId != null) result.deviceId = deviceId;
    if (locator != null) result.locator = locator;
    if (percent != null) result.percent = percent;
    if (vectorClock != null) result.vectorClock = vectorClock;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  ReadingProgress._();

  factory ReadingProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadingProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadingProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'locator')
    ..aD(4, _omitFieldNames ? '' : 'percent')
    ..aOM<$1.VectorClock>(5, _omitFieldNames ? '' : 'vectorClock',
        subBuilder: $1.VectorClock.create)
    ..aOM<$1.HybridTimestamp>(6, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.HybridTimestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadingProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadingProgress copyWith(void Function(ReadingProgress) updates) =>
      super.copyWith((message) => updates(message as ReadingProgress))
          as ReadingProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadingProgress create() => ReadingProgress._();
  @$core.override
  ReadingProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadingProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadingProgress>(create);
  static ReadingProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  /// The device the position belongs to, and half of the row's natural key. It
  /// is not a tie-break here: nothing ever ties.
  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get locator => $_getSZ(2);
  @$pb.TagNumber(3)
  set locator($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocator() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocator() => $_clearField(3);

  /// How far through, 0 to 100, to two decimal places. Derived from the locator
  /// and stored anyway, so that a client can show progress without having to
  /// resolve a position it may not be able to interpret — a device that cannot
  /// open a DjVu can still report that the reader is 40% through it.
  @$pb.TagNumber(4)
  $core.double get percent => $_getN(3);
  @$pb.TagNumber(4)
  set percent($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPercent() => $_has(3);
  @$pb.TagNumber(4)
  void clearPercent() => $_clearField(4);

  /// A version counter rather than a conflict resolver, per C05. It still
  /// travels: replication uses it to recognize a position it has already seen.
  @$pb.TagNumber(5)
  $1.VectorClock get vectorClock => $_getN(4);
  @$pb.TagNumber(5)
  set vectorClock($1.VectorClock value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasVectorClock() => $_has(4);
  @$pb.TagNumber(5)
  void clearVectorClock() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.VectorClock ensureVectorClock() => $_ensure(4);

  @$pb.TagNumber(6)
  $1.HybridTimestamp get updatedAt => $_getN(5);
  @$pb.TagNumber(6)
  set updatedAt($1.HybridTimestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.HybridTimestamp ensureUpdatedAt() => $_ensure(5);
}

class CreateAnnotationRequest extends $pb.GeneratedMessage {
  factory CreateAnnotationRequest({
    Annotation? annotation,
  }) {
    final result = create();
    if (annotation != null) result.annotation = annotation;
    return result;
  }

  CreateAnnotationRequest._();

  factory CreateAnnotationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateAnnotationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateAnnotationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Annotation>(1, _omitFieldNames ? '' : 'annotation',
        subBuilder: Annotation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAnnotationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAnnotationRequest copyWith(
          void Function(CreateAnnotationRequest) updates) =>
      super.copyWith((message) => updates(message as CreateAnnotationRequest))
          as CreateAnnotationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateAnnotationRequest create() => CreateAnnotationRequest._();
  @$core.override
  CreateAnnotationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateAnnotationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateAnnotationRequest>(create);
  static CreateAnnotationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Annotation get annotation => $_getN(0);
  @$pb.TagNumber(1)
  set annotation(Annotation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotation() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotation() => $_clearField(1);
  @$pb.TagNumber(1)
  Annotation ensureAnnotation() => $_ensure(0);
}

class CreateAnnotationResponse extends $pb.GeneratedMessage {
  factory CreateAnnotationResponse({
    Annotation? annotation,
  }) {
    final result = create();
    if (annotation != null) result.annotation = annotation;
    return result;
  }

  CreateAnnotationResponse._();

  factory CreateAnnotationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateAnnotationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateAnnotationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Annotation>(1, _omitFieldNames ? '' : 'annotation',
        subBuilder: Annotation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAnnotationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAnnotationResponse copyWith(
          void Function(CreateAnnotationResponse) updates) =>
      super.copyWith((message) => updates(message as CreateAnnotationResponse))
          as CreateAnnotationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateAnnotationResponse create() => CreateAnnotationResponse._();
  @$core.override
  CreateAnnotationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateAnnotationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateAnnotationResponse>(create);
  static CreateAnnotationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Annotation get annotation => $_getN(0);
  @$pb.TagNumber(1)
  set annotation(Annotation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotation() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotation() => $_clearField(1);
  @$pb.TagNumber(1)
  Annotation ensureAnnotation() => $_ensure(0);
}

class GetAnnotationRequest extends $pb.GeneratedMessage {
  factory GetAnnotationRequest({
    $core.String? annotationId,
  }) {
    final result = create();
    if (annotationId != null) result.annotationId = annotationId;
    return result;
  }

  GetAnnotationRequest._();

  factory GetAnnotationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAnnotationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAnnotationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'annotationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAnnotationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAnnotationRequest copyWith(void Function(GetAnnotationRequest) updates) =>
      super.copyWith((message) => updates(message as GetAnnotationRequest))
          as GetAnnotationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAnnotationRequest create() => GetAnnotationRequest._();
  @$core.override
  GetAnnotationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAnnotationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAnnotationRequest>(create);
  static GetAnnotationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get annotationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set annotationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotationId() => $_clearField(1);
}

class GetAnnotationResponse extends $pb.GeneratedMessage {
  factory GetAnnotationResponse({
    Annotation? annotation,
  }) {
    final result = create();
    if (annotation != null) result.annotation = annotation;
    return result;
  }

  GetAnnotationResponse._();

  factory GetAnnotationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAnnotationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAnnotationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Annotation>(1, _omitFieldNames ? '' : 'annotation',
        subBuilder: Annotation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAnnotationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAnnotationResponse copyWith(
          void Function(GetAnnotationResponse) updates) =>
      super.copyWith((message) => updates(message as GetAnnotationResponse))
          as GetAnnotationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAnnotationResponse create() => GetAnnotationResponse._();
  @$core.override
  GetAnnotationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAnnotationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAnnotationResponse>(create);
  static GetAnnotationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Annotation get annotation => $_getN(0);
  @$pb.TagNumber(1)
  set annotation(Annotation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotation() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotation() => $_clearField(1);
  @$pb.TagNumber(1)
  Annotation ensureAnnotation() => $_ensure(0);
}

class ListAnnotationsRequest extends $pb.GeneratedMessage {
  factory ListAnnotationsRequest({
    $core.String? ebookId,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListAnnotationsRequest._();

  factory ListAnnotationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListAnnotationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListAnnotationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aI(2, _omitFieldNames ? '' : 'pageSize')
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAnnotationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAnnotationsRequest copyWith(
          void Function(ListAnnotationsRequest) updates) =>
      super.copyWith((message) => updates(message as ListAnnotationsRequest))
          as ListAnnotationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListAnnotationsRequest create() => ListAnnotationsRequest._();
  @$core.override
  ListAnnotationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListAnnotationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListAnnotationsRequest>(create);
  static ListAnnotationsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  /// Zero asks the server to choose.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Tombstoned annotations are not listed. A client rebuilding its local state
/// wants them and gets them from SyncService, where the history is.
class ListAnnotationsResponse extends $pb.GeneratedMessage {
  factory ListAnnotationsResponse({
    $core.Iterable<Annotation>? annotations,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (annotations != null) result.annotations.addAll(annotations);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListAnnotationsResponse._();

  factory ListAnnotationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListAnnotationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListAnnotationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Annotation>(1, _omitFieldNames ? '' : 'annotations',
        subBuilder: Annotation.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAnnotationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAnnotationsResponse copyWith(
          void Function(ListAnnotationsResponse) updates) =>
      super.copyWith((message) => updates(message as ListAnnotationsResponse))
          as ListAnnotationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListAnnotationsResponse create() => ListAnnotationsResponse._();
  @$core.override
  ListAnnotationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListAnnotationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListAnnotationsResponse>(create);
  static ListAnnotationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Annotation> get annotations => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

class UpdateAnnotationRequest extends $pb.GeneratedMessage {
  factory UpdateAnnotationRequest({
    $core.String? annotationId,
    Annotation? annotation,
    $2.FieldMask? updateMask,
  }) {
    final result = create();
    if (annotationId != null) result.annotationId = annotationId;
    if (annotation != null) result.annotation = annotation;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateAnnotationRequest._();

  factory UpdateAnnotationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateAnnotationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateAnnotationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'annotationId')
    ..aOM<Annotation>(2, _omitFieldNames ? '' : 'annotation',
        subBuilder: Annotation.create)
    ..aOM<$2.FieldMask>(3, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $2.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAnnotationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAnnotationRequest copyWith(
          void Function(UpdateAnnotationRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateAnnotationRequest))
          as UpdateAnnotationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateAnnotationRequest create() => UpdateAnnotationRequest._();
  @$core.override
  UpdateAnnotationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateAnnotationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateAnnotationRequest>(create);
  static UpdateAnnotationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get annotationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set annotationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotationId() => $_clearField(1);

  @$pb.TagNumber(2)
  Annotation get annotation => $_getN(1);
  @$pb.TagNumber(2)
  set annotation(Annotation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAnnotation() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnnotation() => $_clearField(2);
  @$pb.TagNumber(2)
  Annotation ensureAnnotation() => $_ensure(1);

  /// Per-field last-writer-wins: the mask is the set of fields this write claims
  /// and leaves every other field to whichever device wrote it last.
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

class UpdateAnnotationResponse extends $pb.GeneratedMessage {
  factory UpdateAnnotationResponse({
    Annotation? annotation,
  }) {
    final result = create();
    if (annotation != null) result.annotation = annotation;
    return result;
  }

  UpdateAnnotationResponse._();

  factory UpdateAnnotationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateAnnotationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateAnnotationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Annotation>(1, _omitFieldNames ? '' : 'annotation',
        subBuilder: Annotation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAnnotationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAnnotationResponse copyWith(
          void Function(UpdateAnnotationResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateAnnotationResponse))
          as UpdateAnnotationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateAnnotationResponse create() => UpdateAnnotationResponse._();
  @$core.override
  UpdateAnnotationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateAnnotationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateAnnotationResponse>(create);
  static UpdateAnnotationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Annotation get annotation => $_getN(0);
  @$pb.TagNumber(1)
  set annotation(Annotation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotation() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotation() => $_clearField(1);
  @$pb.TagNumber(1)
  Annotation ensureAnnotation() => $_ensure(0);
}

class DeleteAnnotationRequest extends $pb.GeneratedMessage {
  factory DeleteAnnotationRequest({
    $core.String? annotationId,
  }) {
    final result = create();
    if (annotationId != null) result.annotationId = annotationId;
    return result;
  }

  DeleteAnnotationRequest._();

  factory DeleteAnnotationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteAnnotationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteAnnotationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'annotationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAnnotationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAnnotationRequest copyWith(
          void Function(DeleteAnnotationRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteAnnotationRequest))
          as DeleteAnnotationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteAnnotationRequest create() => DeleteAnnotationRequest._();
  @$core.override
  DeleteAnnotationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteAnnotationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteAnnotationRequest>(create);
  static DeleteAnnotationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get annotationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set annotationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnotationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnotationId() => $_clearField(1);
}

class DeleteAnnotationResponse extends $pb.GeneratedMessage {
  factory DeleteAnnotationResponse() => create();

  DeleteAnnotationResponse._();

  factory DeleteAnnotationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteAnnotationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteAnnotationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAnnotationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAnnotationResponse copyWith(
          void Function(DeleteAnnotationResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteAnnotationResponse))
          as DeleteAnnotationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteAnnotationResponse create() => DeleteAnnotationResponse._();
  @$core.override
  DeleteAnnotationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteAnnotationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteAnnotationResponse>(create);
  static DeleteAnnotationResponse? _defaultInstance;
}

/// The device is not a field: the position belongs to the caller, taken from the
/// authenticated session. A request that could name a device would be a request
/// that could move another device's bookmark.
class UpdateReadingProgressRequest extends $pb.GeneratedMessage {
  factory UpdateReadingProgressRequest({
    $core.String? ebookId,
    $core.String? locator,
    $core.double? percent,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (locator != null) result.locator = locator;
    if (percent != null) result.percent = percent;
    return result;
  }

  UpdateReadingProgressRequest._();

  factory UpdateReadingProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateReadingProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateReadingProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aOS(2, _omitFieldNames ? '' : 'locator')
    ..aD(3, _omitFieldNames ? '' : 'percent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReadingProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReadingProgressRequest copyWith(
          void Function(UpdateReadingProgressRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateReadingProgressRequest))
          as UpdateReadingProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateReadingProgressRequest create() =>
      UpdateReadingProgressRequest._();
  @$core.override
  UpdateReadingProgressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateReadingProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateReadingProgressRequest>(create);
  static UpdateReadingProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get locator => $_getSZ(1);
  @$pb.TagNumber(2)
  set locator($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocator() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get percent => $_getN(2);
  @$pb.TagNumber(3)
  set percent($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearPercent() => $_clearField(3);
}

class UpdateReadingProgressResponse extends $pb.GeneratedMessage {
  factory UpdateReadingProgressResponse({
    ReadingProgress? progress,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    return result;
  }

  UpdateReadingProgressResponse._();

  factory UpdateReadingProgressResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateReadingProgressResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateReadingProgressResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<ReadingProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: ReadingProgress.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReadingProgressResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateReadingProgressResponse copyWith(
          void Function(UpdateReadingProgressResponse) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateReadingProgressResponse))
          as UpdateReadingProgressResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateReadingProgressResponse create() =>
      UpdateReadingProgressResponse._();
  @$core.override
  UpdateReadingProgressResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateReadingProgressResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateReadingProgressResponse>(create);
  static UpdateReadingProgressResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ReadingProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(ReadingProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  ReadingProgress ensureProgress() => $_ensure(0);
}

class ListReadingProgressRequest extends $pb.GeneratedMessage {
  factory ListReadingProgressRequest({
    $core.String? ebookId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    return result;
  }

  ListReadingProgressRequest._();

  factory ListReadingProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReadingProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReadingProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReadingProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReadingProgressRequest copyWith(
          void Function(ListReadingProgressRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListReadingProgressRequest))
          as ListReadingProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReadingProgressRequest create() => ListReadingProgressRequest._();
  @$core.override
  ListReadingProgressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReadingProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReadingProgressRequest>(create);
  static ListReadingProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);
}

/// Not paginated: one row per device the reader has ever read this work on.
class ListReadingProgressResponse extends $pb.GeneratedMessage {
  factory ListReadingProgressResponse({
    $core.Iterable<ReadingProgress>? progress,
  }) {
    final result = create();
    if (progress != null) result.progress.addAll(progress);
    return result;
  }

  ListReadingProgressResponse._();

  factory ListReadingProgressResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReadingProgressResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReadingProgressResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<ReadingProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: ReadingProgress.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReadingProgressResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReadingProgressResponse copyWith(
          void Function(ListReadingProgressResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListReadingProgressResponse))
          as ListReadingProgressResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReadingProgressResponse create() =>
      ListReadingProgressResponse._();
  @$core.override
  ListReadingProgressResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReadingProgressResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReadingProgressResponse>(create);
  static ListReadingProgressResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReadingProgress> get progress => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

// This is a generated file - do not edit.
//
// Generated from quire/v1/library.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/field_mask.pb.dart'
    as $4;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as $1;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $2;

import 'common.pb.dart' as $3;
import 'library.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'library.pbenum.dart';

/// A work in the reader's collection.
class Ebook extends $pb.GeneratedMessage {
  factory Ebook({
    $core.String? id,
    $core.String? title,
    $core.String? author,
    $core.String? publisher,
    $core.String? language,
    EbookFormat? format,
    $core.String? contentHash,
    $fixnum.Int64? sizeBytes,
    $1.Struct? extraMetadata,
    $2.Timestamp? importedAt,
    $3.Revision? revision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (author != null) result.author = author;
    if (publisher != null) result.publisher = publisher;
    if (language != null) result.language = language;
    if (format != null) result.format = format;
    if (contentHash != null) result.contentHash = contentHash;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (extraMetadata != null) result.extraMetadata = extraMetadata;
    if (importedAt != null) result.importedAt = importedAt;
    if (revision != null) result.revision = revision;
    return result;
  }

  Ebook._();

  factory Ebook.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Ebook.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ebook',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'author')
    ..aOS(4, _omitFieldNames ? '' : 'publisher')
    ..aOS(5, _omitFieldNames ? '' : 'language')
    ..aE<EbookFormat>(6, _omitFieldNames ? '' : 'format',
        enumValues: EbookFormat.values)
    ..aOS(7, _omitFieldNames ? '' : 'contentHash')
    ..aInt64(8, _omitFieldNames ? '' : 'sizeBytes')
    ..aOM<$1.Struct>(9, _omitFieldNames ? '' : 'extraMetadata',
        subBuilder: $1.Struct.create)
    ..aOM<$2.Timestamp>(10, _omitFieldNames ? '' : 'importedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$3.Revision>(11, _omitFieldNames ? '' : 'revision',
        subBuilder: $3.Revision.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ebook clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ebook copyWith(void Function(Ebook) updates) =>
      super.copyWith((message) => updates(message as Ebook)) as Ebook;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Ebook create() => Ebook._();
  @$core.override
  Ebook createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Ebook getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ebook>(create);
  static Ebook? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  /// Absent rather than empty when the file did not say. A work whose author is
  /// unknown and one whose author is the empty string are different claims.
  @$pb.TagNumber(3)
  $core.String get author => $_getSZ(2);
  @$pb.TagNumber(3)
  set author($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get publisher => $_getSZ(3);
  @$pb.TagNumber(4)
  set publisher($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPublisher() => $_has(3);
  @$pb.TagNumber(4)
  void clearPublisher() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get language => $_getSZ(4);
  @$pb.TagNumber(5)
  set language($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLanguage() => $_has(4);
  @$pb.TagNumber(5)
  void clearLanguage() => $_clearField(5);

  @$pb.TagNumber(6)
  EbookFormat get format => $_getN(5);
  @$pb.TagNumber(6)
  set format(EbookFormat value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasFormat() => $_has(5);
  @$pb.TagNumber(6)
  void clearFormat() => $_clearField(6);

  /// The digest of the file, lowercase hex sha-256. It is what identifies the
  /// bytes across the whole federation: the same work imported by two readers,
  /// or by one reader on two devices, converges on one stored object.
  ///
  /// It is deliberately not a reference to something this node holds. A node
  /// replicating a reader without their files has every row here and none of
  /// the bytes (D02).
  @$pb.TagNumber(7)
  $core.String get contentHash => $_getSZ(6);
  @$pb.TagNumber(7)
  set contentHash($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasContentHash() => $_has(6);
  @$pb.TagNumber(7)
  void clearContentHash() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sizeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSizeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSizeBytes() => $_clearField(8);

  /// The metadata a format carries and this contract does not name — series,
  /// ISBN, subjects (RF05). An object, never a scalar: the column it lands in
  /// is jsonb and constrained to one.
  @$pb.TagNumber(9)
  $1.Struct get extraMetadata => $_getN(8);
  @$pb.TagNumber(9)
  set extraMetadata($1.Struct value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasExtraMetadata() => $_has(8);
  @$pb.TagNumber(9)
  void clearExtraMetadata() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Struct ensureExtraMetadata() => $_ensure(8);

  @$pb.TagNumber(10)
  $2.Timestamp get importedAt => $_getN(9);
  @$pb.TagNumber(10)
  set importedAt($2.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasImportedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearImportedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.Timestamp ensureImportedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $3.Revision get revision => $_getN(10);
  @$pb.TagNumber(11)
  set revision($3.Revision value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasRevision() => $_has(10);
  @$pb.TagNumber(11)
  void clearRevision() => $_clearField(11);
  @$pb.TagNumber(11)
  $3.Revision ensureRevision() => $_ensure(10);
}

/// A grouping the reader defined over their collection.
class Collection extends $pb.GeneratedMessage {
  factory Collection({
    $core.String? id,
    $core.String? name,
    CollectionKind? kind,
    $core.String? description,
    $2.Timestamp? createdAt,
    $3.Revision? revision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (description != null) result.description = description;
    if (createdAt != null) result.createdAt = createdAt;
    if (revision != null) result.revision = revision;
    return result;
  }

  Collection._();

  factory Collection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Collection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Collection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<CollectionKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: CollectionKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$3.Revision>(6, _omitFieldNames ? '' : 'revision',
        subBuilder: $3.Revision.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Collection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Collection copyWith(void Function(Collection) updates) =>
      super.copyWith((message) => updates(message as Collection)) as Collection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Collection create() => Collection._();
  @$core.override
  Collection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Collection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Collection>(create);
  static Collection? _defaultInstance;

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
  CollectionKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(CollectionKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(5)
  set createdAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureCreatedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $3.Revision get revision => $_getN(5);
  @$pb.TagNumber(6)
  set revision($3.Revision value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRevision() => $_has(5);
  @$pb.TagNumber(6)
  void clearRevision() => $_clearField(6);
  @$pb.TagNumber(6)
  $3.Revision ensureRevision() => $_ensure(5);
}

/// The bytes of a work, as this node holds them.
class EbookContent extends $pb.GeneratedMessage {
  factory EbookContent({
    $core.String? contentHash,
    $fixnum.Int64? sizeBytes,
    $core.String? mediaType,
  }) {
    final result = create();
    if (contentHash != null) result.contentHash = contentHash;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (mediaType != null) result.mediaType = mediaType;
    return result;
  }

  EbookContent._();

  factory EbookContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EbookContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EbookContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'contentHash')
    ..aInt64(2, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(3, _omitFieldNames ? '' : 'mediaType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EbookContent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EbookContent copyWith(void Function(EbookContent) updates) =>
      super.copyWith((message) => updates(message as EbookContent))
          as EbookContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EbookContent create() => EbookContent._();
  @$core.override
  EbookContent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EbookContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EbookContent>(create);
  static EbookContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get contentHash => $_getSZ(0);
  @$pb.TagNumber(1)
  set contentHash($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContentHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearContentHash() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mediaType => $_getSZ(2);
  @$pb.TagNumber(3)
  set mediaType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMediaType() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaType() => $_clearField(3);
}

class CreateEbookRequest extends $pb.GeneratedMessage {
  factory CreateEbookRequest({
    Ebook? ebook,
  }) {
    final result = create();
    if (ebook != null) result.ebook = ebook;
    return result;
  }

  CreateEbookRequest._();

  factory CreateEbookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateEbookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateEbookRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Ebook>(1, _omitFieldNames ? '' : 'ebook', subBuilder: Ebook.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEbookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEbookRequest copyWith(void Function(CreateEbookRequest) updates) =>
      super.copyWith((message) => updates(message as CreateEbookRequest))
          as CreateEbookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateEbookRequest create() => CreateEbookRequest._();
  @$core.override
  CreateEbookRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateEbookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateEbookRequest>(create);
  static CreateEbookRequest? _defaultInstance;

  /// The revision is ignored if set: the server stamps it with the calling
  /// device and that device's clock.
  @$pb.TagNumber(1)
  Ebook get ebook => $_getN(0);
  @$pb.TagNumber(1)
  set ebook(Ebook value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEbook() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbook() => $_clearField(1);
  @$pb.TagNumber(1)
  Ebook ensureEbook() => $_ensure(0);
}

class CreateEbookResponse extends $pb.GeneratedMessage {
  factory CreateEbookResponse({
    Ebook? ebook,
    $core.bool? contentMissing,
  }) {
    final result = create();
    if (ebook != null) result.ebook = ebook;
    if (contentMissing != null) result.contentMissing = contentMissing;
    return result;
  }

  CreateEbookResponse._();

  factory CreateEbookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateEbookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateEbookResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Ebook>(1, _omitFieldNames ? '' : 'ebook', subBuilder: Ebook.create)
    ..aOB(2, _omitFieldNames ? '' : 'contentMissing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEbookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEbookResponse copyWith(void Function(CreateEbookResponse) updates) =>
      super.copyWith((message) => updates(message as CreateEbookResponse))
          as CreateEbookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateEbookResponse create() => CreateEbookResponse._();
  @$core.override
  CreateEbookResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateEbookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateEbookResponse>(create);
  static CreateEbookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Ebook get ebook => $_getN(0);
  @$pb.TagNumber(1)
  set ebook(Ebook value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEbook() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbook() => $_clearField(1);
  @$pb.TagNumber(1)
  Ebook ensureEbook() => $_ensure(0);

  /// True when this node does not hold the bytes for the digest declared, which
  /// is the client's cue to call UploadEbookContent. It is false far more often
  /// than a client might expect — the same file imported on a second device, or
  /// by a second reader on this node, is already here.
  @$pb.TagNumber(2)
  $core.bool get contentMissing => $_getBF(1);
  @$pb.TagNumber(2)
  set contentMissing($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContentMissing() => $_has(1);
  @$pb.TagNumber(2)
  void clearContentMissing() => $_clearField(2);
}

class GetEbookRequest extends $pb.GeneratedMessage {
  factory GetEbookRequest({
    $core.String? ebookId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    return result;
  }

  GetEbookRequest._();

  factory GetEbookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetEbookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEbookRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEbookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEbookRequest copyWith(void Function(GetEbookRequest) updates) =>
      super.copyWith((message) => updates(message as GetEbookRequest))
          as GetEbookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEbookRequest create() => GetEbookRequest._();
  @$core.override
  GetEbookRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetEbookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEbookRequest>(create);
  static GetEbookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);
}

class GetEbookResponse extends $pb.GeneratedMessage {
  factory GetEbookResponse({
    Ebook? ebook,
  }) {
    final result = create();
    if (ebook != null) result.ebook = ebook;
    return result;
  }

  GetEbookResponse._();

  factory GetEbookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetEbookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEbookResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Ebook>(1, _omitFieldNames ? '' : 'ebook', subBuilder: Ebook.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEbookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEbookResponse copyWith(void Function(GetEbookResponse) updates) =>
      super.copyWith((message) => updates(message as GetEbookResponse))
          as GetEbookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEbookResponse create() => GetEbookResponse._();
  @$core.override
  GetEbookResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetEbookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEbookResponse>(create);
  static GetEbookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Ebook get ebook => $_getN(0);
  @$pb.TagNumber(1)
  set ebook(Ebook value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEbook() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbook() => $_clearField(1);
  @$pb.TagNumber(1)
  Ebook ensureEbook() => $_ensure(0);
}

class ListEbooksRequest extends $pb.GeneratedMessage {
  factory ListEbooksRequest({
    $core.int? pageSize,
    $core.String? pageToken,
    $core.String? collectionId,
  }) {
    final result = create();
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    if (collectionId != null) result.collectionId = collectionId;
    return result;
  }

  ListEbooksRequest._();

  factory ListEbooksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEbooksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEbooksRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'pageSize')
    ..aOS(2, _omitFieldNames ? '' : 'pageToken')
    ..aOS(3, _omitFieldNames ? '' : 'collectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEbooksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEbooksRequest copyWith(void Function(ListEbooksRequest) updates) =>
      super.copyWith((message) => updates(message as ListEbooksRequest))
          as ListEbooksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEbooksRequest create() => ListEbooksRequest._();
  @$core.override
  ListEbooksRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEbooksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEbooksRequest>(create);
  static ListEbooksRequest? _defaultInstance;

  /// Zero asks the server to choose. A client that wants a specific page size
  /// says so; one that does not should not have to.
  @$pb.TagNumber(1)
  $core.int get pageSize => $_getIZ(0);
  @$pb.TagNumber(1)
  set pageSize($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageSize() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set pageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageToken() => $_clearField(2);

  /// Narrows the reply to the works filed under one grouping.
  @$pb.TagNumber(3)
  $core.String get collectionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set collectionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollectionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollectionId() => $_clearField(3);
}

/// Tombstoned works are never listed here. A client rebuilding its local state
/// needs them and gets them from SyncService, which is where the history lives;
/// this service answers what the collection is, not how it got that way.
class ListEbooksResponse extends $pb.GeneratedMessage {
  factory ListEbooksResponse({
    $core.Iterable<Ebook>? ebooks,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (ebooks != null) result.ebooks.addAll(ebooks);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListEbooksResponse._();

  factory ListEbooksResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEbooksResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEbooksResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Ebook>(1, _omitFieldNames ? '' : 'ebooks', subBuilder: Ebook.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEbooksResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEbooksResponse copyWith(void Function(ListEbooksResponse) updates) =>
      super.copyWith((message) => updates(message as ListEbooksResponse))
          as ListEbooksResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEbooksResponse create() => ListEbooksResponse._();
  @$core.override
  ListEbooksResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEbooksResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEbooksResponse>(create);
  static ListEbooksResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Ebook> get ebooks => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

class UpdateEbookRequest extends $pb.GeneratedMessage {
  factory UpdateEbookRequest({
    $core.String? ebookId,
    Ebook? ebook,
    $4.FieldMask? updateMask,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (ebook != null) result.ebook = ebook;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateEbookRequest._();

  factory UpdateEbookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateEbookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateEbookRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aOM<Ebook>(2, _omitFieldNames ? '' : 'ebook', subBuilder: Ebook.create)
    ..aOM<$4.FieldMask>(3, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $4.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateEbookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateEbookRequest copyWith(void Function(UpdateEbookRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateEbookRequest))
          as UpdateEbookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateEbookRequest create() => UpdateEbookRequest._();
  @$core.override
  UpdateEbookRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateEbookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateEbookRequest>(create);
  static UpdateEbookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  @$pb.TagNumber(2)
  Ebook get ebook => $_getN(1);
  @$pb.TagNumber(2)
  set ebook(Ebook value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEbook() => $_has(1);
  @$pb.TagNumber(2)
  void clearEbook() => $_clearField(2);
  @$pb.TagNumber(2)
  Ebook ensureEbook() => $_ensure(1);

  /// Which fields the write claims. It is not only a convenience here:
  /// reconciliation is per-field last-writer-wins, so a mask naming two fields
  /// is a claim over those two and leaves every other field to whichever device
  /// wrote it last.
  @$pb.TagNumber(3)
  $4.FieldMask get updateMask => $_getN(2);
  @$pb.TagNumber(3)
  set updateMask($4.FieldMask value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdateMask() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateMask() => $_clearField(3);
  @$pb.TagNumber(3)
  $4.FieldMask ensureUpdateMask() => $_ensure(2);
}

class UpdateEbookResponse extends $pb.GeneratedMessage {
  factory UpdateEbookResponse({
    Ebook? ebook,
  }) {
    final result = create();
    if (ebook != null) result.ebook = ebook;
    return result;
  }

  UpdateEbookResponse._();

  factory UpdateEbookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateEbookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateEbookResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Ebook>(1, _omitFieldNames ? '' : 'ebook', subBuilder: Ebook.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateEbookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateEbookResponse copyWith(void Function(UpdateEbookResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateEbookResponse))
          as UpdateEbookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateEbookResponse create() => UpdateEbookResponse._();
  @$core.override
  UpdateEbookResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateEbookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateEbookResponse>(create);
  static UpdateEbookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Ebook get ebook => $_getN(0);
  @$pb.TagNumber(1)
  set ebook(Ebook value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEbook() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbook() => $_clearField(1);
  @$pb.TagNumber(1)
  Ebook ensureEbook() => $_ensure(0);
}

class DeleteEbookRequest extends $pb.GeneratedMessage {
  factory DeleteEbookRequest({
    $core.String? ebookId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    return result;
  }

  DeleteEbookRequest._();

  factory DeleteEbookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteEbookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteEbookRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteEbookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteEbookRequest copyWith(void Function(DeleteEbookRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteEbookRequest))
          as DeleteEbookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteEbookRequest create() => DeleteEbookRequest._();
  @$core.override
  DeleteEbookRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteEbookRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteEbookRequest>(create);
  static DeleteEbookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);
}

class DeleteEbookResponse extends $pb.GeneratedMessage {
  factory DeleteEbookResponse() => create();

  DeleteEbookResponse._();

  factory DeleteEbookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteEbookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteEbookResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteEbookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteEbookResponse copyWith(void Function(DeleteEbookResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteEbookResponse))
          as DeleteEbookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteEbookResponse create() => DeleteEbookResponse._();
  @$core.override
  DeleteEbookResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteEbookResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteEbookResponse>(create);
  static DeleteEbookResponse? _defaultInstance;
}

enum UploadEbookContentRequest_Payload { content, chunk, notSet }

class UploadEbookContentRequest extends $pb.GeneratedMessage {
  factory UploadEbookContentRequest({
    EbookContent? content,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (content != null) result.content = content;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  UploadEbookContentRequest._();

  factory UploadEbookContentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadEbookContentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UploadEbookContentRequest_Payload>
      _UploadEbookContentRequest_PayloadByTag = {
    1: UploadEbookContentRequest_Payload.content,
    2: UploadEbookContentRequest_Payload.chunk,
    0: UploadEbookContentRequest_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadEbookContentRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<EbookContent>(1, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadEbookContentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadEbookContentRequest copyWith(
          void Function(UploadEbookContentRequest) updates) =>
      super.copyWith((message) => updates(message as UploadEbookContentRequest))
          as UploadEbookContentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadEbookContentRequest create() => UploadEbookContentRequest._();
  @$core.override
  UploadEbookContentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadEbookContentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadEbookContentRequest>(create);
  static UploadEbookContentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UploadEbookContentRequest_Payload whichPayload() =>
      _UploadEbookContentRequest_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// Exactly once, as the first message of the stream.
  @$pb.TagNumber(1)
  EbookContent get content => $_getN(0);
  @$pb.TagNumber(1)
  set content(EbookContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
  @$pb.TagNumber(1)
  EbookContent ensureContent() => $_ensure(0);

  /// Then the bytes, in as many messages as the client chooses. The node
  /// hashes them as they arrive and rejects the upload if the digest does not
  /// match the one declared, so a truncated or altered transfer cannot be
  /// stored under a name that promises otherwise.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
}

class UploadEbookContentResponse extends $pb.GeneratedMessage {
  factory UploadEbookContentResponse({
    EbookContent? content,
  }) {
    final result = create();
    if (content != null) result.content = content;
    return result;
  }

  UploadEbookContentResponse._();

  factory UploadEbookContentResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadEbookContentResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadEbookContentResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<EbookContent>(1, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadEbookContentResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadEbookContentResponse copyWith(
          void Function(UploadEbookContentResponse) updates) =>
      super.copyWith(
              (message) => updates(message as UploadEbookContentResponse))
          as UploadEbookContentResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadEbookContentResponse create() => UploadEbookContentResponse._();
  @$core.override
  UploadEbookContentResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadEbookContentResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadEbookContentResponse>(create);
  static UploadEbookContentResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EbookContent get content => $_getN(0);
  @$pb.TagNumber(1)
  set content(EbookContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
  @$pb.TagNumber(1)
  EbookContent ensureContent() => $_ensure(0);
}

class BeginEbookUploadRequest extends $pb.GeneratedMessage {
  factory BeginEbookUploadRequest({
    EbookContent? content,
  }) {
    final result = create();
    if (content != null) result.content = content;
    return result;
  }

  BeginEbookUploadRequest._();

  factory BeginEbookUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BeginEbookUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BeginEbookUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<EbookContent>(1, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginEbookUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginEbookUploadRequest copyWith(
          void Function(BeginEbookUploadRequest) updates) =>
      super.copyWith((message) => updates(message as BeginEbookUploadRequest))
          as BeginEbookUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BeginEbookUploadRequest create() => BeginEbookUploadRequest._();
  @$core.override
  BeginEbookUploadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BeginEbookUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BeginEbookUploadRequest>(create);
  static BeginEbookUploadRequest? _defaultInstance;

  /// What is about to be sent, and the whole of what the node checks before
  /// agreeing to receive it.
  @$pb.TagNumber(1)
  EbookContent get content => $_getN(0);
  @$pb.TagNumber(1)
  set content(EbookContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
  @$pb.TagNumber(1)
  EbookContent ensureContent() => $_ensure(0);
}

class BeginEbookUploadResponse extends $pb.GeneratedMessage {
  factory BeginEbookUploadResponse({
    $core.String? uploadId,
    $core.bool? alreadyHeld,
    EbookContent? content,
  }) {
    final result = create();
    if (uploadId != null) result.uploadId = uploadId;
    if (alreadyHeld != null) result.alreadyHeld = alreadyHeld;
    if (content != null) result.content = content;
    return result;
  }

  BeginEbookUploadResponse._();

  factory BeginEbookUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BeginEbookUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BeginEbookUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uploadId')
    ..aOB(2, _omitFieldNames ? '' : 'alreadyHeld')
    ..aOM<EbookContent>(3, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginEbookUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginEbookUploadResponse copyWith(
          void Function(BeginEbookUploadResponse) updates) =>
      super.copyWith((message) => updates(message as BeginEbookUploadResponse))
          as BeginEbookUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BeginEbookUploadResponse create() => BeginEbookUploadResponse._();
  @$core.override
  BeginEbookUploadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BeginEbookUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BeginEbookUploadResponse>(create);
  static BeginEbookUploadResponse? _defaultInstance;

  /// Names the upload, and is sent with every chunk. It is empty when the node
  /// already holds the file, because then there is nothing to send.
  @$pb.TagNumber(1)
  $core.String get uploadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set uploadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUploadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadId() => $_clearField(1);

  /// True when this node already had the bytes and no transfer is needed. It is
  /// the same answer CreateEbook gives through content_missing, repeated here
  /// because the two calls may be minutes apart and another device of the same
  /// reader may have sent the file in between.
  @$pb.TagNumber(2)
  $core.bool get alreadyHeld => $_getBF(1);
  @$pb.TagNumber(2)
  set alreadyHeld($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlreadyHeld() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlreadyHeld() => $_clearField(2);

  /// The file as this node holds it, populated only when already_held is true.
  @$pb.TagNumber(3)
  EbookContent get content => $_getN(2);
  @$pb.TagNumber(3)
  set content(EbookContent value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);
  @$pb.TagNumber(3)
  EbookContent ensureContent() => $_ensure(2);
}

class PutEbookChunkRequest extends $pb.GeneratedMessage {
  factory PutEbookChunkRequest({
    $core.String? uploadId,
    $fixnum.Int64? offset,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (uploadId != null) result.uploadId = uploadId;
    if (offset != null) result.offset = offset;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  PutEbookChunkRequest._();

  factory PutEbookChunkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PutEbookChunkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutEbookChunkRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uploadId')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutEbookChunkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutEbookChunkRequest copyWith(void Function(PutEbookChunkRequest) updates) =>
      super.copyWith((message) => updates(message as PutEbookChunkRequest))
          as PutEbookChunkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PutEbookChunkRequest create() => PutEbookChunkRequest._();
  @$core.override
  PutEbookChunkRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PutEbookChunkRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutEbookChunkRequest>(create);
  static PutEbookChunkRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uploadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set uploadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUploadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadId() => $_clearField(1);

  /// Where these bytes belong, counted from the first byte of the file. It is
  /// sent rather than assumed so that a caller which lost a reply can repeat a
  /// chunk without the node appending it twice.
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get chunk => $_getN(2);
  @$pb.TagNumber(3)
  set chunk($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChunk() => $_has(2);
  @$pb.TagNumber(3)
  void clearChunk() => $_clearField(3);
}

class PutEbookChunkResponse extends $pb.GeneratedMessage {
  factory PutEbookChunkResponse({
    $fixnum.Int64? receivedBytes,
  }) {
    final result = create();
    if (receivedBytes != null) result.receivedBytes = receivedBytes;
    return result;
  }

  PutEbookChunkResponse._();

  factory PutEbookChunkResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PutEbookChunkResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutEbookChunkResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'receivedBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutEbookChunkResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutEbookChunkResponse copyWith(
          void Function(PutEbookChunkResponse) updates) =>
      super.copyWith((message) => updates(message as PutEbookChunkResponse))
          as PutEbookChunkResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PutEbookChunkResponse create() => PutEbookChunkResponse._();
  @$core.override
  PutEbookChunkResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PutEbookChunkResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutEbookChunkResponse>(create);
  static PutEbookChunkResponse? _defaultInstance;

  /// How many bytes the node now holds, and therefore the offset the next chunk
  /// must carry. A caller that finds it unchanged sent a chunk the node was not
  /// expecting, and this is where to continue from.
  @$pb.TagNumber(1)
  $fixnum.Int64 get receivedBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set receivedBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceivedBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceivedBytes() => $_clearField(1);
}

class FinishEbookUploadRequest extends $pb.GeneratedMessage {
  factory FinishEbookUploadRequest({
    $core.String? uploadId,
  }) {
    final result = create();
    if (uploadId != null) result.uploadId = uploadId;
    return result;
  }

  FinishEbookUploadRequest._();

  factory FinishEbookUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FinishEbookUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinishEbookUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uploadId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishEbookUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishEbookUploadRequest copyWith(
          void Function(FinishEbookUploadRequest) updates) =>
      super.copyWith((message) => updates(message as FinishEbookUploadRequest))
          as FinishEbookUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FinishEbookUploadRequest create() => FinishEbookUploadRequest._();
  @$core.override
  FinishEbookUploadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FinishEbookUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinishEbookUploadRequest>(create);
  static FinishEbookUploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uploadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set uploadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUploadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadId() => $_clearField(1);
}

class FinishEbookUploadResponse extends $pb.GeneratedMessage {
  factory FinishEbookUploadResponse({
    EbookContent? content,
    $core.bool? alreadyHeld,
  }) {
    final result = create();
    if (content != null) result.content = content;
    if (alreadyHeld != null) result.alreadyHeld = alreadyHeld;
    return result;
  }

  FinishEbookUploadResponse._();

  factory FinishEbookUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FinishEbookUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinishEbookUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<EbookContent>(1, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..aOB(2, _omitFieldNames ? '' : 'alreadyHeld')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishEbookUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishEbookUploadResponse copyWith(
          void Function(FinishEbookUploadResponse) updates) =>
      super.copyWith((message) => updates(message as FinishEbookUploadResponse))
          as FinishEbookUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FinishEbookUploadResponse create() => FinishEbookUploadResponse._();
  @$core.override
  FinishEbookUploadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FinishEbookUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinishEbookUploadResponse>(create);
  static FinishEbookUploadResponse? _defaultInstance;

  /// The file as this node now holds it.
  @$pb.TagNumber(1)
  EbookContent get content => $_getN(0);
  @$pb.TagNumber(1)
  set content(EbookContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
  @$pb.TagNumber(1)
  EbookContent ensureContent() => $_ensure(0);

  /// True when another upload of the same file finished while this one was
  /// arriving. The bytes are identical by construction, since the digest is the
  /// key, so it is the answer the caller wanted reached by somebody else.
  @$pb.TagNumber(2)
  $core.bool get alreadyHeld => $_getBF(1);
  @$pb.TagNumber(2)
  set alreadyHeld($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlreadyHeld() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlreadyHeld() => $_clearField(2);
}

class DiscardEbookUploadRequest extends $pb.GeneratedMessage {
  factory DiscardEbookUploadRequest({
    $core.String? uploadId,
  }) {
    final result = create();
    if (uploadId != null) result.uploadId = uploadId;
    return result;
  }

  DiscardEbookUploadRequest._();

  factory DiscardEbookUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscardEbookUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscardEbookUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uploadId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardEbookUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardEbookUploadRequest copyWith(
          void Function(DiscardEbookUploadRequest) updates) =>
      super.copyWith((message) => updates(message as DiscardEbookUploadRequest))
          as DiscardEbookUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscardEbookUploadRequest create() => DiscardEbookUploadRequest._();
  @$core.override
  DiscardEbookUploadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscardEbookUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscardEbookUploadRequest>(create);
  static DiscardEbookUploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uploadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set uploadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUploadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadId() => $_clearField(1);
}

class DiscardEbookUploadResponse extends $pb.GeneratedMessage {
  factory DiscardEbookUploadResponse() => create();

  DiscardEbookUploadResponse._();

  factory DiscardEbookUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscardEbookUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscardEbookUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardEbookUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardEbookUploadResponse copyWith(
          void Function(DiscardEbookUploadResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DiscardEbookUploadResponse))
          as DiscardEbookUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscardEbookUploadResponse create() => DiscardEbookUploadResponse._();
  @$core.override
  DiscardEbookUploadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscardEbookUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscardEbookUploadResponse>(create);
  static DiscardEbookUploadResponse? _defaultInstance;
}

class DownloadEbookContentRequest extends $pb.GeneratedMessage {
  factory DownloadEbookContentRequest({
    $core.String? ebookId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    return result;
  }

  DownloadEbookContentRequest._();

  factory DownloadEbookContentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadEbookContentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadEbookContentRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadEbookContentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadEbookContentRequest copyWith(
          void Function(DownloadEbookContentRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DownloadEbookContentRequest))
          as DownloadEbookContentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadEbookContentRequest create() =>
      DownloadEbookContentRequest._();
  @$core.override
  DownloadEbookContentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadEbookContentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadEbookContentRequest>(create);
  static DownloadEbookContentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);
}

enum DownloadEbookContentResponse_Payload { content, chunk, notSet }

class DownloadEbookContentResponse extends $pb.GeneratedMessage {
  factory DownloadEbookContentResponse({
    EbookContent? content,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (content != null) result.content = content;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  DownloadEbookContentResponse._();

  factory DownloadEbookContentResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadEbookContentResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DownloadEbookContentResponse_Payload>
      _DownloadEbookContentResponse_PayloadByTag = {
    1: DownloadEbookContentResponse_Payload.content,
    2: DownloadEbookContentResponse_Payload.chunk,
    0: DownloadEbookContentResponse_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadEbookContentResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<EbookContent>(1, _omitFieldNames ? '' : 'content',
        subBuilder: EbookContent.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadEbookContentResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadEbookContentResponse copyWith(
          void Function(DownloadEbookContentResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DownloadEbookContentResponse))
          as DownloadEbookContentResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadEbookContentResponse create() =>
      DownloadEbookContentResponse._();
  @$core.override
  DownloadEbookContentResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadEbookContentResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadEbookContentResponse>(create);
  static DownloadEbookContentResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DownloadEbookContentResponse_Payload whichPayload() =>
      _DownloadEbookContentResponse_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  EbookContent get content => $_getN(0);
  @$pb.TagNumber(1)
  set content(EbookContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
  @$pb.TagNumber(1)
  EbookContent ensureContent() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
}

class CreateCollectionRequest extends $pb.GeneratedMessage {
  factory CreateCollectionRequest({
    Collection? collection,
  }) {
    final result = create();
    if (collection != null) result.collection = collection;
    return result;
  }

  CreateCollectionRequest._();

  factory CreateCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Collection>(1, _omitFieldNames ? '' : 'collection',
        subBuilder: Collection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCollectionRequest copyWith(
          void Function(CreateCollectionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateCollectionRequest))
          as CreateCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateCollectionRequest create() => CreateCollectionRequest._();
  @$core.override
  CreateCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateCollectionRequest>(create);
  static CreateCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Collection get collection => $_getN(0);
  @$pb.TagNumber(1)
  set collection(Collection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);
  @$pb.TagNumber(1)
  Collection ensureCollection() => $_ensure(0);
}

class CreateCollectionResponse extends $pb.GeneratedMessage {
  factory CreateCollectionResponse({
    Collection? collection,
  }) {
    final result = create();
    if (collection != null) result.collection = collection;
    return result;
  }

  CreateCollectionResponse._();

  factory CreateCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Collection>(1, _omitFieldNames ? '' : 'collection',
        subBuilder: Collection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCollectionResponse copyWith(
          void Function(CreateCollectionResponse) updates) =>
      super.copyWith((message) => updates(message as CreateCollectionResponse))
          as CreateCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateCollectionResponse create() => CreateCollectionResponse._();
  @$core.override
  CreateCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateCollectionResponse>(create);
  static CreateCollectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Collection get collection => $_getN(0);
  @$pb.TagNumber(1)
  set collection(Collection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);
  @$pb.TagNumber(1)
  Collection ensureCollection() => $_ensure(0);
}

class GetCollectionRequest extends $pb.GeneratedMessage {
  factory GetCollectionRequest({
    $core.String? collectionId,
  }) {
    final result = create();
    if (collectionId != null) result.collectionId = collectionId;
    return result;
  }

  GetCollectionRequest._();

  factory GetCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'collectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCollectionRequest copyWith(void Function(GetCollectionRequest) updates) =>
      super.copyWith((message) => updates(message as GetCollectionRequest))
          as GetCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetCollectionRequest create() => GetCollectionRequest._();
  @$core.override
  GetCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCollectionRequest>(create);
  static GetCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get collectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set collectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCollectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollectionId() => $_clearField(1);
}

class GetCollectionResponse extends $pb.GeneratedMessage {
  factory GetCollectionResponse({
    Collection? collection,
  }) {
    final result = create();
    if (collection != null) result.collection = collection;
    return result;
  }

  GetCollectionResponse._();

  factory GetCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Collection>(1, _omitFieldNames ? '' : 'collection',
        subBuilder: Collection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCollectionResponse copyWith(
          void Function(GetCollectionResponse) updates) =>
      super.copyWith((message) => updates(message as GetCollectionResponse))
          as GetCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetCollectionResponse create() => GetCollectionResponse._();
  @$core.override
  GetCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCollectionResponse>(create);
  static GetCollectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Collection get collection => $_getN(0);
  @$pb.TagNumber(1)
  set collection(Collection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);
  @$pb.TagNumber(1)
  Collection ensureCollection() => $_ensure(0);
}

class ListCollectionsRequest extends $pb.GeneratedMessage {
  factory ListCollectionsRequest({
    $core.String? ebookId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    return result;
  }

  ListCollectionsRequest._();

  factory ListCollectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListCollectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCollectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCollectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCollectionsRequest copyWith(
          void Function(ListCollectionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListCollectionsRequest))
          as ListCollectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListCollectionsRequest create() => ListCollectionsRequest._();
  @$core.override
  ListCollectionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListCollectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCollectionsRequest>(create);
  static ListCollectionsRequest? _defaultInstance;

  /// Narrows the reply to the groupings one work is filed under, which is the
  /// reverse of the filter ListEbooks offers.
  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);
}

/// Not paginated, unlike the works themselves: a reader defines shelves by hand
/// and there are as many of them as they had patience for.
class ListCollectionsResponse extends $pb.GeneratedMessage {
  factory ListCollectionsResponse({
    $core.Iterable<Collection>? collections,
  }) {
    final result = create();
    if (collections != null) result.collections.addAll(collections);
    return result;
  }

  ListCollectionsResponse._();

  factory ListCollectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListCollectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCollectionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Collection>(1, _omitFieldNames ? '' : 'collections',
        subBuilder: Collection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCollectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCollectionsResponse copyWith(
          void Function(ListCollectionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListCollectionsResponse))
          as ListCollectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListCollectionsResponse create() => ListCollectionsResponse._();
  @$core.override
  ListCollectionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListCollectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCollectionsResponse>(create);
  static ListCollectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Collection> get collections => $_getList(0);
}

class UpdateCollectionRequest extends $pb.GeneratedMessage {
  factory UpdateCollectionRequest({
    $core.String? collectionId,
    Collection? collection,
    $4.FieldMask? updateMask,
  }) {
    final result = create();
    if (collectionId != null) result.collectionId = collectionId;
    if (collection != null) result.collection = collection;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateCollectionRequest._();

  factory UpdateCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'collectionId')
    ..aOM<Collection>(2, _omitFieldNames ? '' : 'collection',
        subBuilder: Collection.create)
    ..aOM<$4.FieldMask>(3, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $4.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCollectionRequest copyWith(
          void Function(UpdateCollectionRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateCollectionRequest))
          as UpdateCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateCollectionRequest create() => UpdateCollectionRequest._();
  @$core.override
  UpdateCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCollectionRequest>(create);
  static UpdateCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get collectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set collectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCollectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  Collection get collection => $_getN(1);
  @$pb.TagNumber(2)
  set collection(Collection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCollection() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollection() => $_clearField(2);
  @$pb.TagNumber(2)
  Collection ensureCollection() => $_ensure(1);

  @$pb.TagNumber(3)
  $4.FieldMask get updateMask => $_getN(2);
  @$pb.TagNumber(3)
  set updateMask($4.FieldMask value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdateMask() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateMask() => $_clearField(3);
  @$pb.TagNumber(3)
  $4.FieldMask ensureUpdateMask() => $_ensure(2);
}

class UpdateCollectionResponse extends $pb.GeneratedMessage {
  factory UpdateCollectionResponse({
    Collection? collection,
  }) {
    final result = create();
    if (collection != null) result.collection = collection;
    return result;
  }

  UpdateCollectionResponse._();

  factory UpdateCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<Collection>(1, _omitFieldNames ? '' : 'collection',
        subBuilder: Collection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCollectionResponse copyWith(
          void Function(UpdateCollectionResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateCollectionResponse))
          as UpdateCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateCollectionResponse create() => UpdateCollectionResponse._();
  @$core.override
  UpdateCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCollectionResponse>(create);
  static UpdateCollectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Collection get collection => $_getN(0);
  @$pb.TagNumber(1)
  set collection(Collection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);
  @$pb.TagNumber(1)
  Collection ensureCollection() => $_ensure(0);
}

class DeleteCollectionRequest extends $pb.GeneratedMessage {
  factory DeleteCollectionRequest({
    $core.String? collectionId,
  }) {
    final result = create();
    if (collectionId != null) result.collectionId = collectionId;
    return result;
  }

  DeleteCollectionRequest._();

  factory DeleteCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'collectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCollectionRequest copyWith(
          void Function(DeleteCollectionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteCollectionRequest))
          as DeleteCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteCollectionRequest create() => DeleteCollectionRequest._();
  @$core.override
  DeleteCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteCollectionRequest>(create);
  static DeleteCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get collectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set collectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCollectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollectionId() => $_clearField(1);
}

/// The works survive the grouping. Deleting a shelf is not deleting what was on
/// it, and the memberships are tombstoned with it.
class DeleteCollectionResponse extends $pb.GeneratedMessage {
  factory DeleteCollectionResponse() => create();

  DeleteCollectionResponse._();

  factory DeleteCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCollectionResponse copyWith(
          void Function(DeleteCollectionResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteCollectionResponse))
          as DeleteCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteCollectionResponse create() => DeleteCollectionResponse._();
  @$core.override
  DeleteCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteCollectionResponse>(create);
  static DeleteCollectionResponse? _defaultInstance;
}

class AddEbookToCollectionRequest extends $pb.GeneratedMessage {
  factory AddEbookToCollectionRequest({
    $core.String? ebookId,
    $core.String? collectionId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (collectionId != null) result.collectionId = collectionId;
    return result;
  }

  AddEbookToCollectionRequest._();

  factory AddEbookToCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddEbookToCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddEbookToCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aOS(2, _omitFieldNames ? '' : 'collectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddEbookToCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddEbookToCollectionRequest copyWith(
          void Function(AddEbookToCollectionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AddEbookToCollectionRequest))
          as AddEbookToCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddEbookToCollectionRequest create() =>
      AddEbookToCollectionRequest._();
  @$core.override
  AddEbookToCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddEbookToCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddEbookToCollectionRequest>(create);
  static AddEbookToCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get collectionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set collectionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCollectionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollectionId() => $_clearField(2);
}

class AddEbookToCollectionResponse extends $pb.GeneratedMessage {
  factory AddEbookToCollectionResponse() => create();

  AddEbookToCollectionResponse._();

  factory AddEbookToCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddEbookToCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddEbookToCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddEbookToCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddEbookToCollectionResponse copyWith(
          void Function(AddEbookToCollectionResponse) updates) =>
      super.copyWith(
              (message) => updates(message as AddEbookToCollectionResponse))
          as AddEbookToCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddEbookToCollectionResponse create() =>
      AddEbookToCollectionResponse._();
  @$core.override
  AddEbookToCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddEbookToCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddEbookToCollectionResponse>(create);
  static AddEbookToCollectionResponse? _defaultInstance;
}

class RemoveEbookFromCollectionRequest extends $pb.GeneratedMessage {
  factory RemoveEbookFromCollectionRequest({
    $core.String? ebookId,
    $core.String? collectionId,
  }) {
    final result = create();
    if (ebookId != null) result.ebookId = ebookId;
    if (collectionId != null) result.collectionId = collectionId;
    return result;
  }

  RemoveEbookFromCollectionRequest._();

  factory RemoveEbookFromCollectionRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveEbookFromCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveEbookFromCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ebookId')
    ..aOS(2, _omitFieldNames ? '' : 'collectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveEbookFromCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveEbookFromCollectionRequest copyWith(
          void Function(RemoveEbookFromCollectionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RemoveEbookFromCollectionRequest))
          as RemoveEbookFromCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveEbookFromCollectionRequest create() =>
      RemoveEbookFromCollectionRequest._();
  @$core.override
  RemoveEbookFromCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveEbookFromCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveEbookFromCollectionRequest>(
          create);
  static RemoveEbookFromCollectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ebookId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ebookId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEbookId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEbookId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get collectionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set collectionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCollectionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollectionId() => $_clearField(2);
}

class RemoveEbookFromCollectionResponse extends $pb.GeneratedMessage {
  factory RemoveEbookFromCollectionResponse() => create();

  RemoveEbookFromCollectionResponse._();

  factory RemoveEbookFromCollectionResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveEbookFromCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveEbookFromCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveEbookFromCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveEbookFromCollectionResponse copyWith(
          void Function(RemoveEbookFromCollectionResponse) updates) =>
      super.copyWith((message) =>
              updates(message as RemoveEbookFromCollectionResponse))
          as RemoveEbookFromCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveEbookFromCollectionResponse create() =>
      RemoveEbookFromCollectionResponse._();
  @$core.override
  RemoveEbookFromCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveEbookFromCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveEbookFromCollectionResponse>(
          create);
  static RemoveEbookFromCollectionResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

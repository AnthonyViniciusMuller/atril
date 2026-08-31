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

import 'package:protobuf/protobuf.dart' as $pb;

/// The formats UC02 admits, as listed in subsection 4.2.2.
///
/// Adding a value here is not a breaking change: an older node receiving one it
/// does not know keeps the number and can still store, replicate and return the
/// work — it simply cannot name the format to its own reader.
class EbookFormat extends $pb.ProtobufEnum {
  static const EbookFormat EBOOK_FORMAT_UNSPECIFIED =
      EbookFormat._(0, _omitEnumNames ? '' : 'EBOOK_FORMAT_UNSPECIFIED');
  static const EbookFormat EBOOK_FORMAT_EPUB =
      EbookFormat._(1, _omitEnumNames ? '' : 'EBOOK_FORMAT_EPUB');
  static const EbookFormat EBOOK_FORMAT_PDF =
      EbookFormat._(2, _omitEnumNames ? '' : 'EBOOK_FORMAT_PDF');
  static const EbookFormat EBOOK_FORMAT_MOBI =
      EbookFormat._(3, _omitEnumNames ? '' : 'EBOOK_FORMAT_MOBI');
  static const EbookFormat EBOOK_FORMAT_DJVU =
      EbookFormat._(4, _omitEnumNames ? '' : 'EBOOK_FORMAT_DJVU');
  static const EbookFormat EBOOK_FORMAT_CBZ =
      EbookFormat._(5, _omitEnumNames ? '' : 'EBOOK_FORMAT_CBZ');

  static const $core.List<EbookFormat> values = <EbookFormat>[
    EBOOK_FORMAT_UNSPECIFIED,
    EBOOK_FORMAT_EPUB,
    EBOOK_FORMAT_PDF,
    EBOOK_FORMAT_MOBI,
    EBOOK_FORMAT_DJVU,
    EBOOK_FORMAT_CBZ,
  ];

  static final $core.List<EbookFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static EbookFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EbookFormat._(super.value, super.name);
}

/// Collections and categories are the same structure with a different meaning,
/// which is what lets RF05 offer both without a second entity.
class CollectionKind extends $pb.ProtobufEnum {
  static const CollectionKind COLLECTION_KIND_UNSPECIFIED =
      CollectionKind._(0, _omitEnumNames ? '' : 'COLLECTION_KIND_UNSPECIFIED');
  static const CollectionKind COLLECTION_KIND_COLLECTION =
      CollectionKind._(1, _omitEnumNames ? '' : 'COLLECTION_KIND_COLLECTION');
  static const CollectionKind COLLECTION_KIND_CATEGORY =
      CollectionKind._(2, _omitEnumNames ? '' : 'COLLECTION_KIND_CATEGORY');

  static const $core.List<CollectionKind> values = <CollectionKind>[
    COLLECTION_KIND_UNSPECIFIED,
    COLLECTION_KIND_COLLECTION,
    COLLECTION_KIND_CATEGORY,
  ];

  static final $core.List<CollectionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CollectionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CollectionKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

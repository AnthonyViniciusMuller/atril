// This is a generated file - do not edit.
//
// Generated from quire/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// VectorClock records, per device, how many events of that device a replica
/// has observed. Comparing two of them tells whether one write causally
/// precedes the other or whether the two are genuinely concurrent, which is the
/// only case a tie-break is needed for (RN02, RNF03).
///
/// The Go side of this is internal/shared/crdt.VectorClock, whose merge is a
/// pointwise maximum — a join semilattice, proved by property test in that
/// package.
class VectorClock extends $pb.GeneratedMessage {
  factory VectorClock({
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addEntries(entries);
    return result;
  }

  VectorClock._();

  factory VectorClock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VectorClock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VectorClock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..m<$core.String, $fixnum.Int64>(1, _omitFieldNames ? '' : 'entries',
        entryClassName: 'VectorClock.EntriesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OU6,
        packageName: const $pb.PackageName('quire.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VectorClock clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VectorClock copyWith(void Function(VectorClock) updates) =>
      super.copyWith((message) => updates(message as VectorClock))
          as VectorClock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VectorClock create() => VectorClock._();
  @$core.override
  VectorClock createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VectorClock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VectorClock>(create);
  static VectorClock? _defaultInstance;

  /// Keyed by device id, valued by the number of that device's events observed.
  ///
  /// A device absent from the map and a device mapped to zero mean the same
  /// thing: no event of that device has been observed. Senders drop the zero
  /// entries, and a receiver must treat the two forms as equal, or the same
  /// causal history would compare unequal depending on how it was built.
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $fixnum.Int64> get entries => $_getMap(0);
}

/// HybridTimestamp is the instant a write was stamped with, on the clock
/// described by C01 in docs/tcc-corrections.md.
///
/// It is deliberately not a google.protobuf.Timestamp. The value is not a wall
/// clock: every write stamps
///
///   t = max(local wall clock, greatest t this replica has observed + 1µs)
///
/// which is what makes a causally later write carry a later timestamp even when
/// the authoring device's clock runs behind. Without that, the last-writer-wins
/// tie-break has a cycle and merge stops being associative, so two nodes that
/// saw the same writes in different orders converge on different values. A
/// distinct message is what stops anything from comparing it against a real
/// clock by accident, or from rendering it to a reader as the time of day.
///
/// Instants that *are* wall clocks — when a row was created, when a credential
/// expires — use google.protobuf.Timestamp, and the contrast is the point.
class HybridTimestamp extends $pb.GeneratedMessage {
  factory HybridTimestamp({
    $fixnum.Int64? unixMicros,
  }) {
    final result = create();
    if (unixMicros != null) result.unixMicros = unixMicros;
    return result;
  }

  HybridTimestamp._();

  factory HybridTimestamp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HybridTimestamp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HybridTimestamp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'unixMicros')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HybridTimestamp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HybridTimestamp copyWith(void Function(HybridTimestamp) updates) =>
      super.copyWith((message) => updates(message as HybridTimestamp))
          as HybridTimestamp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HybridTimestamp create() => HybridTimestamp._();
  @$core.override
  HybridTimestamp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HybridTimestamp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HybridTimestamp>(create);
  static HybridTimestamp? _defaultInstance;

  /// Microseconds since the Unix epoch. The resolution matches the timestamptz
  /// column the value is stored in, which is also what the "+1µs" above steps
  /// by: a coarser unit on the wire would collapse two writes the database can
  /// still tell apart.
  @$pb.TagNumber(1)
  $fixnum.Int64 get unixMicros => $_getI64(0);
  @$pb.TagNumber(1)
  set unixMicros($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnixMicros() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnixMicros() => $_clearField(1);
}

/// Revision is the replication metadata every replicable record carries: the
/// e-book, the collection, the membership of one in the other, and the
/// annotation. It is the same four fields on all of them, which is what lets one
/// reconciler serve every entity.
///
/// Reading progress is the exception, and C05 explains why: a progress row has
/// exactly one writer, so its versions can never be concurrent and it carries
/// the clock and the timestamp without the two fields that break a tie.
class Revision extends $pb.GeneratedMessage {
  factory Revision({
    VectorClock? vectorClock,
    HybridTimestamp? updatedAt,
    $core.String? deviceId,
    $core.bool? deleted,
  }) {
    final result = create();
    if (vectorClock != null) result.vectorClock = vectorClock;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (deviceId != null) result.deviceId = deviceId;
    if (deleted != null) result.deleted = deleted;
    return result;
  }

  Revision._();

  factory Revision.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Revision.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Revision',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOM<VectorClock>(1, _omitFieldNames ? '' : 'vectorClock',
        subBuilder: VectorClock.create)
    ..aOM<HybridTimestamp>(2, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: HybridTimestamp.create)
    ..aOS(3, _omitFieldNames ? '' : 'deviceId')
    ..aOB(4, _omitFieldNames ? '' : 'deleted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Revision clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Revision copyWith(void Function(Revision) updates) =>
      super.copyWith((message) => updates(message as Revision)) as Revision;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Revision create() => Revision._();
  @$core.override
  Revision createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Revision getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Revision>(create);
  static Revision? _defaultInstance;

  /// The causal version of the record. The reconciler consults this first, and
  /// consults nothing else unless it reports the two versions concurrent.
  @$pb.TagNumber(1)
  VectorClock get vectorClock => $_getN(0);
  @$pb.TagNumber(1)
  set vectorClock(VectorClock value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVectorClock() => $_has(0);
  @$pb.TagNumber(1)
  void clearVectorClock() => $_clearField(1);
  @$pb.TagNumber(1)
  VectorClock ensureVectorClock() => $_ensure(0);

  /// The first half of the tie-break for the concurrent case.
  @$pb.TagNumber(2)
  HybridTimestamp get updatedAt => $_getN(1);
  @$pb.TagNumber(2)
  set updatedAt(HybridTimestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdatedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdatedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  HybridTimestamp ensureUpdatedAt() => $_ensure(1);

  /// The second half, and the reason the pair is a total order: two devices that
  /// have never heard of each other can still land on the same timestamp, and
  /// any fixed rule settles them provided every node applies the same one.
  ///
  /// It is the device whose write the record currently reflects, never the one
  /// that created it. Appendix A of the TCC describes it the other way round on
  /// anotacao, and after an edit from a second device the two are different
  /// devices — see C10.
  @$pb.TagNumber(3)
  $core.String get deviceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceId() => $_clearField(3);

  /// The tombstone. A record removed outright is resurrected by the next node
  /// that had not yet heard about the deletion, so deletion is a write like any
  /// other and reconciles like one.
  @$pb.TagNumber(4)
  $core.bool get deleted => $_getBF(3);
  @$pb.TagNumber(4)
  set deleted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeleted() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleted() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

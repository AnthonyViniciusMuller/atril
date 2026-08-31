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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as $1;

import 'common.pb.dart' as $2;
import 'sync.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'sync.pbenum.dart';

/// One change to one record, as it travels between nodes.
class Operation extends $pb.GeneratedMessage {
  factory Operation({
    $core.String? id,
    $core.String? deviceId,
    TargetEntity? targetEntity,
    $core.String? targetId,
    OperationKind? operation,
    $1.Struct? delta,
    $2.VectorClock? vectorClock,
    $2.HybridTimestamp? createdAt,
    $fixnum.Int64? position,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (deviceId != null) result.deviceId = deviceId;
    if (targetEntity != null) result.targetEntity = targetEntity;
    if (targetId != null) result.targetId = targetId;
    if (operation != null) result.operation = operation;
    if (delta != null) result.delta = delta;
    if (vectorClock != null) result.vectorClock = vectorClock;
    if (createdAt != null) result.createdAt = createdAt;
    if (position != null) result.position = position;
    return result;
  }

  Operation._();

  factory Operation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Operation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Operation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aE<TargetEntity>(3, _omitFieldNames ? '' : 'targetEntity',
        enumValues: TargetEntity.values)
    ..aOS(4, _omitFieldNames ? '' : 'targetId')
    ..aE<OperationKind>(5, _omitFieldNames ? '' : 'operation',
        enumValues: OperationKind.values)
    ..aOM<$1.Struct>(6, _omitFieldNames ? '' : 'delta',
        subBuilder: $1.Struct.create)
    ..aOM<$2.VectorClock>(7, _omitFieldNames ? '' : 'vectorClock',
        subBuilder: $2.VectorClock.create)
    ..aOM<$2.HybridTimestamp>(8, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.HybridTimestamp.create)
    ..aInt64(9, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Operation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Operation copyWith(void Function(Operation) updates) =>
      super.copyWith((message) => updates(message as Operation)) as Operation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Operation create() => Operation._();
  @$core.override
  Operation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Operation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Operation>(create);
  static Operation? _defaultInstance;

  /// Minted by the authoring device, and identical on every node that ever sees
  /// it. A node never generates one of its own on receipt.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The device that authored the change. RN10 requires it to be the device
  /// making the call, which is what stops one device from writing under
  /// another's clock entry.
  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  TargetEntity get targetEntity => $_getN(2);
  @$pb.TagNumber(3)
  set targetEntity(TargetEntity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetEntity() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetEntity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get targetId => $_getSZ(3);
  @$pb.TagNumber(4)
  set targetId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTargetId() => $_has(3);
  @$pb.TagNumber(4)
  void clearTargetId() => $_clearField(4);

  @$pb.TagNumber(5)
  OperationKind get operation => $_getN(4);
  @$pb.TagNumber(5)
  set operation(OperationKind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOperation() => $_has(4);
  @$pb.TagNumber(5)
  void clearOperation() => $_clearField(5);

  /// The changed fields and nothing else (RN06). An object, never a whole
  /// record: reconciliation is per-field, so a delta naming two fields claims
  /// those two and leaves the rest to whichever device wrote them last.
  @$pb.TagNumber(6)
  $1.Struct get delta => $_getN(5);
  @$pb.TagNumber(6)
  set delta($1.Struct value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDelta() => $_has(5);
  @$pb.TagNumber(6)
  void clearDelta() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Struct ensureDelta() => $_ensure(5);

  /// The causal version the change was authored at, which is what the reconciler
  /// consults before anything else (RN02).
  @$pb.TagNumber(7)
  $2.VectorClock get vectorClock => $_getN(6);
  @$pb.TagNumber(7)
  set vectorClock($2.VectorClock value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasVectorClock() => $_has(6);
  @$pb.TagNumber(7)
  void clearVectorClock() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.VectorClock ensureVectorClock() => $_ensure(6);

  /// Stamped by the authoring device on the clock C01 describes, and the reason
  /// that clock has to be hybrid rather than a wall clock: it is the tie-break
  /// for the concurrent case, and a wall clock makes that relation cyclic.
  @$pb.TagNumber(8)
  $2.HybridTimestamp get createdAt => $_getN(7);
  @$pb.TagNumber(8)
  set createdAt($2.HybridTimestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $2.HybridTimestamp ensureCreatedAt() => $_ensure(7);

  /// This node's order for this reader's log, assigned when the operation was
  /// stored here. It is meaningless in a request and ignored if set: the sender
  /// cannot know a number the receiver has not allocated yet.
  @$pb.TagNumber(9)
  $fixnum.Int64 get position => $_getI64(8);
  @$pb.TagNumber(9)
  set position($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPosition() => $_has(8);
  @$pb.TagNumber(9)
  void clearPosition() => $_clearField(9);
}

/// The verdict on one operation.
class OperationResult extends $pb.GeneratedMessage {
  factory OperationResult({
    $core.String? operationId,
    OperationOutcome? outcome,
    $core.String? detail,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    if (outcome != null) result.outcome = outcome;
    if (detail != null) result.detail = detail;
    return result;
  }

  OperationResult._();

  factory OperationResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..aE<OperationOutcome>(2, _omitFieldNames ? '' : 'outcome',
        enumValues: OperationOutcome.values)
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResult copyWith(void Function(OperationResult) updates) =>
      super.copyWith((message) => updates(message as OperationResult))
          as OperationResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationResult create() => OperationResult._();
  @$core.override
  OperationResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationResult>(create);
  static OperationResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  @$pb.TagNumber(2)
  OperationOutcome get outcome => $_getN(1);
  @$pb.TagNumber(2)
  set outcome(OperationOutcome value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOutcome() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField(2);

  /// Populated for a rejection, and for the operator rather than the reader.
  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);
}

/// A group of operations travelling together. It is a message rather than a
/// bare repeated field because the sync stream carries it in both directions.
class OperationBatch extends $pb.GeneratedMessage {
  factory OperationBatch({
    $core.Iterable<Operation>? operations,
  }) {
    final result = create();
    if (operations != null) result.operations.addAll(operations);
    return result;
  }

  OperationBatch._();

  factory OperationBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Operation>(1, _omitFieldNames ? '' : 'operations',
        subBuilder: Operation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationBatch copyWith(void Function(OperationBatch) updates) =>
      super.copyWith((message) => updates(message as OperationBatch))
          as OperationBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationBatch create() => OperationBatch._();
  @$core.override
  OperationBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationBatch>(create);
  static OperationBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Operation> get operations => $_getList(0);
}

class PushOperationsRequest extends $pb.GeneratedMessage {
  factory PushOperationsRequest({
    $core.Iterable<Operation>? operations,
  }) {
    final result = create();
    if (operations != null) result.operations.addAll(operations);
    return result;
  }

  PushOperationsRequest._();

  factory PushOperationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushOperationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushOperationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Operation>(1, _omitFieldNames ? '' : 'operations',
        subBuilder: Operation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushOperationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushOperationsRequest copyWith(
          void Function(PushOperationsRequest) updates) =>
      super.copyWith((message) => updates(message as PushOperationsRequest))
          as PushOperationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushOperationsRequest create() => PushOperationsRequest._();
  @$core.override
  PushOperationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PushOperationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushOperationsRequest>(create);
  static PushOperationsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Operation> get operations => $_getList(0);
}

class PushOperationsResponse extends $pb.GeneratedMessage {
  factory PushOperationsResponse({
    $core.Iterable<OperationResult>? results,
    $fixnum.Int64? lastPosition,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
    if (lastPosition != null) result.lastPosition = lastPosition;
    return result;
  }

  PushOperationsResponse._();

  factory PushOperationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushOperationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushOperationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<OperationResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: OperationResult.create)
    ..aInt64(2, _omitFieldNames ? '' : 'lastPosition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushOperationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushOperationsResponse copyWith(
          void Function(PushOperationsResponse) updates) =>
      super.copyWith((message) => updates(message as PushOperationsResponse))
          as PushOperationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushOperationsResponse create() => PushOperationsResponse._();
  @$core.override
  PushOperationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PushOperationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushOperationsResponse>(create);
  static PushOperationsResponse? _defaultInstance;

  /// One result per operation offered, in the order they were offered.
  @$pb.TagNumber(1)
  $pb.PbList<OperationResult> get results => $_getList(0);

  /// This node's head position for the reader after the push. A device that has
  /// just pushed learns from it whether there is anything to pull, without
  /// asking.
  @$pb.TagNumber(2)
  $fixnum.Int64 get lastPosition => $_getI64(1);
  @$pb.TagNumber(2)
  set lastPosition($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastPosition() => $_clearField(2);
}

class PullOperationsRequest extends $pb.GeneratedMessage {
  factory PullOperationsRequest({
    $fixnum.Int64? afterPosition,
    $core.int? limit,
  }) {
    final result = create();
    if (afterPosition != null) result.afterPosition = afterPosition;
    if (limit != null) result.limit = limit;
    return result;
  }

  PullOperationsRequest._();

  factory PullOperationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PullOperationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullOperationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'afterPosition')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullOperationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullOperationsRequest copyWith(
          void Function(PullOperationsRequest) updates) =>
      super.copyWith((message) => updates(message as PullOperationsRequest))
          as PullOperationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullOperationsRequest create() => PullOperationsRequest._();
  @$core.override
  PullOperationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PullOperationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PullOperationsRequest>(create);
  static PullOperationsRequest? _defaultInstance;

  /// Everything strictly after this position, in order. Zero means from the
  /// beginning, which is what a device that has just been bound asks for.
  ///
  /// The position is this node's. A device that also pulls from a replica keeps
  /// that node's cursor separately, and the two numbers have nothing to do with
  /// each other.
  @$pb.TagNumber(1)
  $fixnum.Int64 get afterPosition => $_getI64(0);
  @$pb.TagNumber(1)
  set afterPosition($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterPosition() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterPosition() => $_clearField(1);

  /// Zero asks the server to choose.
  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class PullOperationsResponse extends $pb.GeneratedMessage {
  factory PullOperationsResponse({
    $core.Iterable<Operation>? operations,
    $fixnum.Int64? lastPosition,
    $core.bool? hasMore,
  }) {
    final result = create();
    if (operations != null) result.operations.addAll(operations);
    if (lastPosition != null) result.lastPosition = lastPosition;
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  PullOperationsResponse._();

  factory PullOperationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PullOperationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullOperationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<Operation>(1, _omitFieldNames ? '' : 'operations',
        subBuilder: Operation.create)
    ..aInt64(2, _omitFieldNames ? '' : 'lastPosition')
    ..aOB(3, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullOperationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullOperationsResponse copyWith(
          void Function(PullOperationsResponse) updates) =>
      super.copyWith((message) => updates(message as PullOperationsResponse))
          as PullOperationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullOperationsResponse create() => PullOperationsResponse._();
  @$core.override
  PullOperationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PullOperationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PullOperationsResponse>(create);
  static PullOperationsResponse? _defaultInstance;

  /// In ascending position order. A reader that has seen position N has
  /// necessarily seen every position below it — that is what allocating the
  /// number inside the writing transaction buys, and it is what lets the cursor
  /// be a single number rather than a set.
  @$pb.TagNumber(1)
  $pb.PbList<Operation> get operations => $_getList(0);

  /// The position of the last operation returned, and the cursor to send next
  /// time. It is not this node's head: with has_more true there is more behind
  /// it.
  @$pb.TagNumber(2)
  $fixnum.Int64 get lastPosition => $_getI64(1);
  @$pb.TagNumber(2)
  set lastPosition($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastPosition() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hasMore => $_getBF(2);
  @$pb.TagNumber(3)
  set hasMore($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasMore() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasMore() => $_clearField(3);
}

enum SyncRequest_Payload { start, push, ack, notSet }

class SyncRequest extends $pb.GeneratedMessage {
  factory SyncRequest({
    SyncStart? start,
    OperationBatch? push,
    SyncAck? ack,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (push != null) result.push = push;
    if (ack != null) result.ack = ack;
    return result;
  }

  SyncRequest._();

  factory SyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SyncRequest_Payload>
      _SyncRequest_PayloadByTag = {
    1: SyncRequest_Payload.start,
    2: SyncRequest_Payload.push,
    3: SyncRequest_Payload.ack,
    0: SyncRequest_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<SyncStart>(1, _omitFieldNames ? '' : 'start',
        subBuilder: SyncStart.create)
    ..aOM<OperationBatch>(2, _omitFieldNames ? '' : 'push',
        subBuilder: OperationBatch.create)
    ..aOM<SyncAck>(3, _omitFieldNames ? '' : 'ack', subBuilder: SyncAck.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest copyWith(void Function(SyncRequest) updates) =>
      super.copyWith((message) => updates(message as SyncRequest))
          as SyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncRequest create() => SyncRequest._();
  @$core.override
  SyncRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncRequest>(create);
  static SyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  SyncRequest_Payload whichPayload() =>
      _SyncRequest_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// Exactly once, as the first message of the stream. It carries the cursor,
  /// so the stream begins by draining what the device missed and then stays
  /// open for what happens next.
  @$pb.TagNumber(1)
  SyncStart get start => $_getN(0);
  @$pb.TagNumber(1)
  set start(SyncStart value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);
  @$pb.TagNumber(1)
  SyncStart ensureStart() => $_ensure(0);

  /// Changes the device authored, at any point after the start.
  @$pb.TagNumber(2)
  OperationBatch get push => $_getN(1);
  @$pb.TagNumber(2)
  set push(OperationBatch value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPush() => $_has(1);
  @$pb.TagNumber(2)
  void clearPush() => $_clearField(2);
  @$pb.TagNumber(2)
  OperationBatch ensurePush() => $_ensure(1);

  /// The device confirms it has durably stored everything up to a position.
  /// The node advances the device's cursor on this and not on what it sent:
  /// an operation written to a socket is not an operation written to disk, and
  /// a device that dies in between must come back to the same place.
  @$pb.TagNumber(3)
  SyncAck get ack => $_getN(2);
  @$pb.TagNumber(3)
  set ack(SyncAck value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAck() => $_has(2);
  @$pb.TagNumber(3)
  void clearAck() => $_clearField(3);
  @$pb.TagNumber(3)
  SyncAck ensureAck() => $_ensure(2);
}

enum SyncResponse_Payload { operations, pushResult, notSet }

class SyncResponse extends $pb.GeneratedMessage {
  factory SyncResponse({
    OperationBatch? operations,
    SyncPushResult? pushResult,
  }) {
    final result = create();
    if (operations != null) result.operations = operations;
    if (pushResult != null) result.pushResult = pushResult;
    return result;
  }

  SyncResponse._();

  factory SyncResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SyncResponse_Payload>
      _SyncResponse_PayloadByTag = {
    1: SyncResponse_Payload.operations,
    2: SyncResponse_Payload.pushResult,
    0: SyncResponse_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OperationBatch>(1, _omitFieldNames ? '' : 'operations',
        subBuilder: OperationBatch.create)
    ..aOM<SyncPushResult>(2, _omitFieldNames ? '' : 'pushResult',
        subBuilder: SyncPushResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResponse copyWith(void Function(SyncResponse) updates) =>
      super.copyWith((message) => updates(message as SyncResponse))
          as SyncResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncResponse create() => SyncResponse._();
  @$core.override
  SyncResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncResponse>(create);
  static SyncResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SyncResponse_Payload whichPayload() =>
      _SyncResponse_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// Changes the device has not seen, sent as they are found and as they
  /// arrive from elsewhere.
  @$pb.TagNumber(1)
  OperationBatch get operations => $_getN(0);
  @$pb.TagNumber(1)
  set operations(OperationBatch value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperations() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperations() => $_clearField(1);
  @$pb.TagNumber(1)
  OperationBatch ensureOperations() => $_ensure(0);

  /// The verdicts on a push, one result per operation offered.
  @$pb.TagNumber(2)
  SyncPushResult get pushResult => $_getN(1);
  @$pb.TagNumber(2)
  set pushResult(SyncPushResult value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPushResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearPushResult() => $_clearField(2);
  @$pb.TagNumber(2)
  SyncPushResult ensurePushResult() => $_ensure(1);
}

class SyncStart extends $pb.GeneratedMessage {
  factory SyncStart({
    $fixnum.Int64? afterPosition,
  }) {
    final result = create();
    if (afterPosition != null) result.afterPosition = afterPosition;
    return result;
  }

  SyncStart._();

  factory SyncStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'afterPosition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncStart copyWith(void Function(SyncStart) updates) =>
      super.copyWith((message) => updates(message as SyncStart)) as SyncStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncStart create() => SyncStart._();
  @$core.override
  SyncStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncStart>(create);
  static SyncStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get afterPosition => $_getI64(0);
  @$pb.TagNumber(1)
  set afterPosition($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterPosition() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterPosition() => $_clearField(1);
}

class SyncAck extends $pb.GeneratedMessage {
  factory SyncAck({
    $fixnum.Int64? position,
  }) {
    final result = create();
    if (position != null) result.position = position;
    return result;
  }

  SyncAck._();

  factory SyncAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncAck copyWith(void Function(SyncAck) updates) =>
      super.copyWith((message) => updates(message as SyncAck)) as SyncAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncAck create() => SyncAck._();
  @$core.override
  SyncAck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncAck>(create);
  static SyncAck? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get position => $_getI64(0);
  @$pb.TagNumber(1)
  set position($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPosition() => $_has(0);
  @$pb.TagNumber(1)
  void clearPosition() => $_clearField(1);
}

class SyncPushResult extends $pb.GeneratedMessage {
  factory SyncPushResult({
    $core.Iterable<OperationResult>? results,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
    return result;
  }

  SyncPushResult._();

  factory SyncPushResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncPushResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncPushResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<OperationResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: OperationResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncPushResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncPushResult copyWith(void Function(SyncPushResult) updates) =>
      super.copyWith((message) => updates(message as SyncPushResult))
          as SyncPushResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncPushResult create() => SyncPushResult._();
  @$core.override
  SyncPushResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncPushResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncPushResult>(create);
  static SyncPushResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OperationResult> get results => $_getList(0);
}

class WatchOperationsRequest extends $pb.GeneratedMessage {
  factory WatchOperationsRequest({
    $fixnum.Int64? afterPosition,
  }) {
    final result = create();
    if (afterPosition != null) result.afterPosition = afterPosition;
    return result;
  }

  WatchOperationsRequest._();

  factory WatchOperationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchOperationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchOperationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'afterPosition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchOperationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchOperationsRequest copyWith(
          void Function(WatchOperationsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchOperationsRequest))
          as WatchOperationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchOperationsRequest create() => WatchOperationsRequest._();
  @$core.override
  WatchOperationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchOperationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchOperationsRequest>(create);
  static WatchOperationsRequest? _defaultInstance;

  /// What the caller has already seen, so that the node can tell it about a
  /// backlog immediately rather than only about what happens next. Zero asks to
  /// be told about a log that is not empty, which is what a browser that has
  /// just been bound wants to hear.
  ///
  /// It is a starting point and not a subscription the caller can move. The node
  /// reports what it has told this stream about, and a caller that has fallen
  /// behind is not told twice — it pulls, and its own cursor is what says where
  /// it got to.
  @$pb.TagNumber(1)
  $fixnum.Int64 get afterPosition => $_getI64(0);
  @$pb.TagNumber(1)
  set afterPosition($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterPosition() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterPosition() => $_clearField(1);
}

class WatchOperationsResponse extends $pb.GeneratedMessage {
  factory WatchOperationsResponse({
    $fixnum.Int64? lastPosition,
  }) {
    final result = create();
    if (lastPosition != null) result.lastPosition = lastPosition;
    return result;
  }

  WatchOperationsResponse._();

  factory WatchOperationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchOperationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchOperationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'lastPosition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchOperationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchOperationsResponse copyWith(
          void Function(WatchOperationsResponse) updates) =>
      super.copyWith((message) => updates(message as WatchOperationsResponse))
          as WatchOperationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchOperationsResponse create() => WatchOperationsResponse._();
  @$core.override
  WatchOperationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchOperationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchOperationsResponse>(create);
  static WatchOperationsResponse? _defaultInstance;

  /// This node's head position for the reader: everything up to here exists, and
  /// the caller has seen up to wherever its own cursor is. The gap between the
  /// two is what to pull.
  ///
  /// It is the head and not a page boundary, because nothing is being delivered
  /// and there is no page — a caller pulls until PullOperations reports no more.
  @$pb.TagNumber(1)
  $fixnum.Int64 get lastPosition => $_getI64(0);
  @$pb.TagNumber(1)
  set lastPosition($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLastPosition() => $_has(0);
  @$pb.TagNumber(1)
  void clearLastPosition() => $_clearField(1);
}

class ReplicateOperationsRequest extends $pb.GeneratedMessage {
  factory ReplicateOperationsRequest({
    $core.String? userId,
    $core.Iterable<Operation>? operations,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (operations != null) result.operations.addAll(operations);
    return result;
  }

  ReplicateOperationsRequest._();

  factory ReplicateOperationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplicateOperationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplicateOperationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..pPM<Operation>(2, _omitFieldNames ? '' : 'operations',
        subBuilder: Operation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicateOperationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicateOperationsRequest copyWith(
          void Function(ReplicateOperationsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ReplicateOperationsRequest))
          as ReplicateOperationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplicateOperationsRequest create() => ReplicateOperationsRequest._();
  @$core.override
  ReplicateOperationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplicateOperationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplicateOperationsRequest>(create);
  static ReplicateOperationsRequest? _defaultInstance;

  /// The reader whose log these operations belong to. A device-facing call takes
  /// this from the session; a peer-facing one cannot, because the certificate
  /// identifies the calling node and not a reader.
  ///
  /// The node serves the call only if that reader has an active authorization
  /// for the calling node (RF16, UC15). Nothing else in this contract is refused
  /// on the reader's own instruction, and RN03 is why this one is.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Operation> get operations => $_getList(1);
}

class ReplicateOperationsResponse extends $pb.GeneratedMessage {
  factory ReplicateOperationsResponse({
    $core.Iterable<OperationResult>? results,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
    return result;
  }

  ReplicateOperationsResponse._();

  factory ReplicateOperationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplicateOperationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplicateOperationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'quire.v1'),
      createEmptyInstance: create)
    ..pPM<OperationResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: OperationResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicateOperationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplicateOperationsResponse copyWith(
          void Function(ReplicateOperationsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ReplicateOperationsResponse))
          as ReplicateOperationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplicateOperationsResponse create() =>
      ReplicateOperationsResponse._();
  @$core.override
  ReplicateOperationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplicateOperationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplicateOperationsResponse>(create);
  static ReplicateOperationsResponse? _defaultInstance;

  /// What the destination did with each operation. The origin marks its delivery
  /// rows applied from this, and anything not confirmed here is retried — which
  /// is safe precisely because receiving is idempotent by operation id.
  @$pb.TagNumber(1)
  $pb.PbList<OperationResult> get results => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

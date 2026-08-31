/// One change to one record, in both directions.
///
/// This is the only replicable thing this app serializes, and the reason is
/// the whole shape of the client: a change is authored locally, appended to
/// the log, and handed to the node as an operation. Nothing else about a work,
/// a grouping, a filing, a position or a mark is ever sent as a record.
///
/// The `position` field is deliberately not mapped in either direction. It is
/// one node's order for one reader's log, allocated when the operation was
/// stored there, so it is meaningless in a request and belongs to the cursor
/// rather than to the operation on the way back.
library;

import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart';

import '../../domain/models/operation.dart';
import '../services/api/generated/quire/v1/sync.pb.dart' as pb;
import 'mapping.dart';

/// The replicable entities, by the name the contract's enum spells them with.
const Map<String, TargetEntity> targetEntitiesByWireName =
    <String, TargetEntity>{
      'TARGET_ENTITY_EBOOK': TargetEntity.ebook,
      'TARGET_ENTITY_COLLECTION': TargetEntity.collection,
      'TARGET_ENTITY_EBOOK_COLLECTION': TargetEntity.ebookCollection,
      'TARGET_ENTITY_READING_PROGRESS': TargetEntity.readingProgress,
      'TARGET_ENTITY_ANNOTATION': TargetEntity.annotation,
    };

/// The contract's name for each entity, which is what a push has to send.
const Map<TargetEntity, pb.TargetEntity>
wireTargetEntities = <TargetEntity, pb.TargetEntity>{
  TargetEntity.ebook: pb.TargetEntity.TARGET_ENTITY_EBOOK,
  TargetEntity.collection: pb.TargetEntity.TARGET_ENTITY_COLLECTION,
  TargetEntity.ebookCollection: pb.TargetEntity.TARGET_ENTITY_EBOOK_COLLECTION,
  TargetEntity.readingProgress: pb.TargetEntity.TARGET_ENTITY_READING_PROGRESS,
  TargetEntity.annotation: pb.TargetEntity.TARGET_ENTITY_ANNOTATION,
};

/// The kinds of change, by the name the contract's enum spells them with.
const Map<String, OperationKind> operationKindsByWireName =
    <String, OperationKind>{
      'OPERATION_KIND_INSERT': OperationKind.insert,
      'OPERATION_KIND_UPDATE': OperationKind.update,
      'OPERATION_KIND_DELETE': OperationKind.delete,
    };

/// The contract's name for each kind.
const Map<OperationKind, pb.OperationKind> wireOperationKinds =
    <OperationKind, pb.OperationKind>{
      OperationKind.insert: pb.OperationKind.OPERATION_KIND_INSERT,
      OperationKind.update: pb.OperationKind.OPERATION_KIND_UPDATE,
      OperationKind.delete: pb.OperationKind.OPERATION_KIND_DELETE,
    };

/// The verdicts, by the name the contract's enum spells them with.
const Map<String, OperationOutcome> operationOutcomesByWireName =
    <String, OperationOutcome>{
      'OPERATION_OUTCOME_APPLIED': OperationOutcome.applied,
      'OPERATION_OUTCOME_DUPLICATE': OperationOutcome.duplicate,
      'OPERATION_OUTCOME_SUPERSEDED': OperationOutcome.superseded,
      'OPERATION_OUTCOME_REJECTED': OperationOutcome.rejected,
    };

/// One change, as it arrived.
///
/// An entity or a kind this build cannot name is refused rather than applied
/// with a guess. Refusing the operation and going on with the batch is what
/// surviving the federation learning a new kind of record looks like; applying
/// one whose target is unknown would be writing somewhere nobody named.
Operation operationOf(pb.Operation operation) {
  final entity = targetEntitiesByWireName[operation.targetEntity.name];

  if (entity == null) {
    throw malformed('target_entity', 'names a record this build cannot apply');
  }

  final kind = operationKindsByWireName[operation.operation.name];

  if (kind == null) {
    throw malformed('operation', 'names a change this build cannot apply');
  }

  final delta = operation.delta.toProto3Json();

  if (delta is! Map<String, Object?>) {
    throw malformed('delta', 'is not an object');
  }

  return Operation(
    id: operation.id.toLowerCase(),
    deviceId: operation.deviceId.toLowerCase(),
    entity: entity,
    targetId: operation.targetId.toLowerCase(),
    kind: kind,
    delta: delta,
    vectorClock: vectorClockOf(operation.vectorClock),
    createdAt: instantOf(operation.createdAt),
  );
}

/// The change, as a push sends it.
///
/// The delta is written through `Struct`, which is proto3's JSON object, so a
/// field the author left out stays out and a field it set to null arrives as
/// null. That difference is the whole of per-field reconciliation: an unnamed
/// field keeps whatever device wrote it last, and a field named as null is one
/// the reader cleared.
pb.Operation wireOperation(Operation operation) => pb.Operation(
  id: operation.id,
  deviceId: operation.deviceId,
  targetEntity: wireTargetEntities[operation.entity],
  targetId: operation.targetId,
  operation: wireOperationKinds[operation.kind],
  delta: Struct()..mergeFromProto3Json(operation.delta),
  vectorClock: wireVectorClock(operation.vectorClock),
  createdAt: wireInstant(operation.createdAt),
);

/// What a node did with one operation.
OperationResult operationResultOf(pb.OperationResult result) => OperationResult(
  operationId: result.operationId.toLowerCase(),
  outcome: operationOutcomesByWireName[result.outcome.name],
  detail: result.detail,
);

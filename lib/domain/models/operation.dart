/// One change to one record, as it is authored here and as it travels.
///
/// It is the port of
/// [`internal/sync/domain/operation`](../../../../quire/internal/sync/domain/operation),
/// reduced to what a device needs. Three properties of the node's own log hold
/// here for the same reasons:
///
/// **The identifier is minted by the authoring device** and is the same on
/// every node that ever sees the operation. A node receiving it twice — from
/// this device, and again from a peer that also replicates the reader —
/// recognizes it by that identifier, so receiving is idempotent and the
/// reconciler never has to compare payloads.
///
/// **The delta is the changed fields and nothing else** (RN06). A field the
/// delta does not name keeps whatever device wrote it last; a field named as
/// JSON null is a field the change *cleared*. That difference is the whole of
/// what per-field reconciliation rests on, and it is why the delta is a map to
/// nullable values rather than a map with the nulls dropped.
///
/// **The position is not here.** It is a node's own order for the reader's log,
/// assigned when the operation was stored there, and two nodes number the same
/// operations differently. What this device keeps is one cursor per node, in
/// `node_cursors`, and nothing about an operation itself.
library;

import '../crdt/revision.dart';
import '../crdt/vector_clock.dart';

/// Which kind of record a change addressed.
///
/// The names are logical rather than tabular, and they are the node's own: the
/// same spelling travels through the contract's `TargetEntity`, through
/// `sync.operations.target_entity`, and through the log table on this device. A
/// name that meant a table would have to be translated at every hop.
enum TargetEntity {
  /// A work in the reader's collection.
  ebook('ebook'),

  /// A grouping the reader defined.
  collection('collection'),

  /// The filing of a work under a grouping, which replicates on its own terms
  /// (C06) and is addressed by its pair rather than by its identifier (C18).
  ebookCollection('ebook_collection'),

  /// Where one device stopped in one work, which has exactly one writer (C05).
  readingProgress('reading_progress'),

  /// A mark the reader left.
  annotation('annotation');

  const TargetEntity(this.wireName);

  /// The name the contract, the node's column and this device's log all use.
  final String wireName;

  /// The entity [name] spells, or `null` for one this device cannot replicate.
  ///
  /// An unknown name is an answer and not a failure: it is what a node running
  /// a later version legitimately sends, and refusing that one operation while
  /// applying the rest of a batch is what surviving the federation learning a
  /// new kind of record looks like.
  static TargetEntity? parse(String name) {
    for (final entity in TargetEntity.values) {
      if (entity.wireName == name) {
        return entity;
      }
    }

    return null;
  }

  @override
  String toString() => wireName;
}

/// What the change did to the record it names.
///
/// Deletion is one of the three and not a separate mechanism: it sets the
/// tombstone, travels as a delta like any other write, and reconciles by the
/// same rule.
enum OperationKind {
  /// The record did not exist here before.
  insert('insert'),

  /// The record existed and some of its fields changed.
  update('update'),

  /// The record was tombstoned.
  delete('delete');

  const OperationKind(this.wireName);

  /// The name the contract and both schemas use.
  final String wireName;

  /// The kind [name] spells, or `null` for one this device cannot name.
  static OperationKind? parse(String name) {
    for (final kind in OperationKind.values) {
      if (kind.wireName == name) {
        return kind;
      }
    }

    return null;
  }

  @override
  String toString() => wireName;
}

/// One change to one record.
final class Operation {
  /// The change, as it was authored or as it arrived.
  const Operation({
    required this.id,
    required this.deviceId,
    required this.entity,
    required this.targetId,
    required this.kind,
    required this.delta,
    required this.vectorClock,
    required this.createdAt,
  });

  /// Minted by the authoring device, and the same on every replica that sees
  /// it.
  final String id;

  /// The device that authored the change, which RN10 requires to be the device
  /// making the call. It is what stops one device from writing under another's
  /// clock entry.
  final String deviceId;

  /// Which kind of record changed.
  final TargetEntity entity;

  /// The record, as the author names it.
  ///
  /// For three of the five entities it is the record's own identifier. For a
  /// filing and a reading position it is the row the *author* minted, and the
  /// record is resolved by the natural key in the delta instead (C18).
  final String targetId;

  /// What the change did.
  final OperationKind kind;

  /// The changed fields and nothing else. A key present with a null value is a
  /// field the change cleared.
  final Map<String, Object?> delta;

  /// The causal version the change was authored at.
  final VectorClock vectorClock;

  /// The instant it was stamped at, on the hybrid clock C01 describes.
  final DateTime createdAt;

  /// The replication metadata this change carries, for a record with more than
  /// one writer.
  ///
  /// The tombstone is the kind of change and not a field of the delta, which is
  /// what makes a deletion reconcile as the write it is.
  Revision get revision => Revision(
    vectorClock: vectorClock,
    updatedAt: createdAt,
    deviceId: deviceId,
    deleted: kind == OperationKind.delete,
  );

  /// The same, for the one record that has exactly one writer.
  ///
  /// The two fields it drops are the two that break a tie, and a row whose only
  /// writer is the device it names can never have one to break (C05).
  Version get version =>
      Version(vectorClock: vectorClock, updatedAt: createdAt);

  /// Whether the delta claims [field] at all.
  ///
  /// A field it does not claim is one this change did not write, and it keeps
  /// whatever device wrote it last.
  bool claims(String field) => delta.containsKey(field);

  @override
  String toString() =>
      'Operation($id, $kind $entity $targetId, by $deviceId, $vectorClock)';
}

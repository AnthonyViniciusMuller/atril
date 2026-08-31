/// How this device addresses a record it has touched.
///
/// Three of the five replicable entities are addressed by their own identifier:
/// a work, a grouping and a mark are created once, by one device, and what it
/// minted is what every replica calls them.
///
/// The other two are not, and C18 is the finding. A filing and a reading
/// position carry a surrogate identifier that *each replica mints for itself*,
/// so two devices filing the same work under the same shelf while offline
/// produce two identifiers for one record. What identifies those across the
/// federation is the natural key the schema makes unique — the pair — which the
/// delta carries and which the reconciler resolves them by.
///
/// This type is that distinction spelled once. A caller that wants the version
/// of a filing asks for it by its pair and cannot ask for it by an identifier,
/// which is what stops a device from minting a new name for the same record on
/// every write.
library;

import 'operation.dart';

/// The address of one record in this device's causal state.
final class RecordKey {
  const RecordKey._(this.entity, this.identity);

  /// A record addressed by its own identifier: a work, a grouping or a mark.
  factory RecordKey.record(TargetEntity entity, String id) {
    assert(
      entity != TargetEntity.ebookCollection &&
          entity != TargetEntity.readingProgress,
      'a filing and a position are addressed by their natural key (C18)',
    );

    return RecordKey._(entity, id.toLowerCase());
  }

  /// The filing of a work under a grouping, addressed by the pair (C06, C18).
  factory RecordKey.filing({
    required String ebookId,
    required String collectionId,
  }) => RecordKey._(
    TargetEntity.ebookCollection,
    '${ebookId.toLowerCase()}:${collectionId.toLowerCase()}',
  );

  /// Where this device stopped in a work.
  ///
  /// The device is not part of the key. This state belongs to one device, and
  /// the only reading position it can author is its own (C05) — a key that
  /// named a device would be a key that could name another one's.
  factory RecordKey.position({required String ebookId}) =>
      RecordKey._(TargetEntity.readingProgress, ebookId.toLowerCase());

  /// Which kind of record.
  final TargetEntity entity;

  /// What identifies it: its own identifier, or the natural key, in canonical
  /// lowercase text.
  final String identity;

  @override
  bool operator ==(Object other) =>
      other is RecordKey &&
      other.entity == entity &&
      other.identity == identity;

  @override
  int get hashCode => Object.hash(entity, identity);

  @override
  String toString() => '${entity.wireName}:$identity';
}

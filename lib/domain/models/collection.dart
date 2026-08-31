/// A grouping the reader defined over their collection.
///
/// A collection and a category are the same structure with a different
/// meaning, which is what lets RF05 offer both without a second entity. The
/// screens are what keep them apart; nothing below the UI needs to.
library;

import '../crdt/revision.dart';

/// The two meanings one structure carries.
enum CollectionKind {
  /// A grouping the reader put together.
  collection('collection'),

  /// A subject they filed a work under.
  category('category');

  const CollectionKind(this.wireName);

  /// The name the contract and both schemas use.
  final String wireName;

  /// The kind [name] spells, or `null` for one this build cannot name.
  static CollectionKind? parse(String name) {
    for (final kind in CollectionKind.values) {
      if (kind.wireName == name) {
        return kind;
      }
    }

    return null;
  }

  @override
  String toString() => wireName;
}

/// A grouping.
final class Collection {
  /// The grouping, as a replica holds it.
  const Collection({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.revision,
    this.description,
  });

  /// The identifier the device that created it minted.
  final String id;

  /// What the reader called it.
  final String name;

  /// Which of the two meanings, or `null` for one this build cannot name.
  final CollectionKind? kind;

  /// What the reader said it is for, if anything.
  final String? description;

  /// When it was created, on a wall clock.
  final DateTime createdAt;

  /// The replication metadata.
  final Revision revision;

  @override
  String toString() => 'Collection($id, $name)';
}

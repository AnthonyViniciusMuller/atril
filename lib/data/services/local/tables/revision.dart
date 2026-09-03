/// The replication metadata every replicated table carries.
///
/// It is the same four columns on the e-book, the collection, the filing of one
/// in the other and the annotation, which is what lets one reconciler serve
/// every one of them. Reading progress is the exception and carries [Version]
/// instead; C05 is why, and `reading.dart` says it where the table is.
///
/// They are a mixin rather than four copies because the reconciler reads them
/// generically: a column named differently on one table would be a record the
/// merge quietly skipped.
library;

import 'package:drift/drift.dart';

import '../../../../domain/crdt/vector_clock.dart';
import '../converters.dart';

/// The four columns of [RevisionColumns], as a type.
///
/// drift generates one unrelated class per table, so what the four replicated
/// rows share is a shape and not a supertype — and the reconciler, which reads
/// them generically, had four identical bodies to turn a row into a
/// `Revision`. Declaring it here and naming it in each table's
/// `@DataClassName` is what makes the shape a type: nothing about the schema
/// changes, and the merge is read off a row by one function.
abstract interface class HasRevision {
  /// The causal version of the record.
  VectorClock get vectorClock;

  /// The first half of the tie-break.
  DateTime get updatedAt;

  /// The second half: the device whose write the record reflects.
  String get deviceId;

  /// Whether the record is a tombstone.
  bool get deleted;
}

/// `vector_clock`, `updated_at`, `device_id` and `deleted`, spelled once.
///
/// The names are the node's own, and deliberately: the same vocabulary travels
/// through the contract, `library.ebooks` on the other side and this schema, so
/// that a delta naming `title` means the same thing in all three.
mixin RevisionColumns on Table {
  /// The causal version of the record, as the JSON object the node stores in
  /// `jsonb`. The reconciler consults it first and consults nothing else unless
  /// it reports two versions concurrent.
  TextColumn get vectorClock => text().map(const VectorClockConverter())();

  /// The first half of the tie-break, on the hybrid clock C01 describes. It is
  /// not a wall clock reading, and nothing renders it to a reader.
  IntColumn get updatedAt => integer().map(const InstantConverter())();

  /// The second half: the device whose write the record currently reflects,
  /// never the one that created it (C10).
  TextColumn get deviceId => text().withLength(min: 36, max: 36)();

  /// The tombstone. A record removed outright is resurrected by the next
  /// replica that had not yet heard about the deletion, so deletion is a write
  /// like any other and reconciles like one.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// The causal state a change is authored on top of.
library;

import 'package:drift/drift.dart';

import '../../../../domain/models/operation.dart';
import '../converters.dart';
import 'constraints.dart';

/// The version this device last saw of each record it has touched, and the
/// identifier it minted for the two records that need one.
///
/// It exists because authoring a change means ticking the clock of *the version
/// it was derived from*. A device that had forgotten that version would author
/// a first write to a record that already has a history, and the node would
/// order the result behind writes it causally follows.
///
/// The second column is C18. A filing and a reading position carry a surrogate
/// identifier each replica mints for itself, so the one this device minted has
/// to be remembered or it mints another on every write — filling the log with a
/// new name for the same record while the reconciler on the other side resolves
/// all of them to the same row.
///
/// It is not the same thing as the replica. The replica holds what the records
/// currently are; this holds what this device knows about their history, which
/// is what the next write has to be stamped against. They move together and are
/// written in one transaction, but a record can be here and not there — a
/// filing this device deleted before any node had heard of it, say.
@DataClassName('RecordVersionRow')
class RecordVersions extends Table {
  /// Which kind of record.
  TextColumn get entity => text().withLength(min: 1, max: 40)();

  /// What identifies it: its own identifier for three of the five entities, and
  /// the natural key for the two C18 names.
  TextColumn get identity => text().withLength(min: 1, max: 128)();

  /// The identifier this device uses for the row — the record's own where it
  /// has one, and the surrogate this device minted where it does not.
  TextColumn get recordId => text().withLength(min: 36, max: 36)();

  /// The causal version last seen.
  ///
  /// It is merged and never replaced. A device holding a change it has not
  /// pushed knows a version the node does not, and a reply that overwrote this
  /// with the node's would let the next write be stamped underneath a write
  /// this device itself made.
  TextColumn get vectorClock => text().map(const VectorClockConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{entity, identity};

  @override
  List<String> get customConstraints => <String>[
    oneOf('entity', TargetEntity.values.map((entity) => entity.wireName)),
  ];
}

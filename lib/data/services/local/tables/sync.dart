/// What this device owes the federation, and how far it has read from each
/// node.
///
/// Neither table replicates. `pending_operations` is this device's outbox — the
/// changes it authored and has not handed over — and `node_cursors` is its
/// place in somebody else's log. They are the two halves of RN06 seen from a
/// device: what it has to say, and what it has heard.
library;

import 'package:drift/drift.dart';

import '../../../../domain/models/operation.dart';
import '../converters.dart';
import 'constraints.dart';
import 'identity.dart';

/// The changes this device authored and has not yet handed to a node.
///
/// It is drained by the push of phase 11, in the order it was written, and an
/// entry leaves it when a node has answered for it — applied, duplicate or
/// superseded all retire an operation, because all three mean the node has it.
///
/// The row is ordered by [sequence] and identified by [id], and the two are
/// separate on purpose. The identifier is minted by this device and is the same
/// uuid on every node that ever sees the operation, so it cannot also be a
/// position; the sequence is sqlite's own rowid, which is the order the rows
/// were written in and therefore the order this device authored them. A log
/// pushed out of order is a log whose updates arrive before their inserts.
@DataClassName('PendingOperationRow')
class PendingOperations extends Table {
  /// This device's authoring order. It is the rowid, so it is assigned by
  /// sqlite and never reused while the log has an entry above it.
  IntColumn get sequence => integer().autoIncrement()();

  /// The identifier this device minted for the change, which every replica
  /// recognizes it by.
  TextColumn get id => text().withLength(min: 36, max: 36).unique()();

  /// The device that authored it, which is this one. It is stored rather than
  /// inferred because an operation carries its author across the wire, and
  /// because a migration to another node pushes what was authored *here* under
  /// the identity it was authored with.
  TextColumn get deviceId => text().withLength(min: 36, max: 36)();

  /// Which kind of record changed.
  TextColumn get targetEntity => text().withLength(min: 1, max: 40)();

  /// The record the change names.
  TextColumn get targetId => text().withLength(min: 36, max: 36)();

  /// What the change did.
  TextColumn get operation => text().withLength(min: 1, max: 20)();

  /// The changed fields and nothing else, as the JSON object the contract
  /// carries in `Operation.delta`.
  ///
  /// It is stored as text rather than decoded because nothing between here and
  /// the wire reads inside it: the push renders it and the reconciler on the
  /// other side decodes it. A field named as JSON null is a field the change
  /// cleared, so the nulls have to survive being stored, which they do here and
  /// would not in a map that dropped them.
  TextColumn get delta => text()();

  /// The causal version the change was authored at.
  TextColumn get vectorClock => text().map(const VectorClockConverter())();

  /// When it was stamped, on the hybrid clock.
  IntColumn get createdAt => integer().map(const InstantConverter())();

  @override
  List<String> get customConstraints => <String>[
    oneOf(
      'target_entity',
      TargetEntity.values.map((entity) => entity.wireName),
    ),
    oneOf('operation', OperationKind.values.map((kind) => kind.wireName)),
    // The set is closed here as it is in the node's column, and for the reason
    // that schema gives: a typo in an entity name would otherwise produce
    // operations no reconciler ever applies, and nothing would say so.
    "CHECK (json_type(delta) = 'object')",
  ];
}

/// The operations this device has already applied to its replica.
///
/// It is how receiving is made idempotent, and it is the device's equivalent of
/// the node's `INSERT ... ON CONFLICT (id) DO NOTHING` against its own log: an
/// operation reaching a replica twice — from the node it was pulled from, and
/// again from a peer that also replicates the reader — is recognized by the
/// identifier its author minted, and never applied twice.
///
/// Applying twice would in fact be harmless, because the merge is idempotent:
/// the second application loses to the version the first one wrote. This table
/// is what makes redelivery *free* rather than merely safe, and what lets the
/// caller be told `duplicate` — which is a different thing from `superseded`,
/// and the difference is what a reader is shown when a change of theirs lost.
@DataClassName('AppliedOperationRow')
class AppliedOperations extends Table {
  /// The identifier the authoring device minted.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// When this device applied it, on a wall clock. It is a diagnostic, and it
  /// is what a later phase would prune by.
  IntColumn get appliedAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// How far this device has read from each node's log.
///
/// The cursor is keyed by the node because a position is *that node's* order
/// for the reader's log, assigned when the operation was stored there. Two
/// nodes number the same operations differently, so a device that pulls from
/// its origin and from a replica keeps two numbers that have nothing to do with
/// each other, and C08 is why neither of them can be a timestamp: an operation
/// stamped early and committed late is skipped by a cursor that has already
/// moved past it, and it is not delayed, it is lost.
@DataClassName('NodeCursorRow')
class NodeCursors extends Table {
  /// The node this position belongs to, by the domain this device addresses it
  /// at. See [KnownServers.domain] for why that is the key and not the node's
  /// own identifier.
  TextColumn get serverDomain =>
      text().references(KnownServers, #domain, onDelete: KeyAction.cascade)();

  /// The last position this device has pulled and committed.
  ///
  /// It is advanced after the batch is written and not after it is received: an
  /// operation read from a socket is not an operation written to disk, and a
  /// device that dies in between must come back to the same place. Zero is a
  /// device that has pulled nothing, which is what a freshly bound one asks
  /// from.
  IntColumn get lastPosition => integer().withDefault(const Constant(0))();

  /// When the cursor last moved, on a wall clock.
  ///
  /// It is a diagnostic and never a cursor: it is what the sync surface of
  /// phase 11 shows a reader who wants to know whether their notes are only on
  /// this phone.
  IntColumn get pulledAt =>
      integer().map(const InstantConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{serverDomain};

  @override
  List<String> get customConstraints => <String>['CHECK (last_position >= 0)'];
}

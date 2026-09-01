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

/// The changes a node refused, and the reason it gave.
///
/// It is the quarantine, and it is deliberately minimal. A refusal is the one
/// outcome of a push that reaches a reader, and the shape of the response is
/// argued in the roadmap's decision table: **the local write stays**, the change
/// is flagged, and the reader is shown the node's reason with a discard.
///
/// It is not a rollback. The change may have others built on top of it — a note
/// on a work whose creation was refused, a filing under a shelf — and destroying
/// those to satisfy a refusal is the one outcome worse than the refusal. And it
/// is not silence: a device holding a change nobody will ever receive, and
/// saying nothing about it, is a device disagreeing with every replica while its
/// reader believes otherwise.
///
/// It is a **side table and not a column** on `pending_operations`, for a reason
/// this schema's migration makes concrete: every version so far only adds, so
/// the upgrade is `createAll` and its statements are `CREATE TABLE IF NOT
/// EXISTS`. A column would make this the first stepped migration in the project,
/// which is a change worth making on the day a column actually has to change and
/// not for a flag. It also keeps the outbox dumb, which its own comment asks
/// for.
///
/// The row is deleted with the operation it names. Discarding a refused change
/// removes the outbox entry and this goes with it; so does a change the node
/// later accepted, which is what happens when a refusal was about something the
/// reader has since fixed.
@DataClassName('RefusedOperationRow')
class RefusedOperations extends Table {
  /// The operation refused, which is still in the outbox.
  TextColumn get id => text()
      .withLength(min: 36, max: 36)
      .references(PendingOperations, #id, onDelete: KeyAction.cascade)();

  /// What the node said, verbatim.
  ///
  /// The contract writes it for an operator rather than for a reader, and it is
  /// stored and shown unchanged anyway: a screen that knows why and does not say
  /// is worse than one that says something only half its readers can act on.
  TextColumn get reason => text().withDefault(const Constant(''))();

  /// When this device was told, on a wall clock.
  IntColumn get refusedAt => integer().map(const InstantConverter())();

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

  /// When this device last completed an exchange with the node, on a wall
  /// clock.
  ///
  /// It is a diagnostic and never a cursor: it is what the sync surface shows a
  /// reader who wants to know whether their notes are only on this phone. It
  /// moves when the cursor does *and* when a live channel opens onto a log that
  /// had nothing new in it — a device that is up to date exchanges nothing, and
  /// a column that only moved on a pull would tell that reader their last sync
  /// was a week ago because nothing has happened since.
  IntColumn get pulledAt =>
      integer().map(const InstantConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{serverDomain};

  @override
  List<String> get customConstraints => <String>['CHECK (last_position >= 0)'];
}

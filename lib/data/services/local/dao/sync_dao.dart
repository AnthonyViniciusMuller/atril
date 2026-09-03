/// The outbox and the cursors: what this device owes, and where it has read to.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../domain/models/operation.dart';
import '../database.dart';
import '../tables/sync.dart';

part 'sync_dao.g.dart';

/// The local operation log and the per-node cursors.
///
/// Nothing here decides anything about a record. Appending is what the
/// operation author of phase 7 does after it has written the local replica, and
/// draining is what the push of phase 11 does; this is the storage between the
/// two, and it is deliberately dumb — an outbox that reordered, deduplicated or
/// interpreted what it holds would be a second reconciler with no tests.
@DriftAccessor(
  tables: <Type>[
    PendingOperations,
    NodeCursors,
    AppliedOperations,
    RefusedOperations,
  ],
)
class SyncDao extends DatabaseAccessor<AtrilDatabase> with _$SyncDaoMixin {
  /// The accessor over [database].
  SyncDao(super.database);

  /// Appends [operation] to what this device owes.
  ///
  /// The identifier is unique, so the same operation offered twice is a
  /// conflict rather than a second row: an author that retried after a failure
  /// it could not see the outcome of must not queue the change again.
  Future<void> append(Operation operation) =>
      into(pendingOperations).insert(_rowOf(operation));

  /// Appends [operations] in the order given, as one transaction.
  Future<void> appendAll(Iterable<Operation> operations) => batch(
    (batch) => batch.insertAll(pendingOperations, operations.map(_rowOf)),
  );

  /// What this device has authored and not handed over, oldest first.
  ///
  /// The order is the order it was authored in, which is the order it has to be
  /// pushed in: a log whose updates arrive before their inserts is a log the
  /// node refuses half of.
  ///
  /// A quarantined change is not among them. It is still owed in the sense that
  /// this device holds it and no node does, and it is not *offerable*: the node
  /// refused it and will refuse it again, and leaving it at the head of the
  /// queue would stop every change behind it from ever being offered.
  Future<List<Operation>> pending({int? limit}) async {
    final query = select(pendingOperations)
      ..where((row) => notExistsQuery(_refusal(row.id)))
      ..orderBy(<OrderClauseGenerator<$PendingOperationsTable>>[
        (row) => OrderingTerm(expression: row.sequence),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return (await query.get()).map(_operationOf).toList();
  }

  /// How many changes are still going to be offered, which is what the sync
  /// surface counts as *waiting*.
  ///
  /// A quarantined change is not among them, for the reason it is not among
  /// [pending]: it is not waiting for anything, and counting it as though it
  /// were would be telling a reader to be patient about a change that will
  /// never leave.
  Future<int> pendingCount() async {
    final count = pendingOperations.sequence.count();
    final row =
        await (selectOnly(pendingOperations)
              ..addColumns(<Expression<Object>>[count])
              ..where(notExistsQuery(_refusal(pendingOperations.id))))
            .getSingle();

    return row.read(count) ?? 0;
  }

  /// [pendingCount], as it changes.
  Stream<int> watchPendingCount() {
    final count = pendingOperations.sequence.count();

    return (selectOnly(pendingOperations)
          ..addColumns(<Expression<Object>>[count])
          ..where(notExistsQuery(_refusal(pendingOperations.id))))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Records that a node refused [id], because [reason].
  ///
  /// The operation stays in the outbox and stops being offered. Nothing about
  /// the replica changes: the reader has seen the change land, others may be
  /// built on top of it, and undoing those to satisfy a refusal is the one
  /// outcome worse than the refusal itself.
  Future<void> quarantine(
    String id, {
    required String reason,
    required DateTime at,
  }) => into(refusedOperations).insertOnConflictUpdate(
    RefusedOperationsCompanion.insert(
      id: id,
      refusedAt: at,
      reason: Value<String>(reason),
    ),
  );

  /// The changes a node refused, most recently refused first.
  ///
  /// It answers with the operation and what the node said, because a reader
  /// looking at this list is looking at a change they made and needs to
  /// recognize it as one.
  Future<List<(Operation, RefusedOperationRow)>> refused() async =>
      _refusalsOf(await _refusedQuery().get());

  /// [refused], as it changes.
  Stream<List<(Operation, RefusedOperationRow)>> watchRefused() =>
      _refusedQuery().watch().map(_refusalsOf);

  /// Forgets the refused change [id], at the reader's asking.
  ///
  /// It removes the outbox entry and the refusal with it. The record itself is
  /// untouched, which is the whole of what *discard* means here: the reader
  /// stops being told about a delivery that will not happen, and nothing they
  /// wrote is destroyed.
  Future<int> discard(String id) =>
      (delete(pendingOperations)..where((row) => row.id.equals(id))).go();

  /// Retires the operations a node has answered for.
  ///
  /// Applied, duplicate and superseded all retire one, because all three mean
  /// the node has it: a superseded operation is stored in its log and lost the
  /// merge there, which is a verdict and not a failure to deliver.
  Future<int> retire(Iterable<String> ids) => (delete(
    pendingOperations,
  )..where((row) => row.id.isIn(ids.toList()))).go();

  /// Whether this device has already applied the operation [id] names.
  Future<bool> hasApplied(String id) async =>
      await (select(appliedOperations)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// Records that the operation [id] names has been applied to the replica.
  ///
  /// It is written inside the same transaction as the change it describes. A
  /// device that recorded it separately could be interrupted between the two
  /// and would then either apply an operation twice or never — and the second
  /// is not made safe by the merge.
  Future<void> markApplied(String id, {required DateTime at}) =>
      into(appliedOperations).insert(
        AppliedOperationsCompanion.insert(id: id, appliedAt: at),
        mode: InsertMode.insertOrIgnore,
      );

  /// This device's position in the log of the node at [serverDomain], which is
  /// zero for a node it has never pulled from.
  Future<int> cursor(String serverDomain) async {
    final row =
        await (select(nodeCursors)
              ..where((cursor) => cursor.serverDomain.equals(serverDomain)))
            .getSingleOrNull();

    return row?.lastPosition ?? 0;
  }

  /// Records that everything up to [position] in the log of the node at
  /// [serverDomain] has been committed here.
  ///
  /// It never moves backwards. A pull that answered with an older page — a
  /// retry, a node that restarted mid-stream — must not undo a position this
  /// device has already written, because the operations behind it are already
  /// applied and re-applying them is work rather than correction.
  Future<void> advanceCursor(
    String serverDomain,
    int position, {
    required DateTime at,
  }) => into(nodeCursors).insert(
    NodeCursorsCompanion.insert(
      serverDomain: serverDomain,
      lastPosition: Value<int>(position),
      pulledAt: Value<DateTime>(at),
    ),
    onConflict: DoUpdate<$NodeCursorsTable, NodeCursorRow>(
      (_) => NodeCursorsCompanion(
        lastPosition: Value<int>(position),
        pulledAt: Value<DateTime>(at),
      ),
      where: (cursor) => cursor.lastPosition.isSmallerThanValue(position),
    ),
  );

  /// Records that this device reached the node at [serverDomain] at [at],
  /// whether or not it had anything to say.
  ///
  /// It moves [NodeCursors.pulledAt] and nothing else, and it is the other half
  /// of what that column means: a device that is up to date pulls nothing, and
  /// a timestamp that only moved on a pull would tell a reader their last sync
  /// was whenever somebody last wrote something. What its callers pass is
  /// evidence the node answered, and never the fact that a channel was opened
  /// — opening one does not reach it.
  Future<void> recordExchange(String serverDomain, {required DateTime at}) =>
      into(nodeCursors).insert(
        NodeCursorsCompanion.insert(
          serverDomain: serverDomain,
          pulledAt: Value<DateTime>(at),
        ),
        onConflict: DoUpdate<$NodeCursorsTable, NodeCursorRow>(
          (_) => NodeCursorsCompanion(pulledAt: Value<DateTime>(at)),
        ),
      );

  /// When this device last reached the node at [serverDomain], or `null` if it
  /// never has.
  Future<DateTime?> lastExchangeWith(String serverDomain) async =>
      (await (select(nodeCursors)
                ..where((cursor) => cursor.serverDomain.equals(serverDomain)))
              .getSingleOrNull())
          ?.pulledAt;

  /// [lastExchangeWith], as it changes.
  Stream<DateTime?> watchLastExchangeWith(String serverDomain) =>
      (select(nodeCursors)
            ..where((cursor) => cursor.serverDomain.equals(serverDomain)))
          .watchSingleOrNull()
          .map((NodeCursorRow? row) => row?.pulledAt);

  /// Forgets this device's position in the log of the node at [serverDomain].
  ///
  /// It is what a migration does and the only thing that does it. A position
  /// is a number in *that* node's log; the log it is about to start writing
  /// for this reader is empty, and a number left over from an earlier
  /// conversation with the same address would skip everything the migration is
  /// about to put there.
  Future<int> dropCursor(String serverDomain) => (delete(
    nodeCursors,
  )..where((cursor) => cursor.serverDomain.equals(serverDomain))).go();

  /// Every cursor this device holds.
  Future<List<NodeCursorRow>> cursors() => select(nodeCursors).get();

  JoinedSelectStatement<HasResultSet, dynamic> _refusedQuery() =>
      select(refusedOperations).join(<Join<HasResultSet, dynamic>>[
        innerJoin(
          pendingOperations,
          pendingOperations.id.equalsExp(refusedOperations.id),
        ),
      ])..orderBy(<OrderingTerm>[
        OrderingTerm.desc(refusedOperations.refusedAt),
      ]);

  List<(Operation, RefusedOperationRow)> _refusalsOf(List<TypedResult> rows) =>
      <(Operation, RefusedOperationRow)>[
        for (final row in rows)
          (
            _operationOf(row.readTable(pendingOperations)),
            row.readTable(refusedOperations),
          ),
      ];

  /// The refusal naming [id], as the subquery `pending` excludes rows by.
  SimpleSelectStatement<$RefusedOperationsTable, RefusedOperationRow> _refusal(
    Expression<String> id,
  ) => select(refusedOperations)..where((row) => row.id.equalsExp(id));

  PendingOperationsCompanion _rowOf(Operation operation) =>
      PendingOperationsCompanion.insert(
        id: operation.id,
        deviceId: operation.deviceId,
        targetEntity: operation.entity.wireName,
        targetId: operation.targetId,
        operation: operation.kind.wireName,
        delta: json.encode(operation.delta),
        vectorClock: operation.vectorClock,
        createdAt: operation.createdAt,
      );

  Operation _operationOf(PendingOperationRow row) {
    final entity = TargetEntity.parse(row.targetEntity);
    final kind = OperationKind.parse(row.operation);

    if (entity == null || kind == null) {
      // The column admits neither, so reaching this means the schema and this
      // vocabulary have come apart — which is a fault in this build and not in
      // anything a node sent.
      throw StateError(
        'the log holds a ${row.operation} on a ${row.targetEntity}, which this '
        'build cannot name',
      );
    }

    return Operation(
      id: row.id,
      deviceId: row.deviceId,
      entity: entity,
      targetId: row.targetId,
      kind: kind,
      delta: _deltaOf(row.delta),
      vectorClock: row.vectorClock,
      createdAt: row.createdAt,
    );
  }

  Map<String, Object?> _deltaOf(String stored) {
    final decoded = json.decode(stored);

    if (decoded is! Map<String, Object?>) {
      throw FormatException('the delta is not an object', stored);
    }

    return decoded;
  }
}

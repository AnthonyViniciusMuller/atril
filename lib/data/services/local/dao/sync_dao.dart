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
@DriftAccessor(tables: <Type>[PendingOperations, NodeCursors])
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
  Future<List<Operation>> pending({int? limit}) async {
    final query = select(pendingOperations)
      ..orderBy(<OrderClauseGenerator<$PendingOperationsTable>>[
        (row) => OrderingTerm(expression: row.sequence),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return (await query.get()).map(_operationOf).toList();
  }

  /// How many changes are waiting, which is what the sync surface counts.
  Future<int> pendingCount() async {
    final count = pendingOperations.sequence.count();
    final row = await (selectOnly(
      pendingOperations,
    )..addColumns(<Expression<Object>>[count])).getSingle();

    return row.read(count) ?? 0;
  }

  /// [pendingCount], as it changes.
  Stream<int> watchPendingCount() {
    final count = pendingOperations.sequence.count();

    return (selectOnly(pendingOperations)
          ..addColumns(<Expression<Object>>[count]))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Retires the operations a node has answered for.
  ///
  /// Applied, duplicate and superseded all retire one, because all three mean
  /// the node has it: a superseded operation is stored in its log and lost the
  /// merge there, which is a verdict and not a failure to deliver.
  Future<int> retire(Iterable<String> ids) => (delete(
    pendingOperations,
  )..where((row) => row.id.isIn(ids.toList()))).go();

  /// This device's position in [serverId]'s log, which is zero for a node it
  /// has never pulled from.
  Future<int> cursor(String serverId) async {
    final row = await (select(
      nodeCursors,
    )..where((cursor) => cursor.serverId.equals(serverId))).getSingleOrNull();

    return row?.lastPosition ?? 0;
  }

  /// Records that everything up to [position] in [serverId]'s log has been
  /// committed here.
  ///
  /// It never moves backwards. A pull that answered with an older page — a
  /// retry, a node that restarted mid-stream — must not undo a position this
  /// device has already written, because the operations behind it are already
  /// applied and re-applying them is work rather than correction.
  Future<void> advanceCursor(
    String serverId,
    int position, {
    required DateTime at,
  }) => into(nodeCursors).insert(
    NodeCursorsCompanion.insert(
      serverId: serverId,
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

  /// Every cursor this device holds.
  Future<List<NodeCursorRow>> cursors() => select(nodeCursors).get();

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

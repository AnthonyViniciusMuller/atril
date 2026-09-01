/// Reading and writing what this device knows about each record's history.
library;

import 'package:drift/drift.dart';

import '../../../../domain/crdt/vector_clock.dart';
import '../../../../domain/models/record_key.dart';
import '../database.dart';
import '../tables/records.dart';

part 'records_dao.g.dart';

/// The causal state the operation author stamps a change on top of.
@DriftAccessor(tables: <Type>[RecordVersions])
class RecordsDao extends DatabaseAccessor<AtrilDatabase>
    with _$RecordsDaoMixin {
  /// The accessor over [database].
  RecordsDao(super.database);

  /// What this device last saw of [key], or `null` if it has never touched it.
  Future<RecordVersionRow?> versionOf(RecordKey key) =>
      (select(recordVersions)..where(
            (row) =>
                row.entity.equals(key.entity.wireName) &
                row.identity.equals(key.identity),
          ))
          .getSingleOrNull();

  /// The causal version to stamp the next change to [key] on top of, which is
  /// the empty clock for a record this device has not touched.
  Future<VectorClock> clockOf(RecordKey key) async =>
      (await versionOf(key))?.vectorClock ?? VectorClock.empty;

  /// The identifier this device uses for [key], minting one with [mint] the
  /// first time.
  ///
  /// This is the half of C18 that matters on every write. The node resolves a
  /// filing and a position by their natural key, so the identifier an operation
  /// names is only what the author calls the row — and a device that minted a
  /// new one per write would fill the log with new names for one record.
  Future<String> identifierFor(
    RecordKey key, {
    required String Function() mint,
  }) async => (await versionOf(key))?.recordId ?? mint();

  /// Folds [clock] into what this device knows about [key].
  ///
  /// The merge is the point. A device holding a change it has not yet pushed
  /// knows a version the node does not, and a reply that replaced this with the
  /// node's would let the next write be stamped underneath a write this device
  /// itself made.
  ///
  /// The identifier is not merged and not overwritten: the first one recorded
  /// for a key is the one this device keeps using.
  Future<void> remember(
    RecordKey key, {
    required String recordId,
    required VectorClock clock,
  }) async {
    final known = await versionOf(key);

    await into(recordVersions).insertOnConflictUpdate(
      RecordVersionsCompanion.insert(
        entity: key.entity.wireName,
        identity: key.identity,
        recordId: known?.recordId ?? recordId.toLowerCase(),
        vectorClock: known == null ? clock : known.vectorClock.merge(clock),
      ),
    );
  }

  /// Every version this device holds, for the migration of phase 12 and for a
  /// test that wants to see the whole of it.
  Future<List<RecordVersionRow>> versions() => select(recordVersions).get();

  /// Every device this replica's causal state names.
  ///
  /// A vector clock is keyed by the identifier of the device that ticked it,
  /// so the union of the keys across this table is the set of devices that
  /// have ever authored a change this device has seen. It is what a migration
  /// falls back on when the node being left cannot be asked: the names are
  /// gone, and the identifiers — which are the half that cannot be recreated,
  /// because every operation and every clock references them (C11) — are
  /// here.
  Future<Set<String>> devicesInHistory() async => <String>{
    for (final version in await versions()) ...version.vectorClock.devices,
  };
}

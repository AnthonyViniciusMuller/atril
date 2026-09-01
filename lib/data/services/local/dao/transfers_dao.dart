/// Reading and writing what this device still owes the node in bytes.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/pins.dart';
import '../tables/transfers.dart';

part 'transfers_dao.g.dart';

/// The outbox for files, and what the reader decided to keep.
///
/// Nothing here decides anything: queueing is what the import does, draining is
/// what the uploader does, and this is the storage between them — deliberately
/// dumb, for the reason `SyncDao` is. A queue that reordered or interpreted
/// what it holds would be a second uploader with no tests.
@DriftAccessor(tables: <Type>[ContentUploads, ContentPins])
class TransfersDao extends DatabaseAccessor<AtrilDatabase>
    with _$TransfersDaoMixin {
  /// The accessor over [database].
  TransfersDao(super.database);

  /// Records that [contentHash] is owed, unless it already is.
  ///
  /// It never overwrites. Two works imported from one file are one transfer,
  /// and the row for the first of them may be part way through a session the
  /// node is holding — replacing it would throw away the offset and send the
  /// file again from nothing.
  Future<void> enqueue({
    required String contentHash,
    required String mediaType,
    required int sizeBytes,
    required DateTime at,
  }) => into(contentUploads).insert(
    ContentUploadsCompanion.insert(
      contentHash: contentHash,
      mediaType: mediaType,
      sizeBytes: sizeBytes,
      queuedAt: at,
    ),
    mode: InsertMode.insertOrIgnore,
  );

  /// What is still owed, oldest first.
  ///
  /// The order is the order the reader imported in, which is the order they
  /// are most likely to want the books available in — and it is stable, so a
  /// transfer that keeps failing does not keep jumping the queue.
  Future<List<ContentUploadRow>> pending({int? limit}) {
    final query = select(contentUploads)
      ..orderBy(<OrderClauseGenerator<$ContentUploadsTable>>[
        (row) => OrderingTerm(expression: row.queuedAt),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// [pending], as it changes.
  Stream<List<ContentUploadRow>> watchPending() =>
      (select(contentUploads)..orderBy(
            <OrderClauseGenerator<$ContentUploadsTable>>[
              (row) => OrderingTerm(expression: row.queuedAt),
            ],
          ))
          .watch();

  /// One transfer, or `null` if the file is not owed.
  Future<ContentUploadRow?> transfer(String contentHash) =>
      (select(contentUploads)
            ..where((row) => row.contentHash.equals(contentHash)))
          .getSingleOrNull();

  /// [transfer], as it changes.
  Stream<ContentUploadRow?> watchTransfer(String contentHash) =>
      (select(contentUploads)
            ..where((row) => row.contentHash.equals(contentHash)))
          .watchSingleOrNull();

  /// Records how far the node says the transfer of [contentHash] has got.
  ///
  /// [uploadId] and [sentBytes] are the node's answer and not this device's
  /// arithmetic: what is written here is what a later launch will try to
  /// continue from, and a device that recorded what it *sent* would resume
  /// past bytes that never landed.
  Future<void> recordProgress({
    required String contentHash,
    required String uploadId,
    required int sentBytes,
  }) => (update(
    contentUploads,
  )..where((row) => row.contentHash.equals(contentHash))).write(
    ContentUploadsCompanion(
      uploadId: Value<String?>(uploadId),
      sentBytes: Value<int>(sentBytes),
    ),
  );

  /// Records that an attempt was made and did not finish.
  ///
  /// The session is forgotten when [keepSession] is false, which is what a
  /// refusal the node will not change its mind about deserves: the next
  /// attempt begins rather than trying to continue something that was
  /// released.
  Future<void> recordAttempt({
    required String contentHash,
    required DateTime at,
    String? refusedCode,
    bool keepSession = true,
  }) async {
    final row = await transfer(contentHash);

    if (row == null) {
      return;
    }

    await (update(
      contentUploads,
    )..where((column) => column.contentHash.equals(contentHash))).write(
      ContentUploadsCompanion(
        attemptedAt: Value<DateTime?>(at),
        refusedCode: Value<String?>(refusedCode),
        attempts: Value<int>(row.attempts + 1),
        uploadId: keepSession
            ? const Value<String?>.absent()
            : const Value<String?>(null),
        sentBytes: keepSession
            ? const Value<int>.absent()
            : const Value<int>(0),
      ),
    );
  }

  /// Forgets the transfer of [contentHash], which is what a finished one is.
  ///
  /// A file the node holds is not owed, however it came to hold it: this
  /// device sent it, another device of the reader's did, or it was there all
  /// along because somebody else on the node had imported the same book.
  Future<int> retire(String contentHash) => (delete(
    contentUploads,
  )..where((row) => row.contentHash.equals(contentHash))).go();

  /// What the reader decided about [contentHash], or `null` for a file they
  /// have not decided about — which is the platform's default and not a
  /// third state.
  Future<bool?> decision(String contentHash) async =>
      (await (select(contentPins)
                ..where((row) => row.contentHash.equals(contentHash)))
              .getSingleOrNull())
          ?.kept;

  /// [decision], as it changes.
  Stream<bool?> watchDecision(String contentHash) =>
      (select(contentPins)
            ..where((row) => row.contentHash.equals(contentHash)))
          .watchSingleOrNull()
          .map((row) => row?.kept);

  /// Every decision the reader has taken, by digest.
  Stream<Map<String, bool>> watchDecisions() => select(contentPins).watch().map(
    (rows) => <String, bool>{
      for (final row in rows) row.contentHash: row.kept,
    },
  );

  /// Records that this device does or does not keep [contentHash].
  Future<void> decide({
    required String contentHash,
    required bool kept,
    required DateTime at,
  }) => into(contentPins).insertOnConflictUpdate(
    ContentPinsCompanion.insert(
      contentHash: contentHash,
      kept: kept,
      decidedAt: at,
    ),
  );

  /// How many files are still owed, which is what a sync surface counts.
  Stream<int> watchPendingCount() {
    final counted = contentUploads.contentHash.count();

    return (selectOnly(contentUploads)
          ..addColumns(<Expression<Object>>[counted]))
        .watchSingle()
        .map((row) => row.read(counted) ?? 0);
  }
}

/// Applying one operation to the local replica.
///
/// This is the computation `internal/shared/crdt` performs on the node, run on
/// a device: consult the causal version, and only where it reports two versions
/// concurrent break the tie on `(updated_at, device_id)`. Holding a replica is
/// what makes it unavoidable — `architecture.md` says so under *Holding a
/// replica means owning a reconciler* — and a client that merged differently
/// from the node would converge differently, which is to say it would not
/// converge.
///
/// It decides nothing about *which* version survives. That is
/// [Revision.supersedes], in the shared core, where the merge laws are proved.
/// What this file contributes is the three things the rule cannot do for
/// itself: resolve the record an operation names, decode the fields its delta
/// claims, and write the result.
///
/// It is a service and not a use case, for the reason `architecture.md` gives:
/// applying an operation is not something a view triggers, so it has no view
/// model above it. Together with the operation author of phase 7 it is the only
/// writer to the replicated tables.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../../../domain/crdt/hybrid_clock.dart';
import '../../../domain/crdt/revision.dart';
import '../../../domain/crdt/vector_clock.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/operation.dart';
import '../../../domain/models/record_key.dart';
import '../../../utils/logging.dart';
import '../local/database.dart';
import '../local/tables/library.dart';
import '../local/tables/reading.dart';
import 'delta.dart';

final _log = loggerFor('data/sync');

/// What became of one operation.
///
/// The four are the contract's own `OperationOutcome`, and they are answered
/// here rather than reported to a node: a device reconciles what it pulled, and
/// what it tells is the sync loop above it. Phase 11 is what turns [rejected]
/// into something a reader sees.
enum ReconcileOutcome {
  /// Stored, and it changed the record.
  applied('applied'),

  /// Already applied here, by identifier. Nothing was done and nothing is
  /// wrong: an operation reaching a replica twice by two routes is the normal
  /// shape of a federation.
  duplicate('duplicate'),

  /// Applied and lost. The record already held a version this one does not
  /// causally precede and does not beat on the tie-break, so the record is
  /// unchanged — and the operation is still recorded as seen, because a later
  /// replica must reach the same conclusion from the same history.
  superseded('superseded'),

  /// Refused. The detail says why: a target that is not here, a field the
  /// record cannot hold, a kind of record this build cannot name. No retry
  /// changes any of them.
  rejected('rejected');

  const ReconcileOutcome(this.label);

  /// The name of the outcome, for a log line and a failing test.
  final String label;

  @override
  String toString() => label;
}

/// The answer to one operation.
final class Verdict {
  const Verdict._(this.outcome, this.detail);

  /// The operation changed the record.
  const Verdict.applied() : this._(ReconcileOutcome.applied, null);

  /// The operation had already been applied here.
  const Verdict.duplicate() : this._(ReconcileOutcome.duplicate, null);

  /// The operation lost the merge.
  const Verdict.superseded() : this._(ReconcileOutcome.superseded, null);

  /// The operation was refused, because [detail].
  const Verdict.rejected(String detail)
    : this._(ReconcileOutcome.rejected, detail);

  /// What became of it.
  final ReconcileOutcome outcome;

  /// Why it was refused, for an operator rather than for a reader.
  final String? detail;

  /// Whether the record was changed.
  bool get isApplied => outcome == ReconcileOutcome.applied;

  /// Whether the operation was refused.
  bool get isRejected => outcome == ReconcileOutcome.rejected;

  @override
  String toString() => detail == null ? '$outcome' : '$outcome: $detail';
}

/// Merges operations into the records they name.
final class Reconciler {
  /// The reconciler over a replica, folding every instant it sees into that
  /// device's hybrid clock.
  ///
  /// The clock is positional because a named one cannot be an initializing
  /// formal — Dart has no private named parameter — and holding it in a field
  /// assigned by hand is the one thing the analyzer asks not to do.
  Reconciler(this._database, this._clock);

  final AtrilDatabase _database;
  final HybridClock _clock;

  /// The devices already reported for a clock too far ahead of this one.
  final Set<String> _skewed = <String>{};

  /// Applies [operation] to the replica, and answers for it.
  ///
  /// The whole of it is one transaction: the record, the causal state the next
  /// change will be stamped against, and the note that this operation has been
  /// seen. A device interrupted between any two of those would either apply an
  /// operation twice or forget a version it has already acted on, and only the
  /// first of those is made harmless by the merge.
  Future<Verdict> reconcile(Operation operation) {
    // The instant is folded into this device's clock outside the transaction,
    // because it is not part of the replica: what it guarantees is that the
    // next change this device stamps is stamped after everything it has seen,
    // and that holds whether or not the operation below is applied.
    if (!_clock.observe(operation.createdAt)) {
      _reportSkew(operation);
    }

    return _database.transaction(() async {
      if (await _database.syncDao.hasApplied(operation.id)) {
        return const Verdict.duplicate();
      }

      final verdict = await _apply(operation);

      if (verdict.isRejected) {
        // A refusal is deterministic and is not recorded as applied. Nothing
        // is gained by remembering it — the same operation delivered again is
        // refused again, at the cost of one decode — and something is lost: a
        // build that grows a field this one could not hold would skip it.
        _log.warning('an operation was refused: $operation, ${verdict.detail}');

        return verdict;
      }

      await _database.syncDao.markApplied(operation.id, at: DateTime.now());

      return verdict;
    });
  }

  /// Applies [operations] in the order given, answering for each.
  ///
  /// Each is its own transaction, because each is its own verdict: a batch that
  /// rolled back on the first refusal would discard the operations behind it,
  /// which are somebody else's changes and are not wrong.
  Future<List<Verdict>> reconcileAll(Iterable<Operation> operations) async {
    final verdicts = <Verdict>[];

    for (final operation in operations) {
      verdicts.add(await reconcile(operation));
    }

    return verdicts;
  }

  Future<Verdict> _apply(Operation operation) async {
    try {
      return switch (operation.entity) {
        TargetEntity.ebook => await _ebook(operation),
        TargetEntity.collection => await _collection(operation),
        TargetEntity.ebookCollection => await _filing(operation),
        TargetEntity.annotation => await _annotation(operation),
        TargetEntity.readingProgress => await _position(operation),
      };
    } on DeltaException catch (failure) {
      return Verdict.rejected('$failure');
    } on InvalidDataException catch (failure) {
      // drift checks a column's declared length in Dart before the statement
      // is built, so a locator past its bound or a digest of the wrong length
      // never reaches sqlite — and is the same kind of fact about the
      // operation as the constraints that do.
      return Verdict.rejected('the replica cannot hold it: ${failure.message}');
    } on SqliteException catch (failure) {
      return _refusedByTheSchema(failure);
    } on DriftRemoteException catch (failure) {
      // The replica runs on a background isolate on the five native targets,
      // and what the isolate threw arrives wrapped.
      final cause = failure.remoteCause;

      if (cause is SqliteException) {
        return _refusedByTheSchema(cause);
      }

      rethrow;
    }
  }

  /// A constraint the schema enforced and the readers above did not, turned
  /// into the verdict it should have been.
  ///
  /// The readers pre-validate every `CHECK` this build knows to name — a
  /// format, a kind, a note's text, a percent — so that the refusal names the
  /// field. This is the net under them: a constraint added to the schema and
  /// not to a reader is still a delivery the replica cannot hold, and the
  /// alternative to answering for it is throwing out of the transaction, which
  /// aborts the page with the cursor unmoved and has the device reconnect into
  /// the same operation for ever.
  ///
  /// Only a constraint is caught. A disk that is full or a database that is
  /// locked also arrives as a [SqliteException], and neither is a fact about
  /// the operation: answering *rejected* to one of those would move the cursor
  /// past a change this device never applied, so anything else is rethrown and
  /// the page is retried.
  Verdict _refusedByTheSchema(SqliteException failure) {
    if (failure.resultCode != _sqliteConstraint) {
      throw failure;
    }

    return Verdict.rejected('the replica cannot hold it: ${failure.message}');
  }

  // --- the three records addressed by their own identifier -------------------

  Future<Verdict> _ebook(Operation operation) async {
    final delta = Delta(operation.delta);
    final id = operation.targetId.toLowerCase();
    final existing = await (_database.select(
      _database.ebooks,
    )..where((row) => row.id.equals(id))).getSingleOrNull();

    if (existing == null) {
      if (operation.kind != OperationKind.insert) {
        return const Verdict.rejected(
          'this device holds no work with that identifier',
        );
      }

      await _database
          .into(_database.ebooks)
          .insert(
            EbooksCompanion.insert(
              id: id,
              title: delta.requiredText(fieldTitle),
              format: delta.requiredOneOf(fieldFormat, ebookFormats),
              contentHash: delta.requiredId(fieldContentHash),
              author: _optionalText(delta, fieldAuthor),
              publisher: _optionalText(delta, fieldPublisher),
              language: _optionalText(delta, fieldLanguage),
              sizeBytes: _optionalInteger(delta, fieldSizeBytes),
              extraMetadata: _optionalObject(delta, fieldExtraMetadata),
              // A work that did not say when it entered the collection entered it
              // when the change that created it was authored: the column cannot be
              // empty and the instant is one a reader is shown.
              importedAt: delta.instant(fieldImportedAt) ?? operation.createdAt,
              vectorClock: operation.vectorClock,
              updatedAt: operation.createdAt,
              deviceId: operation.deviceId,
              deleted: Value<bool>(operation.revision.deleted),
            ),
          );

      return _remembered(
        operation,
        RecordKey.record(TargetEntity.ebook, id),
        id,
      );
    }

    if (!operation.revision.supersedes(_revisionOfEbook(existing))) {
      return const Verdict.superseded();
    }

    await (_database.update(
      _database.ebooks,
    )..where((row) => row.id.equals(id))).write(
      EbooksCompanion(
        // The five the delta may claim are exactly the paths `UpdateEbook`
        // admits, and that is not a coincidence: an operation is what a device
        // wrote, and a device writes through the same contract. The format, the
        // digest and the length are fixed at import and are not among them — a
        // change that moved them would make the row describe a file it is not.
        title: _claimedText(delta, fieldTitle),
        author: _optionalText(delta, fieldAuthor),
        publisher: _optionalText(delta, fieldPublisher),
        language: _optionalText(delta, fieldLanguage),
        extraMetadata: _optionalObject(delta, fieldExtraMetadata),
        vectorClock: Value<VectorClock>(operation.vectorClock),
        updatedAt: Value<DateTime>(operation.createdAt),
        deviceId: Value<String>(operation.deviceId),
        deleted: Value<bool>(operation.revision.deleted),
      ),
    );

    return _remembered(operation, RecordKey.record(TargetEntity.ebook, id), id);
  }

  Future<Verdict> _collection(Operation operation) async {
    final delta = Delta(operation.delta);
    final id = operation.targetId.toLowerCase();
    final existing = await (_database.select(
      _database.collections,
    )..where((row) => row.id.equals(id))).getSingleOrNull();

    if (existing == null) {
      if (operation.kind != OperationKind.insert) {
        return const Verdict.rejected(
          'this device holds no grouping with that identifier',
        );
      }

      await _database
          .into(_database.collections)
          .insert(
            CollectionsCompanion.insert(
              id: id,
              name: delta.requiredText(fieldName),
              kind: _claimedOneOf(delta, fieldKind, collectionKinds),
              description: _optionalText(delta, fieldDescription),
              createdAt: delta.instant(fieldCreatedAt) ?? operation.createdAt,
              vectorClock: operation.vectorClock,
              updatedAt: operation.createdAt,
              deviceId: operation.deviceId,
              deleted: Value<bool>(operation.revision.deleted),
            ),
          );

      return _remembered(
        operation,
        RecordKey.record(TargetEntity.collection, id),
        id,
      );
    }

    if (!operation.revision.supersedes(_revisionOfCollection(existing))) {
      return const Verdict.superseded();
    }

    await (_database.update(
      _database.collections,
    )..where((row) => row.id.equals(id))).write(
      CollectionsCompanion(
        name: _claimedText(delta, fieldName),
        kind: _claimedOneOf(delta, fieldKind, collectionKinds),
        description: _optionalText(delta, fieldDescription),
        vectorClock: Value<VectorClock>(operation.vectorClock),
        updatedAt: Value<DateTime>(operation.createdAt),
        deviceId: Value<String>(operation.deviceId),
        deleted: Value<bool>(operation.revision.deleted),
      ),
    );

    return _remembered(
      operation,
      RecordKey.record(TargetEntity.collection, id),
      id,
    );
  }

  Future<Verdict> _annotation(Operation operation) async {
    final delta = Delta(operation.delta);
    final id = operation.targetId.toLowerCase();
    final existing = await (_database.select(
      _database.annotations,
    )..where((row) => row.id.equals(id))).getSingleOrNull();

    if (existing == null) {
      if (operation.kind != OperationKind.insert) {
        return const Verdict.rejected(
          'this device holds no mark with that identifier',
        );
      }

      final work = delta.requiredId(fieldEbookId);

      if (!await _holdsWork(work)) {
        return const Verdict.rejected(
          'this device holds no work the mark could be in',
        );
      }

      final kind = delta.requiredOneOf(fieldKind, annotationKinds);
      final content = _optionalText(delta, fieldText);

      if (_isAnEmptyNote(kind, content.present ? content.value : null)) {
        return const Verdict.rejected('a note cannot be without text');
      }

      await _database
          .into(_database.annotations)
          .insert(
            AnnotationsCompanion.insert(
              id: id,
              ebookId: work,
              kind: kind,
              locator: delta.requiredText(fieldLocator),
              content: content,
              vectorClock: operation.vectorClock,
              updatedAt: operation.createdAt,
              deviceId: operation.deviceId,
              deleted: Value<bool>(operation.revision.deleted),
            ),
          );

      return _remembered(
        operation,
        RecordKey.record(TargetEntity.annotation, id),
        id,
      );
    }

    if (!operation.revision.supersedes(_revisionOfAnnotation(existing))) {
      return const Verdict.superseded();
    }

    final kind = _claimedOneOf(delta, fieldKind, annotationKinds);
    final content = _optionalText(delta, fieldText);

    // The row after the write, not the delta alone: a change that turns a
    // highlight into a note without saying what the note says, or clears the
    // text of one, is refused for the same reason an empty note is.
    if (_isAnEmptyNote(
      kind.present ? kind.value : existing.kind,
      content.present ? content.value : existing.content,
    )) {
      return const Verdict.rejected('a note cannot be without text');
    }

    await (_database.update(
      _database.annotations,
    )..where((row) => row.id.equals(id))).write(
      AnnotationsCompanion(
        // The work is not among them. A mark is made in a work and stays in it;
        // a note that moved between books would be a note about a passage that
        // is not there.
        kind: kind,
        locator: _claimedText(delta, fieldLocator),
        content: content,
        vectorClock: Value<VectorClock>(operation.vectorClock),
        updatedAt: Value<DateTime>(operation.createdAt),
        deviceId: Value<String>(operation.deviceId),
        deleted: Value<bool>(operation.revision.deleted),
      ),
    );

    return _remembered(
      operation,
      RecordKey.record(TargetEntity.annotation, id),
      id,
    );
  }

  // --- the two addressed by their natural key (C18) --------------------------

  Future<Verdict> _filing(Operation operation) async {
    final delta = Delta(operation.delta);
    final work = delta.requiredId(fieldEbookId);
    final grouping = delta.requiredId(fieldCollectionId);

    if (!await _holdsWork(work)) {
      return const Verdict.rejected(
        'this device holds no work the filing could be of',
      );
    }

    if (!await _holdsGrouping(grouping)) {
      return const Verdict.rejected(
        'this device holds no grouping the filing could be under',
      );
    }

    final key = RecordKey.filing(ebookId: work, collectionId: grouping);
    final existing =
        await (_database.select(_database.ebookCollections)..where(
              (row) =>
                  row.ebookId.equals(work) & row.collectionId.equals(grouping),
            ))
            .getSingleOrNull();

    // There is no insert and no update here, only the register: filing a work
    // and filing it again are the same request, and what the kind of the change
    // decides is which way the register goes. A deletion of a pair this device
    // has never held is written too, tombstone and all — dropping it would file
    // the work again the moment this device heard about the filing the deletion
    // undid.
    if (existing == null) {
      await _database
          .into(_database.ebookCollections)
          .insert(
            EbookCollectionsCompanion.insert(
              id: operation.targetId.toLowerCase(),
              ebookId: work,
              collectionId: grouping,
              vectorClock: operation.vectorClock,
              updatedAt: operation.createdAt,
              deviceId: operation.deviceId,
              deleted: Value<bool>(operation.revision.deleted),
            ),
          );

      return _remembered(operation, key, operation.targetId.toLowerCase());
    }

    if (!operation.revision.supersedes(_revisionOfFiling(existing))) {
      return const Verdict.superseded();
    }

    await (_database.update(
      _database.ebookCollections,
    )..where((row) => row.id.equals(existing.id))).write(
      EbookCollectionsCompanion(
        vectorClock: Value<VectorClock>(operation.vectorClock),
        updatedAt: Value<DateTime>(operation.createdAt),
        deviceId: Value<String>(operation.deviceId),
        deleted: Value<bool>(operation.revision.deleted),
      ),
    );

    return _remembered(operation, key, existing.id);
  }

  Future<Verdict> _position(Operation operation) async {
    // There is no deletion. A reader who stops reading a work leaves their
    // position where it was, and the row goes when the work goes, by the
    // cascade the schema declares.
    if (operation.kind == OperationKind.delete) {
      return const Verdict.rejected('a reading position cannot be removed');
    }

    final delta = Delta(operation.delta);
    final work = delta.requiredId(fieldEbookId);

    if (!await _holdsWork(work)) {
      return const Verdict.rejected(
        'this device holds no work the position could be in',
      );
    }

    // The device is the one that authored the operation and is never read from
    // the delta. It is the only device that may write the row, and taking it
    // from anywhere else would let one device move another's bookmark. It is
    // also the second half of the natural key the record is addressed by.
    final device = operation.deviceId.toLowerCase();
    final key = RecordKey.position(ebookId: work);
    final existing =
        await (_database.select(_database.progress)..where(
              (row) => row.ebookId.equals(work) & row.deviceId.equals(device),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.progress)
          .insert(
            ProgressCompanion.insert(
              id: operation.targetId.toLowerCase(),
              ebookId: work,
              deviceId: device,
              locator: delta.requiredText(fieldLocator),
              percent: _optionalPercent(delta),
              vectorClock: operation.vectorClock,
              updatedAt: operation.createdAt,
            ),
          );

      return _rememberedPosition(
        operation,
        key,
        operation.targetId.toLowerCase(),
      );
    }

    // The merge here is the causal order alone, with no tie-break, because
    // there is nothing to tie: the row has one writer and its versions are
    // totally ordered by that device's own counter (C05).
    if (!operation.version.supersedes(
      Version(vectorClock: existing.vectorClock, updatedAt: existing.updatedAt),
    )) {
      return const Verdict.superseded();
    }

    await (_database.update(
      _database.progress,
    )..where((row) => row.id.equals(existing.id))).write(
      ProgressCompanion(
        locator: _claimedText(delta, fieldLocator),
        percent: _optionalPercent(delta),
        vectorClock: Value<VectorClock>(operation.vectorClock),
        updatedAt: Value<DateTime>(operation.createdAt),
      ),
    );

    return _rememberedPosition(operation, key, existing.id);
  }

  // --- what every branch ends with -------------------------------------------

  /// Records the version this device has now seen of the record, and answers
  /// that the change was applied.
  Future<Verdict> _remembered(
    Operation operation,
    RecordKey key,
    String recordId,
  ) async {
    await _database.recordsDao.remember(
      key,
      recordId: recordId,
      clock: operation.vectorClock,
    );

    return const Verdict.applied();
  }

  /// [_remembered] for a reading position, which is remembered only when it is
  /// this device's own.
  ///
  /// A position another device wrote is one this device can never author a
  /// change to, so remembering it would be keeping a clock it has no entry in
  /// and no business ticking.
  Future<Verdict> _rememberedPosition(
    Operation operation,
    RecordKey key,
    String recordId,
  ) async {
    final device = await _database.identityDao.deviceId();

    if (device == null || device != operation.deviceId.toLowerCase()) {
      return const Verdict.applied();
    }

    return _remembered(operation, key, recordId);
  }

  /// Reports a peer whose clock is further ahead than [maxClockDrift], once
  /// for each device.
  ///
  /// [HybridClock.observe] answers whether it followed the instant, and it
  /// documents that reporting the refusal is the caller's job — this is the
  /// only caller. The operation is applied like any other: the answer is about
  /// the *clock*, not about the change. What it costs while it lasts is real
  /// and invisible from a screen, which is why it is a warning and not a fine:
  /// every version that peer stamps beats this device's on the tie-break, so a
  /// reader's edits keep quietly losing to a device whose clock is wrong.
  ///
  /// Once per device, because the next operation from it carries the same news
  /// and a log that repeats itself per operation is a log nobody reads. The set
  /// lives as long as this reconciler, which is as long as the app runs.
  void _reportSkew(Operation operation) {
    if (!_skewed.add(operation.deviceId.toLowerCase())) {
      return;
    }

    _log.warning(
      'the device ${operation.deviceId} is stamping changes more than '
      '$maxClockDrift ahead of this one, and they will win every tie-break '
      'against it until its clock is corrected: $operation',
    );
  }

  Future<bool> _holdsWork(String id) async =>
      await (_database.select(_database.ebooks)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Future<bool> _holdsGrouping(String id) async =>
      await (_database.select(_database.collections)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Revision _revisionOfEbook(EbookRow row) => Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  );

  Revision _revisionOfCollection(CollectionRow row) => Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  );

  Revision _revisionOfAnnotation(AnnotationRow row) => Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  );

  Revision _revisionOfFiling(EbookCollectionRow row) => Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  );
}

/// A nullable text column: absent where the delta does not claim the field,
/// and null where it clears it.
Value<String?> _optionalText(Delta delta, String field) => delta.claims(field)
    ? Value<String?>(delta.text(field))
    : const Value<String?>.absent();

/// A column the record cannot hold nothing in: absent where the delta does not
/// claim the field, and refused where it claims it as nothing.
Value<String> _claimedText(Delta delta, String field) => delta.claims(field)
    ? Value<String>(delta.requiredText(field))
    : const Value<String>.absent();

/// A column the schema closes over [allowed]: absent where the delta does not
/// claim the field, and refused where it claims something outside the set.
Value<String> _claimedOneOf(
  Delta delta,
  String field,
  Iterable<String> allowed,
) => delta.claims(field)
    ? Value<String>(delta.requiredOneOf(field, allowed))
    : const Value<String>.absent();

Value<int?> _optionalInteger(Delta delta, String field) => delta.claims(field)
    ? Value<int?>(delta.integer(field))
    : const Value<int?>.absent();

/// How far through a work, bounded as the column is.
Value<double?> _optionalPercent(Delta delta) => delta.claims(fieldPercent)
    ? Value<double?>(delta.numberWithin(fieldPercent, min: 0, max: 100))
    : const Value<double?>.absent();

/// Whether a mark of [kind] carrying [text] is a note that says nothing, which
/// the schema refuses and the reconciler therefore refuses first.
bool _isAnEmptyNote(String kind, String? text) =>
    kind == AnnotationKind.note.wireName && (text ?? '').trim().isEmpty;

/// sqlite's primary result code for a constraint violation, which is the one
/// failure of a statement that is a fact about the operation rather than about
/// the device.
const int _sqliteConstraint = 19;

/// A JSON object column, stored as the text it travelled as.
Value<String?> _optionalObject(Delta delta, String field) {
  if (!delta.claims(field)) {
    return const Value<String?>.absent();
  }

  final value = delta.object(field);

  return Value<String?>(value == null ? null : json.encode(value));
}

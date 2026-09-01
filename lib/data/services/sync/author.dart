/// Authoring a change to a replicable record.
///
/// This is the path every screen in this app takes to write anything the
/// federation replicates, and it is the reason there is no other one. C21 is
/// why: a change made through the node's write RPCs writes the node's table and
/// appends nothing to its operation log, so it reaches the reader's other
/// devices and every authorized replica — never. The same change authored here
/// and pushed reaches all of them. `architecture.md` states the rule and the
/// test beside this file is what keeps it true.
///
/// **The caller does not branch on connectivity.** There is nothing to branch
/// on. A change is stamped, logged and applied against the local replica, and
/// whether a node hears about it in the next second or the next week is the
/// sync loop's problem and never the screen's. A view that showed a spinner
/// while a note saved would be a view written against the wrong layer.
///
/// **The local replica is written by the reconciler and not by this file.** An
/// author that wrote the row itself would be a second implementation of the
/// merge — the same computation, in the same repository, tested half as hard —
/// and the first divergence between the two would be a change that looks
/// applied here and reconciles differently everywhere else. So authoring is
/// three things the reconciler cannot do for itself: decide the version the
/// change is stamped at, name the record the way every replica will resolve it,
/// and record what this device now owes. Applying it is the ordinary path, run
/// against an operation this device happens to have written.
///
/// `architecture.md` calls the author the second of the three writers to the
/// replicated tables. It is the second *author* of a write; the reconciler is
/// still what performs it, and that is a narrowing of the rule rather than a
/// departure from it.
///
/// **Three records are named and two are described.** A work, a grouping and a
/// mark carry the identifier one device minted, and every replica calls them
/// that. A filing and a reading position do not: each replica mints its own
/// identifier for the row, so what identifies them across the federation is the
/// natural key their delta carries — the pair, and the work plus the authoring
/// device. C18 is the finding, and the identifier this device minted is
/// remembered and reused, so that the log does not fill with new names for one
/// record.
///
/// **The instant is stamped twice over.** [HybridClock.now] gives an instant
/// later than everything this device has stamped or observed, and
/// [Revision.next] raises it again to one step past the version the change was
/// derived from. The second is not redundant: a record seeded from the node's
/// read calls carries an instant this device never folded into its clock, so
/// the per-record floor is what keeps a causally later version from carrying an
/// earlier timestamp — the single edge C01's whole acyclicity argument depends
/// on not existing.
library;

// The composed `where` of the two records addressed by their natural key needs
// drift's own operators on a boolean expression, which are an extension this
// library carries.
import 'package:drift/drift.dart';

import '../../../domain/crdt/hybrid_clock.dart';
import '../../../domain/crdt/revision.dart';
import '../../../domain/models/operation.dart';
import '../../../domain/models/record_key.dart';
import '../../../utils/errors.dart';
import '../../../utils/identifiers.dart';
import '../../../utils/logging.dart';
import '../local/database.dart';
import 'delta.dart';
import 'reconciler.dart';

final _log = loggerFor('data/sync');

/// The operation an authored change reports under.
const String opAuthor = 'sync/author: write';

/// One change to one record, as the caller describes it.
///
/// It names the record and says what became of it, and it carries the fields
/// the change claims — exactly those, because a field the delta does not name
/// keeps whatever device wrote it last and a field named as JSON null is a
/// field the reader cleared. `delta.dart` is where that vocabulary is spelled.
final class Change {
  const Change._(this.key, this.kind, this.delta, {this.liftsTombstone = false});

  /// A record this device is creating: a work, a grouping or a mark.
  ///
  /// The delta has to carry every field the record cannot exist without, which
  /// is what the reconciler refuses an insert for and what makes that refusal
  /// name a field rather than a table.
  factory Change.insert(
    TargetEntity entity,
    String id,
    Map<String, Object?> delta,
  ) => Change._(RecordKey.record(entity, id), OperationKind.insert, delta);

  /// Fields of a record this device is changing.
  factory Change.update(
    TargetEntity entity,
    String id,
    Map<String, Object?> delta,
  ) => Change._(RecordKey.record(entity, id), OperationKind.update, delta);

  /// A record this device is removing.
  ///
  /// It is a tombstone and never a deletion: a record removed outright is
  /// resurrected by the next replica that had not yet heard about the removal,
  /// so it travels as a write and reconciles like one. The delta is empty
  /// because there is nothing to claim — the removal is the kind of the change.
  factory Change.delete(TargetEntity entity, String id) =>
      Change._(RecordKey.record(entity, id), OperationKind.delete, const {});

  /// A record this device is bringing back.
  ///
  /// It is an ordinary update carrying no fields, and that is not the same as
  /// a change that claims nothing: the tombstone *is* the claim, exactly as it
  /// is for [Change.delete] in the other direction. A record's `deleted` flag
  /// travels on the revision and the revision is derived from the kind, so an
  /// update on a tombstoned record lifts it — on this device and, by the same
  /// rule in `internal/sync/infra/service/records`, on every other.
  ///
  /// It is what makes an undo cheap. A deletion that had removed the row would
  /// need the record rebuilt from something; a tombstone needs one operation
  /// with nothing in it.
  factory Change.restore(TargetEntity entity, String id) => Change._(
    RecordKey.record(entity, id),
    OperationKind.update,
    const <String, Object?>{},
    liftsTombstone: true,
  );

  /// A work this device is filing under a grouping (C06, C18).
  ///
  /// The pair travels in the delta because the pair is the record: every
  /// replica mints its own identifier for the row, so the identifier the
  /// operation names is provenance and the pair is what resolves it. It costs
  /// nothing to carry — a device filing a work holds both halves by definition.
  factory Change.filing({
    required String ebookId,
    required String collectionId,
  }) => Change._(
    RecordKey.filing(ebookId: ebookId, collectionId: collectionId),
    OperationKind.insert,
    _pair(ebookId, collectionId),
  );

  /// A work this device is taking out of a grouping.
  ///
  /// It is the same record and the same pair, tombstoned. Filing a work and
  /// filing it again are one request and so are their opposites: what the kind
  /// of the change decides is which way the register goes, which is why there
  /// is no update between the two.
  factory Change.unfiling({
    required String ebookId,
    required String collectionId,
  }) => Change._(
    RecordKey.filing(ebookId: ebookId, collectionId: collectionId),
    OperationKind.delete,
    _pair(ebookId, collectionId),
  );

  /// Where this device stopped in a work (C05, C18).
  ///
  /// The delta carries the work and the caller carries the rest. The device
  /// half of the natural key is deliberately not in it: it is the device that
  /// authored the operation, which is the only device that may write the row,
  /// and a delta that named one would let a change move another device's
  /// bookmark.
  ///
  /// The kind is the author's to decide, because it is a question the caller
  /// should not have to answer. A position has exactly one writer, so whether
  /// there is one to update is exactly whether this device has written one
  /// before — and there is no removal at all: a reader who stops reading a work
  /// leaves their position where it was.
  factory Change.position({
    required String ebookId,
    required Map<String, Object?> delta,
  }) => Change._(RecordKey.position(ebookId: ebookId), null, <String, Object?>{
    fieldEbookId: ebookId.toLowerCase(),
    ...delta,
  });

  static Map<String, Object?> _pair(String ebookId, String collectionId) =>
      <String, Object?>{
        fieldEbookId: ebookId.toLowerCase(),
        fieldCollectionId: collectionId.toLowerCase(),
      };

  /// The record, addressed the way every replica resolves it.
  final RecordKey key;

  /// What the change does to it, or `null` where the author decides.
  ///
  /// The reading position is the only record whose kind is derived, and
  /// [Change.position] says why.
  final OperationKind? kind;

  /// The fields it claims.
  final Map<String, Object?> delta;

  /// Whether this change's whole content is that the record is not deleted.
  ///
  /// It is what tells an update claiming nothing apart from a restore, and the
  /// difference is real: the first says nothing happened, and the second says
  /// the record is back.
  final bool liftsTombstone;

  @override
  String toString() => '${kind ?? 'a write'} $key';
}

/// The one entry point for a change to a replicable record.
final class OperationAuthor {
  /// The author over [database], stamping on [clock] and applying through
  /// [reconciler].
  ///
  /// [mint] names the operation, and the surrogate identifier of a record that
  /// has one; it is a parameter so that a test can watch what was minted rather
  /// than guess it.
  OperationAuthor({
    required this.database,
    required this.clock,
    required this.reconciler,
    String Function()? mint,
  }) : _mint = mint ?? mintIdentifier;

  /// The local replica, which is both what the change is applied to and where
  /// the log of what this device owes lives.
  final AtrilDatabase database;

  /// The device-wide hybrid clock every instant this device stamps comes from.
  final HybridClock clock;

  /// What applies the change here, exactly as it will be applied everywhere
  /// else.
  final Reconciler reconciler;

  final String Function() _mint;

  /// Authors [change], and answers with the operation that carries it.
  ///
  /// The whole of it is one transaction: the record, the causal state the next
  /// change will be stamped against, the note that this operation has been
  /// applied here, and the log entry that says a node has not heard it yet. A
  /// device interrupted between any two of those would either show the reader a
  /// change nobody will ever receive or owe a node one it has not made.
  ///
  /// It throws an [AppException] rather than returning a `Result`, which is the
  /// shape everything under `data/services` has: the repository above is the
  /// layer boundary and the layer boundary is where a failure becomes a value.
  Future<Operation> write(Change change) async {
    final device = await database.identityDao.deviceId();

    if (device == null) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'this device has not been bound and cannot author a change',
        code: 'device_not_bound',
        op: opAuthor,
      );
    }

    if (change.kind == OperationKind.update &&
        change.delta.isEmpty &&
        !change.liftsTombstone) {
      // Authoring it would tick a clock, stamp an instant and queue a push, all
      // to tell every replica that nothing happened — and the record would come
      // out of the merge reflecting this device for a write it did not make.
      //
      // A restore is exempt, and is not an exception to the rule: the record's
      // `deleted` flag travels on the revision rather than in the delta, so an
      // update carrying no fields still says something. `Change.restore` is
      // where that is argued.
      throw AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the change to ${change.key} claims no field',
        code: 'empty_delta',
        op: opAuthor,
      );
    }

    // Read outside the transaction, as the reconciler folds an observed instant
    // outside its own: the clock is device state and not part of the replica,
    // and persisting its floor is a write that must not wait on this one.
    final reading = clock.now();

    return database.transaction(() async {
      final stampedAt = await _lastStampedAt(change, device);
      final previous = Revision(
        // What this device last saw, which is not always what the row holds: a
        // change authored here and not yet pushed is a version the row does not
        // reflect if it lost the merge, and stamping the next one underneath it
        // would let this device tick the same counter twice.
        vectorClock: await database.recordsDao.clockOf(change.key),
        updatedAt: stampedAt,
        deviceId: device,
      );
      final revision = previous.next(device, reading);

      final operation = Operation(
        id: _mint(),
        deviceId: device,
        entity: change.key.entity,
        targetId: await _targetId(change),
        kind: change.kind ?? _kindOf(stampedAt),
        delta: change.delta,
        vectorClock: revision.vectorClock,
        createdAt: revision.updatedAt,
      );

      final verdict = await reconciler.reconcile(operation);

      if (!verdict.isApplied) {
        // The reconciler refuses a change the replica cannot hold — an update
        // to a record this device does not have, a field the record cannot
        // hold — and the transaction takes the log entry down with it. Anything
        // else is this device having authored a version of its own record that
        // does not supersede the one it was derived from, which is a fault in
        // the stamping above rather than in the caller.
        throw AppException(
          kind: verdict.isRejected
              ? ErrorKind.failedPrecondition
              : ErrorKind.internal,
          message: 'the change to ${change.key} was $verdict',
          code: 'change_refused',
          op: opAuthor,
        );
      }

      await database.syncDao.append(operation);

      _log.fine('authored $operation');

      return operation;
    });
  }

  /// The identifier the operation names the record by.
  ///
  /// For a work, a grouping and a mark it is the record's own, minted once by
  /// whichever device created it and used by every replica.
  ///
  /// For the two C18 is about it is neither identity nor arbitrary: the record
  /// is resolved by the natural key in the delta, and this is the name *this*
  /// replica files the row under. It is remembered and reused, which is the
  /// half of C18 that matters on every write — a device that minted a new one
  /// per write would fill its log, and every peer's, with new names for one
  /// record.
  Future<String> _targetId(Change change) async => switch (change.key.entity) {
    TargetEntity.ebook ||
    TargetEntity.collection ||
    TargetEntity.annotation => change.key.identity,
    TargetEntity.ebookCollection || TargetEntity.readingProgress =>
      await database.recordsDao.identifierFor(change.key, mint: _mint),
  };

  /// The instant the version this change is derived from was stamped at, or the
  /// epoch for a record this device does not hold.
  ///
  /// It is read from the record and not from the causal state beside it,
  /// because it is the record's own floor: the timestamp another replica will
  /// order this change against is the one stored on the row.
  Future<DateTime> _lastStampedAt(Change change, String device) async {
    final id = change.key.identity;
    final delta = Delta(change.delta);

    final at = switch (change.key.entity) {
      TargetEntity.ebook => (await (database.select(
        database.ebooks,
      )..where((row) => row.id.equals(id))).getSingleOrNull())?.updatedAt,
      TargetEntity.collection => (await (database.select(
        database.collections,
      )..where((row) => row.id.equals(id))).getSingleOrNull())?.updatedAt,
      TargetEntity.annotation => (await (database.select(
        database.annotations,
      )..where((row) => row.id.equals(id))).getSingleOrNull())?.updatedAt,
      // The pair, which the delta carries because the pair is the record.
      TargetEntity.ebookCollection =>
        (await (database.select(database.ebookCollections)..where(
                  (row) =>
                      row.ebookId.equals(delta.requiredId(fieldEbookId)) &
                      row.collectionId.equals(
                        delta.requiredId(fieldCollectionId),
                      ),
                ))
                .getSingleOrNull())
            ?.updatedAt,
      // The work from the delta and the device from the operation, never the
      // other way round: the only position this device may write is its own.
      TargetEntity.readingProgress =>
        (await (database.select(database.progress)..where(
                  (row) =>
                      row.ebookId.equals(delta.requiredId(fieldEbookId)) &
                      row.deviceId.equals(device),
                ))
                .getSingleOrNull())
            ?.updatedAt,
    };

    return at ?? Revision.zero.updatedAt;
  }

  /// What a change whose caller did not say is doing.
  ///
  /// It is the reading position and only it, and the question is answerable
  /// here precisely because of C05: the row has exactly one writer, so a record
  /// this device has never stamped is a record that does not exist.
  OperationKind _kindOf(DateTime stampedAt) =>
      stampedAt.isAtSameMomentAs(Revision.zero.updatedAt)
      ? OperationKind.insert
      : OperationKind.update;
}

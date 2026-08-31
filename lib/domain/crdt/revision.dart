/// The replication metadata every record this device replicates carries, and
/// the rule that decides which of two versions of one record survives.
///
/// It is the port of `crdt.Revision`, `crdt.Version` and the two `Supersedes`
/// methods in
/// [`internal/shared/crdt`](../../../../quire/internal/shared/crdt). Both types
/// live in one file because they share the stamping rule below and nothing
/// else, and that rule is private to them: a caller that could stamp its own
/// timestamp could stamp one earlier than the version it derived from, which is
/// the single edge the whole argument depends on not existing.
///
/// ## The decision procedure
///
/// Reconciling two copies of a record is taking their join. The vector clock
/// decides first, per RN02: if one version causally precedes the other, the
/// later one is the join and nothing else is consulted. Only where the clocks
/// report the two concurrent — each replica observed something the other did
/// not — is a tie-break needed, and it is `(updatedAt, deviceId)`, which C01
/// establishes as a total order.
///
/// That it is a total order is the whole argument. A join over a set of
/// versions is a maximum, a maximum exists only if the relation has no cycle,
/// and C01's counterexample is a cycle built out of three ordinary writes with
/// a wall clock in the timestamp. The relation is acyclic precisely because
/// every edge points at a larger timestamp: the concurrent edges by the
/// tie-break itself, and the causal edges because the timestamp is stamped on
/// the hybrid clock, so a write that observed another carries a later instant.
library;

import 'hybrid_clock.dart';
import 'ordering.dart';
import 'vector_clock.dart';

/// The instant a record with no history is stamped against.
final DateTime _epoch = DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);

/// The instant to record, given the reading of the hybrid clock and the instant
/// the previous version of this record carries.
///
/// It is the per-record half of C01. A second write to the same record is later
/// than the first even if the authoring device's clock ran backwards between
/// them, so a causally later version can never carry an earlier timestamp and
/// the tie-break cannot cycle.
///
/// The other half is device-wide and is [HybridClock], which is where [at]
/// comes from. The two compose, because a maximum of maxima is a maximum: that
/// clock strengthens this floor without changing it, and this floor is what
/// still holds on a launch whose stored floor was lost.
DateTime _stamp(DateTime at, DateTime previous) {
  final stamped = at.toUtc();
  final floor = previous.toUtc().add(clockResolution);

  return stamped.isBefore(floor) ? floor : stamped;
}

/// The replication metadata of a record with more than one writer: the e-book,
/// the collection, the membership of one in the other, and the annotation.
///
/// It is the same four fields on all of them, which is what lets one reconciler
/// serve every entity. Reading progress is the exception and carries a
/// [Version] instead; C05 is why.
final class Revision {
  /// The revision a record read out of the local database carries.
  ///
  /// It stamps nothing: the values are what was stored, and stamping them again
  /// on the way in would move a timestamp another replica has already ordered
  /// against.
  const Revision({
    required this.vectorClock,
    required this.updatedAt,
    required this.deviceId,
    this.deleted = false,
  });

  /// The metadata of a record [deviceId] has just created: one event, observed
  /// from that device alone.
  factory Revision.first(String deviceId, DateTime at) => Revision(
    vectorClock: VectorClock.empty.tick(deviceId),
    updatedAt: _stamp(at, _epoch),
    deviceId: deviceId,
  );

  /// A revision with no causal history at all, which is the state of a record
  /// nothing has stamped.
  static final Revision zero = Revision(
    vectorClock: VectorClock.empty,
    updatedAt: _epoch,
    deviceId: '',
  );

  /// The causal version of the record.
  ///
  /// A reconciler consults this first, and consults nothing else unless it
  /// reports the two versions concurrent.
  final VectorClock vectorClock;

  /// The first half of the tie-break, on the clock C01 describes: it is
  /// causally monotonic, not a wall clock reading. [next] is what keeps it so.
  final DateTime updatedAt;

  /// The second half, and the reason the pair is a total order: two devices
  /// that have never heard of each other can still stamp the same microsecond,
  /// and any fixed rule settles them provided every replica applies the same
  /// one.
  ///
  /// It is the device whose write the record currently reflects, never the one
  /// that created it. Appendix A of the TCC describes it the other way round on
  /// `anotacao`; see C10.
  ///
  /// It is a device identifier in canonical lowercase text, which is both the
  /// key its [vectorClock] entry is counted under and — because that spelling
  /// compares in the same order as the sixteen bytes behind it — a tie-break
  /// this device and the node cannot decide differently.
  final String deviceId;

  /// The tombstone.
  ///
  /// A record removed outright is resurrected by the next replica that had not
  /// yet heard about the deletion, so deletion is a write like any other and
  /// reconciles like one.
  final bool deleted;

  /// Whether the record has no causal history at all.
  bool get isZero =>
      vectorClock.isEmpty &&
      updatedAt.isAtSameMomentAs(_epoch) &&
      deviceId.isEmpty &&
      !deleted;

  /// The metadata of the record after [deviceId] writes to it again.
  ///
  /// Three things happen, and each is required by a different part of the
  /// design. The clock ticks, so the new version causally dominates the one it
  /// was derived from. The timestamp is stamped, never merely assigned. And the
  /// device is recorded as the one whose write the record now reflects, which is
  /// what C10 corrects in Appendix A.
  ///
  /// The tombstone is deliberately not cleared. A record is undeleted by a write
  /// that says so, not by any write that happens to follow the deletion.
  Revision next(String deviceId, DateTime at) => Revision(
    vectorClock: vectorClock.tick(deviceId),
    updatedAt: _stamp(at, updatedAt),
    deviceId: deviceId,
    deleted: deleted,
  );

  /// [next] with the record marked removed. Deletion is a write, and reconciles
  /// like one.
  Revision tombstone(String deviceId, DateTime at) =>
      _copyWith(next(deviceId, at), deleted: true);

  /// [next] with the record marked present again, which is what an offline
  /// device re-adding something another device removed is asking for.
  Revision restore(String deviceId, DateTime at) =>
      _copyWith(next(deviceId, at), deleted: false);

  /// Whether this revision is the one that survives a merge with [other].
  ///
  /// It is false for two revisions that describe the same version, which is
  /// what makes it a strict order: an operation that adds nothing to what the
  /// record already reflects changes nothing, and is answered as superseded
  /// rather than as applied.
  bool supersedes(Revision other) =>
      switch (vectorClock.compare(other.vectorClock)) {
        Ordering.after => true,
        Ordering.before || Ordering.equal => false,
        Ordering.concurrent => _beatsOnTheTieBreak(other),
      };

  /// Whichever of the two revisions survives.
  ///
  /// It is the join, and the reason it can be written as a choice rather than
  /// as a combination is that a revision describes one version of a whole
  /// record: the fields of the loser are not folded into the winner, because
  /// they belong to a version this one supersedes.
  Revision merge(Revision other) => other.supersedes(this) ? other : this;

  /// Settles two versions the causal order reports concurrent.
  ///
  /// The instant decides, and the device settles the instants that are equal.
  /// The identifiers are compared as their canonical lowercase text, which
  /// orders exactly as the sixteen bytes behind them and is an order a replica
  /// cannot get wrong by rendering the value differently.
  bool _beatsOnTheTieBreak(Revision other) {
    if (!updatedAt.isAtSameMomentAs(other.updatedAt)) {
      return updatedAt.isAfter(other.updatedAt);
    }

    return deviceId.compareTo(other.deviceId) > 0;
  }

  Revision _copyWith(Revision revision, {required bool deleted}) => Revision(
    vectorClock: revision.vectorClock,
    updatedAt: revision.updatedAt,
    deviceId: revision.deviceId,
    deleted: deleted,
  );

  @override
  bool operator ==(Object other) =>
      other is Revision &&
      other.vectorClock == vectorClock &&
      other.updatedAt.isAtSameMomentAs(updatedAt) &&
      other.deviceId == deviceId &&
      other.deleted == deleted;

  @override
  int get hashCode => Object.hash(
    vectorClock,
    updatedAt.toUtc().microsecondsSinceEpoch,
    deviceId,
    deleted,
  );

  @override
  String toString() =>
      'Revision($vectorClock, ${updatedAt.toIso8601String()}, $deviceId'
      '${deleted ? ', deleted' : ''})';
}

/// The replication metadata of a record with exactly one writer: the causal
/// version, and the instant the write was stamped at.
///
/// Reading progress is the only such record, and C05 is why this exists as a
/// type of its own. A progress row belongs to one work and one device, so that
/// device is its only writer, its writes are totally ordered by its own
/// counter, and two versions of the row can never be concurrent. There is
/// nothing to break a tie between, which is precisely the two fields [Revision]
/// carries and this does not: the device whose write the record reflects is
/// already the row's own key, and a tombstone would be a deletion with no
/// meaning — a reader who stops reading a work leaves the position where it was.
///
/// It is therefore not a smaller [Revision] and does not embed one. The clock
/// here is a version counter for deduplication rather than a conflict resolver,
/// and a type that offered a tie-break would invite the reconciler to apply one
/// where nothing ties.
final class Version {
  /// The version a progress row read out of the local database carries.
  const Version({required this.vectorClock, required this.updatedAt});

  /// The metadata of a record [deviceId] has just written for the first time.
  factory Version.first(String deviceId, DateTime at) => Version(
    vectorClock: VectorClock.empty.tick(deviceId),
    updatedAt: _stamp(at, _epoch),
  );

  /// A version with no causal history at all.
  static final Version zero = Version(
    vectorClock: VectorClock.empty,
    updatedAt: _epoch,
  );

  /// The causal version of the record. Because the row has one writer it always
  /// has exactly one entry, and it grows by one on every write.
  final VectorClock vectorClock;

  /// When the write happened, on the clock C01 describes.
  final DateTime updatedAt;

  /// Whether the record has no causal history at all.
  bool get isZero => vectorClock.isEmpty && updatedAt.isAtSameMomentAs(_epoch);

  /// The metadata of the record after its device writes to it again.
  ///
  /// The device is a parameter rather than something the version remembers,
  /// because the version does not carry one: which device this is belongs to
  /// the row, and passing it here is what keeps the clock keyed by the same
  /// device a caller could otherwise silently change.
  Version next(String deviceId, DateTime at) => Version(
    vectorClock: vectorClock.tick(deviceId),
    updatedAt: _stamp(at, updatedAt),
  );

  /// Whether this version is the one that survives a merge with [other].
  ///
  /// There is no tie-break, and that is C05 rather than an omission. A pair
  /// that somehow is concurrent is not a tie to break but a row written by a
  /// device that had no business writing it, and answering it with "neither
  /// supersedes" is what leaves the record alone until somebody looks.
  bool supersedes(Version other) => vectorClock.happensAfter(other.vectorClock);

  /// Whichever of the two versions survives.
  Version merge(Version other) => other.supersedes(this) ? other : this;

  @override
  bool operator ==(Object other) =>
      other is Version &&
      other.vectorClock == vectorClock &&
      other.updatedAt.isAtSameMomentAs(updatedAt);

  @override
  int get hashCode =>
      Object.hash(vectorClock, updatedAt.toUtc().microsecondsSinceEpoch);

  @override
  String toString() => 'Version($vectorClock, ${updatedAt.toIso8601String()})';
}

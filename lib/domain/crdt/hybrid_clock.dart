/// The clock every timestamp this device stamps comes from.
///
/// It is C01 in
/// [`quire/docs/tcc-corrections.md`](../../../../quire/docs/tcc-corrections.md),
/// and the correction is worth restating because the naive reading looks
/// harmless. The tie-break for two concurrent versions is
/// `(updated_at, device_id)`, and while `updated_at` is a wall clock reading
/// that relation has cycles: ordinary skew between two devices, with neither
/// clock ever running backwards, is enough for a causally later write to carry
/// an earlier instant. A cycle has no maximum, so the merge stops being
/// associative and two replicas that saw the same writes in different orders
/// land on different values — exactly what RNF03 promises cannot happen.
///
/// The rule the correction states is that every write stamps
///
/// ```text
/// t = max(local wall clock, greatest t this replica has observed + one step)
/// ```
///
/// and this is that rule over everything this device has seen. The other half
/// applies it over a single record and lives with the revision, where a version
/// is stamped no earlier than one step past the version it was derived from.
/// The two compose, because a maximum of maxima is a maximum.
///
/// ## What is different here from the node's own
///
/// Two things, and both come from this being a device rather than a server.
///
/// The floor is persisted. The node's clock holds it in memory and argues that
/// a restart is survivable because the per-record floor still holds; a phone is
/// restarted far more often than a node, and it authors operations that other
/// replicas will order against. So the greatest observed instant goes through
/// [HybridClockStore], and a fresh launch resumes from it rather than beginning
/// as though it had observed nothing.
///
/// The wall clock is coarser in a browser. `DateTime.now()` is a JavaScript
/// `Date` there and carries milliseconds, so a thousand writes inside one
/// millisecond all read the same instant. The rule still holds: the step is
/// what makes each one later than the last, and it is why the clock is a
/// maximum and not merely a reading.
library;

import 'dart:async';

/// The granularity every replicated timestamp is held at.
///
/// It is a microsecond because that is what the node's `timestamptz` stores. A
/// value stamped finer would not survive a write followed by a read, and two
/// writes the database cannot tell apart would compare unequal here and equal
/// there — which is the sort of difference a reconciler decides a conflict by.
///
/// Dart's [DateTime] is itself microsecond-resolution, so nothing is truncated
/// on the way in; the constant is the size of the step the rule adds.
const Duration clockResolution = Duration(microseconds: 1);

/// How far ahead of this device's wall clock an observed instant may be and
/// still be adopted.
///
/// Without a ceiling, one peer whose clock is a year fast would push this
/// device a year into the future and keep it there: everything stamped
/// afterwards would be ahead of real time, and every tie against a correctly
/// stamped write would go to whichever record had been poisoned.
///
/// Refusing the observation is safe for the same reason a restart is: the edge
/// that must point forwards is the one between two versions of a record, and
/// the per-record floor holds it whatever this clock adopted.
const Duration maxClockDrift = Duration(minutes: 5);

/// Where the clock's floor survives a restart.
///
/// It is a port, and the implementation is the local database — the floor is
/// device state like the device identifier, and phase 3 gives it a row. It is
/// asynchronous because a database is, and the clock is not: a stamp happens in
/// the middle of authoring an operation and cannot await anything, so the floor
/// is read once at startup and written behind the stamp.
abstract interface class HybridClockStore {
  /// The greatest instant this device had observed when it was last running,
  /// or `null` if it has never run.
  Future<DateTime?> load();

  /// Records [instant] as the floor to resume from.
  Future<void> save(DateTime instant);
}

/// The device-wide hybrid logical clock.
///
/// Build it with [HybridClock.restore] wherever a floor may have been saved,
/// which is everywhere but a test.
final class HybridClock {
  /// A clock that has observed [observed], reading [wall] for its physical
  /// half and persisting its floor to [store].
  ///
  /// [wall] is injected rather than called directly, so that a test can drive
  /// the clock backwards — the condition this type exists for, and one a real
  /// machine offers on nobody's schedule.
  HybridClock({
    DateTime Function()? wall,
    HybridClockStore? store,
    void Function(Object error, StackTrace stackTrace)? onStoreError,
    DateTime? observed,
  }) : _wall = wall ?? DateTime.now,
       _store = store ?? const _NoStore(),
       _onStoreError = onStoreError ?? _ignore,
       _observed = observed?.toUtc() ?? _epoch;

  /// A clock resuming from the floor [store] holds.
  ///
  /// A device whose floor is missing — a first launch, or a store that has just
  /// been cleared — starts from its wall clock, which is what a device that has
  /// observed nothing should stamp.
  static Future<HybridClock> restore({
    required HybridClockStore store,
    DateTime Function()? wall,
    void Function(Object error, StackTrace stackTrace)? onStoreError,
  }) async {
    final floor = await store.load();

    return HybridClock(
      wall: wall,
      store: store,
      onStoreError: onStoreError,
      observed: floor,
    );
  }

  static final DateTime _epoch = DateTime.fromMicrosecondsSinceEpoch(
    0,
    isUtc: true,
  );

  static void _ignore(Object error, StackTrace stackTrace) {}

  final DateTime Function() _wall;
  final HybridClockStore _store;
  final void Function(Object error, StackTrace stackTrace) _onStoreError;

  DateTime _observed;
  bool _writing = false;
  bool _pending = false;

  /// The greatest instant this clock has stamped or adopted.
  ///
  /// It is a reading and not a stamp: it advances nothing, and two calls with
  /// no write between them return the same value. What it is for is diagnosis —
  /// a device whose observed instant is far ahead of its wall clock is a device
  /// that met a peer with a broken one.
  DateTime get observed => _observed;

  /// Stamps a write made on this device.
  ///
  /// The instant returned is strictly greater than every instant this clock has
  /// returned or observed, so two writes never carry the same one and a write
  /// made after seeing a peer's is stamped after it.
  ///
  /// It is in UTC, because the value travels: it is written to the local
  /// database, rendered onto the wire, and compared against instants stamped on
  /// other devices in other zones.
  DateTime now() {
    final reading = _wall().toUtc();
    final floor = _observed.add(clockResolution);

    _observed = reading.isBefore(floor) ? floor : reading;
    _persist();

    return _observed;
  }

  /// Folds an instant this device has seen into the clock, and reports whether
  /// it was adopted.
  ///
  /// The reconciler calls it for every operation it ingests, and it is what
  /// makes the rule hold across the federation rather than only on this device:
  /// a local write that follows a remote one has to be stamped after it, and
  /// the only way this device can know what "after" is is to have been told.
  ///
  /// A `false` is not a rejection of the operation. It says the instant is
  /// further ahead of this device's wall clock than [maxClockDrift], so the
  /// clock did not follow it there; the operation is applied exactly as any
  /// other, and what the caller does with the answer is report it, because a
  /// peer that far off is a fault somebody has to see.
  bool observe(DateTime at) {
    final seen = at.toUtc();

    if (seen.isAfter(_wall().toUtc().add(maxClockDrift))) {
      return false;
    }

    if (seen.isAfter(_observed)) {
      _observed = seen;
      _persist();
    }

    return true;
  }

  /// Writes the floor, behind whatever asked for it.
  ///
  /// At most one write is in flight, and a stamp made while one is running
  /// marks the floor dirty rather than queueing: what has to survive a restart
  /// is the greatest instant, and every value between it and the one being
  /// written is already covered by it. A burst of annotations therefore costs
  /// two writes rather than one per annotation.
  void _persist() {
    _pending = true;

    if (_writing) {
      return;
    }

    _writing = true;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    while (_pending) {
      _pending = false;

      try {
        await _store.save(_observed);
      } catch (error, stackTrace) {
        // A floor that could not be written is a device that will resume from
        // an older one, which the per-record floor still corrects. It is worth
        // reporting and it is not worth failing a write the reader made.
        _onStoreError(error, stackTrace);
      }
    }

    _writing = false;
  }
}

/// The store a clock built without one uses: it remembers nothing, which is
/// what a clock in a test wants and what the node's own does by design.
final class _NoStore implements HybridClockStore {
  const _NoStore();

  @override
  Future<DateTime?> load() async => null;

  @override
  Future<void> save(DateTime instant) async {}
}

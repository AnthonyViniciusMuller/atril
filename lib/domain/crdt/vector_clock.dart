/// The causal version every replicated record in Atril carries.
///
/// This is the Dart port of
/// [`internal/shared/crdt`](../../../../quire/internal/shared/crdt), and it is
/// a port rather than an interpretation on purpose. A reader annotates on a
/// train and another device of theirs annotates the same book somewhere else;
/// when the two histories meet there is no authority to ask which write came
/// first, so the answer has to be derivable from the data, identically on
/// every replica. A client that merged differently from the node would
/// converge differently — which is to say it would not converge.
///
/// A clock records, for each device, how many events of that device this
/// replica has observed. Comparing two of them says whether one write causally
/// precedes the other or whether the two are genuinely concurrent; only the
/// concurrent case needs the tie-break, and that lives with the revision.
///
/// Clocks are values and every operation returns a new one. A replicated
/// structure that can be aliased by accident is a structure that converges by
/// accident.
library;

import 'ordering.dart';

/// The events one replica has observed from each device, counted.
///
/// A device absent from the clock and a device counted at zero are the same
/// history — no event of that device has been observed. Every operation here
/// preserves that equivalence, so the same history always compares equal,
/// hashes the same and encodes to the same bytes however it was built. Keeping
/// it is what [VectorClock.of] and [VectorClock.fromJson] compact for.
///
/// The key is a device identifier in its canonical lowercase text, which is
/// what the node counts a clock entry under and what a `jsonb` object can hold
/// as a key.
final class VectorClock {
  const VectorClock._(this._counters);

  /// The clock that has observed nothing. It is the identity of [merge] and
  /// the version of a record nothing has stamped.
  static const VectorClock empty = VectorClock._(<String, int>{});

  /// The clock counting [counters], with the entries at zero dropped.
  ///
  /// A negative counter is refused rather than dropped: a count of events is
  /// never negative, so one that appears is a decoding fault or an arithmetic
  /// one, and a clock that silently swallowed it would compare equal to a
  /// history it is not.
  factory VectorClock.of(Map<String, int> counters) {
    final compacted = <String, int>{};

    for (final entry in counters.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'a vector clock counter is never negative',
        );
      }

      if (entry.value > 0) {
        compacted[entry.key] = entry.value;
      }
    }

    return VectorClock._(compacted);
  }

  /// The clock decoded from what a database column or the wire holds.
  ///
  /// It throws a [FormatException] on a value that is not an integer, and the
  /// caller — a DAO or a mapper — is what turns that into an
  /// [AppException](../../utils/errors.dart). The decoding happens at a layer
  /// boundary, so the boundary is where it becomes a `Result`.
  factory VectorClock.fromJson(Map<String, Object?> json) {
    final counters = <String, int>{};

    for (final entry in json.entries) {
      final counter = entry.value;

      if (counter is! int) {
        throw FormatException(
          'the vector clock entry for ${entry.key} is not an integer',
          json,
        );
      }

      counters[entry.key] = counter;
    }

    return VectorClock.of(counters);
  }

  final Map<String, int> _counters;

  /// The events observed from [device], which is zero for a device this clock
  /// has never seen.
  int operator [](String device) => _counters[device] ?? 0;

  /// The devices with at least one observed event.
  ///
  /// The order is unspecified. [toJson] and [toString] are what sort, because
  /// they are what has to be stable.
  Iterable<String> get devices => _counters.keys;

  /// How many devices have at least one observed event.
  int get length => _counters.length;

  /// Whether the clock has observed no event at all.
  bool get isEmpty => _counters.isEmpty;

  /// Whether the clock has observed anything.
  bool get isNotEmpty => _counters.isNotEmpty;

  /// This clock with one more event observed from [device]. It is what a
  /// device calls when it authors a write.
  VectorClock tick(String device) =>
      VectorClock._(<String, int>{..._counters, device: this[device] + 1});

  /// The least upper bound of the two clocks: for each device, the larger of
  /// the two counters.
  ///
  /// This is the join of the semilattice the whole design rests on. Being a
  /// pointwise maximum it is idempotent, commutative and associative, which is
  /// exactly what lets replicas exchange state in any order, more than once,
  /// and still land on the same history. `vector_clock_laws_test.dart` is the
  /// proof, over the same laws the node's own property tests check.
  VectorClock merge(VectorClock other) {
    final merged = <String, int>{..._counters};

    for (final entry in other._counters.entries) {
      if (entry.value > (merged[entry.key] ?? 0)) {
        merged[entry.key] = entry.value;
      }
    }

    return VectorClock._(merged);
  }

  /// The causal relation between this clock and [other].
  ///
  /// Both clocks are walked once, recording whether any device is behind and
  /// whether any is ahead. Behind and ahead at once is what concurrency means:
  /// each replica observed something the other did not.
  Ordering compare(VectorClock other) {
    var behind = false;
    var ahead = false;

    for (final entry in _counters.entries) {
      final theirs = other[entry.key];

      if (entry.value < theirs) {
        behind = true;
      } else if (entry.value > theirs) {
        ahead = true;
      }
    }

    for (final entry in other._counters.entries) {
      // A device present in both was already accounted for above, and the
      // canonical form means a device present here is counted above zero.
      if (!_counters.containsKey(entry.key)) {
        behind = true;
      }
    }

    return switch ((behind, ahead)) {
      (true, true) => Ordering.concurrent,
      (true, false) => Ordering.before,
      (false, true) => Ordering.after,
      (false, false) => Ordering.equal,
    };
  }

  /// Whether every event in this clock is also in [other], and [other] holds at
  /// least one more.
  bool happensBefore(VectorClock other) => compare(other) == Ordering.before;

  /// [happensBefore] seen from the other side.
  bool happensAfter(VectorClock other) => compare(other) == Ordering.after;

  /// Whether neither clock causally precedes the other, which is the case the
  /// reconciler has to break a tie for.
  bool isConcurrentWith(VectorClock other) =>
      compare(other) == Ordering.concurrent;

  /// Whether this clock has observed everything [other] has, whether or not it
  /// has observed more.
  ///
  /// It is the question the sync loop asks about a record a node offered: is
  /// there anything here this device has not already seen?
  bool dominates(VectorClock other) => switch (compare(other)) {
    Ordering.after || Ordering.equal => true,
    Ordering.before || Ordering.concurrent => false,
  };

  /// The clock as a JSON object, its devices in a stable order.
  ///
  /// The sort is not decoration. `dart:convert` encodes a map in insertion
  /// order where Go's `encoding/json` sorts keys, so without it the same
  /// history would produce different bytes on the two sides and two stored
  /// clocks could not be compared without being decoded.
  Map<String, int> toJson() {
    final devices = _counters.keys.toList()..sort();

    return <String, int>{
      for (final device in devices) device: _counters[device]!,
    };
  }

  /// Whether both clocks describe the same causal history.
  @override
  bool operator ==(Object other) {
    if (other is! VectorClock || other._counters.length != _counters.length) {
      return false;
    }

    for (final entry in _counters.entries) {
      if (other._counters[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  /// The hash of the canonical form.
  ///
  /// Order-independent, because a map has no order and two clocks built in
  /// different orders are the same history. [Object.hashAllUnordered] over the
  /// entries is what says so.
  @override
  int get hashCode => Object.hashAllUnordered(<int>[
    for (final entry in _counters.entries) Object.hash(entry.key, entry.value),
  ]);

  /// The clock with its devices in a stable order, so that a log line or a
  /// failing test is readable and diffable.
  @override
  String toString() {
    final devices = _counters.keys.toList()..sort();

    return '{${devices.map((device) => '$device:${_counters[device]}').join(' ')}}';
  }
}

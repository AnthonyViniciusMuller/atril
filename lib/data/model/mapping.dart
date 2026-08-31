/// What the mappers in this directory share: how they name a failure, and how
/// they read the three values every replicable record carries.
///
/// The layer exists to keep one rule true — **a view model never sees a
/// generated message**. `quire.v1.Ebook` becomes `domain.Ebook` here and
/// nowhere else, so a `Timestamp` or an `Int64` reaching a widget is this
/// directory having been bypassed rather than a type that leaked.
///
/// The functions are named in one direction each: `xOf` reads the wire and
/// answers with a domain value, and `wireX` does the reverse. Most of them
/// exist only in the first direction, and that is not an omission — Atril
/// never sends a replicable record. Every change to one is authored as an
/// operation locally and pushed, so the only things this app serializes are
/// operations, credentials and the calls that are not writes to a record at
/// all.
///
/// A malformed value is a failure and not an assertion. What arrives here came
/// from a node, so a clock counter that is not a count is data this device
/// cannot use rather than a mistake in this program, and it is reported in the
/// vocabulary every layer speaks.
library;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

import '../../domain/crdt/revision.dart';
import '../../domain/crdt/vector_clock.dart';
import '../../utils/errors.dart';
import '../services/api/generated/quire/v1/common.pb.dart' as pb;

/// The operation a decoding failure is reported under.
const String opMapping = 'data/model: decode';

/// The stable code of a value the wire carried and this device cannot read.
const String codeMalformedValue = 'malformed_value';

/// The causal version, as a domain clock.
///
/// The rule this applies is [VectorClock.of]'s and not this file's: entries at
/// zero are dropped, so a device absent from the clock and a device counted at
/// zero stay the same history. What is done here is the one thing the domain
/// type cannot do without importing a wire type — turning an `Int64` into an
/// `int`, which a microsecond epoch and a clock counter both survive.
VectorClock vectorClockOf(pb.VectorClock clock) {
  final counters = <String, int>{};

  for (final entry in clock.entries.entries) {
    final counter = entry.value.toInt();

    if (counter < 0) {
      throw malformed(
        'vector_clock',
        'the counter of ${entry.key} is not a count of events',
      );
    }

    counters[entry.key] = counter;
  }

  return VectorClock.of(counters);
}

/// The clock, as the wire carries it.
pb.VectorClock wireVectorClock(VectorClock clock) => pb.VectorClock(
  entries: <MapEntry<String, Int64>>[
    for (final device in clock.devices) MapEntry(device, Int64(clock[device])),
  ],
);

/// The instant a write was stamped at, on the hybrid clock C01 describes.
///
/// It is deliberately not a wall clock and the contract spells the difference
/// with a message of its own, so this is the only place a `HybridTimestamp`
/// becomes a `DateTime` — and the `DateTime` it becomes is UTC, because a
/// local one would invite being rendered as the time of day.
DateTime instantOf(pb.HybridTimestamp stamp) =>
    DateTime.fromMicrosecondsSinceEpoch(stamp.unixMicros.toInt(), isUtc: true);

/// The instant, as the wire carries it.
pb.HybridTimestamp wireInstant(DateTime at) =>
    pb.HybridTimestamp(unixMicros: Int64(at.toUtc().microsecondsSinceEpoch));

/// A wall clock instant — when a row was created, when a credential expires.
///
/// The contrast with [instantOf] is the point: these are times of day and are
/// shown to a reader, and nothing orders a merge by one.
DateTime wallClockOf(Timestamp stamp) => stamp.toDateTime(toLocal: false);

/// The instant, as the wire carries a time of day.
Timestamp wireWallClock(DateTime at) => Timestamp.fromDateTime(at.toUtc());

/// The replication metadata of a record with more than one writer.
Revision revisionOf(pb.Revision revision) => Revision(
  vectorClock: vectorClockOf(revision.vectorClock),
  updatedAt: instantOf(revision.updatedAt),
  deviceId: revision.deviceId.toLowerCase(),
  deleted: revision.deleted,
);

/// The same, for the one record that has exactly one writer (C05).
Version versionOf(pb.VectorClock clock, pb.HybridTimestamp updatedAt) =>
    Version(vectorClock: vectorClockOf(clock), updatedAt: instantOf(updatedAt));

/// The failure raised for a value this device cannot read.
AppException malformed(String field, String reason) => AppException(
  kind: ErrorKind.invalidArgument,
  message: 'the node sent a $field this device cannot read: $reason',
  code: codeMalformedValue,
  op: opMapping,
).withField(field, reason);

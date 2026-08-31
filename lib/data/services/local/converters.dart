/// The two values this schema stores in a column sqlite has no type for.
///
/// Both are written the way the wire writes them rather than the way sqlite
/// would prefer, and for the same reason: what is stored here is compared
/// against what another replica stored, so a representation that loses
/// anything loses it on one side of a merge.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/crdt/vector_clock.dart';

/// An instant, as microseconds since the Unix epoch.
///
/// It is an integer and not a string, and not drift's own `DateTime` support
/// either. Those store either seconds — which collapses two writes the hybrid
/// clock deliberately stepped one microsecond apart — or a textual form whose
/// comparison depends on how it was rendered. Microseconds are what
/// `HybridTimestamp.unix_micros` carries on the wire and what the node's
/// `timestamptz` holds, so this column, that field and that column are the same
/// number.
///
/// Every instant comes back in UTC. The value travels between devices in
/// different zones, and a local one would compare against them by accident.
final class InstantConverter extends TypeConverter<DateTime, int> {
  /// The converter, which holds nothing.
  const InstantConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().microsecondsSinceEpoch;
}

/// A vector clock, as the JSON object the node stores in `jsonb` and the
/// contract carries in `VectorClock.entries`.
///
/// [VectorClock.toJson] sorts its devices, so the same causal history always
/// produces the same bytes here — which is what lets a stored clock be compared
/// as text when a comparison is cheaper than a decode, and what keeps a diff of
/// two databases readable.
///
/// A column holding something that is not an object of integers throws a
/// [FormatException] here, and the DAO above it is what turns that into an
/// `AppException`: decoding happens at a layer boundary, and the boundary is
/// where a failure becomes a `Result`.
final class VectorClockConverter extends TypeConverter<VectorClock, String> {
  /// The converter, which holds nothing.
  const VectorClockConverter();

  @override
  VectorClock fromSql(String fromDb) {
    final decoded = json.decode(fromDb);

    if (decoded is! Map<String, Object?>) {
      throw FormatException('the vector clock is not an object', fromDb);
    }

    return VectorClock.fromJson(decoded);
  }

  @override
  String toSql(VectorClock value) => json.encode(value.toJson());
}

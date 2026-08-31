/// The check constraints more than one table spells.
library;

/// `CHECK (column IN ('a', 'b'))`, over a closed set of values.
///
/// The sets in this schema are the node's own — the formats, the kinds of
/// grouping, the kinds of mark, the replicable entities — and they are closed
/// in SQL for the reason the node's schema gives: a value nothing can name
/// would otherwise be stored, replicated and read by a reconciler that skips
/// it, and nothing would say so.
String oneOf(String column, Iterable<String> values) =>
    'CHECK ($column IN (${values.map((value) => "'$value'").join(', ')}))';

/// The causal relation between two vector clocks.
///
/// It is `crdt.Ordering` on the node, value for value. The reconciler in
/// `data/services/sync` reads it exactly as the Go one does: three of the four
/// answers decide the merge on their own, and only the fourth needs the
/// tie-break the revision carries.
library;

/// The relation two vector clocks stand in. They stand in exactly one of them.
enum Ordering {
  /// Both clocks observed exactly the same events. Neither replica knows
  /// anything the other does not.
  equal('equal'),

  /// The receiver happened before the argument: every event it observed the
  /// argument observed too, and the argument observed more.
  before('before'),

  /// [before] seen from the other side.
  after('after'),

  /// Each clock observed at least one event the other did not.
  ///
  /// This is the conflict reconciliation exists to resolve, and the only case
  /// where a deterministic tie-break is needed.
  concurrent('concurrent');

  const Ordering(this.label);

  /// The name of the relation, for a log line and a failing test.
  final String label;

  /// The relation seen from the other operand, so that
  /// `a.compare(b) == b.compare(a).reversed` always holds.
  Ordering get reversed => switch (this) {
    Ordering.before => Ordering.after,
    Ordering.after => Ordering.before,
    Ordering.equal || Ordering.concurrent => this,
  };

  @override
  String toString() => label;
}

/// The live half of synchronization, in the one shape both transports have.
///
/// There are two implementations and they are not variations on a theme: on the
/// five native targets a single bidirectional `Sync` stream carries the pushes,
/// the acknowledgements and the deliveries, and in a browser the same work is
/// three calls — `PushOperations`, `WatchOperations` and `PullOperations` —
/// because gRPC-Web carries a unary call and a server stream and neither of the
/// other two. D10 records what that costs; this is where it stops costing
/// anything above `data/services`.
///
/// What they share is exactly this: a device opens one, hands over what it owes
/// through it, and closes it. The scheduler above knows nothing else about
/// either, which is what lets the platform question be answered once, where the
/// graph is composed, rather than at every call site.
library;

/// One open connection to a node's log.
abstract interface class SyncChannel {
  /// Whether the channel is open.
  bool get isOpen;

  /// Opens it, and answers with a future that completes when it ends.
  ///
  /// The future carries whatever ended it, which is what lets the scheduler
  /// tell a node that hung up from one that was never reachable.
  Future<void> open();

  /// Hands over what this device owes, if the channel is open.
  ///
  /// It is what the scheduler calls when a change has been authored. On the
  /// stream it is a message; in a browser it is a unary push. Neither promises
  /// the whole outbox goes in one call.
  Future<void> offer();

  /// Closes it. A channel that is not open is left alone.
  Future<void> close();
}

/// A reader, as their origin server knows them.
///
/// Every field here is answered by exactly one node — the reader's origin
/// server (RN08) — and a node that merely replicates the reader holds the row
/// without an address and without a password (C03). The address is the one
/// field that is personal data rather than identity, which is why it is
/// absent from every reply but the reader's own (RN09).
library;

/// The reader.
final class User {
  /// The reader, as a node reports them.
  const User({
    required this.id,
    required this.localName,
    required this.displayName,
    required this.originServerDomain,
    required this.federatedId,
    required this.createdAt,
    this.email,
  });

  /// The identifier at the origin node.
  final String id;

  /// The first half of the federated identifier, constrained by the node to
  /// `^[a-z0-9]([a-z0-9._-]{0,62}[a-z0-9])?$`.
  final String localName;

  /// What the reader calls themselves, and the only name meant to be shown.
  final String displayName;

  /// The domain of the node that authenticates this reader.
  final String originServerDomain;

  /// `@local_name:domain`, assembled by the node so that every client renders
  /// the identifier the same way.
  final String federatedId;

  /// When the account was created, on a wall clock.
  final DateTime createdAt;

  /// The address recovery is sent to. Absent unless this reader is the caller.
  final String? email;

  @override
  String toString() => 'User($federatedId)';
}

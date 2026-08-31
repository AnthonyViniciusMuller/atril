/// The nodes a reader knows, what each publishes about itself, and which of
/// them may hold a copy of their data.
///
/// RN03 gives the reader control over the servers used for synchronization,
/// and these three types are what that control is exercised over: a
/// descriptor is what discovery found, a [KnownServer] is a descriptor the
/// reader decided to keep, and a [ReplicaAuthorization] is the permission that
/// makes a kept node a replica.
library;

/// What a node publishes about itself, as discovery returns it.
final class ServerDescriptor {
  /// The descriptor a lookup answered with.
  const ServerDescriptor({
    required this.domain,
    required this.baseUrl,
    this.jwksUri,
    this.certificateFingerprint,
    this.grpcAuthority,
  });

  /// The authority the lookup was addressed to, and the second half of every
  /// federated identifier hosted there.
  final String domain;

  /// Where the node answers. Separate from [domain] on purpose: a node may be
  /// identified by one host and served from another.
  final String baseUrl;

  /// Where it publishes the keys its tokens are signed with.
  final String? jwksUri;

  /// `spki-sha256:<base64>` — a digest of the public key and not of the
  /// certificate (C12).
  ///
  /// This device never presents one and never checks one: it is what a *peer*
  /// pins for node-to-node mTLS. It is held so that a reader authorizing a
  /// replica can see what they are authorizing, and notice when it rotates.
  final String? certificateFingerprint;

  /// The authority to dial for gRPC, as `host:port`.
  ///
  /// Absent on a node whose document publishes none, which is a node this
  /// device can record and cannot dial. It is what the five native targets
  /// dial; a browser dials the gateway the environment names, because this is
  /// the address a peer dials for replication and a browser is not a peer.
  final String? grpcAuthority;

  @override
  String toString() => 'ServerDescriptor($domain at $baseUrl)';
}

/// A node in this reader's catalogue.
final class KnownServer {
  /// The node, as the catalogue holds it.
  const KnownServer({
    required this.id,
    required this.descriptor,
    required this.isOrigin,
    required this.active,
    this.discoveredAt,
  });

  /// The identifier the node knows itself by.
  final String id;

  /// What discovery learned.
  final ServerDescriptor descriptor;

  /// Whether this is the node the reader is signed in at. At most one row may
  /// claim it.
  final bool isOrigin;

  /// Whether the node takes part in replication. Clearing it stops the traffic
  /// without losing what discovery already learned.
  final bool active;

  /// When the document was last read. A key that has rotated is found by
  /// asking again, and this is what says how long ago that was.
  final DateTime? discoveredAt;

  @override
  String toString() =>
      'KnownServer(${descriptor.domain}${isOrigin ? ', origin' : ''})';
}

/// A reader's permission for one node to hold a copy of their data.
final class ReplicaAuthorization {
  /// The permission, as the origin node records it.
  const ReplicaAuthorization({
    required this.id,
    required this.serverId,
    required this.serverDomain,
    required this.authorizedAt,
    required this.replicatesFiles,
    required this.active,
  });

  /// The permission's own identifier.
  final String id;

  /// The node it was granted to.
  final String serverId;

  /// That node's domain, carried alongside so that a screen can name it
  /// without a second call.
  final String serverDomain;

  /// When it was granted.
  final DateTime authorizedAt;

  /// Whether it covers the e-book files as well as the metadata. Metadata
  /// without the files is the cheap replica a reader is most likely to want on
  /// a node they do not own.
  final bool replicatesFiles;

  /// False once it has been withdrawn. The record stays, because it is what
  /// explains why a peer still holds data: revoking stops the replication, it
  /// does not reach into another operator's database.
  final bool active;

  @override
  String toString() =>
      'ReplicaAuthorization($serverDomain'
      '${replicatesFiles ? ', with files' : ''}'
      '${active ? '' : ', revoked'})';
}

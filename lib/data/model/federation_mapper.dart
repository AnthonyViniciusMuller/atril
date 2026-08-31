/// The federation half of the contract, as domain values: what a node
/// publishes about itself, the catalogue a reader keeps, and the permissions
/// they grant over it.
library;

import '../../domain/models/server.dart';
import '../services/api/generated/quire/v1/federation.pb.dart' as pb;
import 'mapping.dart';

/// What a node publishes about itself.
///
/// Three of the five fields are `optional` in the contract and are read as
/// absent rather than empty, because each absence means something: a node with
/// no `grpc` authority is one this device can record and cannot dial, and a
/// node with no fingerprint is one no peer can pin.
ServerDescriptor descriptorOf(pb.ServerDescriptor descriptor) =>
    ServerDescriptor(
      domain: descriptor.domain,
      baseUrl: descriptor.baseUrl,
      jwksUri: descriptor.hasJwksUri() ? descriptor.jwksUri : null,
      certificateFingerprint: descriptor.hasCertificateFingerprint()
          ? descriptor.certificateFingerprint
          : null,
      grpcAuthority: descriptor.hasGrpc() ? descriptor.grpc : null,
    );

/// A node in the reader's catalogue.
KnownServer knownServerOf(pb.Server server) => KnownServer(
  id: server.id.toLowerCase(),
  descriptor: descriptorOf(server.descriptor),
  isOrigin: server.isLocal,
  active: server.active,
  discoveredAt: server.hasDiscoveredAt()
      ? wallClockOf(server.discoveredAt)
      : null,
);

/// A permission for one node to hold a copy of the reader's data.
ReplicaAuthorization replicaAuthorizationOf(pb.ReplicaAuthorization grant) =>
    ReplicaAuthorization(
      id: grant.id.toLowerCase(),
      serverId: grant.serverId.toLowerCase(),
      serverDomain: grant.serverDomain,
      authorizedAt: wallClockOf(grant.authorizedAt),
      replicatesFiles: grant.replicatesFiles,
      active: grant.active,
    );

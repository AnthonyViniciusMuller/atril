/// A node that answers `FederationService`, for the tests that need a real
/// socket.
///
/// The repositories of phase 12 read from the node and hold nothing, so a fake
/// *repository* would prove nothing about them — what is worth testing is that
/// the right call is made, that what came back is what the screen is given,
/// and that the local catalogue was brought into step. So this is the node,
/// small enough to assert against: a catalogue in a map, a refusal a test can
/// arm, and a record of every request it was sent.
library;

import 'package:atril/data/services/api/generated/quire/v1/federation.pbgrpc.dart';
import 'package:grpc/grpc.dart' hide Server;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

/// The identifier this node calls itself by.
const String fakeLocalServerId = '44444444-4444-4444-8444-444444444444';

/// The domain the reader of these tests is hosted at.
const String fakeOriginDomain = 'quire-a.example';

/// A node that keeps a catalogue in memory.
final class FakeFederationService extends FederationServiceBase {
  /// A node whose catalogue already holds the reader's own entry.
  FakeFederationService() {
    catalogue[fakeOriginDomain] = Server(
      id: fakeLocalServerId,
      isLocal: true,
      active: true,
      discoveredAt: Timestamp.fromDateTime(DateTime.utc(2026)),
      descriptor: ServerDescriptor(
        domain: fakeOriginDomain,
        baseUrl: 'https://$fakeOriginDomain',
        grpc: '$fakeOriginDomain:9090',
        jwksUri: 'https://$fakeOriginDomain/.well-known/jwks.json',
        certificateFingerprint: 'spki-sha256:AAAA',
      ),
    );
  }

  /// The catalogue, by domain.
  final Map<String, Server> catalogue = <String, Server>{};

  /// What the next call fails with, or `null` to let it answer.
  GrpcError? refusal;

  /// Every domain an addition was asked for, in order.
  final List<String> added = <String>[];

  /// Every update, as `(serverId, active)`.
  final List<(String, bool)> updated = <(String, bool)>[];

  /// Every server a refresh was asked for, in order.
  final List<String> refreshed = <String>[];

  /// Every server a removal was asked for, in order.
  final List<String> removed = <String>[];

  /// Whether the next refresh reports a key that moved.
  bool fingerprintChanges = false;

  /// The identifiers this node hands out, one per record it mints.
  int _minted = 0;

  String _nextId() {
    _minted++;

    return '5555555$_minted-5555-4555-8555-555555555555';
  }

  void _check() {
    final refused = refusal;

    if (refused != null) {
      refusal = null;

      throw refused;
    }
  }

  @override
  Future<DiscoverServerResponse> discoverServer(
    ServiceCall call,
    DiscoverServerRequest request,
  ) async {
    _check();

    return DiscoverServerResponse(
      descriptor: ServerDescriptor(
        domain: request.domain,
        baseUrl: 'https://${request.domain}',
        grpc: '${request.domain}:9090',
      ),
    );
  }

  @override
  Future<AddKnownServerResponse> addKnownServer(
    ServiceCall call,
    AddKnownServerRequest request,
  ) async {
    added.add(request.domain);
    _check();

    if (catalogue.containsKey(request.domain)) {
      throw GrpcError.alreadyExists('that domain is already known');
    }

    final server = Server(
      id: _nextId(),
      isLocal: false,
      active: true,
      discoveredAt: Timestamp.fromDateTime(DateTime.utc(2026, 6)),
      descriptor: ServerDescriptor(
        domain: request.domain,
        baseUrl: 'https://${request.domain}',
        grpc: '${request.domain}:9090',
        certificateFingerprint: 'spki-sha256:BBBB',
      ),
    );

    catalogue[request.domain] = server;

    return AddKnownServerResponse(server: server);
  }

  @override
  Future<GetKnownServerResponse> getKnownServer(
    ServiceCall call,
    GetKnownServerRequest request,
  ) async {
    _check();

    return GetKnownServerResponse(server: _byId(request.serverId));
  }

  @override
  Future<ListKnownServersResponse> listKnownServers(
    ServiceCall call,
    ListKnownServersRequest request,
  ) async {
    listed.add(request.includeInactive);
    _check();

    return ListKnownServersResponse(
      servers: <Server>[
        for (final server in catalogue.values)
          if (request.includeInactive || server.active) server,
      ],
    );
  }

  /// Whether each listing asked for the deactivated nodes, in order.
  final List<bool> listed = <bool>[];

  @override
  Future<UpdateKnownServerResponse> updateKnownServer(
    ServiceCall call,
    UpdateKnownServerRequest request,
  ) async {
    updated.add((request.serverId, request.server.active));
    _check();

    final server = _byId(request.serverId)..active = request.server.active;

    return UpdateKnownServerResponse(server: server);
  }

  @override
  Future<RefreshKnownServerResponse> refreshKnownServer(
    ServiceCall call,
    RefreshKnownServerRequest request,
  ) async {
    refreshed.add(request.serverId);
    _check();

    final server = _byId(request.serverId);

    if (fingerprintChanges) {
      server.descriptor.certificateFingerprint = 'spki-sha256:CCCC';
    }

    return RefreshKnownServerResponse(
      server: server,
      certificateFingerprintChanged: fingerprintChanges,
    );
  }

  @override
  Future<RemoveKnownServerResponse> removeKnownServer(
    ServiceCall call,
    RemoveKnownServerRequest request,
  ) async {
    removed.add(request.serverId);
    _check();

    catalogue.removeWhere(
      (String _, Server server) => server.id == request.serverId,
    );

    return RemoveKnownServerResponse();
  }

  @override
  Future<AuthorizeReplicaResponse> authorizeReplica(
    ServiceCall call,
    AuthorizeReplicaRequest request,
  ) async => throw GrpcError.unimplemented('not this test');

  @override
  Future<RevokeReplicaResponse> revokeReplica(
    ServiceCall call,
    RevokeReplicaRequest request,
  ) async => throw GrpcError.unimplemented('not this test');

  @override
  Future<ListReplicaAuthorizationsResponse> listReplicaAuthorizations(
    ServiceCall call,
    ListReplicaAuthorizationsRequest request,
  ) async => throw GrpcError.unimplemented('not this test');

  @override
  Future<MigrateHomeServerResponse> migrateHomeServer(
    ServiceCall call,
    MigrateHomeServerRequest request,
  ) async => throw GrpcError.unimplemented('not this test');

  Server _byId(String id) {
    for (final server in catalogue.values) {
      if (server.id == id) {
        return server;
      }
    }

    throw GrpcError.notFound('no such server');
  }
}

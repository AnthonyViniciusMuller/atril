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

import 'package:atril/data/services/api/generated/quire/v1/auth.pb.dart'
    as auth;
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

  /// The replica permissions this node holds, by the server they name.
  final Map<String, ReplicaAuthorization> grants =
      <String, ReplicaAuthorization>{};

  /// Whether each listing of the permissions asked for the revoked ones.
  final List<bool> listedGrants = <bool>[];

  /// Every grant, as `(serverId, replicatesFiles)`.
  final List<(String, bool)> authorized = <(String, bool)>[];

  /// Every server a withdrawal was asked for, in order.
  final List<String> revoked = <String>[];

  @override
  Future<AuthorizeReplicaResponse> authorizeReplica(
    ServiceCall call,
    AuthorizeReplicaRequest request,
  ) async {
    authorized.add((request.serverId, request.replicatesFiles));
    _check();

    final grant = ReplicaAuthorization(
      id: _nextId(),
      serverId: request.serverId,
      serverDomain: _byId(request.serverId).descriptor.domain,
      authorizedAt: Timestamp.fromDateTime(DateTime.utc(2026, 9)),
      replicatesFiles: request.replicatesFiles,
      active: true,
    );

    grants[request.serverId] = grant;

    return AuthorizeReplicaResponse(authorization: grant);
  }

  @override
  Future<RevokeReplicaResponse> revokeReplica(
    ServiceCall call,
    RevokeReplicaRequest request,
  ) async {
    revoked.add(request.serverId);
    _check();

    // Deactivated and kept, as the node does it: the record that a permission
    // once existed is what explains a peer that still holds data.
    grants[request.serverId]?.active = false;

    return RevokeReplicaResponse();
  }

  @override
  Future<ListReplicaAuthorizationsResponse> listReplicaAuthorizations(
    ServiceCall call,
    ListReplicaAuthorizationsRequest request,
  ) async {
    listedGrants.add(request.includeInactive);
    _check();

    return ListReplicaAuthorizationsResponse(
      authorizations: <ReplicaAuthorization>[
        for (final grant in grants.values)
          if (request.includeInactive || grant.active) grant,
      ],
    );
  }

  /// Every migration this node was sent, in order.
  final List<MigrateHomeServerRequest> migrations =
      <MigrateHomeServerRequest>[];

  /// The credential this node issues to a reader who arrives.
  static const String migratedAccessToken = 'migrated-access';

  /// The domain this node calls itself by when it takes a reader in.
  ///
  /// It is deliberately not [fakeOriginDomain]: a migration is a move to
  /// somewhere else, and a test whose two nodes shared a domain could not tell
  /// the reader's identifier having changed from its not having.
  static const String migratedDomain = 'quire-b.example';

  @override
  Future<MigrateHomeServerResponse> migrateHomeServer(
    ServiceCall call,
    MigrateHomeServerRequest request,
  ) async {
    migrations.add(request);
    _check();

    if (request.devices.isEmpty) {
      throw GrpcError.invalidArgument('a migration carries its devices');
    }

    // The wall clock, because a session holder compares an expiry against the
    // time of day: a fixed instant would be a credential already expired on
    // any day but one.
    final now = DateTime.now().toUtc();

    return MigrateHomeServerResponse(
      user: auth.User(
        id: '66666666-6666-4666-8666-666666666666',
        localName: request.localName,
        displayName: request.displayName,
        originServerDomain: migratedDomain,
        federatedId: '@${request.localName}:$migratedDomain',
        email: request.email,
        createdAt: Timestamp.fromDateTime(now),
      ),
      // Adopted with the identifiers they arrived with, which is the whole of
      // C11 and the one thing a client has to be able to check.
      devices: request.devices,
      session: auth.Session(
        accessToken: migratedAccessToken,
        accessTokenExpiresAt: Timestamp.fromDateTime(
          now.add(const Duration(minutes: 5)),
        ),
        refreshToken: 'migrated-refresh',
        refreshTokenExpiresAt: Timestamp.fromDateTime(
          now.add(const Duration(days: 30)),
        ),
      ),
    );
  }

  Server _byId(String id) {
    for (final server in catalogue.values) {
      if (server.id == id) {
        return server;
      }
    }

    throw GrpcError.notFound('no such server');
  }
}

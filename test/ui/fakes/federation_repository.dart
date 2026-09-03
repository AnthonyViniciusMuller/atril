/// A [FederationRepository] that answers from memory.
library;

import 'dart:async';

import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/data/services/api/federation_api.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/result.dart';

/// A [FederationRepository] that answers from memory.
///
/// It answers with a `Result` and holds no stream, because the repository it
/// stands in for holds none either: the catalogue is what the node knows, so
/// every screen above it asks and is answered once.
final class FakeFederationRepository implements FederationRepository {
  /// The catalogue this node reports, which a test sets.
  List<KnownServer> catalogue = <KnownServer>[];

  /// What the next call fails with, or `null` to let it answer.
  Exception? refusal;

  /// How many times the catalogue was read.
  int reads = 0;

  /// Every domain an addition was asked for, in order.
  final List<String> added = <String>[];

  /// Every change to the switch, as `(serverId, active)`.
  final List<(String, bool)> switched = <(String, bool)>[];

  /// Every server a refresh was asked for, in order.
  final List<String> refreshed = <String>[];

  /// Every server a removal was asked for, in order.
  final List<String> forgotten = <String>[];

  /// Whether the next refresh reports a key that moved.
  bool fingerprintChanges = false;

  @override
  Future<Result<List<KnownServer>>> knownServers() async {
    reads++;

    final refused = refusal;

    return refused == null
        ? Result<List<KnownServer>>.ok(catalogue)
        : Result<List<KnownServer>>.error(refused);
  }

  @override
  Future<Result<KnownServer>> addServer(String domain) async {
    added.add(domain);

    final refused = refusal;

    if (refused != null) {
      return Result<KnownServer>.error(refused);
    }

    final server = KnownServer(
      id: 'added',
      descriptor: ServerDescriptor(
        domain: domain,
        baseUrl: 'https://$domain',
        grpcAuthority: '$domain:9090',
      ),
      isOrigin: false,
      active: true,
    );

    catalogue = <KnownServer>[...catalogue, server];

    return Result<KnownServer>.ok(server);
  }

  @override
  Future<Result<KnownServer>> setActive({
    required String serverId,
    required bool active,
  }) async {
    switched.add((serverId, active));

    final refused = refusal;

    if (refused != null) {
      return Result<KnownServer>.error(refused);
    }

    return Result<KnownServer>.ok(_byId(serverId));
  }

  @override
  Future<Result<ServerRefresh>> refreshServer(String serverId) async {
    refreshed.add(serverId);

    final refused = refusal;

    if (refused != null) {
      return Result<ServerRefresh>.error(refused);
    }

    return Result<ServerRefresh>.ok(
      ServerRefresh(
        server: _byId(serverId),
        fingerprintChanged: fingerprintChanges,
      ),
    );
  }

  @override
  Future<Result<void>> forgetServer(KnownServer server) async {
    forgotten.add(server.id);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    catalogue = <KnownServer>[
      for (final held in catalogue)
        if (held.id != server.id) held,
    ];

    return const Result<void>.ok(null);
  }

  /// The permissions this node reports, which a test sets.
  List<ReplicaAuthorization> grants = <ReplicaAuthorization>[];

  /// Every grant it was asked for, as `(serverId, replicatesFiles)`.
  final List<(String, bool)> authorized = <(String, bool)>[];

  /// Every permission a withdrawal was asked for, in order.
  final List<String> revoked = <String>[];

  @override
  Future<Result<List<ReplicaAuthorization>>> replicas() async {
    final refused = refusal;

    return refused == null
        ? Result<List<ReplicaAuthorization>>.ok(grants)
        : Result<List<ReplicaAuthorization>>.error(refused);
  }

  @override
  Future<Result<ReplicaAuthorization>> authorizeReplica({
    required String serverId,
    required bool replicatesFiles,
  }) async {
    authorized.add((serverId, replicatesFiles));

    final refused = refusal;

    if (refused != null) {
      return Result<ReplicaAuthorization>.error(refused);
    }

    final granted = ReplicaAuthorization(
      id: 'grant-${grants.length + 1}',
      serverId: serverId,
      serverDomain: _byId(serverId).descriptor.domain,
      authorizedAt: DateTime.utc(2026, 9),
      replicatesFiles: replicatesFiles,
      active: true,
    );

    grants = <ReplicaAuthorization>[...grants, granted];

    return Result<ReplicaAuthorization>.ok(granted);
  }

  @override
  Future<Result<void>> revokeReplica(String serverId) async {
    revoked.add(serverId);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    grants = <ReplicaAuthorization>[
      for (final grant in grants)
        if (grant.serverId == serverId)
          ReplicaAuthorization(
            id: grant.id,
            serverId: grant.serverId,
            serverDomain: grant.serverDomain,
            authorizedAt: grant.authorizedAt,
            replicatesFiles: grant.replicatesFiles,
            active: false,
          )
        else
          grant,
    ];

    return const Result<void>.ok(null);
  }

  /// The devices this migration would carry, which a test sets.
  CarriedDevices carried = const CarriedDevices(
    named: true,
    devices: <CarriedDevice>[
      CarriedDevice(
        id: '11111111-1111-4111-8111-111111111111',
        isThisDevice: true,
        name: 'Celular',
        platform: 'android',
      ),
    ],
  );

  /// Every migration it was handed, in order.
  final List<HomeServerMigration> migrations = <HomeServerMigration>[];

  @override
  Future<Result<CarriedDevices>> devicesToCarry() async {
    final refused = refusal;

    return refused == null
        ? Result<CarriedDevices>.ok(carried)
        : Result<CarriedDevices>.error(refused);
  }

  @override
  Future<Result<User>> migrate(HomeServerMigration migration) async {
    migrations.add(migration);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    return Result<User>.ok(
      User(
        id: '22222222-2222-4222-8222-222222222222',
        localName: migration.localName,
        displayName: migration.displayName,
        originServerDomain: migration.domain,
        federatedId: '@${migration.localName}:${migration.domain}',
        createdAt: DateTime.utc(2026, 9),
        email: migration.email,
      ),
    );
  }

  KnownServer _byId(String id) =>
      catalogue.firstWhere((KnownServer server) => server.id == id);
}

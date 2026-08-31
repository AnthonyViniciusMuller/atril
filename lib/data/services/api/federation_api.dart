/// `FederationService`: which nodes the reader knows, which of them may hold a
/// copy of their data, and how they move to a different one.
///
/// RN03 gives the reader control over the servers used for synchronization,
/// and this is where that control is exercised: nothing leaves a node for a
/// peer the reader has not named here.
///
/// One thing this client cannot do, and phase 12 says so on the screen rather
/// than appearing to have worked: **a node cannot be told through the API that
/// it is a replica** (C22). [authorizeReplica] grants the permission on the
/// origin node, and completing the federation is out of band.
library;

import 'package:protobuf/well_known_types/google/protobuf/field_mask.pb.dart';

import '../../../domain/models/device.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/user.dart';
import '../../model/federation_mapper.dart';
import '../../model/identity_mapper.dart';
import 'api_client.dart';
import 'generated/quire/v1/auth.pb.dart' as auth;
import 'generated/quire/v1/federation.pbgrpc.dart' as pb;

/// The operation discovery reports under.
const String opDiscover = 'federation/servers: discover';

/// The operation the catalogue reports under.
const String opServers = 'federation/servers';

/// The operation a replica permission reports under.
const String opReplicas = 'federation/replicas';

/// The operation a migration reports under.
const String opMigrate = 'federation/migration: migrate';

/// What a refresh of a known node found.
final class ServerRefresh {
  /// The node as it now is, and whether its key changed.
  const ServerRefresh({required this.server, required this.fingerprintChanged});

  /// The node, re-discovered.
  final KnownServer server;

  /// Whether the node now presents a different certificate from the one on
  /// record.
  ///
  /// It is reported rather than applied silently, because a rotation and an
  /// interception look identical from here and the reader is the only party
  /// who can tell them apart.
  final bool fingerprintChanged;
}

/// What a migration answered with.
final class Migration {
  /// The reader as they now exist on the new node, their devices as adopted,
  /// and the session for the calling device.
  const Migration({
    required this.user,
    required this.devices,
    required this.session,
  });

  /// The account on the new node. The identifier changed, because the domain
  /// half is this node.
  final User user;

  /// The devices as adopted, which a client should compare against what it
  /// sent before pushing anything.
  final List<Device> devices;

  /// For the calling device, so that it can begin pushing its local log
  /// immediately. The other devices log in as they normally would.
  final Session session;
}

/// `FederationService`, as this app calls it.
final class FederationApi extends ApiClient {
  /// The client over the channel this node is dialled on.
  FederationApi({
    required super.channel,
    required super.session,
    super.reachability,
  });

  late final pb.FederationServiceClient _stub = pb.FederationServiceClient(
    channel,
    interceptors: interceptors,
  );

  /// UC13, RF14. Resolves a domain to the services it exposes, and returns
  /// what it found without storing anything.
  ///
  /// It is a call to a node this device is already signed in at, and it is not
  /// public: a device with no node to ask yet reads the `.well-known` document
  /// directly instead, which is what phase 6 adds beside this.
  Future<ServerDescriptor> discoverServer(String domain) => call(
    opDiscover,
    () async => descriptorOf(
      (await _stub.discoverServer(pb.DiscoverServerRequest(domain: domain)))
          .descriptor,
    ),
  );

  /// UC12, create. Discovers the domain and records the result, pinning the
  /// fingerprint node-to-node mTLS will be checked against (RNF08).
  ///
  /// The domain is the only parameter: the rest of the record is what the node
  /// says about itself, and a reader who could type the fingerprint by hand
  /// could also pin the wrong one.
  Future<KnownServer> addKnownServer(String domain) => call(
    opServers,
    () async => knownServerOf(
      (await _stub.addKnownServer(pb.AddKnownServerRequest(domain: domain)))
          .server,
    ),
  );

  /// UC12, read.
  Future<KnownServer> getKnownServer(String serverId) => call(
    opServers,
    () async => knownServerOf(
      (await _stub.getKnownServer(pb.GetKnownServerRequest(serverId: serverId)))
          .server,
    ),
  );

  /// UC12, read. Nodes the reader deactivated are hidden by default.
  Future<List<KnownServer>> listKnownServers({bool includeInactive = false}) =>
      call(
        opServers,
        () async => <KnownServer>[
          for (final server in (await _stub.listKnownServers(
            pb.ListKnownServersRequest(includeInactive: includeInactive),
          )).servers)
            knownServerOf(server),
        ],
      );

  /// UC12, update. Whether the node takes part is the only editable field:
  /// everything else was learned from the node itself.
  Future<KnownServer> setKnownServerActive({
    required String serverId,
    required bool active,
  }) => call(
    opServers,
    () async => knownServerOf(
      (await _stub.updateKnownServer(
        pb.UpdateKnownServerRequest(
          serverId: serverId,
          server: pb.Server(active: active),
          updateMask: FieldMask(paths: <String>['active']),
        ),
      )).server,
    ),
  );

  /// UC12, update — the half that re-runs discovery.
  ///
  /// It is the only way a pinned fingerprint changes, and it is a deliberate
  /// act by the reader precisely because a node that re-pinned on its own
  /// would have no pin at all: whoever could answer for the domain would be
  /// accepted on the strength of answering for the domain.
  Future<ServerRefresh> refreshKnownServer(String serverId) =>
      call(opServers, () async {
        final answer = await _stub.refreshKnownServer(
          pb.RefreshKnownServerRequest(serverId: serverId),
        );

        return ServerRefresh(
          server: knownServerOf(answer.server),
          fingerprintChanged: answer.certificateFingerprintChanged,
        );
      });

  /// UC12, delete. Refused by the node while an active authorization names it:
  /// forgetting a peer that still holds a copy would leave the reader unable
  /// to revoke it, and RN03 is the promise that they can.
  Future<void> removeKnownServer(String serverId) => call(
    opServers,
    () => _stub.removeKnownServer(
      pb.RemoveKnownServerRequest(serverId: serverId),
    ),
  );

  /// UC15, RF16. Allows a known node to hold a copy, with or without the
  /// files.
  Future<ReplicaAuthorization> authorizeReplica({
    required String serverId,
    required bool replicatesFiles,
  }) => call(
    opReplicas,
    () async => replicaAuthorizationOf(
      (await _stub.authorizeReplica(
        pb.AuthorizeReplicaRequest(
          serverId: serverId,
          replicatesFiles: replicatesFiles,
        ),
      )).authorization,
    ),
  );

  /// UC15, RF16. Withdraws that permission, which stops the replication and
  /// does not reach into another operator's database.
  Future<void> revokeReplica(String serverId) => call(
    opReplicas,
    () => _stub.revokeReplica(pb.RevokeReplicaRequest(serverId: serverId)),
  );

  /// UC15, read. Which nodes hold a copy, which of them hold the files, and
  /// which used to.
  Future<List<ReplicaAuthorization>> listReplicaAuthorizations({
    bool includeInactive = false,
  }) => call(
    opReplicas,
    () async => <ReplicaAuthorization>[
      for (final grant in (await _stub.listReplicaAuthorizations(
        pb.ListReplicaAuthorizationsRequest(includeInactive: includeInactive),
      )).authorizations)
        replicaAuthorizationOf(grant),
    ],
  );

  /// UC16, RF17. Moves the reader to a node they had no account on.
  ///
  /// It is addressed to the node being moved *to*, by a device that already
  /// holds the whole collection locally, which is what lets the migration
  /// proceed without the previous node's cooperation or availability.
  ///
  /// [devices] carry the identifiers they already hold, and C11 is why they
  /// have to: every operation names its authoring device and every clock is
  /// keyed by a device id, so a node that minted fresh ones would hold a
  /// history naming devices that do not exist, and two devices that had been
  /// in sync would read as concurrent for ever. Sending one twice is not an
  /// error; omitting one is, and the omission surfaces later as a log the node
  /// cannot insert.
  Future<Migration> migrateHomeServer({
    required String localName,
    required String displayName,
    required String email,
    required String password,
    required String previousFederatedId,
    required List<Device> devices,
  }) => call(opMigrate, () async {
    final answer = await _stub.migrateHomeServer(
      pb.MigrateHomeServerRequest(
        localName: localName,
        displayName: displayName,
        email: email,
        password: password,
        previousFederatedId: previousFederatedId,
        devices: <auth.Device>[
          for (final device in devices) wireDevice(device),
        ],
      ),
    );

    return Migration(
      user: userOf(answer.user),
      devices: <Device>[for (final device in answer.devices) deviceOf(device)],
      session: sessionOf(answer.session),
    );
  });
}

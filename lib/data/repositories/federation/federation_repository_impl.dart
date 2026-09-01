/// [FederationRepository] over `FederationService` and the local catalogue.
library;

import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/errors.dart';
import '../../services/api/federation_api.dart';
import '../../services/local/dao/identity_dao.dart';
import 'federation_repository.dart';

final _log = loggerFor('data/federation');

/// The operation the catalogue reports its failures under.
const String opCatalogue = 'federation/servers: catalogue';

/// The operation adding a node reports under.
const String opAddServer = 'federation/servers: add';

/// The operation re-running discovery reports under.
const String opRefreshServer = 'federation/servers: refresh';

/// The operation forgetting a node reports under.
const String opForgetServer = 'federation/servers: forget';

/// The operation reading the replica permissions reports under.
const String opReplicas = 'federation/replicas: list';

/// The operation granting one reports under.
const String opAuthorizeReplica = 'federation/replicas: authorize';

/// The operation withdrawing one reports under.
const String opRevokeReplica = 'federation/replicas: revoke';

/// The stable code of a domain that is not one a lookup can be addressed to.
const String codeInvalidDomain = 'invalid_server_domain';

/// The reader's federation, over the node that keeps it.
final class FederationRepositoryImpl implements FederationRepository {
  /// The repository over [federation], mirroring what it learns into
  /// [identity].
  FederationRepositoryImpl({
    required this.federation,
    required this.identity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The node's `FederationService`, which is where the catalogue lives.
  final FederationApi federation;

  /// The local catalogue, which is what this device dials.
  final IdentityDao identity;

  final DateTime Function() _clock;

  @override
  Future<Result<List<KnownServer>>> servers() async {
    try {
      // Deactivated nodes included, because this is the screen a node is
      // turned back on from: a list that hid them would hide the only row
      // carrying the switch that would undo the state.
      final catalogue = await federation.listKnownServers(
        includeInactive: true,
      );

      await _mirror(catalogue);

      return Result<List<KnownServer>>.ok(catalogue);
    } on Exception catch (error) {
      return Result<List<KnownServer>>.error(
        failureFrom(error, op: opCatalogue),
      );
    }
  }

  @override
  Future<Result<KnownServer>> addServer(String domain) async {
    final wanted = canonicalServerDomain(domain);
    final violation = serverDomainViolation(wanted);

    // Checked here so that a reader is told what is wrong with what they typed
    // before a request travels. It is not distrust of the node — the node
    // checks it again and is the only authority on a domain *resolving* — it
    // is that a malformed domain has no node to be refused by.
    if (violation != null) {
      return Result<KnownServer>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the domain "$wanted" $violation',
          code: codeInvalidDomain,
          op: opAddServer,
        ).withField('domain', violation),
      );
    }

    try {
      final added = await federation.addKnownServer(wanted);

      await _mirror(<KnownServer>[added]);
      _log.info('${added.descriptor.domain} was added to the catalogue');

      return Result<KnownServer>.ok(added);
    } on Exception catch (error) {
      return Result<KnownServer>.error(failureFrom(error, op: opAddServer));
    }
  }

  @override
  Future<Result<KnownServer>> setActive({
    required String serverId,
    required bool active,
  }) async {
    try {
      final changed = await federation.setKnownServerActive(
        serverId: serverId,
        active: active,
      );

      await _mirror(<KnownServer>[changed]);

      return Result<KnownServer>.ok(changed);
    } on Exception catch (error) {
      return Result<KnownServer>.error(failureFrom(error, op: opCatalogue));
    }
  }

  @override
  Future<Result<ServerRefresh>> refreshServer(String serverId) async {
    try {
      final refreshed = await federation.refreshKnownServer(serverId);

      // Mirrored whether or not the key moved. What the reader is asked about
      // is the *pin*, which is the node's to hold; what this device keeps is
      // the address it dials, and that is now stale either way.
      await _mirror(<KnownServer>[refreshed.server]);

      if (refreshed.fingerprintChanged) {
        _log.warning(
          '${refreshed.server.descriptor.domain} presents a different key '
          'from the one on record',
        );
      }

      return Result<ServerRefresh>.ok(refreshed);
    } on Exception catch (error) {
      return Result<ServerRefresh>.error(
        failureFrom(error, op: opRefreshServer),
      );
    }
  }

  @override
  Future<Result<void>> forgetServer(KnownServer server) async {
    try {
      await federation.removeKnownServer(server.id);

      // Deactivated here and not deleted. The row is what the reader's own
      // row references and what explains a peer that still holds a copy, and
      // the column's comment has said so since the table was written.
      await identity.deactivateServer(server.descriptor.domain);
      _log.info('${server.descriptor.domain} was forgotten');

      return const Result<void>.ok(null);
    } on Exception catch (error) {
      return Result<void>.error(failureFrom(error, op: opForgetServer));
    }
  }

  @override
  Future<Result<List<ReplicaAuthorization>>> replicas() async {
    try {
      return Result<List<ReplicaAuthorization>>.ok(
        // The revoked ones included: they are what explains a peer that still
        // holds data, and a sovereignty screen that showed only the live
        // grants would answer *nobody* about a node that has a copy.
        await federation.listReplicaAuthorizations(includeInactive: true),
      );
    } on Exception catch (error) {
      return Result<List<ReplicaAuthorization>>.error(
        failureFrom(error, op: opReplicas),
      );
    }
  }

  @override
  Future<Result<ReplicaAuthorization>> authorizeReplica({
    required String serverId,
    required bool replicatesFiles,
  }) async {
    try {
      final granted = await federation.authorizeReplica(
        serverId: serverId,
        replicatesFiles: replicatesFiles,
      );

      _log.info(
        '${granted.serverDomain} may hold a copy'
        '${replicatesFiles ? ', files included' : ', metadata only'}',
      );

      return Result<ReplicaAuthorization>.ok(granted);
    } on Exception catch (error) {
      return Result<ReplicaAuthorization>.error(
        failureFrom(error, op: opAuthorizeReplica),
      );
    }
  }

  @override
  Future<Result<void>> revokeReplica(String serverId) async {
    try {
      await federation.revokeReplica(serverId);

      return const Result<void>.ok(null);
    } on Exception catch (error) {
      return Result<void>.error(failureFrom(error, op: opRevokeReplica));
    }
  }

  /// Records what the node said about [catalogue] in the local one.
  ///
  /// A failure here is logged and not returned, and the asymmetry is
  /// deliberate: the reader asked what their federation looks like and the
  /// node answered, so a screen refusing to show that answer because a local
  /// write failed would be reporting the wrong thing having failed. What a
  /// failed mirror costs is a `remote_id` filled in on the next visit.
  Future<void> _mirror(List<KnownServer> catalogue) async {
    final at = _clock();

    for (final server in catalogue) {
      try {
        await identity.rememberKnownServer(server, at: at);
      } on Exception catch (error) {
        _log.warning(
          '${server.descriptor.domain} was not recorded locally',
          error,
        );
      }
    }
  }
}

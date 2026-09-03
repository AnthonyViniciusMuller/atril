/// [FederationRepository] over `FederationService` and the local catalogue.
library;

import '../../../domain/models/device.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/errors.dart';
import '../../services/api/federation_api.dart';
import '../../services/api/session.dart';
import '../../services/local/dao/identity_dao.dart';
import '../../services/local/dao/records_dao.dart';
import '../../services/local/dao/sync_dao.dart';
import '../server/server_repository.dart';
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

/// The operation reading the devices a migration would carry reports under.
const String opCarriedDevices = 'federation/migration: devices';

/// The operation a migration reports under.
const String opMigrate = 'federation/migration: migrate';

/// The stable code of a domain that is not one a lookup can be addressed to.
const String codeInvalidDomain = 'invalid_server_domain';

/// The stable code of a migration from a device that is not bound to anybody.
///
/// There is nothing to move: no reader to record as the previous identity, and
/// no identifier for the new node to adopt.
const String codeNothingToMigrate = 'nothing_to_migrate';

/// The reader's federation, over the node that keeps it.
final class FederationRepositoryImpl implements FederationRepository {
  /// The repository over [federation], mirroring what it learns into
  /// [identity].
  FederationRepositoryImpl({
    required this.federation,
    required this.identity,
    this.auth,
    this.records,
    this.sync,
    this.servers,
    this.session,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The node's `FederationService`, which is where the catalogue lives.
  final FederationApi federation;

  /// The local catalogue, which is what this device dials.
  final IdentityDao identity;

  /// The node's `AuthService`, for the one thing UC16 needs from it.
  ///
  /// It is here rather than behind another repository because the migration is
  /// the one call of `FederationService` whose work belongs to the identity
  /// slice — Quire says exactly that on the other side, where the controller
  /// of one slice translates for a use case of another — and because what this
  /// asks of it is a *name*, not an account: `ListDevices` is how the devices a
  /// migration carries get called something the reader recognizes.
  ///
  /// The five below are nullable so that the catalogue half of this repository
  /// can be built without any of them; the composition root passes them all,
  /// and a migration attempted without them is a programming error rather than
  /// a state.
  final AuthApi? auth;

  /// The causal state, which is where a device identifier survives a node that
  /// cannot be reached.
  final RecordsDao? records;

  /// The cursors, for the one this migration drops.
  final SyncDao? sync;

  /// What points this device at the node being moved to.
  final ServerRepository? servers;

  /// The session this device holds, which the migration replaces.
  final SessionHolder? session;

  final DateTime Function() _clock;

  @override
  Future<Result<List<KnownServer>>> knownServers() async {
    try {
      // Deactivated nodes included, because this is the screen a node is
      // turned back on from: a list that hid them would hide the only row
      // carrying the switch that would undo the state.
      final catalogue = await federation.listKnownServers(
        includeInactive: true,
      );

      await _mirror(catalogue);

      return Result<List<KnownServer>>.ok(catalogue);
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
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
    } on Object catch (error) {
      return Result<void>.error(failureFrom(error, op: opRevokeReplica));
    }
  }

  @override
  Future<Result<CarriedDevices>> devicesToCarry() async {
    final own = await identity.device();

    if (own == null) {
      return Result<CarriedDevices>.error(
        const AppException(
          kind: ErrorKind.failedPrecondition,
          message: 'this device is bound to nobody',
          code: codeNothingToMigrate,
          op: opCarriedDevices,
        ),
      );
    }

    // The node being left, asked for the names only. A node that does not
    // answer costs exactly that: the identifiers come from the replica
    // instead, and they are the half that cannot be recreated.
    List<Device>? named;

    try {
      named = await auth!.listDevices();
    } on Object catch (error) {
      _log.info('the node being left did not name the devices', error);
    }

    if (named != null) {
      // This device is put into the answer if the node left it out. It is
      // carried whether or not anything else is — the session comes back for
      // the first device in the list, and a device that migrated an account
      // without itself would have nowhere to push from.
      final all = _thisFirst(<Device>[
        Device(
          id: own.id,
          name: own.name,
          platform: own.platform,
          active: true,
        ),
        ...named,
      ], own.id);

      return Result<CarriedDevices>.ok(
        CarriedDevices(
          named: true,
          devices: <CarriedDevice>[
            for (final device in all)
              CarriedDevice(
                id: device.id,
                isThisDevice: device.id == own.id,
                name: device.name,
                platform: device.platform,
              ),
          ],
        ),
      );
    }

    final remembered = await records!.devicesInHistory();

    return Result<CarriedDevices>.ok(
      CarriedDevices(
        named: false,
        devices: <CarriedDevice>[
          CarriedDevice(
            id: own.id,
            isThisDevice: true,
            name: own.name,
            platform: own.platform,
          ),
          for (final id in remembered)
            if (id != own.id) CarriedDevice(id: id, isThisDevice: false),
        ],
      ),
    );
  }

  @override
  Future<Result<User>> migrate(HomeServerMigration migration) async {
    final domain = canonicalServerDomain(migration.domain);
    final localName = canonicalLocalName(migration.localName);
    final displayName = migration.displayName.trim();
    final email = migration.email.trim();

    // Every violation and not the first: a wizard that reported one field at a
    // time would make the reader submit four times to learn four things this
    // device already knew.
    final refused = <String, String>{
      if (serverDomainViolation(domain) case final String why) 'domain': why,
      if (localNameViolation(localName) case final String why)
        'local_name': why,
      if (displayNameViolation(displayName) case final String why)
        'display_name': why,
      if (emailViolation(email) case final String why) 'email': why,
      if (passwordViolation(migration.password) case final String why)
        'password': why,
    };

    if (refused.isNotEmpty) {
      return Result<User>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the migration was refused before it was sent',
          op: opMigrate,
        ).withFields(<FieldFailure>[
          for (final MapEntry<String, String> entry in refused.entries)
            FieldFailure(entry.key, entry.value),
        ]),
      );
    }

    final own = await identity.device();
    final reader = await identity.reader();

    if (own == null || reader == null) {
      return Result<User>.error(
        const AppException(
          kind: ErrorKind.failedPrecondition,
          message: 'this device holds no reader to move',
          code: codeNothingToMigrate,
          op: opMigrate,
        ),
      );
    }

    // Where this device was pointed, so that a migration that fails leaves it
    // talking to the node it is still signed in at. A device pointed at a node
    // it has no account on, holding a session for one it is no longer dialling,
    // is a device every call fails on for a reason nothing on screen explains.
    final previous = await servers!.current();

    final pointed = await servers!.choose(ServerChoice(domain));

    if (pointed case Error<ServerDescriptor>(:final error)) {
      return Result<User>.error(error);
    }

    try {
      final moved = await federation.migrateHomeServer(
        localName: localName,
        displayName: displayName,
        email: email,
        password: migration.password,
        // Recorded there and never believed: this node cannot check it, and
        // C11 says so in the contract itself.
        previousFederatedId: reader.federatedId,
        devices: _thisFirst(<Device>[
          Device(
            id: own.id,
            name: own.name,
            platform: own.platform,
            active: true,
          ),
          ...migration.devices,
        ], own.id),
      );

      await _adopt(moved, domain: domain, deviceId: own.id);
      _log.info('the reader is now ${moved.user.federatedId}');

      return Result<User>.ok(moved.user);
    } on Object catch (error) {
      await _pointBack(previous);

      return Result<User>.error(failureFrom(error, op: opMigrate));
    }
  }

  /// Makes [moved] this device's account, keeping everything the migration is
  /// about.
  ///
  /// The order is the sign-in's order and for the sign-in's reason: everything
  /// is written before the session is adopted, because a device the shell
  /// believes is signed in and that cannot say who as is a library it cannot
  /// fill. What is deliberately *not* here is any clearing — the outbox, the
  /// causal state and the replica are what the devices are about to push, and
  /// a client that emptied them would have completed the migration by
  /// discarding what was being migrated.
  Future<void> _adopt(
    Migration moved, {
    required String domain,
    required String deviceId,
  }) async {
    final at = _clock();

    // The node echoes the devices it adopted. This device's identifier is
    // unchanged by construction — that is the whole of C11 — and what may have
    // moved is the name, so the row is brought into step rather than rewritten.
    for (final device in moved.devices) {
      if (device.id == deviceId) {
        await identity.bindDevice(
          id: device.id,
          name: device.name,
          platform: device.platform,
          at: at,
        );
      }
    }

    await servers!.adoptOrigin(domain);

    await identity.rememberReader(
      id: moved.user.id,
      localName: moved.user.localName,
      displayName: moved.user.displayName,
      originServerDomain: moved.user.originServerDomain,
      federatedId: moved.user.federatedId,
      createdAt: moved.user.createdAt,
      email: moved.user.email,
    );

    // The position this device holds in *that* node's log. The log it is about
    // to write for this reader is empty, and a number left over from an
    // earlier conversation with the same address would skip everything the
    // migration is about to put there.
    await sync!.dropCursor(domain);

    await session!.begin(moved.session);
  }

  /// Points this device back at the node it was talking to.
  Future<void> _pointBack(Result<ServerDescriptor?> previous) async {
    if (previous case Ok<ServerDescriptor?>(:final value) when value != null) {
      final back = await servers!.choose(ServerChoice(value.domain));

      if (back is Error<ServerDescriptor>) {
        _log.warning(
          'this device is still pointed at the node it did not '
          'migrate to',
        );
      }
    }
  }

  /// [devices] with [deviceId] first and each identifier once.
  ///
  /// C20: the contract carries no field naming the calling device, the session
  /// comes back for the first in the list, and the order is the only thing a
  /// client controls. The correction is recorded on the Quire side and the
  /// vendored `.proto` does not yet say it, so the rule is honoured here and
  /// named where it is honoured.
  List<Device> _thisFirst(List<Device> devices, String deviceId) {
    final named = <String>{};
    final ordered = <Device>[];

    for (final device in devices) {
      if (device.id == deviceId && named.add(device.id)) {
        ordered.insert(0, device);
      } else if (named.add(device.id)) {
        ordered.add(device);
      }
    }

    return ordered;
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
      } on Object catch (error) {
        _log.warning(
          '${server.descriptor.domain} was not recorded locally',
          error,
        );
      }
    }
  }
}

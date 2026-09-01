/// The reader's federation: which nodes they know, which of those may hold a
/// copy of their data, and how they move to a different one.
///
/// RN03 gives the reader control over the servers used for synchronization,
/// and this is where that control is exercised — nothing leaves their node for
/// a peer they have not named here.
///
/// **It is the one repository in the app that does not answer from the local
/// replica, and that is the point rather than an omission.** Every other
/// repository holds records that replicate, so the truth is here and the node
/// hears about it later. A catalogue entry, a replica permission and an
/// account are none of those: they are what *the node* knows and enforces, they
/// are changed on more than one device, and there is nothing a reader can do
/// about any of them while the node cannot be reached. A cached list would
/// therefore be a screen showing a permission that may already have been
/// revoked, offering a button that cannot work — which is worse than a screen
/// that says the node did not answer.
///
/// The catalogue is still *mirrored* into `known_servers` as each answer
/// arrives, and that is a different job: the local row is what a launch dials
/// and what fills in `remote_id`, which `ListKnownServers` is the only call
/// that reports.
library;

import '../../../domain/models/device.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import '../../services/api/federation_api.dart';

/// The platform a device recovered from the replica's own clocks is carried
/// under.
///
/// The contract leaves the field free-form so that a seventh platform does not
/// need the node redeployed, and it refuses a blank one — a device the node
/// being left could not name has no platform to report, and this is the value
/// that says so in the same vocabulary `android` and `web` are written in.
const String unknownPlatform = 'unknown';

/// One of the devices a migration has to carry.
///
/// The identifier is the half that cannot be recreated: every operation names
/// the device that authored it and every vector clock is keyed by one, so a
/// node that minted fresh identifiers would hold a history naming devices that
/// do not exist, and two devices that had been in sync would read as
/// concurrent for ever (C11). The name is the half that can — it is what the
/// node being left called it, and it is absent when that node could not be
/// asked.
final class CarriedDevice {
  /// The device [id], named if the node being left answered.
  const CarriedDevice({
    required this.id,
    required this.isThisDevice,
    this.name,
    this.platform,
  });

  /// The identifier its vector-clock entries are counted under.
  final String id;

  /// Whether it is the device the reader is migrating from.
  ///
  /// That one is carried whether or not anything else is, and it goes first:
  /// the session comes back for the first device in the list, and a device
  /// that migrated an account without itself would have nowhere to push from.
  final bool isThisDevice;

  /// What the node being left called it, or `null` when that node did not
  /// answer and this identifier came out of the replica's own clocks.
  final String? name;

  /// The platform the node recorded, or `null` for the same reason.
  final String? platform;

  @override
  String toString() =>
      'CarriedDevice($id${name == null ? ', unnamed' : ', $name'})';
}

/// The devices a migration will carry, and where their names came from.
final class CarriedDevices {
  /// The devices, this one first.
  const CarriedDevices({required this.devices, required this.named});

  /// Every device the reader owns, as far as this device can establish.
  final List<CarriedDevice> devices;

  /// Whether the node being left answered.
  ///
  /// When it did not, the identifiers come from the replica's causal state and
  /// the names do not exist. That is worth showing the reader rather than
  /// papering over: a migration is still correct without the names, and it is
  /// not correct without the identifiers.
  final bool named;

  @override
  String toString() =>
      'CarriedDevices(${devices.length}${named ? '' : ', unnamed'})';
}

/// What a reader hands over to move to another origin server.
///
/// It is a registration plus a claim. The four account fields make the account
/// on the node being moved *to*, and [previousFederatedId] is recorded there as
/// provenance and never believed — a node that needs nothing from the previous
/// server has nothing to check it with, which is the same independence UC16
/// exists for (C11).
final class HomeServerMigration {
  /// The account `@localName` as it will exist at [domain], carrying
  /// [devices].
  const HomeServerMigration({
    required this.domain,
    required this.localName,
    required this.displayName,
    required this.email,
    required this.password,
    required this.devices,
  });

  /// The node being moved to, as the reader typed it.
  final String domain;

  /// The first half of the new identifier. The second half is that node, so
  /// the identifier changes whatever is typed here.
  final String localName;

  /// What the reader calls themselves.
  final String displayName;

  /// The address recovery is sent to at the new node.
  final String email;

  /// The password of the new account, which is a new credential and not the
  /// old one carried across.
  final String password;

  /// The devices to adopt, with the identifiers they already hold.
  ///
  /// The device making the call does not have to be among them and is added if
  /// it is not: the repository is what guarantees it goes first, because the
  /// contract carries no field naming the calling device and the order is the
  /// only thing a client controls (C20).
  final List<Device> devices;

  /// The migration, without the credential.
  @override
  String toString() => 'HomeServerMigration(@$localName:$domain)';
}

/// The nodes a reader knows and what they have allowed each of them.
abstract interface class FederationRepository {
  /// UC12, read. Every node in the reader's catalogue, the deactivated ones
  /// included.
  ///
  /// They are included rather than hidden because this screen is where a node
  /// is turned back on: a catalogue that showed only what takes part would be
  /// a catalogue with no way out of the state its own switch produces.
  Future<Result<List<KnownServer>>> knownServers();

  /// UC12, create. Discovers [domain] and records what it published, pinning
  /// the key node-to-node mTLS will be checked against (RNF08).
  ///
  /// The domain is the only parameter. The rest of the record is what the node
  /// says about itself, and a reader who could type a fingerprint by hand
  /// could also pin the wrong one.
  Future<Result<KnownServer>> addServer(String domain);

  /// UC12, update. Whether the node takes part in replication, which is the
  /// only field of the record a reader writes.
  Future<Result<KnownServer>> setActive({
    required String serverId,
    required bool active,
  });

  /// UC12, update — the half that re-runs discovery, and the only way a pinned
  /// key changes.
  ///
  /// It is a deliberate act by the reader precisely because a node that
  /// re-pinned on its own would have no pin at all: whoever could answer for
  /// the domain would be accepted on the strength of answering for it. When
  /// the key has moved, the answer says so and the screen asks rather than
  /// tells — a rotation and an interception look identical from here.
  Future<Result<ServerRefresh>> refreshServer(String serverId);

  /// UC15, read. Which nodes hold a copy, which of them hold the files, and
  /// which used to.
  ///
  /// The revoked ones are included, and they are the half a sovereignty screen
  /// cannot leave out: revoking stops the replication and does not reach into
  /// another operator's database, so a permission that once existed is the
  /// only thing that explains a peer still holding data.
  Future<Result<List<ReplicaAuthorization>>> replicas();

  /// UC15, RF16. Allows the node [serverId] to hold a copy, with the files or
  /// without them.
  ///
  /// **It grants a permission it cannot complete.** C22: nothing in the
  /// contract can tell a node that it is a replica, so what this writes is the
  /// record on the reader's own node and the federation itself is arranged out
  /// of band between the two operators. The screen says so rather than
  /// appearing to have worked.
  Future<Result<ReplicaAuthorization>> authorizeReplica({
    required String serverId,
    required bool replicatesFiles,
  });

  /// UC15, RF16. Withdraws that permission.
  ///
  /// It stops the replication. It does not reach into another operator's
  /// database, and the record is deactivated rather than removed for exactly
  /// that reason.
  Future<Result<void>> revokeReplica(String serverId);

  /// The devices a migration would carry, and where their names came from.
  ///
  /// The node being left is asked, because it is the only thing that knows
  /// what the reader calls each device — and it is asked in the one way that
  /// keeps UC16's independence intact: a node that does not answer costs the
  /// names and not the identifiers, which come out of the replica's own causal
  /// state instead. That is the half that cannot be recreated, and a migration
  /// carrying the identifiers under invented names is a migration the reader
  /// can repair afterwards by renaming a device.
  Future<Result<CarriedDevices>> devicesToCarry();

  /// UC16, RF17. Moves the reader to the node [migration] names.
  ///
  /// It is addressed to the node being moved *to*, by a device that already
  /// holds the whole collection locally, which is what lets it proceed without
  /// the previous node's cooperation or availability. The previous node is
  /// asked nothing here and loses nothing.
  ///
  /// What it does to this device is the point of the call and is the opposite
  /// of what signing in to another account does. The identifier changes, since
  /// the domain half is the new node; the device keeps its identifier, its
  /// clock and its pending log, because those are what it then pushes through
  /// `SyncService` — and a client that cleared them on the change of account
  /// would have completed the migration by discarding what was being migrated
  /// (C11).
  ///
  /// The cursor for the new node is dropped rather than kept, for the reason
  /// the reference client drops it: a position is a number in that node's log,
  /// the log it is about to write for this reader is empty, and a number left
  /// over from an earlier conversation with the same address would skip
  /// everything the migration is about to put there.
  Future<Result<User>> migrate(HomeServerMigration migration);

  /// UC12, delete. Takes [server] out of the catalogue.
  ///
  /// The node refuses while an active authorization names it, and that refusal
  /// is a feature: forgetting a peer that still holds a copy would leave the
  /// reader unable to revoke it, and RN03 is the promise that they can.
  Future<Result<void>> forgetServer(KnownServer server);
}

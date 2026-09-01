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

import '../../../domain/models/server.dart';
import '../../../utils/result.dart';
import '../../services/api/federation_api.dart';

/// The nodes a reader knows and what they have allowed each of them.
abstract interface class FederationRepository {
  /// UC12, read. Every node in the reader's catalogue, the deactivated ones
  /// included.
  ///
  /// They are included rather than hidden because this screen is where a node
  /// is turned back on: a catalogue that showed only what takes part would be
  /// a catalogue with no way out of the state its own switch produces.
  Future<Result<List<KnownServer>>> servers();

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

  /// UC12, delete. Takes [server] out of the catalogue.
  ///
  /// The node refuses while an active authorization names it, and that refusal
  /// is a feature: forgetting a peer that still holds a copy would leave the
  /// reader unable to revoke it, and RN03 is the promise that they can.
  Future<Result<void>> forgetServer(KnownServer server);
}

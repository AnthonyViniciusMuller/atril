/// What the replica authorization screen knows.
///
/// It reads two lists and joins nothing. The permissions are what the reader
/// granted; the catalogue is what they *could* grant to, and a node already
/// named by a live permission is not among them — which is the only piece of
/// arithmetic here, and it is the screen's question rather than the node's.
///
/// Both are read from the node, and one failure is enough to make the screen
/// say so: a catalogue that arrived without its permissions would let a reader
/// authorize a node they had already authorized, and a list of permissions
/// with no catalogue behind it would offer nothing to grant.
library;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/federation/federation_repository.dart';
import '../../../domain/models/server.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the replica authorization screen.
final class ReplicasViewModel extends ChangeNotifier {
  /// The view model over [federation].
  ReplicasViewModel({required this.federation}) {
    load = Command0<void>(_load)..execute();
    authorize = Command1<ReplicaAuthorization, ReplicaGrant>(_authorize);
  }

  /// Where the permissions and the catalogue come from.
  final FederationRepository federation;

  /// Reads both lists. It runs at construction and again after every change.
  late final Command0<void> load;

  /// Grants one node the right to hold a copy.
  late final Command1<ReplicaAuthorization, ReplicaGrant> authorize;

  List<ReplicaAuthorization> _grants = const <ReplicaAuthorization>[];
  List<KnownServer> _catalogue = const <KnownServer>[];

  /// The permissions that are in force, most recently granted first.
  List<ReplicaAuthorization> get granted =>
      <ReplicaAuthorization>[
        for (final grant in _grants)
          if (grant.active) grant,
      ]..sort(
        (ReplicaAuthorization a, ReplicaAuthorization b) =>
            b.authorizedAt.compareTo(a.authorizedAt),
      );

  /// The permissions that were withdrawn, which are what explains a peer that
  /// still holds data.
  List<ReplicaAuthorization> get revoked => <ReplicaAuthorization>[
    for (final grant in _grants)
      if (!grant.active) grant,
  ];

  /// The nodes a permission could still be granted to.
  ///
  /// The reader's own node is not among them — it is where their library
  /// already is, and a node cannot replicate to itself — and neither is one a
  /// live permission already names.
  List<KnownServer> get candidates {
    final already = <String>{for (final grant in granted) grant.serverId};

    return <KnownServer>[
      for (final server in _catalogue)
        if (!server.isOrigin && !already.contains(server.id)) server,
    ];
  }

  /// Withdraws the permission naming [serverId].
  ///
  /// It is a method and not a `Command` for the reason the sync screen's
  /// discard is: there is one of these per row, and a single command would
  /// report the last row's outcome against every one of them.
  Future<Result<void>> revoke(String serverId) async {
    final outcome = await federation.revokeReplica(serverId);

    await load.execute();

    return outcome;
  }

  Future<Result<void>> _load() async {
    final grants = await federation.replicas();

    if (grants case Error<List<ReplicaAuthorization>>(:final error)) {
      return Result<void>.error(error);
    }

    final catalogue = await federation.knownServers();

    if (catalogue case Error<List<KnownServer>>(:final error)) {
      return Result<void>.error(error);
    }

    _grants = (grants as Ok<List<ReplicaAuthorization>>).value;
    _catalogue = (catalogue as Ok<List<KnownServer>>).value;
    notifyListeners();

    return const Result<void>.ok(null);
  }

  Future<Result<ReplicaAuthorization>> _authorize(ReplicaGrant grant) async {
    final granted = await federation.authorizeReplica(
      serverId: grant.serverId,
      replicatesFiles: grant.replicatesFiles,
    );

    if (granted is Ok<ReplicaAuthorization>) {
      await load.execute();
    }

    return granted;
  }

  @override
  void dispose() {
    load.dispose();
    authorize.dispose();
    super.dispose();
  }
}

/// What a reader decided to allow one node.
///
/// The two halves travel together because they are one decision, and the
/// second is not a detail of the first: metadata without the files is the
/// cheap replica a reader is most likely to want on a node they do not own,
/// and it is why the library's records do not reference the stored objects
/// (D02).
final class ReplicaGrant {
  /// The permission for [serverId], covering the files or not.
  const ReplicaGrant({required this.serverId, required this.replicatesFiles});

  /// The node the permission is for, by the identifier its own node reports.
  final String serverId;

  /// Whether it covers the e-book files as well as the metadata.
  final bool replicatesFiles;

  @override
  String toString() =>
      'ReplicaGrant($serverId${replicatesFiles ? ', with files' : ''})';
}

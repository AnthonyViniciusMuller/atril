/// What the known servers screen knows.
///
/// It is the first view model in the app whose state is not a stream, and the
/// reason is the repository's: the catalogue is what the *node* holds, so
/// there is nothing local to watch and nothing that changes without this
/// screen having asked. Every action therefore ends by asking again, which is
/// also what keeps a row the node edited its own way — a domain it
/// canonicalized, an `active` it refused to change — from being replaced here
/// by what this device assumed would happen.
///
/// The per-row actions are methods and not `Command` objects, which is the
/// same departure the sync screen makes and for the same reason: a command
/// carries the state of *one* running action, and there is one of these per
/// node in a list. A single command would report the last row's outcome
/// against every row.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/federation/federation_repository.dart';
import '../../../data/services/api/federation_api.dart';
import '../../../domain/models/server.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the known servers screen.
final class KnownServersViewModel extends ChangeNotifier {
  /// The view model over [federation].
  KnownServersViewModel({required this.federation}) {
    load = Command0<List<KnownServer>>(_load);

    unawaited(load.execute());
    add = Command1<KnownServer, String>(_add);
  }

  /// The reader's federation, as the node holds it.
  final FederationRepository federation;

  /// Reads the catalogue. It runs once at construction and again after every
  /// change, because the node is the only thing that knows what it now says.
  late final Command0<List<KnownServer>> load;

  /// Adds a node by domain, which discovers it and pins its key.
  late final Command1<KnownServer, String> add;

  List<KnownServer> _servers = const <KnownServer>[];

  /// The catalogue as it was last read, which is empty until it has been.
  List<KnownServer> get servers => _servers;

  /// Whether the node takes part in replication.
  Future<Result<KnownServer>> setActive(
    KnownServer server, {
    required bool active,
  }) => _reloading(federation.setActive(serverId: server.id, active: active));

  /// Re-runs discovery against [server], which is the only way a pinned key
  /// changes.
  ///
  /// The answer is handed back rather than folded into the state, because the
  /// half of it that matters is not a row: whether the key moved is a question
  /// for the reader, and only the screen can ask one.
  Future<Result<ServerRefresh>> refresh(KnownServer server) async {
    final refreshed = await federation.refreshServer(server.id);

    await load.execute();

    return refreshed;
  }

  /// Takes [server] out of the catalogue.
  Future<Result<void>> forget(KnownServer server) =>
      _reloading(federation.forgetServer(server));

  /// Runs [change] and reads the catalogue again, whatever it answered.
  ///
  /// Even a failure: the node may have refused because the record is not what
  /// this device thinks it is, and a screen that only refreshed on success
  /// would leave the reader looking at the version that caused the refusal.
  Future<Result<T>> _reloading<T>(Future<Result<T>> change) async {
    final outcome = await change;

    await load.execute();

    return outcome;
  }

  Future<Result<List<KnownServer>>> _load() async {
    final catalogue = await federation.knownServers();

    if (catalogue case Ok<List<KnownServer>>(:final value)) {
      _servers = value;
      notifyListeners();
    }

    return catalogue;
  }

  Future<Result<KnownServer>> _add(String domain) async {
    final added = await federation.addServer(domain);

    if (added is Ok<KnownServer>) {
      await load.execute();
    }

    return added;
  }

  @override
  void dispose() {
    load.dispose();
    add.dispose();
    super.dispose();
  }
}

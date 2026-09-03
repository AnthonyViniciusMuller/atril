/// What the server selection screen knows.
///
/// It is the first view model in the app, and it is the shape every one after
/// it follows: the repository is injected, the actions are [Command] objects
/// rather than methods, and nothing here knows what a widget looks like.
///
/// The one thing it holds beyond the commands is the list of nodes this build
/// can reach in a tap, which is empty in a shipped build. That comes from the
/// [Environment] rather than from the repository on purpose — it is a fact
/// about the *build* and not about the reader, and a repository that answered
/// it would be a repository reading the configuration.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../config/environment.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/server.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/onboarding');

/// The state of the server selection screen.
final class ServerSelectionViewModel extends ChangeNotifier {
  /// The view model over [servers], offering the nodes [environment] knows.
  ServerSelectionViewModel({
    required this.servers,
    required Environment environment,
  }) : federation = environment.federation {
    choose = Command1<ServerDescriptor, ServerChoice>(_choose);
    load = Command0<ServerDescriptor?>(_load);

    unawaited(load.execute());
  }

  /// Where the choice is made and recorded.
  final ServerRepository servers;

  /// The nodes this build reaches in one tap, which is empty in production.
  final List<KnownNode> federation;

  /// Reads the node this device is already pointed at.
  ///
  /// It runs once, at construction, and it is a command like the other so that
  /// the screen has one way of knowing that something is in flight.
  late final Command0<ServerDescriptor?> load;

  /// Looks a node up and points this device at it.
  late final Command1<ServerDescriptor, ServerChoice> choose;

  ServerDescriptor? _chosen;

  /// The node this device talks to, or `null` while nobody has chosen one.
  ServerDescriptor? get chosen => _chosen;

  /// The domain the last failed attempt was about, so that a message can name
  /// it.
  ///
  /// It is remembered rather than read back off the text field: a reader who
  /// starts editing after a refusal should keep seeing what was refused until
  /// they ask again.
  String? get attempted => _attempted;

  String? _attempted;

  Future<Result<ServerDescriptor?>> _load() async {
    final result = await servers.current();

    if (result case Ok<ServerDescriptor?>(:final value)) {
      _chosen = value;
    }

    return result;
  }

  Future<Result<ServerDescriptor>> _choose(ServerChoice choice) async {
    _attempted = choice.domain;

    final result = await servers.choose(choice);

    switch (result) {
      case Ok<ServerDescriptor>(:final value):
        _chosen = value;
      case Error<ServerDescriptor>(:final error):
        _log.warning('the node at ${choice.domain} was not usable', error);
    }

    return result;
  }
}

/// What the registration screen knows.
library;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/onboarding');

/// The state of the registration screen.
final class RegisterViewModel extends ChangeNotifier {
  /// The view model over [auth], naming the node [servers] is pointed at.
  RegisterViewModel({required this.auth, required this.servers}) {
    register = Command1<User, Registration>(_register);
    load = Command0<ServerDescriptor?>(_load)..execute();
  }

  /// Where the registration goes.
  final AuthRepository auth;

  /// What knows which node it goes to.
  final ServerRepository servers;

  /// Reads the node this device is pointed at, so that the screen can name it.
  ///
  /// The domain is about to become the second half of the reader's own
  /// identifier, which is the one thing on this form they cannot change
  /// afterwards without migrating.
  late final Command0<ServerDescriptor?> load;

  /// Creates the account.
  late final Command1<User, Registration> register;

  ServerDescriptor? _node;

  /// The node the account will be created at.
  ServerDescriptor? get node => _node;

  Future<Result<ServerDescriptor?>> _load() async {
    final result = await servers.current();

    if (result case Ok<ServerDescriptor?>(:final value)) {
      _node = value;
    }

    return result;
  }

  Future<Result<User>> _register(Registration registration) async {
    final result = await auth.register(registration);

    if (result case Error<User>(:final error)) {
      _log.warning(
        'the registration of ${registration.localName} failed',
        error,
      );
    }

    return result;
  }
}

/// What the sign-in screen knows.
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

/// The state of the sign-in screen.
final class SignInViewModel extends ChangeNotifier {
  /// The view model over [auth], naming the node [servers] is pointed at.
  SignInViewModel({required this.auth, required this.servers}) {
    signIn = Command1<User, Credentials>(_signIn);
    load = Command0<ServerDescriptor?>(_load)..execute();
  }

  /// Where the credentials go.
  final AuthRepository auth;

  /// What knows which node they go to.
  final ServerRepository servers;

  /// Reads the node this device is pointed at, so that the screen can name it.
  ///
  /// The reader is about to type a password, and which node it is being sent to
  /// is the one thing they cannot check afterwards.
  late final Command0<ServerDescriptor?> load;

  /// Signs in and binds this device.
  late final Command1<User, Credentials> signIn;

  ServerDescriptor? _node;

  /// The node the credentials are addressed to.
  ServerDescriptor? get node => _node;

  Future<Result<ServerDescriptor?>> _load() async {
    final result = await servers.current();

    if (result case Ok<ServerDescriptor?>(:final value)) {
      _node = value;
    }

    return result;
  }

  Future<Result<User>> _signIn(Credentials credentials) async {
    final result = await auth.signIn(credentials);

    if (result case Error<User>(:final error)) {
      _log.warning('the sign-in of ${credentials.identifier} failed', error);
    }

    return result;
  }
}

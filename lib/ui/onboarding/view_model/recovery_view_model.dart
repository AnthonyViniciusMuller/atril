/// What the two recovery screens know.
///
/// One view model over both halves of UC08, because they are one behaviour
/// split across two screens by where the credential arrives: the request is
/// made here and the code comes back by mail, as often as not on another
/// device. Each screen builds its own instance and uses the command it needs.
library;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/server.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/onboarding');

/// A recovery credential and the password it is being spent on.
final class PasswordReset {
  /// The reset spending [token] to set [password].
  const PasswordReset({required this.token, required this.password});

  /// The credential the node sent by mail.
  final String token;

  /// The new password.
  final String password;

  /// The reset, without either secret in it.
  @override
  String toString() => 'PasswordReset()';
}

/// The state of the recovery screens.
final class RecoveryViewModel extends ChangeNotifier {
  /// The view model over [auth], naming the node [servers] is pointed at.
  RecoveryViewModel({required this.auth, required this.servers}) {
    request = Command1<void, String>(_request);
    reset = Command1<void, PasswordReset>(_reset);
    load = Command0<ServerDescriptor?>(_load)..execute();
  }

  /// Where the request and the reset go.
  final AuthRepository auth;

  /// What knows which node they go to.
  final ServerRepository servers;

  /// Reads the node this device is pointed at, so that a screen can name it.
  late final Command0<ServerDescriptor?> load;

  /// Asks the node to send a recovery credential.
  late final Command1<void, String> request;

  /// Spends one, and sets the password.
  late final Command1<void, PasswordReset> reset;

  ServerDescriptor? _node;

  /// The node the recovery is addressed to.
  ServerDescriptor? get node => _node;

  Future<Result<ServerDescriptor?>> _load() async {
    final result = await servers.current();

    if (result case Ok<ServerDescriptor?>(:final value)) {
      _node = value;
    }

    return result;
  }

  /// The address is not remembered and is not logged.
  ///
  /// Whether an address is registered somewhere is the fact this whole call is
  /// built not to reveal, and a log line naming it would put it in the one
  /// place nobody thinks to look at.
  Future<Result<void>> _request(String email) async {
    final result = await auth.requestPasswordRecovery(email);

    if (result case Error<void>(:final error)) {
      _log.warning('a recovery request failed', error);
    }

    return result;
  }

  Future<Result<void>> _reset(PasswordReset attempt) async {
    final result = await auth.resetPassword(
      recoveryToken: attempt.token,
      newPassword: attempt.password,
    );

    if (result case Error<void>(:final error)) {
      _log.warning('a password reset failed', error);
    }

    return result;
  }
}

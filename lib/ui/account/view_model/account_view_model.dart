/// What the account screen knows.
///
/// It reads the reader from **two** places and that is deliberate. The row in
/// this device's database is what every surface in the app already names them
/// by, and it is what makes this screen show something on a device that has
/// been offline for a week; the node is the authority on all three fields, so
/// the screen asks it once when it opens and writes what comes back into that
/// same row. There is no third copy: a refresh that failed leaves the row —
/// and the screen — saying what it said before, which is the last thing this
/// device was told rather than a guess.
///
/// The three changes are three commands and not one, because they are three
/// calls with three different proofs. C14 is why the contract splits them, and
/// it survives here: a single *save* button over a form would have to demand a
/// password for the name as well, or accept one for none of it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/account');

/// What a reader hands over to change their address.
final class EmailChange {
  /// The address [email], proved with [password].
  const EmailChange({required this.password, required this.email});

  /// The current password, which is what proves the reader is at the device.
  final String password;

  /// The address recovery will be sent to from now on.
  final String email;

  /// The change, without the credential.
  @override
  String toString() => 'EmailChange($email)';
}

/// What a reader hands over to change their password.
final class PasswordChange {
  /// The new password, proved with the current one.
  const PasswordChange({required this.current, required this.next});

  /// The password now, which a session cannot stand in for: it proves a device
  /// is unlocked and not that the reader is at it.
  final String current;

  /// The password from now on.
  final String next;

  /// The change, without either credential.
  @override
  String toString() => 'PasswordChange()';
}

/// The state of the account screen.
final class AccountViewModel extends ChangeNotifier {
  /// The view model over [account], naming the reader out of [auth].
  AccountViewModel({required this.account, required this.auth}) {
    refresh = Command0<User>(account.readAccount);

    unawaited(refresh.execute());
    rename = Command1<User, String>(account.changeDisplayName);
    changeEmail = Command1<User, EmailChange>(
      (EmailChange change) =>
          account.changeEmail(password: change.password, email: change.email),
    );
    changePassword = Command1<void, PasswordChange>(
      (PasswordChange change) => account.changePassword(
        currentPassword: change.current,
        newPassword: change.next,
      ),
    );

    _reader = auth.reader().listen(_onReader);
  }

  /// Where the account is changed.
  final AccountRepository account;

  /// Who is signed in on this device, which is what the screen shows while the
  /// node is being asked and if it never answers.
  final AuthRepository auth;

  /// Reads the record from the node, writing it into this device's row.
  late final Command0<User> refresh;

  /// Changes the display name, which is the only field a mask can carry.
  late final Command1<User, String> rename;

  /// Changes the address, which asks for the password (C14).
  late final Command1<User, EmailChange> changeEmail;

  /// Changes the password, which ends every session of every device.
  late final Command1<void, PasswordChange> changePassword;

  late final StreamSubscription<Result<User?>> _reader;

  User? _signedIn;

  /// The reader, as this device holds them.
  User? get signedIn => _signedIn;

  void _onReader(Result<User?> reader) {
    // A failure here leaves the reader as they were rather than blanking the
    // surface that names them: the row is still in the replica and the next
    // answer will carry it, and a screen that forgot who was signed in
    // because one query failed would be the worse of the two wrong answers.
    switch (reader) {
      case Ok<User?>(:final User? value):
        _signedIn = value;
        notifyListeners();
      case Error<User?>(:final Exception error):
        _log.warning('the signed-in reader could not be read', error);
    }
  }

  @override
  void dispose() {
    unawaited(_reader.cancel());
    refresh.dispose();
    rename.dispose();
    changeEmail.dispose();
    changePassword.dispose();
    super.dispose();
  }
}

/// What the settings screen knows.
///
/// It is one destination with several sections behind it, and phase 6 fills
/// exactly one: the account, and the sign-out that ends the session on this
/// device and on no other (RN07). The devices, the known servers and the state
/// of the sync arrive in phases 11 and 12.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';

/// The state of the settings screen.
final class SettingsViewModel extends ChangeNotifier {
  /// The view model over [auth].
  SettingsViewModel({required this.auth}) {
    signOut = Command0<void>(auth.signOut);
    _reader = auth.reader().listen(_onReader);
  }

  /// Where the account lives.
  final AuthRepository auth;

  /// Ends the session on this device.
  late final Command0<void> signOut;

  late final StreamSubscription<User?> _reader;

  User? _signedIn;

  /// The reader signed in here, or `null` on a device where nobody is.
  User? get signedIn => _signedIn;

  void _onReader(User? reader) {
    _signedIn = reader;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_reader.cancel());
    super.dispose();
  }
}

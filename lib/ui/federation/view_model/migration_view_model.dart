/// What the home server migration wizard knows.
///
/// **The devices are read when the wizard opens and not when their step is
/// reached.** `ListDevices` is a call to the node being *left*, and the last
/// thing the wizard does is point this device somewhere else — so the one
/// moment it is certain to reach that node is the moment the reader arrives on
/// the first step. Reading later would make the names depend on how long the
/// reader spent on a form.
///
/// **Nothing else is read at all.** The wizard holds what the reader typed and
/// asks the repository once, at the end, because every step before that is
/// deliberation: the operation cannot be undone, and a screen that had already
/// pointed this device at the new node halfway through would have started what
/// it is still asking about.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/federation/federation_repository.dart';
import '../../../domain/models/device.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the migration wizard.
final class MigrationViewModel extends ChangeNotifier {
  /// The view model over [federation], naming the reader out of [auth].
  MigrationViewModel({required this.federation, required this.auth}) {
    devices = Command0<CarriedDevices>(federation.devicesToCarry)..execute();
    migrate = Command1<User, HomeServerMigration>(federation.migrate);
    _reader = auth.reader().listen(_onReader);
  }

  /// The reader's federation, which is where the migration is made.
  final FederationRepository federation;

  /// Who is signed in here, so that the wizard can say which identifier is
  /// about to stop being theirs.
  final AuthRepository auth;

  /// Works out what travels. It runs once, at construction, while this device
  /// is still pointed at the node it is leaving.
  late final Command0<CarriedDevices> devices;

  /// Moves the reader. It runs once and it cannot be undone.
  late final Command1<User, HomeServerMigration> migrate;

  User? _signedIn;

  /// The reader as they are now, or `null` on a device where nobody is.
  User? get signedIn => _signedIn;

  /// The devices this migration would carry, or `null` before the answer.
  CarriedDevices? get carried => switch (devices.result) {
    Ok<CarriedDevices>(:final value) => value,
    _ => null,
  };

  /// How many devices travel, which is what the summary counts.
  int get deviceCount => carried?.devices.length ?? 1;

  /// Whether the node being left named them.
  bool get named => carried?.named ?? true;

  /// The devices to send, with [nameFor] filling in the ones the node being
  /// left could not name.
  ///
  /// The name comes from the screen and not from here for the reason
  /// `Credentials.deviceName` does: it is a user-visible string, and those live
  /// in the ARB. A device carried under an invented name is still a device
  /// carried under the identifier that matters, and the reader can rename it
  /// afterwards.
  List<Device> carrying(String Function(CarriedDevice device) nameFor) =>
      <Device>[
        for (final device in carried?.devices ?? const <CarriedDevice>[])
          Device(
            id: device.id,
            name: device.name ?? nameFor(device),
            platform: device.platform ?? unknownPlatform,
            active: true,
          ),
      ];

  late final StreamSubscription<User?> _reader;

  void _onReader(User? reader) {
    _signedIn = reader;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_reader.cancel());
    devices.dispose();
    migrate.dispose();
    super.dispose();
  }
}

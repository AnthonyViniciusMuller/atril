/// What the home server migration wizard knows.
///
/// **The devices are read when the wizard opens and not when their step is
/// reached.** `ListDevices` is a call to the node being *left*, and the last
/// thing the wizard does is point this device somewhere else — so the one
/// moment it is certain to reach that node is the moment the reader arrives on
/// the first step. Reading later would make the names depend on how long the
/// reader spent on a form.
///
/// **The catalogue is read there too, and for the same reason.**
/// `ListKnownServers` also goes to the node being left, and what it answers is
/// the list of nodes this reader has already discovered — which is what the
/// destination field offers instead of making them type a domain they have
/// already typed once. A catalogue that could not be read is not a failure of
/// the wizard: the field takes a domain either way, which is what it did
/// before the list existed.
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
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/federation');

/// The state of the migration wizard.
final class MigrationViewModel extends ChangeNotifier {
  /// The view model over [federation], naming the reader out of [auth].
  MigrationViewModel({required this.federation, required this.auth}) {
    devices = Command0<CarriedDevices>(federation.devicesToCarry);

    unawaited(devices.execute());
    catalogue = Command0<List<KnownServer>>(_catalogue);

    unawaited(catalogue.execute());
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

  /// Reads the nodes the reader already knows. It runs once, at construction,
  /// while this device is still pointed at the node that holds the catalogue.
  late final Command0<List<KnownServer>> catalogue;

  /// Moves the reader. It runs once and it cannot be undone.
  late final Command1<User, HomeServerMigration> migrate;

  List<KnownServer> _destinations = const <KnownServer>[];

  /// The nodes this migration could go to, which is the catalogue without the
  /// node being left.
  ///
  /// The deactivated ones are in it: `active` says whether a node takes part
  /// in replication, and a reader moving house is not asking about that. The
  /// origin is not, because moving to the node the reader is already on is the
  /// one destination the operation has nothing to do with.
  ///
  /// It is empty until the catalogue has been read, and stays empty when it
  /// could not be — the reader types a domain, as they did before the list
  /// existed.
  List<KnownServer> get destinations => _destinations;

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

  Future<Result<List<KnownServer>>> _catalogue() async {
    final known = await federation.knownServers();

    switch (known) {
      case Ok<List<KnownServer>>(:final List<KnownServer> value):
        _destinations = <KnownServer>[
          for (final server in value)
            if (!server.isOrigin) server,
        ];
        notifyListeners();
      case Error<List<KnownServer>>(:final Exception error):
        // A wizard without the shortcut is the wizard as it was, so this is
        // logged and not surfaced: the step it belongs to is about a domain,
        // and the reader can type one.
        _log.warning('the catalogue of nodes could not be read', error);
    }

    return known;
  }

  late final StreamSubscription<Result<User?>> _reader;

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
    devices.dispose();
    catalogue.dispose();
    migrate.dispose();
    super.dispose();
  }
}

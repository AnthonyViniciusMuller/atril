/// What the devices screen knows.
///
/// It reads once and again after every change, for the reason the catalogue
/// does: the list is what the *node* holds, nothing local changes it, and an
/// answer this device assumed would be right is an answer that disagrees with
/// the node the moment anything else touched the account.
///
/// The per-row actions are methods and not `Command` objects, which is the
/// departure the sync screen makes and for the same reason: a command carries
/// the state of one running action, and there is one of these per device.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../domain/models/device.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the devices screen.
final class DevicesViewModel extends ChangeNotifier {
  /// The view model over [account].
  DevicesViewModel({required this.account}) {
    load = Command0<BoundDevices>(_load);

    unawaited(load.execute());
  }

  /// Where the devices come from.
  final AccountRepository account;

  /// Reads the devices. It runs at construction and again after every change.
  late final Command0<BoundDevices> load;

  BoundDevices _bound = const BoundDevices(
    devices: <Device>[],
    thisDevice: null,
  );

  /// The devices, the ones that may write first.
  ///
  /// An unbound device is still shown — its row is what gives a name to an
  /// identifier the reader's history carries — but it is shown after the ones
  /// the question *which of my devices can write* is actually about.
  List<Device> get devices => <Device>[
    for (final device in _bound.devices)
      if (device.active) device,
    for (final device in _bound.devices)
      if (!device.active) device,
  ];

  /// The identifier this device writes under, or `null` before it is bound.
  String? get thisDevice => _bound.thisDevice;

  /// Renames [device], and answers for it.
  Future<Result<Device>> rename(Device device, String name) async {
    final renamed = await account.renameDevice(deviceId: device.id, name: name);

    await load.execute();

    return renamed;
  }

  /// Unbinds [device], and answers for it.
  Future<Result<void>> revoke(Device device) async {
    final revoked = await account.revokeDevice(device.id);

    await load.execute();

    return revoked;
  }

  Future<Result<BoundDevices>> _load() async {
    final bound = await account.devices();

    if (bound case Ok<BoundDevices>(:final value)) {
      _bound = value;
      notifyListeners();
    }

    return bound;
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}

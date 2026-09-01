/// A device bound to a reader's account.
///
/// Binding is what makes causality resolvable: a vector clock is keyed by a
/// device identifier, so an unregistered writer would introduce an entry no
/// node could attribute to anybody. It is also why a revoked device keeps its
/// row — every operation it ever authored still names it, and a clock entry
/// nobody can resolve cannot be explained to a reader or checked against RN10.
library;

/// The greatest length `identity.devices.name` holds, in characters as
/// PostgreSQL counts a `varchar`.
const int maxDeviceNameLength = 120;

/// The stable code of a device name that is blank or too long.
const String codeInvalidDeviceName = 'invalid_device_name';

/// Why [name] is not a usable device name, or `null` when it is one.
///
/// It is `device.Name.Validate` on the other side, applied here so that a
/// reader is told before a request travels. The blank check is the one
/// `identity.devices_name_not_blank` makes, and it exists for a reason this
/// screen makes visible: a device named nothing cannot be told from another in
/// the list RF11 makes auditable.
String? deviceNameViolation(String name) {
  if (name.isEmpty) {
    return 'it must not be empty';
  }

  if (name.runes.length > maxDeviceNameLength) {
    return 'it must be at most $maxDeviceNameLength characters long';
  }

  return null;
}

/// One of the reader's devices.
final class Device {
  /// The device, as a node reports it.
  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.active,
    this.lastSyncedAt,
  });

  /// The identifier this device's vector-clock entries are counted under.
  final String id;

  /// What the reader calls it.
  final String name;

  /// `android`, `ios`, `web`, `linux`, `macos` or `windows`. Free-form in the
  /// contract on purpose, so that a seventh does not need the node redeployed.
  final String platform;

  /// False once the device has been unbound. The row stays either way.
  final bool active;

  /// The last completed synchronization, absent until the first one.
  ///
  /// It is a diagnostic and not a cursor: what decides what to send is the
  /// position in `SyncService`, for the reason C08 sets out — an operation
  /// stamped early and committed late is skipped by a cursor that has already
  /// moved past it, and it is not delayed, it is lost.
  final DateTime? lastSyncedAt;

  @override
  String toString() =>
      'Device($id, $name, $platform${active ? '' : ', unbound'})';
}

/// How a device names itself when it asks to be bound.
final class DeviceBinding {
  /// The binding of a device that already has an identifier, or of one being
  /// bound for the first time when [deviceId] is `null`.
  const DeviceBinding({
    required this.name,
    required this.platform,
    this.deviceId,
  });

  /// The identity this device already writes under.
  ///
  /// Omitting it on a device that has one is the mistake the whole design is
  /// most vulnerable to: the node would mint a second identifier, and this
  /// device would start a vector-clock entry that never merges with the first.
  final String? deviceId;

  /// What the reader calls it.
  final String name;

  /// The platform, as [Device.platform] spells it.
  final String platform;

  @override
  String toString() =>
      'DeviceBinding(${deviceId ?? 'unbound'}, $name, $platform)';
}

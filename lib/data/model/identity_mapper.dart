/// The identity half of the contract, as domain values: the reader, their
/// devices, and the session a device holds.
library;

import '../../domain/models/device.dart';
import '../../domain/models/session.dart';
import '../../domain/models/user.dart';
import '../services/api/generated/quire/v1/auth.pb.dart' as pb;
import 'mapping.dart';

/// The reader, as a node reports them.
///
/// `email` is read through `hasEmail` rather than off the field, because the
/// contract marks it `optional` and a node that only replicates this reader
/// holds the row without one (C03) — where the absence and the empty string
/// are different claims, proto3 answers the second unless it is asked.
User userOf(pb.User user) => User(
  id: user.id,
  localName: user.localName,
  displayName: user.displayName,
  originServerDomain: user.originServerDomain,
  federatedId: user.federatedId,
  createdAt: wallClockOf(user.createdAt),
  email: user.hasEmail() ? user.email : null,
);

/// One of the reader's devices.
Device deviceOf(pb.Device device) => Device(
  id: device.id.toLowerCase(),
  name: device.name,
  platform: device.platform,
  active: device.active,
  lastSyncedAt: device.hasLastSyncedAt()
      ? wallClockOf(device.lastSyncedAt)
      : null,
);

/// The device, as the wire carries it.
///
/// It is sent in exactly one call — the migration of UC16, which adopts the
/// reader's devices with the identifiers they already hold. C11 is why it has
/// to: every operation names its authoring device and every clock is keyed by
/// one, so a node that minted fresh identifiers would hold a history naming
/// devices that do not exist.
pb.Device wireDevice(Device device) => pb.Device(
  id: device.id,
  name: device.name,
  platform: device.platform,
  active: device.active,
);

/// How a device asks to be bound.
pb.DeviceBinding wireDeviceBinding(DeviceBinding binding) => pb.DeviceBinding(
  deviceId: binding.deviceId,
  name: binding.name,
  platform: binding.platform,
);

/// The session a node issued.
///
/// Both instants are wall clocks and are compared against the time of day, so
/// they are read as one — an expiry is not a position in a causal history and
/// nothing here should let it be mistaken for one.
Session sessionOf(pb.Session session) => Session(
  accessToken: session.accessToken,
  accessTokenExpiresAt: wallClockOf(session.accessTokenExpiresAt),
  refreshToken: session.refreshToken,
  refreshTokenExpiresAt: wallClockOf(session.refreshTokenExpiresAt),
);

/// The reader's own record and the devices that may write on their behalf.
///
/// UC06 and RF11 are one feature and not two, which is why they are one
/// repository. Both are served by `AuthService`, both are answered by exactly
/// one node — the reader's origin server (RN08) — and both are about *the
/// account rather than the library*: nothing here replicates, and a device that
/// cannot reach its node can change none of it.
///
/// It is separate from `AuthRepository` for the same reason: that one is about
/// how this device got a session, and this is about what the reader can do once
/// it has one. Which reader is signed in stays there, and this reads it back
/// from the node only where the node is the authority — the address, which is
/// personal data the node keeps out of the replicated set (RN09).
library;

import '../../../domain/models/device.dart';
import '../../../utils/result.dart';

/// The reader's devices, and which of them is this one.
final class BoundDevices {
  /// The [devices] the node reports, with [thisDevice] naming the one asking.
  const BoundDevices({required this.devices, required this.thisDevice});

  /// Every device bound to the account, the unbound ones included.
  ///
  /// They are included because a revoked device's row survives and its clock
  /// entry survives with it: an operation that names a device nobody can
  /// resolve cannot be explained to a reader or checked against RN10, and this
  /// list is where that identifier gets a name.
  final List<Device> devices;

  /// The identifier this device's vector-clock entries are counted under, or
  /// `null` on one that has never been bound.
  final String? thisDevice;

  @override
  String toString() => 'BoundDevices(${devices.length})';
}

/// The reader's account, as their origin server holds it.
abstract interface class AccountRepository {
  /// RF11. The reader's devices, and which of them is asking.
  Future<Result<BoundDevices>> devices();

  /// Renames the device [deviceId].
  ///
  /// It is the only field of a bound device that is editable: the platform is
  /// what it is, and the identifier is referenced by every clock it appears in.
  Future<Result<Device>> renameDevice({
    required String deviceId,
    required String name,
  });

  /// Unbinds the device [deviceId]: it may no longer write, and its sessions
  /// end.
  ///
  /// The record survives, and so does its entry in every vector clock that
  /// names it. That is not tidiness deferred — it is the only thing that keeps
  /// the history readable, and it is why the screen says *unbound* rather than
  /// *deleted*.
  ///
  /// The device asking is refused here rather than at the node. Revoking it
  /// would end this session and every future one, on the device holding the
  /// screen, with nothing on it to undo the act — and the node, which cannot
  /// tell that request apart from any other, would carry it out.
  Future<Result<void>> revokeDevice(String deviceId);
}

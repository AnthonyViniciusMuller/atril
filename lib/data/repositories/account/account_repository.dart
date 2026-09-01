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
import '../../../domain/models/user.dart';
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
  /// UC06, read. The reader's own record, as the node holds it now.
  ///
  /// It is the one call in this repository whose answer is *also* kept
  /// locally. The reader's row is what phase 6 wrote at sign-in and what every
  /// surface in the app names them by, and the address on it is the field this
  /// screen exists to change — so what the node answers is written there
  /// rather than held beside it, and the two cannot come apart.
  Future<Result<User>> readAccount();

  /// UC06, update. The display name, which is the only field `UpdateUser`
  /// writes.
  ///
  /// The address is a credential in its own right and goes through
  /// [changeEmail]; the password goes through [changePassword]. C14 is why
  /// neither is a field here, and why a field mask could not have expressed
  /// it: a request naming both would have to demand a password for both or
  /// accept one for neither.
  Future<Result<User>> changeDisplayName(String displayName);

  /// UC06, update — the address, proved with the current [password].
  ///
  /// The proof is asked for because the address is the channel UC08 recovers
  /// an account through: whoever can change it can have a recovery credential
  /// sent somewhere of their choosing and then set the password. A session
  /// proves that a device is unlocked, not that the reader is at it.
  Future<Result<User>> changeEmail({
    required String password,
    required String email,
  });

  /// UC06, update — the password, proved with the current one.
  ///
  /// **It ends every session of every device, and the contract does not say
  /// so.** `internal/identity/application/usecase/changepassword` does: a
  /// reader changing their password is responding to a suspicion, and a
  /// session that survived would be the one they suspect. So this device's own
  /// session is cleared here rather than left to fail at the next call, and
  /// the screen warns before it asks.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

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

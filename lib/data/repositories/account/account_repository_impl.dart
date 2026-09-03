/// [AccountRepository] over the node's `AuthService` and this device's own
/// identity row.
library;

import '../../../domain/models/device.dart';
import '../../../domain/models/user.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/errors.dart';
import '../../services/api/session.dart';
import '../../services/local/dao/identity_dao.dart';
import 'account_repository.dart';

final _log = loggerFor('data/account');

/// The operation reading the reader's record reports under.
const String opReadAccount = 'identity/user: read';

/// The operation changing the display name reports under.
const String opChangeDisplayName = 'identity/user: display name';

/// The operation changing the address reports under.
const String opChangeEmail = 'identity/user: email';

/// The operation changing the password reports under.
const String opChangePassword = 'identity/user: password';

/// The node's code for a proof that did not match.
///
/// It is the same code for the address, the password and the deletion, and
/// deliberately so on the other side: it is the same refusal, of the same
/// proof, for the same reason. It is not the code a login raises — there the
/// answer covers who the reader is as well, and here the reader is already
/// established and only the proof failed.
const String codeWrongPassword = 'wrong_password';

/// The operation deleting the account reports under.
const String opDeleteAccount = 'identity/user: delete';

/// The operation reading the reader's devices reports under.
const String opDevices = 'identity/device: list';

/// The operation renaming one reports under.
const String opRenameDevice = 'identity/device: rename';

/// The operation unbinding one reports under.
const String opRevokeDevice = 'identity/device: revoke';

/// The stable code of an attempt to unbind the device making it.
const String codeCannotRevokeThisDevice = 'cannot_revoke_this_device';

/// The reader's account, over the node that authenticates them.
final class AccountRepositoryImpl implements AccountRepository {
  /// The repository over [auth], naming this device out of [identity].
  ///
  /// [session] is what a password change clears. It is nullable so that the
  /// device half of this repository can be built without one; the composition
  /// root always passes it.
  AccountRepositoryImpl({
    required this.auth,
    required this.identity,
    this.session,
  });

  /// The node's `AuthService`, which is the only node that serves any of this.
  final AuthApi auth;

  /// This device's own identity row, which is what says which of the devices
  /// in the list is the one being looked at.
  final IdentityDao identity;

  /// The session this device holds, which a password change ends.
  final SessionHolder? session;

  @override
  Future<Result<User>> readAccount() async {
    try {
      final reader = await auth.getUser();

      await _remember(reader);

      return Result<User>.ok(reader);
    } on Object catch (error) {
      return Result<User>.error(failureFrom(error, op: opReadAccount));
    }
  }

  @override
  Future<Result<User>> changeDisplayName(String displayName) async {
    final wanted = displayName.trim();
    final violation = displayNameViolation(wanted);

    if (violation != null) {
      return Result<User>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the display name $violation',
          code: codeInvalidDisplayName,
          op: opChangeDisplayName,
        ).withField('display_name', violation),
      );
    }

    try {
      final reader = await auth.updateDisplayName(wanted);

      await _remember(reader);

      return Result<User>.ok(reader);
    } on Object catch (error) {
      return Result<User>.error(failureFrom(error, op: opChangeDisplayName));
    }
  }

  @override
  Future<Result<User>> changeEmail({
    required String password,
    required String email,
  }) async {
    final wanted = email.trim();
    final violation = emailViolation(wanted);

    if (violation != null) {
      return Result<User>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the address "$wanted" $violation',
          code: codeInvalidEmail,
          op: opChangeEmail,
        ).withField('email', violation),
      );
    }

    try {
      final reader = await auth.changeEmail(password: password, email: wanted);

      await _remember(reader);

      return Result<User>.ok(reader);
    } on Object catch (error) {
      return Result<User>.error(failureFrom(error, op: opChangeEmail));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final violation = passwordViolation(newPassword);

    if (violation != null) {
      return Result<void>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the new password $violation',
          code: codeInvalidPassword,
          op: opChangePassword,
        ).withField('password', violation),
      );
    }

    try {
      await auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Every session of every device is over. The contract does not say so
      // and the node's own use case does: a reader changing their password is
      // responding to a suspicion, and a session that survived would be the
      // one they suspect. Clearing it here is what stops this device from
      // presenting a credential the node has already thrown away.
      await session?.end();
      _log.info('the password changed; every session ended with it');

      return const Result<void>.ok(null);
    } on Object catch (error) {
      return Result<void>.error(failureFrom(error, op: opChangePassword));
    }
  }

  /// Writes what the node said about the reader into this device's own row.
  ///
  /// A failure here is logged and not returned. The change happened at the
  /// node — which is the authority on all three fields — and reporting the
  /// local write as the failure would tell the reader the opposite of what
  /// occurred.
  Future<void> _remember(User reader) async {
    try {
      await identity.rememberReader(
        id: reader.id,
        localName: reader.localName,
        displayName: reader.displayName,
        originServerDomain: reader.originServerDomain,
        federatedId: reader.federatedId,
        createdAt: reader.createdAt,
        email: reader.email,
      );
    } on Object catch (error) {
      _log.warning('the reader row was not brought into step', error);
    }
  }

  @override
  Future<Result<void>> deleteAccount(String password) async {
    try {
      await auth.deleteUser(password);

      // The session and nothing else. The replica stays: it is the reader's
      // own copy, the export is how they take it elsewhere, and erasing it
      // would destroy the only copy of whatever the node never received.
      await session?.end();
      _log.info('the reader was removed from this node');

      return const Result<void>.ok(null);
    } on Object catch (error) {
      return Result<void>.error(failureFrom(error, op: opDeleteAccount));
    }
  }

  @override
  Future<Result<BoundDevices>> devices() async {
    try {
      // The unbound ones too. A revoked device's row survives and its clock
      // entry survives with it, and this list is the only place an identifier
      // the reader no longer recognizes gets a name.
      final bound = await auth.listDevices(includeInactive: true);

      return Result<BoundDevices>.ok(
        BoundDevices(devices: bound, thisDevice: await identity.deviceId()),
      );
    } on Object catch (error) {
      return Result<BoundDevices>.error(failureFrom(error, op: opDevices));
    }
  }

  @override
  Future<Result<Device>> renameDevice({
    required String deviceId,
    required String name,
  }) async {
    final wanted = name.trim();
    final violation = deviceNameViolation(wanted);

    if (violation != null) {
      return Result<Device>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the device name $violation',
          code: codeInvalidDeviceName,
          op: opRenameDevice,
        ).withField('name', violation),
      );
    }

    try {
      final renamed = await auth.renameDevice(deviceId: deviceId, name: wanted);

      // This device's own row is kept in step, because it is what the next
      // binding sends and what the sync surface would otherwise call by a name
      // the reader has already changed.
      final own = await identity.device();

      if (own != null && own.id == renamed.id) {
        await identity.bindDevice(
          id: own.id,
          name: renamed.name,
          platform: own.platform,
          at: own.boundAt,
        );
      }

      return Result<Device>.ok(renamed);
    } on Object catch (error) {
      return Result<Device>.error(failureFrom(error, op: opRenameDevice));
    }
  }

  @override
  Future<Result<void>> revokeDevice(String deviceId) async {
    // Refused here and not at the node, which cannot tell this request apart
    // from any other. Unbinding the device holding the screen would end this
    // session and every future one, with nothing left on it to undo the act.
    if (deviceId == await identity.deviceId()) {
      return Result<void>.error(
        const AppException(
          kind: ErrorKind.failedPrecondition,
          message: 'a device cannot unbind itself',
          code: codeCannotRevokeThisDevice,
          op: opRevokeDevice,
        ),
      );
    }

    try {
      await auth.revokeDevice(deviceId);
      _log.info('$deviceId may no longer write');

      return const Result<void>.ok(null);
    } on Object catch (error) {
      return Result<void>.error(failureFrom(error, op: opRevokeDevice));
    }
  }
}

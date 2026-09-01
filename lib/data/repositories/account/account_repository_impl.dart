/// [AccountRepository] over the node's `AuthService` and this device's own
/// identity row.
library;

import '../../../domain/models/device.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/errors.dart';
import '../../services/local/dao/identity_dao.dart';
import 'account_repository.dart';

final _log = loggerFor('data/account');

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
  AccountRepositoryImpl({required this.auth, required this.identity});

  /// The node's `AuthService`, which is the only node that serves any of this.
  final AuthApi auth;

  /// This device's own identity row, which is what says which of the devices
  /// in the list is the one being looked at.
  final IdentityDao identity;

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
    } on Exception catch (error) {
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
    } on Exception catch (error) {
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
    } on Exception catch (error) {
      return Result<void>.error(failureFrom(error, op: opRevokeDevice));
    }
  }
}

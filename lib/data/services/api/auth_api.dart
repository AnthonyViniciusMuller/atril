/// `AuthService`: who the reader is, how they prove it, and which of their
/// devices may write on their behalf.
///
/// It is the only service in the contract served by exactly one node for any
/// given reader — their origin server (RN08) — and the only one that ever sees
/// a password. A node that merely replicates a reader holds their row without
/// an address and without a password (C03), so it can serve none of these
/// calls; the discovery in `FederationApi` is how a device finds the one that
/// can.
///
/// It implements [SessionRefresher], which is the loop closed: the session
/// authorizes the calls of the client that refreshes it.
library;

import 'package:protobuf/well_known_types/google/protobuf/field_mask.pb.dart';

import '../../../domain/models/device.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/user.dart';
import '../../model/identity_mapper.dart';
import 'api_client.dart';
import 'generated/quire/v1/auth.pbgrpc.dart' as pb;
import 'session.dart';

/// The operations this client reports its failures under.
const String opRegister = 'identity/user: register';

/// The operation a sign-in reports under.
const String opLogin = 'identity/session: login';

/// The operation a sign-out reports under.
const String opLogout = 'identity/session: logout';

/// The operation a refresh reports under.
const String opRefresh = 'identity/session: refresh';

/// The operation the reader's own record reports under.
const String opUser = 'identity/user: read';

/// The operation a change to the reader's record reports under.
const String opUpdateUser = 'identity/user: update';

/// The operation a credential change reports under.
const String opCredentials = 'identity/user: credentials';

/// The operation account recovery reports under.
const String opRecovery = 'identity/user: recover';

/// The operations about this reader's devices.
const String opDevices = 'identity/device';

/// What a sign-in answered with.
///
/// The device is part of it because binding happens here: a device logging in
/// for the first time is given the identifier its vector-clock entries are
/// counted under from then on, and losing that identifier is the one mistake
/// this app cannot recover from.
final class SignIn {
  /// The session, the reader and the device the node bound.
  const SignIn({
    required this.session,
    required this.user,
    required this.device,
  });

  /// What this device presents from now on.
  final Session session;

  /// Who signed in.
  final User user;

  /// The device, with the identifier it must write under.
  final Device device;
}

/// `AuthService`, as this app calls it.
final class AuthApi extends ApiClient implements SessionRefresher {
  /// The client over [channel], authorized by [session].
  AuthApi({required super.channel, required super.session});

  late final pb.AuthServiceClient _stub = pb.AuthServiceClient(
    channel,
    interceptors: interceptors,
  );

  /// UC14. Creates the reader on this node and binds them to it.
  ///
  /// The server half of the identifier is not a parameter: it is which node
  /// the call was addressed to.
  Future<User> registerUser({
    required String localName,
    required String displayName,
    required String email,
    required String password,
  }) => call(
    opRegister,
    () async => userOf(
      (await _stub.registerUser(
        pb.RegisterUserRequest(
          localName: localName,
          displayName: displayName,
          email: email,
          password: password,
        ),
      )).user,
    ),
  );

  /// UC07. Verifies the password, binds [device] if it is not bound yet, and
  /// issues the session.
  ///
  /// [identifier] is either half of what identifies the reader to their own
  /// node, and which of the two is decided here rather than by the node: a
  /// local name cannot contain an `@` and an address must, and the contract
  /// spells the choice as a `oneof` precisely so that a server is not left
  /// parsing it.
  ///
  /// The session it answers with is *not* adopted here. Signing in is a
  /// decision the onboarding flow makes with the reader in front of it, and it
  /// is what calls [SessionHolder.begin].
  Future<SignIn> login({
    required String identifier,
    required String password,
    required DeviceBinding device,
  }) => call(opLogin, () async {
    final request = pb.LoginRequest(
      password: password,
      device: wireDeviceBinding(device),
    );

    if (identifier.contains('@')) {
      request.email = identifier;
    } else {
      request.localName = identifier;
    }

    final answer = await _stub.login(request);

    return SignIn(
      session: sessionOf(answer.session),
      user: userOf(answer.user),
      device: deviceOf(answer.device),
    );
  });

  /// UC07, the other half. Ends the session of the device that holds
  /// [refreshToken] and of no other device (RN07).
  ///
  /// The credential is presented rather than inferred from the session, which
  /// is what lets a device whose access token has already expired sign out
  /// without refreshing first.
  Future<void> logout(String refreshToken) => call(
    opLogout,
    () => _stub.logout(pb.LogoutRequest(refreshToken: refreshToken)),
  );

  /// Exchanges a refresh credential for a session.
  ///
  /// The credential presented is consumed and the reply carries its
  /// replacement, which is why [SessionHolder] writes the new one before
  /// adopting the session.
  @override
  Future<Session> refreshSession(String refreshToken) => call(
    opRefresh,
    () async => sessionOf(
      (await _stub.refreshSession(
        pb.RefreshSessionRequest(refreshToken: refreshToken),
      )).session,
    ),
  );

  /// UC06, read. The caller's own record, which is the only one a node serves.
  Future<User> getUser() => call(
    opUser,
    () async => userOf((await _stub.getUser(pb.GetUserRequest())).user),
  );

  /// UC06, update. The display name is the only field this call writes.
  ///
  /// The mask names it explicitly, because absence is not emptiness: a client
  /// that sent no mask and one that meant to clear the field look identical
  /// without one. The address goes through [changeEmail] and the password
  /// through [changePassword], and C14 is why neither is a field here.
  Future<User> updateDisplayName(String displayName) => call(
    opUpdateUser,
    () async => userOf(
      (await _stub.updateUser(
        pb.UpdateUserRequest(
          user: pb.User(displayName: displayName),
          updateMask: FieldMask(paths: <String>['display_name']),
        ),
      )).user,
    ),
  );

  /// UC06. Changes the password, proving the reader is at the device.
  ///
  /// A session proves that a device is unlocked and not that the reader is at
  /// it, which is why the current password is asked for.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => call(
    opCredentials,
    () => _stub.changePassword(
      pb.ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    ),
  );

  /// UC06. Changes the address, which is a credential in its own right (C14):
  /// whoever can change it can have a recovery credential sent somewhere of
  /// their choosing.
  Future<User> changeEmail({required String password, required String email}) =>
      call(
        opCredentials,
        () async => userOf(
          (await _stub.changeEmail(
            pb.ChangeEmailRequest(password: password, email: email),
          )).user,
        ),
      );

  /// UC06, delete. Removes the reader from this node, with everything that
  /// cascades from them.
  ///
  /// It is not a migration and it does not reach the replicas that already
  /// hold a copy — phase 12's screen is where that is said rather than
  /// implied.
  Future<void> deleteUser(String password) => call(
    opCredentials,
    () => _stub.deleteUser(pb.DeleteUserRequest(password: password)),
  );

  /// UC08, first half. Sends a recovery credential to the address on record.
  ///
  /// It reports the same outcome whether or not the address is registered
  /// here, so that it cannot be used to find out who is.
  Future<void> requestPasswordRecovery(String email) => call(
    opRecovery,
    () => _stub.requestPasswordRecovery(
      pb.RequestPasswordRecoveryRequest(email: email),
    ),
  );

  /// UC08, second half. Consumes the recovery credential and sets the
  /// password, ending every session of every device.
  Future<void> resetPassword({
    required String recoveryToken,
    required String newPassword,
  }) => call(
    opRecovery,
    () => _stub.resetPassword(
      pb.ResetPasswordRequest(
        recoveryToken: recoveryToken,
        newPassword: newPassword,
      ),
    ),
  );

  /// RF11, UC10. Binds a device without logging in with it, for pairing a
  /// second application from an already authenticated one.
  Future<Device> registerDevice({
    required String name,
    required String platform,
  }) => call(
    opDevices,
    () async => deviceOf(
      (await _stub.registerDevice(
        pb.RegisterDeviceRequest(name: name, platform: platform),
      )).device,
    ),
  );

  /// The reader's devices, which is what makes RF11 auditable: a clock entry
  /// is keyed by a device id, and this is where those ids get a name.
  Future<List<Device>> listDevices({bool includeInactive = false}) => call(
    opDevices,
    () async => <Device>[
      for (final device in (await _stub.listDevices(
        pb.ListDevicesRequest(includeInactive: includeInactive),
      )).devices)
        deviceOf(device),
    ],
  );

  /// Renames a device. Nothing else about a bound one is editable.
  Future<Device> renameDevice({
    required String deviceId,
    required String name,
  }) => call(
    opDevices,
    () async => deviceOf(
      (await _stub.updateDevice(
        pb.UpdateDeviceRequest(
          deviceId: deviceId,
          device: pb.Device(name: name),
          updateMask: FieldMask(paths: <String>['name']),
        ),
      )).device,
    ),
  );

  /// Unbinds a device: it may no longer write, and its sessions end.
  ///
  /// The record survives, because every operation it authored still names it
  /// and a clock entry nobody can resolve cannot be explained to the reader.
  Future<void> revokeDevice(String deviceId) => call(
    opDevices,
    () => _stub.revokeDevice(pb.RevokeDeviceRequest(deviceId: deviceId)),
  );
}

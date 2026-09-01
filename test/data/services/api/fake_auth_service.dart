/// A node that answers `AuthService`, for the tests that need a real socket.
///
/// It is the smallest thing that behaves like the node in the two ways the
/// session depends on: an authenticated method refuses a call whose bearer
/// token is not the one currently issued, and `RefreshSession` consumes the
/// credential presented and answers with its replacement.
library;

import 'dart:convert';

import 'package:atril/data/services/api/generated/google/rpc/error_details.pb.dart';
import 'package:atril/data/services/api/generated/google/rpc/status.pb.dart'
    as rpc;
import 'package:atril/data/services/api/generated/quire/v1/auth.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

/// The reader this node hosts.
///
/// It is a uuid and not a readable name because it is stored: the local
/// identity tables hold exactly thirty-six characters, which is what the node
/// mints and what a test that writes one has to send.
const String fakeReaderId = '22222222-2222-4222-8222-222222222222';

/// The identifier this node mints for a device being bound for the first time.
const String fakeMintedDeviceId = '33333333-3333-4333-8333-333333333333';

/// The node, as far as a session is concerned.
final class FakeAuthService extends AuthServiceBase {
  /// The node issuing tokens numbered from [issued].
  FakeAuthService({this.accessTokenLifetime = const Duration(minutes: 5)});

  /// How long an access token this node issues is valid for.
  final Duration accessTokenLifetime;

  int _issued = 1;

  /// The access token this node currently accepts.
  String accessToken = 'access-1';

  /// The refresh credential this node currently accepts.
  String refreshToken = 'refresh-1';

  /// What every call presented in its `authorization` metadata, in order,
  /// including the calls that presented nothing.
  final List<String?> presented = <String?>[];

  /// How many refreshes this node has served.
  int refreshes = 0;

  /// Every address a recovery was asked for, in order.
  final List<String> recoveries = <String>[];

  /// Every password this node was asked to set through a reset, in order.
  final List<String> reset = <String>[];

  /// The recovery credential this node will take.
  static const String recoveryToken = 'recovery-1';

  /// Every refresh credential this node was asked to revoke, in order.
  final List<String> loggedOut = <String>[];

  /// Every registration this node was sent, in order.
  final List<RegisterUserRequest> registered = <RegisterUserRequest>[];

  /// The local name this node answers `ALREADY_EXISTS` for.
  static const String takenLocalName = 'taken';

  /// Issues the next pair, as a rotation does.
  Session rotate() {
    _issued++;
    accessToken = 'access-$_issued';
    refreshToken = 'refresh-$_issued';

    return _session();
  }

  /// Stops accepting the access token this node last issued, leaving the
  /// refresh credential good. It is what an expiry looks like from the
  /// caller's side, without a test having to wait for one.
  void expireAccessToken() {
    accessToken = 'expired-$_issued';
  }

  Session _session() {
    final now = DateTime.now().toUtc();

    return Session(
      accessToken: accessToken,
      accessTokenExpiresAt: Timestamp.fromDateTime(
        now.add(accessTokenLifetime),
      ),
      refreshToken: refreshToken,
      refreshTokenExpiresAt: Timestamp.fromDateTime(
        now.add(const Duration(days: 30)),
      ),
    );
  }

  void _record(ServiceCall call) =>
      presented.add(call.clientMetadata?['authorization']);

  void _authenticate(ServiceCall call) {
    _record(call);

    if (call.clientMetadata?['authorization'] != 'Bearer $accessToken') {
      throw GrpcError.unauthenticated('this call needs an access token');
    }
  }

  @override
  Future<LoginResponse> login(ServiceCall call, LoginRequest request) async {
    _record(call);

    return LoginResponse(
      session: _session(),
      user: User(
        id: fakeReaderId,
        localName: 'reader',
        displayName: 'A Reader',
        originServerDomain: 'quire-a.example',
        federatedId: '@reader:quire-a.example',
        email: 'reader@quire-a.example',
        createdAt: Timestamp.fromDateTime(DateTime.utc(2026, 1, 2, 3, 4, 5)),
      ),
      // The device the reader named, with the identifier it must write under
      // from now on. A device being bound for the first time sends none and
      // learns it here.
      device: Device(
        id: request.device.hasDeviceId()
            ? request.device.deviceId
            : fakeMintedDeviceId,
        name: request.device.name,
        platform: request.device.platform,
        active: true,
      ),
    );
  }

  @override
  Future<RefreshSessionResponse> refreshSession(
    ServiceCall call,
    RefreshSessionRequest request,
  ) async {
    _record(call);
    refreshes++;

    if (request.refreshToken != refreshToken) {
      throw GrpcError.unauthenticated('the refresh credential was consumed');
    }

    return RefreshSessionResponse(session: rotate());
  }

  /// The reader this node holds, which the account calls read and write.
  ///
  /// It carries the whole record rather than the two fields the session tests
  /// needed, because UC06 is about the rest of it: the address is what
  /// `ChangeEmail` moves, and the identifier is what a screen shows and never
  /// edits.
  User reader = User(
    id: fakeReaderId,
    localName: 'reader',
    displayName: 'A leitora',
    originServerDomain: 'quire-a.example',
    federatedId: '@reader:quire-a.example',
    email: 'reader@example.com',
    createdAt: Timestamp.fromDateTime(DateTime.utc(2026)),
  );

  /// The password this node accepts as proof.
  String password = 'uma senha boa';

  @override
  Future<GetUserResponse> getUser(
    ServiceCall call,
    GetUserRequest request,
  ) async {
    _authenticate(call);

    return GetUserResponse(user: reader);
  }

  @override
  Future<RegisterUserResponse> registerUser(
    ServiceCall call,
    RegisterUserRequest request,
  ) async {
    _record(call);
    registered.add(request);

    if (request.localName == takenLocalName) {
      throw GrpcError.alreadyExists('that name is already taken here');
    }

    // Public, and answering with no session: what follows a registration is a
    // login like anybody else's.
    return RegisterUserResponse(
      user: User(
        id: fakeReaderId,
        localName: request.localName,
        displayName: request.displayName,
        originServerDomain: 'quire-a.example',
        federatedId: '@${request.localName}:quire-a.example',
        email: request.email,
        createdAt: Timestamp.fromDateTime(DateTime.utc(2026, 1, 2, 3, 4, 5)),
      ),
    );
  }

  @override
  Future<RequestPasswordRecoveryResponse> requestPasswordRecovery(
    ServiceCall call,
    RequestPasswordRecoveryRequest request,
  ) async {
    _record(call);
    recoveries.add(request.email);

    // Empty, and empty on purpose: the same outcome whether or not the address
    // is registered here.
    return RequestPasswordRecoveryResponse();
  }

  @override
  Future<ResetPasswordResponse> resetPassword(
    ServiceCall call,
    ResetPasswordRequest request,
  ) async {
    _record(call);

    if (request.recoveryToken != recoveryToken) {
      throw GrpcError.invalidArgument('that credential is not one of ours');
    }

    reset.add(request.newPassword);

    return ResetPasswordResponse();
  }

  @override
  Future<LogoutResponse> logout(ServiceCall call, LogoutRequest request) async {
    _record(call);
    loggedOut.add(request.refreshToken);

    return LogoutResponse();
  }

  // Everything below is part of the contract and not part of what these tests
  // exercise. They answer as a node that does not implement them would, which
  // is louder than a null.

  Never _unimplemented() => throw GrpcError.unimplemented('not in this fake');

  /// Every update to the record, as `(paths, displayName)`.
  final List<(List<String>, String)> updated = <(List<String>, String)>[];

  /// Every password change, as `(current, next)`.
  final List<(String, String)> passwords = <(String, String)>[];

  /// Every address change, as `(password, email)`.
  final List<(String, String)> emails = <(String, String)>[];

  /// Every password a deletion was proved with, in order.
  final List<String> deleted = <String>[];

  /// The address this node answers `ALREADY_EXISTS` for.
  static const String registeredEmail = 'taken@example.com';

  /// The refusal all three credential calls raise for a proof that did not
  /// match, with the code the node attaches to it.
  ///
  /// It is the same code for the address, the password and the deletion,
  /// deliberately so on the other side: the same refusal, of the same proof,
  /// for the same reason.
  Never _wrongPassword() => _refuse(
    StatusCode.invalidArgument,
    'wrong_password',
    'the password does '
        'not match',
  );

  /// A refusal carrying [reason] the way a node carries it.
  ///
  /// The status detail travels in a trailer and not in `GrpcError.details`,
  /// which is what a real node does and what `package:grpc` only serializes
  /// this way: a server that set `details` alone would send a status the
  /// client reads with an empty code.
  Never _refuse(int status, String reason, String message) {
    final detail = rpc.Status(
      code: status,
      message: message,
      details: <Any>[Any.pack(ErrorInfo(reason: reason, domain: 'quire.v1'))],
    );

    throw GrpcError.custom(status, message, null, null, <String, String>{
      'grpc-status-details-bin': base64Url.encode(detail.writeToBuffer()),
    });
  }

  @override
  Future<UpdateUserResponse> updateUser(
    ServiceCall call,
    UpdateUserRequest request,
  ) async {
    _authenticate(call);
    updated.add((request.updateMask.paths, request.user.displayName));

    reader = reader.deepCopy()..displayName = request.user.displayName;

    return UpdateUserResponse(user: reader);
  }

  @override
  Future<ChangePasswordResponse> changePassword(
    ServiceCall call,
    ChangePasswordRequest request,
  ) async {
    _authenticate(call);
    passwords.add((request.currentPassword, request.newPassword));

    if (request.currentPassword != password) {
      _wrongPassword();
    }

    password = request.newPassword;

    // Every session of every device ends with it, which the node does and the
    // contract does not say.
    rotate();

    return ChangePasswordResponse();
  }

  @override
  Future<ChangeEmailResponse> changeEmail(
    ServiceCall call,
    ChangeEmailRequest request,
  ) async {
    _authenticate(call);
    emails.add((request.password, request.email));

    if (request.password != password) {
      _wrongPassword();
    }

    if (request.email == registeredEmail) {
      _refuse(
        StatusCode.alreadyExists,
        'email_registered',
        'that address is registered here',
      );
    }

    reader = reader.deepCopy()..email = request.email;

    return ChangeEmailResponse(user: reader);
  }

  @override
  Future<DeleteUserResponse> deleteUser(
    ServiceCall call,
    DeleteUserRequest request,
  ) async {
    _authenticate(call);
    deleted.add(request.password);

    if (request.password != password) {
      _wrongPassword();
    }

    return DeleteUserResponse();
  }

  @override
  Future<RegisterDeviceResponse> registerDevice(
    ServiceCall call,
    RegisterDeviceRequest request,
  ) async => _unimplemented();

  /// The reader's devices, as this node holds them.
  ///
  /// It is empty by default, which is a node that has never been asked rather
  /// than a reader with no device: a test that wants the list sets it.
  final List<Device> devices = <Device>[];

  /// Whether each listing asked for the unbound devices, in order.
  final List<bool> listedDevices = <bool>[];

  /// What the next call to a method that checks it fails with, or `null`.
  ///
  /// It is a node that is not there, which is a different thing from a node
  /// that refuses a credential: the second is answered by a refresh and a
  /// retry, and this is not answered at all.
  GrpcError? refusal;

  @override
  Future<ListDevicesResponse> listDevices(
    ServiceCall call,
    ListDevicesRequest request,
  ) async {
    _authenticate(call);

    final refused = refusal;

    if (refused != null) {
      refusal = null;

      throw refused;
    }

    listedDevices.add(request.includeInactive);

    return ListDevicesResponse(
      devices: <Device>[
        for (final device in devices)
          if (request.includeInactive || device.active) device,
      ],
    );
  }

  /// Every rename, as `(deviceId, name)`.
  final List<(String, String)> renamed = <(String, String)>[];

  /// Every device an unbinding was asked for, in order.
  final List<String> unbound = <String>[];

  @override
  Future<UpdateDeviceResponse> updateDevice(
    ServiceCall call,
    UpdateDeviceRequest request,
  ) async {
    _authenticate(call);
    renamed.add((request.deviceId, request.device.name));

    final device = _device(request.deviceId)..name = request.device.name;

    return UpdateDeviceResponse(device: device);
  }

  @override
  Future<RevokeDeviceResponse> revokeDevice(
    ServiceCall call,
    RevokeDeviceRequest request,
  ) async {
    _authenticate(call);
    unbound.add(request.deviceId);

    // Deactivated and kept, as the node does it: every operation the device
    // authored still names it.
    _device(request.deviceId).active = false;

    return RevokeDeviceResponse();
  }

  Device _device(String id) {
    for (final device in devices) {
      if (device.id == id) {
        return device;
      }
    }

    throw GrpcError.notFound('no such device');
  }
}

/// A node that answers `AuthService`, for the tests that need a real socket.
///
/// It is the smallest thing that behaves like the node in the two ways the
/// session depends on: an authenticated method refuses a call whose bearer
/// token is not the one currently issued, and `RefreshSession` consumes the
/// credential presented and answers with its replacement.
library;

import 'package:atril/data/services/api/generated/quire/v1/auth.pbgrpc.dart';
import 'package:grpc/grpc.dart';
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

  @override
  Future<GetUserResponse> getUser(
    ServiceCall call,
    GetUserRequest request,
  ) async {
    _authenticate(call);

    return GetUserResponse(
      user: User(id: fakeReaderId, localName: 'reader'),
    );
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
  Future<LogoutResponse> logout(ServiceCall call, LogoutRequest request) async {
    _record(call);
    loggedOut.add(request.refreshToken);

    return LogoutResponse();
  }

  // Everything below is part of the contract and not part of what these tests
  // exercise. They answer as a node that does not implement them would, which
  // is louder than a null.

  Never _unimplemented() => throw GrpcError.unimplemented('not in this fake');

  @override
  Future<UpdateUserResponse> updateUser(
    ServiceCall call,
    UpdateUserRequest request,
  ) async => _unimplemented();

  @override
  Future<ChangePasswordResponse> changePassword(
    ServiceCall call,
    ChangePasswordRequest request,
  ) async => _unimplemented();

  @override
  Future<ChangeEmailResponse> changeEmail(
    ServiceCall call,
    ChangeEmailRequest request,
  ) async => _unimplemented();

  @override
  Future<DeleteUserResponse> deleteUser(
    ServiceCall call,
    DeleteUserRequest request,
  ) async => _unimplemented();

  @override
  Future<RequestPasswordRecoveryResponse> requestPasswordRecovery(
    ServiceCall call,
    RequestPasswordRecoveryRequest request,
  ) async => _unimplemented();

  @override
  Future<ResetPasswordResponse> resetPassword(
    ServiceCall call,
    ResetPasswordRequest request,
  ) async => _unimplemented();

  @override
  Future<RegisterDeviceResponse> registerDevice(
    ServiceCall call,
    RegisterDeviceRequest request,
  ) async => _unimplemented();

  @override
  Future<ListDevicesResponse> listDevices(
    ServiceCall call,
    ListDevicesRequest request,
  ) async => _unimplemented();

  @override
  Future<UpdateDeviceResponse> updateDevice(
    ServiceCall call,
    UpdateDeviceRequest request,
  ) async => _unimplemented();

  @override
  Future<RevokeDeviceResponse> revokeDevice(
    ServiceCall call,
    RevokeDeviceRequest request,
  ) async => _unimplemented();
}

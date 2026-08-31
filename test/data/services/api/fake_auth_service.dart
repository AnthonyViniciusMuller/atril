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

    return LoginResponse(session: _session());
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
      user: User(id: 'a-reader', localName: 'reader'),
    );
  }

  @override
  Future<LogoutResponse> logout(ServiceCall call, LogoutRequest request) async {
    _record(call);

    return LogoutResponse();
  }

  // Everything below is part of the contract and not part of what these tests
  // exercise. They answer as a node that does not implement them would, which
  // is louder than a null.

  Never _unimplemented() => throw GrpcError.unimplemented('not in this fake');

  @override
  Future<RegisterUserResponse> registerUser(
    ServiceCall call,
    RegisterUserRequest request,
  ) async => _unimplemented();

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

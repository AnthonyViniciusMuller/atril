// This is a generated file - do not edit.
//
// Generated from quire/v1/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'auth.pb.dart' as $0;

export 'auth.pb.dart';

/// AuthService is the only service in the contract that is served by exactly one
/// node for any given reader, and the only one that ever sees a password.
@$pb.GrpcServiceName('quire.v1.AuthService')
class AuthServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AuthServiceClient(super.channel, {super.options, super.interceptors});

  /// UC14. Creates the reader on this node and, in doing so, binds them to it:
  /// the identifier is @local_name:<this node's domain>, so the server half is
  /// not a parameter — it is which node the call was addressed to. A client
  /// finds that address with FederationService.DiscoverServer, which is the
  /// UC13 that UC14 includes.
  $grpc.ResponseFuture<$0.RegisterUserResponse> registerUser(
    $0.RegisterUserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerUser, request, options: options);
  }

  /// UC06, read. Returns the caller's own record. A node never serves one
  /// reader's record to another: the address is personal data kept out of the
  /// replicated set on purpose (RN09), and the only party entitled to read it
  /// is the reader themselves.
  $grpc.ResponseFuture<$0.GetUserResponse> getUser(
    $0.GetUserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUser, request, options: options);
  }

  /// UC06, update.
  $grpc.ResponseFuture<$0.UpdateUserResponse> updateUser(
    $0.UpdateUserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateUser, request, options: options);
  }

  /// UC06, update — the credentials half, which a field mask cannot express:
  /// changing a password takes the old one as well as the new.
  $grpc.ResponseFuture<$0.ChangePasswordResponse> changePassword(
    $0.ChangePasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changePassword, request, options: options);
  }

  /// UC06, update — the address, which is not one registration field among
  /// others and therefore not part of UpdateUser.
  ///
  /// The address is the channel UC08 recovers an account through, so whoever can
  /// change it can have a recovery credential sent somewhere of their choosing
  /// and then set the password. A session proves that a device is unlocked, not
  /// that the reader is at it, which is exactly why ChangePassword asks for the
  /// current password — and this call asks for it for the same reason. C14 in
  /// docs/tcc-corrections.md is the finding.
  ///
  /// It is its own call rather than a password field on UpdateUserRequest
  /// because a field mask has no way to say "this one field needs a credential":
  /// a request that named display_name and email would either demand a password
  /// for both or accept one for neither.
  $grpc.ResponseFuture<$0.ChangeEmailResponse> changeEmail(
    $0.ChangeEmailRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeEmail, request, options: options);
  }

  /// UC06, delete. Removes the reader from this node, with everything that
  /// cascades from them. It is not a migration: RF17 moves a reader to another
  /// origin server and is served by FederationService.MigrateHomeServer.
  $grpc.ResponseFuture<$0.DeleteUserResponse> deleteUser(
    $0.DeleteUserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteUser, request, options: options);
  }

  /// UC07, first half. Verifies the password, binds the calling device if it is
  /// not bound yet, and issues the session.
  $grpc.ResponseFuture<$0.LoginResponse> login(
    $0.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  /// UC07, second half. Consumes the refresh credential presented, which ends
  /// the session of the device that holds it and of no other device (RN07: a
  /// reader uses several at once).
  $grpc.ResponseFuture<$0.LogoutResponse> logout(
    $0.LogoutRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$logout, request, options: options);
  }

  /// Exchanges a refresh credential for a new session. The access token is
  /// short-lived by RNF11, so this is the call a device makes most often after
  /// the sync ones.
  $grpc.ResponseFuture<$0.RefreshSessionResponse> refreshSession(
    $0.RefreshSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshSession, request, options: options);
  }

  /// UC08, first half. Sends a recovery credential to the address on record.
  $grpc.ResponseFuture<$0.RequestPasswordRecoveryResponse>
      requestPasswordRecovery(
    $0.RequestPasswordRecoveryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$requestPasswordRecovery, request,
        options: options);
  }

  /// UC08, second half. Consumes the recovery credential and sets the new
  /// password.
  $grpc.ResponseFuture<$0.ResetPasswordResponse> resetPassword(
    $0.ResetPasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }

  /// Binds a device without logging in with it, for pairing a second
  /// application from an already authenticated one (RF11, UC10).
  $grpc.ResponseFuture<$0.RegisterDeviceResponse> registerDevice(
    $0.RegisterDeviceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerDevice, request, options: options);
  }

  /// The reader's devices, which is what makes RF11 auditable: a vector clock
  /// entry is keyed by a device id, and this is where those ids get a name.
  $grpc.ResponseFuture<$0.ListDevicesResponse> listDevices(
    $0.ListDevicesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDevices, request, options: options);
  }

  /// Renames a device. Nothing else about a bound device is editable — its
  /// platform is what it is, and its id is referenced by every clock it appears
  /// in.
  $grpc.ResponseFuture<$0.UpdateDeviceResponse> updateDevice(
    $0.UpdateDeviceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateDevice, request, options: options);
  }

  /// Unbinds a device: it may no longer write, and its sessions end. The record
  /// itself survives, because every operation it ever authored is still keyed
  /// by its id and a clock naming a device nobody can resolve cannot be
  /// explained to the reader or checked against RN10.
  $grpc.ResponseFuture<$0.RevokeDeviceResponse> revokeDevice(
    $0.RevokeDeviceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeDevice, request, options: options);
  }

  // method descriptors

  static final _$registerUser =
      $grpc.ClientMethod<$0.RegisterUserRequest, $0.RegisterUserResponse>(
          '/quire.v1.AuthService/RegisterUser',
          ($0.RegisterUserRequest value) => value.writeToBuffer(),
          $0.RegisterUserResponse.fromBuffer);
  static final _$getUser =
      $grpc.ClientMethod<$0.GetUserRequest, $0.GetUserResponse>(
          '/quire.v1.AuthService/GetUser',
          ($0.GetUserRequest value) => value.writeToBuffer(),
          $0.GetUserResponse.fromBuffer);
  static final _$updateUser =
      $grpc.ClientMethod<$0.UpdateUserRequest, $0.UpdateUserResponse>(
          '/quire.v1.AuthService/UpdateUser',
          ($0.UpdateUserRequest value) => value.writeToBuffer(),
          $0.UpdateUserResponse.fromBuffer);
  static final _$changePassword =
      $grpc.ClientMethod<$0.ChangePasswordRequest, $0.ChangePasswordResponse>(
          '/quire.v1.AuthService/ChangePassword',
          ($0.ChangePasswordRequest value) => value.writeToBuffer(),
          $0.ChangePasswordResponse.fromBuffer);
  static final _$changeEmail =
      $grpc.ClientMethod<$0.ChangeEmailRequest, $0.ChangeEmailResponse>(
          '/quire.v1.AuthService/ChangeEmail',
          ($0.ChangeEmailRequest value) => value.writeToBuffer(),
          $0.ChangeEmailResponse.fromBuffer);
  static final _$deleteUser =
      $grpc.ClientMethod<$0.DeleteUserRequest, $0.DeleteUserResponse>(
          '/quire.v1.AuthService/DeleteUser',
          ($0.DeleteUserRequest value) => value.writeToBuffer(),
          $0.DeleteUserResponse.fromBuffer);
  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.LoginResponse>(
      '/quire.v1.AuthService/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      $0.LoginResponse.fromBuffer);
  static final _$logout =
      $grpc.ClientMethod<$0.LogoutRequest, $0.LogoutResponse>(
          '/quire.v1.AuthService/Logout',
          ($0.LogoutRequest value) => value.writeToBuffer(),
          $0.LogoutResponse.fromBuffer);
  static final _$refreshSession =
      $grpc.ClientMethod<$0.RefreshSessionRequest, $0.RefreshSessionResponse>(
          '/quire.v1.AuthService/RefreshSession',
          ($0.RefreshSessionRequest value) => value.writeToBuffer(),
          $0.RefreshSessionResponse.fromBuffer);
  static final _$requestPasswordRecovery = $grpc.ClientMethod<
          $0.RequestPasswordRecoveryRequest,
          $0.RequestPasswordRecoveryResponse>(
      '/quire.v1.AuthService/RequestPasswordRecovery',
      ($0.RequestPasswordRecoveryRequest value) => value.writeToBuffer(),
      $0.RequestPasswordRecoveryResponse.fromBuffer);
  static final _$resetPassword =
      $grpc.ClientMethod<$0.ResetPasswordRequest, $0.ResetPasswordResponse>(
          '/quire.v1.AuthService/ResetPassword',
          ($0.ResetPasswordRequest value) => value.writeToBuffer(),
          $0.ResetPasswordResponse.fromBuffer);
  static final _$registerDevice =
      $grpc.ClientMethod<$0.RegisterDeviceRequest, $0.RegisterDeviceResponse>(
          '/quire.v1.AuthService/RegisterDevice',
          ($0.RegisterDeviceRequest value) => value.writeToBuffer(),
          $0.RegisterDeviceResponse.fromBuffer);
  static final _$listDevices =
      $grpc.ClientMethod<$0.ListDevicesRequest, $0.ListDevicesResponse>(
          '/quire.v1.AuthService/ListDevices',
          ($0.ListDevicesRequest value) => value.writeToBuffer(),
          $0.ListDevicesResponse.fromBuffer);
  static final _$updateDevice =
      $grpc.ClientMethod<$0.UpdateDeviceRequest, $0.UpdateDeviceResponse>(
          '/quire.v1.AuthService/UpdateDevice',
          ($0.UpdateDeviceRequest value) => value.writeToBuffer(),
          $0.UpdateDeviceResponse.fromBuffer);
  static final _$revokeDevice =
      $grpc.ClientMethod<$0.RevokeDeviceRequest, $0.RevokeDeviceResponse>(
          '/quire.v1.AuthService/RevokeDevice',
          ($0.RevokeDeviceRequest value) => value.writeToBuffer(),
          $0.RevokeDeviceResponse.fromBuffer);
}

@$pb.GrpcServiceName('quire.v1.AuthService')
abstract class AuthServiceBase extends $grpc.Service {
  $core.String get $name => 'quire.v1.AuthService';

  AuthServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.RegisterUserRequest, $0.RegisterUserResponse>(
            'RegisterUser',
            registerUser_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RegisterUserRequest.fromBuffer(value),
            ($0.RegisterUserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUserRequest, $0.GetUserResponse>(
        'GetUser',
        getUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetUserRequest.fromBuffer(value),
        ($0.GetUserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateUserRequest, $0.UpdateUserResponse>(
        'UpdateUser',
        updateUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdateUserRequest.fromBuffer(value),
        ($0.UpdateUserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangePasswordRequest,
            $0.ChangePasswordResponse>(
        'ChangePassword',
        changePassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangePasswordRequest.fromBuffer(value),
        ($0.ChangePasswordResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ChangeEmailRequest, $0.ChangeEmailResponse>(
            'ChangeEmail',
            changeEmail_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ChangeEmailRequest.fromBuffer(value),
            ($0.ChangeEmailResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteUserRequest, $0.DeleteUserResponse>(
        'DeleteUser',
        deleteUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteUserRequest.fromBuffer(value),
        ($0.DeleteUserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.LoginResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogoutRequest, $0.LogoutResponse>(
        'Logout',
        logout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LogoutRequest.fromBuffer(value),
        ($0.LogoutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RefreshSessionRequest,
            $0.RefreshSessionResponse>(
        'RefreshSession',
        refreshSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RefreshSessionRequest.fromBuffer(value),
        ($0.RefreshSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RequestPasswordRecoveryRequest,
            $0.RequestPasswordRecoveryResponse>(
        'RequestPasswordRecovery',
        requestPasswordRecovery_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RequestPasswordRecoveryRequest.fromBuffer(value),
        ($0.RequestPasswordRecoveryResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ResetPasswordRequest, $0.ResetPasswordResponse>(
            'ResetPassword',
            resetPassword_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ResetPasswordRequest.fromBuffer(value),
            ($0.ResetPasswordResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RegisterDeviceRequest,
            $0.RegisterDeviceResponse>(
        'RegisterDevice',
        registerDevice_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RegisterDeviceRequest.fromBuffer(value),
        ($0.RegisterDeviceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListDevicesRequest, $0.ListDevicesResponse>(
            'ListDevices',
            listDevices_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListDevicesRequest.fromBuffer(value),
            ($0.ListDevicesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateDeviceRequest, $0.UpdateDeviceResponse>(
            'UpdateDevice',
            updateDevice_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateDeviceRequest.fromBuffer(value),
            ($0.UpdateDeviceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RevokeDeviceRequest, $0.RevokeDeviceResponse>(
            'RevokeDevice',
            revokeDevice_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RevokeDeviceRequest.fromBuffer(value),
            ($0.RevokeDeviceResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.RegisterUserResponse> registerUser_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RegisterUserRequest> $request) async {
    return registerUser($call, await $request);
  }

  $async.Future<$0.RegisterUserResponse> registerUser(
      $grpc.ServiceCall call, $0.RegisterUserRequest request);

  $async.Future<$0.GetUserResponse> getUser_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetUserRequest> $request) async {
    return getUser($call, await $request);
  }

  $async.Future<$0.GetUserResponse> getUser(
      $grpc.ServiceCall call, $0.GetUserRequest request);

  $async.Future<$0.UpdateUserResponse> updateUser_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateUserRequest> $request) async {
    return updateUser($call, await $request);
  }

  $async.Future<$0.UpdateUserResponse> updateUser(
      $grpc.ServiceCall call, $0.UpdateUserRequest request);

  $async.Future<$0.ChangePasswordResponse> changePassword_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangePasswordRequest> $request) async {
    return changePassword($call, await $request);
  }

  $async.Future<$0.ChangePasswordResponse> changePassword(
      $grpc.ServiceCall call, $0.ChangePasswordRequest request);

  $async.Future<$0.ChangeEmailResponse> changeEmail_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChangeEmailRequest> $request) async {
    return changeEmail($call, await $request);
  }

  $async.Future<$0.ChangeEmailResponse> changeEmail(
      $grpc.ServiceCall call, $0.ChangeEmailRequest request);

  $async.Future<$0.DeleteUserResponse> deleteUser_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteUserRequest> $request) async {
    return deleteUser($call, await $request);
  }

  $async.Future<$0.DeleteUserResponse> deleteUser(
      $grpc.ServiceCall call, $0.DeleteUserRequest request);

  $async.Future<$0.LoginResponse> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$0.LoginResponse> login(
      $grpc.ServiceCall call, $0.LoginRequest request);

  $async.Future<$0.LogoutResponse> logout_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LogoutRequest> $request) async {
    return logout($call, await $request);
  }

  $async.Future<$0.LogoutResponse> logout(
      $grpc.ServiceCall call, $0.LogoutRequest request);

  $async.Future<$0.RefreshSessionResponse> refreshSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshSessionRequest> $request) async {
    return refreshSession($call, await $request);
  }

  $async.Future<$0.RefreshSessionResponse> refreshSession(
      $grpc.ServiceCall call, $0.RefreshSessionRequest request);

  $async.Future<$0.RequestPasswordRecoveryResponse> requestPasswordRecovery_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RequestPasswordRecoveryRequest> $request) async {
    return requestPasswordRecovery($call, await $request);
  }

  $async.Future<$0.RequestPasswordRecoveryResponse> requestPasswordRecovery(
      $grpc.ServiceCall call, $0.RequestPasswordRecoveryRequest request);

  $async.Future<$0.ResetPasswordResponse> resetPassword_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResetPasswordRequest> $request) async {
    return resetPassword($call, await $request);
  }

  $async.Future<$0.ResetPasswordResponse> resetPassword(
      $grpc.ServiceCall call, $0.ResetPasswordRequest request);

  $async.Future<$0.RegisterDeviceResponse> registerDevice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RegisterDeviceRequest> $request) async {
    return registerDevice($call, await $request);
  }

  $async.Future<$0.RegisterDeviceResponse> registerDevice(
      $grpc.ServiceCall call, $0.RegisterDeviceRequest request);

  $async.Future<$0.ListDevicesResponse> listDevices_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListDevicesRequest> $request) async {
    return listDevices($call, await $request);
  }

  $async.Future<$0.ListDevicesResponse> listDevices(
      $grpc.ServiceCall call, $0.ListDevicesRequest request);

  $async.Future<$0.UpdateDeviceResponse> updateDevice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateDeviceRequest> $request) async {
    return updateDevice($call, await $request);
  }

  $async.Future<$0.UpdateDeviceResponse> updateDevice(
      $grpc.ServiceCall call, $0.UpdateDeviceRequest request);

  $async.Future<$0.RevokeDeviceResponse> revokeDevice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RevokeDeviceRequest> $request) async {
    return revokeDevice($call, await $request);
  }

  $async.Future<$0.RevokeDeviceResponse> revokeDevice(
      $grpc.ServiceCall call, $0.RevokeDeviceRequest request);
}

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:atril/data/services/api/errors.dart';
import 'package:atril/data/services/api/generated/google/rpc/error_details.pb.dart';
import 'package:atril/data/services/api/generated/google/rpc/status.pb.dart'
    as rpc;
import 'package:atril/data/services/api/generated/quire/v1/auth.pbgrpc.dart'
    as pb;
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide ClientChannel;
import 'package:grpc/service_api.dart' show ClientChannel;
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';

/// A node that refuses one registration the way the node refuses one.
///
/// It answers through `grpc-status-details-bin`, which is where
/// `internal/shared/grpcx` puts the reason and the field violations, and it is
/// the trailer the caller has to read them out of.
final class _RefusingAuthService extends pb.AuthServiceBase {
  @override
  Future<pb.RegisterUserResponse> registerUser(
    ServiceCall call,
    pb.RegisterUserRequest request,
  ) async {
    final status = rpc.Status(
      code: StatusCode.alreadyExists,
      message: 'that address is already registered here',
      details: <Any>[
        Any.pack(
          ErrorInfo(reason: 'email_already_registered', domain: 'quire.v1'),
        ),
        Any.pack(
          BadRequest(
            fieldViolations: <BadRequest_FieldViolation>[
              BadRequest_FieldViolation(
                field_1: 'email',
                description: 'is already registered',
              ),
            ],
          ),
        ),
      ],
    );

    throw GrpcError.custom(
      StatusCode.alreadyExists,
      'that address is already registered here',
      null,
      null,
      <String, String>{
        'grpc-status-details-bin': base64Url.encode(status.writeToBuffer()),
      },
    );
  }

  Never _unimplemented() => throw GrpcError.unimplemented('not in this fake');

  @override
  Future<pb.GetUserResponse> getUser(
    ServiceCall call,
    pb.GetUserRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.UpdateUserResponse> updateUser(
    ServiceCall call,
    pb.UpdateUserRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.ChangePasswordResponse> changePassword(
    ServiceCall call,
    pb.ChangePasswordRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.ChangeEmailResponse> changeEmail(
    ServiceCall call,
    pb.ChangeEmailRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.DeleteUserResponse> deleteUser(
    ServiceCall call,
    pb.DeleteUserRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.LoginResponse> login(
    ServiceCall call,
    pb.LoginRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.LogoutResponse> logout(
    ServiceCall call,
    pb.LogoutRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.RefreshSessionResponse> refreshSession(
    ServiceCall call,
    pb.RefreshSessionRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.RequestPasswordRecoveryResponse> requestPasswordRecovery(
    ServiceCall call,
    pb.RequestPasswordRecoveryRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.ResetPasswordResponse> resetPassword(
    ServiceCall call,
    pb.ResetPasswordRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.RegisterDeviceResponse> registerDevice(
    ServiceCall call,
    pb.RegisterDeviceRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.ListDevicesResponse> listDevices(
    ServiceCall call,
    pb.ListDevicesRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.UpdateDeviceResponse> updateDevice(
    ServiceCall call,
    pb.UpdateDeviceRequest request,
  ) async => _unimplemented();
  @override
  Future<pb.RevokeDeviceResponse> revokeDevice(
    ServiceCall call,
    pb.RevokeDeviceRequest request,
  ) async => _unimplemented();
}

void main() {
  group('kindOfStatus', () {
    test('reads the table the node writes forwards', () {
      expect(
        kindOfStatus(StatusCode.invalidArgument),
        ErrorKind.invalidArgument,
      );
      expect(
        kindOfStatus(StatusCode.unauthenticated),
        ErrorKind.unauthenticated,
      );
      expect(
        kindOfStatus(StatusCode.permissionDenied),
        ErrorKind.permissionDenied,
      );
      expect(kindOfStatus(StatusCode.notFound), ErrorKind.notFound);
      expect(kindOfStatus(StatusCode.alreadyExists), ErrorKind.alreadyExists);
      expect(
        kindOfStatus(StatusCode.failedPrecondition),
        ErrorKind.failedPrecondition,
      );
      expect(
        kindOfStatus(StatusCode.resourceExhausted),
        ErrorKind.resourceExhausted,
      );
      expect(kindOfStatus(StatusCode.unavailable), ErrorKind.unavailable);
      expect(kindOfStatus(StatusCode.internal), ErrorKind.internal);
      expect(kindOfStatus(StatusCode.unimplemented), ErrorKind.unimplemented);
      expect(kindOfStatus(StatusCode.cancelled), ErrorKind.canceled);
      expect(
        kindOfStatus(StatusCode.deadlineExceeded),
        ErrorKind.deadlineExceeded,
      );
      expect(kindOfStatus(StatusCode.unknown), ErrorKind.unknown);
    });

    test(
      'reads a lost concurrent write as a conflict and not a precondition',
      () {
        // The node answers ABORTED for its conflict kind, and the difference
        // matters to a device draining an offline queue: a conflict is retried
        // after reconciling, and a failed precondition is not retried at all.
        expect(kindOfStatus(StatusCode.aborted), ErrorKind.conflict);
        expect(kindOfStatus(StatusCode.aborted).isRetryable, isTrue);
      },
    );
  });

  group('failureFrom', () {
    test('carries the code and the message of a status', () {
      final failure = failureFrom(
        const GrpcError.notFound('no such e-book'),
        op: 'library/ebooks: get',
      );

      expect(failure.kind, ErrorKind.notFound);
      expect(failure.message, 'no such e-book');
      expect(failure.op, 'library/ebooks: get');
      expect(failure.cause, isA<GrpcError>());
    });

    test('reads the stable reason out of the details', () {
      final failure = failureFrom(
        GrpcError.custom(StatusCode.alreadyExists, 'taken', <ErrorInfo>[
          ErrorInfo(reason: 'email_already_registered', domain: 'quire.v1'),
        ]),
      );

      expect(failure.code, 'email_already_registered');
    });

    test('ignores a reason scoped to somebody else', () {
      // A detail attached by a gateway means what that gateway meant by it,
      // and branching on it would be this app acting on a vocabulary it does
      // not speak.
      final failure = failureFrom(
        GrpcError.custom(StatusCode.permissionDenied, 'refused', <ErrorInfo>[
          ErrorInfo(reason: 'RBAC_DENIED', domain: 'istio.io'),
        ]),
      );

      expect(failure.code, isEmpty);
    });

    test('keeps the fields a validation failure named', () {
      final failure = failureFrom(
        GrpcError.custom(StatusCode.invalidArgument, 'refused', <BadRequest>[
          BadRequest(
            fieldViolations: <BadRequest_FieldViolation>[
              BadRequest_FieldViolation(
                field_1: 'local_name',
                description: 'is taken',
              ),
              BadRequest_FieldViolation(
                field_1: 'password',
                description: 'is too short',
              ),
            ],
          ),
        ]),
      );

      expect(failure.fields, <FieldFailure>[
        const FieldFailure('local_name', 'is taken'),
        const FieldFailure('password', 'is too short'),
      ]);
    });

    test('passes an already classified failure through', () {
      const raised = AppException(
        kind: ErrorKind.notFound,
        message: 'this device does not hold the bytes',
        code: 'blob_missing',
      );

      final failure = failureFrom(raised, op: 'library/ebooks: open');

      expect(failure.kind, ErrorKind.notFound);
      expect(failure.code, 'blob_missing');
      expect(failure.op, 'library/ebooks: open');
    });

    test('does not reclassify a failure that already names its operation', () {
      const raised = AppException(
        kind: ErrorKind.internal,
        op: 'data/storage: blob',
      );

      expect(
        failureFrom(raised, op: 'library/ebooks: open').op,
        'data/storage: blob',
      );
    });

    test('leaves anything it does not recognize unclassified', () {
      final failure = failureFrom(
        const FormatException('not json'),
        op: 'data/sync: pull',
      );

      expect(failure.kind, ErrorKind.unknown);
      expect(failure.op, 'data/sync: pull');
      expect(failure.cause, isA<FormatException>());
    });
  });

  group('over a socket', () {
    test('the reason and the fields survive the wire', () async {
      final server = Server.create(services: <Service>[_RefusingAuthService()]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

      final ClientChannel channel = openChannel(
        NodeEndpoint(
          authority: '127.0.0.1:${server.port}',
          transportSecurity: false,
        ),
      );
      final client = pb.AuthServiceClient(channel);

      AppException? failure;

      try {
        await client.registerUser(pb.RegisterUserRequest(email: 'a@b.example'));
      } on Object catch (error) {
        failure = failureFrom(error, op: 'identity/user: register');
      }

      await channel.shutdown();
      await server.shutdown();

      expect(failure, isNotNull);
      expect(failure!.kind, ErrorKind.alreadyExists);
      expect(failure.code, 'email_already_registered');
      expect(failure.message, 'that address is already registered here');
      expect(failure.fields, <FieldFailure>[
        const FieldFailure('email', 'is already registered'),
      ]);
    });
  });
}

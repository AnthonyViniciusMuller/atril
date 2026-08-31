/// The one place a gRPC status becomes an [AppException].
///
/// The node speaks the vocabulary in [`utils/errors.dart`](../../../utils/errors.dart)
/// and answers in gRPC, and `internal/shared/grpcx` is where it makes the
/// translation. This file is the same table read backwards, so that a failure
/// arrives here as what the node meant rather than as a number: an
/// `ALREADY_EXISTS` is [ErrorKind.alreadyExists] and an `ABORTED` is
/// [ErrorKind.conflict], because that is what the node sent it for.
///
/// Two things travel besides the code, and they are the reason this file is
/// more than a `switch`.
///
/// **The stable reason.** The node attaches a `google.rpc.ErrorInfo` whose
/// `reason` is the machine-readable code — `email_already_registered` and the
/// like — scoped to the `quire.v1` domain. It survives a wording change on
/// either side, which is what a view model branches on and what an ARB key is
/// chosen by.
///
/// **The field violations.** A rejected registration carries a
/// `google.rpc.BadRequest` naming the inputs that failed, and dropping it at
/// the edge is dropping the only thing that turns a refusal into something a
/// form can point at.
///
/// `package:grpc` parses both into types it keeps under `src/` and does not
/// export, so this project generates its own from the canonical
/// `google/rpc/error_details.proto` — the Makefile says why — and recognizes a
/// detail by its qualified message name before re-reading it as one. That name
/// is present unless a build defines `protobuf.omit_message_names`, which this
/// project does not and which would cost it the details.
library;

import 'package:protobuf/protobuf.dart' show GeneratedMessage;

import '../../../utils/errors.dart';
import 'generated/google/rpc/error_details.pb.dart';
import 'grpc_status.dart';

/// The authority the machine-readable reason of a failure is scoped to.
///
/// It names the contract rather than the node, because the same reason means
/// the same thing on every node in the federation. A detail scoped to anything
/// else was attached by something between here and the node — a gateway, a
/// proxy — and its reason is not one this app can branch on.
const String errorDomain = 'quire.v1';

/// The qualified names of the two details the node attaches.
const String errorInfoName = 'google.rpc.ErrorInfo';

/// The qualified name of the validation detail.
const String badRequestName = 'google.rpc.BadRequest';

/// The kind of failure a gRPC status code reports.
///
/// It is `grpcx.Code` inverted, and the two are kept equal deliberately: a
/// kind that mapped to one code on the node and back to another here would be
/// a failure the two sides disagree about the meaning of.
ErrorKind kindOfStatus(int code) => switch (code) {
  StatusCode.cancelled => ErrorKind.canceled,
  StatusCode.invalidArgument => ErrorKind.invalidArgument,
  StatusCode.deadlineExceeded => ErrorKind.deadlineExceeded,
  StatusCode.notFound => ErrorKind.notFound,
  StatusCode.alreadyExists => ErrorKind.alreadyExists,
  StatusCode.permissionDenied => ErrorKind.permissionDenied,
  StatusCode.resourceExhausted => ErrorKind.resourceExhausted,
  StatusCode.failedPrecondition => ErrorKind.failedPrecondition,
  // Aborted and not FailedPrecondition, for the reason the node gives where it
  // chooses the code: a concurrent write lost and the caller should reconcile
  // and try again, which is exactly what a device draining an offline queue
  // must not be told to give up on.
  StatusCode.aborted => ErrorKind.conflict,
  // The node never sends it. It means an argument that is wrong for the state
  // the system is in rather than wrong in itself, so it is the precondition
  // and not the argument that a caller has to change.
  StatusCode.outOfRange => ErrorKind.failedPrecondition,
  StatusCode.unimplemented => ErrorKind.unimplemented,
  StatusCode.internal => ErrorKind.internal,
  StatusCode.unavailable => ErrorKind.unavailable,
  // Data lost or corrupted in transit is not something a caller can act on,
  // and it is the node's fault or the network's rather than the request's.
  StatusCode.dataLoss => ErrorKind.internal,
  StatusCode.unauthenticated => ErrorKind.unauthenticated,
  _ => ErrorKind.unknown,
};

/// [error] as the vocabulary every layer of this app speaks.
///
/// [op] is the operation being attempted, in the form `library/ebooks:
/// import`, and it is recorded on the failure so that a log line names the
/// call path without the cost of a stack trace.
///
/// An [AppException] passes through, gaining [op] if it did not already name
/// one: a failure raised below this layer has already been classified, and
/// reclassifying it would be this file guessing at something it was told.
AppException failureFrom(Object error, {String op = ''}) {
  if (error is AppException) {
    return error.op.isEmpty && op.isNotEmpty ? error.withOp(op) : error;
  }

  if (error is GrpcError) {
    return _fromStatus(error, op);
  }

  // Everything else is what this app raised on its way to the wire, or what
  // the platform did: a timeout is recognized by the vocabulary itself, and
  // the rest is unclassified on purpose. Guessing here would be the decision
  // about how much of an unknown failure to reveal, taken by the wrong code.
  return AppException(
    kind: AppException.kindOf(error),
    message: '$error',
    op: op,
    cause: error,
  );
}

AppException _fromStatus(GrpcError error, String op) {
  final details = error.details;

  return AppException(
    kind: kindOfStatus(error.code),
    message: error.message ?? '',
    code: _reasonIn(details),
    op: op,
    fields: _violationsIn(details),
    cause: error,
  );
}

/// The stable reason the node attached, or the empty string.
String _reasonIn(List<GeneratedMessage>? details) {
  for (final detail in details ?? const <GeneratedMessage>[]) {
    if (detail.info_.qualifiedMessageName != errorInfoName) {
      continue;
    }

    final info = ErrorInfo.fromBuffer(detail.writeToBuffer());

    if (info.domain == errorDomain) {
      return info.reason;
    }
  }

  return '';
}

/// The inputs the node refused, in the order it listed them.
List<FieldFailure> _violationsIn(List<GeneratedMessage>? details) {
  for (final detail in details ?? const <GeneratedMessage>[]) {
    if (detail.info_.qualifiedMessageName != badRequestName) {
      continue;
    }

    final refused = BadRequest.fromBuffer(detail.writeToBuffer());

    return <FieldFailure>[
      for (final violation in refused.fieldViolations)
        FieldFailure(violation.field_1, violation.description),
    ];
  }

  return const <FieldFailure>[];
}

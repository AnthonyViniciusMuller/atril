/// The single error vocabulary of the app.
///
/// It is the Dart half of
/// [`internal/shared/errs`](../../../quire/internal/shared/errs), and it is
/// deliberately the same vocabulary rather than a similar one: the node already
/// answers `ALREADY_EXISTS` for a duplicate identifier and carries the fields
/// that failed validation, and a client that flattened that into a string at
/// the edge would be throwing away the only thing that turns a rejected
/// registration into something a form can point at. Phase 4 maps `GrpcError`
/// onto these values in `data/services/api`, in one place.
///
/// Every layer speaks it. A repository returns `Result<T>` whose failure is an
/// [AppException]; a view model reads the [ErrorKind] to decide whether to
/// offer a retry, and the [AppException.code] to decide what to say.
///
/// Nothing here is a user-visible string. [AppException.message] is
/// diagnostic — it is what the node said, or what this layer knows, and it
/// names hosts and identifiers freely because it is written to the log. What a
/// reader sees is chosen by the UI from the kind and the code, out of the ARB
/// files, which is what keeps this file free of any language.
library;

import 'dart:async';

/// What a caller can do about a failure.
///
/// The values are those of `errs.Kind` on the node, in the same order, because
/// the mapping between them and a gRPC status is the identity: a kind that
/// existed on only one side would be a status one of the two could not name.
enum ErrorKind {
  /// No kind was assigned. It is the classification of an error this app did
  /// not raise and could not recognize.
  unknown('unknown'),

  /// The request itself is malformed. Sending it again unchanged fails again.
  invalidArgument('invalid argument'),

  /// No valid credential was presented.
  unauthenticated('unauthenticated'),

  /// The credential is valid and insufficient.
  permissionDenied('permission denied'),

  /// The addressed entity does not exist, or is hidden from this caller.
  notFound('not found'),

  /// Creating the entity would violate uniqueness.
  alreadyExists('already exists'),

  /// A concurrent write won. The caller should reconcile and retry.
  conflict('conflict'),

  /// The system is in a state where the operation cannot run, and retrying
  /// will not help until that changes.
  failedPrecondition('failed precondition'),

  /// A quota or a rate limit was reached.
  resourceExhausted('resource exhausted'),

  /// A dependency — the node, the gateway, the network — is temporarily
  /// unreachable. Retrying with backoff may work.
  unavailable('unavailable'),

  /// The node, or this app, is at fault.
  internal('internal'),

  /// The method exists and is not implemented here.
  unimplemented('unimplemented'),

  /// The caller gave up before the operation finished.
  canceled('canceled'),

  /// The operation ran past its deadline.
  deadlineExceeded('deadline exceeded');

  const ErrorKind(this.label);

  /// The name of the kind, for a log line and for a failing test.
  final String label;

  /// Whether repeating the same request later could succeed without the
  /// caller changing anything.
  ///
  /// The sync loop is what asks: it decides between backing off and giving up,
  /// and a device on a train asks it constantly. The list is the node's own,
  /// so that a failure the node considers transient is not retried forever on
  /// one side and abandoned on the other.
  bool get isRetryable => switch (this) {
    ErrorKind.unavailable ||
    ErrorKind.resourceExhausted ||
    ErrorKind.deadlineExceeded ||
    ErrorKind.conflict => true,
    ErrorKind.unknown ||
    ErrorKind.invalidArgument ||
    ErrorKind.unauthenticated ||
    ErrorKind.permissionDenied ||
    ErrorKind.notFound ||
    ErrorKind.alreadyExists ||
    ErrorKind.failedPrecondition ||
    ErrorKind.internal ||
    ErrorKind.unimplemented ||
    ErrorKind.canceled => false,
  };

  @override
  String toString() => label;
}

/// One input that failed validation, so that a form points at the control that
/// is wrong instead of at the request as a whole.
final class FieldFailure {
  const FieldFailure(this.name, this.reason);

  /// The field path as the client knows it, such as `email` or
  /// `annotation.range.start`.
  final String name;

  /// Why it was refused, as the node put it. Like [AppException.message] this
  /// is diagnostic text; a form shows what the ARB files say about [name].
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is FieldFailure && other.name == name && other.reason == reason;

  @override
  int get hashCode => Object.hash(name, reason);

  @override
  String toString() => '$name: $reason';
}

/// The exception every layer boundary in this app carries.
///
/// It is the failure case of [Result], and the one type `data`, `domain` and
/// `ui` all agree on. A layer that invented its own would force the layer above
/// it to translate, and a translation is where a code and a field list go
/// missing.
///
/// Instances are immutable. [withOp], [withCode] and [withField] return a new
/// exception rather than annotating this one, because a failure travelling
/// outwards is read by whoever caught it and must not change under them.
final class AppException implements Exception {
  const AppException({
    required this.kind,
    this.message = '',
    this.code = '',
    this.op = '',
    this.fields = const <FieldFailure>[],
    this.cause,
  });

  /// What the caller can do about it.
  final ErrorKind kind;

  /// The explanation, for the log. Not a string a reader sees.
  final String message;

  /// A stable machine-readable identifier, such as `email_already_registered`.
  ///
  /// It is what a view model branches on and what an ARB key is chosen by:
  /// unlike [message] it survives a wording change, on either side of the
  /// wire.
  final String code;

  /// The operation that failed, such as `library/ebooks: import`. It gives a
  /// log reader the call path without the cost of a stack trace.
  final String op;

  /// The individual validation violations, if any.
  final List<FieldFailure> fields;

  /// What this failure was raised from — a `GrpcError`, a socket exception, a
  /// drift failure. It belongs in the log and never in a screen.
  final Object? cause;

  /// Whether retrying is worth it, per [ErrorKind.isRetryable].
  bool get isRetryable => kind.isRetryable;

  /// This exception with [op] recorded.
  AppException withOp(String op) => _copyWith(op: op);

  /// This exception with [code] recorded.
  AppException withCode(String code) => _copyWith(code: code);

  /// This exception with one more validation violation.
  AppException withField(String name, String reason) =>
      _copyWith(fields: <FieldFailure>[...fields, FieldFailure(name, reason)]);

  /// This exception with [failures] appended to its validation violations.
  AppException withFields(Iterable<FieldFailure> failures) =>
      _copyWith(fields: <FieldFailure>[...fields, ...failures]);

  AppException _copyWith({
    String? code,
    String? op,
    List<FieldFailure>? fields,
  }) => AppException(
    kind: kind,
    message: message,
    code: code ?? this.code,
    op: op ?? this.op,
    fields: fields ?? this.fields,
    cause: cause,
  );

  /// Classifies anything that was caught.
  ///
  /// An [AppException] answers with its own kind. A [TimeoutException] is
  /// recognized unwrapped, because a deadline is reached in places that never
  /// went through this vocabulary. Anything else is [ErrorKind.unknown]: the
  /// layer that catches it decides how much of an unclassified failure to
  /// reveal, and guessing here would be that decision taken by the wrong code.
  static ErrorKind kindOf(Object? error) => switch (error) {
    AppException(:final kind) => kind,
    TimeoutException() => ErrorKind.deadlineExceeded,
    _ => ErrorKind.unknown,
  };

  @override
  String toString() {
    final parts = <String>[
      if (op.isNotEmpty) op,
      kind.label,
      if (code.isNotEmpty) code,
      if (message.isNotEmpty) message,
      if (fields.isNotEmpty) fields.join(', '),
      if (cause != null) '$cause',
    ];

    return parts.join(': ');
  }

  /// Equality ignores [cause], which is whatever was caught below and has no
  /// equality of its own. Two failures with the same kind, code, message,
  /// operation and fields are the same failure to everything that reads one.
  @override
  bool operator ==(Object other) =>
      other is AppException &&
      other.kind == kind &&
      other.message == message &&
      other.code == code &&
      other.op == op &&
      _sameFields(other.fields);

  @override
  int get hashCode =>
      Object.hash(kind, message, code, op, Object.hashAll(fields));

  bool _sameFields(List<FieldFailure> other) {
    if (other.length != fields.length) {
      return false;
    }

    for (var index = 0; index < fields.length; index++) {
      if (other[index] != fields[index]) {
        return false;
      }
    }

    return true;
  }
}

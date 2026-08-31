/// The type every call that can fail hands back across a layer boundary.
///
/// The [Flutter architecture guide](https://docs.flutter.dev/app-architecture/design-patterns/result)
/// states the rule this file exists to make possible: an exception is thrown by
/// the code that discovers a failure and caught by the code that can act on it,
/// and between the two it travels as a value. A repository that throws leaves
/// its caller no signature to read — the failure is invisible until it happens
/// at runtime, on a device, offline, in front of a reader.
///
/// So a fallible call returns `Result<T>` and never throws across the boundary.
/// The exception is caught where it is raised, wrapped, and returned; the
/// caller pattern-matches over the two cases the sealed hierarchy allows the
/// analyzer to prove are the only ones:
///
/// ```dart
/// switch (await repository.loadEbook(id)) {
///   case Ok(:final value):
///     _ebook = value;
///   case Error(:final error):
///     _log.warning('loading the e-book', error);
/// }
/// ```
///
/// [Error] shadows `dart:core`'s own within a file that imports this one. That
/// is the guide's naming and it is kept, because the two are never wanted in
/// the same scope: `dart:core`'s `Error` is a programming mistake that should
/// crash, and this one is a failure the app is expected to handle.
library;

/// The outcome of an operation that can fail: either [Ok] or [Error], and
/// nothing else.
///
/// The type is sealed, so a `switch` over it without a default is exhaustive
/// and the analyzer reports the day a third case appears. That is the whole
/// benefit over a nullable return: a caller cannot forget the failure.
sealed class Result<T> {
  const Result();

  /// The success case, carrying the value produced.
  const factory Result.ok(T value) = Ok<T>._;

  /// The failure case, carrying the exception that explains it.
  ///
  /// The argument is an [Exception] and not an [Object] on purpose: what
  /// crosses a boundary here is a failure the caller is expected to handle,
  /// and `dart:core`'s [Error] hierarchy is a bug in this program rather than
  /// a condition to report. A failed assertion should reach a crash reporter,
  /// not a `SnackBar`.
  const factory Result.error(Exception error) = Error<T>._;
}

/// The result of an operation that succeeded.
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// The value produced.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// The result of an operation that failed.
final class Error<T> extends Result<T> {
  const Error._(this.error);

  /// The exception that explains the failure.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

/// The operations a caller performs on a result without unwrapping it by hand.
///
/// They are extensions rather than methods on the sealed class so that the
/// hierarchy stays two constructors and two fields — the part a `switch` reads
/// — and the conveniences stay separable from it.
extension ResultExtensions<T> on Result<T> {
  /// Whether the operation succeeded.
  bool get isOk => this is Ok<T>;

  /// Whether the operation failed.
  bool get isError => this is Error<T>;

  /// The value, or `null` when the operation failed.
  ///
  /// It is `T?` and not `T`, so a `T` that is itself nullable makes the two
  /// cases indistinguishable. Use it where the distinction does not matter and
  /// [fold] where it does.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Error<T>() => null,
  };

  /// The exception, or `null` when the operation succeeded.
  Exception? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Error<T>(:final error) => error,
  };

  /// The value, or [fallback] when the operation failed.
  T valueOr(T fallback) => switch (this) {
    Ok<T>(:final value) => value,
    Error<T>() => fallback,
  };

  /// Collapses both cases into one value, which is what a widget builder and a
  /// view model's getter both need.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Exception error) onError,
  }) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Error<T>(:final error) => onError(error),
  };

  /// Applies [transform] to the value of a success, and passes a failure
  /// through untouched.
  ///
  /// This is the mapper's shape: a client returns `Result<quire.v1.Ebook>` and
  /// the layer above it returns `Result<Ebook>` without ever having to decide
  /// what to do about the failure it is not equipped to handle.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Result<R>.ok(transform(value)),
    Error<T>(:final error) => Result<R>.error(error),
  };

  /// [map] for a [transform] that can itself fail, so that two fallible calls
  /// compose into one result rather than into a result of a result.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => transform(value),
    Error<T>(:final error) => Result<R>.error(error),
  };

  /// Applies [transform] to the exception of a failure, and passes a success
  /// through untouched.
  ///
  /// It is how a layer adds what it knows to a failure raised below it without
  /// discarding the failure itself.
  Result<T> mapError(Exception Function(Exception error) transform) =>
      switch (this) {
        Ok<T>() => this,
        Error<T>(:final error) => Result<T>.error(transform(error)),
      };
}

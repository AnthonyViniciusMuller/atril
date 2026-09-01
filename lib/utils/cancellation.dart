/// Something the reader changed their mind about.
///
/// Dart has no cancellation token of its own, and the two things this app has
/// to cancel — a download of a large book, and phase 9's rendering of one —
/// are both long enough that a reader will. What they need is small: a flag
/// something checks between chunks, and a future something else can race.
///
/// It is deliberately *not* a `StreamSubscription`. Cancelling a subscription
/// stops the delivery and says nothing about what should happen to what has
/// already arrived, and a download that is abandoned has to discard a staged
/// object as well as stop reading.
library;

import 'dart:async';

import 'errors.dart';

/// A signal that says the caller has stopped wanting the answer.
final class Cancellation {
  /// A signal nobody has raised yet.
  Cancellation();

  final Completer<void> _cancelled = Completer<void>();

  /// Whether the caller has given up.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when the caller gives up, and never otherwise.
  ///
  /// It is what a long wait races against — a call that has already been made
  /// and cannot be checked between steps.
  Future<void> get whenCancelled => _cancelled.future;

  /// Gives up. Calling it twice does nothing the first call did not.
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }

  /// Throws if the caller has given up.
  ///
  /// It is what a loop calls between steps, and the failure it raises is the
  /// reader's decision rather than a fault: nothing above should apologize for
  /// it or retry it.
  void throwIfCancelled({required String op}) {
    if (isCancelled) {
      throw AppException(
        kind: ErrorKind.canceled,
        message: 'the caller gave up',
        code: codeCancelled,
        op: op,
      );
    }
  }
}

/// The stable code of something the caller abandoned.
const String codeCancelled = 'cancelled';

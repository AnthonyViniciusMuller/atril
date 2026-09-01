/// Where this device stands with its node, as a reader is entitled to see it.
///
/// It is one value and not four streams because the four only mean anything
/// together. *Three changes pending* is reassuring while a channel is open and
/// is the whole of the problem while nothing has connected for a day, and a
/// screen that had to assemble that sentence out of separate subscriptions
/// would be a screen that showed a coherent state only most of the time.
///
/// The claim this exists to make good on is the one in the roadmap: a reader
/// who cannot tell whether their notes are only on this phone has not been
/// given the guarantee the app makes. So the two facts that answer that
/// question are durable and come from the database — what is owed, and when
/// this device last reached its node — and the two that describe right now come
/// from the loop.
library;

import '../../utils/errors.dart';

/// What the synchronization loop is doing.
enum SyncActivity {
  /// Not trying, and not waiting to: signed out, in the background, or
  /// stopped.
  idle('idle'),

  /// Opening a channel.
  connecting('connecting'),

  /// A channel is open, and anything authored here goes out at once.
  live('live'),

  /// A channel ended and the next attempt is waiting out its backoff.
  waiting('waiting');

  const SyncActivity(this.label);

  /// The name of the state, for a log line and a failing test.
  final String label;

  @override
  String toString() => label;
}

/// What this device owes, what it has heard, and what it is doing about it.
final class SyncState {
  /// The state.
  const SyncState({
    this.activity = SyncActivity.idle,
    this.pending = 0,
    this.lastSyncedAt,
    this.failure,
    this.retryIn,
  });

  /// What the loop is doing.
  final SyncActivity activity;

  /// How many changes this device has authored and not handed over.
  ///
  /// It is read from the outbox and not from the loop, so it is true across a
  /// restart and true while nothing is running.
  final int pending;

  /// When this device last reached its node, or `null` if it never has.
  final DateTime? lastSyncedAt;

  /// What went wrong last, or `null` where nothing has.
  ///
  /// It survives into [SyncActivity.live] so that a screen can say *it is
  /// working now, and this is what was wrong before*.
  final AppException? failure;

  /// How long until the next attempt, while [activity] is
  /// [SyncActivity.waiting].
  final Duration? retryIn;

  /// Whether everything this device authored has reached a node.
  bool get isHandedOver => pending == 0;

  @override
  String toString() =>
      'SyncState($activity, $pending pending, last $lastSyncedAt)';
}

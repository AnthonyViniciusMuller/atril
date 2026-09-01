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
import 'operation.dart';

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

/// A change a node refused, and what it said.
///
/// It is the state the local-first write path makes possible and nothing else
/// in this app produces: the reader has seen the change land, it is in the
/// replica, and the node will not take it — so this device is holding something
/// that will reach nobody. A correct client should rarely author one, which is
/// why this is a flag and a list rather than a merge interface.
final class RefusedChange {
  /// The change [refusedAt], because [reason].
  const RefusedChange({
    required this.change,
    required this.reason,
    required this.refusedAt,
  });

  /// The operation the node refused, which is still in this device's outbox and
  /// is no longer offered.
  final Operation change;

  /// What the node said. It is written for an operator rather than for a
  /// reader, and it is shown anyway: a screen that knows why and does not say
  /// is worse than one that says something only half its readers can act on.
  final String reason;

  /// When this device was told.
  final DateTime refusedAt;

  @override
  String toString() => 'RefusedChange(${change.id}: $reason)';
}

/// What this device owes, what it has heard, and what it is doing about it.
final class SyncState {
  /// The state.
  const SyncState({
    this.activity = SyncActivity.idle,
    this.pending = 0,
    this.refusals = const <RefusedChange>[],
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

  /// The changes a node refused outright.
  ///
  /// They are held apart from [pending] because they are not waiting for
  /// anything: no connection makes them go, and a surface that folded them into
  /// one number would be telling a reader to be patient about a change that
  /// will never leave.
  final List<RefusedChange> refusals;

  /// How many of those there are.
  int get refused => refusals.length;

  /// How many changes this device holds that no node does.
  ///
  /// It is the honest answer to *are my notes only on this phone*, and it is
  /// what the navigation surface's badge counts: both halves are still only
  /// here, and only the screen behind it has room to say why they differ.
  int get notHandedOver => pending + refused;

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
  bool get isHandedOver => notHandedOver == 0;

  @override
  String toString() =>
      'SyncState($activity, $pending pending, $refused refused, '
      'last $lastSyncedAt)';
}

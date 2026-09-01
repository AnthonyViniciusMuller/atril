/// [SyncRepository] over the outbox, the cursor and the loop.
library;

import 'dart:async';

import '../../../domain/models/sync_state.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/errors.dart';
import '../../services/local/dao/identity_dao.dart';
import '../../services/local/dao/sync_dao.dart';
import '../../services/local/database.dart';
import '../../services/sync/scheduler.dart';
import 'sync_repository.dart';

final _log = loggerFor('data/sync');

/// The operation a reader-asked synchronization reports under.
const String opSyncNow = 'sync: now';

/// The state of synchronization, joined out of its three sources.
final class SyncRepositoryImpl implements SyncRepository {
  /// The repository over [sync] and [identity], watching [scheduler].
  SyncRepositoryImpl({
    required this.sync,
    required this.identity,
    required this.scheduler,
  });

  /// The outbox and the cursors.
  final SyncDao sync;

  /// The catalogue, which is what says which node this device's cursor is
  /// against.
  final IdentityDao identity;

  /// The loop, for what it is doing now and for the one thing a reader can ask
  /// of it.
  final SyncScheduler scheduler;

  @override
  Stream<SyncState> watchState() =>
      Stream<SyncState>.multi((MultiStreamController<SyncState> listener) {
        // The three sources are merged by hand rather than with a combinator,
        // because two of them are database streams that emit at once and the
        // third replays its current value to every listener — so the first
        // frame is complete without anything having to wait for the other two.
        var status = scheduler.status;
        var pending = 0;
        DateTime? lastSyncedAt;

        void emit() => listener.add(
          SyncState(
            activity: status.activity,
            pending: pending,
            lastSyncedAt: lastSyncedAt,
            failure: status.failure,
            retryIn: status.retryIn,
          ),
        );

        final subscriptions = <StreamSubscription<Object?>>[
          scheduler.statuses.listen((SyncStatus next) {
            status = next;
            emit();
          }),
          sync.watchPendingCount().listen((int owed) {
            pending = owed;
            emit();
          }),
          _lastSynced().listen((DateTime? at) {
            lastSyncedAt = at;
            emit();
          }),
        ];

        listener.onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      });

  @override
  Future<Result<void>> syncNow() async {
    try {
      await scheduler.syncNow();

      return const Result<void>.ok(null);
    } on Exception catch (error, trace) {
      final failure = failureFrom(error, op: opSyncNow);

      _log.warning('synchronizing now failed', error, trace);

      return Result<void>.error(failure);
    }
  }

  /// When this device last reached the node it is signed in at.
  ///
  /// The cursor is keyed by the node, so this follows the origin rather than
  /// holding a domain read once: a reader who migrates to another node in
  /// phase 12 changes which row this is, and a screen showing the old one
  /// would be showing a fact about a node they left.
  Stream<DateTime?> _lastSynced() => identity
      .watchServers()
      .map(_originOf)
      .distinct()
      .asyncExpand(
        (String? domain) => domain == null
            ? Stream<DateTime?>.value(null)
            : sync.watchLastExchangeWith(domain),
      );

  String? _originOf(List<ServerRow> servers) {
    for (final server in servers) {
      if (server.isOrigin) {
        return server.domain;
      }
    }

    return null;
  }
}

/// The kind of failure a reader is shown for [failure], where they are shown
/// one at all.
///
/// It is here rather than in the screen because the screen's job is a sentence
/// and this is a classification: a node that is not answering is a *wait*, and
/// anything else is a *this needs looking at*.
bool isWaitingOn(AppException failure) => failure.kind.isRetryable;

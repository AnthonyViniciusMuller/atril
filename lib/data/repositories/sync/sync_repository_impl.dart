/// [SyncRepository] over the outbox, the cursor and the loop.
library;

import 'dart:async';

import '../../../domain/models/operation.dart';
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

/// The operation discarding a refused change reports under.
const String opDiscard = 'sync: discard';

/// The stable code of a refused change this device no longer holds.
const String codeNoSuchRefusal = 'refusal_not_found';

/// The state of synchronization, joined out of its four sources.
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
        // The four sources are merged by hand rather than with a combinator,
        // because three of them are database streams that emit at once and the
        // fourth replays its current value to every listener — so the first
        // frame is complete without anything having to wait for the rest.
        var status = scheduler.status;
        var pending = 0;
        var refusals = const <RefusedChange>[];
        DateTime? lastSyncedAt;

        void emit() => listener.add(
          SyncState(
            activity: status.activity,
            pending: pending,
            refusals: refusals,
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
          sync.watchRefused().listen((
            List<(Operation, RefusedOperationRow)> refused,
          ) {
            refusals = <RefusedChange>[
              for (final (Operation change, RefusedOperationRow row) in refused)
                RefusedChange(
                  change: change,
                  reason: row.reason,
                  refusedAt: row.refusedAt,
                ),
            ];
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
  Future<Result<void>> discard(String operationId) async {
    try {
      if (await sync.discard(operationId) == 0) {
        return Result<void>.error(
          const AppException(
            kind: ErrorKind.notFound,
            message: 'this device does not hold that refused change',
            code: codeNoSuchRefusal,
            op: opDiscard,
          ),
        );
      }

      _log.info('a refused change was discarded: $operationId');

      return const Result<void>.ok(null);
    } on Exception catch (error, trace) {
      _log.warning('discarding a refused change failed', error, trace);

      return Result<void>.error(failureFrom(error, op: opDiscard));
    }
  }

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

/// A [SyncRepository] that answers with whatever a test put in it.
library;

import 'dart:async';

import 'package:atril/data/repositories/sync/sync_repository.dart';
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/utils/result.dart';

/// A [SyncRepository] that answers with whatever a test put in it.
///
/// The state is a broadcast controller for the reason the works are: what the
/// badge and the sync screen are written against is a *stream*, and a
/// repository that answered once would be a repository this app does not have.
/// The current value is replayed to each listener, as the real one's is —
/// the shell's badge subscribes long after the loop started.
final class FakeSyncRepository implements SyncRepository {
  final StreamController<SyncState> _states =
      StreamController<SyncState>.broadcast();

  SyncState _state = const SyncState();

  /// How many times a reader asked for a synchronization.
  int asked = 0;

  /// The refused changes a reader asked this device to forget.
  final List<String> discarded = <String>[];

  /// What [discard] answers with.
  Result<void> discards = const Result<void>.ok(null);

  /// What [syncNow] answers with.
  Result<void> answers = const Result<void>.ok(null);

  /// Announces [state].
  void emit(SyncState state) {
    _state = state;
    _states.add(state);
  }

  @override
  Stream<SyncState> watchState() =>
      Stream<SyncState>.multi((MultiStreamController<SyncState> listener) {
        listener.add(_state);

        final subscription = _states.stream.listen(
          listener.add,
          onDone: listener.close,
        );

        listener.onCancel = subscription.cancel;
      });

  @override
  Future<Result<void>> discard(String operationId) async {
    discarded.add(operationId);

    return discards;
  }

  @override
  Future<Result<void>> syncNow() async {
    asked++;

    return answers;
  }

  /// Closes the stream, as a test tearing down its tree would want.
  Future<void> dispose() => _states.close();
}

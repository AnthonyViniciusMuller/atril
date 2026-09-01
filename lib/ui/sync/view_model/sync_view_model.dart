/// What the sync surface knows.
///
/// It is one view model used in two places: the screen behind the settings, and
/// the badge on the navigation surface that leads to it. They want different
/// parts of the same state — the badge only ever reads [state]'s count — and
/// giving them one class rather than two is what keeps the two from ever
/// disagreeing about what *pending* means.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/sync/sync_repository.dart';
import '../../../domain/models/sync_state.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the sync surface.
final class SyncViewModel extends ChangeNotifier {
  /// The view model over [sync].
  SyncViewModel({required this.sync}) {
    now = Command0<void>(sync.syncNow);
    _states = sync.watchState().listen(_onState);
  }

  /// Where the state comes from.
  final SyncRepository sync;

  /// Synchronizes at the reader's asking, clearing whatever wait was running.
  late final Command0<void> now;

  /// Forgets the refused change [operationId], and answers for it.
  ///
  /// It is a method and not a `Command` deliberately, which is the one place
  /// this app departs from *view models expose commands*: a command carries the
  /// state of *one* running action, and there is one of these per refused
  /// change in a list. A single command would report the last one's outcome
  /// against every row.
  Future<Result<void>> discard(String operationId) =>
      sync.discard(operationId);

  late final StreamSubscription<SyncState> _states;

  SyncState _state = const SyncState();

  /// Where this device stands with its node.
  SyncState get state => _state;

  void _onState(SyncState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_states.cancel());
    now.dispose();
    super.dispose();
  }
}

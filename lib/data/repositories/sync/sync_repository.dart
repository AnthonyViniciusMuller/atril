/// Where this device stands with its node, as every screen above this line
/// sees it.
///
/// It is a repository and not a view model reading the scheduler directly, for
/// the reason every other feature here has one: a screen that reached into
/// `data/services` would be a screen that knows which of two live channels this
/// build uses, and the whole point of the port below it is that nothing above
/// does.
///
/// What it answers is one question asked four ways. *Are my notes only on this
/// phone?* — which is what is owed, when this device last reached its node,
/// what the loop is doing about it, and what went wrong last. They are joined
/// into one [SyncState] because separately they mislead: three changes pending
/// is reassuring while a channel is open and is the whole of the problem while
/// nothing has connected since Tuesday.
library;

import '../../../domain/models/sync_state.dart';
import '../../../utils/result.dart';

/// The state of synchronization, and the one thing a reader can do about it.
abstract interface class SyncRepository {
  /// Where this device stands, now and whenever it changes.
  ///
  /// It never fails. Everything in it is either a row in this device's own
  /// database or a state the loop is already holding, so there is nothing here
  /// for a `Result` to carry — which is why this is the one stream in the app
  /// that is not one.
  Stream<SyncState> watchState();

  /// Synchronizes now, because the reader asked.
  ///
  /// It clears a backoff that is already running, which is the difference
  /// between this and what the loop does on its own: a reader tapping it is
  /// telling the device something it could not have known.
  Future<Result<void>> syncNow();
}

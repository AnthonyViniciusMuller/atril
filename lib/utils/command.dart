/// The action a view model exposes, instead of a method.
///
/// The [Flutter architecture guide](https://docs.flutter.dev/app-architecture/design-patterns/command)
/// argues it from the state a button needs and a method cannot carry. Tapping
/// *import* has to disable the control while the import runs, show what went
/// wrong if it failed, and navigate away once it succeeded — and a
/// `Future<void> import()` says nothing about any of the three. Every view
/// model that tried would grow the same three fields, spelled differently, and
/// a widget would read `isLoading` in one screen and `busy` in the next.
///
/// A [Command] is those fields, once. It runs the action, holds the [Result],
/// and notifies its listeners at both ends of the call, so a widget listens to
/// the command rather than to a hand-written flag.
///
/// It also fixes the bug the guide names: a command already running ignores a
/// second execution, so a reader who taps twice imports one book.
///
/// This is the one file of the shared core that imports Flutter.
/// [ChangeNotifier] is where the framework keeps its listener bookkeeping, and
/// a second implementation of it in this project would be a type `provider`,
/// `ListenableBuilder` and every widget that rebuilds could not observe.
library;

import 'package:flutter/foundation.dart';

import 'result.dart';

/// An action that takes nothing.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// An action that takes one argument.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// What a [Command0] and a [Command1] share: the running flag, the result of
/// the last run, and the notification around both.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;

  /// Whether the action is running. A control bound to a command that is
  /// running is disabled, and that is the whole of what a widget has to know.
  bool get running => _running;

  /// The result of the last run, or `null` before the first one and while one
  /// is in flight.
  Result<T>? get result => _result;

  /// Whether the last run failed.
  ///
  /// It is a `bool` and not the exception, which the guide spells this way and
  /// which reads oddly beside [Result]'s own [Error] case. The exception is one
  /// step away, in [result], and a widget that only has to choose between two
  /// subtrees should not have to unwrap anything to do it.
  bool get error => _result is Error<T>;

  /// Whether the last run succeeded.
  bool get completed => _result is Ok<T>;

  /// Forgets the last result.
  ///
  /// A view is expected to call it once it has acted on the outcome — shown
  /// the failure, or navigated away from the success. Without it a rebuild
  /// triggered by anything else replays a `SnackBar` the reader already
  /// dismissed.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Runs [action] unless this command is already running.
  ///
  /// The result is cleared before the run, so that a view rebuilding mid-flight
  /// cannot read the outcome of the previous one as if it were this one's.
  ///
  /// The action is expected to return its failure rather than throw it, which
  /// is the rule [Result] exists to state. One that throws anyway leaves the
  /// command not running, with no result, and the exception continues out of
  /// `execute` — deliberately: it is a broken layer boundary, and swallowing
  /// it here would turn a bug in the app into a button that does nothing.
  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) {
      return;
    }

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] over an action that takes no argument.
final class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Runs the action.
  Future<void> execute() => _execute(_action);
}

/// A [Command] over an action that takes one argument, supplied at the moment
/// the action is run rather than when the command is built.
final class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Runs the action with [argument].
  Future<void> execute(A argument) => _execute(() => _action(argument));
}

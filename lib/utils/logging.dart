/// The one place this app writes anything.
///
/// It is the counterpart of
/// [`internal/shared/logging`](../../../quire/internal/shared/logging), reduced
/// to what a device needs. Two conventions carry it:
///
/// **One logger per component, named.** [loggerFor] returns a logger under the
/// `atril` hierarchy, so a record says where it came from and a level can be
/// raised for one component without raising it everywhere.
///
/// **Errors are passed, never interpolated.** An [AppException] renders its
/// kind, operation, code, message and cause on its own; a record built as
/// `'import failed: $error'` throws that structure away and cannot be filtered
/// on afterwards.
///
/// ```dart
/// final _log = loggerFor('data/sync');
///
/// _log.warning('the pull was refused', failure);
/// ```
///
/// Nothing else in the app writes: `avoid_print` is an error in
/// `analysis_options.yaml`, because a `print` is invisible on five of the six
/// targets and is the console on the sixth.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// The name every logger in this app hangs under.
const String logHierarchy = 'atril';

/// The level a build defaults to, read at compile time from
/// `--dart-define=ATRIL_LOG_LEVEL=...`.
///
/// It is one of the two compile-time constants this app reads — the other is
/// the development certificate authority, in `main_development.dart` — and it
/// is read here so that nothing below `main` has to. `config/environment.dart`
/// resolves it against the flavour's own default and passes the answer to
/// [installLogging]; this is what a caller that passed nothing falls back to,
/// which is every test.
const String configuredLogLevel = String.fromEnvironment('ATRIL_LOG_LEVEL');

/// The levels a build may ask for by name, lowercase, as the node spells them.
///
/// `logging` ships more than these — `SHOUT`, `CONFIG`, `FINER` — and they are
/// deliberately not offered: the vocabulary a log query is written against is
/// worth keeping small, and it is the one `log/slog` uses on the other side.
const Map<String, Level> logLevels = <String, Level>{
  'debug': Level.FINE,
  'info': Level.INFO,
  'warn': Level.WARNING,
  'error': Level.SEVERE,
  'off': Level.OFF,
};

/// What a log record is handed to. [installLogging] takes one for tests, and
/// the default is [_emit].
typedef LogSink = void Function(LogRecord record);

/// The logger for [component], such as `data/sync` or `ui/library`.
///
/// The name is the path of the thing that logs rather than a Dart library name,
/// because what a reader of the log is looking for is the layer.
Logger loggerFor(String component) => Logger('$logHierarchy.$component');

/// The level named by [name], or [fallback] when it names nothing.
///
/// An unrecognized name is not an error: it arrives from a build flag or a
/// stored setting, and refusing to start over a misspelt level would be a
/// device that will not open because of how loudly it was asked to log.
Level logLevelFrom(String? name, {Level fallback = Level.INFO}) =>
    logLevels[name?.trim().toLowerCase() ?? ''] ?? fallback;

/// Installs the single listener every record in this app goes through.
///
/// It is called once, from the entry point, before anything else runs.
/// Calling it again replaces the listener rather than adding a second one,
/// which is what keeps a test from seeing every record twice.
///
/// [level] defaults to what `ATRIL_LOG_LEVEL` asked for, and to [Level.INFO]
/// when the build asked for nothing.
void installLogging({Level? level, LogSink? sink}) {
  Logger.root.level = level ?? logLevelFrom(configuredLogLevel);

  _subscription?.cancel();
  _subscription = Logger.root.onRecord.listen(sink ?? _emit);
}

/// Removes the listener and returns the root logger to its default level, so
/// that one test's logging cannot reach the next one's sink.
void resetLogging() {
  _subscription?.cancel();
  _subscription = null;
  Logger.root.level = Level.INFO;
}

/// The listener installed by [installLogging], held so that it can be replaced
/// rather than joined by a second one.
StreamSubscription<LogRecord>? _subscription;

/// Writes a record where the platform shows it.
///
/// `dart:developer` is the sink that exists on all six targets: it is the
/// DevTools and IDE log on the five native ones and the browser console on the
/// sixth. `print` is not, which is why it is an analyzer error.
///
/// The error and the stack trace are handed over rather than folded into the
/// message, so a domain failure keeps the structure it renders with.
void _emit(LogRecord record) {
  developer.log(
    record.message,
    time: record.time,
    level: record.level.value,
    name: record.loggerName,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

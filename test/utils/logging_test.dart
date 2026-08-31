import 'package:atril/utils/errors.dart';
import 'package:atril/utils/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  tearDown(resetLogging);

  group('loggerFor', () {
    test('hangs the component under the app hierarchy', () {
      // `name` is the leaf and `fullName` is the path, which is what a record
      // carries and what a log query is written against.
      expect(loggerFor('data/sync').fullName, 'atril.data/sync');
      expect(loggerFor('data/sync').parent?.fullName, logHierarchy);
    });

    test('returns the same logger for the same component', () {
      expect(loggerFor('data/sync'), same(loggerFor('data/sync')));
    });
  });

  group('logLevelFrom', () {
    test('reads the names a build may ask for', () {
      expect(logLevelFrom('debug'), Level.FINE);
      expect(logLevelFrom('info'), Level.INFO);
      expect(logLevelFrom('warn'), Level.WARNING);
      expect(logLevelFrom('error'), Level.SEVERE);
      expect(logLevelFrom('off'), Level.OFF);
    });

    test('ignores case and surrounding space', () {
      expect(logLevelFrom('  WARN '), Level.WARNING);
    });

    test('falls back rather than refusing a name it does not know', () {
      // A misspelt level arrives from a build flag, and a device that would not
      // open because of how loudly it was asked to log is worse than a device
      // that logs at the default.
      expect(logLevelFrom('verbose'), Level.INFO);
      expect(logLevelFrom(''), Level.INFO);
      expect(logLevelFrom(null), Level.INFO);
      expect(logLevelFrom('verbose', fallback: Level.SEVERE), Level.SEVERE);
    });
  });

  group('installLogging', () {
    test('sends every record to the sink', () {
      final records = <LogRecord>[];
      installLogging(level: Level.ALL, sink: records.add);

      loggerFor('data/sync').info('the pull finished');

      expect(records, hasLength(1));
      expect(records.single.message, 'the pull finished');
      expect(records.single.loggerName, 'atril.data/sync');
    });

    test('drops what the level does not ask for', () {
      final records = <LogRecord>[];
      installLogging(level: Level.WARNING, sink: records.add);

      loggerFor('data/sync')
        ..info('the pull finished')
        ..warning('the pull was refused');

      expect(records.map((record) => record.message), <String>[
        'the pull was refused',
      ]);
    });

    test('keeps a domain failure whole rather than as text', () {
      // The convention the file exists to state: an AppException is passed, so
      // that its kind, code and fields survive into the record.
      final records = <LogRecord>[];
      installLogging(level: Level.ALL, sink: records.add);

      const failure = AppException(
        kind: ErrorKind.unavailable,
        code: 'node_unreachable',
      );
      loggerFor('data/sync').warning('the pull was refused', failure);

      expect(records.single.error, same(failure));
      expect(records.single.message, 'the pull was refused');
    });

    test('carries a stack trace when one is given', () {
      final records = <LogRecord>[];
      installLogging(level: Level.ALL, sink: records.add);

      final trace = StackTrace.current;
      loggerFor('data/sync').severe('the write failed', Exception('x'), trace);

      expect(records.single.stackTrace, same(trace));
    });

    test('replaces the listener instead of adding a second one', () {
      final first = <LogRecord>[];
      final second = <LogRecord>[];

      installLogging(level: Level.ALL, sink: first.add);
      installLogging(level: Level.ALL, sink: second.add);

      loggerFor('data/sync').info('once');

      expect(first, isEmpty);
      expect(second, hasLength(1));
    });

    test('defaults to info when the build asked for nothing', () {
      final records = <LogRecord>[];
      installLogging(sink: records.add);

      expect(Logger.root.level, Level.INFO);

      loggerFor('data/sync')
        ..fine('too quiet to keep')
        ..info('kept');

      expect(records.map((record) => record.message), <String>['kept']);
    });
  });

  group('resetLogging', () {
    test('stops the sink from hearing anything more', () {
      final records = <LogRecord>[];
      installLogging(level: Level.ALL, sink: records.add);

      resetLogging();
      loggerFor('data/sync').severe('after the reset');

      expect(records, isEmpty);
      expect(Logger.root.level, Level.INFO);
    });
  });
}

import 'dart:async';

import 'package:atril/utils/command.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Command0', () {
    test('starts idle, with no result', () {
      final command = Command0<int>(() async => const Result<int>.ok(1));

      expect(command.running, isFalse);
      expect(command.result, isNull);
      expect(command.error, isFalse);
      expect(command.completed, isFalse);
    });

    test('runs the action and holds its success', () async {
      final command = Command0<int>(() async => const Result<int>.ok(7));

      await command.execute();

      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(command.running, isFalse);
      expect(command.result?.valueOrNull, 7);
    });

    test('holds a failure without throwing it', () async {
      const failure = AppException(kind: ErrorKind.unavailable);
      final command = Command0<int>(
        () async => const Result<int>.error(failure),
      );

      await command.execute();

      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect(command.result?.errorOrNull, failure);
    });

    test('is running while the action is in flight', () async {
      final gate = Completer<Result<int>>();
      final command = Command0<int>(() => gate.future);

      final run = command.execute();
      expect(command.running, isTrue);
      expect(command.result, isNull);

      gate.complete(const Result<int>.ok(1));
      await run;

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
    });

    test('notifies at both ends of the run', () async {
      final gate = Completer<Result<int>>();
      final command = Command0<int>(() => gate.future);

      var notifications = 0;
      command.addListener(() => notifications++);

      final run = command.execute();
      expect(notifications, 1);

      gate.complete(const Result<int>.ok(1));
      await run;
      expect(notifications, 2);
    });

    test('ignores a second execution while it is running', () async {
      // A reader who taps twice imports one book.
      final gate = Completer<Result<int>>();
      var runs = 0;
      final command = Command0<int>(() {
        runs++;

        return gate.future;
      });

      final first = command.execute();
      await command.execute();

      expect(runs, 1);

      gate.complete(const Result<int>.ok(1));
      await first;

      expect(runs, 1);
    });

    test('clears the previous result before running again', () async {
      final gate = Completer<Result<int>>();
      var call = 0;
      final command = Command0<int>(() {
        call++;

        return call == 1
            ? Future<Result<int>>.value(const Result<int>.ok(1))
            : gate.future;
      });

      await command.execute();
      expect(command.completed, isTrue);

      final second = command.execute();
      expect(command.result, isNull);
      expect(command.completed, isFalse);

      gate.complete(const Result<int>.ok(2));
      await second;

      expect(command.result?.valueOrNull, 2);
    });

    test('clearResult forgets the outcome and notifies', () async {
      final command = Command0<int>(() async => const Result<int>.ok(1));

      await command.execute();

      var notifications = 0;
      command.addListener(() => notifications++);

      command.clearResult();

      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(notifications, 1);
    });

    test('disposed while running does not notify', () async {
      // Leaving a screen while a command runs is the ordinary case: the book is
      // still opening, the file is still downloading. The view model disposes
      // the command, the action finishes, and a notification then would be a
      // `ChangeNotifier` asserting in debug on a listener list that is gone.
      final gate = Completer<Result<int>>();
      final command = Command0<int>(() => gate.future);

      var notifications = 0;
      command.addListener(() => notifications++);

      final run = command.execute();
      expect(notifications, 1);

      command.dispose();
      gate.complete(const Result<int>.ok(1));

      await expectLater(run, completes);
      expect(notifications, 1);
      expect(command.running, isFalse);
    });

    test('an action that throws leaves the command runnable again', () async {
      // Throwing across the boundary is a bug rather than a failure, so the
      // exception is not swallowed — but the command must not be left running,
      // or the screen is dead until it is rebuilt.
      var attempts = 0;
      final command = Command0<int>(() async {
        attempts++;

        if (attempts == 1) {
          throw StateError('a layer that throws');
        }

        return const Result<int>.ok(2);
      });

      await expectLater(command.execute(), throwsStateError);

      expect(command.running, isFalse);
      expect(command.result, isNull);

      await command.execute();

      expect(command.result?.valueOrNull, 2);
    });
  });

  group('Command1', () {
    test('passes the argument given at execution', () async {
      final command = Command1<String, int>(
        (argument) async => Result<String>.ok('got $argument'),
      );

      await command.execute(4);

      expect(command.result?.valueOrNull, 'got 4');
    });

    test('runs the action once per execution', () async {
      final arguments = <int>[];
      final command = Command1<void, int>((argument) async {
        arguments.add(argument);

        return const Result<void>.ok(null);
      });

      await command.execute(1);
      await command.execute(2);

      expect(arguments, <int>[1, 2]);
    });

    test('ignores a second execution while it is running', () async {
      final gate = Completer<Result<int>>();
      final arguments = <int>[];
      final command = Command1<int, int>((argument) {
        arguments.add(argument);

        return gate.future;
      });

      final first = command.execute(1);
      await command.execute(2);

      expect(arguments, <int>[1]);

      gate.complete(const Result<int>.ok(1));
      await first;
    });
  });
}

import 'package:atril/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// The exception the tests fail with. It is a type of its own so that a test
/// can assert the failure that came out is the one that went in.
class _Failed implements Exception {
  const _Failed(this.reason);

  final String reason;

  @override
  String toString() => 'Failed: $reason';
}

void main() {
  group('Result', () {
    test('ok carries the value', () {
      const Result<int> result = Result<int>.ok(7);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, 7);
    });

    test('error carries the exception', () {
      const failure = _Failed('offline');
      const Result<int> result = Result<int>.error(failure);

      expect(result, isA<Error<int>>());
      expect((result as Error<int>).error, same(failure));
    });

    test('a switch over the two cases is exhaustive', () {
      // The value of the sealed hierarchy is that this compiles without a
      // default clause. A third case would stop it compiling, which is the
      // point: nothing silently falls through.
      String describe(Result<int> result) => switch (result) {
        Ok<int>(:final value) => 'ok $value',
        Error<int>(:final error) => 'error $error',
      };

      expect(describe(const Result<int>.ok(1)), 'ok 1');
      expect(
        describe(const Result<int>.error(_Failed('x'))),
        'error Failed: x',
      );
    });

    test('ok holds a null value distinctly from a failure', () {
      // `valueOrNull` cannot tell the two apart, and that is why `fold` and the
      // predicates exist.
      const Result<int?> result = Result<int?>.ok(null);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, isNull);
    });
  });

  group('ResultExtensions', () {
    const failure = _Failed('offline');
    const success = Result<int>.ok(3);
    const failed = Result<int>.error(failure);

    test('isOk and isError report the case', () {
      expect(success.isOk, isTrue);
      expect(success.isError, isFalse);
      expect(failed.isOk, isFalse);
      expect(failed.isError, isTrue);
    });

    test('valueOrNull and errorOrNull answer for their own case only', () {
      expect(success.valueOrNull, 3);
      expect(success.errorOrNull, isNull);
      expect(failed.valueOrNull, isNull);
      expect(failed.errorOrNull, same(failure));
    });

    test('valueOr falls back only on a failure', () {
      expect(success.valueOr(0), 3);
      expect(failed.valueOr(0), 0);
    });

    test('fold collapses both cases', () {
      expect(
        success.fold(onOk: (value) => 'ok $value', onError: (_) => 'error'),
        'ok 3',
      );
      expect(
        failed.fold(onOk: (value) => 'ok $value', onError: (e) => 'error $e'),
        'error Failed: offline',
      );
    });

    test('map transforms a success and passes a failure through', () {
      expect(success.map((value) => value * 2).valueOrNull, 6);
      expect(failed.map((value) => value * 2).errorOrNull, same(failure));
    });

    test('map does not run its transform on a failure', () {
      var ran = false;

      failed.map((value) {
        ran = true;

        return value;
      });

      expect(ran, isFalse);
    });

    test('flatMap composes two fallible calls into one result', () {
      Result<String> parse(int value) => value > 0
          ? Result<String>.ok('$value')
          : const Result<String>.error(_Failed('not positive'));

      expect(success.flatMap(parse).valueOrNull, '3');
      expect(
        const Result<int>.ok(-1).flatMap(parse).errorOrNull,
        isA<_Failed>(),
      );
      expect(failed.flatMap(parse).errorOrNull, same(failure));
    });

    test('mapError annotates a failure and passes a success through', () {
      const annotated = _Failed('annotated');

      expect(failed.mapError((_) => annotated).errorOrNull, same(annotated));
      expect(success.mapError((_) => annotated).valueOrNull, 3);
    });

    test('mapError does not run its transform on a success', () {
      var ran = false;

      success.mapError((error) {
        ran = true;

        return error;
      });

      expect(ran, isFalse);
    });
  });
}

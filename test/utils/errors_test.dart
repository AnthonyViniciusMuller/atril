import 'dart:async';

import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorKind', () {
    test('every kind has a label', () {
      for (final kind in ErrorKind.values) {
        expect(kind.label, isNotEmpty);
        expect(kind.toString(), kind.label);
      }
    });

    test('the retryable kinds are those of the node', () {
      // The list is asserted whole rather than one membership at a time: the
      // thing that would go wrong is a kind added later and classified by
      // nobody, and only an exhaustive comparison notices that.
      expect(
        ErrorKind.values.where((kind) => kind.isRetryable),
        unorderedEquals(<ErrorKind>[
          ErrorKind.conflict,
          ErrorKind.resourceExhausted,
          ErrorKind.unavailable,
          ErrorKind.deadlineExceeded,
        ]),
      );
    });
  });

  group('FieldFailure', () {
    test('compares by name and reason', () {
      expect(
        const FieldFailure('email', 'taken'),
        const FieldFailure('email', 'taken'),
      );
      expect(
        const FieldFailure('email', 'taken'),
        isNot(const FieldFailure('email', 'malformed')),
      );
    });

    test('renders as the field and the reason', () {
      expect(const FieldFailure('email', 'taken').toString(), 'email: taken');
    });
  });

  group('AppException', () {
    test('carries the kind and defaults the rest to empty', () {
      const failure = AppException(kind: ErrorKind.notFound);

      expect(failure.kind, ErrorKind.notFound);
      expect(failure.message, isEmpty);
      expect(failure.code, isEmpty);
      expect(failure.op, isEmpty);
      expect(failure.fields, isEmpty);
      expect(failure.cause, isNull);
    });

    test('is an Exception, so it fits the failure case of a Result', () {
      expect(const AppException(kind: ErrorKind.internal), isA<Exception>());
    });

    test('reports retryability from its kind', () {
      expect(
        const AppException(kind: ErrorKind.unavailable).isRetryable,
        isTrue,
      );
      expect(
        const AppException(kind: ErrorKind.invalidArgument).isRetryable,
        isFalse,
      );
    });

    test('the annotations return a new exception and leave this one alone', () {
      const original = AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the registration was refused',
      );

      final annotated = original
          .withOp('identity/session: register')
          .withCode('email_already_registered')
          .withField('email', 'taken');

      expect(annotated.op, 'identity/session: register');
      expect(annotated.code, 'email_already_registered');
      expect(annotated.fields, <FieldFailure>[
        const FieldFailure('email', 'taken'),
      ]);
      expect(annotated.kind, original.kind);
      expect(annotated.message, original.message);

      expect(original.op, isEmpty);
      expect(original.code, isEmpty);
      expect(original.fields, isEmpty);
    });

    test('withField accumulates rather than replaces', () {
      final failure = const AppException(kind: ErrorKind.invalidArgument)
          .withField('email', 'taken')
          .withField('password', 'too short');

      expect(failure.fields, <FieldFailure>[
        const FieldFailure('email', 'taken'),
        const FieldFailure('password', 'too short'),
      ]);
    });

    test('withFields appends every failure given', () {
      final failure = const AppException(kind: ErrorKind.invalidArgument)
          .withField('email', 'taken')
          .withFields(const <FieldFailure>[
            FieldFailure('password', 'too short'),
            FieldFailure('name', 'blank'),
          ]);

      expect(failure.fields, hasLength(3));
      expect(failure.fields.last, const FieldFailure('name', 'blank'));
    });

    test('the cause survives the annotations', () {
      final cause = StateError('the channel was shut down');
      final failure = AppException(
        kind: ErrorKind.unavailable,
        cause: cause,
      ).withOp('sync: pull');

      expect(failure.cause, same(cause));
    });

    test('renders operation, kind, code, message, fields and cause', () {
      final failure = AppException(
        kind: ErrorKind.alreadyExists,
        message: 'the address is registered',
        code: 'email_already_registered',
        op: 'identity/session: register',
        fields: const <FieldFailure>[FieldFailure('email', 'taken')],
        cause: Exception('grpc: ALREADY_EXISTS'),
      );

      expect(
        failure.toString(),
        'identity/session: register: already exists: '
        'email_already_registered: the address is registered: '
        'email: taken: Exception: grpc: ALREADY_EXISTS',
      );
    });

    test('renders only what it carries', () {
      expect(
        const AppException(kind: ErrorKind.notFound).toString(),
        'not found',
      );
    });

    test('compares by everything but the cause', () {
      const one = AppException(
        kind: ErrorKind.conflict,
        message: 'the record moved on',
        code: 'stale_version',
      );
      final other = AppException(
        kind: ErrorKind.conflict,
        message: 'the record moved on',
        code: 'stale_version',
        cause: StateError('whatever was caught below'),
      );

      expect(other, one);
      expect(other.hashCode, one.hashCode);
    });

    test('compares the field failures in order', () {
      final one = const AppException(kind: ErrorKind.invalidArgument)
          .withField('email', 'taken')
          .withField('password', 'too short');
      final reversed = const AppException(kind: ErrorKind.invalidArgument)
          .withField('password', 'too short')
          .withField('email', 'taken');

      expect(reversed, isNot(one));
    });

    test('differs by kind alone', () {
      expect(
        const AppException(kind: ErrorKind.notFound),
        isNot(const AppException(kind: ErrorKind.internal)),
      );
    });
  });

  group('AppException.kindOf', () {
    test('answers with the kind of an AppException', () {
      expect(
        AppException.kindOf(const AppException(kind: ErrorKind.conflict)),
        ErrorKind.conflict,
      );
    });

    test('recognizes a deadline that never went through this vocabulary', () {
      expect(
        AppException.kindOf(TimeoutException('the call ran out of time')),
        ErrorKind.deadlineExceeded,
      );
    });

    test('classifies anything else as unknown', () {
      expect(AppException.kindOf(null), ErrorKind.unknown);
      expect(AppException.kindOf(Exception('a stray')), ErrorKind.unknown);
      expect(AppException.kindOf(StateError('a bug')), ErrorKind.unknown);
    });
  });
}

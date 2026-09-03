/// Writing a delta: what is claimed, what is cleared, and what is left alone.
library;

import 'package:atril/data/services/sync/delta.dart';
import 'package:flutter_test/flutter_test.dart';

const String _work = 'AAAAAAAA-1111-4111-8111-111111111111';

void main() {
  group('a field', () {
    test('is unnamed until something claims it', () {
      final changes = DeltaWriter();

      expect(changes.isEmpty, isTrue);
      expect(changes.claims(fieldTitle), isFalse);
      expect(changes.fields, isEmpty);
    });

    test('claimed as null is a field the reader cleared', () {
      final changes = DeltaWriter()..text(fieldAuthor, null);

      expect(changes.claims(fieldAuthor), isTrue);
      expect(changes.fields[fieldAuthor], isNull);
      expect(changes.delta.text(fieldAuthor), isNull);
    });

    test('is cleared out loud by clear', () {
      final changes = DeltaWriter()..clear(fieldPublisher);

      expect(changes.fields, <String, Object?>{fieldPublisher: null});
    });
  });

  group('a claim against what the record holds', () {
    test('is dropped where nothing changed', () {
      final changes = DeltaWriter()
        ..text(fieldTitle, 'Sagarana', current: 'Sagarana');

      expect(changes.isEmpty, isTrue);
    });

    test('is made where something did', () {
      final changes = DeltaWriter()
        ..text(fieldTitle, 'Sagarana', current: 'Grande Sertão');

      expect(changes.fields, <String, Object?>{fieldTitle: 'Sagarana'});
    });

    test('tells clearing a field apart from leaving it cleared', () {
      final cleared = DeltaWriter()
        ..text(fieldAuthor, null, current: 'Guimarães Rosa');
      final untouched = DeltaWriter()..text(fieldAuthor, null, current: null);

      expect(cleared.claims(fieldAuthor), isTrue);
      expect(cleared.fields[fieldAuthor], isNull);
      expect(untouched.isEmpty, isTrue);
    });

    test('reads an instant as an instant and not as a zone', () {
      final at = DateTime.utc(2026, 3, 14, 15, 9, 26);
      final changes = DeltaWriter()
        ..instant(fieldImportedAt, at, current: at.toLocal());

      expect(changes.isEmpty, isTrue);
    });

    test('reads an object by what it holds and not by how it was built', () {
      final changes = DeltaWriter()
        ..object(
          fieldExtraMetadata,
          <String, Object?>{
            'isbn': '9788501012876',
            'series': <String>['Sertão'],
          },
          current: <String, Object?>{
            'series': <String>['Sertão'],
            'isbn': '9788501012876',
          },
        );

      expect(changes.isEmpty, isTrue);
    });

    test('sees a list whose order changed', () {
      final changes = DeltaWriter()
        ..object(
          fieldExtraMetadata,
          <String, Object?>{
            'subjects': <String>['a', 'b'],
          },
          current: <String, Object?>{
            'subjects': <String>['b', 'a'],
          },
        );

      expect(changes.claims(fieldExtraMetadata), isTrue);
    });
  });

  group('the encoding', () {
    test('carries an instant as the RFC 3339 text a delta reads back', () {
      final at = DateTime.utc(2026, 3, 14, 15, 9, 26);
      final changes = DeltaWriter()..instant(fieldCreatedAt, at);

      expect(changes.fields[fieldCreatedAt], '2026-03-14T15:09:26.000Z');
      expect(changes.delta.instant(fieldCreatedAt), at);
    });

    test('carries an instant the node can decode', () {
      // The node reads these two fields into a Go `time.Time` through
      // `encoding/json`, which admits RFC 3339 and nothing else. A number here
      // is an operation rejected for ever, and a rejection is not retried.
      final changes = DeltaWriter()
        ..instant(fieldCreatedAt, DateTime.utc(2026, 3, 14, 15, 9, 26))
        ..instant(fieldImportedAt, DateTime(2026, 3, 14, 15, 9, 26));

      for (final field in <String>[fieldCreatedAt, fieldImportedAt]) {
        expect(changes.fields[field], isA<String>());
        expect(changes.fields[field], endsWith('Z'));
      }
    });

    test('refuses an instant that is not RFC 3339 text', () {
      const asNumber = Delta(<String, Object?>{fieldCreatedAt: 1773500966000000});
      const asNonsense = Delta(<String, Object?>{fieldCreatedAt: 'yesterday'});

      expect(
        () => asNumber.instant(fieldCreatedAt),
        throwsA(isA<DeltaException>()),
      );
      expect(
        () => asNonsense.instant(fieldCreatedAt),
        throwsA(isA<DeltaException>()),
      );
    });

    test('reads a cleared instant as cleared', () {
      const cleared = Delta(<String, Object?>{fieldCreatedAt: null});

      expect(cleared.instant(fieldCreatedAt), isNull);
    });

    test('carries a number a delta reads back', () {
      final changes = DeltaWriter()
        ..number(fieldPercent, 42.5)
        ..integer(fieldSizeBytes, 1024);

      expect(changes.delta.number(fieldPercent), 42.5);
      expect(changes.delta.integer(fieldSizeBytes), 1024);
    });

    test('carries an identifier in the case every replica compares', () {
      final changes = DeltaWriter()..id(fieldEbookId, _work);

      expect(changes.fields[fieldEbookId], _work.toLowerCase());
      expect(changes.delta.requiredId(fieldEbookId), _work.toLowerCase());
    });

    test('compares an identifier without its case', () {
      final changes = DeltaWriter()
        ..id(fieldEbookId, _work, current: _work.toLowerCase());

      expect(changes.isEmpty, isTrue);
    });

    test('refuses an identifier that names nothing', () {
      expect(
        () => DeltaWriter().id(fieldCollectionId, '  '),
        throwsA(isA<DeltaException>()),
      );
    });
  });

  test('the fields are a copy, so a logged change cannot grow', () {
    final changes = DeltaWriter()..text(fieldTitle, 'Sagarana');
    final taken = changes.fields;

    changes.text(fieldAuthor, 'Guimarães Rosa');

    expect(taken.keys, <String>[fieldTitle]);
  });
}

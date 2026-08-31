import 'package:atril/data/services/local/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A replica in memory, closed when the test that opened it ends.
///
/// Each test opens its own rather than sharing one from `setUp`, because one
/// of them opens a second database and drift warns — correctly — about two
/// instances existing at once.
AtrilDatabase open({int? userVersion}) {
  final database = AtrilDatabase(
    NativeDatabase.memory(
      setup: userVersion == null ? null : (db) => db.userVersion = userVersion,
    ),
  );

  addTearDown(database.close);

  return database;
}

void main() {
  group('AtrilDatabase', () {
    test('opens at the schema version this build expects', () async {
      final database = open();

      await database.customSelect('SELECT 1').get();

      expect(database.schemaVersion, 1);
    });

    test(
      'enforces foreign keys, which sqlite does not do by default',
      () async {
        final row = await open()
            .customSelect('PRAGMA foreign_keys')
            .getSingle();

        expect(row.data.values.single, 1);
      },
    );

    test('refuses a database some other version wrote', () async {
      final database = open(userVersion: 2);

      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

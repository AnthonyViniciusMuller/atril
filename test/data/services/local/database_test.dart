import 'package:atril/data/services/local/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A replica in memory, closed when the test that opened it ends.
///
/// Each test opens its own rather than sharing one from `setUp`, because one
/// of them opens a second database and drift warns — correctly — about two
/// instances existing at once.
AtrilDatabase open({int? userVersion, List<String> before = const <String>[]}) {
  final database = AtrilDatabase(
    NativeDatabase.memory(
      setup: userVersion == null && before.isEmpty
          ? null
          : (db) {
              // Run before drift has looked at the file, which is the only
              // place a *previous* version of this app's database can be
              // described: everything after this point is the migration under
              // test.
              for (final statement in before) {
                db.execute(statement);
              }

              if (userVersion != null) {
                db.userVersion = userVersion;
              }
            },
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

      expect(database.schemaVersion, 3);
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

    test('builds what an older version was missing', () async {
      // Every version so far only adds, so the upgrade is `createAll` — whose
      // statements are `CREATE TABLE IF NOT EXISTS`. A database left at
      // version one is one an install made while phase 3 was worked, and what
      // it lacks is the tables this device keeps for itself.
      final database = open(userVersion: 1);

      await database.customSelect('SELECT 1').get();

      expect(await database.select(database.ebookCovers).get(), isEmpty);
    });

    test('does not empty a table an older version already had', () async {
      // The rows a device already held have to survive the upgrade. A
      // migration that recreated the schema would be a reader whose library
      // disappeared when they updated the app, and it is exactly what a
      // `createAll` without `IF NOT EXISTS` would do.
      final database = open(
        userVersion: 1,
        before: <String>[
          'CREATE TABLE applied_operations ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'applied_at INTEGER NOT NULL)',
          "INSERT INTO applied_operations VALUES "
              "('aaaaaaaa-1111-4111-8111-111111111111', 0)",
        ],
      );

      expect(
        await database.syncDao.hasApplied(
          'aaaaaaaa-1111-4111-8111-111111111111',
        ),
        isTrue,
      );
    });
  });
}

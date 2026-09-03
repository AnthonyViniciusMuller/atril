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

/// The tables the schema had at version one: the identity, the library, what
/// the reader wrote and where they stopped, the log and the causal state. Every
/// version since has only added tables, so a device that was at one holds
/// exactly these — and, with them, the four indexes below.
const Set<String> _versionOneTables = <String>{
  'bound_device',
  'signed_in_reader',
  'known_servers',
  'clock_floor',
  'ebooks',
  'collections',
  'ebook_collections',
  'annotations',
  'progress',
  'pending_operations',
  'node_cursors',
  'applied_operations',
  'record_versions',
};

/// The indexes version one created, none of which said `IF NOT EXISTS`.
const Set<String> _versionOneIndexes = <String>{
  'known_servers_origin',
  'ebooks_content_hash',
  'ebook_collections_collection',
  'annotations_ebook',
};

void main() {
  group('AtrilDatabase', () {
    test('opens at the schema version this build expects', () async {
      final database = open();

      await database.customSelect('SELECT 1').get();

      expect(database.schemaVersion, 5);
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

    test('re-creates nothing a version one database already has', () async {
      // The upgrade is `createAll`, and drift writes `IF NOT EXISTS` into a
      // table's statement and not into an index's — so the test that upgraded
      // an *empty* database at version one passed while every real one failed
      // with *index already exists*. This one holds what a device that was at
      // version one actually holds: the tables of that version, and their
      // indexes. It reads that schema off a fresh replica rather than spelling
      // it out, because no column of those tables has changed since and the
      // statement drift generates is the statement the old install ran.
      final current = open();
      final rows = await current
          .customSelect(
            'SELECT type, name, sql FROM sqlite_master '
            "WHERE sql IS NOT NULL AND type IN ('table', 'index')",
          )
          .get();

      await current.close();

      final versionOne = <String>[
        for (final row in rows)
          if (row.read<String>('type') == 'table' &&
              _versionOneTables.contains(row.read<String>('name')))
            row.read<String>('sql'),
        for (final row in rows)
          if (row.read<String>('type') == 'index' &&
              _versionOneIndexes.contains(row.read<String>('name')))
            row.read<String>('sql'),
      ];

      expect(versionOne, hasLength(_versionOneTables.length + 4));

      final database = open(userVersion: 1, before: versionOne);

      // The open itself is the assertion that matters: it is where the bare
      // `CREATE INDEX` used to fail.
      await database.customSelect('SELECT 1').get();

      final indexes = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            'AND sql IS NOT NULL ORDER BY name',
          )
          .map((row) => row.read<String>('name'))
          .get();

      expect(indexes, _versionOneIndexes.toList()..sort());
      expect(await database.select(database.ebookCovers).get(), isEmpty);
      expect(await database.select(database.contentPins).get(), isEmpty);
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

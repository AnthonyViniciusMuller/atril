import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _shelf = 'bbbbbbbb-1111-4111-8111-111111111111';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26, 535, 897);

AtrilDatabase open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

EbooksCompanion _ebook({
  String id = _work,
  String title = 'Grande Sertão: Veredas',
  String format = 'epub',
  String hash = _hash,
  Value<int?> size = const Value<int?>(1),
  Value<String?> extra = const Value<String?>.absent(),
}) => EbooksCompanion.insert(
  id: id,
  title: title,
  format: format,
  contentHash: hash,
  sizeBytes: size,
  extraMetadata: extra,
  importedAt: _at,
  vectorClock: VectorClock.empty.tick(_device),
  updatedAt: _at,
  deviceId: _device,
);

CollectionsCompanion _collection({
  String id = _shelf,
  String kind = 'collection',
}) => CollectionsCompanion.insert(
  id: id,
  name: 'Para reler',
  kind: Value<String>(kind),
  createdAt: _at,
  vectorClock: VectorClock.empty.tick(_device),
  updatedAt: _at,
  deviceId: _device,
);

EbookCollectionsCompanion _filing({required String id}) =>
    EbookCollectionsCompanion.insert(
      id: id,
      ebookId: _work,
      collectionId: _shelf,
      vectorClock: VectorClock.empty.tick(_device),
      updatedAt: _at,
      deviceId: _device,
    );

void main() {
  group('a work', () {
    test('carries its causal version through the column', () async {
      final database = open();

      await database.into(database.ebooks).insert(_ebook());

      final stored = await database.select(database.ebooks).getSingle();

      expect(stored.vectorClock, VectorClock.empty.tick(_device));
      expect(stored.updatedAt, _at);
      expect(stored.deleted, isFalse);
    });

    test('is refused a format nothing can name', () async {
      final database = open();

      await expectLater(
        database.into(database.ebooks).insert(_ebook(format: 'azw3')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('is refused a digest that is not a sha-256', () async {
      final database = open();

      await expectLater(
        database
            .into(database.ebooks)
            .insert(_ebook(hash: 'zz${_hash.substring(2)}')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('holds extra metadata only as an object', () async {
      final database = open();

      await database
          .into(database.ebooks)
          .insert(
            _ebook(extra: const Value<String?>('{"isbn": "9788501012876"}')),
          );

      await expectLater(
        database
            .into(database.ebooks)
            .insert(
              _ebook(
                id: _shelf,
                extra: const Value<String?>('"9788501012876"'),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('a filing', () {
    test('is the pair, so the same pair cannot be written twice', () async {
      final database = open();

      await database.into(database.ebooks).insert(_ebook());
      await database.into(database.collections).insert(_collection());
      await database
          .into(database.ebookCollections)
          .insert(_filing(id: 'cccccccc-1111-4111-8111-111111111111'));

      await expectLater(
        database
            .into(database.ebookCollections)
            .insert(_filing(id: 'dddddddd-1111-4111-8111-111111111111')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('cannot name a work this device does not hold', () async {
      final database = open();

      await database.into(database.collections).insert(_collection());

      await expectLater(
        database
            .into(database.ebookCollections)
            .insert(_filing(id: 'cccccccc-1111-4111-8111-111111111111')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('a grouping', () {
    test('is a collection or a category and nothing else', () async {
      final database = open();

      await database
          .into(database.collections)
          .insert(_collection(kind: 'category'));

      await expectLater(
        database
            .into(database.collections)
            .insert(_collection(id: _work, kind: 'shelf')),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}

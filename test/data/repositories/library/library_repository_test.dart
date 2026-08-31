import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/library/library_repository_impl.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';

/// A digest per work, so that two works are never the same file by accident.
String _hashOf(int seed) => seed.toRadixString(16).padLeft(64, '0');

final DateTime _at = DateTime.utc(2026, 8, 31, 12);

AtrilDatabase _open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

LibraryRepository _repository(AtrilDatabase database) =>
    LibraryRepositoryImpl(library: database.libraryDao);

Future<void> _work(
  AtrilDatabase database, {
  required String id,
  required String title,
  String? author,
  int seed = 1,
  DateTime? importedAt,
  bool deleted = false,
  String? extraMetadata,
}) => database
    .into(database.ebooks)
    .insert(
      EbooksCompanion.insert(
        id: id,
        title: title,
        author: Value<String?>(author),
        format: 'epub',
        contentHash: _hashOf(seed),
        extraMetadata: Value<String?>(extraMetadata),
        importedAt: importedAt ?? _at,
        vectorClock: VectorClock.empty.tick(_device),
        updatedAt: _at,
        deviceId: _device,
        deleted: Value<bool>(deleted),
      ),
    );

Future<void> _grouping(
  AtrilDatabase database, {
  required String id,
  required String name,
  bool deleted = false,
}) => database
    .into(database.collections)
    .insert(
      CollectionsCompanion.insert(
        id: id,
        name: name,
        createdAt: _at,
        vectorClock: VectorClock.empty.tick(_device),
        updatedAt: _at,
        deviceId: _device,
        deleted: Value<bool>(deleted),
      ),
    );

Future<void> _filing(
  AtrilDatabase database, {
  required String id,
  required String ebookId,
  required String collectionId,
  bool deleted = false,
}) => database
    .into(database.ebookCollections)
    .insert(
      EbookCollectionsCompanion.insert(
        id: id,
        ebookId: ebookId,
        collectionId: collectionId,
        vectorClock: VectorClock.empty.tick(_device),
        updatedAt: _at,
        deviceId: _device,
        deleted: Value<bool>(deleted),
      ),
    );

/// The identifier of the *n*th fixture of a kind, spelled once.
String _id(String prefix, int n) =>
    '$prefix${n.toString().padLeft(4, '0')}-1111-4111-8111-111111111111';

extension on Result<List<Ebook>> {
  List<String> get titles => switch (this) {
    Ok<List<Ebook>>(:final value) => <String>[
      for (final work in value) work.title,
    ],
    Error<List<Ebook>>(:final error) => throw error,
  };
}

void main() {
  group('the collection', () {
    test('answers with what this device holds and nothing else', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Grande Sertão');

      final result = await _repository(database).watchEbooks().first;

      expect(result.titles, <String>['Grande Sertão']);
    });

    test('is empty on a device that has imported nothing', () async {
      final result = await _repository(_open()).watchEbooks().first;

      expect(result.titles, isEmpty);
    });

    test('does not list a work that has been tombstoned', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Kept');
      await _work(
        database,
        id: _id('aaaa', 2),
        title: 'Removed',
        seed: 2,
        deleted: true,
      );

      final result = await _repository(database).watchEbooks().first;

      expect(result.titles, <String>['Kept']);
    });

    test('answers again when a work is imported', () async {
      final database = _open();
      final answers = _repository(database).watchEbooks();

      expect(
        answers.map((result) => result.titles),
        emitsInOrder(<Object>[
          <String>[],
          <String>['Vidas Secas'],
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      await _work(database, id: _id('aaaa', 1), title: 'Vidas Secas');
    });
  });

  group('the order', () {
    test('is the newest arrival first by default', () async {
      final database = _open();

      await _work(
        database,
        id: _id('aaaa', 1),
        title: 'Older',
        importedAt: _at,
      );
      await _work(
        database,
        id: _id('aaaa', 2),
        title: 'Newer',
        seed: 2,
        importedAt: _at.add(const Duration(days: 1)),
      );

      final result = await _repository(database).watchEbooks().first;

      expect(result.titles, <String>['Newer', 'Older']);
    });

    test('puts an accented title where a reader would look for it', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Serviço');
      await _work(database, id: _id('aaaa', 2), title: 'Sertão', seed: 2);
      await _work(database, id: _id('aaaa', 3), title: 'Sermão', seed: 3);

      final result = await _repository(database)
          .watchEbooks(const LibraryQuery(sort: LibrarySort.title))
          .first;

      expect(result.titles, <String>['Sermão', 'Sertão', 'Serviço']);
    });

    test('sorts a work whose author the file did not say last', () async {
      final database = _open();

      await _work(
        database,
        id: _id('aaaa', 1),
        title: 'Anonymous',
        seed: 1,
      );
      await _work(
        database,
        id: _id('aaaa', 2),
        title: 'Vidas Secas',
        author: 'Graciliano Ramos',
        seed: 2,
      );

      final result = await _repository(database)
          .watchEbooks(const LibraryQuery(sort: LibrarySort.author))
          .first;

      expect(result.titles, <String>['Vidas Secas', 'Anonymous']);
    });
  });

  group('a grouping', () {
    test('narrows the collection to what is filed under it', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Filed');
      await _work(database, id: _id('aaaa', 2), title: 'Unfiled', seed: 2);
      await _grouping(database, id: _id('bbbb', 1), name: 'Para reler');
      await _filing(
        database,
        id: _id('cccc', 1),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 1),
      );

      final result = await _repository(database)
          .watchEbooks(LibraryQuery(collectionId: _id('bbbb', 1)))
          .first;

      expect(result.titles, <String>['Filed']);
    });

    test('does not show a work whose filing was tombstoned', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Unfiled again');
      await _grouping(database, id: _id('bbbb', 1), name: 'Para reler');
      await _filing(
        database,
        id: _id('cccc', 1),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 1),
        deleted: true,
      );

      final result = await _repository(database)
          .watchEbooks(LibraryQuery(collectionId: _id('bbbb', 1)))
          .first;

      expect(result.titles, isEmpty);
    });

    test('counts the works filed under each one, in one query', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'One');
      await _work(database, id: _id('aaaa', 2), title: 'Two', seed: 2);
      await _grouping(database, id: _id('bbbb', 1), name: 'Cheia');
      await _grouping(database, id: _id('bbbb', 2), name: 'Vazia');
      await _filing(
        database,
        id: _id('cccc', 1),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 1),
      );
      await _filing(
        database,
        id: _id('cccc', 2),
        ebookId: _id('aaaa', 2),
        collectionId: _id('bbbb', 1),
      );

      final counts = await _repository(database).watchFilingCounts().first;

      // A grouping nothing is filed under is absent rather than zero, which is
      // what one query over two tables can answer and what `?? 0` reads.
      expect(
        (counts as Ok<Map<String, int>>).value,
        <String, int>{_id('bbbb', 1): 2},
      );
    });

    test('lists the groupings one work is filed under, by name', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Filed twice');
      await _grouping(database, id: _id('bbbb', 1), name: 'Ótimos');
      await _grouping(database, id: _id('bbbb', 2), name: 'Ontem');
      await _filing(
        database,
        id: _id('cccc', 1),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 1),
      );
      await _filing(
        database,
        id: _id('cccc', 2),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 2),
      );

      final result = await _repository(
        database,
      ).watchCollectionsOf(_id('aaaa', 1)).first;

      expect(
        <String>[
          for (final grouping in (result as Ok<List<Collection>>).value)
            grouping.name,
        ],
        <String>['Ontem', 'Ótimos'],
      );
    });
  });

  group('one work', () {
    test('becomes null once a tombstone for it arrives', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Doomed');

      final answers = _repository(database).watchEbook(_id('aaaa', 1));

      expect(
        answers.map(
          (result) => (result as Ok<Ebook?>).value?.title,
        ),
        emitsInOrder(<Object?>['Doomed', null]),
      );

      await Future<void>.delayed(Duration.zero);
      await (database.update(database.ebooks)
            ..where((row) => row.id.equals(_id('aaaa', 1))))
          .write(const EbooksCompanion(deleted: Value<bool>(true)));
    });

    test('is read tombstone and all by the reader a write prepares', () async {
      final database = _open();

      await _work(
        database,
        id: _id('aaaa', 1),
        title: 'Deleted',
        deleted: true,
      );

      final result = await _repository(database).ebook(_id('aaaa', 1));

      expect((result as Ok<Ebook?>).value?.revision.deleted, isTrue);
    });

    test('carries the extra metadata the row holds', () async {
      final database = _open();

      await _work(
        database,
        id: _id('aaaa', 1),
        title: 'Com série',
        extraMetadata: '{"series":"Os Sertões","volume":2}',
      );

      final result = await _repository(database).ebook(_id('aaaa', 1));

      expect((result as Ok<Ebook?>).value?.extraMetadata, <String, Object?>{
        'series': 'Os Sertões',
        'volume': 2,
      });
    });
  });
}

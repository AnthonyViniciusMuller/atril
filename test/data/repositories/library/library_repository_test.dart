import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/library/library_repository_impl.dart';
import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/content/upload_queue.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'dart:io';

import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
// drift publishes an `isNull` of its own — the SQL predicate — which is not
// the matcher this file wants and is ambiguous with it.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/epub/epub_metadata_test.dart';
import '../../services/storage/memory_blob_store.dart';

const String _device = '11111111-1111-4111-8111-111111111111';

/// A digest per work, so that two works are never the same file by accident.
String _hashOf(int seed) => seed.toRadixString(16).padLeft(64, '0');

final DateTime _at = DateTime.utc(2026, 8, 31, 12);

AtrilDatabase _open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

/// The store the repository writes a book's bytes into.
late MemoryBlobStore blobs;

/// A client pointed at a node nothing is listening on.
///
/// These tests are about what an import writes to this device, and nothing in
/// them reaches a node: a transfer is a row in a queue here, and the queue is
/// never run. A client dialling nowhere is what makes that visible — a test
/// that started talking to a node would fail rather than quietly pass.
LibraryApi _api() => LibraryApi(
  connection: NodeConnection(NodeEndpoint(authority: 'nowhere.example:9090')),
  session: SessionHolder(
    store: MemorySessionStore(),
    refresher: () => throw StateError('an import dials nothing'),
  ),
);

int _minted = 0;

String _nextId() =>
    '${(++_minted).toString().padLeft(8, '0')}-1111-4111-8111-111111111111';

/// The repository over [database], with a device bound so that it can author.
///
/// Binding is not incidental: an operation carrying no author is refused by
/// the node and would be a clock entry nothing could attribute, so the author
/// refuses to write on a device that has none.
Future<LibraryRepository> _repository(
  AtrilDatabase database, {
  bool bound = true,
  bool keepsByDefault = true,
  int? quota,
}) async {
  if (bound) {
    await database.identityDao.bindDevice(
      id: _device,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );
  }

  final clock = HybridClock(wall: () => _at);

  blobs = MemoryBlobStore();

  return LibraryRepositoryImpl(
    library: database.libraryDao,
    author: OperationAuthor(
      database: database,
      clock: clock,
      reconciler: Reconciler(database, clock),
      mint: _nextId,
    ),
    blobs: blobs,
    downloads: ContentDownloader(api: _api(), blobs: blobs),
    transfers: database.transfersDao,
    keepsByDefault: keepsByDefault,
    budget: (BlobStore store) async =>
        StorageBudget(used: await store.usedBytes(), quota: quota),
    uploads: UploadQueue(
      database: database,
      // The queue is never run in these tests. What is being checked is that
      // an import leaves the node owed a file, which is a row and not a call.
      uploader: ContentUploader(api: _api(), blobs: blobs),
      now: () => _at,
    ),
    mint: _nextId,
    now: () => _at,
  );
}

/// A file the reader named, made of [bytes].
final class _File implements FileSource {
  _File(this.name, this.bytes);

  @override
  final String name;

  final List<int> bytes;

  /// How many times the bytes were asked for, which a streaming import reads
  /// exactly once.
  int reads = 0;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Stream<List<int>> openRead() async* {
    reads++;

    // In two chunks, because a platform hands a file over in whatever pieces
    // it likes and a digest computed over one buffer would pass a test a
    // streaming one fails.
    yield bytes.sublist(0, bytes.length ~/ 2);
    yield bytes.sublist(bytes.length ~/ 2);
  }
}

/// A one-pixel cover, which is a picture as far as this app cares.
final Uint8List _coverBytes = Uint8List.fromList(<int>[137, 80, 78, 71]);

/// An EPUB that describes itself in full.
final List<int> _epub = epubOf(<String, Object>{
  containerPath: containerFor('OEBPS/content.opf'),
  'OEBPS/content.opf': opfWith(
    '<dc:title>Grande Sertão: Veredas</dc:title>'
    '<dc:creator>João Guimarães Rosa</dc:creator>'
    '<dc:publisher>José Olympio</dc:publisher>'
    '<dc:language>pt-BR</dc:language>'
    '<meta name="calibre:series" content="Clássicos"/>',
    manifest:
        '<item id="capa" href="capa.png" media-type="image/png" '
        'properties="cover-image"/>',
  ),
  'OEBPS/capa.png': _coverBytes,
});

/// An EPUB that says only what a work cannot exist without.
final List<int> _bareEpub = epubOf(<String, Object>{
  containerPath: containerFor('content.opf'),
  'content.opf': opfWith('<dc:title>Anônimo</dc:title>'),
});

/// A file that fails part way through, which is a connection dropping while a
/// book is being copied off a network share.
final class _Unreadable implements FileSource {
  const _Unreadable(this.name);

  @override
  final String name;

  @override
  Future<int?> length() async => null;

  @override
  Stream<List<int>> openRead() async* {
    yield <int>[1, 2, 3];

    throw const FileSystemException('the file went away');
  }
}

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
  group('an import', () {
    test('stores the bytes under the digest of what it read', () async {
      final database = _open();
      final repository = await _repository(database);
      final file = _File('Vidas Secas.epub', <int>[1, 2, 3, 4, 5, 6, 7, 8]);

      final result = await repository.importEbook(file);

      // The digest of those eight bytes, computed independently of the code
      // that computed it here: the name an object is stored under is what
      // every replica in the federation will address it by, so a test that
      // asked the implementation what it hashed would prove nothing.
      const digest =
          '66840dda154e8a113c31dd0ad32f7f3a366a80e8136979d8f5a101d3d29d6f72';

      expect((result as Ok<Ebook>).value.contentHash, digest);
      expect(blobs.objects.keys, <String>[digest]);
      expect(blobs.objects[digest], <int>[1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('reads the file once, in whatever pieces it arrives in', () async {
      // The digest and the copy happen in one pass. A book is large enough
      // that holding it twice matters, and reading it twice would need a
      // source that can be replayed — which a browser's file input is not.
      final database = _open();
      final file = _File('Vidas Secas.epub', <int>[1, 2, 3, 4]);

      await (await _repository(database)).importEbook(file);

      expect(file.reads, 1);
    });

    test('declares the length it counted', () async {
      final database = _open();
      final file = _File('Vidas Secas.epub', List<int>.filled(1000, 7));

      final result = await (await _repository(database)).importEbook(file);

      expect((result as Ok<Ebook>).value.sizeBytes, 1000);
    });

    test('names the format from the extension, not from the bytes', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Os Sertões.PDF', <int>[1, 2, 3]),
      );

      expect((result as Ok<Ebook>).value.format, EbookFormat.pdf);
    });

    test('calls a work by its file name when nothing else has', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Grande Sertão: Veredas.epub', <int>[1]),
      );

      expect((result as Ok<Ebook>).value.title, 'Grande Sertão: Veredas');
    });

    test('refuses a name this app cannot place, before copying', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('anotações.txt', <int>[1, 2, 3]),
      );

      expect(
        ((result as Error<Ebook>).error as AppException).code,
        codeUnsupportedFormat,
      );
      // Nothing was staged, so nothing had to be discarded: the refusal
      // happens before the first byte moves.
      expect(blobs.objects, isEmpty);
      expect(blobs.aborted, 0);
    });

    test('authors the work as an operation this device owes', () async {
      // The whole of C21 in one assertion. A work created through the node's
      // CreateEbook would write the node's table and append nothing to its
      // log, so it would reach the reader's other devices — never.
      final database = _open();
      final repository = await _repository(database);

      await repository.importEbook(_File('Vidas Secas.epub', <int>[1]));

      final owed = await database.syncDao.pending();

      expect(owed, hasLength(1));
      expect(owed.single.entity, TargetEntity.ebook);
      expect(owed.single.kind, OperationKind.insert);
      expect(owed.single.delta[fieldTitle], 'Vidas Secas');
    });

    test('shows the work in the collection it was imported into', () async {
      final database = _open();
      final repository = await _repository(database);

      await repository.importEbook(_File('Vidas Secas.epub', <int>[1]));

      final result = await repository.watchEbooks().first;

      expect(result.titles, <String>['Vidas Secas']);
    });

    test('converges on one object when the same file arrives twice', () async {
      // Two works and one file. It is what a digest-addressed store is for,
      // and it is the same answer whether the second import happened here or
      // on another device of the same reader.
      final database = _open();
      final repository = await _repository(database);

      final first = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final second = await repository.importEbook(
        _File('Vidas Secas (cópia).epub', <int>[1, 2, 3]),
      );

      expect(
        (first as Ok<Ebook>).value.contentHash,
        (second as Ok<Ebook>).value.contentHash,
      );
      expect(first.value.id, isNot(second.value.id));
      expect(blobs.objects, hasLength(1));
    });

    test('leaves nothing behind when the file cannot be read', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _Unreadable('Vidas Secas.epub'),
      );

      expect(result, isA<Error<Ebook>>());
      // Staged and discarded: a store never holds a partial object under a
      // digest, because the digest is only attached once the object is whole.
      expect(blobs.objects, isEmpty);
      expect(blobs.aborted, 1);
      expect(await database.syncDao.pending(), isEmpty);
    });

    test('refuses to author on a device that has not been bound', () async {
      // An operation carrying no author is a clock entry nothing can
      // attribute. The bytes are still stored, and the next import of the same
      // file on a bound device adopts them.
      final database = _open();
      final repository = await _repository(database, bound: false);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1]),
      );

      expect(result, isA<Error<Ebook>>());
      expect(await database.syncDao.pending(), isEmpty);
    });
  });

  group('an EPUB', () {
    test('is imported under the title its package document gives', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('qualquer-nome.epub', _epub),
      );

      final work = (result as Ok<Ebook>).value;

      // The file name is the title of last resort and nothing more. A reader
      // whose books are named `9788535902778.epub` should see the book.
      expect(work.title, 'Grande Sertão: Veredas');
      expect(work.author, 'João Guimarães Rosa');
      expect(work.publisher, 'José Olympio');
      expect(work.language, 'pt-BR');
      expect(work.extraMetadata['series'], 'Clássicos');
    });

    test('claims no field the package document did not carry', () async {
      // The claim is what matters and not the row: a delta naming `author` as
      // null is a device saying the work has none, and every replica would
      // take it — including one whose file did say who wrote it.
      final database = _open();
      final repository = await _repository(database);

      await repository.importEbook(_File('livro.epub', _bareEpub));

      final delta = (await database.syncDao.pending()).single.delta;

      expect(delta.containsKey(fieldTitle), isTrue);
      expect(delta.containsKey(fieldAuthor), isFalse);
      expect(delta.containsKey(fieldPublisher), isFalse);
      expect(delta.containsKey(fieldLanguage), isFalse);
      expect(delta.containsKey(fieldExtraMetadata), isFalse);
    });

    test('keeps the cover the file carried', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('livro.epub', _epub),
      );

      final cover = await repository.cover((result as Ok<Ebook>).value.id);

      expect((cover as Ok<EpubCover?>).value?.mediaType, 'image/png');
      expect(cover.value?.bytes, _coverBytes);
    });

    test('loses its cover with the work it belonged to', () async {
      // The row references the work and is cascaded away with it, which is
      // half of why a cover is a table here rather than an object in the store
      // the reader's books live in.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('livro.epub', _epub),
      );
      final id = (result as Ok<Ebook>).value.id;

      await (database.delete(
        database.ebooks,
      )..where((row) => row.id.equals(id))).go();

      expect(((await repository.cover(id)) as Ok<EpubCover?>).value, isNull);
    });

    test('is imported anyway when its package document is unreadable', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3, 4]),
      );

      expect((result as Ok<Ebook>).value.title, 'Vidas Secas');
    });

    test('is not read at all when it is another format', () async {
      // A PDF's metadata is a different specification and a CBZ has none.
      // Handing either to a zip decoder is work with no possible answer.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(_File('livro.pdf', _epub));

      expect((result as Ok<Ebook>).value.title, 'livro');
    });
  });

  group('what this device keeps', () {
    test('is every book, on a target that keeps everything', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final id = (result as Ok<Ebook>).value.id;

      expect(
        ((await repository.watchContent(id).first) as Ok<ContentState>).value.kept,
        isTrue,
      );
    });

    test('is nothing, on a target that keeps nothing until asked', () async {
      // The browser. The origin is lent a share of a disk it may be asked to
      // give back, so a build that filled it by default would be promising
      // something it cannot keep.
      final database = _open();
      final repository = await _repository(database, keepsByDefault: false);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final id = (result as Ok<Ebook>).value.id;

      expect(
        ((await repository.watchContent(id).first) as Ok<ContentState>).value.kept,
        isFalse,
      );
    });

    test('is the reader decision where they took one', () async {
      // One mechanism with two defaults: the row records what the reader
      // decided, and its absence is what the platform answers. A table of
      // *kept* books could not express the first case and a table of
      // *released* ones could not express the second.
      final database = _open();
      final repository = await _repository(database, keepsByDefault: false);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final id = (result as Ok<Ebook>).value.id;

      await repository.keepEbook(id);

      expect(
        ((await repository.watchContent(id).first) as Ok<ContentState>).value.kept,
        isTrue,
      );
    });

    test('refuses to release the only copy there is', () async {
      // The one gesture in this app that could destroy something. A file still
      // in the queue is on this device and nowhere else.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final work = (result as Ok<Ebook>).value;

      final released = await repository.releaseEbook(work.id);

      expect(
        ((released as Error<void>).error as AppException).code,
        codeNotYetSent,
      );
      expect(await blobs.contains(work.contentHash), isTrue);
    });

    test('releases the file once the node has it', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final work = (result as Ok<Ebook>).value;

      // The transfer finished, as a pass over the queue would have left it.
      await database.transfersDao.retire(work.contentHash);

      expect(await repository.releaseEbook(work.id), isA<Ok<void>>());
      expect(await blobs.contains(work.contentHash), isFalse);
      expect(
        ((await repository.watchContent(work.id).first) as Ok<ContentState>).value.kept,
        isFalse,
      );
    });

    test('keeps the record of a work whose file it released', () async {
      // Releasing space is not deleting a book. The row stays, the shelf still
      // shows it, and asking for it again brings the file back.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final work = (result as Ok<Ebook>).value;

      await database.transfersDao.retire(work.contentHash);
      await repository.releaseEbook(work.id);

      expect((await repository.watchEbooks().first).titles, <String>[
        'Vidas Secas',
      ]);
    });

    test('lists what it is holding and not what it merely has a row for', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final work = (result as Ok<Ebook>).value;

      // A work that arrived by synchronization, whose file is on the node.
      await _work(database, id: _id('dddd', 1), title: 'Não baixado', seed: 9);

      final held = await repository.watchKeptEbooks().first;

      expect(
        <String>[for (final book in (held as Ok<List<Ebook>>).value) book.title],
        <String>['Vidas Secas'],
      );
      expect(work.title, 'Vidas Secas');
    });

    test('reports what the store holds', () async {
      final database = _open();
      final repository = await _repository(database, quota: 1000);

      await repository.importEbook(_File('livro.epub', List<int>.filled(300, 7)));

      final budget = await repository.storage();

      expect((budget as Ok<StorageBudget>).value.used, 300);
      expect(budget.value.available, 700);
    });
  });

  group('the collection', () {
    test('answers with what this device holds and nothing else', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Grande Sertão');

      final result = await (await _repository(database)).watchEbooks().first;

      expect(result.titles, <String>['Grande Sertão']);
    });

    test('is empty on a device that has imported nothing', () async {
      final result = await (await _repository(_open())).watchEbooks().first;

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

      final result = await (await _repository(database)).watchEbooks().first;

      expect(result.titles, <String>['Kept']);
    });

    test('answers again when a work is imported', () async {
      final database = _open();
      final answers = (await _repository(database)).watchEbooks();

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

      final result = await (await _repository(database)).watchEbooks().first;

      expect(result.titles, <String>['Newer', 'Older']);
    });

    test('puts an accented title where a reader would look for it', () async {
      final database = _open();

      await _work(database, id: _id('aaaa', 1), title: 'Serviço');
      await _work(database, id: _id('aaaa', 2), title: 'Sertão', seed: 2);
      await _work(database, id: _id('aaaa', 3), title: 'Sermão', seed: 3);

      final result = await (await _repository(database))
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

      final result = await (await _repository(database))
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

      final result = await (await _repository(database))
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

      final result = await (await _repository(database))
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

      final counts = await (await _repository(database)).watchFilingCounts().first;

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

      final result = await (await _repository(
        database,
      )).watchCollectionsOf(_id('aaaa', 1)).first;

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

      final answers = (await _repository(database)).watchEbook(_id('aaaa', 1));

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

      final result = await (await _repository(database)).ebook(_id('aaaa', 1));

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

      final result = await (await _repository(database)).ebook(_id('aaaa', 1));

      expect((result as Ok<Ebook?>).value?.extraMetadata, <String, Object?>{
        'series': 'Os Sertões',
        'volume': 2,
      });
    });
  });
}

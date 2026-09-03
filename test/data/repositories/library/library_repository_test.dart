import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/library/library_repository_impl.dart';
import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/content/upload_queue.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:atril/data/services/local/dao/library_dao.dart';
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

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart' show Server, Service;

import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
// drift publishes `isNull` and `isNotNull` of its own — the SQL predicates —
// which are not the matchers this file wants and are ambiguous with them.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/content/fake_content_service.dart';
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
  LibraryDao? library,
  LibraryApi? api,
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
    library: library ?? database.libraryDao,
    author: OperationAuthor(
      database: database,
      clock: clock,
      reconciler: Reconciler(database, clock),
      mint: _nextId,
    ),
    blobs: blobs,
    downloads: ContentDownloader(api: api ?? _api(), blobs: blobs),
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

/// A [LibraryDao] whose cover table refuses the first [failures] writes.
///
/// It stands in for anything that can go wrong between authoring a work and
/// finishing its bookkeeping — a full disk, a constraint, a crash — and it is
/// the cover rather than the transfer because the queue is final and the DAO is
/// not; the property under test is the same for either.
final class _FlakyLibraryDao extends LibraryDao {
  _FlakyLibraryDao(super.database);

  /// How many more writes it refuses.
  int failures = 1;

  @override
  Future<void> saveCover({
    required String ebookId,
    required String mediaType,
    required Uint8List bytes,
  }) {
    if (failures-- > 0) {
      throw StateError('the cover table is not writable right now');
    }

    return super.saveCover(
      ebookId: ebookId,
      mediaType: mediaType,
      bytes: bytes,
    );
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
  String format = 'epub',
  String? contentHash,
}) => database
    .into(database.ebooks)
    .insert(
      EbooksCompanion.insert(
        id: id,
        title: title,
        author: Value<String?>(author),
        format: format,
        contentHash: contentHash ?? _hashOf(seed),
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

    test('leaves no work behind when its bookkeeping fails', () async {
      // The record, the cover and the debt are one transaction. Before they
      // were, a failure between authoring and queueing left a work the node
      // was never owed: no upload, a second work on the retry, and a release
      // that would have removed the only copy of the file.
      final database = _open();
      final repository = await _repository(
        database,
        library: _FlakyLibraryDao(database),
      );

      final failed = await repository.importEbook(_File('livro.epub', _epub));

      expect(failed, isA<Error<Ebook>>());
      expect(await database.select(database.ebooks).get(), isEmpty);
      expect(await database.syncDao.pending(), isEmpty);
      expect(await database.transfersDao.pending(), isEmpty);
      // The bytes were stored first and stay: a file nothing names is what the
      // retry adopts, and the store is keyed by the digest.
      expect(blobs.objects, hasLength(1));

      final retried = await repository.importEbook(_File('livro.epub', _epub));

      expect(retried, isA<Ok<Ebook>>());
      expect(await database.select(database.ebooks).get(), hasLength(1));
      expect(await database.syncDao.pending(), hasLength(1));
      expect(await database.transfersDao.pending(), hasLength(1));
      expect(blobs.objects, hasLength(1));
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

      final result = await repository.importEbook(_File('livro.epub', _epub));

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

      final result = await repository.importEbook(_File('livro.epub', _epub));
      final id = (result as Ok<Ebook>).value.id;

      await (database.delete(
        database.ebooks,
      )..where((row) => row.id.equals(id))).go();

      expect(((await repository.cover(id)) as Ok<EpubCover?>).value, isNull);
    });

    test(
      'is imported anyway when its package document is unreadable',
      () async {
        final database = _open();
        final repository = await _repository(database);

        final result = await repository.importEbook(
          _File('Vidas Secas.epub', <int>[1, 2, 3, 4]),
        );

        expect((result as Ok<Ebook>).value.title, 'Vidas Secas');
      },
    );

    test('is not read at all when it is another format', () async {
      // A PDF's metadata is a different specification and a CBZ has none.
      // Handing either to a zip decoder is work with no possible answer.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.importEbook(_File('livro.pdf', _epub));

      expect((result as Ok<Ebook>).value.title, 'livro');
    });
  });

  group('an edit', () {
    /// A work in the replica, and the repository that will change it.
    Future<(LibraryRepository, AtrilDatabase, String)> imported({
      Map<String, Object?> extra = const <String, Object?>{},
    }) async {
      final database = _open();
      final repository = await _repository(database);
      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final id = (result as Ok<Ebook>).value.id;

      if (extra.isNotEmpty) {
        await (database.update(
          database.ebooks,
        )..where((row) => row.id.equals(id))).write(
          EbooksCompanion(extraMetadata: Value<String?>(json.encode(extra))),
        );
      }

      return (repository, database, id);
    }

    /// The delta of the last change this device authored.
    Future<Map<String, Object?>> lastDelta(AtrilDatabase database) async =>
        (await database.syncDao.pending()).last.delta;

    test('claims the field the reader changed', () async {
      final (repository, database, id) = await imported();

      await repository.editEbook(
        id,
        const EbookEdits(title: 'Vidas Secas', author: 'Graciliano Ramos'),
      );

      expect(await lastDelta(database), <String, Object?>{
        fieldAuthor: 'Graciliano Ramos',
      });
    });

    test('claims nothing the reader did not change', () async {
      // C17 in one assertion. Reconciliation is per record, so a delta
      // restating a title carries this device's claim to it — and the next
      // merge against a device that really did change the title is decided by
      // a tie-break rather than by what anybody meant.
      final (repository, database, id) = await imported();

      await repository.editEbook(
        id,
        const EbookEdits(title: 'Vidas Secas', author: 'Graciliano Ramos'),
      );

      final delta = await lastDelta(database);

      expect(delta.containsKey(fieldTitle), isFalse);
      expect(delta.containsKey(fieldPublisher), isFalse);
      expect(delta.containsKey(fieldLanguage), isFalse);
    });

    test('is not an operation at all when nothing changed', () async {
      // Authoring it would tick a clock and stamp an instant to tell every
      // replica that nothing happened, and leave the record reflecting this
      // device for a write it did not make.
      final (repository, database, id) = await imported();
      final before = (await database.syncDao.pending()).length;

      final result = await repository.editEbook(
        id,
        const EbookEdits(title: 'Vidas Secas'),
      );

      expect(result, isA<Ok<void>>());
      expect(await database.syncDao.pending(), hasLength(before));
    });

    test('clears a field the reader emptied, and says so', () async {
      // A form has no other way to say *there is no author*, and clearing is a
      // claim rather than a silence: a field named as null is one the change
      // cleared, and every replica takes it.
      final (repository, database, id) = await imported();

      await repository.editEbook(
        id,
        const EbookEdits(title: 'Vidas Secas', author: 'Graciliano Ramos'),
      );
      await repository.editEbook(
        id,
        const EbookEdits(title: 'Vidas Secas', author: '  '),
      );

      final delta = await lastDelta(database);

      expect(delta.containsKey(fieldAuthor), isTrue);
      expect(delta[fieldAuthor], isNull);
      expect(
        ((await repository.ebook(id)) as Ok<Ebook?>).value?.author,
        isNull,
      );
    });

    test(
      'changes what the reader sees, before any node hears about it',
      () async {
        final (repository, _, id) = await imported();

        await repository.editEbook(
          id,
          const EbookEdits(title: 'Vidas Secas', publisher: 'Record'),
        );

        final work = ((await repository.ebook(id)) as Ok<Ebook?>).value;

        expect(work?.publisher, 'Record');
      },
    );

    test('never touches the file the record describes', () async {
      // The format, the digest and the length are fixed at import. A record
      // that described a file it is not would be a book that will not open,
      // and the reconciler refuses to move them anyway.
      final (repository, database, id) = await imported();

      await repository.editEbook(id, const EbookEdits(title: 'Outro título'));

      final delta = await lastDelta(database);

      expect(delta.containsKey(fieldFormat), isFalse);
      expect(delta.containsKey(fieldContentHash), isFalse);
      expect(delta.containsKey(fieldSizeBytes), isFalse);
    });

    test('keeps the extra metadata as an object', () async {
      // The column it lands in is `jsonb` and constrained to an object, on the
      // node and on this device.
      final (repository, database, id) = await imported();

      await repository.editEbook(
        id,
        const EbookEdits(
          title: 'Vidas Secas',
          extraMetadata: <String, Object?>{'series': 'Clássicos'},
        ),
      );

      expect((await lastDelta(database))[fieldExtraMetadata], <String, Object?>{
        'series': 'Clássicos',
      });
      expect(
        ((await repository.ebook(id)) as Ok<Ebook?>).value?.extraMetadata,
        <String, Object?>{'series': 'Clássicos'},
      );
    });

    test('does not claim extra metadata that only changed key order', () async {
      // The comparison is structural. A map rebuilt by a form in a different
      // order is the same metadata, and claiming it would be this device
      // taking ownership of a field nobody edited.
      final (repository, database, id) = await imported(
        extra: const <String, Object?>{'series': 'Clássicos', 'isbn': '123'},
      );
      final before = (await database.syncDao.pending()).length;

      await repository.editEbook(
        id,
        const EbookEdits(
          title: 'Vidas Secas',
          extraMetadata: <String, Object?>{
            'isbn': '123',
            'series': 'Clássicos',
          },
        ),
      );

      expect(await database.syncDao.pending(), hasLength(before));
    });

    test('clears the extra metadata when every entry was removed', () async {
      final (repository, database, id) = await imported(
        extra: const <String, Object?>{'series': 'Clássicos'},
      );

      await repository.editEbook(id, const EbookEdits(title: 'Vidas Secas'));

      final delta = await lastDelta(database);

      expect(delta.containsKey(fieldExtraMetadata), isTrue);
      expect(delta[fieldExtraMetadata], isNull);
    });

    test('refuses a work this device does not hold', () async {
      final (repository, _, _) = await imported();

      final result = await repository.editEbook(
        'ffffffff-1111-4111-8111-111111111111',
        const EbookEdits(title: 'Nada'),
      );

      expect(
        ((result as Error<void>).error as AppException).kind,
        ErrorKind.notFound,
      );
    });
  });

  group('a deletion', () {
    Future<(LibraryRepository, AtrilDatabase, String)> imported() async {
      final database = _open();
      final repository = await _repository(database);
      final result = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );

      return (repository, database, (result as Ok<Ebook>).value.id);
    }

    test('is a tombstone and never a removal', () async {
      // A record removed outright is resurrected by the next replica that had
      // not yet heard about the removal, so the deletion has to travel as a
      // write and reconcile like one.
      final (repository, database, id) = await imported();

      await repository.deleteEbook(id);

      final row = await database.libraryDao.readEbook(id);

      expect(row, isNotNull);
      expect(row?.deleted, isTrue);
      expect(
        (await database.syncDao.pending()).last.kind,
        OperationKind.delete,
      );
    });

    test('takes the work off the shelf', () async {
      final (repository, _, id) = await imported();

      await repository.deleteEbook(id);

      expect((await repository.watchEbooks().first).titles, isEmpty);
    });

    test('is undone by one operation carrying nothing', () async {
      // The whole reason a deletion is a tombstone. The `deleted` flag travels
      // on the revision rather than in the delta, so bringing a book back is
      // an update with no fields — and not a record to rebuild from somewhere.
      final (repository, database, id) = await imported();

      await repository.deleteEbook(id);
      await repository.restoreEbook(id);

      final undo = (await database.syncDao.pending()).last;

      expect(undo.kind, OperationKind.update);
      expect(undo.delta, isEmpty);
      expect((await repository.watchEbooks().first).titles, <String>[
        'Vidas Secas',
      ]);
    });

    test('leaves the file where it is, and the transfer queued', () async {
      // A tombstoned work still counts for the node's C16 check, so a book
      // deleted while its bytes were going up finishes going up — and an undo
      // finds the file here rather than having to fetch it back.
      final (repository, database, id) = await imported();
      final work = ((await repository.ebook(id)) as Ok<Ebook?>).value!;

      await repository.deleteEbook(id);

      expect(await blobs.contains(work.contentHash), isTrue);
      expect(await database.transfersDao.pending(), hasLength(1));
    });

    test('refuses a work this device does not hold', () async {
      final (repository, _, _) = await imported();

      final result = await repository.deleteEbook(
        'ffffffff-1111-4111-8111-111111111111',
      );

      expect(
        ((result as Error<void>).error as AppException).kind,
        ErrorKind.notFound,
      );
    });
  });

  group('a grouping', () {
    test('is created as an operation this device owes', () async {
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.createCollection(
        const CollectionEdits(name: 'Para reler'),
      );

      final owed = (await database.syncDao.pending()).single;

      expect((result as Ok<Collection>).value.name, 'Para reler');
      expect(owed.entity, TargetEntity.collection);
      expect(owed.kind, OperationKind.insert);
      expect(owed.delta[fieldKind], 'collection');
    });

    test('carries the kind the reader chose', () async {
      // A collection is a grouping the reader put together and a category is a
      // subject. One structure, two meanings, and the choice is the reader's.
      final database = _open();
      final repository = await _repository(database);

      final result = await repository.createCollection(
        const CollectionEdits(name: 'Sertão', kind: CollectionKind.category),
      );

      expect((result as Ok<Collection>).value.kind, CollectionKind.category);
    });

    test('claims only what an edit changed', () async {
      final database = _open();
      final repository = await _repository(database);
      final created = await repository.createCollection(
        const CollectionEdits(name: 'Para reler', description: 'Um dia'),
      );
      final id = (created as Ok<Collection>).value.id;

      await repository.editCollection(
        id,
        const CollectionEdits(name: 'Reler', description: 'Um dia'),
      );

      final delta = (await database.syncDao.pending()).last.delta;

      expect(delta, <String, Object?>{fieldName: 'Reler'});
    });

    test('is not an operation when an edit changed nothing', () async {
      final database = _open();
      final repository = await _repository(database);
      final created = await repository.createCollection(
        const CollectionEdits(name: 'Para reler'),
      );
      final id = (created as Ok<Collection>).value.id;
      final before = (await database.syncDao.pending()).length;

      await repository.editCollection(
        id,
        const CollectionEdits(name: 'Para reler'),
      );

      expect(await database.syncDao.pending(), hasLength(before));
    });

    test('is tombstoned rather than removed, and comes back', () async {
      final database = _open();
      final repository = await _repository(database);
      final created = await repository.createCollection(
        const CollectionEdits(name: 'Para reler'),
      );
      final id = (created as Ok<Collection>).value.id;

      await repository.deleteCollection(id);

      expect(
        await repository.watchCollections().first,
        isA<Ok<List<Collection>>>().having(
          (result) => result.value,
          'the groupings on the shelf screen',
          isEmpty,
        ),
      );
      expect(await database.libraryDao.readCollection(id), isNotNull);

      await repository.restoreCollection(id);

      expect(
        ((await repository.watchCollections().first) as Ok<List<Collection>>)
            .value,
        hasLength(1),
      );
    });

    test('leaves the works behind when it is deleted', () async {
      // Deleting a shelf is not deleting what was on it, which is what the
      // contract says where `DeleteCollection` is declared.
      final database = _open();
      final repository = await _repository(database);
      final imported = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final created = await repository.createCollection(
        const CollectionEdits(name: 'Para reler'),
      );

      await repository.deleteCollection((created as Ok<Collection>).value.id);

      expect((await repository.watchEbooks().first).titles, <String>[
        (imported as Ok<Ebook>).value.title,
      ]);
    });

    test('refuses an edit to a grouping this device does not hold', () async {
      final repository = await _repository(_open());

      final result = await repository.editCollection(
        'ffffffff-1111-4111-8111-111111111111',
        const CollectionEdits(name: 'Nada'),
      );

      expect(
        ((result as Error<void>).error as AppException).kind,
        ErrorKind.notFound,
      );
    });
  });

  group('filing a work', () {
    /// A work and a shelf, both on this device.
    Future<(LibraryRepository, AtrilDatabase, String, String)> shelf() async {
      final database = _open();
      final repository = await _repository(database);
      final work = await repository.importEbook(
        _File('Vidas Secas.epub', <int>[1, 2, 3]),
      );
      final grouping = await repository.createCollection(
        const CollectionEdits(name: 'Para reler'),
      );

      return (
        repository,
        database,
        (work as Ok<Ebook>).value.id,
        (grouping as Ok<Collection>).value.id,
      );
    }

    test('puts the work on the shelf', () async {
      final (repository, _, work, grouping) = await shelf();

      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );

      final result = await repository
          .watchEbooks(LibraryQuery(collectionId: grouping))
          .first;

      expect(result.titles, <String>['Vidas Secas']);
    });

    test('carries the pair, because the pair is the record', () async {
      // C18. Every replica mints its own identifier for the row, so what
      // resolves the record across the federation is the natural key the delta
      // carries and not the name the operation gives it.
      final (repository, database, work, grouping) = await shelf();

      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );

      final owed = (await database.syncDao.pending()).last;

      expect(owed.entity, TargetEntity.ebookCollection);
      expect(owed.delta[fieldEbookId], work);
      expect(owed.delta[fieldCollectionId], grouping);
    });

    test('is a register, so the two directions are the only two', () async {
      // C06. Filing and unfiling are the two directions and there is no update
      // between them: the row is reused and its tombstone flipped, never
      // inserted a second time.
      final (repository, database, work, grouping) = await shelf();

      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );
      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: false,
      );
      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );

      final filings = await database.select(database.ebookCollections).get();

      expect(filings, hasLength(1));
      expect(filings.single.deleted, isFalse);

      final kinds = (await database.syncDao.pending())
          .where((op) => op.entity == TargetEntity.ebookCollection)
          .map((op) => op.kind)
          .toList();

      expect(kinds, <OperationKind>[
        OperationKind.insert,
        OperationKind.delete,
        OperationKind.insert,
      ]);
    });

    test('names one record however often it is written', () async {
      // The other half of C18: the surrogate identifier this device minted is
      // remembered and reused, so the log does not fill with new names for one
      // record while every replica resolves all of them to the same row.
      final (repository, database, work, grouping) = await shelf();

      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );
      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: false,
      );

      final named = (await database.syncDao.pending())
          .where((op) => op.entity == TargetEntity.ebookCollection)
          .map((op) => op.targetId)
          .toSet();

      expect(named, hasLength(1));
    });

    test('takes the work off the shelf without deleting either', () async {
      final (repository, _, work, grouping) = await shelf();

      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: true,
      );
      await repository.fileEbook(
        ebookId: work,
        collectionId: grouping,
        filed: false,
      );

      expect((await repository.watchEbooks().first).titles, <String>[
        'Vidas Secas',
      ]);
      expect(
        ((await repository.watchCollections().first) as Ok<List<Collection>>)
            .value,
        hasLength(1),
      );
    });

    test('refuses a pair whose halves this device does not hold', () async {
      // Refused here rather than by a foreign key, so the failure names the
      // book or the shelf instead of a table.
      final (repository, _, work, grouping) = await shelf();

      expect(
        await repository.fileEbook(
          ebookId: 'ffffffff-1111-4111-8111-111111111111',
          collectionId: grouping,
          filed: true,
        ),
        isA<Error<void>>(),
      );
      expect(
        await repository.fileEbook(
          ebookId: work,
          collectionId: 'ffffffff-1111-4111-8111-111111111111',
          filed: true,
        ),
        isA<Error<void>>(),
      );
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
        ((await repository.watchContent(id).first) as Ok<ContentState>)
            .value
            .kept,
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
        ((await repository.watchContent(id).first) as Ok<ContentState>)
            .value
            .kept,
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
        ((await repository.watchContent(id).first) as Ok<ContentState>)
            .value
            .kept,
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
        ((await repository.watchContent(work.id).first) as Ok<ContentState>)
            .value
            .kept,
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

    test(
      'lists what it is holding and not what it merely has a row for',
      () async {
        final database = _open();
        final repository = await _repository(database);

        final result = await repository.importEbook(
          _File('Vidas Secas.epub', <int>[1, 2, 3]),
        );
        final work = (result as Ok<Ebook>).value;

        // A work that arrived by synchronization, whose file is on the node.
        await _work(
          database,
          id: _id('dddd', 1),
          title: 'Não baixado',
          seed: 9,
        );

        final held = await repository.watchKeptEbooks().first;

        expect(
          <String>[
            for (final book in (held as Ok<List<Ebook>>).value) book.title,
          ],
          <String>['Vidas Secas'],
        );
        expect(work.title, 'Vidas Secas');
      },
    );

    test('reports what the store holds', () async {
      final database = _open();
      final repository = await _repository(database, quota: 1000);

      await repository.importEbook(
        _File('livro.epub', List<int>.filled(300, 7)),
      );

      final budget = await repository.storage();

      expect((budget as Ok<StorageBudget>).value.used, 300);
      expect(budget.value.available, 700);
    });
  });

  group('the content watch', () {
    late FakeContentService node;
    late Server server;
    late NodeConnection connection;

    setUp(() async {
      node = FakeContentService();
      server = Server.create(services: <Service>[node]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      connection = NodeConnection(
        NodeEndpoint(
          authority: '127.0.0.1:${server.port}',
          transportSecurity: false,
        ),
      );
    });

    tearDown(() async {
      await server.shutdown();
      await connection.shutdown();
    });

    /// A work whose file is on the node and not here, as synchronization
    /// leaves one, and the repository that can fetch it.
    Future<(LibraryRepository, String)> elsewhere(
      AtrilDatabase database,
    ) async {
      final bytes = List<int>.generate(200, (int index) => index % 256);
      final digest = sha256.convert(bytes).toString();
      final id = _id('aaaa', 1);

      node.held[digest] = Uint8List.fromList(bytes);
      node.works[id] = digest;

      final repository = await _repository(
        database,
        api: LibraryApi(
          connection: connection,
          session: SessionHolder(
            store: MemorySessionStore(),
            refresher: () => throw StateError('a download needs no refresh'),
          ),
        ),
      );

      await _work(database, id: id, title: 'Baixado', contentHash: digest);

      return (repository, id);
    }

    test('notices a download the moment the bytes land', () async {
      // A download writes to the store and to no table, so a watch woken only
      // by the transfer and the pin kept saying *not here* after the file had
      // arrived — until something unrelated moved. The store now announces
      // what it publishes and the watch listens.
      final database = _open();
      final (repository, id) = await elsewhere(database);

      final here = repository
          .watchContent(id)
          .map(
            (Result<ContentState> state) => (state as Ok<ContentState>).value,
          )
          .map((ContentState state) => state.onThisDevice);

      final flips = expectLater(
        here,
        emitsInOrder(<Object>[false, emitsThrough(true)]),
      );

      expect(await repository.downloadEbook(id), isA<Ok<EbookContent>>());

      await flips;
    });

    test(
      'drops a released file from the kept list without a row moving',
      () async {
        final database = _open();
        final (repository, id) = await elsewhere(database);

        await repository.downloadEbook(id);

        // Broadcast so that the first answer can be awaited on the same
        // subscription the rest is watched on: a second subscription would
        // read the store after the removal below and never see the book.
        final kept = repository
            .watchKeptEbooks()
            .map((Result<List<Ebook>> list) => (list as Ok<List<Ebook>>).value)
            .map((List<Ebook> works) => works.length)
            .asBroadcastStream();

        expect(await kept.first, 1);

        final emptied = expectLater(kept, emitsThrough(0));

        // Straight out of the store, as a release does: no row of any table is
        // written by it.
        await blobs.remove(node.works[id]!);

        await emptied;
      },
    );
  });

  group('a search', () {
    /// Three works with different titles, authors and formats.
    Future<LibraryRepository> shelf(AtrilDatabase database) async {
      final repository = await _repository(database);

      await _work(
        database,
        id: _id('aaaa', 1),
        title: 'Grande Sertão: Veredas',
        author: 'João Guimarães Rosa',
      );
      await _work(
        database,
        id: _id('aaaa', 2),
        title: 'Vidas Secas',
        author: 'Graciliano Ramos',
        seed: 2,
      );
      await _work(
        database,
        id: _id('aaaa', 3),
        title: 'Os Sertões',
        author: 'Euclides da Cunha',
        seed: 3,
        format: 'pdf',
      );

      return repository;
    }

    test('finds a word the reader typed without its accents', () async {
      // The same fold the shelf is ordered by. `LIKE` in sqlite is
      // ASCII-insensitive and nothing else, so this reader would find nothing.
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(term: 'sertao'))
          .first;

      expect(result.titles, <String>['Grande Sertão: Veredas']);
    });

    test('matches what it was given and does not guess a plural', () async {
      // `sertao` does not find *Os Sertões*, and that is the match this app
      // makes rather than a gap in it: folding removes the marks above the
      // letters and nothing else, so a search stays something a reader can
      // predict. A stemmer would find the plural and would also decide, on
      // this app's behalf, which words are the same word — in a library that
      // holds books in more than one language.
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(term: 'sert'))
          .first;

      expect(result.titles, <String>['Grande Sertão: Veredas', 'Os Sertões']);
    });

    test('searches the author as well as the title', () async {
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(term: 'graciliano'))
          .first;

      expect(result.titles, <String>['Vidas Secas']);
    });

    test('matches every word, and not the phrase in order', () async {
      // A reader who types an author and a title is naming two things, and a
      // search that required them adjacent would find nothing.
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(term: 'rosa veredas'))
          .first;

      expect(result.titles, <String>['Grande Sertão: Veredas']);
    });

    test('narrows to one format', () async {
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(format: EbookFormat.pdf))
          .first;

      expect(result.titles, <String>['Os Sertões']);
    });

    test('narrows by the format and the search together', () async {
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(
            const LibraryQuery(term: 'sertao', format: EbookFormat.epub),
          )
          .first;

      expect(result.titles, <String>['Grande Sertão: Veredas']);
    });

    test('narrows by the shelf, the format and the search together', () async {
      final database = _open();
      final repository = await shelf(database);

      await _grouping(database, id: _id('bbbb', 1), name: 'Para reler');
      await _filing(
        database,
        id: _id('cccc', 1),
        ebookId: _id('aaaa', 1),
        collectionId: _id('bbbb', 1),
      );
      await _filing(
        database,
        id: _id('cccc', 2),
        ebookId: _id('aaaa', 3),
        collectionId: _id('bbbb', 1),
      );

      final result = await repository
          .watchEbooks(
            LibraryQuery(
              collectionId: _id('bbbb', 1),
              format: EbookFormat.epub,
              term: 'sertao',
            ),
          )
          .first;

      expect(result.titles, <String>['Grande Sertão: Veredas']);
    });

    test('answers the whole collection for a term of only spaces', () async {
      final repository = await shelf(_open());

      final result = await repository
          .watchEbooks(const LibraryQuery(term: '   '))
          .first;

      expect(result.titles, hasLength(3));
    });

    test('reaches no node to answer any of it', () async {
      // The collection is on this device, so narrowing it is a question about
      // rows this app already holds — and the client in this fixture dials a
      // host nothing is listening on, which is what makes that assertion
      // rather than an assumption.
      final repository = await shelf(_open());

      expect(
        (await repository.watchEbooks(const LibraryQuery(term: 'sertao')).first)
            .titles,
        isNotEmpty,
      );
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

      await _work(database, id: _id('aaaa', 1), title: 'Anonymous', seed: 1);
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

      final counts = await (await _repository(database))
          .watchFilingCounts()
          .first;

      // A grouping nothing is filed under is absent rather than zero, which is
      // what one query over two tables can answer and what `?? 0` reads.
      expect((counts as Ok<Map<String, int>>).value, <String, int>{
        _id('bbbb', 1): 2,
      });
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

      final result = await (await _repository(database))
          .watchCollectionsOf(_id('aaaa', 1))
          .first;

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
        answers.map((result) => (result as Ok<Ebook?>).value?.title),
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

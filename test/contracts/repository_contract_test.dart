/// The contract, run against the fake and against the thing.
///
/// Eleven fakes stand in for the repositories in every widget test in this
/// suite, and nothing said they agreed with the repositories they stand in for.
/// This is what says it: the same descriptions, twice, over a list on one side
/// and a drift database on the other.
library;

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/annotations/annotation_repository_impl.dart';
import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/library/library_repository_impl.dart';
import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/content/upload_queue.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/services/storage/memory_blob_store.dart';
import '../ui/fakes/fakes.dart';
import 'repository_contract.dart';

/// The device the seeded rows are attributed to.
const String _device = '11111111-1111-4111-8111-111111111111';

final DateTime _at = DateTime.utc(2026, 8, 31, 12);

/// A digest per work, so two works are never the same file by accident.
String _hashOf(String id) =>
    id.hashCode.abs().toRadixString(16).padLeft(64, '0');

Revision _revision(DateTime at, {bool deleted = false}) => Revision(
  vectorClock: VectorClock.of(<String, int>{_device: 1}),
  updatedAt: at,
  deviceId: _device,
  deleted: deleted,
);

/// The contract over the fakes every widget test in this suite is written
/// against.
final class _FakeSubject with RepositoryContract {
  @override
  Future<({LibraryRepository library, AnnotationRepository annotations})> seed({
    List<WorkSeed> works = const <WorkSeed>[],
    List<MarkSeed> marks = const <MarkSeed>[],
  }) async {
    final FakeLibraryRepository library = FakeLibraryRepository();
    final FakeAnnotationRepository annotations = FakeAnnotationRepository();

    addTearDown(annotations.close);

    final List<Ebook> shelf = <Ebook>[
      for (final WorkSeed it in works)
        Ebook(
          id: contractId(it.id),
          title: it.title,
          author: it.author,
          format: it.format,
          contentHash: _hashOf(it.id),
          importedAt: it.importedAt,
          revision: _revision(it.importedAt, deleted: it.deleted),
        ),
    ];
    final List<Annotation> made = <Annotation>[
      for (final MarkSeed it in marks)
        Annotation(
          id: contractId(it.id),
          ebookId: contractId(it.ebookId),
          kind: it.kind,
          locator: it.locator,
          revision: _revision(it.at, deleted: it.removed),
        ),
    ];

    library.works.add(Result<List<Ebook>>.ok(shelf));
    annotations
      ..emitMarks(made)
      ..exportable = <MarkedPassage>[
        for (final Annotation it in made)
          if (!it.revision.deleted)
            MarkedPassage(
              mark: it,
              work: shelf.firstWhere((Ebook work) => work.id == it.ebookId),
            ),
      ];

    return (library: library, annotations: annotations);
  }
}

/// The contract over the repositories the application actually runs.
final class _DriftSubject with RepositoryContract {
  @override
  Future<({LibraryRepository library, AnnotationRepository annotations})> seed({
    List<WorkSeed> works = const <WorkSeed>[],
    List<MarkSeed> marks = const <MarkSeed>[],
  }) async {
    final AtrilDatabase database = AtrilDatabase(NativeDatabase.memory());

    addTearDown(database.close);

    await database.identityDao.bindDevice(
      id: _device,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );

    for (final WorkSeed it in works) {
      await database
          .into(database.ebooks)
          .insert(
            EbooksCompanion.insert(
              id: contractId(it.id),
              title: it.title,
              author: Value<String?>(it.author),
              format: it.format.wireName,
              contentHash: _hashOf(it.id),
              importedAt: it.importedAt,
              vectorClock: VectorClock.of(<String, int>{_device: 1}),
              updatedAt: it.importedAt,
              deviceId: _device,
              deleted: Value<bool>(it.deleted),
            ),
          );
    }

    for (final MarkSeed it in marks) {
      await database
          .into(database.annotations)
          .insert(
            AnnotationsCompanion.insert(
              id: contractId(it.id),
              ebookId: contractId(it.ebookId),
              kind: it.kind.wireName,
              locator: it.locator,
              content: Value<String?>(
                it.kind == AnnotationKind.note ? 'uma nota' : null,
              ),
              vectorClock: VectorClock.of(<String, int>{_device: 1}),
              updatedAt: it.at,
              deviceId: _device,
              deleted: Value<bool>(it.removed),
            ),
          );
    }

    final HybridClock clock = HybridClock(wall: () => _at);
    final OperationAuthor author = OperationAuthor(
      database: database,
      clock: clock,
      reconciler: Reconciler(database, clock),
      mint: () => contractId('minted'),
    );
    final MemoryBlobStore blobs = MemoryBlobStore();
    // A client dialling nowhere: nothing in the contract reaches a node, and a
    // subject that started talking to one should fail rather than pass quietly.
    final LibraryApi api = LibraryApi(
      connection: NodeConnection(
        NodeEndpoint(authority: 'nowhere.example:9090'),
      ),
      session: SessionHolder(
        store: MemorySessionStore(),
        refresher: () => throw StateError('the contract dials nothing'),
      ),
    );

    return (
      library: LibraryRepositoryImpl(
        library: database.libraryDao,
        author: author,
        blobs: blobs,
        downloads: ContentDownloader(api: api, blobs: blobs),
        transfers: database.transfersDao,
        keepsByDefault: true,
        budget: (BlobStore store) async =>
            StorageBudget(used: await store.usedBytes()),
        uploads: UploadQueue(
          database: database,
          uploader: ContentUploader(api: api, blobs: blobs),
          now: () => _at,
        ),
        mint: () => contractId('minted'),
        now: () => _at,
      ),
      annotations: AnnotationRepositoryImpl(
        marks: database.annotationsDao,
        library: database.libraryDao,
        author: author,
        mint: () => contractId('minted'),
      ),
    );
  }
}

void main() {
  group('the fakes the screens are tested against', _FakeSubject().runContract);
  group('the repositories the app runs', _DriftSubject().runContract);
}

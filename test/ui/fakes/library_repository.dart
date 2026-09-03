/// A [LibraryRepository] that answers from memory.
library;

import 'dart:async';

import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/utils/cancellation.dart';
import 'package:atril/utils/collation.dart';
import 'package:atril/utils/result.dart';

/// A [LibraryRepository] that answers from memory.
///
/// The works and the groupings are broadcast controllers rather than fields,
/// because what the screen is written against is a *stream*: a test that set a
/// list and pumped would be exercising a repository this app does not have.
/// Nothing is emitted until a test says so, which is also how the state before
/// the first answer — the one that is neither empty nor full — is reached.
final class FakeLibraryRepository implements LibraryRepository {
  /// Remembers what was last pushed, so that a watch started afterwards is
  /// answered rather than left waiting.
  FakeLibraryRepository() {
    works.stream.listen((Result<List<Ebook>> result) => _latest = result);
  }

  /// The works, as the screen sees them arrive.
  final StreamController<Result<List<Ebook>>> works =
      StreamController<Result<List<Ebook>>>.broadcast();

  /// The last answer pushed, or `null` before the first one.
  ///
  /// **A watch opens with it, as drift's does.** The real repository answers a
  /// `watch` with the rows as they stand and then with every change; a fake
  /// that said nothing until the next push would leave a screen that subscribed
  /// late on its spinner forever, which is a difference between the fake and
  /// the thing rather than a state of this application. Nothing is replayed
  /// before the first push, which is what keeps *the answer has not arrived*
  /// reachable.
  Result<List<Ebook>>? _latest;

  /// The groupings.
  final StreamController<Result<List<Collection>>> groupings =
      StreamController<Result<List<Collection>>>.broadcast();

  /// How many works are filed under each grouping.
  final StreamController<Result<Map<String, int>>> counts =
      StreamController<Result<Map<String, int>>>.broadcast();

  /// Every query the screen has asked, in order.
  final List<LibraryQuery> queries = <LibraryQuery>[];

  /// Every file it was asked to import, in order.
  final List<FileSource> imports = <FileSource>[];

  /// What the next import fails with, or `null` to let it succeed.
  Exception? refusal;

  /// How many times the screen asked for the deleted works' files back.
  int reclaims = 0;

  @override
  Future<Result<int>> reclaimBytes() async {
    reclaims++;

    return const Result<int>.ok(0);
  }

  @override
  Future<Result<Ebook>> importEbook(FileSource file) async {
    imports.add(file);

    final refused = refusal;

    if (refused != null) {
      return Result<Ebook>.error(refused);
    }

    return Result<Ebook>.ok(_imported(file));
  }

  Ebook _imported(FileSource file) => Ebook(
    id: 'imported',
    title: file.name,
    format: EbookFormat.epub,
    contentHash: '0' * 64,
    importedAt: DateTime.utc(2026, 8, 31),
    revision: Revision(
      vectorClock: VectorClock.empty.tick('device'),
      updatedAt: DateTime.utc(2026, 8, 31),
      deviceId: 'device',
    ),
  );

  /// Which works are filed under which grouping, for a query that narrows to
  /// one.
  final Map<String, Set<String>> filedUnder = <String, Set<String>>{};

  /// The works [query] asks for, out of what a test pushed.
  ///
  /// **It narrows, orders and drops tombstones exactly as the real repository
  /// does**, using the same collation, because a fake that answered every
  /// query with the whole list is a fake the screens above it agree with and
  /// the app does not. `repository_contract_test.dart` is what says the two
  /// still agree.
  List<Ebook> narrow(List<Ebook> works, LibraryQuery query) {
    final String? shelf = query.collectionId;
    final List<Ebook> matching = <Ebook>[
      for (final Ebook work in works)
        if (!work.revision.deleted &&
            (query.format == null || work.format == query.format) &&
            (shelf == null ||
                (filedUnder[shelf]?.contains(work.id) ?? false)) &&
            _matches(work, query.term))
          work,
    ];

    switch (query.sort) {
      case LibrarySort.recentlyImported:
        matching.sort((Ebook a, Ebook b) {
          final int byInstant = b.importedAt.compareTo(a.importedAt);

          return byInstant != 0 ? byInstant : compareFolded(a.title, b.title);
        });
      case LibrarySort.title:
        matching.sort((Ebook a, Ebook b) => compareFolded(a.title, b.title));
      case LibrarySort.author:
        matching.sort((Ebook a, Ebook b) {
          final int byAuthor = switch ((a.author, b.author)) {
            (null, null) => 0,
            (null, _) => 1,
            (_, null) => -1,
            (final String left, final String right) => compareFolded(
              left,
              right,
            ),
          };

          return byAuthor != 0 ? byAuthor : compareFolded(a.title, b.title);
        });
    }

    return matching;
  }

  bool _matches(Ebook work, String term) {
    final List<String> words = term.trim().split(RegExp(r'\s+'))
      ..removeWhere((String word) => word.isEmpty);

    if (words.isEmpty) {
      return true;
    }

    final String haystack = '${work.title} ${work.author ?? ''}';

    return words.every((String word) => containsFolded(haystack, word));
  }

  @override
  Stream<Result<List<Ebook>>> watchEbooks([
    LibraryQuery query = const LibraryQuery(),
  ]) {
    queries.add(query);

    return _answers.map(
      (Result<List<Ebook>> result) => switch (result) {
        Ok<List<Ebook>>(:final List<Ebook> value) => Result<List<Ebook>>.ok(
          narrow(value, query),
        ),
        Error<List<Ebook>>() => result,
      },
    );
  }

  /// What has been pushed, starting from the last one where there is one.
  Stream<Result<List<Ebook>>> get _answers async* {
    final Result<List<Ebook>>? latest = _latest;

    if (latest != null) {
      yield latest;
    }

    yield* works.stream;
  }

  @override
  Stream<Result<Ebook?>> watchEbook(String id) => works.stream.map(
    (result) => switch (result) {
      Ok<List<Ebook>>(:final value) => Result<Ebook?>.ok(
        value.where((work) => work.id == id).firstOrNull,
      ),
      Error<List<Ebook>>(:final error) => Result<Ebook?>.error(error),
    },
  );

  @override
  Future<Result<Ebook?>> ebook(String id) async =>
      const Result<Ebook?>.ok(null);

  @override
  Stream<Result<List<Collection>>> watchCollections() => groupings.stream;

  @override
  Stream<Result<Map<String, int>>> watchFilingCounts() => counts.stream;

  @override
  Stream<Result<List<Collection>>> watchCollectionsOf(String ebookId) =>
      groupings.stream;

  /// The works whose bytes this device holds.
  final Set<String> downloaded = <String>{};

  /// Every work a download was asked for, in order.
  final List<String> fetches = <String>[];

  @override
  Future<Result<EbookContent>> downloadEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    fetches.add(ebookId);

    final refused = refusal;

    if (refused != null) {
      return Result<EbookContent>.error(refused);
    }

    downloaded.add(ebookId);

    return Result<EbookContent>.ok(
      const EbookContent(
        contentHash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        sizeBytes: 3,
        mediaType: 'application/epub+zip',
      ),
    );
  }

  /// The works whose files the node has not received yet, and how big they are.
  final Map<String, int> owed = <String, int>{};

  @override
  Stream<Result<ContentState>> watchContent(String ebookId) => works.stream.map(
    (_) => Result<ContentState>.ok(
      ContentState(
        onThisDevice: downloaded.contains(ebookId),
        kept: kept.contains(ebookId),
        owedBytes: owed[ebookId],
      ),
    ),
  );

  /// Every edit it was handed, as `(ebookId, edits)`.
  final List<(String, EbookEdits)> edits = <(String, EbookEdits)>[];

  @override
  Future<Result<void>> editEbook(String ebookId, EbookEdits changes) async {
    edits.add((ebookId, changes));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// Every grouping it was asked to create, in order.
  final List<CollectionEdits> created = <CollectionEdits>[];

  /// Every change to a grouping, as `(collectionId, edits)`.
  final List<(String, CollectionEdits)> collectionEdits =
      <(String, CollectionEdits)>[];

  /// Every grouping it was asked to tombstone, and to bring back.
  final List<String> deletedCollections = <String>[];

  /// Every grouping it was asked to bring back, in order.
  final List<String> restoredCollections = <String>[];

  @override
  Future<Result<Collection>> createCollection(CollectionEdits edits) async {
    created.add(edits);

    final refused = refusal;

    if (refused != null) {
      return Result<Collection>.error(refused);
    }

    return Result<Collection>.ok(
      Collection(
        id: 'created',
        name: edits.name,
        kind: edits.kind,
        description: edits.description,
        createdAt: DateTime.utc(2026, 8, 31),
        revision: Revision(
          vectorClock: VectorClock.empty.tick('device'),
          updatedAt: DateTime.utc(2026, 8, 31),
          deviceId: 'device',
        ),
      ),
    );
  }

  @override
  Future<Result<void>> editCollection(
    String collectionId,
    CollectionEdits edits,
  ) async {
    collectionEdits.add((collectionId, edits));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    deletedCollections.add(collectionId);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreCollection(String collectionId) async {
    restoredCollections.add(collectionId);

    return const Result<void>.ok(null);
  }

  /// Every filing it was asked for, as `(ebookId, collectionId, filed)`.
  final List<(String, String, bool)> filings = <(String, String, bool)>[];

  @override
  Future<Result<void>> fileEbook({
    required String ebookId,
    required String collectionId,
    required bool filed,
  }) async {
    filings.add((ebookId, collectionId, filed));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// Every work it was asked to tombstone, in order.
  final List<String> deleted = <String>[];

  /// Every work it was asked to bring back, in order.
  final List<String> restored = <String>[];

  @override
  Future<Result<void>> deleteEbook(String ebookId) async {
    deleted.add(ebookId);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreEbook(String ebookId) async {
    restored.add(ebookId);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// The works this device keeps, which starts as every one it holds.
  final Set<String> kept = <String>{};

  /// Every work a release was asked for, in order.
  final List<String> released = <String>[];

  /// What the store reports.
  StorageBudget storageBudget = const StorageBudget(used: 0);

  @override
  Future<Result<void>> keepEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    kept.add(ebookId);
    downloaded.add(ebookId);

    return const Result<void>.ok(null);
  }

  @override
  Future<Result<void>> releaseEbook(String ebookId) async {
    released.add(ebookId);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    kept.remove(ebookId);
    downloaded.remove(ebookId);

    return const Result<void>.ok(null);
  }

  @override
  Future<Result<StorageBudget>> storage() async =>
      Result<StorageBudget>.ok(storageBudget);

  @override
  Stream<Result<List<Ebook>>> watchKeptEbooks() => works.stream.map(
    (result) => switch (result) {
      Ok<List<Ebook>>(:final value) => Result<List<Ebook>>.ok(<Ebook>[
        for (final work in value)
          if (kept.contains(work.id)) work,
      ]),
      Error<List<Ebook>>(:final error) => Result<List<Ebook>>.error(error),
    },
  );

  /// The covers this device has, by work.
  final Map<String, EpubCover> covers = <String, EpubCover>{};

  @override
  Future<Result<EpubCover?>> cover(String ebookId) async =>
      Result<EpubCover?>.ok(covers[ebookId]);
}

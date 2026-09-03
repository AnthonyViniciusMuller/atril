/// [LibraryRepository] over the local replica.
library;

import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../domain/models/operation.dart';
import '../../../utils/collation.dart';
import '../../../utils/errors.dart';
import '../../../utils/identifiers.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../../utils/streams.dart';
import '../../model/row_mappers.dart';
import '../../services/api/errors.dart';
import '../../services/content/content_downloader.dart';
import '../../services/content/upload_queue.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/dao/transfers_dao.dart';
import '../../services/storage/blob_storage.dart';
import '../../services/sync/author.dart';
import '../../services/sync/delta.dart';
import 'library_bytes.dart';
import 'library_repository.dart';

final _log = loggerFor('data/library');

/// The operation an edit reports under.
const String opEdit = 'library/collection: edit';

/// The operation a deletion and its undo report under.
const String opDelete = 'library/collection: delete';

/// The operation a change to a grouping reports under.
const String opGrouping = 'library/groupings: write';

/// The operation filing and unfiling report under.
const String opFiling = 'library/filings: write';

/// [value], or `null` where it holds nothing.
///
/// An object with no entries and no object at all are the same claim about a
/// work — there is nothing the format carried — and the column stores `NULL`
/// for both. Normalizing them here is what lets the two sides of a comparison
/// be compared at all.
Map<String, Object?>? _emptyIsCleared(Map<String, Object?> value) =>
    value.isEmpty ? null : value;

/// The reader's collection, read out of drift.
///
/// The half of it that moves *bytes* — importing a file, fetching one, keeping
/// one, letting one go — is [LibraryBytes], in its own file. It is one
/// repository over one interface either way: the two halves share the DAO and
/// the author and nothing else, and the split is what keeps a transfer from
/// sitting between two methods about titles.
final class LibraryRepositoryImpl
    with LibraryBytes
    implements LibraryRepository {
  /// The repository over [library], writing through [author] and keeping the
  /// bytes in [blobs].
  ///
  /// [mint] names a work and [now] stamps when it entered the collection; both
  /// are parameters so that a test can say what it expects rather than read
  /// back what happened.
  LibraryRepositoryImpl({
    required this.library,
    required this.author,
    required this.blobs,
    required this.uploads,
    required this.downloads,
    required this.transfers,
    required this.budget,
    this.keepsByDefault = true,
    String Function()? mint,
    DateTime Function()? now,
  }) : mintIdentity = mint ?? mintIdentifier,
       now = now ?? DateTime.now;

  @override
  final LibraryDao library;

  /// Where a change to a replicable record goes. There is no other way out of
  /// this repository, and C21 is why.
  @override
  final OperationAuthor author;

  /// Where the bytes go.
  @override
  final BlobStore blobs;

  /// What the node is owed, and what eventually pays it.
  @override
  final UploadQueue uploads;

  /// What brings a file the other way.
  @override
  final ContentDownloader downloads;

  /// What is owed, and what the reader decided to keep.
  @override
  final TransfersDao transfers;

  /// What the store holds and may hold, asked of the platform.
  @override
  final Future<StorageBudget> Function(BlobStore blobs) budget;

  /// Whether a book arrives kept.
  ///
  /// True on the five native targets and false in a browser, decided at the
  /// composition root rather than here: a repository that asked the framework
  /// what platform it was on would be a repository that could not be tested as
  /// any other. It is the *default* and never the answer — the answer is the
  /// reader's decision where they have taken one.
  @override
  final bool keepsByDefault;

  @override
  final String Function() mintIdentity;

  @override
  final DateTime Function() now;

  @override
  Future<Result<void>> editEbook(String ebookId, EbookEdits edits) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opEdit,
        );
      }

      // Every claim carries the value the record already holds, and one that
      // matches it is not made. C17 is why it is worth the parameters: a delta
      // restating a title the reader never touched carries this device's claim
      // to it, and the next merge against a device that *did* change it is
      // decided by a tie-break rather than by what anybody meant.
      final claims = DeltaWriter()
        ..text(fieldTitle, edits.title.trim(), current: work.title)
        ..text(fieldAuthor, blankIsAbsent(edits.author), current: work.author)
        ..text(
          fieldPublisher,
          blankIsAbsent(edits.publisher),
          current: work.publisher,
        )
        ..text(
          fieldLanguage,
          blankIsAbsent(edits.language),
          current: work.language,
        )
        ..object(
          fieldExtraMetadata,
          _emptyIsCleared(edits.extraMetadata),
          // Both sides are normalized the same way, and that is what stops an
          // edit from claiming a field nobody touched: a record with no extra
          // metadata reads back as an empty map, and comparing that against a
          // form which produced one would make *no metadata* and *no metadata*
          // look like a change on every save.
          current: _emptyIsCleared(metadataOf(work.extraMetadata)),
        );

      if (claims.isEmpty) {
        // Nothing changed. It is not a failure and there is nothing to report:
        // a reader who opened a form and closed it has done nothing wrong, and
        // authoring an empty change would be this device telling every replica
        // that nothing happened.
        _log.fine('the edit to $ebookId claims nothing');

        return const Result<void>.ok(null);
      }

      await author.write(
        Change.update(TargetEntity.ebook, ebookId, claims.fields),
      );

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning('$ebookId could not be edited', error, stackTrace);

      return Result<void>.error(failureFrom(error, op: opEdit));
    }
  }

  @override
  Future<Result<Collection>> createCollection(CollectionEdits edits) async {
    try {
      final id = mintIdentity();
      final claims = DeltaWriter()
        ..text(fieldName, edits.name.trim())
        ..text(fieldKind, edits.kind.wireName)
        ..text(fieldDescription, blankIsAbsent(edits.description))
        ..instant(fieldCreatedAt, now().toUtc());

      await author.write(
        Change.insert(TargetEntity.collection, id, claims.fields),
      );

      return Result<Collection>.ok(
        collectionOfRow((await library.readCollection(id))!),
      );
    } on Object catch (error, stackTrace) {
      _log.warning('the grouping could not be created', error, stackTrace);

      return Result<Collection>.error(failureFrom(error, op: opGrouping));
    }
  }

  @override
  Future<Result<void>> editCollection(
    String collectionId,
    CollectionEdits edits,
  ) async {
    try {
      final row = await library.readCollection(collectionId);

      if (row == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no grouping called $collectionId',
          op: opGrouping,
        );
      }

      final claims = DeltaWriter()
        ..text(fieldName, edits.name.trim(), current: row.name)
        ..text(fieldKind, edits.kind.wireName, current: row.kind)
        ..text(
          fieldDescription,
          blankIsAbsent(edits.description),
          current: row.description,
        );

      if (claims.isEmpty) {
        return const Result<void>.ok(null);
      }

      await author.write(
        Change.update(TargetEntity.collection, collectionId, claims.fields),
      );

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning('$collectionId could not be edited', error, stackTrace);

      return Result<void>.error(failureFrom(error, op: opGrouping));
    }
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) => _grouping(
    collectionId,
    Change.delete(TargetEntity.collection, collectionId),
  );

  @override
  Future<Result<void>> restoreCollection(String collectionId) => _grouping(
    collectionId,
    Change.restore(TargetEntity.collection, collectionId),
  );

  /// Authors [change] against the grouping [collectionId] names.
  Future<Result<void>> _grouping(String collectionId, Change change) async {
    try {
      if (await library.readCollection(collectionId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no grouping called $collectionId',
          op: opGrouping,
        );
      }

      await author.write(change);

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning('$change on $collectionId did not apply', error, stackTrace);

      return Result<void>.error(failureFrom(error, op: opGrouping));
    }
  }

  @override
  Future<Result<void>> fileEbook({
    required String ebookId,
    required String collectionId,
    required bool filed,
  }) async {
    try {
      // Both halves, checked here so that the refusal names the book or the
      // shelf. The reconciler refuses the same thing one layer down and would
      // report it as a record it does not hold, which is true and is not what
      // a reader needs to be told.
      if (await library.readEbook(ebookId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opFiling,
        );
      }

      if (await library.readCollection(collectionId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no grouping called $collectionId',
          op: opFiling,
        );
      }

      // Two directions and no update between them, because membership is a
      // register per pair and not a row that is appended. Filing a work that
      // is already filed is the same request as filing it, which is what makes
      // the operation safe to replay and safe to send twice.
      await author.write(
        filed
            ? Change.filing(ebookId: ebookId, collectionId: collectionId)
            : Change.unfiling(ebookId: ebookId, collectionId: collectionId),
      );

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning(
        '$ebookId could not be filed under $collectionId',
        error,
        stackTrace,
      );

      return Result<void>.error(failureFrom(error, op: opFiling));
    }
  }

  @override
  Future<Result<void>> deleteEbook(String ebookId) async {
    final tombstoned = await _tombstone(
      ebookId,
      Change.delete(TargetEntity.ebook, ebookId),
    );

    if (tombstoned case Ok<void>()) {
      // The moment the bytes become reclaimable, and the moment the reader is
      // looking at the number that has to move. A failure here is not the
      // deletion's — the work is tombstoned either way — and `reclaimBytes`
      // reports rather than throws.
      await reclaimBytes();
    }

    return tombstoned;
  }

  @override
  Future<Result<void>> restoreEbook(String ebookId) =>
      _tombstone(ebookId, Change.restore(TargetEntity.ebook, ebookId));

  /// Authors [change] against the work [ebookId] names.
  ///
  /// The two directions are one path because they are one operation with one
  /// bit different, and writing them apart would be two chances to get the
  /// same thing wrong.
  Future<Result<void>> _tombstone(String ebookId, Change change) async {
    try {
      if (await library.readEbook(ebookId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opDelete,
        );
      }

      await author.write(change);

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning('$change on $ebookId did not apply', error, stackTrace);

      return Result<void>.error(failureFrom(error, op: opDelete));
    }
  }

  @override
  Stream<Result<List<Ebook>>> watchEbooks([
    LibraryQuery query = const LibraryQuery(),
  ]) => library
      .watchEbooks(
        collectionId: query.collectionId,
        format: query.format?.wireName,
      )
      .map(
        (rows) => _sorted(
          // The search is matched here and not in SQL, on the same folded key
          // the shelf is ordered by. `LIKE` in sqlite is ASCII-insensitive
          // and nothing else, so a reader who typed `sertao` would find
          // nothing — and one who typed `Sertão` would find it under a rule
          // that disagrees with the order the results come back in.
          <Ebook>[
            for (final row in rows.map(ebookOfRow))
              if (_matches(row, query.term)) row,
          ],
          query.sort,
        ),
      )
      .asResults(opReadLibrary);

  @override
  Stream<Result<Ebook?>> watchEbook(String id) => library
      .watchEbook(id)
      .map((row) => row?.let(ebookOfRow))
      .asResults(opReadLibrary);

  @override
  Future<Result<Ebook?>> ebook(String id) async {
    try {
      return Result<Ebook?>.ok((await library.readEbook(id))?.let(ebookOfRow));
    } on Object catch (error) {
      _log.warning('the work $id could not be read', error);

      return Result<Ebook?>.error(failureFrom(error, op: opReadLibrary));
    }
  }

  @override
  Stream<Result<List<Collection>>> watchCollections() => library
      .watchCollections()
      .map((rows) => rows.map(collectionOfRow).toList()..sort(_byName))
      .asResults(opReadLibrary);

  @override
  Stream<Result<Map<String, int>>> watchFilingCounts() =>
      library.watchFilingCounts().asResults(opReadLibrary);

  @override
  Stream<Result<List<Collection>>> watchCollectionsOf(String ebookId) => library
      .watchCollectionsOf(ebookId)
      .map((rows) => rows.map(collectionOfRow).toList()..sort(_byName))
      .asResults(opReadLibrary);
}

/// [works], in the order [sort] asks for.
///
/// The list is sorted rather than the query, and the comparison is the folded
/// one: *Sertão* belongs between *Sermão* and *Serviço*, which no collation
/// sqlite ships would put it in. The tie-break is always the title, so that
/// two works by one author have an order at all — a list whose rows swap
/// between two builds of the same query is a list that jumps under the
/// reader's finger.
List<Ebook> _sorted(List<Ebook> works, LibrarySort sort) {
  switch (sort) {
    case LibrarySort.recentlyImported:
      works.sort((a, b) {
        final byInstant = b.importedAt.compareTo(a.importedAt);

        return byInstant != 0 ? byInstant : compareFolded(a.title, b.title);
      });
    case LibrarySort.title:
      works.sort((a, b) => compareFolded(a.title, b.title));
    case LibrarySort.author:
      works.sort((a, b) {
        // An absent author sorts last, and not under some rendering of
        // *unknown*: it is a fact about the file, and sorting it into the As
        // would put it among the names of real people.
        final byAuthor = switch ((a.author, b.author)) {
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
          (final String left, final String right) => compareFolded(left, right),
        };

        return byAuthor != 0 ? byAuthor : compareFolded(a.title, b.title);
      });
  }

  return works;
}

int _byName(Collection a, Collection b) => compareFolded(a.name, b.name);

/// Whether [work] answers [term].
///
/// The title and the author, which are the two things a reader remembers about
/// a book they are looking for. The publisher and the language are not: a
/// search over them would return every book from one house for a term that
/// happened to name one.
///
/// Every word has to match something, and not the whole phrase in order: a
/// reader who types `rosa sertão` is naming an author and a title, and a search
/// that required them adjacent would find nothing.
bool _matches(Ebook work, String term) {
  final words = term.trim().split(RegExp(r'\s+'))
    ..removeWhere((String word) => word.isEmpty);

  if (words.isEmpty) {
    return true;
  }

  final haystack = '${work.title} ${work.author ?? ''}';

  return words.every((String word) => containsFolded(haystack, word));
}

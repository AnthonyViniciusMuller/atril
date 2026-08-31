/// [LibraryRepository] over the local replica.
library;

import 'dart:async';
import 'dart:convert';

import '../../../domain/crdt/revision.dart';
import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../utils/collation.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/errors.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/database.dart';
import 'library_repository.dart';

final _log = loggerFor('data/library');

/// The operation a failed reading of the collection reports under.
const String opReadLibrary = 'library/collection: read';

/// The reader's collection, read out of drift.
final class LibraryRepositoryImpl implements LibraryRepository {
  /// The repository over [library].
  LibraryRepositoryImpl({required this.library});

  /// The rows.
  final LibraryDao library;

  @override
  Stream<Result<List<Ebook>>> watchEbooks([
    LibraryQuery query = const LibraryQuery(),
  ]) => _guard(
    library
        .watchEbooks(collectionId: query.collectionId)
        .map((rows) => _sorted(rows.map(ebookOfRow).toList(), query.sort)),
  );

  @override
  Stream<Result<Ebook?>> watchEbook(String id) =>
      _guard(library.watchEbook(id).map((row) => row?.let(ebookOfRow)));

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
  Stream<Result<List<Collection>>> watchCollections() => _guard(
    library.watchCollections().map(
      (rows) => rows.map(collectionOfRow).toList()..sort(_byName),
    ),
  );

  @override
  Stream<Result<Map<String, int>>> watchFilingCounts() =>
      _guard(library.watchFilingCounts());

  @override
  Stream<Result<List<Collection>>> watchCollectionsOf(String ebookId) => _guard(
    library.watchCollectionsOf(ebookId).map(
      (rows) => rows.map(collectionOfRow).toList()..sort(_byName),
    ),
  );

  /// [source] with every value wrapped and every failure reported as one.
  ///
  /// The stream is not ended by a failure that reaches here, because the thing
  /// that failed is one query and not the database: a screen told that its
  /// list could not be built should still be showing the next version of it
  /// when the reason goes away. drift's own stream does close after an error,
  /// which is the case this cannot mend and is the reason the error is
  /// reported rather than swallowed.
  Stream<Result<T>> _guard<T>(Stream<T> source) => source.transform(
    StreamTransformer<T, Result<T>>.fromHandlers(
      handleData: (T value, EventSink<Result<T>> sink) =>
          sink.add(Result<T>.ok(value)),
      handleError:
          (Object error, StackTrace stackTrace, EventSink<Result<T>> sink) {
            _log.warning('the collection could not be read', error, stackTrace);

            sink.add(Result<T>.error(failureFrom(error, op: opReadLibrary)));
          },
    ),
  );
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

/// A work, as the replica holds it.
///
/// The format is read through [EbookFormat.parse], so a value a later build of
/// the node knows and this one does not comes back as `null` rather than as a
/// failure: a work whose format this build cannot name is still listed,
/// synchronized and kept.
Ebook ebookOfRow(EbookRow row) => Ebook(
  id: row.id,
  title: row.title,
  author: row.author,
  publisher: row.publisher,
  language: row.language,
  format: EbookFormat.parse(row.format),
  contentHash: row.contentHash,
  sizeBytes: row.sizeBytes,
  extraMetadata: _metadataOf(row.extraMetadata),
  importedAt: row.importedAt,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// A grouping, as the replica holds it.
Collection collectionOfRow(CollectionRow row) => Collection(
  id: row.id,
  name: row.name,
  kind: CollectionKind.parse(row.kind),
  description: row.description,
  createdAt: row.createdAt,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// The extra metadata a row carries, decoded.
///
/// The column is constrained to a JSON object by the schema and by the node's
/// own, so anything else in it is a database this app did not write. It is
/// reported as empty rather than thrown, because the alternative is one
/// malformed row making the whole collection unreadable.
Map<String, Object?> _metadataOf(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return const <String, Object?>{};
  }

  final decoded = json.decode(encoded);

  if (decoded is! Map<String, Object?>) {
    _log.warning('the extra metadata of a work is not an object');

    return const <String, Object?>{};
  }

  return decoded;
}

/// `?.let`, which Dart has no operator for.
///
/// It is here so that a nullable row maps to a nullable model without the
/// call site restating the null check, and it is private because it is a
/// convenience of this file rather than a utility of the app.
extension on EbookRow {
  T let<T>(T Function(EbookRow row) transform) => transform(this);
}

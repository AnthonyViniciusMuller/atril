/// [LibraryRepository] over the local replica.
library;

import 'dart:async';
import 'dart:convert';

import '../../../domain/crdt/revision.dart';
import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../domain/models/operation.dart';
import '../../../utils/cancellation.dart';
import '../../../utils/collation.dart';
import '../../../utils/errors.dart';
import '../../../utils/identifiers.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

import 'dart:typed_data';

import '../../services/api/errors.dart';
import '../../services/content/content_downloader.dart';
import '../../services/content/upload_queue.dart';
import '../../services/epub/epub_metadata.dart';
import '../../services/files/file_kind.dart';
import '../../services/files/file_source.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/dao/transfers_dao.dart';
import '../../services/local/database.dart';
import '../../services/storage/blob_storage.dart';
import '../../services/sync/author.dart';
import '../../services/sync/delta.dart';
import 'library_repository.dart';

final _log = loggerFor('data/library');

/// The operation a failed reading of the collection reports under.
const String opReadLibrary = 'library/collection: read';

/// The operation an import reports under.
const String opImport = 'library/collection: import';

/// The operation a download reports under.
const String opDownload = 'library/content: download';

/// The operation keeping and releasing report under.
const String opKeep = 'library/content: keep';

/// The operation an edit reports under.
const String opEdit = 'library/collection: edit';

/// The operation a deletion and its undo report under.
const String opDelete = 'library/collection: delete';

/// The operation a change to a grouping reports under.
const String opGrouping = 'library/groupings: write';

/// [value], or `null` where it holds nothing.
///
/// An object with no entries and no object at all are the same claim about a
/// work — there is nothing the format carried — and the column stores `NULL`
/// for both. Normalizing them here is what lets the two sides of a comparison
/// be compared at all.
Map<String, Object?>? _emptyIsCleared(Map<String, Object?> value) =>
    value.isEmpty ? null : value;

/// [value] trimmed, or `null` where the reader left the field empty.
///
/// A form has no way to express *absent* other than an empty field, so an
/// empty one is read as the reader clearing it — which is a claim and not a
/// silence, and is exactly the difference `optional` spells in the contract.
String? _blankIsCleared(String? value) {
  final trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// The reader's collection, read out of drift.
final class LibraryRepositoryImpl implements LibraryRepository {
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
  }) : _mint = mint ?? mintIdentifier,
       _now = now ?? DateTime.now;

  /// The rows.
  final LibraryDao library;

  /// Where a change to a replicable record goes. There is no other way out of
  /// this repository, and C21 is why.
  final OperationAuthor author;

  /// Where the bytes go.
  final BlobStore blobs;

  /// What the node is owed, and what eventually pays it.
  final UploadQueue uploads;

  /// What brings a file the other way.
  final ContentDownloader downloads;

  /// What is owed, and what the reader decided to keep.
  final TransfersDao transfers;

  /// What the store holds and may hold, asked of the platform.
  final Future<StorageBudget> Function(BlobStore blobs) budget;

  /// Whether a book arrives kept.
  ///
  /// True on the five native targets and false in a browser, decided at the
  /// composition root rather than here: a repository that asked the framework
  /// what platform it was on would be a repository that could not be tested as
  /// any other. It is the *default* and never the answer — the answer is the
  /// reader's decision where they have taken one.
  final bool keepsByDefault;

  final String Function() _mint;
  final DateTime Function() _now;

  @override
  Future<Result<Ebook>> importEbook(FileSource file) async {
    try {
      final kind = describeFile(file.name);

      if (kind == null) {
        // Refused before a byte is copied. The node records what it is told
        // the bytes are and never opens them, so a format guessed here is a
        // format nothing downstream can correct.
        throw AppException(
          kind: ErrorKind.invalidArgument,
          message: 'this app cannot tell what ${file.name} is',
          code: codeUnsupportedFormat,
          op: opImport,
        ).withField('format', 'the name carries no extension this app knows');
      }

      // The bytes first, and the record after them. A device interrupted
      // between the two has a file nothing names, which the next import of the
      // same book adopts for free — the store is keyed by the digest. The
      // other order would leave a work whose file this device never had, which
      // reads to a reader as a book that will not open.
      final stored = await blobs.store(file.openRead());

      _log.fine('imported ${file.name} as $stored');

      // Read back out of the store rather than off the source. The source is a
      // stream that cannot be replayed — a browser's file input is consumed —
      // and the store is the one place the bytes are now certain to be.
      final described = await _describe(kind.format, stored);

      final id = _mint();
      final claims = DeltaWriter()
        // What the file said, and the file name where it said nothing. A field
        // the OPF did not carry is not claimed at all, which is the difference
        // between *unknown* and *empty*: the first keeps whatever another
        // device wrote there and the second says there is none.
        ..text(fieldTitle, described?.title ?? titleFromFileName(file.name))
        ..text(fieldFormat, kind.format.wireName)
        ..id(fieldContentHash, stored.contentHash)
        ..integer(fieldSizeBytes, stored.sizeBytes)
        ..instant(fieldImportedAt, _now().toUtc());

      if (described?.author != null) {
        claims.text(fieldAuthor, described!.author);
      }

      if (described?.publisher != null) {
        claims.text(fieldPublisher, described!.publisher);
      }

      if (described?.language != null) {
        claims.text(fieldLanguage, described!.language);
      }

      if (described != null && described.extra.isNotEmpty) {
        claims.object(fieldExtraMetadata, described.extra);
      }

      await author.write(Change.insert(TargetEntity.ebook, id, claims.fields));

      // After the work exists, because the row references it and is deleted
      // with it. A cover saved first would be a row pointing at nothing, and
      // the foreign key would refuse it.
      if (described?.cover case final EpubCover cover) {
        await library.saveCover(
          ebookId: id,
          mediaType: cover.mediaType,
          bytes: cover.bytes,
        );
      }

      // The node is owed the file from here on, and the queue is a table: an
      // import made on a train is a transfer that survives closing the app.
      // It is queued and not sent — C16 refuses an upload for a digest no work
      // of the reader's names, and the work reaches the node with the log, so
      // the first attempt of a fresh import is a *not yet* by construction.
      await uploads.owe(
        contentHash: stored.contentHash,
        mediaType: kind.mediaType,
        sizeBytes: stored.sizeBytes,
      );

      final imported = await library.readEbook(id);

      // The row is read back rather than built here. What a work *is* after a
      // change is the reconciler's answer, and a repository that assembled its
      // own copy would be a second one to keep in step.
      return Result<Ebook>.ok(ebookOfRow(imported!));
    } on Object catch (error, stackTrace) {
      _log.warning('${file.name} could not be imported', error, stackTrace);

      return Result<Ebook>.error(failureFrom(error, op: opImport));
    }
  }

  @override
  Future<Result<EbookContent>> downloadEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null || work.deleted) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opDownload,
        );
      }

      final content = await downloads.download(
        ebookId: ebookId,
        // The digest the *work* names, and not whatever arrives. It is what
        // the transfer is checked against, so that a node sending something
        // else is caught here rather than by a reader opening gibberish.
        expectedHash: work.contentHash,
        cancel: cancel,
        onProgress: onProgress,
      );

      // The file is here now, so a cover can be read out of it — which is the
      // whole reason a cover is derived per device rather than replicated. A
      // work downloaded on a second device gets its own.
      await _keepCoverOf(work);

      return Result<EbookContent>.ok(content);
    } on Object catch (error, stackTrace) {
      _log.warning('the file of $ebookId did not arrive', error, stackTrace);

      return Result<EbookContent>.error(failureFrom(error, op: opDownload));
    }
  }

  @override
  Stream<Result<ContentState>> watchContent(String ebookId) => _guard(
    // It follows the *work* and not the digest, because a work whose row
    // arrives by synchronization before its file is the ordinary case and the
    // screen has to stop saying *not here* the moment the bytes land. The
    // transfer is watched under it, so that a queue draining while the reader
    // is looking at the book is something they see happen.
    library.watchEbook(ebookId).asyncExpand((row) {
      if (row == null) {
        return Stream<ContentState>.value(
          const ContentState(onThisDevice: false, kept: false),
        );
      }

      return Rx.combine(
        transfers.watchTransfer(row.contentHash),
        transfers.watchDecision(row.contentHash),
      ).asyncMap(
        (pair) async => ContentState(
          onThisDevice: await blobs.contains(row.contentHash),
          kept: pair.$2 ?? keepsByDefault,
          owedBytes: pair.$1?.sizeBytes,
          sentBytes: pair.$1?.sentBytes ?? 0,
        ),
      );
    }),
  );

  @override
  Future<Result<void>> keepEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opKeep,
        );
      }

      // The decision first, so that a download interrupted half way through
      // leaves a device that still intends to keep the book — and a later
      // pass finishes it — rather than one that has forgotten it was asked.
      await transfers.decide(
        contentHash: work.contentHash,
        kept: true,
        at: _now(),
      );

      if (!await blobs.contains(work.contentHash)) {
        final result = await downloadEbook(
          ebookId,
          cancel: cancel,
          onProgress: onProgress,
        );

        if (result case Error<EbookContent>(:final error)) {
          return Result<void>.error(error);
        }
      }

      return const Result<void>.ok(null);
    } on Object catch (error) {
      _log.warning('$ebookId could not be kept', error);

      return Result<void>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Future<Result<void>> releaseEbook(String ebookId) async {
    try {
      final work = await library.readEbook(ebookId);

      if (work == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opKeep,
        );
      }

      // Nothing in this app destroys the only copy of a book. A file still in
      // the queue is on this device and nowhere else, and releasing it would
      // be the one gesture here that loses something the reader cannot get
      // back — so it is refused until the node has it.
      if (await transfers.transfer(work.contentHash) != null) {
        throw AppException(
          kind: ErrorKind.failedPrecondition,
          message:
              'the file of $ebookId has not reached the node and is only here',
          code: codeNotYetSent,
          op: opKeep,
        );
      }

      await transfers.decide(
        contentHash: work.contentHash,
        kept: false,
        at: _now(),
      );

      // Two works naming one file are one file. Releasing it releases both,
      // which is not a compromise: they are the same bytes.
      await blobs.remove(work.contentHash);

      _log.fine('released ${work.contentHash}');

      return const Result<void>.ok(null);
    } on Object catch (error) {
      _log.warning('$ebookId could not be released', error);

      return Result<void>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Future<Result<StorageBudget>> storage() async {
    try {
      return Result<StorageBudget>.ok(await budget(blobs));
    } on Object catch (error) {
      _log.warning('the storage budget could not be read', error);

      return Result<StorageBudget>.error(failureFrom(error, op: opKeep));
    }
  }

  @override
  Stream<Result<List<Ebook>>> watchKeptEbooks() => _guard(
    library.watchEbooks().asyncMap((rows) async {
      final held = (await blobs.digests()).toSet();

      return <Ebook>[
        for (final row in rows)
          if (held.contains(row.contentHash)) ebookOfRow(row),
      ]..sort((a, b) => b.importedAt.compareTo(a.importedAt));
    }),
  );

  /// Extracts and keeps the cover of [work], if this device can read one.
  ///
  /// It never throws: the file is on the device either way, and failing a
  /// download over a picture would throw away the thing the reader asked for.
  Future<void> _keepCoverOf(EbookRow work) async {
    if (await library.readCover(work.id) != null) {
      return;
    }

    final format = EbookFormat.parse(work.format);
    final described = format == null
        ? null
        : await _describe(
            format,
            StoredBlob(
              contentHash: work.contentHash,
              sizeBytes: work.sizeBytes ?? 0,
            ),
          );

    if (described?.cover case final EpubCover cover) {
      await library.saveCover(
        ebookId: work.id,
        mediaType: cover.mediaType,
        bytes: cover.bytes,
      );
    }
  }

  @override
  Future<Result<EpubCover?>> cover(String ebookId) async {
    try {
      final row = await library.readCover(ebookId);

      return Result<EpubCover?>.ok(
        row == null
            ? null
            : EpubCover(mediaType: row.mediaType, bytes: row.bytes),
      );
    } on Object catch (error) {
      _log.warning('the cover of $ebookId could not be read', error);

      return Result<EpubCover?>.error(failureFrom(error, op: opReadLibrary));
    }
  }

  /// What the stored file says about itself, or `null` where nothing can.
  ///
  /// Only an EPUB, because it is the only format in the contract whose
  /// metadata this app reads — a PDF's is a different specification and a CBZ
  /// has none — and only under [metadataSizeLimit], because the archive is
  /// held in memory to be read.
  Future<EpubMetadata?> _describe(EbookFormat format, StoredBlob stored) async {
    if (format != EbookFormat.epub || stored.sizeBytes > metadataSizeLimit) {
      return null;
    }

    try {
      final bytes = BytesBuilder(copy: false);

      await for (final chunk in blobs.read(stored.contentHash)) {
        bytes.add(chunk);
      }

      return readEpubMetadata(bytes.takeBytes());
    } on Object catch (error) {
      // The book is already in the library at this point. Failing the import
      // because its cover could not be read would throw away a file the reader
      // has, over a picture.
      _log.fine('${stored.contentHash} could not be described', error);

      return null;
    }
  }

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
        ..text(fieldAuthor, _blankIsCleared(edits.author), current: work.author)
        ..text(
          fieldPublisher,
          _blankIsCleared(edits.publisher),
          current: work.publisher,
        )
        ..text(
          fieldLanguage,
          _blankIsCleared(edits.language),
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
          current: _emptyIsCleared(_metadataOf(work.extraMetadata)),
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
      final id = _mint();
      final claims = DeltaWriter()
        ..text(fieldName, edits.name.trim())
        ..text(fieldKind, edits.kind.wireName)
        ..text(fieldDescription, _blankIsCleared(edits.description))
        ..instant(fieldCreatedAt, _now().toUtc());

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
          _blankIsCleared(edits.description),
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
  Future<Result<void>> deleteEbook(String ebookId) =>
      _tombstone(ebookId, Change.delete(TargetEntity.ebook, ebookId));

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
    library
        .watchCollectionsOf(ebookId)
        .map((rows) => rows.map(collectionOfRow).toList()..sort(_byName)),
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
/// Combining two streams into one that carries the latest of each.
///
/// It is four lines rather than a dependency because it is used once, and
/// because the semantics that matter here are narrow: nothing is emitted until
/// both have spoken, and after that every change on either side is a new pair.
/// A screen fed by a combinator with any other rule would show a file's state
/// and a decision taken about a different moment.
abstract final class Rx {
  /// [first] and [second], as pairs of their latest values.
  static Stream<(A?, B?)> combine<A, B>(Stream<A?> first, Stream<B?> second) {
    late StreamController<(A?, B?)> controller;
    StreamSubscription<A?>? left;
    StreamSubscription<B?>? right;
    A? a;
    B? b;
    var hasA = false;
    var hasB = false;

    void emit() {
      if (hasA && hasB) {
        controller.add((a, b));
      }
    }

    controller = StreamController<(A?, B?)>(
      onListen: () {
        left = first.listen((A? value) {
          a = value;
          hasA = true;
          emit();
        }, onError: controller.addError);
        right = second.listen((B? value) {
          b = value;
          hasB = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await left?.cancel();
        await right?.cancel();
      },
    );

    return controller.stream;
  }
}

extension on EbookRow {
  T let<T>(T Function(EbookRow row) transform) => transform(this);
}

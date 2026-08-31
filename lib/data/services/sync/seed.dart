/// Filling a freshly bound device's replica from the node's read calls.
///
/// This is the one place in the app the read RPCs are used — `ListEbooks`,
/// `ListCollections`, `ListAnnotations` and `ListReadingProgress` — and it runs
/// exactly once per device, before the first pull. After it, the local replica
/// is the truth and the log is how it changes.
///
/// **Why a pull is not enough.** A device bound to a reader with a history
/// could ask `PullOperations` from position zero and replay everything the log
/// holds. Until C21 closes, the log is not everything: a change made through
/// the node's write RPCs writes the record and appends no operation, so a
/// library imported through any other client is invisible to a replay. The
/// seed is what a new device is given instead; the pull that follows it is what
/// keeps it current.
///
/// **What is written is what the node said.** A work, a grouping and a mark all
/// carry their `Revision` on the wire, and a position its `Version`, so those
/// four are seeded with the causal metadata the node holds and reconcile from
/// then on exactly as if they had been pulled. A replayed operation carrying
/// the same version loses the comparison and changes nothing, which is the
/// right answer and not a collision.
///
/// **The filing is the exception, and the contract is why.** There is no
/// `ListEbookCollections` and no `EbookCollection` message: the membership of a
/// work in a grouping is visible only through the filters on the two list
/// calls, and neither carries a revision for it. So a filing is seeded with no
/// causal history at all — the empty clock and the epoch — which makes every
/// operation about it supersede the seeded row. The row is there so that a
/// reader's shelves are not empty on a new device, and it yields to the first
/// thing the log says about it. Its surrogate identifier is minted here, which
/// is what C18 says a replica must do: the pair is what identifies it across
/// the federation, and the identifier is a local handle.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/crdt/revision.dart';
import '../../../domain/crdt/vector_clock.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/operation.dart';
import '../../../domain/models/record_key.dart';
import '../../../utils/identifiers.dart';
import '../../../utils/logging.dart';
import '../api/library_api.dart';
import '../api/reading_api.dart';
import '../local/database.dart';

final _log = loggerFor('data/sync');

/// How many records a page of a seed asks for.
///
/// Zero would let the node choose, which is what a caller with no opinion
/// should send — and this caller has one: it is filling an empty database over
/// what may be a mobile connection, and a page it has to retry costs less when
/// it is small.
const int seedPageSize = 100;

/// What a seed put into the replica.
final class SeedSummary {
  /// The counts, per kind of record.
  const SeedSummary({
    required this.ebooks,
    required this.collections,
    required this.filings,
    required this.annotations,
    required this.positions,
  });

  /// The works seeded.
  final int ebooks;

  /// The groupings seeded.
  final int collections;

  /// The filings of a work under a grouping.
  final int filings;

  /// The marks seeded.
  final int annotations;

  /// The reading positions seeded, across every device the reader has.
  final int positions;

  @override
  String toString() =>
      'SeedSummary($ebooks works, $collections groupings, $filings filings, '
      '$annotations marks, $positions positions)';
}

/// What fills the replica of a device that has just been bound.
///
/// It is a port and not the class alone for the reason `SessionRefresher` is
/// one: the repository that calls it is the repository whose sign-in this
/// stands at the end of, and a test of that sign-in should be able to watch the
/// seed happen without a node's whole library behind it.
abstract interface class ReplicaSeed {
  /// Reads the reader's collection into the replica of [deviceId].
  Future<SeedSummary> seed({required String deviceId});
}

/// Fills the replica of a device that has just been bound.
final class ReplicaSeeder implements ReplicaSeed {
  /// The seeder over [database], reading through [library] and [reading].
  ///
  /// [mint] is what names a filing this device has to invent an identifier for;
  /// it is a parameter so that a test can watch what was minted rather than
  /// guess it.
  ReplicaSeeder({
    required this.database,
    required this.library,
    required this.reading,
    String Function()? mint,
  }) : _mint = mint ?? mintIdentifier;

  /// The replica being filled.
  final AtrilDatabase database;

  /// The node's `LibraryService`, read from and never written to.
  final LibraryApi library;

  /// The node's `ReadingService`, likewise.
  final ReadingApi reading;

  final String Function() _mint;

  /// Reads the reader's collection into the replica.
  ///
  /// [deviceId] is this device's identifier, and it is the author recorded
  /// against a seeded filing — the one record here with no author of its own to
  /// carry.
  ///
  /// It is not a transaction. A seed is a great many rows over a network that
  /// may be a phone's, and one transaction spanning every call would hold a
  /// write lock for as long as the slowest of them; what makes it safe to
  /// interrupt is that every write is an upsert keyed by an identifier the node
  /// chose, so a second run finishes what the first started.
  @override
  Future<SeedSummary> seed({required String deviceId}) async {
    final works = await _ebooks();
    final groupings = await _collections();
    final filings = await _filings(groupings, deviceId: deviceId);

    var annotations = 0;
    var positions = 0;

    for (final work in works) {
      annotations += await _annotations(work);
      positions += await _positions(work, deviceId: deviceId);
    }

    final summary = SeedSummary(
      ebooks: works.length,
      collections: groupings.length,
      filings: filings,
      annotations: annotations,
      positions: positions,
    );

    _log.info('the replica was seeded: $summary');

    return summary;
  }

  /// Every work, page by page.
  Future<List<String>> _ebooks() async {
    final seeded = <String>[];
    var token = '';

    do {
      final page = await library.listEbooks(
        pageSize: seedPageSize,
        pageToken: token,
      );

      for (final ebook in page.ebooks) {
        // A work whose format this build cannot name is one the schema cannot
        // hold — `oneOf('format', ebookFormats)` is the same check the
        // reconciler runs into when it rejects the operation — so it is
        // skipped, loudly, rather than written as something it is not. It is
        // what a node running a later version of the contract legitimately
        // sends, and the honest answer is a line in the log rather than a
        // library row claiming the file is an EPUB.
        if (ebook.format == null) {
          _log.warning(
            'the work ${ebook.id} is in a format this build cannot name',
          );

          continue;
        }

        await _writeEbook(ebook);
        seeded.add(ebook.id.toLowerCase());
      }

      token = page.nextPageToken;
    } while (token.isNotEmpty);

    return seeded;
  }

  Future<void> _writeEbook(Ebook ebook) async {
    final id = ebook.id.toLowerCase();

    await database
        .into(database.ebooks)
        .insertOnConflictUpdate(
          EbooksCompanion.insert(
            id: id,
            title: ebook.title,
            format: ebook.format!.wireName,
            contentHash: ebook.contentHash,
            author: Value<String?>(ebook.author),
            publisher: Value<String?>(ebook.publisher),
            language: Value<String?>(ebook.language),
            sizeBytes: Value<int?>(ebook.sizeBytes),
            extraMetadata: Value<String?>(
              ebook.extraMetadata.isEmpty
                  ? null
                  : jsonEncode(ebook.extraMetadata),
            ),
            importedAt: ebook.importedAt,
            vectorClock: ebook.revision.vectorClock,
            updatedAt: ebook.revision.updatedAt,
            deviceId: ebook.revision.deviceId,
            deleted: Value<bool>(ebook.revision.deleted),
          ),
        );

    await _remember(
      RecordKey.record(TargetEntity.ebook, id),
      id,
      ebook.revision.vectorClock,
    );
  }

  /// Every grouping. Not paginated, as the contract says: a reader defines
  /// shelves by hand and there are as many of them as they had patience for.
  Future<List<String>> _collections() async {
    final seeded = <String>[];

    for (final collection in await library.listCollections()) {
      final id = collection.id.toLowerCase();

      // As with a work's format: a grouping of a kind this build cannot name
      // is one the schema refuses, and skipping it is what the reconciler
      // does with the operation that would have created it.
      if (collection.kind == null) {
        _log.warning('the grouping $id is of a kind this build cannot name');

        continue;
      }

      await database
          .into(database.collections)
          .insertOnConflictUpdate(
            CollectionsCompanion.insert(
              id: id,
              name: collection.name,
              kind: Value<String>(collection.kind!.wireName),
              description: Value<String?>(collection.description),
              createdAt: collection.createdAt,
              vectorClock: collection.revision.vectorClock,
              updatedAt: collection.revision.updatedAt,
              deviceId: collection.revision.deviceId,
              deleted: Value<bool>(collection.revision.deleted),
            ),
          );

      await _remember(
        RecordKey.record(TargetEntity.collection, id),
        id,
        collection.revision.vectorClock,
      );

      seeded.add(id);
    }

    return seeded;
  }

  /// Which works are filed under each grouping.
  ///
  /// One call per grouping and not one per work, because a reader has fewer
  /// shelves than books — and because `ListEbooks` narrowed to a grouping is
  /// the only window the contract offers onto a membership.
  Future<int> _filings(
    List<String> collections, {
    required String deviceId,
  }) async {
    var filed = 0;

    for (final collection in collections) {
      var token = '';

      do {
        final page = await library.listEbooks(
          pageSize: seedPageSize,
          pageToken: token,
          collectionId: collection,
        );

        for (final ebook in page.ebooks) {
          await _writeFiling(
            ebookId: ebook.id.toLowerCase(),
            collectionId: collection,
            deviceId: deviceId,
          );
          filed++;
        }

        token = page.nextPageToken;
      } while (token.isNotEmpty);
    }

    return filed;
  }

  Future<void> _writeFiling({
    required String ebookId,
    required String collectionId,
    required String deviceId,
  }) async {
    final key = RecordKey.filing(ebookId: ebookId, collectionId: collectionId);
    final id = await database.recordsDao.identifierFor(key, mint: _mint);

    await database
        .into(database.ebookCollections)
        .insertOnConflictUpdate(
          EbookCollectionsCompanion.insert(
            id: id,
            ebookId: ebookId,
            collectionId: collectionId,
            // No causal history, because the contract publishes none for a
            // filing: the first operation about it supersedes this row, which
            // is what makes seeding one safe.
            vectorClock: VectorClock.empty,
            updatedAt: Revision.zero.updatedAt,
            deviceId: deviceId,
          ),
        );

    await _remember(key, id, VectorClock.empty);
  }

  /// Everything written in one work.
  Future<int> _annotations(String ebookId) async {
    var seeded = 0;
    var token = '';

    do {
      final page = await reading.listAnnotations(
        ebookId: ebookId,
        pageSize: seedPageSize,
        pageToken: token,
      );

      for (final annotation in page.annotations) {
        if (annotation.kind == null) {
          _log.warning(
            'the mark ${annotation.id} is of a kind this build cannot name',
          );

          continue;
        }

        await _writeAnnotation(annotation);
        seeded++;
      }

      token = page.nextPageToken;
    } while (token.isNotEmpty);

    return seeded;
  }

  Future<void> _writeAnnotation(Annotation annotation) async {
    final id = annotation.id.toLowerCase();

    await database
        .into(database.annotations)
        .insertOnConflictUpdate(
          AnnotationsCompanion.insert(
            id: id,
            ebookId: annotation.ebookId.toLowerCase(),
            kind: annotation.kind!.wireName,
            locator: annotation.locator,
            content: Value<String?>(annotation.text),
            vectorClock: annotation.revision.vectorClock,
            updatedAt: annotation.revision.updatedAt,
            deviceId: annotation.revision.deviceId,
            deleted: Value<bool>(annotation.revision.deleted),
          ),
        );

    await _remember(
      RecordKey.record(TargetEntity.annotation, id),
      id,
      annotation.revision.vectorClock,
    );
  }

  /// Every device's position in one work.
  ///
  /// Every device's, and not this one's: a reader who opens a book on a new
  /// phone should be offered where they stopped on the tablet, and deciding
  /// which position to show is a decision the reader screen makes with all of
  /// them in front of it.
  Future<int> _positions(String ebookId, {required String deviceId}) async {
    var seeded = 0;

    for (final progress in await reading.listReadingProgress(ebookId)) {
      final device = progress.deviceId.toLowerCase();
      final work = progress.ebookId.toLowerCase();
      final key = RecordKey.position(ebookId: work);
      final existing =
          await (database.select(database.progress)..where(
                (row) => row.ebookId.equals(work) & row.deviceId.equals(device),
              ))
              .getSingleOrNull();
      final id = existing?.id ?? _mint();

      await database
          .into(database.progress)
          .insertOnConflictUpdate(
            ProgressCompanion.insert(
              id: id,
              ebookId: work,
              deviceId: device,
              locator: progress.locator,
              percent: Value<double?>(progress.percent),
              vectorClock: progress.version.vectorClock,
              updatedAt: progress.version.updatedAt,
            ),
          );

      // Only this device's own position is causal state it will ever stamp a
      // change on top of: a position has exactly one writer (C05), and
      // `RecordKey.position` names no device precisely because the only one it
      // could name is this one. Another device's row is data to show and never
      // a version to write against.
      if (device == deviceId.toLowerCase()) {
        await _remember(key, id, progress.version.vectorClock);
      }

      seeded++;
    }

    return seeded;
  }

  Future<void> _remember(RecordKey key, String id, VectorClock clock) =>
      database.recordsDao.remember(key, recordId: id, clock: clock);
}

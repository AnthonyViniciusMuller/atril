/// The reader's collection, as every screen above this line sees it.
///
/// This is the repository the architecture guide's rule reads most cleanly
/// against, and it is worth saying why out loud. **It answers from the local
/// replica and nothing else.** There is no network path through this file, no
/// fallback to `ListEbooks`, and nothing here to be told that the node is
/// unreachable — a library that needed a node to list itself would be a
/// library that is empty on a train, which is the one thing UC01 cannot be.
/// The seed of a freshly bound device is the single place the read RPCs are
/// called, it runs once, and after it the replica is the truth.
///
/// It follows that a screen never shows a spinner while something saves. A
/// change is authored into this database and pushed later, so what a view
/// waits for is a row appearing in a stream it is already watching.
///
/// **The answers are streams of [Result].** A repository method that can fail
/// returns a `Result` in this app, and a stream that failed by ending would be
/// an exception crossing a layer boundary with a `Stream` around it. A query
/// that cannot be answered is therefore an error *in* the stream, which is
/// also the only shape a screen can render: a list that stops arriving looks
/// exactly like an empty collection.
library;

import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../utils/result.dart';
import '../../../utils/cancellation.dart';
import '../../services/content/content_downloader.dart';
import '../../services/storage/blob_storage.dart';
import '../../services/epub/epub_metadata.dart';
import '../../services/files/file_source.dart';

/// The stable code of a file whose name this app cannot place.
const String codeUnsupportedFormat = 'unsupported_format';

/// The stable code of a file the node has not received yet.
///
/// It is what refuses to release the last copy of a book. A work whose bytes
/// are still queued exists on this device and nowhere else, and a *keep on
/// this device* control that could delete it would be the one gesture in this
/// app that destroys something.
const String codeNotYetSent = 'content_not_yet_sent';

/// What a reader changed about a work (RF05).
///
/// Every field is present, because the form that fills this in knows them all
/// — and *what changed* is worked out against the record rather than tracked
/// by the screen. That is not a convenience: reconciliation is per record and
/// not per field (C17), so a delta restating a title the reader never touched
/// carries this device's claim to it, and the next merge against a device that
/// *did* change it is settled by a tie-break rather than by what anybody meant.
/// A change that claims only what changed cannot lose an edit it did not make.
///
/// A `null` is a field the reader **cleared**, which is a claim and not a
/// silence: a work whose author is unknown and one whose author is the empty
/// string are different things, and the contract spells the difference with
/// `optional`.
///
/// The format, the digest and the length are not here. They are fixed at
/// import and the reconciler refuses to move them, because a row that
/// described a file it is not would be a book that will not open.
final class EbookEdits {
  /// The work as the reader left it.
  const EbookEdits({
    required this.title,
    this.author,
    this.publisher,
    this.language,
    this.extraMetadata = const <String, Object?>{},
  });

  /// What the work is called. A work cannot be without one.
  final String title;

  /// Its author, or `null` where the reader cleared it.
  final String? author;

  /// Its publisher, or `null` where the reader cleared it.
  final String? publisher;

  /// Its language, or `null` where the reader cleared it.
  final String? language;

  /// The metadata the format carried and the contract does not name.
  ///
  /// An object and never a scalar, because the column it lands in is `jsonb`
  /// and constrained to one — on the node and on this device. An empty map is
  /// a reader who removed every entry, which clears the field.
  final Map<String, Object?> extraMetadata;

  @override
  String toString() => 'EbookEdits($title)';
}

/// The reader's collection.
abstract interface class LibraryRepository {
  /// RF05. Records what the reader changed about one work.
  ///
  /// It claims exactly the fields that differ from the record, and nothing
  /// else. The change is authored as an operation and applied by the
  /// reconciler like any other, so a device with no network edits a book and
  /// every replica hears about it when the log is pushed — which is the whole
  /// of C21 and the reason `UpdateEbook` is never called.
  ///
  /// An edit that changes nothing is not an operation at all: authoring one
  /// would tick a clock and stamp an instant to tell every replica that
  /// nothing happened, and leave the record reflecting this device for a write
  /// it did not make.
  Future<Result<void>> editEbook(String ebookId, EbookEdits edits);

  /// UC02. Takes [file] into the collection.
  ///
  /// The bytes are copied into the blob store under the digest computed while
  /// they were copied, and the work is authored as an operation — in that
  /// order, and both of them locally. Nothing here reaches a node: the record
  /// travels when the log is pushed and the file travels when the transfer
  /// runs, so importing a book on an aeroplane is the ordinary case and not a
  /// degraded one.
  ///
  /// The two are one import and two records. The digest identifies the bytes
  /// across the whole federation, so the same file imported on two devices
  /// converges on one stored object and the two works that name it are two
  /// works — which is what a reader who imported the same book twice actually
  /// has.
  ///
  /// It fails with [codeUnsupportedFormat] for a name this app cannot place.
  Future<Result<Ebook>> importEbook(FileSource file);

  /// The works [query] asks for, as they change.
  ///
  /// Sorted here rather than in SQL, because sqlite's collations are ASCII and
  /// this app's language is not. `utils/collation.dart` carries the reasoning
  /// and the fold.
  Stream<Result<List<Ebook>>> watchEbooks([LibraryQuery query]);

  /// One work, as it changes, or `null` once this device no longer holds it.
  ///
  /// A work another device has just deleted becomes `null` here rather than an
  /// error: the tombstone arrived, the reconciler applied it, and a screen
  /// showing that work now has nothing to show. That is a state and not a
  /// failure.
  Stream<Result<Ebook?>> watchEbook(String id);

  /// One work, once, tombstone and all.
  ///
  /// It is what a change is prepared against — the title an edit compares
  /// itself with, the tombstone an undo lifts — and it is the only reader in
  /// this interface that sees a deleted record.
  Future<Result<Ebook?>> ebook(String id);

  /// The reader's groupings, as they change, in the order a shelf is read in.
  Stream<Result<List<Collection>>> watchCollections();

  /// How many works are filed under each grouping, keyed by its identifier.
  ///
  /// A grouping nothing is filed under is absent rather than zero, which is
  /// what a caller reading it with `?? 0` expects and what one query over two
  /// tables can answer.
  Stream<Result<Map<String, int>>> watchFilingCounts();

  /// The groupings one work is filed under, as they change.
  Stream<Result<List<Collection>>> watchCollectionsOf(String ebookId);

  /// Brings the file of one work onto this device.
  ///
  /// It is the other half of what makes a book readable offline, and it is
  /// separate from the record on purpose: a device holding the row and not the
  /// bytes is the ordinary state of a book that has not been downloaded, and
  /// on the web it is the ordinary state of every book the reader has not
  /// asked to keep.
  ///
  /// A node that replicates this reader without their files answers that it
  /// does not hold them, which is a legitimate state (D02) and reaches the
  /// caller as [codeContentNotFound] rather than as something to retry.
  ///
  /// It is **not resumable**, and that is the contract's shape rather than a
  /// shortcut: `DownloadEbookContentRequest` carries an e-book identifier and
  /// no offset, so an interrupted transfer starts again. Nothing partial is
  /// kept, so starting again is all it costs.
  Future<Result<EbookContent>> downloadEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  });

  /// Where the bytes of one work are, as that changes.
  ///
  /// One stream and not three, because the states are not independent and the
  /// sentence a screen shows depends on the combination: a book can be here
  /// and still owed to the node — which every freshly imported one is — and a
  /// book that is neither here nor owed is one whose file is on the node and
  /// has not been fetched.
  ///
  /// Whether it is *kept* is one mechanism with two defaults. A book on a
  /// native install is kept unless the reader released it; in a browser
  /// nothing is kept until they ask, because the origin is lent a share of a
  /// disk the browser may take back. What differs by platform is the honest
  /// answer, not the question.
  Stream<Result<ContentState>> watchContent(String ebookId);

  /// Keeps the file of one work on this device, downloading it if it is not
  /// here.
  Future<Result<void>> keepEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  });

  /// Stops keeping the file of one work, and removes it.
  ///
  /// It refuses with [codeNotYetSent] while the node has not received the
  /// file. Nothing in this app evicts silently and nothing destroys the only
  /// copy of a book: a work whose bytes are still queued exists here and
  /// nowhere else.
  ///
  /// Two works naming one file are one file, and releasing it releases both.
  /// That is not a compromise — they *are* the same bytes, and there is
  /// nothing to keep separately.
  Future<Result<void>> releaseEbook(String ebookId);

  /// What the store holds, and what it may hold.
  ///
  /// The quota is the browser's own answer and is absent on the five native
  /// targets, where nothing portable can say — which is why the web build is
  /// the one that spends a budget and a native install simply keeps
  /// everything.
  Future<Result<StorageBudget>> storage();

  /// The works whose files this device is holding, newest decision first.
  Stream<Result<List<Ebook>>> watchKeptEbooks();

  /// The cover this device extracted for one work, or `null`.
  ///
  /// It is a `Future` and not a stream, and the difference is what a cover is:
  /// it is derived from a file this device holds and changes exactly when that
  /// file arrives, so a shelf of two hundred books would otherwise open two
  /// hundred queries that wake on every import. A tile asks once for the work
  /// it is showing.
  ///
  /// `null` is the ordinary answer, not a failure. A work whose file is on the
  /// node and not here has no cover to extract, and neither has one in a
  /// format this app does not open.
  Future<Result<EpubCover?>> cover(String ebookId);
}

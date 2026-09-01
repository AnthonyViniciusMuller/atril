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
import '../../services/files/file_source.dart';

/// The stable code of a file whose name this app cannot place.
const String codeUnsupportedFormat = 'unsupported_format';

/// The reader's collection.
abstract interface class LibraryRepository {
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
}

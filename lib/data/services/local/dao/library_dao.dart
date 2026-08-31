/// Reading the reader's collection out of the replica.
///
/// Everything here reads and nothing writes. The replicated tables have two
/// writers — the reconciler and the seed of a freshly bound device — and a
/// third one that answered a screen would be a change that reached no other
/// replica, which is the whole of C21. A screen that saves something reaches
/// the operation author, and the author reaches the reconciler.
///
/// Every stream excludes the tombstoned rows, and that is a decision about
/// *this* layer rather than about the schema. A tombstone is a record the
/// federation still has to carry — it is what keeps a deletion from being
/// undone by the next replica that had not heard about it — and it is not a
/// book. The readers that want them are the ones a write is prepared against:
/// an edit compares itself with the title the row holds, and an undo lifts a
/// tombstone it has to be able to see.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/library.dart';

part 'library_dao.g.dart';

/// The reader's collection, as this device holds it.
@DriftAccessor(tables: <Type>[Ebooks, Collections, EbookCollections])
class LibraryDao extends DatabaseAccessor<AtrilDatabase> with _$LibraryDaoMixin {
  /// The accessor over [database].
  LibraryDao(super.database);

  /// The works the reader holds, as they change.
  ///
  /// [collectionId] narrows the answer to what is filed under one grouping,
  /// which is a join and therefore the one part of a query this file does in
  /// SQL. The ordering is not: sqlite's collations are ASCII and this app's
  /// language is not, so `utils/collation.dart` is what puts *Sertão* between
  /// *Sermão* and *Serviço* — on all six targets, including the one where the
  /// database is a WebAssembly build and a custom collation could not be
  /// registered at all.
  ///
  /// A filing that has been tombstoned does not count as a filing. The row
  /// survives because the federation needs it; the shelf it names does not
  /// show the work any more.
  Stream<List<EbookRow>> watchEbooks({String? collectionId}) =>
      collectionId == null
      ? _live.watch()
      : _filedUnder(collectionId).watch().map(_worksOf);

  /// The works the reader holds, once.
  Future<List<EbookRow>> readEbooks({String? collectionId}) async =>
      collectionId == null
      ? _live.get()
      : _worksOf(await _filedUnder(collectionId).get());

  /// One work, as it changes, or `null` while this device does not hold it.
  ///
  /// The tombstone is excluded here as it is from every stream: a reader
  /// looking at a work another device has just deleted is looking at a screen
  /// about nothing, and that is what the detail screen has to be told so that
  /// it can say so.
  Stream<EbookRow?> watchEbook(String id) =>
      (select(ebooks)..where((row) => row.id.equals(id) & row.deleted.not()))
          .watchSingleOrNull();

  /// One work, once, tombstone and all.
  ///
  /// It is the reading a write is prepared against, and the only reader here
  /// that sees a deleted row: a change authored against a record this device
  /// believed it did not hold would be an insert of something that already
  /// exists everywhere else.
  Future<EbookRow?> readEbook(String id) =>
      (select(ebooks)..where((row) => row.id.equals(id))).getSingleOrNull();

  /// The reader's groupings, as they change.
  ///
  /// Not narrowed and not paginated: a reader defines shelves by hand and
  /// there are as many of them as they had patience for, which is the same
  /// reason `ListCollections` on the wire is not paginated either.
  Stream<List<CollectionRow>> watchCollections() =>
      (select(collections)..where((row) => row.deleted.not())).watch();

  /// The reader's groupings, once.
  Future<List<CollectionRow>> readCollections() =>
      (select(collections)..where((row) => row.deleted.not())).get();

  /// One grouping, once, tombstone and all, for the reason [readEbook] reads
  /// one.
  Future<CollectionRow?> readCollection(String id) =>
      (select(collections)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  /// The groupings one work is filed under, as they change.
  Stream<List<CollectionRow>> watchCollectionsOf(String ebookId) {
    final query =
        select(collections).join(<Join<HasResultSet, dynamic>>[
            innerJoin(
              ebookCollections,
              ebookCollections.collectionId.equalsExp(collections.id) &
                  ebookCollections.ebookId.equals(ebookId) &
                  ebookCollections.deleted.not(),
            ),
          ])
          ..where(collections.deleted.not());

    return query.watch().map(
      (rows) => <CollectionRow>[
        for (final row in rows) row.readTable(collections),
      ],
    );
  }

  /// How many works are filed under each grouping, as it changes.
  ///
  /// One query and not one per shelf: a screen listing twenty groupings beside
  /// their counts would otherwise open twenty streams over the same two
  /// tables, and every one of them would wake on every import.
  Stream<Map<String, int>> watchFilingCounts() {
    final counted = ebookCollections.ebookId.count();
    final query =
        selectOnly(ebookCollections).join(<Join<HasResultSet, dynamic>>[
            innerJoin(
              ebooks,
              ebooks.id.equalsExp(ebookCollections.ebookId) &
                  ebooks.deleted.not(),
            ),
          ])
          ..addColumns(<Expression<Object>>[
            ebookCollections.collectionId,
            counted,
          ])
          ..where(ebookCollections.deleted.not())
          ..groupBy(<Expression<Object>>[ebookCollections.collectionId]);

    return query.watch().map(
      (rows) => <String, int>{
        for (final row in rows)
          row.read(ebookCollections.collectionId)!: row.read(counted) ?? 0,
      },
    );
  }

  /// The filing of one work under one grouping, tombstone and all.
  ///
  /// The pair is the record (C06, C18), so this is how a screen asks whether a
  /// work is on a shelf and how the next change learns what it is changing.
  Future<EbookCollectionRow?> readFiling({
    required String ebookId,
    required String collectionId,
  }) =>
      (select(ebookCollections)..where(
            (row) =>
                row.ebookId.equals(ebookId) &
                row.collectionId.equals(collectionId),
          ))
          .getSingleOrNull();

  /// Whether any work of the reader's names [contentHash], tombstone and all.
  ///
  /// It is this device's copy of the question the node asks before it accepts
  /// an upload (C16), asked here for the same reason: the bytes are addressed
  /// by their digest and shared between every work that names them, so what
  /// makes them the reader's is a row that says so.
  Future<bool> holdsContent(String contentHash) async =>
      await (select(ebooks)
            ..where((row) => row.contentHash.equals(contentHash))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  /// The works naming [contentHash].
  ///
  /// A digest is shared, so a finished transfer makes every work that names it
  /// readable at once — which is what a screen showing *downloaded* has to ask
  /// about rather than assuming one file belongs to one book.
  Future<List<EbookRow>> readWorksNaming(String contentHash) =>
      (select(ebooks)..where(
            (row) => row.contentHash.equals(contentHash) & row.deleted.not(),
          ))
          .get();

  SimpleSelectStatement<$EbooksTable, EbookRow> get _live =>
      select(ebooks)..where((row) => row.deleted.not());

  JoinedSelectStatement<HasResultSet, dynamic> _filedUnder(
    String collectionId,
  ) =>
      select(ebooks).join(<Join<HasResultSet, dynamic>>[
          innerJoin(
            ebookCollections,
            ebookCollections.ebookId.equalsExp(ebooks.id) &
                ebookCollections.collectionId.equals(collectionId) &
                ebookCollections.deleted.not(),
          ),
        ])
        ..where(ebooks.deleted.not());

  List<EbookRow> _worksOf(List<TypedResult> rows) =>
      <EbookRow>[for (final row in rows) row.readTable(ebooks)];
}

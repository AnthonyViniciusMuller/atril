/// What the reader has marked, read out of the replica.
///
/// It is its own accessor beside `LibraryDao` and `ReadingDao` for the reason
/// those two are apart: the library is the collection, reading is where the
/// reader got to, and this is what they wrote down. Three questions, three
/// lifetimes, three sets of screens.
///
/// **Everything here reads and nothing writes.** The replicated tables have two
/// writers — the reconciler and the seed of a freshly bound device — and a mark
/// saved by a third would be a mark that reached no other replica, which is the
/// whole of C21. A screen that highlights a passage reaches the operation
/// author, and the author reaches the reconciler.
///
/// **The order is when the mark was made, and never where it is in the book.**
/// Reading order is what a reader would expect of a list of highlights, and it
/// is unreachable from here: two CFIs are compared by parsing them, and a CFI
/// parser written in Dart is the second implementation `architecture.md`
/// forbids outright — the one whose disagreements arrive as a highlight on the
/// wrong paragraph. So the marks come back most recent first, which is an
/// integer comparison that means the same thing in every language and on every
/// target.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/library.dart';
import '../tables/reading.dart';

part 'annotations_dao.g.dart';

/// A mark and the work it was made in.
///
/// A record and not two parallel lists, for the reason a reading place is one:
/// a mark with no work to name is nothing a screen across the whole library
/// can render.
typedef MarkRow = ({AnnotationRow mark, EbookRow work});

/// What the reader has marked.
@DriftAccessor(tables: <Type>[Annotations, Ebooks])
class AnnotationsDao extends DatabaseAccessor<AtrilDatabase>
    with _$AnnotationsDaoMixin {
  /// The accessor over [database].
  AnnotationsDao(super.database);

  /// The marks in one work, most recent first.
  ///
  /// It is what the reader's screen draws from, so a tombstoned mark is left
  /// out: a highlight another device removed is a highlight that is not on the
  /// page any more.
  Stream<List<AnnotationRow>> watchMarksIn(String ebookId) =>
      (select(annotations)
            ..where(
              ($AnnotationsTable row) =>
                  row.ebookId.equals(ebookId) & row.deleted.not(),
            )
            ..orderBy(<OrderingTerm Function($AnnotationsTable)>[
              ($AnnotationsTable row) => OrderingTerm.desc(row.updatedAt),
            ]))
          .watch();

  /// One mark, once, tombstone and all.
  ///
  /// It is the reading a write is prepared against, and the only reader here
  /// that sees a removed mark: an undo lifts a tombstone it has to be able to
  /// find.
  Future<AnnotationRow?> readMark(String id) => (select(
    annotations,
  )..where(($AnnotationsTable row) => row.id.equals(id))).getSingleOrNull();

  /// Every mark this reader holds, with the work each is in, most recent
  /// first.
  ///
  /// [ebookId] narrows it to one book and [kind] to one sort of mark. Both are
  /// equalities on a column and therefore SQL's to do; nothing here searches,
  /// because a search is matched on a folded key and that is the repository's
  /// job for the reason the shelf's ordering is.
  ///
  /// A mark in a tombstoned work is left out. A reader who deleted a book has
  /// said they are not reading it, and its highlights are not a separate
  /// opinion.
  Stream<List<MarkRow>> watchMarks({
    String? ebookId,
    String? kind,
    int? limit,
  }) => _marks(ebookId: ebookId, kind: kind, limit: limit).watch().map(_rowsOf);

  /// Every mark this reader holds, once.
  Future<List<MarkRow>> readMarks({
    String? ebookId,
    String? kind,
    int? limit,
  }) async =>
      _rowsOf(await _marks(ebookId: ebookId, kind: kind, limit: limit).get());

  JoinedSelectStatement<HasResultSet, dynamic> _marks({
    String? ebookId,
    String? kind,
    int? limit,
  }) {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        select(annotations).join(<Join<HasResultSet, dynamic>>[
          innerJoin(
            ebooks,
            ebooks.id.equalsExp(annotations.ebookId) & ebooks.deleted.not(),
          ),
        ])..where(annotations.deleted.not());

    if (ebookId != null) {
      query.where(annotations.ebookId.equals(ebookId));
    }

    if (kind != null) {
      query.where(annotations.kind.equals(kind));
    }

    query.orderBy(<OrderingTerm>[OrderingTerm.desc(annotations.updatedAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query;
  }

  List<MarkRow> _rowsOf(List<TypedResult> rows) => <MarkRow>[
    for (final TypedResult row in rows)
      (mark: row.readTable(annotations), work: row.readTable(ebooks)),
  ];
}

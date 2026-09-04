/// Where the reader stopped, in every book and on every device.
///
/// It is its own accessor and not a method on `LibraryDao`, for the reason the
/// repositories above them are two: the library is the collection, and this is
/// where reading got to. They join, because a position with no work to show is
/// nothing a screen can render, and the join is the whole of what this file
/// does in SQL.
///
/// **Every device's row is kept, and which of them is answered depends on the
/// question.** Where a reader's devices are in *one* book is a question with
/// one answer per device, and RN01 asks for all of them: [watchPlacesIn] is
/// that question and collapses nothing. *What is there to come back to* is a
/// question about books, and one novel three appliances are in the middle of is
/// one thing to come back to: [watchPlaces] answers with the place each work
/// was last left at, whichever device left it there.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/library.dart';
import '../tables/reading.dart';

part 'reading_dao.g.dart';

/// One device's place in one work.
///
/// A record and not two parallel lists, because a position and the work it is
/// in are read together and shown together: a screen handed them separately
/// would be a screen that can be given a position for a book it does not have.
typedef ReadingPlaceRow = ({ProgressRow position, EbookRow work});

/// Where reading got to.
@DriftAccessor(tables: <Type>[Progress, Ebooks])
class ReadingDao extends DatabaseAccessor<AtrilDatabase>
    with _$ReadingDaoMixin {
  /// The accessor over [database].
  ReadingDao(super.database);

  /// The place each work was last left at, most recent first — one row per
  /// work and not one per device.
  ///
  /// **The collapsing is here and not above**, because [limit] counts books: a
  /// reader whose phone, tablet and laptop are all in one novel is one thing to
  /// come back to, and a limit spent on three rows of it would push two other
  /// books off a strip that has room for them. Every device's row is still
  /// kept, and [watchPlacesIn] is what answers with them.
  ///
  /// **Which row survives is SQLite's own rule and not an accident.** A bare
  /// column in a query that aggregates with `max` takes its value from the
  /// input row the maximum came from, which is stated in SQLite's
  /// documentation and has held since 3.7.11. So grouping by the work and
  /// asking for the newest instant answers with *that* device's locator,
  /// percentage and identifier, rather than with one row's instant beside
  /// another's place. The test beside this file is what would notice the day
  /// it stopped being true.
  ///
  /// Ordered in SQL and not in Dart, unlike the shelf: what orders these is an
  /// instant on the hybrid clock, and an integer sorts the same way in every
  /// language. The shelf is ordered by a title, which is why it is not.
  ///
  /// A tombstoned work is left out. A reader who deleted a book has said they
  /// are not reading it, and a *continue reading* row for it would be the
  /// deletion not having happened.
  Stream<List<ReadingPlaceRow>> watchPlaces({int limit = 20}) {
    // The column is the hybrid clock's instant in microseconds, so the
    // aggregate is over an integer and not over a `DateTime`: the converter is
    // a Dart-side reading of a column sqlite compares as the number it is.
    final Expression<int> latest = progress.updatedAt.max();

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        select(progress).join(<Join<HasResultSet, dynamic>>[
            innerJoin(
              ebooks,
              ebooks.id.equalsExp(progress.ebookId) & ebooks.deleted.not(),
            ),
          ])
          ..addColumns(<Expression<Object>>[latest])
          ..groupBy(<Expression<Object>>[progress.ebookId])
          ..orderBy(<OrderingTerm>[OrderingTerm.desc(latest)])
          ..limit(limit);

    return query.watch().map(
      (List<TypedResult> rows) => <ReadingPlaceRow>[
        for (final TypedResult row in rows)
          (position: row.readTable(progress), work: row.readTable(ebooks)),
      ],
    );
  }

  /// Where this reader's devices are in one work, most recent first.
  Stream<List<ProgressRow>> watchPlacesIn(String ebookId) =>
      (select(progress)
            ..where(($ProgressTable row) => row.ebookId.equals(ebookId))
            ..orderBy(<OrderingTerm Function($ProgressTable)>[
              ($ProgressTable row) => OrderingTerm.desc(row.updatedAt),
            ]))
          .watch();

  /// Where one device is in one work, once.
  Future<ProgressRow?> placeOf({
    required String ebookId,
    required String deviceId,
  }) =>
      (select(progress)..where(
            ($ProgressTable row) =>
                row.ebookId.equals(ebookId) & row.deviceId.equals(deviceId),
          ))
          .getSingleOrNull();
}

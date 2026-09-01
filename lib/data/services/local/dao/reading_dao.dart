/// Where the reader stopped, in every book and on every device.
///
/// It is its own accessor and not a method on `LibraryDao`, for the reason the
/// repositories above them are two: the library is the collection, and this is
/// where reading got to. They join, because a position with no work to show is
/// nothing a screen can render, and the join is the whole of what this file
/// does in SQL.
///
/// **Every device's row is kept and every device's row is answered.** Which
/// position to show a reader — the furthest, the most recent, or a prompt
/// asking which to resume from — is this application's decision to make, and
/// it needs them all to make it. RN01 asks for exactly that, and it is why the
/// rows are not collapsed on the way out of here.
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

  /// Every position this reader's devices have written, most recent first.
  ///
  /// Ordered in SQL and not in Dart, unlike the shelf: what orders these is an
  /// instant on the hybrid clock, and an integer sorts the same way in every
  /// language. The shelf is ordered by a title, which is why it is not.
  ///
  /// A tombstoned work is left out. A reader who deleted a book has said they
  /// are not reading it, and a *continue reading* row for it would be the
  /// deletion not having happened.
  Stream<List<ReadingPlaceRow>> watchPlaces({int limit = 20}) {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        select(progress).join(<Join<HasResultSet, dynamic>>[
            innerJoin(
              ebooks,
              ebooks.id.equalsExp(progress.ebookId) & ebooks.deleted.not(),
            ),
          ])
          ..orderBy(<OrderingTerm>[OrderingTerm.desc(progress.updatedAt)])
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

/// What a screen may assume of a repository, written once.
///
/// **A fake is only worth having if something says it agrees with the thing.**
/// Eleven fakes stand in for the repositories in every widget test in this
/// suite, and each of them reimplements a little of what the real one does —
/// which query narrows what, which list comes back in which order, what a
/// tombstone does to both. Nothing said the two agreed, so a fake that answered
/// every query with the whole list would leave a screen passing against a
/// repository this application does not have.
///
/// These are the methods the screens actually depend on: the shelf's query, the
/// marks over an open book, and the read an export is built from. Each is
/// described once here and run twice — against the fake and against the
/// drift-backed repository — by `repository_contract_test.dart`.
///
/// It is a mixin rather than a function so that what a subject has to provide
/// is a signature the compiler checks: seeding works and marks is the one thing
/// the two sides do differently, and it is the only thing they say separately.
library;

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// The identifier a subject seeds [name] under.
///
/// The schema constrains an identifier to the thirty-six characters every
/// replica in the federation mints, so a contract that named a work `a` would
/// describe rows the real database refuses. Both subjects spell one the same
/// way, and this is where.
String contractId(String name) =>
    '${name.padRight(8, '0')}-1111-4111-8111-111111111111';

/// A work as a contract test describes one.
typedef WorkSeed = ({
  String id,
  String title,
  String? author,
  EbookFormat format,
  DateTime importedAt,
  bool deleted,
});

/// A mark as a contract test describes one.
typedef MarkSeed = ({
  String id,
  String ebookId,
  AnnotationKind kind,
  String locator,
  DateTime at,
  bool removed,
});

/// A work for the contract, with everything but [title] defaulted.
WorkSeed work(
  String id,
  String title, {
  String? author,
  EbookFormat format = EbookFormat.epub,
  DateTime? importedAt,
  bool deleted = false,
}) => (
  id: id,
  title: title,
  author: author,
  format: format,
  importedAt: importedAt ?? DateTime.utc(2026, 8, 31, 12),
  deleted: deleted,
);

/// A mark for the contract.
MarkSeed mark(
  String id,
  String ebookId, {
  AnnotationKind kind = AnnotationKind.highlight,
  String locator = 'epubcfi(/6/4!/4/2)',
  DateTime? at,
  bool removed = false,
}) => (
  id: id,
  ebookId: ebookId,
  kind: kind,
  locator: locator,
  at: at ?? DateTime.utc(2026, 9, 1, 12),
  removed: removed,
);

/// The behaviour every [LibraryRepository] and [AnnotationRepository] in this
/// application has, whether it holds a database or a list.
mixin RepositoryContract {
  /// A library holding [works], and the marks in [marks].
  ///
  /// The subject seeds however it can — a fake by pushing a list, the real one
  /// by writing rows — and answers with the repositories a screen would be
  /// handed.
  Future<({LibraryRepository library, AnnotationRepository annotations})> seed({
    List<WorkSeed> works,
    List<MarkSeed> marks,
  });

  /// The first answer to [query], which is what a screen builds itself from.
  Future<List<Ebook>> shelf(LibraryRepository library, LibraryQuery query) =>
      _first(library.watchEbooks(query));

  /// The first answer to a book's marks.
  Future<List<Annotation>> marksIn(
    AnnotationRepository annotations,
    String ebookId,
  ) => _first(annotations.watchMarksIn(ebookId));

  Future<List<T>> _first<T>(Stream<Result<List<T>>> stream) async {
    final Result<List<T>> answer = await stream.first;

    return switch (answer) {
      Ok<List<T>>(:final List<T> value) => value,
      Error<List<T>>(:final Exception error) => throw error,
    };
  }

  /// Runs the contract against whatever [seed] builds.
  void runContract() {
    group('the shelf a query asks for', () {
      test('is every work when nothing narrows it', () async {
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema'), work('b', 'Os Sertões')],
        );

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(),
          )).map((Ebook it) => it.id),
          unorderedEquals(<String>[contractId('a'), contractId('b')]),
        );
      });

      test('leaves out a work another device deleted', () async {
        // The tombstone is what a delete writes, and a shelf that showed one
        // would be a reader's deletion arriving and changing nothing.
        final subject = await seed(
          works: <WorkSeed>[
            work('a', 'Iracema'),
            work('b', 'Os Sertões', deleted: true),
          ],
        );

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(),
          )).map((Ebook it) => it.id),
          <String>[contractId('a')],
        );
      });

      test('matches the search against the title and the author', () async {
        final subject = await seed(
          works: <WorkSeed>[
            work('a', 'Iracema', author: 'José de Alencar'),
            work('b', 'Os Sertões', author: 'Euclides da Cunha'),
          ],
        );

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(term: 'alencar'),
          )).map((Ebook it) => it.id),
          <String>[contractId('a')],
        );
      });

      test('folds what the reader typed against what is stored', () async {
        // A reader who types `sertoes` finds *Sertões*. sqlite's `LIKE` is
        // ASCII-insensitive and nothing else, which is why the real repository
        // matches in Dart — and why a fake that used `contains` would disagree
        // with it exactly here.
        final subject = await seed(works: <WorkSeed>[work('b', 'Os Sertões')]);

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(term: 'sertoes'),
          )).map((Ebook it) => it.id),
          <String>[contractId('b')],
        );
      });

      test('narrows to one format', () async {
        final subject = await seed(
          works: <WorkSeed>[
            work('a', 'Iracema'),
            work('b', 'Um PDF', format: EbookFormat.pdf),
          ],
        );

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(format: EbookFormat.pdf),
          )).map((Ebook it) => it.id),
          <String>[contractId('b')],
        );
      });

      test('answers in the order the reader asked for', () async {
        final subject = await seed(
          works: <WorkSeed>[
            work(
              'a',
              'Iracema',
              author: 'José de Alencar',
              importedAt: DateTime.utc(2026, 8, 1),
            ),
            work(
              'b',
              'Os Sertões',
              author: 'Euclides da Cunha',
              importedAt: DateTime.utc(2026, 8, 20),
            ),
          ],
        );

        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(),
          )).map((Ebook it) => it.id),
          <String>[contractId('b'), contractId('a')],
          reason: 'the newest arrival comes first by default',
        );
        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(sort: LibrarySort.title),
          )).map((Ebook it) => it.id),
          <String>[contractId('a'), contractId('b')],
        );
        expect(
          (await shelf(
            subject.library,
            const LibraryQuery(sort: LibrarySort.author),
          )).map((Ebook it) => it.id),
          <String>[contractId('b'), contractId('a')],
          reason: 'Euclides sorts before José',
        );
      });
    });

    group('the marks in one book', () {
      test('are that book\'s and no other\'s', () async {
        // They are painted over the open page. A mark from another book would
        // be a highlight on a paragraph that never had one.
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema'), work('b', 'Os Sertões')],
          marks: <MarkSeed>[mark('m1', 'a'), mark('m2', 'b')],
        );

        expect(
          (await marksIn(
            subject.annotations,
            contractId('a'),
          )).map((Annotation it) => it.id),
          <String>[contractId('m1')],
        );
      });

      test('leave out one that was removed', () async {
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema')],
          marks: <MarkSeed>[mark('m1', 'a'), mark('m2', 'a', removed: true)],
        );

        expect(
          (await marksIn(
            subject.annotations,
            contractId('a'),
          )).map((Annotation it) => it.id),
          <String>[contractId('m1')],
        );
      });

      test('come back most recent first', () async {
        // The order is when each was made and deliberately not where it is in
        // the book: two CFIs are compared by parsing them.
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema')],
          marks: <MarkSeed>[
            mark('m1', 'a', at: DateTime.utc(2026, 9, 1)),
            mark('m2', 'a', at: DateTime.utc(2026, 9, 3)),
          ],
        );

        expect(
          (await marksIn(
            subject.annotations,
            contractId('a'),
          )).map((Annotation it) => it.id),
          <String>[contractId('m2'), contractId('m1')],
        );
      });
    });

    group('the read an export is built from', () {
      test('is narrowed to the book that was asked for', () async {
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema'), work('b', 'Os Sertões')],
          marks: <MarkSeed>[mark('m1', 'a'), mark('m2', 'b')],
        );

        final Result<List<MarkedPassage>> read = await subject.annotations
            .readMarks(ebookId: contractId('a'));

        expect(read, isA<Ok<List<MarkedPassage>>>());
        expect(
          (read as Ok<List<MarkedPassage>>).value.map(
            (MarkedPassage it) => it.mark.id,
          ),
          <String>[contractId('m1')],
        );
      });

      test('is narrowed to the kind that was asked for', () async {
        final subject = await seed(
          works: <WorkSeed>[work('a', 'Iracema')],
          marks: <MarkSeed>[
            mark('m1', 'a'),
            mark('m2', 'a', kind: AnnotationKind.bookmark),
          ],
        );

        final Result<List<MarkedPassage>> read = await subject.annotations
            .readMarks(kind: AnnotationKind.bookmark);

        expect(
          (read as Ok<List<MarkedPassage>>).value.map(
            (MarkedPassage it) => it.mark.id,
          ),
          <String>[contractId('m2')],
        );
      });
    });
  }
}

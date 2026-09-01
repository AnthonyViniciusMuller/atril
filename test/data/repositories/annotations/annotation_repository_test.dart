/// Marking a passage, and the one path a mark takes out of this application.
///
/// The assertion that matters most here is not about a column. It is that a
/// highlight leaves an **operation** in the log this device owes: C21 says a
/// mark written through `CreateAnnotation` reaches the reader's other devices
/// never, so a repository that saved the row and appended nothing would be a
/// highlight that exists on one phone and is invisible everywhere else — and
/// nothing on screen would say so.
library;

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/annotations/annotation_repository_impl.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

/// The device the marks are attributed to.
const String _device = '11111111-1111-4111-8111-111111111111';

/// A UUID-shaped identifier from a short name.
///
/// The schema constrains an identifier to thirty-six characters, because that
/// is what every replica in the federation mints.
String _id(String name) =>
    '${name.padRight(8, '0')}-1111-4111-8111-111111111111';

/// A CFI range, as the engine reports one.
///
/// It is the shape of the real thing — two paths and a comma — because the
/// value this app must not touch is exactly this one.
const String _range =
    'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05],/2/1:1,/3:4)';

int _minted = 0;

void main() {
  late AtrilDatabase database;
  late OperationAuthor author;
  late AnnotationRepository annotations;

  setUp(() async {
    database = AtrilDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    // Bound, because the author refuses to write on a device with no identity:
    // an operation carrying no author is a clock entry nothing could attribute.
    await database.identityDao.bindDevice(
      id: _device,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );

    final HybridClock clock = HybridClock(wall: () => _at);

    author = OperationAuthor(
      database: database,
      clock: clock,
      reconciler: Reconciler(database, clock),
      mint: () => _id('m${++_minted}'),
    );
    annotations = AnnotationRepositoryImpl(
      marks: database.annotationsDao,
      library: database.libraryDao,
      author: author,
      mint: () => _id('m${++_minted}'),
    );
  });

  /// A work in the replica.
  Future<void> seedWork(String name) => database
      .into(database.ebooks)
      .insert(
        EbooksCompanion.insert(
          id: _id(name),
          title: 'Os Sertões',
          format: 'epub',
          contentHash: '0' * 64,
          importedAt: _at,
          vectorClock: VectorClock.of(<String, int>{_device: 1}),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  /// The code a refusal carries, or `null` where it succeeded.
  String? codeOf(Result<Object?> result) => switch (result) {
    Error<Object?>(:final Exception error) when error is AppException =>
      error.code,
    _ => null,
  };

  /// The kind a refusal carries, or `null` where it succeeded.
  ErrorKind? kindOf(Result<Object?> result) => switch (result) {
    Error<Object?>(:final Exception error) when error is AppException =>
      error.kind,
    _ => null,
  };

  group('marking a passage', () {
    test('leaves an operation the sync loop will push', () async {
      // The whole of C21 in one assertion. The row is not the point; the
      // operation beside it is, because that is the only thing any other
      // replica will ever hear about this mark.
      await seedWork('a');

      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
        passage: 'A terra é ingrata.',
      );

      expect(made, isA<Ok<Annotation>>());

      final List<Operation> pending = await database.syncDao.pending();

      expect(pending, hasLength(1));
      expect(pending.single.entity, TargetEntity.annotation);
      expect(pending.single.kind, OperationKind.insert);
      expect(pending.single.deviceId, _device);
      expect(pending.single.delta[fieldKind], 'highlight');
      expect(pending.single.delta[fieldEbookId], _id('a'));
    });

    test('carries the range the engine gave, byte for byte', () async {
      // The one value in this record authored by a renderer rather than by
      // this app, and the one phase 9's single engine exists to keep
      // resolvable on the reader's other devices. Anything that trimmed,
      // lowercased or re-encoded it here would be a second CFI implementation
      // arriving by the back door.
      await seedWork('a');

      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
      );

      expect((made as Ok<Annotation>).value.locator, _range);
      expect(
        (await database.syncDao.pending()).single.delta[fieldLocator],
        _range,
      );
    });

    test('keeps the passage the selection reported', () async {
      // A highlight stores the words it covers because the screen that lists
      // marks across the library has no engine and no open book to ask. A row
      // that stored nothing could only ever be shown as a CFI.
      await seedWork('a');

      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
        passage: '  A terra é ingrata.  ',
      );

      final Annotation mark = (made as Ok<Annotation>).value;

      expect(mark.kind, AnnotationKind.highlight);
      expect(mark.text, 'A terra é ingrata.');
      expect(mark.ebookId, _id('a'));
    });

    test('is allowed to carry nothing but its range', () async {
      await seedWork('a');

      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
        passage: '   ',
      );

      // Empty and absent are one claim about a mark: there is no text.
      expect((made as Ok<Annotation>).value.text, isNull);
    });

    test('in a work this device does not hold is refused', () async {
      // Refused here rather than one layer down, so that the sentence names
      // the book. The reconciler would report a record it does not hold, which
      // is true and is not what a reader needs told.
      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('missing'),
        cfiRange: _range,
      );

      expect(kindOf(made), ErrorKind.notFound);
      expect(await database.syncDao.pending(), isEmpty);
    });

    test('over nothing at all is refused', () async {
      await seedWork('a');

      final Result<Annotation> made = await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: '   ',
      );

      expect(kindOf(made), ErrorKind.invalidArgument);
      expect(await database.syncDao.pending(), isEmpty);
    });
  });

  group('noting a passage', () {
    test('keeps the reader\'s words and calls the mark a note', () async {
      await seedWork('a');

      final Result<Annotation> made = await annotations.note(
        ebookId: _id('a'),
        cfiRange: _range,
        text: 'Euclides está descrevendo a seca como personagem.',
      );

      final Annotation mark = (made as Ok<Annotation>).value;

      expect(mark.kind, AnnotationKind.note);
      expect(mark.text, 'Euclides está descrevendo a seca como personagem.');
      expect(mark.locator, _range);
      expect(
        (await database.syncDao.pending()).single.delta[fieldKind],
        'note',
      );
    });

    test('with nothing in it is refused before it is authored', () async {
      // The contract requires a note to carry text and the schema carries the
      // same rule, but a `CHECK` constraint names a table. Refusing it here
      // names the note, which is what a reader can be told about.
      await seedWork('a');

      final Result<Annotation> made = await annotations.note(
        ebookId: _id('a'),
        cfiRange: _range,
        text: '   ',
      );

      expect(codeOf(made), codeNoteWithoutText);
      expect(kindOf(made), ErrorKind.invalidArgument);
      expect(await database.syncDao.pending(), isEmpty);
    });
  });

  group('bookmarking a place', () {
    test('carries a position and nothing else', () async {
      await seedWork('a');

      final Result<Annotation> made = await annotations.bookmark(
        ebookId: _id('a'),
        locator: 'epubcfi(/6/14!/4/10/2/1:0)',
      );

      final Annotation mark = (made as Ok<Annotation>).value;

      expect(mark.kind, AnnotationKind.bookmark);
      expect(mark.locator, 'epubcfi(/6/14!/4/10/2/1:0)');
      // No text is asked for and none is stored. A place the reader had to
      // name would be a note about a place.
      expect(mark.text, isNull);
    });

    test('does not touch where the device stopped reading', () async {
      // Two records that look alike and are not: a position is where a device
      // stopped, has one writer per device (C05) and is overwritten on the
      // next page; a bookmark is a place the reader chose and nothing
      // overwrites it.
      await seedWork('a');

      await annotations.bookmark(
        ebookId: _id('a'),
        locator: 'epubcfi(/6/14!/4/10/2/1:0)',
      );

      expect(
        await database.readingDao.placeOf(ebookId: _id('a'), deviceId: _device),
        isNull,
      );
      expect(
        (await database.syncDao.pending()).single.entity,
        TargetEntity.annotation,
      );
    });
  });

  group('the marks in a book', () {
    test('arrive most recent first and lose the removed ones', () async {
      // The order is when each mark was made, deliberately and not where it is
      // in the book: two CFIs are compared by parsing them, and a CFI parser
      // in Dart is the second implementation architecture.md forbids.
      await seedWork('a');

      final Annotation first = ((await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
      )) as Ok<Annotation>).value;
      final Annotation second = ((await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: 'epubcfi(/6/4!/4/2,/1:0,/1:9)',
      )) as Ok<Annotation>).value;

      expect(
        await annotations
            .watchMarksIn(_id('a'))
            .map(
              (Result<List<Annotation>> marks) => <String>[
                for (final Annotation mark
                    in (marks as Ok<List<Annotation>>).value)
                  mark.id,
              ],
            )
            .first,
        <String>[second.id, first.id],
      );

      await annotations.removeMark(second.id);

      expect(
        await annotations
            .watchMarksIn(_id('a'))
            .map(
              (Result<List<Annotation>> marks) => <String>[
                for (final Annotation mark
                    in (marks as Ok<List<Annotation>>).value)
                  mark.id,
              ],
            )
            .first,
        <String>[first.id],
      );
    });

    test('leave the marks of another book alone', () async {
      await seedWork('a');
      await seedWork('b');

      await annotations.highlight(ebookId: _id('a'), cfiRange: _range);

      final Result<List<Annotation>> other = await annotations
          .watchMarksIn(_id('b'))
          .first;

      expect((other as Ok<List<Annotation>>).value, isEmpty);
    });
  });

  group('every mark the reader holds', () {
    test('comes back with the work each one is in', () async {
      await seedWork('a');

      await annotations.highlight(ebookId: _id('a'), cfiRange: _range);

      final Result<List<MarkedPassage>> everything = await annotations
          .watchMarks()
          .first;
      final List<MarkedPassage> passages =
          (everything as Ok<List<MarkedPassage>>).value;

      expect(passages, hasLength(1));
      expect(passages.single.work.title, 'Os Sertões');
      expect(passages.single.mark.locator, _range);
    });

    test('narrows to one book and to one kind', () async {
      await seedWork('a');
      await seedWork('b');

      await annotations.highlight(ebookId: _id('a'), cfiRange: _range);
      await annotations.note(
        ebookId: _id('a'),
        cfiRange: _range,
        text: 'a seca',
      );
      await annotations.bookmark(ebookId: _id('b'), locator: _range);

      Future<int> count({String? ebookId, AnnotationKind? kind}) async =>
          ((await annotations.watchMarks(ebookId: ebookId, kind: kind).first)
                  as Ok<List<MarkedPassage>>)
              .value
              .length;

      expect(await count(), 3);
      expect(await count(ebookId: _id('a')), 2);
      expect(await count(kind: AnnotationKind.note), 1);
      expect(await count(ebookId: _id('b'), kind: AnnotationKind.note), 0);
    });

    test('leaves out the marks in a book the reader deleted', () async {
      // A reader who deleted a book has said they are not reading it, and its
      // highlights are not a second opinion.
      await seedWork('a');

      await annotations.highlight(ebookId: _id('a'), cfiRange: _range);

      await (database.update(database.ebooks)
            ..where(($EbooksTable row) => row.id.equals(_id('a'))))
          .write(const EbooksCompanion(deleted: Value<bool>(true)));

      expect(
        ((await annotations.watchMarks().first) as Ok<List<MarkedPassage>>)
            .value,
        isEmpty,
      );
    });

    test('reads the same list once, for an export', () async {
      await seedWork('a');

      await annotations.highlight(ebookId: _id('a'), cfiRange: _range);

      final Result<List<MarkedPassage>> once = await annotations.readMarks();

      expect((once as Ok<List<MarkedPassage>>).value, hasLength(1));
    });
  });

  group('writing on a mark', () {
    test('turns a highlight into a note', () async {
      // A mark the reader has written on is what a note is. The passage the
      // highlight had stored gives way to the words, because there is one text
      // field and the contract says a note's belongs to the reader.
      await seedWork('a');

      final Annotation mark = ((await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
        passage: 'A terra é ingrata.',
      )) as Ok<Annotation>).value;

      expect(
        await annotations.reword(mark.id, 'A terra é ingrata. — e é sujeito'),
        isA<Ok<void>>(),
      );

      final AnnotationRow row = (await database.annotationsDao.readMark(
        mark.id,
      ))!;

      expect(row.kind, 'note');
      expect(row.content, 'A terra é ingrata. — e é sujeito');
    });

    test('claims only what changed', () async {
      // Reconciliation is per record and not per field (C17), so a delta
      // restating a kind nobody touched would carry this device's claim to it
      // and let a tie-break settle what nobody meant.
      await seedWork('a');

      final Annotation mark = ((await annotations.note(
        ebookId: _id('a'),
        cfiRange: _range,
        text: 'primeira',
      )) as Ok<Annotation>).value;

      await annotations.reword(mark.id, 'segunda');

      final Operation last = (await database.syncDao.pending()).last;

      expect(last.delta.keys, <String>[fieldText]);
      expect(last.delta[fieldText], 'segunda');
    });

    test('with nothing in it is refused', () async {
      await seedWork('a');

      final Annotation mark = ((await annotations.note(
        ebookId: _id('a'),
        cfiRange: _range,
        text: 'primeira',
      )) as Ok<Annotation>).value;

      expect(
        codeOf(await annotations.reword(mark.id, '  ')),
        codeNoteWithoutText,
      );
      expect((await database.syncDao.pending()), hasLength(1));
    });

    test('on a mark this device does not hold is refused', () async {
      expect(
        codeOf(await annotations.reword(_id('nothing'), 'algo')),
        codeMarkNotFound,
      );
    });
  });

  group('removing a mark', () {
    test('is a tombstone and not a deletion', () async {
      // A row removed outright is resurrected by the first replica that had
      // not yet heard about the removal, so it travels as a write.
      await seedWork('a');

      final Annotation mark = ((await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
      )) as Ok<Annotation>).value;

      expect(await annotations.removeMark(mark.id), isA<Ok<void>>());

      final AnnotationRow? row = await database.annotationsDao.readMark(
        mark.id,
      );

      expect(row, isNotNull);
      expect(row!.deleted, isTrue);
      expect(
        (await database.syncDao.pending()).last.kind,
        OperationKind.delete,
      );
    });

    test('is undone by one operation carrying nothing', () async {
      // What a tombstone makes cheap, and the reason the removal is offered
      // with an undo rather than guarded by a confirmation.
      await seedWork('a');

      final Annotation mark = ((await annotations.highlight(
        ebookId: _id('a'),
        cfiRange: _range,
      )) as Ok<Annotation>).value;

      await annotations.removeMark(mark.id);

      expect(await annotations.restoreMark(mark.id), isA<Ok<void>>());
      expect(
        (await database.annotationsDao.readMark(mark.id))!.deleted,
        isFalse,
      );

      final Operation restored = (await database.syncDao.pending()).last;

      expect(restored.kind, OperationKind.update);
      expect(restored.delta, isEmpty);
    });

    test(
      'this device does not hold names the mark and not the table',
      () async {
        final Result<void> gone = await annotations.removeMark(_id('nothing'));

        expect(codeOf(gone), codeMarkNotFound);
        expect(await database.syncDao.pending(), isEmpty);
      },
    );
  });
}

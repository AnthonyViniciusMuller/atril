/// [AnnotationRepository] over the local replica.
library;

import 'dart:async';

import '../../../domain/crdt/revision.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/operation.dart';
import '../../../utils/errors.dart';
import '../../../utils/identifiers.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/errors.dart';
import '../../services/local/dao/annotations_dao.dart';
import '../../services/local/dao/library_dao.dart';
import '../../services/local/database.dart';
import '../../services/sync/author.dart';
import '../../services/sync/delta.dart';
import 'annotation_repository.dart';

final _log = loggerFor('data/annotations');

/// The operation a failed reading of the marks reports under.
const String opReadMarks = 'annotations: read';

/// The operation a mark being made or unmade reports under.
const String opMark = 'annotations: write';

/// A mark, as the replica holds it.
Annotation annotationOfRow(AnnotationRow row) => Annotation(
  id: row.id,
  ebookId: row.ebookId,
  kind: AnnotationKind.parse(row.kind),
  text: row.content,
  locator: row.locator,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// What the reader marked, read out of the replica and written through the
/// operation author.
final class AnnotationRepositoryImpl implements AnnotationRepository {
  /// The repository over [marks], with the works from [library] and every
  /// change authored through [author].
  AnnotationRepositoryImpl({
    required this.marks,
    required this.library,
    required this.author,
    String Function()? mint,
  }) : _mint = mint ?? mintIdentifier;

  /// Where the marks are.
  final AnnotationsDao marks;

  /// Where the works are, so that a mark can be refused before it is authored
  /// against a book this device does not hold.
  final LibraryDao library;

  /// Where a change to a replicable record goes. There is no other way out of
  /// this repository, and C21 is why.
  final OperationAuthor author;

  final String Function() _mint;

  @override
  Stream<Result<List<Annotation>>> watchMarksIn(String ebookId) => _guard(
    marks
        .watchMarksIn(ebookId)
        .map(
          (List<AnnotationRow> rows) => <Annotation>[
            for (final AnnotationRow row in rows) annotationOfRow(row),
          ],
        ),
  );

  @override
  Future<Result<Annotation>> highlight({
    required String ebookId,
    required String cfiRange,
    String? passage,
  }) => _made(
    ebookId: ebookId,
    kind: AnnotationKind.highlight,
    locator: cfiRange,
    text: passage,
  );

  @override
  Future<Result<Annotation>> note({
    required String ebookId,
    required String cfiRange,
    required String text,
  }) async {
    if (_blankIsNothing(text) == null) {
      // Refused here and not by the column, so that the sentence names the
      // note rather than a `CHECK` constraint. The schema carries the same
      // rule — a note is the one kind whose text cannot be null — and this is
      // where a reader can be told about it.
      _log.warning('a note in $ebookId was written with no words in it');

      return Result<Annotation>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'a note with no text is an empty note',
          code: codeNoteWithoutText,
          op: opMark,
        ),
      );
    }

    return _made(
      ebookId: ebookId,
      kind: AnnotationKind.note,
      locator: cfiRange,
      text: text,
    );
  }

  @override
  Future<Result<Annotation>> bookmark({
    required String ebookId,
    required String locator,
  }) => _made(
    ebookId: ebookId,
    kind: AnnotationKind.bookmark,
    locator: locator,
    // No text, and none is asked for. A bookmark is a place, and a place the
    // reader had to name would be a note about a place.
  );

  /// Authors a new mark of [kind] over [locator], and answers with it as the
  /// replica now holds it.
  ///
  /// What a record *is* after a change is one question with one answer, and the
  /// answer is the reconciler's: the row is read back rather than assembled
  /// here from what was asked for.
  Future<Result<Annotation>> _made({
    required String ebookId,
    required AnnotationKind kind,
    required String locator,
    String? text,
  }) async {
    try {
      // Checked here so that the refusal names the book. The reconciler
      // refuses the same thing one layer down and reports it as a record it
      // does not hold, which is true and is not what a reader needs told.
      if (await library.readEbook(ebookId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no work called $ebookId',
          op: opMark,
        );
      }

      if (locator.trim().isEmpty) {
        throw AppException(
          kind: ErrorKind.invalidArgument,
          message: 'a mark cannot be made without a passage to attach it to',
          op: opMark,
        );
      }

      final String id = _mint();
      final claims = DeltaWriter()
        ..id(fieldEbookId, ebookId)
        ..text(fieldKind, kind.wireName)
        // The locator crosses this layer exactly as the engine reported it —
        // not trimmed, not re-encoded, not lowercased. It is the one value in
        // the record authored by a renderer rather than by this app, and a
        // locator this app tidied would be one that resolves here and nowhere
        // else. The emptiness above is checked on a trimmed copy and stored
        // from the original.
        ..text(fieldLocator, locator)
        ..text(fieldText, _blankIsNothing(text));

      await author.write(
        Change.insert(TargetEntity.annotation, id, claims.fields),
      );

      return Result<Annotation>.ok(
        annotationOfRow((await marks.readMark(id))!),
      );
    } on Object catch (error, stackTrace) {
      _log.warning('the mark in $ebookId was not made', error, stackTrace);

      return Result<Annotation>.error(failureFrom(error, op: opMark));
    }
  }

  @override
  Future<Result<void>> removeMark(String annotationId) =>
      _mark(annotationId, Change.delete(TargetEntity.annotation, annotationId));

  @override
  Future<Result<void>> restoreMark(String annotationId) => _mark(
    annotationId,
    Change.restore(TargetEntity.annotation, annotationId),
  );

  /// Authors [change] against the mark [annotationId] names.
  Future<Result<void>> _mark(String annotationId, Change change) async {
    try {
      if (await marks.readMark(annotationId) == null) {
        throw AppException(
          kind: ErrorKind.notFound,
          message: 'this device holds no mark called $annotationId',
          code: codeMarkNotFound,
          op: opMark,
        );
      }

      await author.write(change);

      return const Result<void>.ok(null);
    } on Object catch (error, stackTrace) {
      _log.warning('$change on $annotationId did not apply', error, stackTrace);

      return Result<void>.error(failureFrom(error, op: opMark));
    }
  }

  /// [source] as a stream of results.
  ///
  /// A stream that failed by ending would be an exception crossing a layer
  /// boundary with a `Stream` around it, and a list that stops arriving looks
  /// exactly like an empty one.
  Stream<Result<T>> _guard<T>(Stream<T> source) => source.transform(
    StreamTransformer<T, Result<T>>.fromHandlers(
      handleData: (T value, EventSink<Result<T>> sink) =>
          sink.add(Result<T>.ok(value)),
      handleError:
          (Object error, StackTrace stackTrace, EventSink<Result<T>> sink) {
            _log.warning('the marks could not be read', error, stackTrace);

            sink.add(Result<T>.error(failureFrom(error, op: opReadMarks)));
          },
    ),
  );
}

/// [value] trimmed, or `null` where there is nothing in it.
///
/// A field given the empty string and a field given nothing are one claim about
/// a mark — there is no text — and the column stores `NULL` for both.
String? _blankIsNothing(String? value) {
  final String? trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

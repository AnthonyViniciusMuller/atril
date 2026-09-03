/// An [AnnotationRepository] that answers from memory.
library;

import 'dart:async';

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/utils/result.dart';

/// An [AnnotationRepository] that answers from memory.
///
/// The marks are a broadcast controller for the reason the works are: what the
/// reader's screen is written against is a *stream*, and a repository that
/// answered a list once would be a repository this app does not have.
final class FakeAnnotationRepository implements AnnotationRepository {
  final StreamController<Result<List<Annotation>>> _marks =
      StreamController<Result<List<Annotation>>>.broadcast();

  /// Every mark it was asked to make, in order.
  final List<({String ebookId, String cfiRange, String? passage})> highlighted =
      <({String ebookId, String cfiRange, String? passage})>[];

  /// Every mark it was asked to remove, and to bring back.
  final List<String> removed = <String>[];

  /// As [removed], the other way.
  final List<String> restored = <String>[];

  /// What the next write fails with, or `null` to let it succeed.
  Exception? refusal;

  /// The last list pushed, replayed to a watch that starts afterwards.
  ///
  /// **A watch opens with it, as drift's does.** The real repository answers a
  /// `watch` with the rows as they stand and then with every change, and a fake
  /// that said nothing until the next push would leave a screen that subscribed
  /// late on its spinner forever. Nothing is replayed before the first push.
  Result<List<Annotation>>? _latestMarks;

  /// Emits [marks] to whoever is watching.
  void emitMarks(List<Annotation> marks) {
    _latestMarks = Result<List<Annotation>>.ok(marks);
    _marks.add(_latestMarks!);
  }

  /// Emits a failure, which a screen should ride out rather than empty itself
  /// over.
  void failMarks(Exception error) {
    _latestMarks = Result<List<Annotation>>.error(error);
    _marks.add(_latestMarks!);
  }

  /// Closes the streams, as a disposed repository would.
  Future<void> close() async {
    await _marks.close();
    await _passages.close();
  }

  final StreamController<Result<List<MarkedPassage>>> _passages =
      StreamController<Result<List<MarkedPassage>>>.broadcast();

  /// Every reworded mark, as `(id, text)`.
  final List<(String, String)> reworded = <(String, String)>[];

  List<MarkedPassage> _current = const <MarkedPassage>[];

  /// Emits [passages] to the annotations screen.
  void emitPassages(List<MarkedPassage> passages) {
    _current = passages;
    _passages.add(Result<List<MarkedPassage>>.ok(passages));
  }

  /// Emits a failure to the annotations screen.
  void failPassages(Exception error) =>
      _passages.add(Result<List<MarkedPassage>>.error(error));

  /// Every scope the screen asked for, as `(ebookId, kind)`.
  final List<(String?, AnnotationKind?)> scopes =
      <(String?, AnnotationKind?)>[];

  /// The marks of one book, most recent first, out of what a test pushed.
  ///
  /// **It scopes and orders as the real repository does**, because a fake that
  /// answered with every mark it was ever given would be one the reader's
  /// screen agrees with and the app does not: a highlight in another book
  /// would be painted over this one's page.
  List<Annotation> marksIn(List<Annotation> marks, String ebookId) =>
      <Annotation>[
        for (final Annotation mark in marks)
          if (mark.ebookId == ebookId && !mark.revision.deleted) mark,
      ]..sort(
        (Annotation a, Annotation b) =>
            b.revision.updatedAt.compareTo(a.revision.updatedAt),
      );

  @override
  Stream<Result<List<Annotation>>> watchMarksIn(String ebookId) =>
      _marksFrom.map(
        (Result<List<Annotation>> result) => switch (result) {
          Ok<List<Annotation>>(:final List<Annotation> value) =>
            Result<List<Annotation>>.ok(marksIn(value, ebookId)),
          Error<List<Annotation>>() => result,
        },
      );

  /// What has been pushed, starting from the last one where there is one.
  Stream<Result<List<Annotation>>> get _marksFrom async* {
    final Result<List<Annotation>>? latest = _latestMarks;

    if (latest != null) {
      yield latest;
    }

    yield* _marks.stream;
  }

  /// The marks a screen is watching, starting from what is held now.
  ///
  /// It opens with the current list rather than waiting, because that is what
  /// the real repository does: drift answers a `watch` with the rows as they
  /// stand and then with every change. A fake that said nothing until a test
  /// pushed something would leave every screen on its spinner, which is a
  /// difference between the fake and the thing rather than a state of the app.
  @override
  Stream<Result<List<MarkedPassage>>> watchMarks({
    String? ebookId,
    AnnotationKind? kind,
  }) async* {
    scopes.add((ebookId, kind));

    yield Result<List<MarkedPassage>>.ok(_current);
    yield* _passages.stream;
  }

  /// What a one-off read answers with, which is what an export is built from.
  List<MarkedPassage> exportable = const <MarkedPassage>[];

  /// Every scope a one-off read was asked for, in order.
  final List<String?> exported = <String?>[];

  @override
  Future<Result<List<MarkedPassage>>> readMarks({
    String? ebookId,
    AnnotationKind? kind,
  }) async {
    exported.add(ebookId);

    // Scoped, as the real one is: an export narrowed to one book that carried
    // the whole library would be a file the reader did not ask for.
    return Result<List<MarkedPassage>>.ok(<MarkedPassage>[
      for (final MarkedPassage passage in exportable)
        if ((ebookId == null || passage.mark.ebookId == ebookId) &&
            (kind == null || passage.mark.kind == kind))
          passage,
    ]);
  }

  @override
  Future<Result<void>> reword(String annotationId, String text) async {
    reworded.add((annotationId, text));

    final Exception? refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<Annotation>> highlight({
    required String ebookId,
    required String cfiRange,
    String? passage,
  }) async {
    highlighted.add((ebookId: ebookId, cfiRange: cfiRange, passage: passage));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length}',
        ebookId: ebookId,
        kind: AnnotationKind.highlight,
        locator: cfiRange,
        text: passage,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  /// Every note it was asked to make, in order.
  final List<({String ebookId, String cfiRange, String text})> noted =
      <({String ebookId, String cfiRange, String text})>[];

  @override
  Future<Result<Annotation>> note({
    required String ebookId,
    required String cfiRange,
    required String text,
  }) async {
    noted.add((ebookId: ebookId, cfiRange: cfiRange, text: text));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length + noted.length}',
        ebookId: ebookId,
        kind: AnnotationKind.note,
        locator: cfiRange,
        text: text,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  /// Every place it was asked to bookmark, in order.
  final List<({String ebookId, String locator})> bookmarked =
      <({String ebookId, String locator})>[];

  @override
  Future<Result<Annotation>> bookmark({
    required String ebookId,
    required String locator,
  }) async {
    bookmarked.add((ebookId: ebookId, locator: locator));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length + noted.length + bookmarked.length}',
        ebookId: ebookId,
        kind: AnnotationKind.bookmark,
        locator: locator,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  @override
  Future<Result<void>> removeMark(String annotationId) async {
    removed.add(annotationId);

    final Exception? refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreMark(String annotationId) async {
    restored.add(annotationId);

    return const Result<void>.ok(null);
  }
}

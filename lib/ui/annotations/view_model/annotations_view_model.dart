/// What the annotations screen knows.
///
/// **One view model for two scopes.** Everything the reader has marked and
/// everything they have marked in one book are the same question asked at two
/// widths, so they are one screen over one stream with a narrowing. Two view
/// models would be two places to fix the day a mark gains a field.
///
/// **The filter is a query and not a `where` over a list held here.** The kind
/// is pushed down to the repository, which pushes it down to a column, because
/// a screen that filtered in Dart would be a screen that has read every mark in
/// the library to show three of them.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../domain/models/annotation.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/annotations');

/// The state of the annotations screen.
final class AnnotationsViewModel extends ChangeNotifier {
  /// The view model over [annotations], showing every mark or — where
  /// [ebookId] is given — the marks in one work.
  AnnotationsViewModel({required this.annotations, this.ebookId}) {
    remove = Command1<void, String>(annotations.removeMark);
    restore = Command1<void, String>(annotations.restoreMark);
    reword = Command1<void, ({String id, String text})>(
      (({String id, String text}) edit) =>
          annotations.reword(edit.id, edit.text),
    );

    _listen();
  }

  /// Where the marks come from.
  final AnnotationRepository annotations;

  /// The work the screen is narrowed to, or `null` for the whole library.
  final String? ebookId;

  /// UC05. Removes a mark.
  late final Command1<void, String> remove;

  /// UC05. Brings a removed mark back.
  late final Command1<void, String> restore;

  /// UC05. Changes what a mark says, which makes it a note.
  late final Command1<void, ({String id, String text})> reword;

  StreamSubscription<Result<List<MarkedPassage>>>? _marks;

  List<MarkedPassage> _passages = const <MarkedPassage>[];
  AnnotationKind? _kind;
  bool _loading = true;
  Exception? _failure;

  /// What the reader has marked, most recent first.
  List<MarkedPassage> get marks => _passages;

  /// The kind the list is narrowed to, or `null` for all of them.
  AnnotationKind? get kind => _kind;

  /// Whether the first answer has not arrived yet.
  bool get loading => _loading;

  /// Why the list is not on screen, or `null` where it is.
  Exception? get failure => _failure;

  /// Whether the reader has marked nothing that the current filter admits.
  bool get isEmpty => !_loading && _failure == null && _passages.isEmpty;

  /// Whether the emptiness is the filter's doing rather than the library's.
  ///
  /// The two are different sentences: a reader who has marked nothing is told
  /// what marking is for, and one whose filter matches nothing is offered the
  /// filter back.
  bool get isFiltered => _kind != null;

  /// Narrows the list to [kind], or widens it to everything.
  void filterBy(AnnotationKind? kind) {
    if (kind == _kind) {
      return;
    }

    _kind = kind;
    _loading = true;
    notifyListeners();
    _listen();
  }

  void _listen() {
    unawaited(_marks?.cancel());

    _marks = annotations
        .watchMarks(ebookId: ebookId, kind: _kind)
        .listen(_onMarks);
  }

  void _onMarks(Result<List<MarkedPassage>> marks) {
    _loading = false;

    switch (marks) {
      case Ok<List<MarkedPassage>>(:final List<MarkedPassage> value):
        _passages = value;
        _failure = null;
      case Error<List<MarkedPassage>>(:final Exception error):
        // The list is kept rather than emptied. A query that failed once says
        // nothing about what the reader has marked, and a screen that went
        // blank would be reporting a deletion that did not happen.
        _log.warning('the marks could not be read', error);
        _failure = error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_marks?.cancel());
    remove.dispose();
    restore.dispose();
    reword.dispose();
    super.dispose();
  }
}

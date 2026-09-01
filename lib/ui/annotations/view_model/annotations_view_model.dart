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
///
/// **The export is read again rather than taken from the list on screen.** A
/// file is written from what is true when the reader asks for it, and what is
/// on screen is a filtered view — a reader looking at their bookmarks who asks
/// for an export means their marks and not the four rows in front of them. The
/// *scope* is honoured, because that one is a place and not a lens: an export
/// from one book's screen is that book's.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../data/services/annotations/annotation_export.dart';
import '../../../data/services/files/file_source.dart';
import '../../../domain/models/annotation.dart';
import '../../../utils/errors.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/annotations');

/// The operation an export reports under.
const String opExport = 'annotations: export';

/// The stable code of an export with nothing in it.
///
/// A file holding a heading and no marks is not the reader's data; it is a file
/// they now have to delete. Saying so is a different sentence from a failure,
/// which is why it is a code.
const String codeNothingToExport = 'nothing_to_export';

/// The state of the annotations screen.
final class AnnotationsViewModel extends ChangeNotifier {
  /// The view model over [annotations], showing every mark or — where
  /// [ebookId] is given — the marks in one work.
  AnnotationsViewModel({
    required this.annotations,
    required this.files,
    this.ebookId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    remove = Command1<void, String>(annotations.removeMark);
    restore = Command1<void, String>(annotations.restoreMark);
    reword = Command1<void, ({String id, String text})>(
      (({String id, String text}) edit) =>
          annotations.reword(edit.id, edit.text),
    );

    export = Command1<String?, ({ExportFormat format, ExportWords words})>(
      _export,
    );

    _listen();
  }

  /// Where the marks come from.
  final AnnotationRepository annotations;

  /// Where a file the reader asked for goes.
  ///
  /// It is here and not in the repository for the reason the import's picker is
  /// in the library's view model: choosing a place on this device is a gesture
  /// and not a change to a record, and a repository that opened a dialog could
  /// not be tested without one.
  final FileSaver files;

  final DateTime Function() _now;

  /// The work the screen is narrowed to, or `null` for the whole library.
  final String? ebookId;

  /// UC05. Removes a mark.
  late final Command1<void, String> remove;

  /// UC05. Brings a removed mark back.
  late final Command1<void, String> restore;

  /// UC05. Changes what a mark says, which makes it a note.
  late final Command1<void, ({String id, String text})> reword;

  /// UC05. Writes everything marked to a file the reader chooses.
  ///
  /// It answers with what the file was saved as, or `null` where the reader
  /// backed out of the dialog — which is a decision and not a failure, and the
  /// screen says nothing about it.
  late final Command1<String?, ({ExportFormat format, ExportWords words})>
  export;

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

  Future<Result<String?>> _export(
    ({ExportFormat format, ExportWords words}) request,
  ) async {
    final Result<List<MarkedPassage>> read = await annotations.readMarks(
      ebookId: ebookId,
    );

    if (read case Error<List<MarkedPassage>>(:final Exception error)) {
      return Result<String?>.error(error);
    }

    final List<MarkedPassage> marks = (read as Ok<List<MarkedPassage>>).value;

    if (marks.isEmpty) {
      // Refused rather than written. A file with a heading and nothing under it
      // is not the reader's data; it is a file they now have to delete.
      return Result<String?>.error(
        AppException(
          kind: ErrorKind.failedPrecondition,
          // Diagnostic and never shown: what the reader sees is chosen from
          // the code, out of the ARB.
          message: 'there is nothing marked to export', // l10n-ignore
          code: codeNothingToExport,
          op: opExport,
        ),
      );
    }

    try {
      return Result<String?>.ok(
        await files.save(
          suggestedName: exportFileName(request.format),
          mimeType: request.format.mediaType,
          bytes: exportBytes(
            marks,
            format: request.format,
            words: request.words,
            at: _now(),
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      _log.warning('the marks could not be exported', error, stackTrace);

      return Result<String?>.error(
        AppException(
          kind: ErrorKind.internal,
          // Diagnostic, as every message in this vocabulary is.
          message: 'the marks could not be written to a file', // l10n-ignore
          op: opExport,
          cause: error,
        ),
      );
    }
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
    export.dispose();
    super.dispose();
  }
}

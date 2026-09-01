/// What the reader's screen knows.
///
/// **It owns the host.** A host is a webview and a book: one per screen, and
/// disposed with it. That is why the provider graph holds an `EpubHostFactory`
/// rather than an `EpubHost`, and why this view model is the thing that creates
/// one — exactly as the library's view model holds a `FilePicker` rather than
/// the screen reaching for a file dialog.
///
/// **The page is the host's and everything around it is Flutter's.** The bar,
/// the contents, the progress and the controls are widgets over the view, never
/// markup inside it, so that the parts of the reader which are not the book are
/// localized, themed and tested like the rest of the application. A table of
/// contents rendered by epub.js would be a second design system and an
/// untranslatable one.
///
/// **Opening is a `Command` and so is everything else.** A book that will not
/// open is the ordinary case — the file is not on this device, the format is
/// one this build does not render — and each of those is a sentence the screen
/// can say rather than a spinner that never stops.
///
/// **The marks on the page are a stream reconciled against the paint.** What is
/// drawn is decided by the list the repository answers with and never by the
/// gesture that made a mark, so a highlight made on a phone appears here when
/// it synchronizes and one removed anywhere leaves the page — and the redraw
/// after a re-open costs the same as the first draw. That is the reason
/// `EpubHost.draw` is specified as idempotent per range.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../data/services/storage/reader_settings_store.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/ebook.dart';
import '../../../utils/command.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';

final _log = loggerFor('ui/reader');

/// How long a reader stays on a page before it is worth recording.
///
/// A position written per page turn would be an operation per turn — a log
/// nobody wants, pushed to a node nobody asked, and a vector clock ticking
/// through a chapter. What a resumed book actually needs is the page somebody
/// stopped on, and somebody who stopped has been still for longer than this.
///
/// Three seconds is short enough that a reader interrupted by a phone call
/// keeps their place and long enough that flicking through a chapter writes
/// once.
const Duration readingPositionDebounce = Duration(seconds: 3);

/// How solid a mark is painted over the page.
///
/// A highlight a reader cannot read through is a highlight that hid the
/// sentence it was about, which is the one thing it was for.
const double readerMarkOpacity = 0.35;

/// The state of the reader's screen.
final class ReaderViewModel extends ChangeNotifier {
  /// The view model over [reading], showing the work [ebookId] names in a host
  /// [hosts] makes.
  ReaderViewModel({
    required this.reading,
    required this.annotations,
    required this.hosts,
    required this.settings,
    required this.ebookId,
    this.debounce = readingPositionDebounce,
  }) : host = hosts.create() {
    open = Command0<void>(_open);
    turnForward = Command0<void>(() => _guard(host.nextPage));
    turnBack = Command0<void>(() => _guard(host.previousPage));
    goTo = Command1<void, String>(_goTo);
    highlight = Command0<Annotation>(_highlight);
    removeMark = Command1<void, String>(_removeMark);
    restoreMark = Command1<void, String>(_restoreMark);

    _positions = host.positions.listen(_onPosition);
    _selections = host.selections.listen(_onSelection);
    _marks = annotations
        .watchMarksIn(ebookId)
        .listen(_onMarks, onError: _onMarksError);

    // Opened at once rather than on a gesture. A reader who tapped a book has
    // already asked for it, and a screen that waited for a second tap would be
    // asking them to confirm the thing they just did.
    unawaited(open.execute());
  }

  /// Where the book comes from.
  final ReadingRepository reading;

  /// What the reader has marked in it.
  ///
  /// It is a second repository beside the first and not a method on it, for the
  /// reason the two exist apart: this screen is one open book, and a mark
  /// outlives it.
  final AnnotationRepository annotations;

  /// What makes a host. It is a factory because a host owns a webview and a
  /// book, so there is one per screen.
  final EpubHostFactory hosts;

  /// Where the reader's typography is remembered between two runs.
  ///
  /// It is a store and not a repository, because what it holds does not
  /// replicate and never reaches a node: `shared_preferences` beside the
  /// window's size, for the reason `architecture.md` gives there.
  final ReaderSettingsStore settings;

  /// The work being read.
  final String ebookId;

  /// How long a page is held before its position is recorded.
  ///
  /// A parameter so that a test can say what it expects rather than wait three
  /// seconds for it.
  final Duration debounce;

  /// The engine, and this platform's DOM for it.
  ///
  /// The screen places `host.view()` and asks this object for nothing else:
  /// every command a control is bound to is on this view model, so a widget
  /// never holds a service.
  final EpubHost host;

  /// UC04. Opens the book.
  late final Command0<void> open;

  /// The next page, and the previous one.
  late final Command0<void> turnForward;

  /// As [turnForward], backwards.
  late final Command0<void> turnBack;

  /// Moves to a CFI or to a chapter from [chapters].
  late final Command1<void, String> goTo;

  /// UC05. Marks the passage the reader has selected.
  ///
  /// It answers with the mark as the replica now holds it, so that the screen
  /// can offer to undo the one it just made rather than the most recent one it
  /// happens to be showing.
  late final Command0<Annotation> highlight;

  /// UC05. Removes a mark.
  late final Command1<void, String> removeMark;

  /// UC05. Brings a removed mark back.
  late final Command1<void, String> restoreMark;

  StreamSubscription<EpubPosition>? _positions;
  StreamSubscription<EpubSelection>? _selections;
  StreamSubscription<Result<List<Annotation>>>? _marks;
  Timer? _pending;
  EpubPosition? _unsaved;

  Ebook? _work;
  EpubStyle _style = const EpubStyle();
  List<EpubChapter> _chapters = const <EpubChapter>[];
  EpubPosition? _position;
  EpubSelection? _selection;
  List<Annotation> _annotations = const <Annotation>[];
  final Map<String, AnnotationKind?> _painted = <String, AnnotationKind?>{};
  bool _opened = false;
  bool _chromeVisible = true;
  bool _disposed = false;

  /// The record, for the chrome. `null` until it has been read.
  ///
  /// The title shown is this one and deliberately not the book's own: the
  /// reader may have corrected it, and RF05 is what let them.
  Ebook? get work => _work;

  /// The book's table of contents, empty until the engine has parsed it and
  /// for a book that has none.
  List<EpubChapter> get chapters => _chapters;

  /// Where the reader is, or `null` before the first page has been laid out.
  EpubPosition? get position => _position;

  /// What the reader has selected, or `null` where they have selected nothing.
  ///
  /// A selection is not a mark and does not survive the screen: it is a
  /// gesture in progress, and what turns it into something replicated is
  /// [highlight].
  EpubSelection? get selection => _selection;

  /// What the reader has marked in this book, most recent first.
  List<Annotation> get marks => _annotations;

  /// Forgets the selection, which is what a reader who changed their mind did.
  ///
  /// The engine is not asked to clear anything. What it reported is a range the
  /// reader made with their own finger, and an app that unmade it would be
  /// undoing a gesture rather than declining to act on one.
  void dismissSelection() {
    if (_selection != null) {
      _selection = null;
      notifyListeners();
    }
  }

  /// How the page is laid out, as this device was left.
  EpubStyle get style => _style;

  /// Applies [style] to the page and remembers it.
  ///
  /// The order matters and is the reason this is not two calls at the sheet:
  /// the page is restyled first, so a reader sees the result of the tap they
  /// just made, and the preference is written after. A write that failed would
  /// leave a reader with the size they chose for this session and the old one
  /// tomorrow, which is the right way round for a value nothing depends on.
  ///
  /// It is a method and not a `Command`, deliberately. A `Command` carries
  /// *running* so that a button can disable itself, and a control that greyed
  /// out while the type size was being applied would flicker under a reader
  /// stepping through sizes — which is exactly how this control is used.
  Future<void> restyle(EpubStyle style) async {
    if (style == _style) {
      return;
    }

    _style = style;
    notifyListeners();

    try {
      await host.apply(style);
    } on Exception catch (error) {
      _log.warning('the page could not be restyled', error);
    }

    await settings.write(style);
  }

  /// How far through, 0 to 1, for a control that wants a fraction.
  double get progress => (_position?.percent ?? 0) / 100;

  /// Whether the bar and the controls are showing.
  ///
  /// They start visible and get out of the way on a tap, rather than starting
  /// hidden: a reader who has just opened a book needs the way back more than
  /// they need the four lines the bar covers.
  bool get chromeVisible => _chromeVisible;

  /// Shows the chrome, or hides it.
  void toggleChrome() {
    _chromeVisible = !_chromeVisible;
    notifyListeners();
  }

  /// Shows the chrome, whatever it was doing.
  ///
  /// It is what a page turn by keyboard calls: a reader who is navigating is a
  /// reader who wants to see where they are.
  void showChrome() {
    if (!_chromeVisible) {
      _chromeVisible = true;
      notifyListeners();
    }
  }

  Future<Result<void>> _open() async {
    // Read before the book, so that the first page a reader sees is at the
    // size they chose rather than at the default for an instant.
    _style = await settings.read();

    final Result<EpubBook> book = await reading.openBook(ebookId);

    switch (book) {
      case Error<EpubBook>(:final Exception error):
        return Result<void>.error(error);
      case Ok<EpubBook>(:final EpubBook value):
        // The record is read alongside and its failure is not fatal: a chrome
        // with no title above a book that opened is worse than nothing to look
        // at, but it is not a reason to refuse the book.
        final Result<Ebook?> record = await reading.ebook(ebookId);

        if (record case Ok<Ebook?>(value: final Ebook? work)) {
          _work = work;
        }

        try {
          await host.apply(_style);
          await host.open(value);
        } on Exception catch (error) {
          return Result<void>.error(error);
        }

        // Asked for after the book is open, because that is when the engine has
        // parsed the navigation document. A book with none answers empty, which
        // is a book with no contents and not a failure.
        _chapters = await host.chapters();

        if (_disposed) {
          return const Result<void>.ok(null);
        }

        // The page exists now, so whatever the repository has already said can
        // be painted. Marks arriving before this point are held rather than
        // drawn: a mark drawn into an engine with no book in it is a call that
        // fails for a reason nobody could act on.
        _opened = true;
        _painted.clear();
        unawaited(_repaint());

        notifyListeners();

        return const Result<void>.ok(null);
    }
  }

  /// Marks the passage the reader has selected.
  Future<Result<Annotation>> _highlight() async {
    final EpubSelection? selected = _selection;

    if (selected == null) {
      // Nothing is selected, so there is nothing to mark. It is reachable only
      // by a control that outlived the selection it was offered for, and the
      // honest answer is a refusal rather than a mark over an empty range.
      return Result<Annotation>.error(
        AppException(
          kind: ErrorKind.failedPrecondition,
          // Diagnostic and never shown: `errors.dart` says the message names
          // hosts and identifiers freely because it is written to the log, and
          // what a reader sees is chosen from the kind and the code.
          message: 'nothing is selected in $ebookId', // l10n-ignore
          op: 'ui/reader: highlight',
        ),
      );
    }

    final Result<Annotation> made = await annotations.highlight(
      ebookId: ebookId,
      cfiRange: selected.cfiRange,
      passage: selected.text,
    );

    if (made is Ok<Annotation>) {
      // Cleared on success only. A selection dropped after a failure would
      // leave the reader with nothing to try again on.
      dismissSelection();
    }

    return made;
  }

  Future<Result<void>> _removeMark(String annotationId) =>
      annotations.removeMark(annotationId);

  Future<Result<void>> _restoreMark(String annotationId) =>
      annotations.restoreMark(annotationId);

  void _onSelection(EpubSelection selection) {
    _selection = selection;
    // A reader who has just selected something is about to act on it, and the
    // controls they would act with are in the chrome.
    _chromeVisible = true;
    notifyListeners();
  }

  void _onMarks(Result<List<Annotation>> marks) {
    switch (marks) {
      case Error<List<Annotation>>(:final Exception error):
        _onMarksError(error);
      case Ok<List<Annotation>>(:final List<Annotation> value):
        _annotations = value;
        notifyListeners();
        unawaited(_repaint());
    }
  }

  void _onMarksError(Object error) {
    // Not shown. The book is on screen and readable; what is missing is the
    // paint over it, and an error banner across a page because a highlight did
    // not draw would be worse than the thing it reports.
    _log.warning('the marks in $ebookId could not be read', error);
  }

  /// Brings the page's paint in line with the list.
  ///
  /// It draws what is not drawn, erases what is no longer in the list, and
  /// redraws a mark whose kind changed — which is what happens when a highlight
  /// is given words and becomes a note. Nothing here remembers a gesture: the
  /// list is the truth, so a mark that arrived by synchronization is painted by
  /// exactly the same code as one made on this device a second ago.
  Future<void> _repaint() async {
    if (!_opened || _disposed) {
      return;
    }

    final Map<String, AnnotationKind?> wanted = <String, AnnotationKind?>{
      for (final Annotation mark in _annotations)
        // A bookmark is a position and covers no range, so there is nothing to
        // paint over. It is shown in the chrome instead.
        if (mark.kind != AnnotationKind.bookmark) mark.locator: mark.kind,
    };

    try {
      for (final String range in _painted.keys.toList()) {
        if (wanted[range] != _painted[range]) {
          await host.erase(range);
        }
      }

      for (final MapEntry<String, AnnotationKind?> mark in wanted.entries) {
        if (_painted[mark.key] != mark.value) {
          await host.draw(
            EpubMark(
              cfiRange: mark.key,
              color: mark.value == AnnotationKind.note
                  ? atrilNote
                  : atrilHighlight,
              opacity: readerMarkOpacity,
            ),
          );
        }
      }

      _painted
        ..clear()
        ..addAll(wanted);
    } on Exception catch (error) {
      // The paint is out of step with the list and the next emission will try
      // again. What has been drawn so far is forgotten rather than assumed, so
      // that the retry is a full redraw and not a diff against a lie.
      _painted.clear();
      _log.warning('the marks in $ebookId could not be drawn', error);
    }
  }

  Future<Result<void>> _goTo(String locator) =>
      _guard(() => host.goTo(locator));

  /// Runs [action] against the host and turns its failure into a value.
  ///
  /// The host is a service and services throw, which `architecture.md` states
  /// and `epub_host.dart` repeats: a failure becomes a value at the layer
  /// boundary, and for the reader that boundary is here. A `Command` is what
  /// carries it the rest of the way to a control.
  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();

      return const Result<void>.ok(null);
    } on Exception catch (error) {
      _log.warning('the reader of $ebookId refused a command', error);

      return Result<void>.error(error);
    }
  }

  void _onPosition(EpubPosition position) {
    _position = position;
    notifyListeners();

    // The page the reader is on now, waiting to see whether they stay on it.
    // Each turn replaces the last rather than queueing behind it, so a reader
    // flicking through a chapter writes one operation and not thirty.
    _unsaved = position;
    _pending?.cancel();
    _pending = Timer(debounce, () => unawaited(_savePosition()));
  }

  /// Records where the reader stopped, if they have moved since the last time.
  ///
  /// It is called by the debounce and again when the screen closes, and the
  /// second is not redundant: a reader who opens a book, reads one page and
  /// leaves within the debounce would otherwise lose the only thing this
  /// screen was for.
  Future<void> _savePosition() async {
    final EpubPosition? position = _unsaved;

    if (position == null) {
      return;
    }

    // Cleared before the write and not after, so that a write still in flight
    // when the screen closes is not repeated by the close.
    _unsaved = null;
    _pending?.cancel();
    _pending = null;

    final Result<void> written = await reading.saveProgress(
      ebookId: ebookId,
      locator: position.startCfi,
      percent: position.percent,
    );

    if (written case Error<void>(:final Exception error)) {
      // Not shown to the reader. They are reading, the page is on screen, and
      // the next turn will try again — an error banner over a book because a
      // bookmark did not save would be worse than the thing it reports.
      _log.warning('the position in $ebookId was not recorded', error);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pending?.cancel();
    // The last page, written on the way out. A reader who read one page and
    // closed the book within the debounce still comes back to it.
    unawaited(_savePosition());
    unawaited(_positions?.cancel());
    unawaited(_selections?.cancel());
    unawaited(_marks?.cancel());
    unawaited(host.dispose());
    open.dispose();
    turnForward.dispose();
    turnBack.dispose();
    goTo.dispose();
    highlight.dispose();
    removeMark.dispose();
    restoreMark.dispose();
    super.dispose();
  }
}

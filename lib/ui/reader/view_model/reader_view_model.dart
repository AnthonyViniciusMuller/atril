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
import 'mark_painter.dart';

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

/// The operation an open reports a failure under.
const String opReaderOpen = 'ui/reader: open';

/// The operation a command against the host reports a failure under.
const String opReaderCommand = 'ui/reader: command';

/// [error] as the failure this layer carries, under [op].
///
/// The catches around the host are `on Object` and not `on Exception`, and
/// that is the boundary rule rather than defensiveness: a bridge answering
/// with a shape nobody expected raises a `TypeError`, which is an `Error` and
/// not an `Exception`, and the narrower catch let it out of the `Command` —
/// an unhandled error in the zone, over a book that had merely failed to open.
/// The kind is read from the error rather than guessed at, so a
/// `TimeoutException` from the host stays a deadline.
AppException _failureOf(Object error, String op) => error is AppException
    ? error
    : AppException(
        kind: AppException.kindOf(error),
        // Diagnostic and never shown: the screen chooses its sentence from the
        // kind and the code, which is what keeps this file free of language.
        message: '$error', // l10n-ignore
        op: op,
        cause: error,
      );

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
    this.at,
    this.debounce = readingPositionDebounce,
  }) : host = hosts.create() {
    open = Command0<void>(_open);
    turnForward = Command0<void>(() => _guard(host.nextPage));
    turnBack = Command0<void>(() => _guard(host.previousPage));
    goTo = Command1<void, String>(_goTo);
    highlight = Command0<Annotation>(_highlight);
    note = Command1<Annotation, String>(_note);
    toggleBookmark = Command0<void>(_toggleBookmark);
    removeMark = Command1<void, String>(_removeMark);
    restoreMark = Command1<void, String>(_restoreMark);

    _positions = host.positions.listen(_onPosition);
    _selections = host.selections.listen(_onSelection);
    _pageEvents = host.pageEvents.listen(_onPageEvent);
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

  /// Where in it to open, or `null` to let the host open where it opens.
  ///
  /// It is what a mark navigates back to, and it crosses this layer unchanged
  /// like every other locator. A CFI that no longer resolves is not a failure:
  /// the host opens at the beginning and reports that as the position, which
  /// is a book that changed under a mark rather than an error to apologize for.
  final String? at;

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

  /// UC05. Marks the selected passage and says something about it.
  ///
  /// The argument is what the reader wrote, which the contract requires a note
  /// to carry: a note with nothing in it is the highlight they already had.
  late final Command1<Annotation, String> note;

  /// UC05. Marks the page the reader is on, or unmarks it.
  ///
  /// One command and not two, because it is one control: a reader looking at a
  /// filled bookmark expects tapping it to empty it.
  late final Command0<void> toggleBookmark;

  /// UC05. Removes a mark.
  late final Command1<void, String> removeMark;

  /// UC05. Brings a removed mark back.
  late final Command1<void, String> restoreMark;

  StreamSubscription<EpubPosition>? _positions;
  StreamSubscription<EpubSelection>? _selections;
  StreamSubscription<EpubPageEvent>? _pageEvents;
  StreamSubscription<Result<List<Annotation>>>? _marks;
  Timer? _pending;
  EpubPosition? _unsaved;

  Ebook? _work;
  EpubStyle _style = const EpubStyle();
  List<EpubChapter> _chapters = const <EpubChapter>[];
  EpubPosition? _position;
  EpubSelection? _selection;
  List<Annotation> _annotations = const <Annotation>[];
  late final MarkPainter _painter = MarkPainter(host);
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

  /// The bookmark on the page the reader is looking at, or `null` where there
  /// is none.
  ///
  /// **The page is matched by the locator, exactly.** A CFI is compared as text
  /// and never parsed, because parsing one here would be the second CFI
  /// implementation `architecture.md` forbids. What that costs is small and
  /// worth saying: the engine reports the same start for the same page in the
  /// same layout, so a bookmark made at one type size is not recognized as
  /// *this page* at another — it is still in the list, still navigates to the
  /// right passage, and the control simply offers to make a new one.
  Annotation? get bookmarkHere {
    final EpubPosition? here = _position;

    if (here == null) {
      return null;
    }

    for (final Annotation mark in _annotations) {
      if (mark.kind == AnnotationKind.bookmark &&
          mark.locator == here.startCfi) {
        return mark;
      }
    }

    return null;
  }

  /// Whether the page the reader is on has been bookmarked.
  bool get pageBookmarked => bookmarkHere != null;

  /// Whether there is a page to bookmark at all.
  ///
  /// There is not until the engine has laid one out and said where it starts,
  /// which is what the control is disabled on: a bookmark with no position is
  /// a mark on nothing.
  bool get canBookmark => _position != null;

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
    } on Object catch (error) {
      _log.warning('the page could not be restyled', error);
    }

    await settings.write(style);
  }

  /// How far through, 0 to 1, for a control that wants a fraction, or `null`
  /// where the engine has not said how far through this is.
  ///
  /// It is absent for the whole of a large book's first minutes, while the
  /// engine builds the location index a percentage is derived from, and
  /// [epubPercentOf] argues why that is reported as nothing rather than as
  /// zero. The chrome shows the bar either way and prints the number only
  /// when there is one.
  double? get progress {
    final double? percent = _position?.percent;

    return percent == null ? null : percent / 100;
  }

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
        return _refused(error);
      case Ok<EpubBook>(:final EpubBook value):
        // The record is read alongside and its failure is not fatal: a chrome
        // with no title above a book that opened is worse than nothing to look
        // at, but it is not a reason to refuse the book.
        final Result<Ebook?> record = await reading.ebook(ebookId);

        if (record case Ok<Ebook?>(value: final Ebook? work)) {
          _work = work;
        }

        // Where the route said, and otherwise where this device stopped. A
        // mark the reader followed is an instruction and wins; nothing in the
        // location means *open this book*, and the answer to that is the page
        // they were on. Without this the position was recorded faithfully and
        // read by nothing, so every open started at page one.
        final String? start = at ?? await _resumeAt();

        if (_disposed) {
          return const Result<void>.ok(null);
        }

        try {
          await host.apply(_style);
          await host.open(value, at: start);
        } on Object catch (error) {
          return _refused(_failureOf(error, opReaderOpen));
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
        _painter.forget();
        unawaited(_repaint());

        notifyListeners();

        return const Result<void>.ok(null);
    }
  }

  /// Where this device stopped in this book, or `null`.
  ///
  /// A failure is not one: the book opens at the beginning, which is where it
  /// opened before anything remembered a position at all, and refusing to show
  /// a reader their book because the app could not remember their page would
  /// be the wrong way round.
  Future<String?> _resumeAt() async {
    final Result<String?> place = await reading.resumeAt(ebookId);

    switch (place) {
      case Ok<String?>(:final String? value):
        return value;
      case Error<String?>(:final Exception error):
        _log.warning('where $ebookId was left could not be read', error);

        return null;
    }
  }

  /// Records why the book did not open, and hands the failure on.
  ///
  /// The log is the only place the diagnostic message goes. The screen chooses
  /// its sentence from the code, for the reason `errors.dart` gives: the
  /// message names identifiers, it is written in whatever language the layer
  /// that raised it was written in — the hosts write English — and a reader
  /// shown it would be reading somebody's debugging.
  Result<void> _refused(Exception error) {
    _log.warning('$ebookId did not open', error);

    return Result<void>.error(error);
  }

  Future<Result<Annotation>> _highlight() => _mark(
    (EpubSelection selected) => annotations.highlight(
      ebookId: ebookId,
      cfiRange: selected.cfiRange,
      passage: selected.text,
    ),
  );

  Future<Result<Annotation>> _note(String text) => _mark(
    (EpubSelection selected) => annotations.note(
      ebookId: ebookId,
      cfiRange: selected.cfiRange,
      text: text,
    ),
  );

  /// Marks the passage the reader has selected, in whichever way [made] says.
  ///
  /// The two kinds differ in one line and share the rest, and the rest is what
  /// matters: the range comes from the selection and never from anywhere else,
  /// and the selection survives a refusal.
  Future<Result<Annotation>> _mark(
    Future<Result<Annotation>> Function(EpubSelection selected) made,
  ) async {
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
          op: 'ui/reader: mark',
        ),
      );
    }

    final Result<Annotation> mark = await made(selected);

    if (mark is Ok<Annotation>) {
      // Cleared on success only. A selection dropped after a failure would
      // leave the reader with nothing to try again on.
      dismissSelection();
    }

    return mark;
  }

  /// Marks the page the reader is on, or takes the mark off it.
  Future<Result<void>> _toggleBookmark() async {
    final Annotation? here = bookmarkHere;

    if (here != null) {
      return annotations.removeMark(here.id);
    }

    final EpubPosition? position = _position;

    if (position == null) {
      return Result<void>.error(
        AppException(
          kind: ErrorKind.failedPrecondition,
          // Diagnostic and never shown, as every message here is.
          message: 'no page has been laid out in $ebookId', // l10n-ignore
          op: 'ui/reader: bookmark',
        ),
      );
    }

    final Result<Annotation> made = await annotations.bookmark(
      ebookId: ebookId,
      // The start of the page and not its end, for the reason a reading
      // position is written from the start: somebody coming back wants the page
      // they marked rather than the one after it.
      locator: position.startCfi,
    );

    return switch (made) {
      Ok<Annotation>() => const Result<void>.ok(null),
      Error<Annotation>(:final Exception error) => Result<void>.error(error),
    };
  }

  Future<Result<void>> _removeMark(String annotationId) =>
      annotations.removeMark(annotationId);

  Future<Result<void>> _restoreMark(String annotationId) =>
      annotations.restoreMark(annotationId);

  /// What the reader did on the page itself.
  ///
  /// **It goes to the same commands the chrome's buttons go to**, which is the
  /// point of routing it here rather than into the widget that drew the page: a
  /// page turned by the arrow key inside a webview, by the arrow key in
  /// Flutter, and by the chevron in the bar are one path with three ways in.
  ///
  /// The screen's own key handler covers the case where Flutter has focus, and
  /// the two cannot both fire for one press: a key reaches whichever document
  /// has focus, and that is either the page or the app.
  void _onPageEvent(EpubPageEvent event) {
    switch (event) {
      case EpubPageEvent.tapped:
        toggleChrome();
      case EpubPageEvent.forward:
        showChrome();
        unawaited(turnForward.execute());
      case EpubPageEvent.back:
        showChrome();
        unawaited(turnBack.execute());
      case EpubPageEvent.dismiss:
        toggleChrome();
    }
  }

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
  /// The diff itself is [MarkPainter]'s, which owns the one piece of state it
  /// needs — what is on the page — and has its own test. What is left here is
  /// when to run it and what to do when it fails, and the answer to the second
  /// is a log line: the book is on screen and readable, what is missing is the
  /// paint over it, and an error banner across a page because a highlight did
  /// not draw would be worse than the thing it reports.
  Future<void> _repaint() async {
    if (!_opened || _disposed) {
      return;
    }

    try {
      await _painter.reconcile(_annotations);
    } on Object catch (error) {
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
    } on Object catch (error) {
      _log.warning('the reader of $ebookId refused a command', error);

      return Result<void>.error(_failureOf(error, opReaderCommand));
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
    unawaited(_pageEvents?.cancel());
    unawaited(_marks?.cancel());
    unawaited(host.dispose());
    open.dispose();
    turnForward.dispose();
    turnBack.dispose();
    goTo.dispose();
    highlight.dispose();
    note.dispose();
    toggleBookmark.dispose();
    removeMark.dispose();
    restoreMark.dispose();
    super.dispose();
  }
}

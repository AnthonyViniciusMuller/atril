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
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../data/services/storage/reader_settings_store.dart';
import '../../../domain/models/ebook.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

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

/// The state of the reader's screen.
final class ReaderViewModel extends ChangeNotifier {
  /// The view model over [reading], showing the work [ebookId] names in a host
  /// [hosts] makes.
  ReaderViewModel({
    required this.reading,
    required this.hosts,
    required this.settings,
    required this.ebookId,
    this.debounce = readingPositionDebounce,
  }) : host = hosts.create() {
    open = Command0<void>(_open);
    turnForward = Command0<void>(() => _guard(host.nextPage));
    turnBack = Command0<void>(() => _guard(host.previousPage));
    goTo = Command1<void, String>(_goTo);

    _positions = host.positions.listen(_onPosition);

    // Opened at once rather than on a gesture. A reader who tapped a book has
    // already asked for it, and a screen that waited for a second tap would be
    // asking them to confirm the thing they just did.
    unawaited(open.execute());
  }

  /// Where the book comes from.
  final ReadingRepository reading;

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

  StreamSubscription<EpubPosition>? _positions;
  Timer? _pending;
  EpubPosition? _unsaved;

  Ebook? _work;
  EpubStyle _style = const EpubStyle();
  List<EpubChapter> _chapters = const <EpubChapter>[];
  EpubPosition? _position;
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

        notifyListeners();

        return const Result<void>.ok(null);
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
    unawaited(host.dispose());
    open.dispose();
    turnForward.dispose();
    turnBack.dispose();
    goTo.dispose();
    super.dispose();
  }
}

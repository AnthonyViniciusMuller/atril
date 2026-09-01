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
import '../../../domain/models/ebook.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/reader');

/// The state of the reader's screen.
final class ReaderViewModel extends ChangeNotifier {
  /// The view model over [reading], showing the work [ebookId] names in a host
  /// [hosts] makes.
  ReaderViewModel({
    required this.reading,
    required this.hosts,
    required this.ebookId,
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

  /// The work being read.
  final String ebookId;

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

  Ebook? _work;
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
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_positions?.cancel());
    unawaited(host.dispose());
    open.dispose();
    turnForward.dispose();
    turnBack.dispose();
    goTo.dispose();
    super.dispose();
  }
}

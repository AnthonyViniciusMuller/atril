/// The reader: a page from the engine, with the app's own chrome over it.
///
/// **Everything except the page is a Flutter widget**, and each part of the
/// chrome lives in its own file beside this one — the bar and the progress, the
/// contents, the selection's actions, the note dialog. What is left here is the
/// screen: the view model it owns, the host's view built once, and the keyboard.
///
/// **The page is built once and never rebuilt.** It is a webview on five
/// targets and a CEF texture on the sixth, and it is mounted from the first
/// frame because both hosts complete `open()` from a callback of the widget it
/// builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../data/services/storage/reader_settings_store.dart';
import '../view_model/reader_view_model.dart';
import 'reader_body.dart';
import 'reader_chrome.dart';
import 'selection_actions.dart';

/// The reader.
class ReaderScreen extends StatefulWidget {
  /// Creates the reader of the work [ebookId] names, opened [at].
  const ReaderScreen({required this.ebookId, this.at, super.key});

  /// The work, from the location.
  final String ebookId;

  /// Where in it to open, from the location, or `null` to resume where this
  /// device stopped.
  ///
  /// It is what a mark navigates back to. A locator that no longer resolves is
  /// not a failure — the host opens at the beginning instead — so nothing here
  /// validates it.
  final String? at;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderViewModel _model = ReaderViewModel(
    reading: context.read<ReadingRepository>(),
    annotations: context.read<AnnotationRepository>(),
    hosts: context.read<EpubHostFactory>(),
    settings: context.read<ReaderSettingsStore>(),
    ebookId: widget.ebookId,
    at: widget.at,
  );

  /// The host's view, built once and held.
  ///
  /// **It is the one widget on this screen that must not be rebuilt.** It is a
  /// platform view — a webview on five targets and a CEF texture on the sixth —
  /// and asking for a new one is asking the framework to consider replacing a
  /// browser with a book in it. Everything else here is chrome over it, and
  /// what a page turn or a selection changes is the chrome.
  late final Widget _page = _model.host.view();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Turns a page from the keyboard.
  ///
  /// A desktop reader turns pages with the arrow keys and the space bar, and a
  /// browser one expects the same. It is here rather than inside the engine
  /// because the webview does not always have focus — on Linux the page is a
  /// texture and the key events reach the Flutter view first.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Not a `const` set: `LogicalKeyboardKey` overrides `==`, which Dart
    // refuses in a constant set because the equality it would use is the
    // identity one.
    final Set<LogicalKeyboardKey> forward = <LogicalKeyboardKey>{
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.pageDown,
      LogicalKeyboardKey.space,
    };
    final Set<LogicalKeyboardKey> back = <LogicalKeyboardKey>{
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.pageUp,
    };

    if (forward.contains(event.logicalKey)) {
      _model.showChrome();
      _model.turnForward.execute();

      return KeyEventResult.handled;
    }

    if (back.contains(event.logicalKey)) {
      _model.showChrome();
      _model.turnBack.execute();

      return KeyEventResult.handled;
    }

    // Escape is what a tap is, for somebody who is not tapping. Every other
    // way to clear the chrome is a gesture on the page, which is a keyboard
    // reader's one unreachable control — and on a desktop the page is where
    // the whole window is.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _model.toggleChrome();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// The screen, with **no listener above the page**.
  ///
  /// One `ListenableBuilder` used to wrap the whole scaffold, so every page
  /// turn, every selection and every mark that arrived by synchronization
  /// rebuilt the platform view along with the four widgets that had actually
  /// changed. The listeners are inside the chrome now, one per thing that
  /// changes, and the page is built once above them.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The book decides what colour a page is, so the scaffold behind it is
      // black and never the theme's surface: a light strip down the side of a
      // dark page is the app showing through its own reader.
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ReaderBody(model: _model, page: _page),
            ),
            ReaderChrome(model: _model),
            // Above the chrome and outside it, deliberately. A reader who
            // has selected a passage has asked a question the app must
            // answer, and a tap that hid the page controls should not take
            // the answer away with them.
            SelectionActions(model: _model),
          ],
        ),
      ),
    );
  }
}

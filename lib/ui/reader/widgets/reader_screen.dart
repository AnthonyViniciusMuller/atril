/// The book, and the chrome that gets out of its way.
///
/// **Everything here except the page is a Flutter widget.** The bar, the
/// contents, the progress and the page controls are laid over the host's view
/// and never rendered inside it. That is not a stylistic choice: markup inside
/// the webview would be a second design system, outside the theme, outside the
/// ARB, and unreachable by a widget test — and it would be drawn by the engine
/// whose one job is to render somebody else's book.
///
/// **The chrome starts visible and hides on a tap.** The opposite — a bare page
/// a reader has to discover the controls on — assumes they know where they are.
/// A reader who has just opened a book needs the way back more than they need
/// the four lines the bar covers, and once they are reading, one tap clears it.
///
/// **The three ways a book does not open are three sentences, not one.** The
/// file is not on this device; the format is one this build does not render;
/// something failed. The first is an offer, the second is a fact about the
/// build that leaves the rest of the book's life intact, and only the third is
/// an apology. A screen that showed one message for all three would be a screen
/// that says *something went wrong* when nothing has.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';

/// The chrome's key, so that a test can name it.
///
/// Material builds `AnimatedOpacity` widgets of its own inside a scaffold, so
/// a test finding one by type would be finding whichever came first.
const Key readerChromeKey = Key('reader chrome');

/// How long the chrome takes to appear and to leave.
///
/// Short enough not to be waited on and long enough not to flash, which is the
/// whole of what an animation over a reading surface owes anybody.
const Duration readerChromeFade = Duration(milliseconds: 150);

/// The reader.
class ReaderScreen extends StatefulWidget {
  /// Creates the reader of the work [ebookId] names.
  const ReaderScreen({required this.ebookId, super.key});

  /// The work, from the location.
  final String ebookId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderViewModel _model = ReaderViewModel(
    reading: context.read<ReadingRepository>(),
    hosts: context.read<EpubHostFactory>(),
    ebookId: widget.ebookId,
  );

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

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (BuildContext context, Widget? _) => Scaffold(
        // The book decides what colour a page is, so the scaffold behind it is
        // black and never the theme's surface: a light strip down the side of a
        // dark page is the app showing through its own reader.
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _ReaderBody(model: _model)),
              _ReaderChrome(model: _model),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page, or what is standing in for it.
class _ReaderBody extends StatelessWidget {
  const _ReaderBody({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model.open,
      builder: (BuildContext context, Widget? _) {
        if (model.open.running) {
          return const _ReaderOpening();
        }

        if (model.open.result case Error<void>(:final Exception error)) {
          return _ReaderRefusal(model: model, error: error);
        }

        // The host's own view, and a tap target over it. The gesture is here
        // and not inside the page because a tap inside the webview is the
        // book's — a reader following a footnote should follow it.
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: model.toggleChrome,
          child: model.host.view(),
        );
      },
    );
  }
}

/// What is shown while the file is read and handed over.
class _ReaderOpening extends StatelessWidget {
  const _ReaderOpening();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.readerOpening,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why the book is not on screen, and what can be done about it.
class _ReaderRefusal extends StatelessWidget {
  const _ReaderRefusal({required this.model, required this.error});

  final ReaderViewModel model;
  final Exception error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? code = error is AppException
        ? (error as AppException).code
        : null;

    final (String title, String message, Widget? action) = switch (code) {
      codeContentNotOnDevice => (
        l10n.readerNotOnDeviceTitle,
        l10n.readerNotOnDeviceMessage,
        // The way out is the book's own screen, which already owns downloading
        // and knows how to show a transfer running. A second download button
        // here would be a second implementation of a progress bar.
        FilledButton(
          onPressed: () => context.go(Routes.ebook(model.ebookId)),
          child: Text(l10n.readerDownload),
        ),
      ),
      codeFormatNotReadable => (
        l10n.readerFormatTitle,
        l10n.readerFormatMessage,
        null,
      ),
      _ => (
        l10n.readerFailedTitle,
        error is AppException
            ? (error as AppException).message
            : error.toString(),
        FilledButton(
          onPressed: model.open.execute,
          child: Text(l10n.readerRetry),
        ),
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 20),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar, the contents and the progress, over the page.
class _ReaderChrome extends StatelessWidget {
  const _ReaderChrome({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !model.chromeVisible,
      child: AnimatedOpacity(
        key: readerChromeKey,
        opacity: model.chromeVisible ? 1 : 0,
        duration: readerChromeFade,
        child: Column(
          children: <Widget>[
            _ReaderBar(model: model),
            const Spacer(),
            // The progress is a line and a sentence, not a slider. Dragging to
            // a percentage is a gesture for a book somebody is skimming, and it
            // would need a control that fights the page turn underneath it;
            // what a reader wants here is to know where they are.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: model.turnBack.execute,
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.white,
                        tooltip: l10n.readerPreviousPage,
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            LinearProgressIndicator(
                              value: model.progress,
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.readerProgress(
                                (model.progress * 100).round(),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: model.turnForward.execute,
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.white,
                        tooltip: l10n.readerNextPage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar above the page.
class _ReaderBar extends StatelessWidget {
  const _ReaderBar({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.go(Routes.ebook(model.ebookId)),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                tooltip: l10n.readerBack,
              ),
              Expanded(
                child: Text(
                  // The record's title, and deliberately not the one inside
                  // the file: the reader may have corrected it, and RF05 is
                  // what let them.
                  model.work?.title ?? '', // l10n-ignore
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () => _showContents(context, model),
                icon: const Icon(Icons.list),
                color: Colors.white,
                tooltip: l10n.readerContents,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the table of contents.
///
/// A sheet and not a drawer, because the reader is a screen without a scaffold
/// drawer and because the contents of a book is a thing you dip into and
/// dismiss rather than a second navigation surface.
Future<void> _showContents(BuildContext context, ReaderViewModel model) async {
  final String? href = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) => _ContentsSheet(model: model),
  );

  if (href != null) {
    await model.goTo.execute(href);
  }
}

/// The book's own table of contents.
class _ContentsSheet extends StatelessWidget {
  const _ContentsSheet({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (model.chapters.isEmpty) {
      // Not a failure. There are published books with no navigation document,
      // and saying which is the case is better than an empty list.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.readerContentsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.readerContentsEmptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final EpubChapter chapter in model.chapters)
              ..._entriesOf(context, chapter),
          ],
        ),
      ),
    );
  }

  /// One entry and everything beneath it, flattened with an indent.
  ///
  /// Flat and not an `ExpansionTile` per level: a contents is read by looking
  /// down it, and a reader who has to open three disclosures to reach chapter
  /// four has been given a filing cabinet.
  List<Widget> _entriesOf(
    BuildContext context,
    EpubChapter chapter, {
    int depth = 0,
  }) => <Widget>[
    ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 16),
      title: Text(
        chapter.title, // l10n-ignore
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.of(context).pop(chapter.href),
    ),
    for (final EpubChapter child in chapter.children)
      ..._entriesOf(context, child, depth: depth + 1),
  ];
}

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

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../data/services/storage/reader_settings_store.dart';
import '../../../domain/models/annotation.dart';
import '../../../routing/routes.dart';
import '../../../utils/command.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';
import 'reader_settings_sheet.dart';

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
              // Above the chrome and outside it, deliberately. A reader who
              // has selected a passage has asked a question the app must
              // answer, and a tap that hid the page controls should not take
              // the answer away with them.
              _SelectionActions(model: _model),
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
                // Disabled until the engine has laid a page out and said where
                // it starts. A bookmark with no position is a mark on nothing.
                onPressed: model.canBookmark
                    ? () => _toggleBookmark(context, model)
                    : null,
                icon: Icon(
                  model.pageBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                color: Colors.white,
                disabledColor: Colors.white30,
                tooltip: model.pageBookmarked
                    ? l10n.readerBookmarkRemove
                    : l10n.readerBookmark,
              ),
              IconButton(
                onPressed: () => showReaderSettings(context, model),
                icon: const Icon(Icons.text_fields),
                color: Colors.white,
                tooltip: l10n.readerSettings,
              ),
              IconButton(
                // Pushed rather than gone to, so that the way back from the
                // marks is the page the reader was on: closing the book to
                // look at what they wrote in it would be an odd price.
                onPressed: () => context.push(Routes.ebookMarks(model.ebookId)),
                icon: const Icon(Icons.brush_outlined),
                color: Colors.white,
                tooltip: l10n.ebookMarksOpen,
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

/// The key of the bar a selection raises, so that a test can name it.
const Key readerSelectionKey = Key('reader selection');

/// What a reader can do with the passage they have just selected.
///
/// It is a bar over the page and not a context menu, for the same reason the
/// rest of the chrome is Flutter's: a menu drawn by the engine would be
/// untranslated, unthemed and unreachable by a widget test — and on Linux it
/// would be drawn by CEF into a texture, where the application has no say over
/// it at all.
///
/// It shows only while something is selected. Nothing here polls the engine to
/// find out whether the reader has since tapped the selection away; the
/// dismissal is a control of its own, because a bar that disappeared on its own
/// timing would be a bar that vanishes as the finger reaches it.
class _SelectionActions extends StatelessWidget {
  const _SelectionActions({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final EpubSelection? selection = model.selection;

    if (selection == null) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
          child: Material(
            key: readerSelectionKey,
            color: theme.colorScheme.surfaceContainerHigh,
            elevation: 6,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => _mark(
                      context,
                      model,
                      () => model.highlight.execute(),
                      model.highlight,
                      l10n.readerHighlighted,
                    ),
                    icon: const Icon(Icons.brush_outlined),
                    label: Text(l10n.readerHighlight),
                  ),
                  TextButton.icon(
                    onPressed: () => _writeNote(context, model),
                    icon: const Icon(Icons.edit_note),
                    label: Text(l10n.readerNote),
                  ),
                  IconButton(
                    onPressed: model.dismissSelection,
                    icon: const Icon(Icons.close),
                    tooltip: l10n.readerSelectionDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs [make] over the selection, and offers to undo what it made.
///
/// The undo is offered rather than a confirmation asked for, and the asymmetry
/// is the point: marking a passage is what the reader came here to do, and a
/// dialog in front of it would be the app asking whether they meant the gesture
/// they just made. Unmaking it is one operation, because the removal is a
/// tombstone and the undo lifts it.
///
/// [command] is the same command [make] runs, read back for its result — a
/// `Command` is what carries the outcome in this app, and a second return path
/// beside it would be two answers to one question.
Future<void> _mark(
  BuildContext context,
  ReaderViewModel model,
  Future<void> Function() make,
  Command<Annotation> command,
  String announcement,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  await make();

  switch (command.result) {
    case Ok<Annotation>(:final Annotation value):
      messenger.showSnackBar(
        SnackBar(
          content: Text(announcement),
          action: SnackBarAction(
            label: l10n.readerMarkUndo,
            onPressed: () => model.removeMark.execute(value.id),
          ),
        ),
      );
    case Error<Annotation>():
      messenger.showSnackBar(SnackBar(content: Text(l10n.readerMarkFailed)));
    case null:
      break;
  }
}

/// Asks the reader what they want to say about the passage, and notes it.
///
/// A dialog and not a location, unlike every form elsewhere in this app. The
/// reason the others are locations is that a reader who switched away should
/// come back to the form; here they would come back to a *selection*, which the
/// engine will not have kept — so a note started and abandoned is a note that
/// was never made, and a route that promised otherwise would be lying.
Future<void> _writeNote(BuildContext context, ReaderViewModel model) async {
  final String? written = await showDialog<String>(
    context: context,
    builder: (BuildContext context) => const _NoteDialog(),
  );

  if (written == null || !context.mounted) {
    return;
  }

  await _mark(
    context,
    model,
    () => model.note.execute(written),
    model.note,
    AppLocalizations.of(context).readerNoted,
  );
}

/// The words a reader is putting against a passage.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.readerNoteTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.readerNoteLabel,
          // Said here rather than reported after the fact: the contract
          // requires a note to carry text, and a reader should learn that from
          // the field and not from a refusal.
          helperText: l10n.readerNoteRequired,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.readerNoteCancel),
        ),
        ListenableBuilder(
          listenable: _text,
          builder: (BuildContext context, Widget? _) => FilledButton(
            // Disabled rather than refused. The rule is the contract's and it
            // is not a surprise worth springing on somebody who has just
            // typed nothing.
            onPressed: _text.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_text.text),
            child: Text(l10n.readerNoteSave),
          ),
        ),
      ],
    );
  }
}

/// Marks the page the reader is on, or takes the mark off it.
///
/// It says which of the two happened, because the control is one button whose
/// icon has just changed under the reader's finger and a page that silently
/// gained a bookmark looks exactly like one that silently lost it.
Future<void> _toggleBookmark(
  BuildContext context,
  ReaderViewModel model,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final bool wasMarked = model.pageBookmarked;

  await model.toggleBookmark.execute();

  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (model.toggleBookmark.result) {
        Error<void>() => l10n.readerMarkFailed,
        _ => wasMarked ? l10n.readerBookmarkRemoved : l10n.readerBookmarked,
      }),
    ),
  );
}

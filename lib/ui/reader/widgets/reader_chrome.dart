/// The bar, the progress and the page controls, over the book.
///
/// **Everything here is a Flutter widget and none of it is markup inside the
/// engine.** That is not a stylistic choice: a bar drawn inside the webview
/// would be a second design system, outside the theme, outside the ARB, and
/// unreachable by a widget test — and it would be drawn by the engine whose one
/// job is to render somebody else's book.
///
/// **The chrome starts visible and hides on a tap.** A reader who has just
/// opened a book needs the way back more than they need the four lines the bar
/// covers, and once they are reading, one tap clears it.
///
/// **It listens, rather than being rebuilt by something that does.** The page
/// under it is a platform view, and a listener above both would rebuild a
/// webview to move a progress bar.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';
import 'contents_sheet.dart';
import 'over_the_page.dart';
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

/// The bar, the contents and the progress, over the page.
///
/// **It listens, rather than being rebuilt by something that does.** The
/// listener used to sit above the whole scaffold, which put the platform view
/// inside it: a page turn rebuilt the webview to move a progress bar four
/// pixels. What changes here is the chrome, so the chrome is what subscribes —
/// once for whether it is showing, and again inside the row that follows the
/// page.
///
/// The bar and the progress used to be built once and handed to every rebuild,
/// on the grounds that showing and hiding the chrome does not change what is in
/// it. It does now: whether each row takes a click away from the book is
/// exactly what showing and hiding changes, so the two rows are built inside
/// the listener. What stays outside it is the page, which is the rebuild that
/// ever mattered.
class ReaderChrome extends StatelessWidget {
  /// The chrome over the page [model] is showing.
  const ReaderChrome({required this.model, super.key});

  /// What the screen knows.
  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (BuildContext context, Widget? _) => IgnorePointer(
      ignoring: !model.chromeVisible,
      child: AnimatedOpacity(
        key: readerChromeKey,
        opacity: model.chromeVisible ? 1 : 0,
        duration: readerChromeFade,
        // **The two rows are wrapped and the space between them is not.**
        // `OverThePage` stops a click reaching the engine underneath, which is
        // what makes these controls work at all on the web — and it would do
        // the same to the whole height if the column were wrapped, so a tap
        // anywhere on the book would be swallowed by a `Spacer`.
        //
        // They stop intercepting when the chrome is out of the way, for the
        // same reason: what is faded out is not there, and a bar that kept the
        // click would leave a strip across the page that never brings it back.
        child: Column(
          children: <Widget>[
            OverThePage(
              intercepting: model.chromeVisible,
              child: _ReaderBar(model: model),
            ),
            const Spacer(),
            OverThePage(
              intercepting: model.chromeVisible,
              child: _ReaderProgress(model: model),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Where the reader is, under the page.
///
/// The progress is a line and a sentence, not a slider. Dragging to a
/// percentage is a gesture for a book somebody is skimming, and it would need a
/// control that fights the page turn underneath it; what a reader wants here is
/// to know where they are.
class _ReaderProgress extends StatelessWidget {
  const _ReaderProgress({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
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
                child: ListenableBuilder(
                  listenable: model,
                  builder: (BuildContext context, Widget? _) => Column(
                    children: <Widget>[
                      LinearProgressIndicator(
                        value: model.progress,
                        backgroundColor: Colors.white24,
                        // The bar is the only thing on this screen that says
                        // where the reader is, and to a screen reader it said
                        // nothing at all. The value is the same sentence the
                        // line under it shows: one number, one wording.
                        semanticsLabel: l10n.readingProgressLabel,
                        // The bare percentage and not the sentence beside it:
                        // the framework reads this value as a number and
                        // refuses one carrying a word.
                        semanticsValue: l10n.readingPercentValue(
                          (model.progress * 100).round(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.readerProgress((model.progress * 100).round()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
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
    );
  }
}

/// The bar above the page.
class _ReaderBar extends StatelessWidget {
  const _ReaderBar({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (BuildContext context, Widget? _) => _bar(context),
  );

  /// The bar as it stands, for whatever the model says now.
  Widget _bar(BuildContext context) {
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
                onPressed: () => showContents(context, model),
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

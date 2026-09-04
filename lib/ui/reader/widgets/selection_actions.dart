/// What a reader can do with the passage they have just selected.
///
/// It is a bar over the page and not a context menu, for the same reason the
/// rest of the chrome is Flutter's: a menu drawn by the engine would be
/// untranslated, unthemed and unreachable by a widget test — and on Linux it
/// would be drawn by CEF into a texture, where the application has no say over
/// it at all.
library;

import 'package:flutter/material.dart';

import '../../../data/services/epub/epub_host.dart';
import '../../../domain/models/annotation.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';
import 'note_dialog.dart';
import 'over_the_page.dart';

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
class SelectionActions extends StatelessWidget {
  /// The actions for whatever [model] says is selected.
  const SelectionActions({required this.model, super.key});

  /// What the screen knows.
  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (BuildContext context, Widget? _) => _actions(context),
  );

  /// The bar for the selection there is, or nothing where there is none.
  Widget _actions(BuildContext context) {
    final EpubSelection? selection = model.selection;

    if (selection == null) {
      // Nothing is drawn, so nothing is taken from the book: `OverThePage`
      // below wraps the bar and not this, and an interceptor over an empty
      // widget would be a strip of dead page.
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
          // The `Material` and not the `Align` above it: the align fills the
          // screen, and an interceptor that size would take every tap on the
          // book with it.
          child: OverThePage(
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
      // **The undo travels in the content, wrapped.** A snackbar is drawn over
      // the page like everything else here, so its action takes no click on the
      // web — and `SnackBar.action` is typed as a `SnackBarAction`, which
      // leaves nowhere to put the interceptor. Moving it into the content is
      // what lets the whole bar be wrapped at once, and a reader who cannot
      // press *undo* has been offered nothing.
      messenger.showSnackBar(
        SnackBar(
          content: OverThePage(
            child: Row(
              children: <Widget>[
                Expanded(child: Text(announcement)),
                SnackBarAction(
                  label: l10n.readerMarkUndo,
                  onPressed: () => model.removeMark.execute(value.id),
                ),
              ],
            ),
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
    // Wrapped like the sheets: a dialog over the page takes no click either,
    // and this one has a text field the reader has to be able to reach.
    builder: (BuildContext context) => const OverThePage(child: NoteDialog()),
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

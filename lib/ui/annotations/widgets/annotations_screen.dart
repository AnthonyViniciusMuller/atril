/// Everything the reader has marked, in one book or across the library.
///
/// **It is a destination and not a tab inside a book.** A highlight is worth as
/// much away from the page it was taken on as on it — that is most of what UC05
/// is for — and a reader looking for the passage about the drought does not
/// necessarily remember which of four books it was in.
///
/// **The two scopes are one screen.** *Everything I have marked* and *what I
/// marked in this book* are the same question at two widths, so the narrowing
/// is a parameter and not a second screen with the same list in it.
///
/// **Every mark leads back to its passage.** That is what the locator is for,
/// and it is the only thing in this app that opens the reader at somewhere
/// other than where the device stopped. A mark whose CFI no longer resolves
/// opens the book at the beginning, which is a book that changed under a mark
/// and not an error to apologize for.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/annotations/annotation_repository.dart';
import '../../../domain/models/annotation.dart';
import '../../../routing/routes.dart';
import '../../core/localization/localization.dart';
import '../../core/themes/colors.dart';
import '../view_model/annotations_view_model.dart';

/// The annotations screen.
class AnnotationsScreen extends StatefulWidget {
  /// Creates the screen, showing every mark or the marks in [ebookId].
  const AnnotationsScreen({super.key, this.ebookId});

  /// The work the screen is narrowed to, or `null` for the whole library.
  final String? ebookId;

  @override
  State<AnnotationsScreen> createState() => _AnnotationsScreenState();
}

class _AnnotationsScreenState extends State<AnnotationsScreen> {
  late final AnnotationsViewModel _model = AnnotationsViewModel(
    annotations: context.read<AnnotationRepository>(),
    ebookId: widget.ebookId,
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: _model,
      builder: (BuildContext context, Widget? _) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.ebookId == null
                ? l10n.navigationAnnotations
                : l10n.annotationsInThisBook,
          ),
        ),
        body: Column(
          children: <Widget>[
            _Kinds(model: _model),
            Expanded(child: _Marks(model: _model)),
          ],
        ),
      ),
    );
  }
}

/// The filter, as chips.
///
/// Chips and not a dropdown: there are four choices, they are the vocabulary of
/// the whole screen, and a control a reader has to open to see what it offers
/// is a control that hides the answer to *what can I look for*.
class _Kinds extends StatelessWidget {
  const _Kinds({required this.model});

  final AnnotationsViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<(AnnotationKind?, String)> choices = <(AnnotationKind?, String)>[
      (null, l10n.annotationsAll),
      (AnnotationKind.highlight, l10n.annotationsHighlights),
      (AnnotationKind.note, l10n.annotationsNotes),
      (AnnotationKind.bookmark, l10n.annotationsBookmarks),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          for (final (AnnotationKind?, String) choice in choices)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(choice.$2),
                selected: model.kind == choice.$1,
                onSelected: (bool _) => model.filterBy(choice.$1),
              ),
            ),
        ],
      ),
    );
  }
}

/// The marks themselves, or what is standing in for them.
class _Marks extends StatelessWidget {
  const _Marks({required this.model});

  final AnnotationsViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    if (model.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (model.failure != null && model.marks.isEmpty) {
      return _Nothing(
        title: l10n.annotationsFailedTitle,
        message: l10n.annotationsFailedMessage,
      );
    }

    if (model.isEmpty) {
      return _Nothing(
        title: model.isFiltered
            ? l10n.annotationsNoneOfThisKindTitle
            : l10n.annotationsEmptyTitle,
        message: model.isFiltered
            ? l10n.annotationsNoneOfThisKindMessage
            : l10n.annotationsEmptyMessage,
        action: model.isFiltered
            ? TextButton(
                onPressed: () => model.filterBy(null),
                child: Text(l10n.annotationsShowAll),
              )
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: model.marks.length,
      separatorBuilder: (BuildContext context, int _) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) => _MarkCard(
        model: model,
        passage: model.marks[index],
        // The book's name is what tells two highlights apart when they are
        // shown side by side, and it is noise on a screen that is already
        // about one book.
        named: model.ebookId == null,
        theme: theme,
      ),
    );
  }
}

/// One mark, and what can be done with it.
class _MarkCard extends StatelessWidget {
  const _MarkCard({
    required this.model,
    required this.passage,
    required this.named,
    required this.theme,
  });

  final AnnotationsViewModel model;
  final MarkedPassage passage;
  final bool named;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Annotation mark = passage.mark;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () =>
            context.go(Routes.readEbook(passage.work.id, at: mark.locator)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: Icon(_iconOf(mark.kind), color: _colorOf(mark.kind)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (mark.text case final String said)
                      Text(
                        // What the reader wrote for a note and the passage
                        // itself for a highlight. Neither is translated, and
                        // that is not an omission: they are the book's words
                        // and the reader's.
                        said, // l10n-ignore
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      )
                    else
                      // A bookmark says nothing, and neither does a highlight
                      // whose passage this build could not capture. Saying
                      // which kind of mark it is beats an empty card.
                      Text(
                        _nameOf(l10n, mark.kind),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      named
                          ? l10n.annotationsFromBook(
                              passage.work.title,
                              MaterialLocalizations.of(context)
                                  .formatMediumDate(
                                    mark.revision.updatedAt.toLocal(),
                                  ),
                            )
                          : MaterialLocalizations.of(context).formatMediumDate(
                              mark.revision.updatedAt.toLocal(),
                            ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _MarkMenu(model: model, mark: mark),
            ],
          ),
        ),
      ),
    );
  }
}

/// What can be done to one mark.
class _MarkMenu extends StatelessWidget {
  const _MarkMenu({required this.model, required this.mark});

  final AnnotationsViewModel model;
  final Annotation mark;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // A bookmark is a place and has nothing to say, so there is nothing to
    // write on it. A highlight and a note both do — the first gains words and
    // becomes the second, the second has its own edited.
    final bool writable = mark.kind != AnnotationKind.bookmark;

    return MenuAnchor(
      menuChildren: <Widget>[
        if (writable)
          MenuItemButton(
            onPressed: () => _write(context, model, mark),
            leadingIcon: const Icon(Icons.edit_note),
            child: Text(
              mark.kind == AnnotationKind.note
                  ? l10n.annotationsEdit
                  : l10n.annotationsAddNote,
            ),
          ),
        MenuItemButton(
          onPressed: () => _remove(context, model, mark),
          leadingIcon: const Icon(Icons.delete_outline),
          child: Text(l10n.annotationsRemove),
        ),
      ],
      builder: (BuildContext context, MenuController menu, Widget? _) =>
          IconButton(
            onPressed: () => menu.isOpen ? menu.close() : menu.open(),
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.annotationsActions,
          ),
    );
  }
}

/// Removes a mark, and offers it back.
Future<void> _remove(
  BuildContext context,
  AnnotationsViewModel model,
  Annotation mark,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  await model.remove.execute(mark.id);

  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.annotationsRemoved),
      action: SnackBarAction(
        label: l10n.annotationsUndo,
        onPressed: () => model.restore.execute(mark.id),
      ),
    ),
  );
}

/// Asks the reader what the mark should say, and says it.
///
/// The field starts at whatever the mark already holds, and for a highlight
/// that is **the passage**. It is there so that promoting a highlight to a note
/// does not quietly throw the words away: there is one text field on the record
/// and the contract says a note's belongs to the reader, so what the reader is
/// looking at when they press save is exactly what is stored.
Future<void> _write(
  BuildContext context,
  AnnotationsViewModel model,
  Annotation mark,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String? written = await showDialog<String>(
    context: context,
    builder: (BuildContext context) => _RewordDialog(mark: mark),
  );

  if (written == null) {
    return;
  }

  await model.reword.execute((id: mark.id, text: written));

  messenger.showSnackBar(SnackBar(content: Text(l10n.annotationsSaved)));
}

/// What a mark says, being changed.
class _RewordDialog extends StatefulWidget {
  const _RewordDialog({required this.mark});

  final Annotation mark;

  @override
  State<_RewordDialog> createState() => _RewordDialogState();
}

class _RewordDialogState extends State<_RewordDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.mark.text,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.annotationsNoteTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLines: 6,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.readerNoteLabel,
          helperText: widget.mark.kind == AnnotationKind.note
              ? l10n.readerNoteRequired
              : l10n.annotationsPassageGivesWay,
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

/// A screen with nothing on it, and why.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon one kind of mark is shown with.
IconData _iconOf(AnnotationKind? kind) => switch (kind) {
  AnnotationKind.note => Icons.edit_note,
  AnnotationKind.bookmark => Icons.bookmark,
  // A highlight, and a kind this build cannot name — which is a mark made by a
  // newer version of the app and is still the reader's.
  _ => Icons.brush_outlined,
};

/// The colour one kind of mark is shown in, matching the paint on the page.
Color? _colorOf(AnnotationKind? kind) => switch (kind) {
  AnnotationKind.note => atrilNote,
  AnnotationKind.highlight => atrilHighlight,
  _ => null,
};

/// What a mark with nothing to say is called.
String _nameOf(AppLocalizations l10n, AnnotationKind? kind) => switch (kind) {
  AnnotationKind.bookmark => l10n.annotationsBookmark,
  AnnotationKind.note => l10n.annotationsNote,
  AnnotationKind.highlight => l10n.annotationsHighlight,
  // A kind this build cannot name is a mark a newer version of the app made,
  // and it is still the reader's: it is listed, it navigates, and it is
  // described as what this build knows about it, which is nothing.
  null => l10n.annotationsUnknownKind,
};

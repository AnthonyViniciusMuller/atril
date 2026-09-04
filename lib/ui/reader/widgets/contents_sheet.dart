/// The book's own table of contents, as a sheet over the page.
///
/// It is a sheet and not a drawer, and it is Flutter's and not the engine's:
/// a contents rendered by epub.js would be a second design system, outside the
/// theme, outside the ARB and unreachable by a widget test.
library;

import 'package:flutter/material.dart';

import '../../../data/services/epub/epub_host.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';
import 'over_the_page.dart';

/// Opens the table of contents.
///
/// A sheet and not a drawer, because the reader is a screen without a scaffold
/// drawer and because the contents of a book is a thing you dip into and
/// dismiss rather than a second navigation surface.
Future<void> showContents(BuildContext context, ReaderViewModel model) async {
  final String? href = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Wrapped, or nothing in it can be pressed on the web: a sheet over a
    // platform view takes no click at all, and one that could be neither used
    // nor dismissed is worse than one that never opened. The drag handle is
    // inside this, which is what still closes it — the route's barrier is the
    // route's own and stays out of reach, so tapping the page behind the sheet
    // does not dismiss it there.
    builder: (BuildContext context) =>
        OverThePage(child: _ContentsSheet(model: model)),
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

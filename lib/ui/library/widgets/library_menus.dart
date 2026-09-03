/// The two menus in the shelf's bar: what order it is in, and what is on it.
library;

import 'package:flutter/material.dart';

import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../core/localization/localization.dart';
import '../view_model/library_view_model.dart';

/// The menu that chooses the order of the shelf.
class SortMenu extends StatelessWidget {
  /// The order menu over [model].
  const SortMenu({required this.model, super.key});

  /// What the shelf knows.
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<LibrarySort>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.librarySort,
      initialValue: model.query.sort,
      onSelected: model.sortBy,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<LibrarySort>>[
        PopupMenuItem<LibrarySort>(
          value: LibrarySort.recentlyImported,
          child: Text(l10n.librarySortRecent),
        ),
        PopupMenuItem<LibrarySort>(
          value: LibrarySort.title,
          child: Text(l10n.librarySortTitle),
        ),
        PopupMenuItem<LibrarySort>(
          value: LibrarySort.author,
          child: Text(l10n.librarySortAuthor),
        ),
      ],
    );
  }
}

/// The menu that narrows the shelf to one format.
class FormatMenu extends StatelessWidget {
  /// The format menu over [model].
  const FormatMenu({required this.model, super.key});

  /// What the shelf knows.
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<EbookFormat?>(
      icon: Icon(
        model.query.format == null
            ? Icons.filter_alt_outlined
            : Icons.filter_alt,
      ),
      tooltip: l10n.libraryFilterFormat,
      initialValue: model.query.format,
      onSelected: model.showFormat,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<EbookFormat?>>[
        PopupMenuItem<EbookFormat?>(child: Text(l10n.libraryAllFormats)),
        for (final format in EbookFormat.values)
          PopupMenuItem<EbookFormat?>(
            value: format,
            // The format's own name, which is the token the contract, the
            // node's column and this schema all spell. Translating it would
            // name a format nothing else calls that.
            child: Text(format.wireName.toUpperCase()), // l10n-ignore
          ),
      ],
    );
  }
}

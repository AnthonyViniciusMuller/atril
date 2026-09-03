/// What is under the bar: the strip, the filter, the shelf — or a sentence.
///
/// **Three emptinesses and not one**, because they are three different things
/// to tell a reader. *You have no books* is where to start; *nothing on this
/// shelf* names a place; *nothing found* names what was asked for. Only the
/// last two need a way out, and it is the same one.
///
/// Before the first answer the screen shows *nothing* rather than a spinner.
/// This is a query over rows this device already holds — a frame or two, never
/// a wait on a node — and a progress indicator on screen for two frames is a
/// flash a reader reads as something having gone wrong.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';
import '../view_model/library_view_model.dart';
import 'continue_reading.dart';
import 'shelf.dart';
import 'shelf_filter.dart';

/// The shelf, the filter above it, or whichever emptiness applies.
class LibraryBody extends StatelessWidget {
  /// The body over [model].
  const LibraryBody({required this.model, super.key});

  /// What the shelf knows.
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final works = model.ebooks;

    if (works == null) {
      // The first answer has not arrived, and the screen deliberately shows
      // *nothing* rather than a spinner. This is a query over rows this device
      // already holds — a frame or two, never a wait on a node — and a
      // progress indicator on screen for two frames is a flash a reader reads
      // as something having gone wrong. It is also not the empty state: a
      // reader who has not been told anything yet must not be told to start
      // importing.
      //
      // The failure is the one thing worth saying, and the exception's own
      // words are not part of it: it is a query against this device's own
      // database, so what a reader can do about it is the same whatever sqlite
      // said, and what sqlite said is developer prose in one language. It is
      // logged.
      return model.error == null
          ? const SizedBox.shrink()
          : ShelfMessage(
              icon: Icons.error_outline,
              title: l10n.libraryReadFailed,
            );
    }

    return Column(
      children: <Widget>[
        // Above the filters and the shelf, and only when there is something in
        // it: a reader who has imported books and opened none should see their
        // shelf rather than an empty band explaining what would go there.
        //
        // It is not narrowed by the search or the shelf filter. What it answers
        // is *where was I*, which is a question about the last few days rather
        // than about whatever is currently being looked for — and a strip that
        // emptied as somebody typed would be a second set of results competing
        // with the one they asked for.
        ContinueReading(places: model.places),
        if (model.collections.isNotEmpty)
          ShelfFilter(
            collections: model.collections,
            counts: model.filingCounts,
            selected: model.query.collectionId,
            onSelected: model.showCollection,
          ),
        Expanded(
          child: works.isEmpty ? EmptyShelf(model: model) : Shelf(works: works),
        ),
      ],
    );
  }
}

/// The two emptinesses, which are two different things to say.
class EmptyShelf extends StatelessWidget {
  /// The sentence [model]'s emptiness calls for.
  const EmptyShelf({required this.model, super.key});

  /// What the shelf knows.
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (model.isEmpty) {
      return ShelfMessage(
        icon: Icons.local_library_outlined,
        title: l10n.libraryEmptyTitle,
        message: l10n.libraryEmptyMessage,
        action: FilledButton.icon(
          onPressed: model.importBook.running ? null : model.importBook.execute,
          icon: const Icon(Icons.add),
          label: Text(l10n.libraryImport),
        ),
      );
    }

    // Three emptinesses and not one, because they are three different things
    // to tell a reader. *You have no books* is where to start; *nothing on
    // this shelf* names a place; *nothing found* names what was asked for.
    // Only the last two need a way out, and it is the same one.
    final searched = model.query.isSearching || model.query.format != null;

    return ShelfMessage(
      icon: searched ? Icons.search_off : Icons.filter_list_off,
      title: searched
          ? l10n.libraryNoMatchesTitle
          : l10n.libraryFilterEmptyTitle,
      message: searched
          ? l10n.libraryNoMatchesMessage
          : l10n.libraryFilterEmptyMessage,
      action: TextButton(
        onPressed: model.clearFilters,
        child: Text(searched ? l10n.libraryClearFilters : l10n.libraryShowAll),
      ),
    );
  }
}

/// Something the screen has to say instead of a shelf.
class ShelfMessage extends StatelessWidget {
  /// A sentence [title], under [icon], with [message] and [action] below it.
  const ShelfMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message case final String message) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action case final Widget action) ...<Widget>[
                const SizedBox(height: 16),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

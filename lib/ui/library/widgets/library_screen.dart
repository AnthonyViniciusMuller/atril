/// The reader's collection (UC01).
///
/// **A grid on a wide window and a list on a narrow one**, decided by the width
/// the screen was given and never by the platform — the same rule
/// `AdaptiveScaffold` states and for the same reason: a desktop window dragged
/// to a third of the screen is a phone, and a browser is whatever the reader
/// has made it this second. The threshold is the navigation surface's own, so
/// that the two changes happen together rather than at two widths a reader
/// would notice separately.
///
/// A grid and a list are two shapes of the same shelf. The grid is what a
/// collection of covers wants; the list is what a narrow column can show
/// without cutting a title in half, and it carries the author beside it, which
/// a grid cell has no room for.
///
/// **Nothing on this screen refreshes.** There is nothing to refresh: the
/// collection is watched out of the local replica, so a work that arrives by
/// synchronization appears without being asked for and a work the reader
/// imports appears through the same subscription. A pull-to-refresh here would
/// be a gesture that runs a query that is already running.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_metadata.dart';
import '../../../data/services/files/file_source.dart';
import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../../core/ui/adaptive_scaffold.dart';
import '../view_model/library_view_model.dart';
import 'continue_reading.dart';

/// The width from which the shelf is a grid.
///
/// It is [compactWidth] deliberately. Below it the navigation goes under the
/// content and there is one column of room; above it there is space beside a
/// cover for a second one. Two thresholds a few pixels apart would be two
/// reflows as a window is dragged.
const double gridWidth = compactWidth;

/// How wide a cover is allowed to be before the grid adds a column.
///
/// A cover is taller than it is wide, and a shelf of them is read by scanning
/// across; a cell much wider than this stops looking like a book.
const double coverExtent = 180;

/// The proportions of a cover, which are roughly those of a paperback.
const double coverAspect = 2 / 3;

/// The library screen.
class LibraryScreen extends StatefulWidget {
  /// Creates the library screen.
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();

  /// Whether the app bar has turned into a search field.
  bool _searching = false;

  late final LibraryViewModel _model = LibraryViewModel(
    library: context.read<LibraryRepository>(),
    reading: context.read<ReadingRepository>(),
    picker: context.read<FilePicker>(),
  );

  @override
  void initState() {
    super.initState();
    _model.importBook.addListener(_onImported);
  }

  @override
  void dispose() {
    _model.importBook.removeListener(_onImported);
    _search.dispose();
    _model.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() => _searching = false);
    _search.clear();
    _model.search('');
  }

  /// Says what happened to an import, once.
  ///
  /// It is a listener rather than something awaited at the call site because
  /// the command is what carries the outcome — a screen that awaited the tap
  /// would have two places holding the same answer. The result is cleared by
  /// the command's next run, so a message is shown for one outcome and not
  /// again on the next rebuild.
  void _onImported() {
    if (_model.importBook.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final message = switch (_model.importBook.result) {
      // The reader closed the dialog without choosing. Nothing happened, and
      // saying so would be the app commenting on a decision.
      Ok<Ebook?>(value: null) => null,
      Ok<Ebook?>(:final value) => l10n.libraryImported(value!.title),
      Error<Ebook?>(:final error)
          when error is AppException && error.code == codeUnsupportedFormat =>
        l10n.libraryImportUnsupported,
      Error<Ebook?>() => l10n.libraryImportFailed,
      null => null,
    };

    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.librarySearchHint,
                  border: InputBorder.none,
                ),
                // As it is typed. The answer is a query over rows this device
                // already holds, so there is nothing to wait for and a
                // debounce would be this app pretending to.
                onChanged: _model.search,
              )
            : Text(l10n.navigationLibrary),
        actions: <Widget>[
          if (_searching)
            IconButton(
              onPressed: _closeSearch,
              tooltip: l10n.librarySearchClear,
              icon: const Icon(Icons.close),
            )
          else ...<Widget>[
            IconButton(
              onPressed: () => setState(() => _searching = true),
              tooltip: l10n.librarySearch,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () => context.go(Routes.shelves),
              tooltip: l10n.shelvesTitle,
              icon: const Icon(Icons.shelves),
            ),
          ],
          ListenableBuilder(
            listenable: _model,
            builder: (BuildContext context, Widget? _) =>
                _FormatMenu(model: _model),
          ),
          ListenableBuilder(
            listenable: _model,
            builder: (BuildContext context, Widget? _) =>
                _SortMenu(model: _model),
          ),
        ],
      ),
      body: ListenableBuilder(
        // The command is a listenable of its own, and the empty state carries
        // a button that has to go quiet while an import is running. Merging
        // them is what keeps the body and the floating button from disagreeing
        // about whether one is in flight.
        listenable: Listenable.merge(<Listenable>[_model, _model.importBook]),
        builder: (BuildContext context, Widget? _) =>
            _LibraryBody(model: _model),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _model.importBook,
        builder: (BuildContext context, Widget? _) => FloatingActionButton(
          // Disabled while one import is in flight, and not because two would
          // corrupt anything — the store is keyed by a digest and two writes
          // of one file converge. It is that a second dialog opened over the
          // first is a reader who cannot tell which file they are answering
          // about.
          onPressed: _model.importBook.running
              ? null
              : _model.importBook.execute,
          tooltip: l10n.libraryImport,
          child: _model.importBook.running
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// The menu that chooses the order of the shelf.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.model});

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
class _FormatMenu extends StatelessWidget {
  const _FormatMenu({required this.model});

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

/// The shelf, the filter above it, or whichever emptiness applies.
class _LibraryBody extends StatelessWidget {
  const _LibraryBody({required this.model});

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
          : _Message(icon: Icons.error_outline, title: l10n.libraryReadFailed);
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
          _ShelfFilter(
            collections: model.collections,
            counts: model.filingCounts,
            selected: model.query.collectionId,
            onSelected: model.showCollection,
          ),
        Expanded(
          child: works.isEmpty
              ? _EmptyShelf(model: model)
              : _Shelf(works: works),
        ),
      ],
    );
  }
}

/// The row of groupings above the shelf.
class _ShelfFilter extends StatelessWidget {
  const _ShelfFilter({
    required this.collections,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final List<Collection> collections;
  final Map<String, int> counts;
  final String? selected;
  final void Function(String? collectionId) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ChoiceChip(
              label: Text(l10n.libraryShowAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              // The count rides on the chip as a badge rather than inside its
              // label. A shelf is chosen by how much is on it as often as by
              // what it is called, and a label built by interpolating a number
              // into a name is a sentence in no language's word order.
              child: Badge.count(
                count: counts[collection.id] ?? 0,
                isLabelVisible: (counts[collection.id] ?? 0) > 0,
                child: ChoiceChip(
                  label: Text(collection.name),
                  tooltip: l10n.libraryBookCount(counts[collection.id] ?? 0),
                  selected: selected == collection.id,
                  onSelected: (_) => onSelected(collection.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The two emptinesses, which are two different things to say.
class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.model});

  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (model.isEmpty) {
      return _Message(
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

    return _Message(
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
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.message,
    this.action,
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

/// The works, as a grid or as a list.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.works});

  final List<Ebook> works;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) =>
        constraints.maxWidth < gridWidth
        ? ListView.builder(
            itemCount: works.length,
            itemBuilder: (BuildContext context, int index) =>
                _WorkTile(work: works[index]),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: coverExtent,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // Room for the cover and for the two lines under it.
              childAspectRatio: 0.52,
            ),
            itemCount: works.length,
            itemBuilder: (BuildContext context, int index) =>
                _WorkCard(work: works[index]),
          ),
  );
}

/// One work, in the narrow shape.
class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.work});

  final Ebook work;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: SizedBox(
      width: 40,
      child: AspectRatio(
        aspectRatio: coverAspect,
        child: _Cover(work: work),
      ),
    ),
    title: Text(work.title, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      work.author ?? AppLocalizations.of(context).libraryUnknownAuthor,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    // A location and not a pushed object. The work's screen is addressable, so
    // it survives a reload in a browser and a link somebody pasted, and it is
    // nested under the shelf so that the way back is where the reader came
    // from.
    onTap: () => context.go(Routes.ebook(work.id)),
  );
}

/// One work, in the wide shape.
class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work});

  final Ebook work;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.go(Routes.ebook(work.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: AspectRatio(
              aspectRatio: coverAspect,
              child: _Cover(work: work),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            work.title,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            work.author ?? AppLocalizations.of(context).libraryUnknownAuthor,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A work's cover, or what stands in for one.
///
/// It is asked for **once per tile** and not watched. A cover is derived from
/// a file this device holds and changes exactly when that file arrives, so a
/// shelf of two hundred books watching two hundred covers would be two hundred
/// queries waking on every import — for a picture that did not change.
///
/// A work with no cover is the ordinary case and not a gap to apologize for:
/// its file may be on the node and not here, or be a format whose metadata
/// this app does not read. The placeholder says the one thing that is always
/// known, which is what format the work is.
class _Cover extends StatefulWidget {
  const _Cover({required this.work});

  final Ebook work;

  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  late Future<Result<EpubCover?>> _cover = _load();

  Future<Result<EpubCover?>> _load() =>
      context.read<LibraryRepository>().cover(widget.work.id);

  @override
  void didUpdateWidget(_Cover old) {
    super.didUpdateWidget(old);

    // The tile is recycled as the shelf scrolls, so the same state is handed a
    // different work. A future built once in `initState` would show one book's
    // cover on another's.
    if (old.work.id != widget.work.id) {
      _cover = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<EpubCover?>>(
    future: _cover,
    builder:
        (BuildContext context, AsyncSnapshot<Result<EpubCover?>> snapshot) {
          final cover = switch (snapshot.data) {
            Ok<EpubCover?>(:final value) => value,
            _ => null,
          };

          return cover == null
              ? _CoverPlaceholder(work: widget.work)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    cover.bytes,
                    fit: BoxFit.cover,
                    // A picture that will not decode is a picture, not a
                    // failure of the shelf.
                    errorBuilder: (
                      BuildContext context,
                      Object _,
                      StackTrace? _,
                    ) => _CoverPlaceholder(work: widget.work),
                  ),
                );
        },
  );
}

/// What is shown for a work with no cover.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.work});

  final Ebook work;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          // The format's own name, which is not a user-visible string in the
          // sense the rule is about: it is `epub`, `pdf`, `mobi` — the same
          // token the contract, the node's column and this schema all spell,
          // and translating it would name a format nothing else calls that.
          work.format?.wireName.toUpperCase() ?? '', // l10n-ignore
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

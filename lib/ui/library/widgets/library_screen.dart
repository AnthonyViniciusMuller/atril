/// The reader's collection (UC01).
///
/// **Nothing on this screen refreshes.** There is nothing to refresh: the
/// collection is watched out of the local replica, so a work that arrives by
/// synchronization appears without being asked for and a work the reader
/// imports appears through the same subscription. A pull-to-refresh here would
/// be a gesture that runs a query that is already running.
///
/// What is left in this file is the screen itself — the bar, the search field
/// it turns into, and the import. The shelf and the two shapes it takes, the
/// filter above it, the menus and the emptinesses are each beside it.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/files/file_source.dart';
import '../../../domain/models/ebook.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/library_view_model.dart';
import 'library_body.dart';
import 'library_menus.dart';

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
                FormatMenu(model: _model),
          ),
          ListenableBuilder(
            listenable: _model,
            builder: (BuildContext context, Widget? _) =>
                SortMenu(model: _model),
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
            LibraryBody(model: _model),
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

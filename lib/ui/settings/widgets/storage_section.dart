/// What this device is keeping, and the room it has for it.
///
/// **One section, two sentences.** On the five native targets every book is
/// kept and the control releases one; in a browser nothing is kept until the
/// reader asks, and the number is spent against a quota the browser lends and
/// may take back. Which sentence is shown is decided by whether there is a
/// quota to spend — `StorageBudget.isMeasured` — rather than by asking the
/// framework what platform this is, because that is the same question one
/// layer further from the answer.
///
/// **Nothing is ever released without being asked for.** A book that vanished
/// between two openings is the one failure an offline-first library cannot
/// explain away, so the store evicts nothing on its own and this is the only
/// screen that removes a file. It refuses to remove the last copy: a work whose
/// bytes have not reached the node exists here and nowhere else.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../domain/models/ebook.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../../core/ui/byte_size.dart';
import '../view_model/storage_view_model.dart';

/// The storage section of the settings screen.
class StorageSection extends StatefulWidget {
  /// Creates the storage section.
  const StorageSection({super.key});

  @override
  State<StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<StorageSection> {
  late final StorageViewModel _model = StorageViewModel(
    library: context.read<LibraryRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _model.release.addListener(_onReleased);
  }

  @override
  void dispose() {
    _model.release.removeListener(_onReleased);
    _model.dispose();
    super.dispose();
  }

  void _onReleased() {
    if (_model.release.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final message = switch (_model.release.result) {
      Error<void>(:final error)
          when error is AppException && error.code == codeNotYetSent =>
        l10n.storageNotYetSent,
      Error<void>() => l10n.storageReleaseFailed,
      _ => null,
    };

    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _model,
        _model.refresh,
        _model.release,
      ]),
      builder: (BuildContext context, Widget? _) {
        final budget = _model.budget;
        final quota = budget.quota;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                l10n.settingsStorageSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage_outlined),
              title: Text(
                // Two sentences and one of them is a fraction. A native
                // install has no quota to report — nothing portable can ask a
                // volume how much room is left — so it is told what it holds
                // and nothing it cannot know.
                quota == null
                    ? l10n.storageUsed(formatBytes(l10n, budget.used))
                    : l10n.storageUsedOfQuota(
                        formatBytes(l10n, budget.used),
                        formatBytes(l10n, quota),
                      ),
              ),
              subtitle: Text(
                budget.isMeasured
                    ? l10n.storageKeptExplanationWeb
                    : l10n.storageKeptExplanationNative,
              ),
            ),
            if (budget.isMeasured && quota != null && quota > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: (budget.used / quota).clamp(0, 1),
                ),
              ),
            if (_model.books.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.storageNothingKept,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final book in _model.books)
              _KeptBook(
                book: book,
                onRelease: _model.release.running
                    ? null
                    : () => _model.release.execute(book.id),
              ),
          ],
        );
      },
    );
  }
}

/// One book whose file is on this device.
class _KeptBook extends StatelessWidget {
  const _KeptBook({required this.book, required this.onRelease});

  final Ebook book;
  final VoidCallback? onRelease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = book.sizeBytes;

    return ListTile(
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: size == null ? null : Text(formatBytes(l10n, size)),
      trailing: TextButton(
        onPressed: onRelease,
        child: Text(l10n.storageRelease),
      ),
    );
  }
}

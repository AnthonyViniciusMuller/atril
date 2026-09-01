/// One work: what it is, where its bytes are, and what can be done about it.
///
/// **It says where the file is, always.** That is not a detail of this screen;
/// it is the consequence of D02 reaching a reader. A device holding the row and
/// not the bytes is the ordinary state of a book that has not been downloaded,
/// and in a browser it is the ordinary state of every book — so a screen that
/// showed a title and an *open* button would be a screen that opens a book
/// which is not here.
///
/// **A work that is gone is a state and not a failure.** Another device can
/// delete a book the reader is looking at; the tombstone arrives, the
/// reconciler applies it, and this screen has nothing left to show. It says so
/// in a sentence that names the reason, because *something went wrong* would be
/// this app blaming itself for working.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/services/content/content_downloader.dart';
import '../../../domain/models/ebook.dart';
import '../../../routing/routes.dart';
import '../../../utils/cancellation.dart';
import '../../../utils/command.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../../core/ui/byte_size.dart';
import '../view_model/ebook_view_model.dart';

/// How wide the cover is on this screen.
const double detailCoverWidth = 140;

/// The screen of one work.
class EbookScreen extends StatefulWidget {
  /// Creates the screen of the work [ebookId] names.
  const EbookScreen({required this.ebookId, super.key});

  /// The work, from the location.
  ///
  /// It is the identifier and not the work itself, because the location is
  /// what survives a reload in a browser and a link somebody pasted — and
  /// because a screen handed an object would be showing a snapshot while the
  /// record it came from changed underneath it.
  final String ebookId;

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  late final EbookViewModel _model = EbookViewModel(
    library: context.read<LibraryRepository>(),
    ebookId: widget.ebookId,
  );

  @override
  void initState() {
    super.initState();
    _model.download.addListener(_onTransfer);
    _model.keep.addListener(_onTransfer);
    _model.release.addListener(_onTransfer);
  }

  @override
  void dispose() {
    _model.download.removeListener(_onTransfer);
    _model.keep.removeListener(_onTransfer);
    _model.release.removeListener(_onTransfer);
    _model.dispose();
    super.dispose();
  }

  /// Says what happened to a transfer, once it has stopped happening.
  void _onTransfer() {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    for (final command in <Command0<void>>[
      _model.download,
      _model.keep,
      _model.release,
    ]) {
      if (command.running || command.result is! Error<void>) {
        continue;
      }

      final error = (command.result as Error<void>).error;
      final code = error is AppException ? error.code : '';

      // A reader who cancelled is not told anything: they know, and the app
      // commenting on their decision would be the app apologizing for it.
      if (code == codeCancelled) {
        continue;
      }

      final message = switch (code) {
        codeContentNotFound => l10n.ebookNotOnServer,
        codeNotYetSent => l10n.storageNotYetSent,
        _ => l10n.ebookDownloadFailed,
      };

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      return;
    }
  }

  /// Asks before deleting, and undoes it afterwards if the reader says so.
  ///
  /// The question is worth asking because the answer is not local: a deletion
  /// leaves the reader's library on every device they have. The undo is worth
  /// offering because it costs one operation carrying nothing — a tombstone is
  /// a flag on a record that is still there, so bringing a book back is not a
  /// restore from anywhere.
  Future<void> _confirmDelete(Ebook work) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    // Read before the screen goes away. The undo runs after this route has
    // been left, so a callback holding this `context` would be holding a dead
    // one.
    final library = context.read<LibraryRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.ebookDeleteConfirmTitle),
        content: Text(l10n.ebookDeleteConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ebookDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _model.delete.execute();

    if (_model.delete.result is Error<void>) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ebookDeleteFailed)));

      return;
    }

    // Back to the shelf, which is where a deleted book is no longer shown.
    router.go(Routes.library);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.ebookDeleted(work.title)),
        action: SnackBarAction(
          label: l10n.ebookDeleteUndo,
          onPressed: () async {
            await library.restoreEbook(work.id);

            messenger.showSnackBar(
              SnackBar(content: Text(l10n.ebookRestored(work.title))),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[
      _model,
      _model.download,
      _model.keep,
      _model.release,
      _model.delete,
      _model.file,
    ]),
    builder: (BuildContext context, Widget? _) {
      final l10n = AppLocalizations.of(context);
      final work = _model.ebook;

      return Scaffold(
        appBar: AppBar(
          title: Text(work?.title ?? ''),
          actions: <Widget>[
            if (work != null) ...<Widget>[
              IconButton(
                onPressed: () => context.go(Routes.editEbook(widget.ebookId)),
                tooltip: l10n.ebookEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: _model.delete.running
                    ? null
                    : () => _confirmDelete(work),
                tooltip: l10n.ebookDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        body: work == null
            // Nothing at all until the first answer: a screen opened at a
            // location the reader typed has neither the book nor its absence
            // yet, and saying it was deleted before the query ran is a lie one
            // frame long.
            ? (!_model.isLoaded ? const SizedBox.shrink() : _Gone(l10n: l10n))
            : _Work(model: _model, work: work),
      );
    },
  );
}

/// A work that no longer exists on this device.
class _Gone extends StatelessWidget {
  const _Gone({required this.l10n});

  final AppLocalizations l10n;

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
              Icon(
                Icons.auto_delete_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.ebookNotFoundTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ebookNotFoundMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The work itself.
class _Work extends StatelessWidget {
  const _Work({required this.model, required this.work});

  final EbookViewModel model;
  final Ebook work;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cover = model.cover;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: detailCoverWidth,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: cover == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(cover.bytes, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(work.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    work.author ?? l10n.libraryUnknownAuthor,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FileSection(model: model),
        const SizedBox(height: 16),
        _Section(title: l10n.ebookMetadataSection),
        if (work.publisher case final String publisher)
          _Fact(label: l10n.ebookPublisher, value: publisher),
        if (work.language case final String language)
          _Fact(label: l10n.ebookLanguage, value: language),
        _Fact(
          label: l10n.ebookFormat,
          // The format's own name, which is `epub`, `pdf`, `mobi` — the token
          // the contract, the node's column and this schema all spell. What is
          // translated is the sentence around it and the case where this build
          // cannot name it at all.
          value:
              work.format?.wireName.toUpperCase() ?? // l10n-ignore
              l10n.ebookUnknownFormat,
        ),
        if (work.sizeBytes case final int size)
          _Fact(label: l10n.ebookSize, value: formatBytes(l10n, size)),
        _Fact(
          label: l10n.ebookImportedAt,
          value: MaterialLocalizations.of(context)
              .formatFullDate(work.importedAt.toLocal()),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(child: _Section(title: l10n.ebookMarksSection)),
            // The marks of one book are the annotations screen narrowed, and
            // not a list of their own: the same question at two widths is one
            // screen, and a second copy of it here would be a second place to
            // fix the day a mark gains a field.
            TextButton.icon(
              onPressed: () => context.go(Routes.ebookMarks(work.id)),
              icon: const Icon(Icons.brush_outlined),
              label: Text(l10n.ebookMarksOpen),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(child: _Section(title: l10n.ebookShelvesSection)),
            TextButton.icon(
              onPressed: model.file.running
                  ? null
                  : () => _chooseShelves(context, model),
              icon: const Icon(Icons.playlist_add),
              label: Text(l10n.ebookShelvesEdit),
            ),
          ],
        ),
        if (model.collections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.ebookNoShelves,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final shelf in model.collections)
                Chip(label: Text(shelf.name)),
            ],
          ),
        if (work.extraMetadata.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _Section(title: l10n.ebookExtraSection),
          for (final entry in work.extraMetadata.entries)
            // The keys are what the file called them — `series`, `isbn`,
            // `subjects` — and they are not translated: they are the metadata's
            // own vocabulary, they differ per file, and inventing a label for
            // each would be this app claiming to know what a publisher meant.
            _Fact(
              label: entry.key, // l10n-ignore
              value: '${entry.value}',
            ),
        ],
      ],
    );
  }
}

/// Where the bytes are, and what can be done about that.
class _FileSection extends StatelessWidget {
  const _FileSection({required this.model});

  final EbookViewModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = model.content;
    final progress = model.progress;
    final busy =
        model.download.running || model.keep.running || model.release.running;

    final sentence = switch (state) {
      // A transfer in flight is what the reader most wants to know about, so
      // it is said before anything else that is also true.
      ContentState(isOwed: true, sentBytes: > 0) => l10n.ebookFileSending(
        '${(state.sentFraction * 100).round()}',
      ),
      ContentState(isOwed: true) => l10n.ebookFileWaiting,
      ContentState(onThisDevice: true, kept: true) => l10n.ebookFileHere,
      ContentState(onThisDevice: true) => l10n.ebookFileHereNotKept,
      _ => l10n.ebookFileOnServer,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Section(title: l10n.ebookFileSection),
        Text(sentence, style: theme.textTheme.bodyMedium),
        if (state.isOwed && state.sentBytes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: state.sentFraction),
          ),
        if (progress != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            l10n.ebookDownloading('${(progress.fraction * 100).round()}'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress.fraction),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (progress != null)
              TextButton(
                onPressed: model.cancelDownload,
                child: Text(l10n.ebookCancelDownload),
              )
            else ...<Widget>[
              // UC04, and the primary thing a reader came here to do. It is in
              // this section rather than beside the title because what governs
              // whether a book can be opened is exactly what this section is
              // about — the file is here, or it is not — and an *open* button
              // above a book that is on the node would be a button that fails.
              //
              // It is offered for an EPUB alone. The other four formats import,
              // list, synchronize and carry a percentage, and a button that
              // opened a screen to say *not this format* would be this app
              // asking the reader to find that out for themselves.
              if (state.onThisDevice && model.ebook?.format == EbookFormat.epub)
                FilledButton.icon(
                  onPressed: () => context.go(Routes.readEbook(model.ebookId)),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.readerOpen),
                ),
              if (!state.onThisDevice)
                FilledButton.icon(
                  onPressed: busy ? null : model.download.execute,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.ebookDownload),
                ),
              // One decision with two directions, and both are offered on
              // every target: the default differs, the question does not.
              if (state.kept)
                TextButton(
                  onPressed: busy ? null : model.release.execute,
                  child: Text(l10n.storageRelease),
                )
              else
                TextButton(
                  onPressed: busy ? null : model.keep.execute,
                  child: Text(l10n.storageKeep),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Opens the chooser, and files or unfiles as the reader marks each shelf.
///
/// Each mark is its own change and takes effect as it is made, rather than
/// being collected and applied when a dialog closes. That is what a register
/// per pair (C06) makes natural: filing a work and filing it again are one
/// request, so there is nothing to batch and nothing to undo if the reader
/// walks away half way through.
Future<void> _chooseShelves(BuildContext context, EbookViewModel model) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l10n.ebookShelvesDialogTitle),
      content: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[model, model.file]),
        builder: (BuildContext context, Widget? _) => SizedBox(
          width: 320,
          child: model.allCollections.isEmpty
              ? Text(l10n.ebookShelvesNone)
              : ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final shelf in model.allCollections)
                      CheckboxListTile(
                        value: model.isFiledUnder(shelf.id),
                        title: Text(shelf.name),
                        onChanged: model.file.running
                            ? null
                            : (bool? filed) => model.file.execute((
                                collectionId: shelf.id,
                                filed: filed ?? false,
                              )),
                      ),
                  ],
                ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );

  if (model.file.result is Error<void>) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.ebookShelvesFailed)));
  }
}

/// The heading of one section.
class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// One labelled fact about the work.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

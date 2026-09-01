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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[
      _model,
      _model.download,
      _model.keep,
      _model.release,
    ]),
    builder: (BuildContext context, Widget? _) {
      final l10n = AppLocalizations.of(context);
      final work = _model.ebook;

      return Scaffold(
        appBar: AppBar(
          title: Text(work?.title ?? ''),
          actions: <Widget>[
            if (work != null)
              IconButton(
                onPressed: () => context.go(Routes.editEbook(widget.ebookId)),
                tooltip: l10n.ebookEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
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
        _Section(title: l10n.ebookShelvesSection),
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

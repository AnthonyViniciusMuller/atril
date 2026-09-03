/// One work on the shelf, in the two shapes the shelf has.
///
/// The tile is what a narrow column can show without cutting a title in half,
/// and it carries the author beside the cover; the card is what a grid of
/// covers wants. A work's cover is asked for **once per cell** and not watched:
/// it is derived from a file this device holds and changes exactly when that
/// file arrives, so a shelf of two hundred books watching two hundred covers
/// would be two hundred queries waking on every import, for a picture that did
/// not change.
///
/// A work with no cover is the ordinary case and not a gap to apologize for:
/// its file may be on the node and not here, or a format whose metadata this
/// app does not read. The placeholder says the one thing that is always known,
/// which is what format the work is.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/services/epub/epub_metadata.dart';
import '../../../domain/models/ebook.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import 'shelf.dart';

/// One work, in the narrow shape.
class WorkTile extends StatelessWidget {
  /// The tile of [work].
  const WorkTile({required this.work, super.key});

  /// The work it is about.
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
class WorkCard extends StatelessWidget {
  /// The card of [work].
  const WorkCard({required this.work, super.key});

  /// The work it is about.
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
          const SizedBox(height: coverLabelGap),
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

  /// The work it is about.
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

  /// The work it is about.
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

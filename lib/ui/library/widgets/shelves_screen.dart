/// The reader's shelves and categories (UC03).
///
/// **The screen does not blur them.** A collection and a category are one
/// structure with two meanings — which is what lets RF05 offer both without a
/// second entity — and the place that difference exists is here: two headings,
/// two lists, and one choice in the form that creates either. A single list
/// with a badge would be this app deciding the distinction does not matter,
/// which is a decision about the reader's library that is not this app's to
/// take.
///
/// **Deleting a shelf is not deleting what was on it.** The contract says so
/// where `DeleteCollection` is declared, the filings are tombstoned with the
/// grouping and the works are not, and the reader is told in the same breath as
/// the confirmation — because the fear that stops somebody tidying their
/// library is exactly that.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../domain/models/collection.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/shelves_view_model.dart';

/// The shelves screen.
class ShelvesScreen extends StatefulWidget {
  /// Creates the shelves screen.
  const ShelvesScreen({super.key});

  @override
  State<ShelvesScreen> createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends State<ShelvesScreen> {
  late final ShelvesViewModel _model = ShelvesViewModel(
    library: context.read<LibraryRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _model.save.addListener(_onSaved);
  }

  @override
  void dispose() {
    _model.save.removeListener(_onSaved);
    _model.dispose();
    super.dispose();
  }

  void _onSaved() {
    if (_model.save.running || !mounted) {
      return;
    }

    if (_model.save.result is Error<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).shelvesSaveFailed)),
      );
    }
  }

  /// Opens the form, and saves what comes back.
  Future<void> _edit(Collection? grouping) async {
    final draft = await showDialog<ShelfDraft>(
      context: context,
      builder: (BuildContext context) => _ShelfForm(grouping: grouping),
    );

    if (draft != null) {
      await _model.save.execute(draft);
    }
  }

  /// Deletes a grouping, and offers the undo a tombstone makes cheap.
  Future<void> _remove(Collection grouping) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await _model.remove.execute(grouping.id);

    if (!mounted) {
      return;
    }

    if (_model.remove.result is Error<void>) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shelvesDeleteFailed)));

      return;
    }

    messenger.showSnackBar(
      SnackBar(
        // The books stay, and the message says so in one sentence rather than
        // two joined with a space: the fear that stops somebody tidying their
        // library is exactly that it might take the books with it, and where
        // that clause goes is a translator's decision and not this file's.
        content: Text(l10n.shelvesDeleted(grouping.name)),
        action: SnackBarAction(
          label: l10n.ebookDeleteUndo,
          onPressed: () => _model.undoRemoval(grouping.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shelvesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        tooltip: l10n.shelvesCreate,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _model,
          _model.save,
          _model.remove,
        ]),
        builder: (BuildContext context, Widget? _) {
          if (_model.all == null) {
            return const SizedBox.shrink();
          }

          if (_model.isEmpty) {
            return _Empty(onCreate: () => _edit(null));
          }

          return ListView(
            children: <Widget>[
              if (_model.collections.isNotEmpty)
                _Group(
                  heading: l10n.shelvesCollections,
                  groupings: _model.collections,
                  counts: _model.filingCounts,
                  onEdit: _edit,
                  onRemove: _remove,
                ),
              if (_model.categories.isNotEmpty)
                _Group(
                  heading: l10n.shelvesCategories,
                  groupings: _model.categories,
                  counts: _model.filingCounts,
                  onEdit: _edit,
                  onRemove: _remove,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One heading and the groupings under it.
class _Group extends StatelessWidget {
  const _Group({
    required this.heading,
    required this.groupings,
    required this.counts,
    required this.onEdit,
    required this.onRemove,
  });

  final String heading;
  final List<Collection> groupings;
  final Map<String, int> counts;
  final void Function(Collection grouping) onEdit;
  final void Function(Collection grouping) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            heading,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final grouping in groupings)
          ListTile(
            title: Text(grouping.name),
            subtitle: Text(
              <String>[
                l10n.shelvesCount(counts[grouping.id] ?? 0),
                if (grouping.description case final String description)
                  description,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onEdit(grouping),
            trailing: IconButton(
              onPressed: () => onRemove(grouping),
              tooltip: l10n.shelvesDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}

/// What a reader who has defined nothing is told.
class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.shelves, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                l10n.shelvesEmpty,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // The one decision the reader has to take when they create one,
              // explained where they are about to take it.
              Text(
                l10n.shelvesEmptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.shelvesCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The form that creates a grouping or changes one.
class _ShelfForm extends StatefulWidget {
  const _ShelfForm({required this.grouping});

  /// The grouping being changed, or `null` for one that does not exist yet.
  final Collection? grouping;

  @override
  State<_ShelfForm> createState() => _ShelfFormState();
}

class _ShelfFormState extends State<_ShelfForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.grouping?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.grouping?.description ?? '',
  );

  // A grouping whose kind this build cannot name is offered as a collection,
  // which is what the schema's own default is. It is a value a later node
  // legitimately sends, and the reader choosing again is a better answer than
  // a form with nothing selected.
  late CollectionKind _kind =
      widget.grouping?.kind ?? CollectionKind.collection;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop((
      id: widget.grouping?.id,
      edits: CollectionEdits(
        name: _name.text,
        kind: _kind,
        description: _description.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        widget.grouping == null ? l10n.shelvesCreate : l10n.shelvesEditTitle,
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.shelvesNameLabel),
              // A grouping without a name is refused by the contract and by
              // the column's own check, so the form refuses it first and the
              // reader is told which field rather than which table.
              validator: (String? value) => (value ?? '').trim().isEmpty
                  ? l10n.shelvesNameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(
                labelText: l10n.shelvesDescriptionLabel,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CollectionKind>(
              segments: <ButtonSegment<CollectionKind>>[
                ButtonSegment<CollectionKind>(
                  value: CollectionKind.collection,
                  label: Text(l10n.shelvesKindCollection),
                ),
                ButtonSegment<CollectionKind>(
                  value: CollectionKind.category,
                  label: Text(l10n.shelvesKindCategory),
                ),
              ],
              selected: <CollectionKind>{_kind},
              onSelectionChanged: (Set<CollectionKind> chosen) =>
                  setState(() => _kind = chosen.single),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.shelvesSave)),
      ],
    );
  }
}

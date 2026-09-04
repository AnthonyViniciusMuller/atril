/// Editing what a work says about itself (RF05).
///
/// **The form knows every field and the repository works out what changed.**
/// That division is C17: reconciliation is per record and not per field, so a
/// delta restating a title the reader never touched carries this device's claim
/// to it, and the next merge against a device that *did* change it is settled
/// by a tie-break rather than by what anybody meant. A screen that tracked its
/// own dirty flags would be a second answer to the same question, and the two
/// would disagree the first time a field was edited back to its original value.
///
/// **An empty field is a field the reader cleared.** A form has no other way to
/// say *there is no author*, and that is a claim rather than a silence — the
/// contract spells the difference with `optional` and the column with `NULL`.
///
/// **The extra metadata edits text and preserves everything else.** What a file
/// carried beyond the contract is an object of whatever the publisher put in
/// it: `subjects` is a list, `series_index` is a number. A form that rendered
/// those into text boxes would turn a list into a string the moment the reader
/// saved anything, so a value that is not text is shown, said to be untouched,
/// and written back exactly as it was.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/repositories/reading/reading_repository.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/ebook_view_model.dart';

/// The form that edits one work.
class EbookEditScreen extends StatefulWidget {
  /// Creates the form for the work [ebookId] names.
  const EbookEditScreen({required this.ebookId, super.key});

  /// The work, from the location.
  final String ebookId;

  @override
  State<EbookEditScreen> createState() => _EbookEditScreenState();
}

class _EbookEditScreenState extends State<EbookEditScreen> {
  late final EbookViewModel _model = EbookViewModel(
    library: context.read<LibraryRepository>(),
    reading: context.read<ReadingRepository>(),
    ebookId: widget.ebookId,
  );

  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _author = TextEditingController();
  final TextEditingController _publisher = TextEditingController();
  final TextEditingController _language = TextEditingController();

  /// The extra metadata, as rows the reader can edit.
  final List<_ExtraRow> _extra = <_ExtraRow>[];

  /// Whether the fields have been filled in from the record.
  ///
  /// Once, and only once. The work is watched — a change arriving from another
  /// device while this reader is typing is an ordinary thing — and a form that
  /// refilled itself from every answer would take the sentence out from under
  /// them mid-word.
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _model.addListener(_fill);
    _model.save.addListener(_onSaved);
  }

  @override
  void dispose() {
    _model.removeListener(_fill);
    _model.save.removeListener(_onSaved);
    _title.dispose();
    _author.dispose();
    _publisher.dispose();
    _language.dispose();

    for (final row in _extra) {
      row.dispose();
    }

    _model.dispose();
    super.dispose();
  }

  void _fill() {
    final work = _model.ebook;

    if (_filled || work == null) {
      return;
    }

    _filled = true;
    _title.text = work.title;
    _author.text = work.author ?? '';
    _publisher.text = work.publisher ?? '';
    _language.text = work.language ?? '';
    _extra.addAll(<_ExtraRow>[
      for (final entry in work.extraMetadata.entries)
        _ExtraRow(entry.key, entry.value),
    ]);
  }

  void _onSaved() {
    if (_model.save.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    switch (_model.save.result) {
      case Ok<void>():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.ebookEditSaved)));

        // Back to the work, which is where the change is now visible. It is a
        // location and not a pop, so a reader who reached the form by typing
        // an address still lands somewhere that exists.
        context.go(Routes.ebook(widget.ebookId));
      case Error<void>():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.ebookEditFailed)));
      case null:
        break;
    }
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    unawaited(
      _model.save.execute(
        EbookEdits(
          title: _title.text,
          author: _author.text,
          publisher: _publisher.text,
          language: _language.text,
          extraMetadata: <String, Object?>{
            for (final row in _extra)
              if (row.name.text.trim().isNotEmpty)
                row.name.text.trim(): row.value,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_model, _model.save]),
      builder: (BuildContext context, Widget? _) => Scaffold(
        appBar: AppBar(title: Text(l10n.ebookEditTitle)),
        body: _model.ebook == null
            ? const SizedBox.shrink()
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    TextFormField(
                      controller: _title,
                      decoration: InputDecoration(
                        labelText: l10n.ebookTitleLabel,
                      ),
                      // The one required field. A work without a title is
                      // refused by the contract and by the column's own check,
                      // so the form refuses it first and names the field.
                      validator: (String? value) => (value ?? '').trim().isEmpty
                          ? l10n.ebookTitleRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _author,
                      decoration: InputDecoration(
                        labelText: l10n.ebookAuthorLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _publisher,
                      decoration: InputDecoration(
                        labelText: l10n.ebookPublisher,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _language,
                      decoration: InputDecoration(
                        labelText: l10n.ebookLanguage,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.ebookExtraSection,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ebookEditExtraExplanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    for (final row in _extra)
                      _ExtraField(
                        row: row,
                        onRemove: () => setState(() {
                          _extra.remove(row);
                          row.dispose();
                        }),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _extra.add(_ExtraRow('', ''))),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.ebookEditExtraAdd),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _model.save.running ? null : _submit,
                      child: Text(l10n.ebookEditSave),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// One entry of the extra metadata, while it is being edited.
///
/// It holds the original value as well as the controllers, because a value that
/// is not text is written back exactly as it was: turning a list of subjects
/// into a string the first time a reader saves anything would lose what the
/// file actually said.
final class _ExtraRow {
  _ExtraRow(String name, Object? value)
    : name = TextEditingController(text: name),
      _original = value,
      text = value is String ? TextEditingController(text: value) : null;

  /// The key, which is always text.
  final TextEditingController name;

  /// The value, where it is text and can be edited.
  final TextEditingController? text;

  final Object? _original;

  /// Whether this entry's value can be edited at all.
  bool get isText => text != null;

  /// What to write back: the edited text, or the original untouched.
  Object? get value => text?.text ?? _original;

  /// The original, for the row that only shows it.
  String get shown => '$_original';

  void dispose() {
    name.dispose();
    text?.dispose();
  }
}

/// One row of the extra metadata editor.
class _ExtraField extends StatelessWidget {
  const _ExtraField({required this.row, required this.onRemove});

  final _ExtraRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: row.name,
              decoration: InputDecoration(labelText: l10n.ebookEditExtraName),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: row.isText
                ? TextFormField(
                    controller: row.text,
                    decoration: InputDecoration(
                      labelText: l10n.ebookEditExtraValue,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(row.shown, style: theme.textTheme.bodyMedium),
                        Text(
                          l10n.ebookEditExtraNotText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: l10n.ebookEditExtraRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

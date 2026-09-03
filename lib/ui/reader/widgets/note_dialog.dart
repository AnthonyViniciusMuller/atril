/// The words a reader is putting against a passage.
///
/// A dialog and not a location, unlike every form elsewhere in this app. The
/// reason the others are locations is that a reader who switched away should
/// come back to the form; here they would come back to a *selection*, which the
/// engine will not have kept — so a note started and abandoned is a note that
/// was never made, and a route that promised otherwise would be lying.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';

/// The words a reader is putting against a passage.
class NoteDialog extends StatefulWidget {
  /// Creates the dialog.
  const NoteDialog({super.key});

  @override
  State<NoteDialog> createState() => NoteDialogState();
}

class NoteDialogState extends State<NoteDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.readerNoteTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.readerNoteLabel,
          // Said here rather than reported after the fact: the contract
          // requires a note to carry text, and a reader should learn that from
          // the field and not from a refusal.
          helperText: l10n.readerNoteRequired,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.readerNoteCancel),
        ),
        ListenableBuilder(
          listenable: _text,
          builder: (BuildContext context, Widget? _) => FilledButton(
            // Disabled rather than refused. The rule is the contract's and it
            // is not a surprise worth springing on somebody who has just
            // typed nothing.
            onPressed: _text.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_text.text),
            child: Text(l10n.readerNoteSave),
          ),
        ),
      ],
    );
  }
}

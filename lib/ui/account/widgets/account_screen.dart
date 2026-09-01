/// The reader's own record (UC06).
///
/// **Three fields, three dialogs, three different proofs — and that is the
/// contract's shape rather than this screen's taste.** Only the display name is
/// written by `UpdateUser`. The address is the channel UC08 recovers an account
/// through, so whoever can change it can have a recovery credential sent
/// somewhere of their choosing and then set the password; it therefore asks for
/// the password, and it is its own call because a field mask cannot say *this
/// one field needs a credential*. That is C14, and a single form with one
/// *save* button would have had to demand a password for the name as well, or
/// accept one for none of it.
///
/// **Changing the password signs this device out, and the screen says so
/// before it asks.** The node ends every session of every device — its own use
/// case says why, and the contract does not say it at all — so a reader who was
/// not warned would experience a correct security decision as the app breaking.
///
/// **The identifier is shown and is not editable.** Its two halves are the
/// local name and the node's domain (RN08); the second changes only by moving
/// server, which is a wizard three lines further down the settings.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/account/account_repository_impl.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/account_view_model.dart';

/// The account screen.
class AccountScreen extends StatefulWidget {
  /// Creates the account screen.
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountViewModel _model = AccountViewModel(
    account: context.read<AccountRepository>(),
    auth: context.read<AuthRepository>(),
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccount)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _model,
          _model.refresh,
          _model.rename,
          _model.changeEmail,
          _model.changePassword,
        ]),
        // The reader is read here and not in `build`, because only this
        // subtree rebuilds when the model notifies: a value captured above
        // would be whatever it was on the first frame, which on this screen is
        // nobody.
        builder: (BuildContext context, Widget? _) =>
            _account(l10n, theme, _model.signedIn),
      ),
    );
  }

  /// The record itself, over the reader this device currently holds.
  Widget _account(AppLocalizations l10n, ThemeData theme, User? reader) =>
      ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          // Said quietly and only where it is true. What is on screen came
          // from this device's own row, which is the last thing the node
          // told it — so a failed refresh is worth a line and not an empty
          // screen.
          if (_model.refresh.error)
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(l10n.accountFailed),
              trailing: TextButton(
                onPressed: _model.refresh.execute,
                child: Text(l10n.federationRetry),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(l10n.accountIdentifier),
            isThreeLine: true,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(reader?.federatedId ?? ''),
                Text(
                  l10n.accountIdentifierExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.accountDisplayName),
            subtitle: Text(reader?.displayName ?? ''),
            trailing: const Icon(Icons.edit_outlined),
            onTap: reader == null ? null : () => _rename(reader),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.accountEmail),
            isThreeLine: true,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(reader?.email ?? l10n.accountEmailAbsent),
                Text(
                  l10n.accountEmailExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _changeEmail,
          ),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(l10n.accountPassword),
            subtitle: Text(l10n.accountPasswordExplanation),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _changePassword,
          ),
          if (reader != null)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                l10n.accountCreated(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(reader.createdAt.toLocal()),
                ),
              ),
            ),
        ],
      );

  Future<void> _rename(User reader) async {
    final l10n = AppLocalizations.of(context);

    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _DisplayNameDialog(current: reader.displayName),
    );

    if (name == null) {
      return;
    }

    await _model.rename.execute(name);

    if (!mounted) {
      return;
    }

    _say(switch (_model.rename.result) {
      Ok<User>(:final value) => l10n.accountNameChanged(value.displayName),
      _ => l10n.accountNameFailed,
    });
  }

  Future<void> _changeEmail() async {
    final l10n = AppLocalizations.of(context);

    final change = await showDialog<EmailChange>(
      context: context,
      builder: (BuildContext context) => const _EmailDialog(),
    );

    if (change == null) {
      return;
    }

    await _model.changeEmail.execute(change);

    if (!mounted) {
      return;
    }

    _say(switch (_model.changeEmail.result) {
      Ok<User>(:final value) => l10n.accountEmailChanged(value.email ?? ''),
      Error<User>(:final error) => _refused(
        l10n,
        error,
        l10n.accountEmailFailed,
      ),
      null => l10n.accountEmailFailed,
    });
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);

    final change = await showDialog<PasswordChange>(
      context: context,
      builder: (BuildContext context) => const _PasswordDialog(),
    );

    if (change == null) {
      return;
    }

    await _model.changePassword.execute(change);

    if (!mounted) {
      return;
    }

    // Nothing navigates here. Ending the session is what the shell's guard
    // watches, and the redirect that already exists is what sends this device
    // back to onboarding — the same argument signing out makes.
    _say(switch (_model.changePassword.result) {
      Ok<void>() => l10n.accountPasswordChanged,
      Error<void>(:final error) => _refused(
        l10n,
        error,
        l10n.accountPasswordFailed,
      ),
      null => l10n.accountPasswordFailed,
    });
  }

  /// What to say about [error], naming the two refusals a reader can act on.
  ///
  /// A password that did not match is the reader's to correct, and an address
  /// somebody else holds here is a fact about the node worth reporting as
  /// itself. Everything else is one sentence, because everything else is the
  /// node having a bad day.
  String _refused(AppLocalizations l10n, Object error, String otherwise) {
    if (error is! AppException) {
      return otherwise;
    }

    return switch (error.code) {
      codeWrongPassword => l10n.accountWrongPassword,
      codeEmailRegistered => l10n.accountEmailRegistered,
      codeInvalidEmail => l10n.accountEmailInvalid,
      codeInvalidPassword => l10n.accountPasswordInvalid,
      _ => otherwise,
    };
  }

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// The one field a mask can carry.
class _DisplayNameDialog extends StatefulWidget {
  const _DisplayNameDialog({required this.current});

  final String current;

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.current,
  );

  bool _faulted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.accountEditName),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.accountDisplayName,
          border: const OutlineInputBorder(),
          errorText: _faulted ? l10n.accountNameInvalid : null,
        ),
        onSubmitted: (String _) => _save(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.federationCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.accountSave)),
      ],
    );
  }

  void _save() {
    if (displayNameViolation(_name.text.trim()) != null) {
      setState(() => _faulted = true);

      return;
    }

    Navigator.of(context).pop(_name.text.trim());
  }
}

/// The address, and the proof C14 asks for.
class _EmailDialog extends StatefulWidget {
  const _EmailDialog();

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _faulted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.accountEditEmail),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _email,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.accountEmail,
              border: const OutlineInputBorder(),
              errorText: _faulted ? l10n.accountEmailInvalid : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.accountCurrentPassword,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (String _) => _save(),
          ),
          const SizedBox(height: 12),
          // The half of C14 that survives somebody who already knows the
          // password: the notice to the old address is how the reader finds
          // out at all.
          Text(
            l10n.accountEmailNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.federationCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.accountSave)),
      ],
    );
  }

  void _save() {
    if (emailViolation(_email.text.trim()) != null) {
      setState(() => _faulted = true);

      return;
    }

    Navigator.of(context)
        .pop(EmailChange(password: _password.text, email: _email.text.trim()));
  }
}

/// The password, and the warning that goes with it.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();

  bool _faulted = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.accountEditPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _current,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.accountCurrentPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.accountNewPassword,
              border: const OutlineInputBorder(),
              errorText: _faulted ? l10n.accountPasswordInvalid : null,
            ),
            onSubmitted: (String _) => _save(),
          ),
          const SizedBox(height: 12),
          // Before the act and not after it. The node ends every session of
          // every device, and a reader who was not told would experience a
          // correct decision as the app breaking.
          Text(
            l10n.accountPasswordEndsSessions,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.federationCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.accountSave)),
      ],
    );
  }

  void _save() {
    if (passwordViolation(_next.text) != null) {
      setState(() => _faulted = true);

      return;
    }

    Navigator.of(context)
        .pop(PasswordChange(current: _current.text, next: _next.text));
  }
}

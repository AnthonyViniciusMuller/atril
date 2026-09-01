/// Removing the reader from their node (UC06, delete).
///
/// **The screen is two lists, and the second one is the point.** What deletion
/// reaches is the account on this node and everything the schema keys to it.
/// What it does not reach is a peer that already holds a copy — revoking never
/// reached one either, and RN03 is a promise about what *starts* rather than
/// about another operator's database — and the books and marks on this device,
/// which are the reader's own copy. Naming the peers rather than alluding to
/// them is why this screen reads the replica permissions: a reader deciding
/// what deletion costs should not have to guess who has their library.
///
/// **The local replica is left alone, and that is a decision rather than an
/// omission.** Erasing it would destroy the only remaining copy of everything
/// the node never received, and the export of phase 10 is how a reader takes
/// their marks with them. The session ends and nothing else does, which is what
/// signing out already means one step further on.
///
/// **It points at the migration.** The two calls exist separately on purpose,
/// and the difference between them is what they cost when the caller was wrong
/// about which they wanted.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/account/account_repository_impl.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/federation/federation_repository.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/delete_account_view_model.dart';

/// The account deletion screen.
class DeleteAccountScreen extends StatefulWidget {
  /// Creates the account deletion screen.
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  late final DeleteAccountViewModel _model = DeleteAccountViewModel(
    account: context.read<AccountRepository>(),
    auth: context.read<AuthRepository>(),
    federation: context.read<FederationRepository>(),
  );

  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model.delete.addListener(_onDeleted);
  }

  @override
  void dispose() {
    _model.delete.removeListener(_onDeleted);
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onDeleted() {
    if (_model.delete.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final domain = _model.signedIn?.originServerDomain ?? '';

    // Nothing navigates. Ending the session is what the shell's guard watches,
    // and the redirect that already exists is what sends this device back to
    // onboarding — the same argument signing out makes.
    switch (_model.delete.result) {
      case Ok<void>():
        _say(l10n.accountDeleted(domain));
      case Error<void>(:final error):
        _say(
          error is AppException && error.code == codeWrongPassword
              ? l10n.accountWrongPassword
              : l10n.accountDeleteFailed,
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountDelete)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_model, _model.delete]),
        builder: (BuildContext context, Widget? _) {
          final domain = _model.signedIn?.originServerDomain ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                l10n.accountDeleteExplanation,
                style: theme.textTheme.bodyMedium,
              ),
              _heading(theme, l10n.accountDeleteReaches),
              _line(
                theme,
                Icons.person_remove_outlined,
                l10n.accountDeleteThisServer(domain),
              ),
              _heading(theme, l10n.accountDeleteDoesNotReach),
              _line(theme, Icons.copy_all_outlined, l10n.accountDeleteReplicas),
              // Named where the node said who they are. An empty list means
              // *not known* rather than *none*, so the sentence above stays
              // either way and only the names come and go.
              if (_model.replicas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 12),
                  child: Text(
                    l10n.accountDeleteReplicaNames(_model.replicas.join(', ')),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _line(theme, Icons.menu_book_outlined, l10n.accountDeleteLocal),
              const SizedBox(height: 8),
              Text(
                l10n.accountDeleteIrreversible,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.go(Routes.migrate),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.accountDeleteMigrateInstead,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                enabled: !_model.delete.running,
                decoration: InputDecoration(
                  labelText: l10n.accountDeletePasswordLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: _model.delete.running ? null : _confirm,
                child: Text(l10n.accountDeleteConfirm),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Asks once more, because there is no screen after this one to ask on.
  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final domain = _model.signedIn?.originServerDomain ?? '';

    final delete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.accountDeleteThisServer(domain)),
        content: Text(l10n.accountDeleteIrreversible),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.federationCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountDeleteConfirm),
          ),
        ],
      ),
    );

    if (delete == true) {
      await _model.delete.execute(_password.text);
    }
  }

  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  Widget _line(ThemeData theme, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

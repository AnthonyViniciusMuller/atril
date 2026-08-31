/// UC08, first half: the reader asks for a recovery credential.
///
/// The screen keeps the promise the node makes. `RequestPasswordRecovery`
/// answers the same way whether or not the address is registered, and the
/// confirmation here is worded to say the same thing either way — a screen that
/// only congratulated addresses that exist would say by omission exactly what
/// the node refuses to say, and would turn a recovery form into a way of
/// finding out who has an account.
///
/// The address is still checked for shape, and that is a different question: it
/// is about what was typed and not about who exists.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/recovery_view_model.dart';

/// The recovery request screen.
class RecoveryScreen extends StatefulWidget {
  /// Creates the recovery request screen.
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  late final RecoveryViewModel _model;
  final TextEditingController _email = TextEditingController();

  @override
  void initState() {
    super.initState();

    _model = RecoveryViewModel(
      auth: context.read<AuthRepository>(),
      servers: context.read<ServerRepository>(),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recoveryTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              _model.load,
              _model.request,
            ]),
            builder: (BuildContext context, Widget? _) {
              final running = _model.request.running;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  Text(
                    l10n.recoveryExplanation(_model.node?.domain ?? ''),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    enabled: !running,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    textInputAction: TextInputAction.go,
                    onSubmitted: (String _) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.recoveryEmailLabel,
                      border: const OutlineInputBorder(),
                      errorText: _fieldFailure(l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: running ? null : _submit,
                    child: running
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.recoverySubmit),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: running
                        ? null
                        : () => context.go(Routes.resetPassword),
                    child: Text(l10n.recoveryHaveCode),
                  ),
                  ..._outcome(l10n, theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() => _model.request.execute(_email.text);

  /// What to say under the address, which is only ever about its shape.
  String? _fieldFailure(AppLocalizations l10n) =>
      switch (_model.request.result) {
        Error<void>(error: AppException(code: codeInvalidEmail)) =>
          l10n.registerEmailInvalid,
        _ => null,
      };

  /// The confirmation, or what went wrong reaching the node.
  List<Widget> _outcome(AppLocalizations l10n, ThemeData theme) {
    if (_model.request.completed) {
      return <Widget>[
        const SizedBox(height: 24),
        // Worded to be true whether or not the address is registered, which is
        // the whole promise this call exists to keep.
        Text(l10n.recoverySent, style: theme.textTheme.bodyMedium),
      ];
    }

    final failure = switch (_model.request.result) {
      Error<void>(:final AppException error)
          when error.code != codeInvalidEmail =>
        error,
      _ => null,
    };

    if (failure == null) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 24),
      Text(
        failure.kind == ErrorKind.unavailable
            ? l10n.recoveryUnreachable(_model.node?.domain ?? '')
            : l10n.recoveryFailed,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ];
  }
}

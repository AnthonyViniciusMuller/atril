/// UC08, second half: the reader spends the credential and chooses a new
/// password.
///
/// It is a location of its own rather than a step inside the request, because
/// the code arrives in a mail client — as often as not on another device — and
/// a reader coming back to this app has to be able to reach this screen without
/// asking for a second code they never needed. A link in the mail can carry the
/// credential in the location, which is what [token] is.
///
/// The node answers one refusal for four states — never issued, already spent,
/// expired, or belonging to somebody else — because which of them it was is a
/// fact about an account the caller has proved nothing about. This screen
/// repeats that indistinction rather than inventing an explanation for it.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/auth/auth_repository_impl.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/recovery_view_model.dart';

/// The password reset screen.
class PasswordResetScreen extends StatefulWidget {
  /// Creates the reset screen, with [token] filled in where a link carried
  /// one.
  const PasswordResetScreen({this.token, super.key});

  /// The recovery credential the location carried, or `null`.
  final String? token;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  late final RecoveryViewModel _model;
  late final TextEditingController _token = TextEditingController(
    text: widget.token,
  );
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();

    _model = RecoveryViewModel(
      auth: context.read<AuthRepository>(),
      servers: context.read<ServerRepository>(),
    );
    _model.reset.addListener(_onReset);
  }

  @override
  void dispose() {
    _model.reset.removeListener(_onReset);
    _token.dispose();
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: _model.reset,
            builder: (BuildContext context, Widget? _) {
              final running = _model.reset.running;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  // The second sentence is a warning and not a detail: whoever
                  // resets a password lost control of the old one, and leaving
                  // the sessions it opened alive would leave whoever took it
                  // signed in.
                  Text(l10n.resetExplanation, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _token,
                    enabled: !running,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.resetTokenLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failureOf(
                        _tokenCodes,
                        l10n.resetTokenInvalid,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    enabled: !running,
                    obscureText: true,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    textInputAction: TextInputAction.go,
                    onSubmitted: (String _) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.resetPasswordLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failureOf(const <String>{
                        codeInvalidPassword,
                      }, l10n.registerPasswordInvalid),
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
                        : Text(l10n.resetSubmit),
                  ),
                  ..._general(l10n, theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The codes that mean the credential is the problem.
  static const Set<String> _tokenCodes = <String>{
    codeNoCredential,
    codeInvalidCredential,
  };

  void _submit() => _model.reset.execute(
    PasswordReset(token: _token.text, password: _password.text),
  );

  /// Sends the reader to sign in once the password has changed.
  void _onReset() {
    if (!_model.reset.completed || !mounted) {
      return;
    }

    _model.reset.clearResult();

    context.go(
      Uri(
        path: Routes.signIn,
        queryParameters: <String, String>{
          Routes.doneParameter: Routes.passwordWasReset,
        },
      ).toString(),
    );
  }

  /// [message] where the refusal carries one of [codes], and `null` otherwise.
  String? _failureOf(Set<String> codes, String message) =>
      switch (_model.reset.result) {
        Error<void>(:final AppException error)
            when codes.contains(error.code) =>
          message,
        _ => null,
      };

  /// What to say about a refusal neither field explains.
  List<Widget> _general(AppLocalizations l10n, ThemeData theme) {
    final failure = switch (_model.reset.result) {
      Error<void>(:final AppException error)
          when !_tokenCodes.contains(error.code) &&
              error.code != codeInvalidPassword =>
        error,
      _ => null,
    };

    if (failure == null) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 16),
      Text(
        failure.kind == ErrorKind.unavailable
            ? l10n.recoveryUnreachable(_model.node?.domain ?? '')
            : l10n.resetFailed,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ];
  }
}

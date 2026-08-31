/// UC14: the reader creates an account on the node they chose.
///
/// The domain is not a field. It is which node the call is addressed to, and
/// therefore the second half of the identifier the reader is about to be given
/// — so the screen names it rather than offering it, and changing it means
/// going back to the screen that asked.
///
/// A successful registration signs nobody in, because the node does not:
/// `RegisterUser` answers with the reader and no session. So it hands the
/// reader to the sign-in screen with the name they just chose already typed
/// in, which is carried in the location rather than in a shared object — a
/// hand-off that survives a reload in a browser.
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
import '../view_model/register_view_model.dart';

/// The field names the node and this app both call the four inputs by.
///
/// They are the contract's own, which is what lets one mapping serve both a
/// refusal this device made and a refusal the node made: a `BadRequest` names
/// `local_name`, and so does the check that ran before anything travelled.
const String fieldLocalName = 'local_name';

/// The display name, as a violation names it.
const String fieldDisplayName = 'display_name';

/// The address, as a violation names it.
const String fieldEmail = 'email';

/// The password, as a violation names it.
const String fieldPassword = 'password';

/// The registration screen.
class RegisterScreen extends StatefulWidget {
  /// Creates the registration screen.
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterViewModel _model;
  final TextEditingController _localName = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();

    _model = RegisterViewModel(
      auth: context.read<AuthRepository>(),
      servers: context.read<ServerRepository>(),
    );
    _model.register.addListener(_onRegistered);
  }

  @override
  void dispose() {
    _model.register.removeListener(_onRegistered);
    _localName.dispose();
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              _model.load,
              _model.register,
            ]),
            builder: (BuildContext context, Widget? _) {
              final node = _model.node;
              final running = _model.register.running;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (node != null)
                    Text(
                      l10n.registerAt(node.domain),
                      style: theme.textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _localName,
                    enabled: !running,
                    autocorrect: false,
                    autofillHints: const <String>[AutofillHints.newUsername],
                    decoration: InputDecoration(
                      labelText: l10n.registerLocalNameLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failure(fieldLocalName, l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _displayName,
                    enabled: !running,
                    autofillHints: const <String>[AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: l10n.registerDisplayNameLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failure(fieldDisplayName, l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    enabled: !running,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.registerEmailLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failure(fieldEmail, l10n),
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
                      labelText: l10n.registerPasswordLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failure(fieldPassword, l10n),
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
                        : Text(l10n.registerSubmit),
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

  void _submit() => _model.register.execute(
    Registration(
      localName: _localName.text,
      displayName: _displayName.text,
      email: _email.text,
      password: _password.text,
    ),
  );

  /// Hands the reader to the sign-in screen once the account exists.
  void _onRegistered() {
    if (!_model.register.completed || !mounted) {
      return;
    }

    final created = _model.register.result?.valueOrNull;

    // Cleared, so that coming back to this screen does not navigate again on
    // the first rebuild.
    _model.register.clearResult();

    context.go(
      Uri(
        path: Routes.signIn,
        queryParameters: <String, String>{
          Routes.identifierParameter: created?.localName ?? '',
        },
      ).toString(),
    );
  }

  /// What to say under [field], or `null` when it is not what was refused.
  String? _failure(String field, AppLocalizations l10n) {
    final failure = _refusal();

    if (failure == null || !failure.fields.any((f) => f.name == field)) {
      return null;
    }

    return switch ((field, failure.code)) {
      (fieldLocalName, codeLocalNameTaken) => l10n.registerLocalNameTaken,
      (fieldLocalName, _) => l10n.registerLocalNameInvalid,
      (fieldDisplayName, _) => l10n.registerDisplayNameInvalid,
      (fieldEmail, codeEmailRegistered) => l10n.registerEmailTaken,
      (fieldEmail, _) => l10n.registerEmailInvalid,
      (fieldPassword, _) => l10n.registerPasswordInvalid,
      _ => null,
    };
  }

  /// What to say about a refusal no field explains.
  List<Widget> _general(AppLocalizations l10n, ThemeData theme) {
    final failure = _refusal();

    if (failure == null || failure.fields.isNotEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 16),
      Text(
        failure.kind == ErrorKind.unavailable
            ? l10n.registerUnreachable(_model.node?.domain ?? '')
            : l10n.registerFailed,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ];
  }

  /// The failure of the last attempt, or `null`.
  AppException? _refusal() => switch (_model.register.result) {
    Error<User>(:final AppException error) => error,
    _ => null,
  };
}

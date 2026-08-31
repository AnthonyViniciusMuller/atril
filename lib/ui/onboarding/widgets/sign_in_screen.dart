/// UC07: the reader proves who they are, and this device is bound.
///
/// It names the node the credentials are being sent to, and that is not
/// decoration: a password goes to one node and the reader cannot check
/// afterwards which one it was.
///
/// Nothing here navigates on success. Adopting the session is what the shell's
/// guard watches, so a device that signs in is redirected to its library by the
/// redirect that already exists — and a screen that pushed a route as well
/// would be a second answer to the question of where a signed-in device
/// belongs.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/platform.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../domain/models/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/sign_in_view_model.dart';

/// The node's code for credentials it will not accept.
const String codeInvalidCredentials = 'invalid_credentials';

/// The node's code for a reader it does not host.
///
/// It is answered by the same message as [codeInvalidCredentials]: telling the
/// two apart would let anybody find out who has an account on a node.
const String codeNoReaderNamed = 'no_reader_named';

/// The node's code for a device that has been unbound.
const String codeDeviceRevoked = 'device_revoked';

/// The sign-in screen.
class SignInScreen extends StatefulWidget {
  /// Creates the sign-in screen, with the identifier field filled in with
  /// [identifier] where something knows it already and a note about what
  /// [done] finished.
  ///
  /// Both come from the location, which is what a registration and a password
  /// reset hand on with: a reader who has just created an account should not
  /// have to type the name they chose a second time, and one who has just reset
  /// their password should be told why they are looking at a login screen.
  const SignInScreen({this.identifier, this.done, super.key});

  /// The identifier to start with, or `null`.
  final String? identifier;

  /// What was just finished elsewhere, or `null`.
  final String? done;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final SignInViewModel _model;
  late final TextEditingController _identifier = TextEditingController(
    text: widget.identifier,
  );
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();

    _model = SignInViewModel(
      auth: context.read<AuthRepository>(),
      servers: context.read<ServerRepository>(),
    );
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              _model.load,
              _model.signIn,
            ]),
            builder: (BuildContext context, Widget? _) {
              final node = _model.node;
              final running = _model.signIn.running;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (widget.done == Routes.passwordWasReset)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n.resetDone,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (node != null)
                    Text(
                      l10n.signInAt(node.domain),
                      style: theme.textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _identifier,
                    enabled: !running,
                    autocorrect: false,
                    autofillHints: const <String>[AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: l10n.signInIdentifierLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    enabled: !running,
                    obscureText: true,
                    autofillHints: const <String>[AutofillHints.password],
                    textInputAction: TextInputAction.go,
                    onSubmitted: (String _) => _submit(l10n),
                    decoration: InputDecoration(
                      labelText: l10n.signInPasswordLabel,
                      border: const OutlineInputBorder(),
                      errorText: _failure(l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: running ? null : () => _submit(l10n),
                    child: running
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.signInSubmit),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: running
                        ? null
                        : () => context.go(Routes.register),
                    child: Text(l10n.signInRegister),
                  ),
                  TextButton(
                    onPressed: running
                        ? null
                        : () => context.go(Routes.recover),
                    child: Text(l10n.signInForgot),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Sends the credentials, naming this device the way the reader's device list
  /// will show it.
  void _submit(AppLocalizations l10n) => _model.signIn.execute(
    Credentials(
      identifier: _identifier.text,
      password: _password.text,
      deviceName: l10n.deviceDefaultName(labelOfPlatform(devicePlatform)),
    ),
  );

  /// What to say about the last attempt.
  String? _failure(AppLocalizations l10n) {
    final result = _model.signIn.result;

    if (result is! Error<User>) {
      return null;
    }

    return switch (result.error) {
      AppException(code: codeInvalidCredentials) ||
      AppException(code: codeNoReaderNamed) => l10n.signInInvalidCredentials,
      AppException(code: codeDeviceRevoked) => l10n.signInDeviceRevoked,
      AppException(kind: ErrorKind.unavailable) => l10n.signInUnreachable(
        _model.node?.domain ?? '',
      ),
      _ => l10n.signInFailed,
    };
  }
}

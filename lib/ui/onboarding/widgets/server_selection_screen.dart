/// The first screen a new install shows: which node the reader's library lives
/// on.
///
/// It is not a preference and it cannot be skipped. The identifier is
/// `@local_name:server` and the server half is which node the call was
/// addressed to, so this screen is half of the reader's own name — nothing else
/// in onboarding can be asked before it is answered, and there is no default
/// that would be honest to offer.
///
/// A debug build lists the local federation, because typing `quire-a.example`
/// would reach nothing: `make dev-up` publishes addresses that resolve inside
/// its compose network, and the flavour is what knows the ones a host can
/// reach. A shipped build lists nothing and the reader types a domain.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/environment.dart';
import '../../../data/repositories/server/server_repository.dart';
import '../../../data/services/discovery/well_known.dart';
import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/server_selection_view_model.dart';

/// The server selection screen.
class ServerSelectionScreen extends StatefulWidget {
  /// Creates the server selection screen.
  const ServerSelectionScreen({super.key});

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  late final ServerSelectionViewModel _model;
  final TextEditingController _domain = TextEditingController();

  @override
  void initState() {
    super.initState();

    _model = ServerSelectionViewModel(
      servers: context.read<ServerRepository>(),
      environment: context.read<Environment>(),
    );
  }

  @override
  void dispose() {
    _domain.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingServerTitle)),
      body: Center(
        child: ConstrainedBox(
          // A paragraph read across a desktop window is a paragraph read one
          // line at a time, and a text field as wide as a monitor invites a URL
          // where a domain was asked for.
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            // Both commands, because both change what this screen shows: the
            // one that reads the node a returning device is pointed at, and
            // the one that changes it.
            listenable: Listenable.merge(<Listenable>[
              _model.load,
              _model.choose,
            ]),
            builder: (BuildContext context, Widget? _) => ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Text(
                  l10n.onboardingServerExplanation,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _domain,
                  enabled: !_model.choose.running,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (String domain) => _typed(),
                  decoration: InputDecoration(
                    labelText: l10n.onboardingServerFieldLabel,
                    hintText: l10n.onboardingServerFieldHint,
                    border: const OutlineInputBorder(),
                    errorText: _failure(l10n),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _model.choose.running ? null : _typed,
                  child: _model.choose.running
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.onboardingServerContinue),
                ),
                ..._chosen(l10n, theme),
                ..._federation(l10n, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Looks up whatever the reader typed.
  void _typed() => _model.choose.execute(ServerChoice(_domain.text));

  /// The confirmation of the node this device now talks to.
  List<Widget> _chosen(AppLocalizations l10n, ThemeData theme) {
    final chosen = _model.chosen;

    if (chosen == null || _model.choose.running) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 24),
      Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.onboardingServerChosen(chosen.domain),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ];
  }

  /// The nodes this build reaches in one tap, which is nothing in production.
  List<Widget> _federation(AppLocalizations l10n, ThemeData theme) {
    if (_model.federation.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 32),
      Text(l10n.onboardingServerDevelopment, style: theme.textTheme.titleSmall),
      for (final node in _model.federation)
        ListTile(
          // The label is the name the compose file next door gives the node, it
          // is shown in a debug build only, and it is not a message a reader of
          // this app will ever see in either language.
          title: Text(node.label), // l10n-ignore
          subtitle: Text(node.domain), // l10n-ignore
          enabled: !_model.choose.running,
          onTap: () => _model.choose.execute(
            ServerChoice(node.domain, discovery: node.discovery),
          ),
        ),
    ];
  }

  /// What to say about the last attempt, or `null` when there is nothing to
  /// say.
  String? _failure(AppLocalizations l10n) {
    final result = _model.choose.result;
    final domain = _model.attempted ?? '';

    if (result is! Error<ServerDescriptor>) {
      return null;
    }

    // The code and not the message: the node's own wording changes and the
    // reason does not, which is the whole point of carrying one.
    return switch (result.error) {
      AppException(code: codeNotAQuireServer) => l10n.onboardingServerNotQuire(
        domain,
      ),
      AppException(code: codeDiscoveryUnreachable) =>
        l10n.onboardingServerUnreachable(domain),
      AppException(code: codeInsecureDiscovery) =>
        l10n.onboardingServerInsecure(domain),
      _ => l10n.onboardingServerFailed(domain),
    };
  }
}

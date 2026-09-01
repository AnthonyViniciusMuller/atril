/// The reader's catalogue of nodes (UC12).
///
/// It is the first of the four screens phase 12 hangs under the settings, and
/// the one the other three depend on: a node has to be in this list before it
/// can be authorized to hold a copy, because the grant is addressed by the
/// identifier only the catalogue reports.
///
/// **It reads from the node and holds nothing.** That is a departure from every
/// other list in this app, which answers out of the local replica and is
/// therefore correct on a train. A catalogue entry is not a record that
/// replicates: it is what the reader's own node knows and enforces, it changes
/// on their other devices, and none of the four things this screen offers can
/// be done while the node cannot be reached. So a failed read says so and
/// offers to ask again, rather than showing a list from yesterday under
/// controls that would all fail.
///
/// **Deactivated nodes are listed.** `ListKnownServers` hides them by default
/// and this screen asks for them, because this is where the switch that
/// deactivated one lives — a list that hid them would have no way back from
/// the state its own control produces.
///
/// **A key that moved is reported and never applied quietly.** The node
/// re-pins on a refresh, and the reader is the only party who can tell a
/// rotation from an interception; the dialog says exactly that rather than
/// implying the app knows which happened.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/federation/federation_repository.dart';
import '../../../data/repositories/federation/federation_repository_impl.dart';
import '../../../data/services/api/federation_api.dart';
import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/known_servers_view_model.dart';

/// The known servers screen.
class KnownServersScreen extends StatefulWidget {
  /// Creates the known servers screen.
  const KnownServersScreen({super.key});

  @override
  State<KnownServersScreen> createState() => _KnownServersScreenState();
}

class _KnownServersScreenState extends State<KnownServersScreen> {
  late final KnownServersViewModel _model = KnownServersViewModel(
    federation: context.read<FederationRepository>(),
  );

  final TextEditingController _domain = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model.add.addListener(_onAdded);
  }

  @override
  void dispose() {
    _model.add.removeListener(_onAdded);
    _domain.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onAdded() {
    if (_model.add.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    switch (_model.add.result) {
      case Ok<KnownServer>(:final value):
        _domain.clear();
        _say(l10n.federationAdded(value.descriptor.domain));
      case Error<KnownServer>():
        // The field carries the one failure that is about what was typed;
        // everything else is about the node and belongs where the reader is
        // looking, not under a text box they have already left.
        if (!_typedWrong) {
          _say(_addFailure(l10n));
        }
      case null:
        break;
    }
  }

  /// Whether the last refusal was about the domain rather than about the node.
  bool get _typedWrong => switch (_model.add.result) {
    Error<KnownServer>(:final error)
        when error is AppException && error.code == codeInvalidDomain =>
      true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsKnownServers)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _model,
          _model.load,
          _model.add,
        ]),
        builder: (BuildContext context, Widget? _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                l10n.federationServersExplanation,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _domain,
                      enabled: !_model.add.running,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (String _) => _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.federationAddLabel,
                        hintText: l10n.federationAddHint,
                        border: const OutlineInputBorder(),
                        errorText: _typedWrong
                            ? l10n.federationAddInvalid
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FilledButton(
                      onPressed: _model.add.running ? null : _submit,
                      child: Text(l10n.federationAdd),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._catalogue(l10n, theme),
          ],
        ),
      ),
    );
  }

  void _submit() => _model.add.execute(_domain.text);

  /// The catalogue, or the one thing worth saying instead of it.
  List<Widget> _catalogue(AppLocalizations l10n, ThemeData theme) {
    if (_model.load.running && _model.servers.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_model.load.error && _model.servers.isEmpty) {
      return <Widget>[
        ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l10n.federationServersFailed),
          trailing: TextButton(
            onPressed: _model.load.execute,
            child: Text(l10n.federationRetry),
          ),
        ),
      ];
    }

    if (_model.servers.isEmpty) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.federationServersEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      for (final server in _model.servers)
        _ServerTile(
          server: server,
          onActive: (bool active) => _setActive(server, active: active),
          onRefresh: () => _refresh(server),
          onForget: () => _confirmForget(server),
        ),
    ];
  }

  Future<void> _setActive(KnownServer server, {required bool active}) async {
    final l10n = AppLocalizations.of(context);
    final outcome = await _model.setActive(server, active: active);

    if (outcome is Error<KnownServer>) {
      _say(l10n.federationActiveFailed);
    }
  }

  /// Re-runs discovery, and asks about the key when it moved.
  ///
  /// The dialog informs rather than offering a choice, because there is none
  /// left to offer: the node has already re-pinned, and what a reader does
  /// about a key they do not recognize is stop the node taking part — which is
  /// the switch on the same row.
  Future<void> _refresh(KnownServer server) async {
    final l10n = AppLocalizations.of(context);
    final outcome = await _model.refresh(server);

    if (!mounted) {
      return;
    }

    switch (outcome) {
      case Ok<ServerRefresh>(:final value) when value.fingerprintChanged:
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l10n.federationKeyChangedTitle),
            content: Text(
              l10n.federationKeyChangedExplanation(
                value.server.descriptor.domain,
              ),
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.federationKeyChangedUnderstood),
              ),
            ],
          ),
        );
      case Ok<ServerRefresh>(:final value):
        _say(l10n.federationRefreshed(value.server.descriptor.domain));
      case Error<ServerRefresh>():
        _say(l10n.federationRefreshFailed);
    }
  }

  Future<void> _confirmForget(KnownServer server) async {
    final l10n = AppLocalizations.of(context);
    final domain = server.descriptor.domain;

    final forget = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.federationForgetTitle(domain)),
        content: Text(l10n.federationForgetExplanation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.federationCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.federationForget),
          ),
        ],
      ),
    );

    if (forget != true) {
      return;
    }

    final outcome = await _model.forget(server);

    _say(switch (outcome) {
      Ok<void>() => l10n.federationForgotten(domain),
      // The node refuses while an active authorization names the node, and
      // that refusal has an answer the reader can act on — so it is named,
      // and everything else is not.
      Error<void>(:final error)
          when error is AppException &&
              error.kind == ErrorKind.failedPrecondition =>
        l10n.federationForgetRefused,
      Error<void>() => l10n.federationForgetFailed,
    });
  }

  /// What the node said about a domain this device could not fault.
  String _addFailure(AppLocalizations l10n) => switch (_model.add.result) {
    Error<KnownServer>(:final error)
        when error is AppException && error.kind == ErrorKind.alreadyExists =>
      l10n.federationAddAlreadyKnown,
    _ => l10n.federationAddFailed,
  };

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// One node, with everything discovery learned about it behind it.
///
/// The detail is folded away rather than shown, because a base URL, a gRPC
/// authority and a key digest are what a reader consults when something is
/// wrong and clutter when nothing is. The node the reader is signed in at
/// carries neither the switch nor the removal: it is not a peer they chose,
/// and there is nothing coherent for either control to do to it.
class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.onActive,
    required this.onRefresh,
    required this.onForget,
  });

  final KnownServer server;
  final ValueChanged<bool> onActive;
  final VoidCallback onRefresh;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final descriptor = server.descriptor;

    return ExpansionTile(
      leading: Icon(
        server.isOrigin ? Icons.home_outlined : Icons.dns_outlined,
        color: server.active ? null : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(descriptor.domain),
      subtitle: Text(
        server.isOrigin
            ? l10n.federationServerOrigin
            : server.active
            ? l10n.federationServerActive
            : l10n.federationServerInactive,
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: <Widget>[
        _detail(theme, l10n.federationServerBaseUrl(descriptor.baseUrl)),
        _detail(
          theme,
          descriptor.grpcAuthority == null
              ? l10n.federationServerGrpcAbsent
              : l10n.federationServerGrpc(descriptor.grpcAuthority!),
        ),
        _detail(
          theme,
          descriptor.certificateFingerprint == null
              ? l10n.federationServerFingerprintAbsent
              : l10n.federationServerFingerprint(
                  descriptor.certificateFingerprint!,
                ),
        ),
        _detail(theme, _discovered(context, l10n)),
        if (!server.isOrigin)
          SwitchListTile(
            value: server.active,
            onChanged: onActive,
            title: Text(l10n.federationServerActive),
          ),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: onRefresh,
              child: Text(l10n.federationRefresh),
            ),
            if (!server.isOrigin)
              TextButton(
                onPressed: onForget,
                child: Text(l10n.federationForget),
              ),
          ],
        ),
      ],
    );
  }

  String _discovered(BuildContext context, AppLocalizations l10n) {
    final at = server.discoveredAt;

    if (at == null) {
      return l10n.federationServerNeverDiscovered;
    }

    final dates = MaterialLocalizations.of(context);
    final local = at.toLocal();

    return l10n.federationServerDiscovered(
      dates.formatMediumDate(local),
      dates.formatTimeOfDay(TimeOfDay.fromDateTime(local)),
    );
  }

  Widget _detail(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
    child: Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

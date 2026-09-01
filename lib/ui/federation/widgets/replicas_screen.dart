/// Who may hold a copy of the reader's library (UC15, RF16).
///
/// **The screen states C22 rather than hiding it.** Nothing in the contract can
/// tell a node that it is a replica: `AuthorizeReplica` writes a permission on
/// the reader's *own* node, and the federation between the two operators is
/// arranged out of band. A screen that granted the permission and said nothing
/// would look like one where the copy is now flowing, and the reader would find
/// out otherwise by never finding out at all. So the note is permanent and sits
/// with the grants, not in a snackbar that scrolls away.
///
/// **What travels is a choice and not a checkbox.** Metadata without the files
/// is the cheap replica a reader is most likely to want on a node they do not
/// own — it is why the library's records do not reference the stored objects
/// (D02) — so the two options are offered side by side with a sentence each,
/// rather than as a box that reads *also replicate files* and explains nothing
/// about what leaving it clear buys.
///
/// **A withdrawn permission stays on the screen.** Revoking stops the
/// replication and does not reach into another operator's database, so the
/// record that a permission once existed is the only thing that explains a peer
/// still holding data. Hiding it would answer *nobody* to a reader asking who
/// has their library.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/federation/federation_repository.dart';
import '../../../domain/models/server.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/replicas_view_model.dart';

/// The replica authorization screen.
class ReplicasScreen extends StatefulWidget {
  /// Creates the replica authorization screen.
  const ReplicasScreen({super.key});

  @override
  State<ReplicasScreen> createState() => _ReplicasScreenState();
}

class _ReplicasScreenState extends State<ReplicasScreen> {
  late final ReplicasViewModel _model = ReplicasViewModel(
    federation: context.read<FederationRepository>(),
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
      appBar: AppBar(title: Text(l10n.settingsReplicas)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _model,
          _model.load,
          _model.authorize,
        ]),
        builder: (BuildContext context, Widget? _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.replicasExplanation,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            ..._body(l10n, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(AppLocalizations l10n, ThemeData theme) {
    if (_model.load.running && _model.granted.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_model.load.error) {
      return <Widget>[
        ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l10n.replicasFailed),
          trailing: TextButton(
            onPressed: _model.load.execute,
            child: Text(l10n.federationRetry),
          ),
        ),
      ];
    }

    return <Widget>[
      _heading(theme, l10n.replicasGrantedSection),
      if (_model.granted.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.replicasNone,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final grant in _model.granted)
        ListTile(
          leading: const Icon(Icons.copy_all_outlined),
          title: Text(grant.serverDomain),
          // Two lines and not one joined with a separator: the two facts are
          // two messages in the ARB, and a translator handed a string this
          // screen assembled would be translating a sentence nobody wrote.
          isThreeLine: true,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                grant.replicatesFiles
                    ? l10n.replicasWithFiles
                    : l10n.replicasWithoutFiles,
              ),
              Text(l10n.replicasGrantedAt(_on(context, grant.authorizedAt))),
            ],
          ),
          trailing: TextButton(
            onPressed: () => _confirmRevoke(grant),
            child: Text(l10n.replicasRevoke),
          ),
        ),
      // The standing truth, and not a message that scrolls away: the
      // permission is on this reader's node and the other one has not been
      // told anything (C22).
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.replicasOutOfBand,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.add),
        title: Text(l10n.replicasAuthorize),
        enabled: !_model.authorize.running,
        onTap: _chooseServer,
      ),
      if (_model.revoked.isNotEmpty) ...<Widget>[
        _heading(theme, l10n.replicasRevokedSection),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.replicasRevokedExplanation,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        for (final grant in _model.revoked)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(grant.serverDomain),
            subtitle: Text(
              l10n.replicasGrantedAt(_on(context, grant.authorizedAt)),
            ),
          ),
      ],
    ];
  }

  /// Asks which node, and then what it will hold.
  ///
  /// Two questions in two dialogs rather than one list of four options,
  /// because they are not the same kind of question: the first is *whom do you
  /// trust with this*, and the second is *how much*.
  Future<void> _chooseServer() async {
    final l10n = AppLocalizations.of(context);
    final candidates = _model.candidates;

    final chosen = await showDialog<KnownServer>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(l10n.replicasChooseServer),
        children: <Widget>[
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(l10n.replicasNoCandidates),
            ),
          for (final server in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(server),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(server.descriptor.domain),
                // Accepted by the node and useless in practice: a peer with no
                // gRPC authority is one nothing can replicate to, and saying so
                // here is cheaper than a reader wondering why nothing arrived.
                subtitle: server.descriptor.grpcAuthority == null
                    ? Text(l10n.replicasCandidateUndialable)
                    : null,
              ),
            ),
        ],
      ),
    );

    if (chosen == null || !mounted) {
      return;
    }

    await _chooseWhat(chosen);
  }

  Future<void> _chooseWhat(KnownServer server) async {
    final l10n = AppLocalizations.of(context);
    final domain = server.descriptor.domain;

    final files = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _WhatTravelsDialog(domain: domain),
    );

    if (files == null) {
      return;
    }

    await _model.authorize.execute(
      ReplicaGrant(serverId: server.id, replicatesFiles: files),
    );

    if (!mounted) {
      return;
    }

    _say(
      _model.authorize.result is Ok<ReplicaAuthorization>
          ? l10n.replicasAuthorized(domain)
          : l10n.replicasAuthorizeFailed,
    );
  }

  Future<void> _confirmRevoke(ReplicaAuthorization grant) async {
    final l10n = AppLocalizations.of(context);

    final revoke = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.replicasRevokeTitle(grant.serverDomain)),
        content: Text(l10n.replicasRevokeExplanation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.federationCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.replicasRevoke),
          ),
        ],
      ),
    );

    if (revoke != true) {
      return;
    }

    final outcome = await _model.revoke(grant.serverId);

    _say(
      outcome is Ok<void>
          ? l10n.replicasRevoked(grant.serverDomain)
          : l10n.replicasRevokeFailed,
    );
  }

  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  String _on(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatMediumDate(at.toLocal());

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// The second question: what the copy covers.
///
/// It is stateful because the two options are a choice made before it is
/// confirmed. A dialog that acted on the tap would make *metadata only* — the
/// answer a reader arrives at by reading both — one gesture away from the
/// wrong one.
class _WhatTravelsDialog extends StatefulWidget {
  const _WhatTravelsDialog({required this.domain});

  final String domain;

  @override
  State<_WhatTravelsDialog> createState() => _WhatTravelsDialogState();
}

class _WhatTravelsDialogState extends State<_WhatTravelsDialog> {
  /// Metadata only, which is the answer that costs the other operator least
  /// and the one this app suggests by selecting it.
  bool _files = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.replicasChooseWhat(widget.domain)),
      content: RadioGroup<bool>(
        groupValue: _files,
        onChanged: (bool? chosen) => setState(() => _files = chosen ?? _files),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RadioListTile<bool>(
              value: false,
              title: Text(l10n.replicasWithoutFiles),
              subtitle: Text(l10n.replicasWithoutFilesExplanation),
            ),
            RadioListTile<bool>(
              value: true,
              title: Text(l10n.replicasWithFiles),
              subtitle: Text(l10n.replicasWithFilesExplanation),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.federationCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_files),
          child: Text(l10n.replicasConfirm),
        ),
      ],
    );
  }
}

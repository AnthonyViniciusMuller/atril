/// The one line the settings screen gives synchronization.
///
/// It is a line and not the screen, because what a reader needs at a glance is
/// the count: everything else — when, why, what to do — is a question they only
/// ask once the count has told them there is something to ask about.
///
/// The one thing that displaces *see the state of the synchronization* is a
/// refusal, because a refusal is the only thing behind this line that asks the
/// reader to decide something. A change that is waiting needs no attention; a
/// change the node will not take needs exactly this much of it.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/sync/sync_repository.dart';
import '../../../routing/routes.dart';
import '../../core/localization/localization.dart';
import '../view_model/sync_view_model.dart';

/// The synchronization section of the settings screen.
class SyncSection extends StatefulWidget {
  /// Creates the synchronization section.
  const SyncSection({super.key});

  @override
  State<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<SyncSection> {
  late final SyncViewModel _model = SyncViewModel(
    sync: context.read<SyncRepository>(),
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

    return ListenableBuilder(
      listenable: _model,
      builder: (BuildContext context, Widget? _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.syncTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              _model.state.isHandedOver
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_upload_outlined,
            ),
            title: Text(l10n.syncPending(_model.state.pending)),
            subtitle: Text(
              _model.state.refused == 0
                  ? l10n.syncOpen
                  : l10n.syncRefusedCount(_model.state.refused),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.sync),
          ),
        ],
      ),
    );
  }
}

/// The federation section of the settings screen.
///
/// It is a section and not a destination for the reason the synchronization
/// one is: which nodes a reader federates with, and what they have allowed
/// each of them, is a property of the app rather than a fourth place to visit.
/// The shell has three destinations because three is what a reader navigates
/// *between*.
///
/// It holds no state and reads no repository. Everything behind these lines
/// is what the node knows, and asking for it on a screen the reader opened to
/// sign out would be a round trip nobody requested.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/localization.dart';

/// The federation section.
class FederationSection extends StatelessWidget {
  /// Creates the federation section.
  const FederationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            l10n.settingsFederationSection,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(l10n.settingsKnownServers),
          subtitle: Text(l10n.settingsKnownServersExplanation),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.servers),
        ),
        ListTile(
          leading: const Icon(Icons.copy_all_outlined),
          title: Text(l10n.settingsReplicas),
          subtitle: Text(l10n.settingsReplicasExplanation),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.replicas),
        ),
      ],
    );
  }
}

/// The account section of the settings screen.
///
/// It sits under the account lines phase 6 put there — the reader's name, the
/// identifier and the way out — because everything it leads to is about the
/// same thing: who this reader is at their node, and which devices may write
/// as them.
///
/// It holds no state and reads no repository. What is behind these lines is
/// what the node knows, and asking for it on a screen the reader opened to
/// sign out would be a round trip nobody requested.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/localization.dart';

/// The account section.
class AccountSection extends StatelessWidget {
  /// Creates the account section.
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.devices_other_outlined),
      title: Text(l10n.settingsDevices),
      subtitle: Text(l10n.settingsDevicesExplanation),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.devices),
    );
  }
}

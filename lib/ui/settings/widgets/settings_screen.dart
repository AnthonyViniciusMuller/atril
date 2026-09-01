/// The account, the devices, the known servers and the state of the sync.
///
/// It is one destination and several screens behind it, which is why it is a
/// branch of the shell and not a page pushed from somewhere: phase 11 put the
/// sync status here, phase 12 the federation and the account, and phase 4
/// already left it something to say — `SecureSessionStore.isSecure` is false on
/// the web, and a reader whose refresh credential is in `localStorage` is
/// entitled to be told so rather than to assume otherwise.
///
/// What phase 11 puts here is one line: how much this device has authored and
/// not handed over, and the way to the screen that explains it.
///
/// What phase 6 puts here is the account and the way out of it. Signing out
/// navigates nowhere: ending the session is what the shell's guard watches, and
/// the redirect that already exists is what sends the device back to
/// onboarding.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../account/widgets/account_section.dart';
import '../../core/localization/localization.dart';
import '../../federation/widgets/federation_section.dart';
import '../../sync/widgets/sync_section.dart';
import '../view_model/settings_view_model.dart';
import 'storage_section.dart';

/// The settings screen.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _model;

  @override
  void initState() {
    super.initState();

    _model = SettingsViewModel(auth: context.read<AuthRepository>());
  }

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
      appBar: AppBar(title: Text(l10n.navigationSettings)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_model, _model.signOut]),
        builder: (BuildContext context, Widget? _) {
          final reader = _model.signedIn;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.settingsAccountSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (reader != null)
                ListTile(
                  title: Text(reader.displayName),
                  // The whole identifier, with both halves: it says which node
                  // the library is on, and a reader may have an account on
                  // more than one.
                  subtitle: Text(l10n.settingsSignedInAs(reader.federatedId)),
                ),
              const AccountSection(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.settingsSignOut),
                subtitle: Text(l10n.settingsSignOutExplanation),
                enabled: !_model.signOut.running,
                onTap: _model.signOut.execute,
              ),
              const SyncSection(),
              const FederationSection(),
              const StorageSection(),
            ],
          );
        },
      ),
    );
  }
}

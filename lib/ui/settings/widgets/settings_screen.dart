/// The account, the devices, the known servers and the state of the sync.
///
/// It is one destination and several screens behind it, which is why it is a
/// branch of the shell and not a page pushed from somewhere: phase 11 puts the
/// sync status here, phase 12 the account, the devices and the federation, and
/// phase 4 already left it something to say — `SecureSessionStore.isSecure` is
/// false on the web, and a reader whose refresh credential is in
/// `localStorage` is entitled to be told so rather than to assume otherwise.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';

/// The settings screen.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).navigationSettings),
    ),
  );
}

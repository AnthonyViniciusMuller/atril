/// Where a device with no session is sent.
///
/// Phase 6 is what makes it a screen: discovering a server from a domain, the
/// selection that is half of the reader's `@local_name:server` identifier,
/// registration, login and device binding, and recovering a password. Until
/// then it is the destination the guard redirects to, and the app's name is
/// the honest amount of interface for a screen that cannot yet do anything.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';

/// The onboarding screen.
class OnboardingScreen extends StatelessWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: theme.textTheme.displaySmall,
        ),
      ),
    );
  }
}

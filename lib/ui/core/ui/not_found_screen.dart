/// What a location no route matches leads to.
///
/// It exists because one of the six targets has an address bar. On the five
/// native ones every location is reached from inside the app and a miss is a
/// bug; in a browser the reader can type a path, follow a link somebody sent
/// them, or come back to a bookmark of a screen that has since been renamed,
/// and the alternative to this screen is `go_router`'s own error page, which
/// is a stack trace on a red background.
///
/// It offers one way out and not a back button. A location that was never
/// valid has no history behind it — a pasted link is the first entry in the
/// tab — so the honest action is the one place a reader always wants to be.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../localization/localization.dart';

/// The screen shown for an unmatched location.
class NotFoundScreen extends StatelessWidget {
  /// The screen for [location], which is the address that matched nothing.
  const NotFoundScreen({required this.location, super.key});

  /// The address the reader asked for.
  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageNotFoundTitle)),
      body: Center(
        child: ConstrainedBox(
          // A paragraph read across a desktop window is a paragraph read one
          // line at a time. The measure is capped for the same reason the type
          // scale gives body text a line height.
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.pageNotFoundMessage(location),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(Routes.library),
                  child: Text(l10n.pageNotFoundAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

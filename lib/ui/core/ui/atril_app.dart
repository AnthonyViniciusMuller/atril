/// The app itself: the themes, the locales, and the router.
///
/// It is one widget shared by both entry points, because the two flavours
/// differ in what they are pointed at and in nothing a reader can see. A
/// second `MaterialApp` for the development build would be a second place to
/// register a delegate, and the one that gets forgotten is always the one
/// nobody runs.
///
/// It reads the router out of the graph rather than building one, so that the
/// navigation state of the three branches survives every rebuild above it.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../localization/localization.dart';
import '../themes/theme.dart';

/// The root widget.
class AtrilApp extends StatelessWidget {
  /// Creates the root widget.
  const AtrilApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    // `onGenerateTitle` and not `title`: the name is in the ARB like every
    // other string, and this is the callback that runs with a context the
    // delegates have already answered for. It is what a task switcher, a
    // window manager and a browser tab read.
    onGenerateTitle: (BuildContext context) =>
        AppLocalizations.of(context).appTitle,

    theme: AtrilTheme.light,
    darkTheme: AtrilTheme.dark,

    // The device already knows which the reader wants. Asking again in a
    // settings screen would be this app disagreeing with the platform about a
    // decision the platform owns.
    themeMode: ThemeMode.system,

    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,

    routerConfig: context.read<GoRouter>(),
  );
}

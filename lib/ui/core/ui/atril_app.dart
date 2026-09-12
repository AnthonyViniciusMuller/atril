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
import '../themes/appearance_view_model.dart';
import '../themes/theme.dart';

/// The root widget.
class AtrilApp extends StatelessWidget {
  /// Creates the root widget.
  const AtrilApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watched and not read: this is the one widget in the app that rebuilds
    // when the reader changes how the app is drawn, and it rebuilds for that
    // and for nothing else — the appearance is the only listenable above
    // `MaterialApp`.
    final AppearanceViewModel appearance = context.watch<AppearanceViewModel>();

    return MaterialApp.router(
      // `onGenerateTitle` and not `title`: the name is in the ARB like every
      // other string, and this is the callback that runs with a context the
      // delegates have already answered for. It is what a task switcher, a
      // window manager and a browser tab read.
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,

      // Both themes are registered whatever the mode is, because the mode can
      // be the device's: `MaterialApp` is what watches the platform's
      // brightness, and handing it one theme would be this widget doing that
      // job worse.
      theme: AtrilTheme.light(scheme: appearance.lightScheme),
      darkTheme: AtrilTheme.dark(scheme: appearance.darkScheme),

      themeMode: appearance.mode,

      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      routerConfig: context.read<GoRouter>(),
    );
  }
}

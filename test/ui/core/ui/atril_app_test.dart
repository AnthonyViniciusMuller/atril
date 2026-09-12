/// The root widget: what it registers, and where it gets it from.
///
/// Everything here is a wiring mistake that compiles. A missing delegate is an
/// app that throws on the first `AppLocalizations.of`; a title written into
/// the widget is a task switcher that says the same word in every language; a
/// router built in `build` is a reader who loses their place whenever anything
/// above them rebuilds. None of the three is visible in a diff.
library;

import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/appearance/system_seed.dart';
import 'package:atril/data/services/storage/appearance_store.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/routing/router.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/core/themes/colors.dart';
import 'package:atril/ui/core/themes/theme.dart';
import 'package:atril/ui/core/ui/atril_app.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/ui/onboarding/widgets/server_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../fakes/fakes.dart';

/// A refresher nothing here reaches.
final class _NeverAsked implements SessionRefresher {
  @override
  Future<Session> refreshSession(String refreshToken) =>
      throw StateError('the guard asked for a refresh');
}

/// A session good for a month.
Session _session() {
  final now = DateTime.now().toUtc();

  return Session(
    accessToken: 'access',
    accessTokenExpiresAt: now.add(const Duration(minutes: 5)),
    refreshToken: 'refresh',
    refreshTokenExpiresAt: now.add(const Duration(days: 30)),
  );
}

/// The two providers [AtrilApp] reaches for, over an in-memory store.
///
/// It is the shape of `providersFor` and not the thing itself: the real graph
/// opens a database file, a platform keychain and the device's connectivity,
/// none of which a widget test has. What is under test is the widget above the
/// graph, so what it is given is the part of the graph it reads.
List<SingleChildWidget> _providers(
  SessionHolder session, {
  AppearanceStore? appearance,
  SystemSeed? seed,
}) => <SingleChildWidget>[
  ...fakeProviders(appearance: appearance, seed: seed),
  Provider<SessionHolder>.value(value: session),
  Provider<GoRouter>(
    create: (_) => atrilRouter(session: session),
    dispose: (_, GoRouter router) => router.dispose(),
  ),
];

Future<SessionHolder> _pump(
  WidgetTester tester, {
  bool signedIn = true,
  AppearanceStore? appearance,
  SystemSeed? seed,
}) async {
  final session = SessionHolder(
    store: MemorySessionStore(),
    refresher: _NeverAsked.new,
  );

  if (signedIn) {
    await session.begin(_session());
  }

  addTearDown(session.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: _providers(session, appearance: appearance, seed: seed),
      child: const AtrilApp(),
    ),
  );
  await tester.pumpAndSettle();

  return session;
}

void main() {
  testWidgets('resolves its title from the ARB', (WidgetTester tester) async {
    await _pump(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Nothing set `MaterialApp.title`, and nothing should: a literal there is
    // a task switcher saying the same word whatever language the device is
    // in, and it is the one string no screen would ever show the mistake on.
    expect(app.title, anyOf(isNull, isEmpty));
    expect(
      app.onGenerateTitle,
      isNotNull,
      reason: 'the title is not being resolved against a locale',
    );
    expect(
      app.onGenerateTitle!(tester.element(find.byType(LibraryScreen))),
      'Atril',
    );
  });

  testWidgets('registers both themes and follows the device by default', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Both are registered whatever the mode is, because the mode can be the
    // device's and `MaterialApp` is what watches the platform's brightness.
    expect(app.theme, AtrilTheme.light());
    expect(app.darkTheme, AtrilTheme.dark());
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('is drawn the way the reader last left it', (
    WidgetTester tester,
  ) async {
    // A device that chose dark, on a platform with no colour of its own. What
    // is under test is the one thing a preference cannot do for itself: reach
    // the widget above every screen.
    await _pump(
      tester,
      appearance: MemoryAppearanceStore(const Appearance(mode: ThemeMode.dark)),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme, AtrilTheme.light());
    expect(app.darkTheme, AtrilTheme.dark());
  });

  testWidgets('grows both themes from the colour the platform offers', (
    WidgetTester tester,
  ) async {
    const Color wallpaper = Color(0xFF8E4585);

    await _pump(tester, seed: const MemorySystemSeed(wallpaper));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(
      app.theme?.colorScheme,
      atrilSchemeOf(brightness: Brightness.light, seed: wallpaper),
    );
    expect(
      app.darkTheme?.colorScheme,
      atrilSchemeOf(brightness: Brightness.dark, seed: wallpaper),
    );
    expect(app.theme?.colorScheme, isNot(atrilLightScheme));
  });

  testWidgets('keeps its own colours where the reader turned the others off', (
    WidgetTester tester,
  ) async {
    // The platform has a colour and the reader said no. The preference is what
    // decides, and it decides the same way on a device that has no colour to
    // refuse — which is why the store holds what the reader wants rather than
    // what this device can do.
    await _pump(
      tester,
      appearance: MemoryAppearanceStore(const Appearance(systemColors: false)),
      seed: const MemorySystemSeed(Color(0xFF8E4585)),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.colorScheme, atrilLightScheme);
    expect(app.darkTheme?.colorScheme, atrilDarkScheme);
  });

  testWidgets('registers the delegates and the locales', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.supportedLocales, AppLocalizations.supportedLocales);
    expect(
      app.supportedLocales.first,
      const Locale('pt', 'BR'),
      reason: 'the fallback locale is no longer Brazilian Portuguese',
    );

    // Material's own strings — the copy button in a text field, the labels in
    // a date picker — come from the global delegates. Without them a
    // translated app is translated only where this project wrote the string.
    expect(
      app.localizationsDelegates,
      containsAll(AppLocalizations.localizationsDelegates),
    );
  });

  testWidgets('takes the router from the graph and keeps it', (
    WidgetTester tester,
  ) async {
    final session = await _pump(tester);

    final before = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Anything above the app rebuilding must not replace the router: it holds
    // the navigation state of the three branches.
    await tester.pumpWidget(
      MultiProvider(providers: _providers(session), child: const AtrilApp()),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      same(before.routerConfig),
    );
  });

  testWidgets('shows onboarding on a device with no session', (
    WidgetTester tester,
  ) async {
    await _pump(tester, signedIn: false);

    expect(find.byType(ServerSelectionScreen), findsOneWidget);
  });
}

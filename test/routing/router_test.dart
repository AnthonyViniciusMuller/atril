/// The route table and the guard, exercised through a real router.
///
/// The guard is the one piece of this shell that can be wrong silently. A
/// redirect that stopped firing leaves an app that works perfectly for a
/// signed-in reader and shows a signed-out one an empty library instead of a
/// login, and every screen after this phase is written assuming it holds.
library;

import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/routing/router.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/annotations/widgets/annotations_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/core/ui/not_found_screen.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/ui/onboarding/widgets/register_screen.dart';
import 'package:atril/ui/onboarding/widgets/server_selection_screen.dart';
import 'package:atril/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/onboarding/fake_server_repository.dart';

/// A refresher nothing in this file reaches, since no test lets a token go
/// stale: the guard reads the stored credential and never exchanges it.
final class _NeverAsked implements SessionRefresher {
  @override
  Future<Session> refreshSession(String refreshToken) =>
      throw StateError('the guard asked for a refresh');
}

/// A session whose credential is good for a month.
Session _session() {
  final now = DateTime.now().toUtc();

  return Session(
    accessToken: 'access',
    accessTokenExpiresAt: now.add(const Duration(minutes: 5)),
    refreshToken: 'refresh',
    refreshTokenExpiresAt: now.add(const Duration(days: 30)),
  );
}

/// A holder over an empty store.
SessionHolder _holder() =>
    SessionHolder(store: MemorySessionStore(), refresher: _NeverAsked.new);

/// Pumps [router] inside the app the entry point builds around it.
Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MultiProvider(
      // The onboarding screens read their repositories out of the tree, so a
      // router test that lands on one has to supply them. Nothing here asserts
      // anything about them: what is under test is where the redirect went.
      providers: onboardingProviders(),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the guard', () {
    testWidgets('sends a device with no session to onboarding', (
      WidgetTester tester,
    ) async {
      final session = _holder();
      final router = atrilRouter(session: session);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(ServerSelectionScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
    });

    testWidgets('sends a device with a session away from onboarding', (
      WidgetTester tester,
    ) async {
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(
        session: session,
        initialLocation: Routes.onboarding,
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.byType(ServerSelectionScreen), findsNothing);
    });

    testWidgets('lets a signed-in device through to any destination', (
      WidgetTester tester,
    ) async {
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(session: session);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);
      expect(find.byType(LibraryScreen), findsOneWidget);

      router.go(Routes.annotations);
      await tester.pumpAndSettle();
      expect(find.byType(AnnotationsScreen), findsOneWidget);

      router.go(Routes.settings);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('reacts to a session that ends while a screen is open', (
      WidgetTester tester,
    ) async {
      // The case the redirect exists for and the one a navigation-time check
      // would miss: what signs a device out without the reader asking is a
      // refresh credential the node refused, and it happens while they are
      // looking at something.
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(session: session);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);
      expect(find.byType(LibraryScreen), findsOneWidget);

      await session.end();
      await tester.pumpAndSettle();

      expect(find.byType(ServerSelectionScreen), findsOneWidget);
    });

    testWidgets('treats every location below onboarding as onboarding', (
      WidgetTester tester,
    ) async {
      // Phase 6 hangs registration and password recovery below the prefix, and
      // a guard testing for equality would bounce a signed-out device off the
      // very screens it is being sent to use.
      final session = _holder();
      final router = atrilRouter(
        session: session,
        initialLocation: Routes.register,
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('an unmatched location', () {
    testWidgets('says which address it was, and offers the library', (
      WidgetTester tester,
    ) async {
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(
        session: session,
        initialLocation: '/nao-existe',
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.textContaining('/nao-existe'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryScreen), findsOneWidget);
    });
  });

  group('the shell', () {
    testWidgets('is what the caller passed, around the current branch', (
      WidgetTester tester,
    ) async {
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(
        session: session,
        shellBuilder: (BuildContext context, StatefulNavigationShell shell) =>
            Column(children: <Widget>[Expanded(child: shell)]),
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('gives each destination its own navigator', (
      WidgetTester tester,
    ) async {
      // The property `StatefulShellRoute` is chosen for: the branch a reader
      // leaves is kept, so coming back to it is coming back and not starting
      // over. What it means here is that all three are built and only one is
      // shown.
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(session: session);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      router.go(Routes.annotations);
      await tester.pumpAndSettle();

      expect(find.byType(AnnotationsScreen), findsOneWidget);
      expect(
        find.byType(LibraryScreen, skipOffstage: false),
        findsOneWidget,
        reason: 'the library branch was disposed rather than kept',
      );
    });
  });

  test('the shell destinations are the branches, in order', () {
    // The navigation surface indexes into this list and the router builds its
    // branches from the same order. One list is what keeps the two agreeing.
    expect(Routes.shell, <String>[
      Routes.library,
      Routes.annotations,
      Routes.settings,
    ]);
  });
}

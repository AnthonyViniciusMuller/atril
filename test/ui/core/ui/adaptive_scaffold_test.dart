/// The three layouts, at the widths that choose them.
///
/// What is worth pinning is not that a `NavigationRail` renders — Flutter's
/// own tests cover that — but the two thresholds, the fact that nothing about
/// the decision consults the platform, and that a tap moves the branch the
/// router is showing. A window resized across a threshold is what a desktop
/// reader does by dragging an edge, and it is the case a layout keyed on the
/// operating system gets wrong.
///
/// It is driven through a real router, because `StatefulNavigationShell` is
/// built by `go_router` and cannot be constructed beside it — and because a
/// test that rebuilt the widget's own logic to check the widget's own logic
/// would agree with anything.
library;

import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/routing/router.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/annotations/widgets/annotations_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/core/ui/adaptive_scaffold.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../fakes/fakes.dart';

/// A refresher nothing here reaches: the credential below is good for a month.
final class _NeverAsked implements SessionRefresher {
  @override
  Future<Session> refreshSession(String refreshToken) =>
      throw StateError('the guard asked for a refresh');
}

/// The app in a window [width] wide, on a signed-in device.
///
/// The window is resized rather than the app wrapped in a box, because a box
/// inside the test's own 800-pixel surface cannot be wider than it and every
/// desktop width would silently become 800. What is being exercised is the
/// widest of the three layouts, so the surface has to be able to hold it.
Future<GoRouter> _pumpAt(
  WidgetTester tester,
  double width, {
  Locale? locale,
  FakeSyncRepository? sync,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  final now = DateTime.now().toUtc();
  final session = SessionHolder(
    store: MemorySessionStore(),
    refresher: _NeverAsked.new,
  );

  await session.begin(
    Session(
      accessToken: 'access',
      accessTokenExpiresAt: now.add(const Duration(minutes: 5)),
      refreshToken: 'refresh',
      refreshTokenExpiresAt: now.add(const Duration(days: 30)),
    ),
  );

  final router = atrilRouter(session: session);

  addTearDown(router.dispose);
  addTearDown(session.dispose);

  await tester.pumpWidget(
    MultiProvider(
      // The settings destination reads its repository out of the tree. Nothing
      // here asserts anything about it: what is under test is which branch a
      // tap moves to.
      providers: fakeProviders(sync: sync),
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

void main() {
  group('the destinations', () {
    test('are the branches of the router, one for one', () {
      // The surface reports the index it was tapped at and the shell resolves
      // it against its branches. Two lists of different lengths is a tap that
      // opens nothing; two lists in a different order is a tap that opens the
      // wrong thing and says nothing about it.
      expect(destinations, hasLength(Routes.shell.length));
    });

    test('each have a filled twin for the selected state', () {
      for (final destination in destinations) {
        expect(destination.selectedIcon, isNot(destination.icon));
      }
    });

    test('exactly one carries the count of what has not been handed over', () {
      // One number, on the destination that leads to the screen explaining it.
      // Two badges would be two claims about the same fact, and a badge on the
      // library would be a claim about the wrong one.
      expect(
        destinations.where(
          (Destination destination) => destination.badgesPendingChanges,
        ),
        hasLength(1),
      );
    });
  });

  group('the badge', () {
    testWidgets('counts what has not left this device, in the bar', (
      WidgetTester tester,
    ) async {
      final sync = FakeSyncRepository()..emit(const SyncState(pending: 3));

      addTearDown(sync.dispose);

      await _pumpAt(tester, compactWidth - 1, sync: sync);

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('counts it in the rail too', (WidgetTester tester) async {
      // The badge is on the destination and not on one of the three layouts:
      // a reader who widened the window has not stopped being entitled to
      // know.
      final sync = FakeSyncRepository()..emit(const SyncState(pending: 2));

      addTearDown(sync.dispose);

      await _pumpAt(tester, compactWidth, sync: sync);

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('is absent while everything has been handed over', (
      WidgetTester tester,
    ) async {
      // A badge showing a nought is a permanent mark reporting that everything
      // is fine, which is the state a reader already assumes.
      final sync = FakeSyncRepository()..emit(const SyncState());

      addTearDown(sync.dispose);

      await _pumpAt(tester, compactWidth - 1, sync: sync);

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('appears when a change is authored', (
      WidgetTester tester,
    ) async {
      final sync = FakeSyncRepository();

      addTearDown(sync.dispose);

      await _pumpAt(tester, compactWidth - 1, sync: sync);

      expect(find.byType(Badge), findsNothing);

      sync.emit(const SyncState(pending: 1));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsOneWidget);
    });
  });

  group('the thresholds', () {
    testWidgets('put the navigation under the content below 600', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, compactWidth - 1);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('put a rail beside it from 600', (WidgetTester tester) async {
      await _pumpAt(tester, compactWidth);

      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
    });

    testWidgets('extend the rail from 1200', (WidgetTester tester) async {
      await _pumpAt(tester, expandedWidth);

      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
    });

    testWidgets('follow the width across a threshold', (
      WidgetTester tester,
    ) async {
      // A desktop window dragged narrow is a phone, and this is the moment it
      // becomes one. Nothing in the widget mentions a platform.
      await _pumpAt(tester, 1300);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );

      await _pumpAt(tester, 700);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );

      await _pumpAt(tester, 420);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('the labels', () {
    /// The label of the destination at [index], as the rail renders it.
    Finder inRail(String label) => find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text(label),
    );

    testWidgets('come from the ARB', (WidgetTester tester) async {
      await _pumpAt(tester, 700, locale: const Locale('pt', 'BR'));

      // Scoped to the rail: the library's own app bar carries the same word,
      // which is the point of one message serving the destination and the
      // title of the screen it opens.
      expect(inRail('Biblioteca'), findsOneWidget);
      expect(inRail('Anotações'), findsOneWidget);
      expect(inRail('Configurações'), findsOneWidget);
    });

    testWidgets('are translated where the locale is supported', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, 700, locale: const Locale('en'));

      expect(inRail('Library'), findsOneWidget);
      expect(inRail('Annotations'), findsOneWidget);
      expect(inRail('Settings'), findsOneWidget);
    });

    testWidgets('fall back to Brazilian Portuguese and not to English', (
      WidgetTester tester,
    ) async {
      // The reason `l10n.yaml` names `preferred-supported-locales`. Flutter
      // resolves an unsupported locale to the first entry of
      // `supportedLocales`, which gen-l10n orders alphabetically unless it is
      // told otherwise — and alphabetically is `en`.
      await _pumpAt(tester, 700, locale: const Locale('ja'));

      expect(inRail('Biblioteca'), findsOneWidget);
    });
  });

  group('a tap', () {
    testWidgets('moves the branch, from the bar', (WidgetTester tester) async {
      final router = await _pumpAt(tester, 420);

      expect(find.byType(LibraryScreen), findsOneWidget);

      await tester.tap(find.byIcon(destinations[1].icon));
      await tester.pumpAndSettle();

      expect(find.byType(AnnotationsScreen), findsOneWidget);
      expect(
        router.state.uri.toString(),
        Routes.annotations,
        reason: 'the location did not follow the destination',
      );
    });

    testWidgets('moves the branch, from the rail', (WidgetTester tester) async {
      await _pumpAt(tester, 1300);

      await tester.tap(find.byIcon(destinations[2].icon));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}

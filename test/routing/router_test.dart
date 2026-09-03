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
import 'package:atril/ui/account/widgets/account_screen.dart';
import 'package:atril/ui/account/widgets/delete_account_screen.dart';
import 'package:atril/ui/account/widgets/devices_screen.dart';
import 'package:atril/ui/annotations/widgets/annotations_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/core/ui/not_found_screen.dart';
import 'package:atril/ui/federation/widgets/known_servers_screen.dart';
import 'package:atril/ui/federation/widgets/migration_screen.dart';
import 'package:atril/ui/federation/widgets/replicas_screen.dart';
import 'package:atril/ui/library/widgets/ebook_screen.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/ui/onboarding/widgets/password_reset_screen.dart';
import 'package:atril/ui/onboarding/widgets/register_screen.dart';
import 'package:atril/ui/onboarding/widgets/server_selection_screen.dart';
import 'package:atril/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/fakes/fakes.dart';

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
      providers: fakeProviders(),
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

    testWidgets('remembers where a device with no session was going', (
      WidgetTester tester,
    ) async {
      // A link somebody shared, or the screen a reader was on when their
      // credential expired. Sending them to the library after they sign in
      // throws away the one thing they asked for.
      const String wanted = '/library/aaaaaaaa-1111-4111-8111-111111111111';
      final session = _holder();
      final router = atrilRouter(session: session, initialLocation: wanted);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);
      expect(find.byType(ServerSelectionScreen), findsOneWidget);

      await session.begin(_session());
      await tester.pumpAndSettle();

      expect(find.byType(EbookScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
    });

    testWidgets('remembers it across the screens onboarding is made of', (
      WidgetTester tester,
    ) async {
      // The parameter on `/onboarding` does not survive this: the server
      // selection goes to the sign-in screen with a bare path, as every screen
      // below the prefix goes to the next. The guard remembers its own
      // deflection for exactly this reason.
      const String wanted = '/library/aaaaaaaa-1111-4111-8111-111111111111';
      final session = _holder();
      final router = atrilRouter(session: session, initialLocation: wanted);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      router.go(Routes.signIn);
      await tester.pumpAndSettle();

      await session.begin(_session());
      await tester.pumpAndSettle();

      expect(find.byType(EbookScreen), findsOneWidget);
    });

    testWidgets('refuses a destination that is not a location of this app', (
      WidgetTester tester,
    ) async {
      // It arrives in the address bar, so what it is allowed to be is stated
      // rather than assumed: honouring an absolute URL would be this app
      // forwarding a reader who has just typed their password somewhere else.
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(
        session: session,
        initialLocation: Uri(
          path: Routes.onboarding,
          queryParameters: <String, String>{
            Routes.fromParameter: 'https://elsewhere.example/library',
          },
        ).toString(),
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('lets a signed-in device follow a password reset link', (
      WidgetTester tester,
    ) async {
      // The credential arrives in a mail client, as often as not on another
      // device. A reader who already has a session here is still a reader
      // changing their password, and the library discards the token.
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(
        session: session,
        initialLocation: Uri(
          path: Routes.resetPassword,
          queryParameters: <String, String>{Routes.tokenParameter: 'a-token'},
        ).toString(),
      );

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      expect(find.byType(PasswordResetScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
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

  testWidgets('one work is a location below the shelf it was opened from', (
    WidgetTester tester,
  ) async {
    // Below and not beside: the way back from a book is the shelf, a browser's
    // back button lands there whether or not this app accounts for it, and the
    // identifier is in the path so the location survives a reload and a link
    // somebody pasted.
    final session = _holder();
    await session.begin(_session());

    final router = atrilRouter(session: session);

    addTearDown(router.dispose);
    addTearDown(session.dispose);

    await _pump(tester, router);

    router.go(Routes.ebook('aaaaaaaa-1111-4111-8111-111111111111'));
    await tester.pumpAndSettle();

    expect(find.byType(EbookScreen), findsOneWidget);
    expect(
      router.state.pathParameters[Routes.ebookParameter],
      'aaaaaaaa-1111-4111-8111-111111111111',
    );
  });

  test('a mark\'s locator survives the URL it travels in', () {
    // It is a query parameter and not a path segment because it is not part of
    // the identity of the screen: the same reader, the same book, opened
    // somewhere else. What this pins is the encoding — a CFI is full of
    // slashes, brackets and commas, and one written into a location unescaped
    // would come back as a different locator or as no route at all.
    const String cfi = 'epubcfi(/6/14[chap05]!/4/10,/2/1:1,/3:4)';
    const String id = 'aaaaaaaa-1111-4111-8111-111111111111';

    final Uri location = Uri.parse(Routes.readEbook(id, at: cfi));

    expect(location.path, Routes.readEbook(id));
    expect(location.queryParameters[Routes.locatorParameter], cfi);
  });

  testWidgets('one work\'s marks are a location below the work', (
    WidgetTester tester,
  ) async {
    final session = _holder();
    await session.begin(_session());

    final router = atrilRouter(session: session);

    addTearDown(router.dispose);
    addTearDown(session.dispose);

    await _pump(tester, router);

    router.go(Routes.ebookMarks('aaaaaaaa-1111-4111-8111-111111111111'));
    await tester.pumpAndSettle();

    expect(find.byType(AnnotationsScreen), findsOneWidget);
  });

  testWidgets(
    'the federation and account screens are locations below the settings',
    (WidgetTester tester) async {
      // Below and not beside: the shell has three destinations because three is
      // what a reader navigates between, and closing this lands on the screen
      // that led here — which on the web is what the back button does anyway.
      final session = _holder();
      await session.begin(_session());

      final router = atrilRouter(session: session);

      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await _pump(tester, router);

      router.go(Routes.servers);
      await tester.pumpAndSettle();

      expect(find.byType(KnownServersScreen), findsOneWidget);

      router.go(Routes.replicas);
      await tester.pumpAndSettle();

      expect(find.byType(ReplicasScreen), findsOneWidget);

      router.go(Routes.migrate);
      await tester.pumpAndSettle();

      expect(find.byType(MigrationScreen), findsOneWidget);

      router.go(Routes.devices);
      await tester.pumpAndSettle();

      expect(find.byType(DevicesScreen), findsOneWidget);

      router.go(Routes.account);
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);

      router.go(Routes.deleteAccount);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    },
  );

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

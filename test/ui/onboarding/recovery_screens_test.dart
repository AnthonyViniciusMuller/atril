/// UC08 as a reader sees it, in both halves.
library;

import 'package:atril/data/repositories/auth/auth_repository_impl.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/onboarding/widgets/password_reset_screen.dart';
import 'package:atril/ui/onboarding/widgets/recovery_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

/// Where the sign-in screen would be, showing what the hand-off carried.
const String signInMarker = 'sign-in:';

Future<void> pump(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  String location = Routes.recover,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.recover,
        builder: (BuildContext context, GoRouterState state) =>
            RecoveryScreen(key: UniqueKey()),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.resetPasswordSegment,
            builder: (BuildContext context, GoRouterState state) =>
                PasswordResetScreen(
                  key: UniqueKey(),
                  token: state.uri.queryParameters[Routes.tokenParameter],
                ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (BuildContext context, GoRouterState state) => Text(
          '$signInMarker${state.uri.queryParameters[Routes.doneParameter]}',
          textDirection: TextDirection.ltr,
        ),
      ),
    ],
  );

  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(
        auth: auth,
        servers: FakeServerRepository()
          ..node = const ServerDescriptor(
            domain: 'quire-a.example',
            baseUrl: 'https://quire-a.example',
          ),
      ),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String? errorOf(WidgetTester tester, int field) => tester
    .widget<TextField>(find.byType(TextField).at(field))
    .decoration
    ?.errorText;

void main() {
  group('asking for a credential', () {
    testWidgets('sends the address and says nothing about who exists', (
      WidgetTester tester,
    ) async {
      final auth = FakeAuthRepository();

      await pump(tester, auth: auth);
      await tester.enterText(find.byType(TextField), 'ana@quire-a.example');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(auth.recoveries, <String>['ana@quire-a.example']);

      // The confirmation is worded to be true whether or not the address is
      // registered. A screen that only congratulated addresses that exist
      // would say by omission exactly what the node refuses to say.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.recoverySent), findsOneWidget);
    });

    testWidgets('says the same thing when the node refuses', (
      WidgetTester tester,
    ) async {
      // Nothing about a refusal may distinguish a registered address from an
      // unregistered one either, so the only failure a reader sees here is one
      // about reaching the node at all.
      final auth = FakeAuthRepository()
        ..refusal = const AppException(kind: ErrorKind.unavailable);

      await pump(tester, auth: auth);
      await tester.enterText(find.byType(TextField), 'ana@quire-a.example');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('quire-a.example'), findsWidgets);
    });
  });

  group('spending one', () {
    testWidgets('takes the credential a link carried', (
      WidgetTester tester,
    ) async {
      final auth = FakeAuthRepository();

      await pump(
        tester,
        auth: auth,
        location:
            '${Routes.resetPassword}'
            '?${Routes.tokenParameter}=recovery-1',
      );

      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'recovery-1',
      );
    });

    testWidgets('sends the credential and the new password', (
      WidgetTester tester,
    ) async {
      final auth = FakeAuthRepository();

      await pump(tester, auth: auth, location: Routes.resetPassword);
      await tester.enterText(find.byType(TextField).at(0), 'recovery-1');
      await tester.enterText(find.byType(TextField).at(1), 'a new passphrase');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(auth.resets.single, ('recovery-1', 'a new passphrase'));
    });

    testWidgets('sends the reader to sign in, saying why', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        auth: FakeAuthRepository(),
        location: Routes.resetPassword,
      );
      await tester.enterText(find.byType(TextField).at(0), 'recovery-1');
      await tester.enterText(find.byType(TextField).at(1), 'a new passphrase');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('$signInMarker${Routes.passwordWasReset}'),
        findsOneWidget,
      );
    });

    testWidgets('points a refused credential at the field it was typed into', (
      WidgetTester tester,
    ) async {
      final auth = FakeAuthRepository()
        ..refusal = const AppException(
          kind: ErrorKind.invalidArgument,
          code: codeInvalidCredential,
        );

      await pump(tester, auth: auth, location: Routes.resetPassword);
      await tester.enterText(find.byType(TextField).at(0), 'stale');
      await tester.enterText(find.byType(TextField).at(1), 'a new passphrase');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(errorOf(tester, 0), isNotNull);
      expect(errorOf(tester, 1), isNull);
    });
  });
}

/// UC14 as a reader sees it.
library;

import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/onboarding/widgets/register_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/routing/routes.dart';
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
}) async {
  // A real router, because a successful registration navigates: it hands the
  // reader to the sign-in screen with the name they chose in the location.
  final router = GoRouter(
    initialLocation: Routes.register,
    routes: <RouteBase>[
      GoRoute(
        // The key is unique per pump so that a test pumping twice gets a new
        // screen rather than the previous one's state under a new provider.
        path: Routes.register,
        builder: (BuildContext context, GoRouterState state) =>
            RegisterScreen(key: UniqueKey()),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (BuildContext context, GoRouterState state) => Text(
          '$signInMarker'
          '${state.uri.queryParameters[Routes.identifierParameter]}',
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

Future<void> fillIn(
  WidgetTester tester, {
  String localName = 'ana',
  String password = 'a passphrase',
}) async {
  final fields = find.byType(TextField);

  await tester.enterText(fields.at(0), localName);
  await tester.enterText(fields.at(1), 'Ana Maria');
  await tester.enterText(fields.at(2), 'ana@quire-a.example');
  await tester.enterText(fields.at(3), password);
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

String? errorOf(WidgetTester tester, int field) => tester
    .widget<TextField>(find.byType(TextField).at(field))
    .decoration
    ?.errorText;

void main() {
  testWidgets('names the node the identifier will be half of', (
    WidgetTester tester,
  ) async {
    // The domain is not a field: it is which node the call is addressed to,
    // and therefore the second half of the name the reader is about to get.
    await pump(tester, auth: FakeAuthRepository());

    expect(find.textContaining('quire-a.example'), findsOneWidget);
  });

  testWidgets('sends the four inputs the contract names', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();

    await pump(tester, auth: auth);
    await fillIn(tester);

    expect(auth.registrations.single.localName, 'ana');
    expect(auth.registrations.single.displayName, 'Ana Maria');
    expect(auth.registrations.single.email, 'ana@quire-a.example');
    expect(auth.registrations.single.password, 'a passphrase');
  });

  testWidgets('hands the reader to the sign-in screen with the name they '
      'chose', (WidgetTester tester) async {
    // RegisterUser answers with the reader and no session, so what follows a
    // registration is a login — and the reader should not have to type the
    // name they picked a second time.
    await pump(tester, auth: FakeAuthRepository());
    await fillIn(tester);

    expect(find.text('${signInMarker}ana'), findsOneWidget);
  });

  testWidgets('points a refusal at the field that caused it', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.alreadyExists,
        code: codeLocalNameTaken,
        fields: <FieldFailure>[FieldFailure('local_name', 'it is taken')],
      );

    await pump(tester, auth: auth);
    await fillIn(tester);

    expect(errorOf(tester, 0), isNotNull);
    expect(errorOf(tester, 1), isNull);
    expect(errorOf(tester, 2), isNull);
    expect(errorOf(tester, 3), isNull);
  });

  testWidgets('tells a taken name from a malformed one', (
    WidgetTester tester,
  ) async {
    final malformed = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.invalidArgument,
        code: codeInvalidLocalName,
        fields: <FieldFailure>[FieldFailure('local_name', 'it has a space')],
      );

    await pump(tester, auth: malformed);
    await fillIn(tester);

    final shape = errorOf(tester, 0);

    final taken = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.alreadyExists,
        code: codeLocalNameTaken,
        fields: <FieldFailure>[FieldFailure('local_name', 'it is taken')],
      );

    await pump(tester, auth: taken);
    await fillIn(tester);

    expect(errorOf(tester, 0), isNotNull);
    expect(errorOf(tester, 0), isNot(shape));
  });

  testWidgets('says something about a refusal no field explains', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository()
      ..refusal = const AppException(kind: ErrorKind.unavailable);

    await pump(tester, auth: auth);
    await fillIn(tester);

    for (var field = 0; field < 4; field++) {
      expect(errorOf(tester, field), isNull);
    }

    expect(find.textContaining('quire-a.example'), findsWidgets);
  });
}

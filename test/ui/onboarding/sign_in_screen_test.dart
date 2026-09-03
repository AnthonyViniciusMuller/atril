/// UC07 as a reader sees it.
library;

import 'package:atril/domain/models/server.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/onboarding/widgets/sign_in_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

Future<void> pump(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeServerRepository? servers,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(
        auth: auth,
        servers:
            servers ??
            (FakeServerRepository()
              ..node = const ServerDescriptor(
                domain: 'quire-a.example',
                baseUrl: 'https://quire-a.example',
              )),
      ),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SignInScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fillIn(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'reader');
  await tester.enterText(find.byType(TextField).last, 'a passphrase');
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names the node the password is being sent to', (
    WidgetTester tester,
  ) async {
    // The reader is about to type a password, and which node it goes to is the
    // one thing they cannot check afterwards.
    await pump(tester, auth: FakeAuthRepository());

    expect(find.textContaining('quire-a.example'), findsOneWidget);
  });

  testWidgets('sends the identifier, the password and a device name', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();

    await pump(tester, auth: auth);
    await fillIn(tester);

    expect(auth.attempts.single.identifier, 'reader');
    expect(auth.attempts.single.password, 'a passphrase');
    // The name the reader's device list will show, which is a user-visible
    // string and therefore comes from the ARB rather than from the repository.
    expect(auth.attempts.single.deviceName, isNotEmpty);
  });

  testWidgets('says the same thing about a wrong password and an unknown '
      'reader', (WidgetTester tester) async {
    // Telling the two apart would let anybody find out who has an account on a
    // node.
    final wrong = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unauthenticated,
        code: codeInvalidCredentials,
      );

    await pump(tester, auth: wrong);
    await fillIn(tester);

    final refused = tester
        .widget<TextField>(find.byType(TextField).last)
        .decoration
        ?.errorText;

    final unknown = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unauthenticated,
        code: codeNoReaderNamed,
      );

    await pump(tester, auth: unknown);
    await fillIn(tester);

    expect(
      tester
          .widget<TextField>(find.byType(TextField).last)
          .decoration
          ?.errorText,
      refused,
    );
    expect(refused, isNotNull);
  });

  testWidgets('says what an unbound device can do about it', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository()
      ..refusal = const AppException(
        kind: ErrorKind.permissionDenied,
        code: codeDeviceRevoked,
      );

    await pump(tester, auth: auth);
    await fillIn(tester);

    expect(
      tester
          .widget<TextField>(find.byType(TextField).last)
          .decoration
          ?.errorText,
      isNotNull,
    );
  });
}

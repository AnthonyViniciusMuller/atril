/// The account section, and the way out of it.
library;

import 'package:atril/domain/models/user.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

final User _reader = User(
  id: '22222222-2222-4222-8222-222222222222',
  localName: 'ana',
  displayName: 'Ana Maria',
  originServerDomain: 'quire-a.example',
  federatedId: '@ana:quire-a.example',
  createdAt: DateTime.utc(2026),
);

Future<void> pump(WidgetTester tester, FakeAuthRepository auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(auth: auth),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names the reader by the whole federated identifier', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();

    await pump(tester, auth);
    auth.readers.add(_reader);
    await tester.pumpAndSettle();

    // Both halves: the identifier says which node the library is on, and a
    // reader may have an account on more than one.
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.textContaining('@ana:quire-a.example'), findsOneWidget);
  });

  testWidgets('stops naming a reader the moment the session ends', (
    WidgetTester tester,
  ) async {
    // What signs a device out without the reader asking is a refresh credential
    // the node refused, and it happens while they are looking at something.
    final auth = FakeAuthRepository();

    await pump(tester, auth);
    auth.readers.add(_reader);
    await tester.pumpAndSettle();

    auth.readers.add(null);
    await tester.pumpAndSettle();

    expect(find.text('Ana Maria'), findsNothing);
  });

  testWidgets('signs out, and says what signing out does not do', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();

    await pump(tester, auth);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    // The library, the annotations and the changes this device still owes stay
    // here, and a reader has no way of knowing that unless it is said.
    expect(find.byType(ListTile), findsWidgets);
  });
}

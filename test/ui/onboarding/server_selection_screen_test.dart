/// The first screen a new install shows.
library;

import 'package:atril/config/environment.dart';
import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/onboarding/widgets/server_selection_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

Future<void> pump(
  WidgetTester tester, {
  required FakeServerRepository servers,
  Environment? environment,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(servers: servers, environment: environment),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ServerSelectionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('looks up the domain the reader typed', (
    WidgetTester tester,
  ) async {
    final servers = FakeServerRepository();

    await pump(tester, servers: servers);
    await tester.enterText(find.byType(TextField), 'quire-a.example');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(servers.asked.single.domain, 'quire-a.example');
    // A typed domain carries no discovery address: RFC 8615 says where the
    // document is, and a lookup that could be pointed elsewhere would be a
    // lookup an attacker could point.
    expect(servers.asked.single.discovery, isNull);
  });

  testWidgets('says which node it settled on', (WidgetTester tester) async {
    final servers = FakeServerRepository();

    await pump(tester, servers: servers);
    await tester.enterText(find.byType(TextField), 'quire-a.example');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('quire-a.example'), findsWidgets);
  });

  testWidgets('offers the local federation in a development build', (
    WidgetTester tester,
  ) async {
    final servers = FakeServerRepository();

    await pump(
      tester,
      servers: servers,
      environment: Environment.development(),
    );

    expect(find.text('Node A'), findsOneWidget);
    expect(find.text('Node B'), findsOneWidget);

    await tester.tap(find.text('Node A'));
    await tester.pumpAndSettle();

    // Tapped, it is looked up where the flavour says the document is and not
    // at the address the node publishes about itself.
    expect(servers.asked.single.domain, 'quire-a.example');
    expect(servers.asked.single.discovery, Uri.parse('http://127.0.0.1:18080'));
  });

  testWidgets('offers no federation in a shipped build', (
    WidgetTester tester,
  ) async {
    await pump(tester, servers: FakeServerRepository());

    expect(find.text('Node A'), findsNothing);
  });

  testWidgets('names the refusal on the field that caused it', (
    WidgetTester tester,
  ) async {
    final servers = FakeServerRepository()
      ..refusal = const AppException(
        kind: ErrorKind.failedPrecondition,
        code: codeNotAQuireServer,
      );

    await pump(tester, servers: servers);
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.decoration?.errorText, contains('example.com'));
  });

  testWidgets('leads on to signing in once a node is chosen', (
    WidgetTester tester,
  ) async {
    final servers = FakeServerRepository();

    await pump(tester, servers: servers);

    // Nothing to go on to until a node has been chosen: the way onward names
    // the node it leads to.
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'quire-a.example');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsNWidgets(2));
  });

  testWidgets('shows the node a returning device is already pointed at', (
    WidgetTester tester,
  ) async {
    final servers = FakeServerRepository()
      ..node = const ServerDescriptor(
        domain: 'quire-a.example',
        baseUrl: 'https://quire-a.example',
      );

    await pump(tester, servers: servers);

    expect(find.textContaining('quire-a.example'), findsWidgets);
  });
}

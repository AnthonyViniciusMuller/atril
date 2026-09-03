/// The catalogue, and the three things about it a reader can get wrong.
///
/// What is pinned here is what the screen *claims*: that a node the reader has
/// deactivated is still shown, because this is where it is turned back on;
/// that a failed read says the node did not answer instead of showing an empty
/// federation; and that a key which moved is put in front of the reader rather
/// than absorbed. The last is the one that matters most — a rotation and an
/// interception look identical from here, and the reader is the only party who
/// can tell them apart.
library;

import 'package:atril/data/repositories/federation/federation_repository_impl.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/federation/widgets/known_servers_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

const KnownServer _origin = KnownServer(
  id: 'origin',
  descriptor: ServerDescriptor(
    domain: 'quire-a.example',
    baseUrl: 'https://quire-a.example',
    grpcAuthority: 'quire-a.example:9090',
    certificateFingerprint: 'spki-sha256:AAAA',
  ),
  isOrigin: true,
  active: true,
);

const KnownServer _peer = KnownServer(
  id: 'peer',
  descriptor: ServerDescriptor(
    domain: 'quire-b.example',
    baseUrl: 'https://quire-b.example',
  ),
  isOrigin: false,
  active: false,
);

/// The screen over [federation], in Brazilian Portuguese as the app's default
/// is.
Future<void> _pump(
  WidgetTester tester,
  FakeFederationRepository federation,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(federation: federation),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: KnownServersScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists what the node holds, deactivated nodes included', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer];

    await _pump(tester, federation);

    expect(find.text('quire-a.example'), findsOneWidget);
    expect(find.text('quire-b.example'), findsOneWidget);
    expect(find.text('Fora da replicação'), findsOneWidget);
  });

  testWidgets('names the node the reader is signed in at', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin];

    await _pump(tester, federation);

    expect(find.text('O seu servidor'), findsOneWidget);
  });

  testWidgets('a node that did not answer is said, not shown as empty', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'federation/servers: catalogue',
      );

    await _pump(tester, federation);

    expect(
      find.text('Não foi possível ler o catálogo. O servidor não respondeu.'),
      findsOneWidget,
    );
    expect(
      find.text('Você ainda não adicionou nenhum servidor.'),
      findsNothing,
    );
  });

  testWidgets('asking again is offered and asks again', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'federation/servers: catalogue',
      );

    await _pump(tester, federation);
    expect(federation.reads, 1);

    federation.refusal = null;
    federation.catalogue = <KnownServer>[_origin];

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(federation.reads, 2);
    expect(find.text('quire-a.example'), findsOneWidget);
  });

  testWidgets('a domain that is not one is faulted under the field', (
    WidgetTester tester,
  ) async {
    // The repository is what refuses it, before anything travels; what this
    // pins is where the refusal lands. A message about what was typed belongs
    // under the box it was typed into, and a message about the node belongs
    // where the reader is looking — and the screen tells the two apart by the
    // code rather than by guessing from the kind.
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.invalidArgument,
        message:
            'the domain "not a domain" may contain only lower-case '
            'letters, digits, dots and hyphens',
        code: codeInvalidDomain,
        op: 'federation/servers: add',
      );

    await _pump(tester, federation);

    await tester.enterText(find.byType(TextField), 'not a domain');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Isto não é um endereço de servidor.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a node that refused the addition says so where it is read', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.alreadyExists,
        message: 'that domain is already known',
        op: 'federation/servers: add',
      );

    await _pump(tester, federation);

    await tester.enterText(find.byType(TextField), 'quire-b.example');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Este servidor já está no seu catálogo.'), findsOneWidget);
  });

  testWidgets('a domain that is one is added and the field is cleared', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository();

    await _pump(tester, federation);

    await tester.enterText(find.byType(TextField), 'quire-b.example');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(federation.added, <String>['quire-b.example']);
    expect(find.text('quire-b.example foi adicionado.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('the reader\'s own node offers no removal', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-a.example'));
    await tester.pumpAndSettle();

    // It is not a peer the reader chose, and there is nothing coherent for a
    // removal or a replication switch to do to it.
    expect(find.text('Esquecer'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Redescobrir'), findsOneWidget);
  });

  testWidgets('what discovery learned is behind the row and not on it', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin];

    await _pump(tester, federation);
    expect(find.text('Chave spki-sha256:AAAA'), findsNothing);

    await tester.tap(find.text('quire-a.example'));
    await tester.pumpAndSettle();

    expect(find.text('Chave spki-sha256:AAAA'), findsOneWidget);
    expect(find.text('Responde em https://quire-a.example'), findsOneWidget);
  });

  testWidgets('a node that publishes no gRPC address says what that costs', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não publica endereço gRPC — nada replica para ele.'),
      findsOneWidget,
    );
    expect(find.text('Nenhuma chave fixada.'), findsOneWidget);
  });

  testWidgets('a key that moved is put in front of the reader', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer]
      ..fingerprintChanges = true;

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redescobrir'));
    await tester.pumpAndSettle();

    expect(find.text('A chave deste servidor mudou'), findsOneWidget);
    expect(federation.refreshed, <String>['peer']);
  });

  testWidgets('a key that did not move says so and asks nothing', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redescobrir'));
    await tester.pumpAndSettle();

    expect(find.text('A chave deste servidor mudou'), findsNothing);
    expect(
      find.text('quire-b.example foi redescoberto e a chave é a mesma.'),
      findsOneWidget,
    );
  });

  testWidgets('forgetting asks first, and says what it does not reach', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Esquecer'));
    await tester.pumpAndSettle();

    expect(find.text('Esquecer quire-b.example?'), findsOneWidget);
    expect(
      find.textContaining('esquecer não alcança o banco de outro operador'),
      findsOneWidget,
    );
    expect(federation.forgotten, isEmpty);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(federation.forgotten, isEmpty);
  });

  testWidgets('a peer that still holds a copy is refused in its own words', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    federation.refusal = const AppException(
      kind: ErrorKind.failedPrecondition,
      message: 'an authorization names it',
      op: 'federation/servers: forget',
    );

    await tester.tap(find.text('Esquecer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Esquecer'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Este servidor guarda uma cópia sua. Revogue a réplica antes de '
        'esquecê-lo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the switch sends what the reader asked for', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_peer];

    await _pump(tester, federation);
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(federation.switched, <(String, bool)>[('peer', true)]);
  });
}

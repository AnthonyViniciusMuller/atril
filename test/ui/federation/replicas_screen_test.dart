/// Who holds a copy, and the three things this screen has to say out loud.
///
/// C22 is the first: the permission is written on the reader's own node, the
/// origin carries it to the other one only at delivery, and that node listens
/// only to an origin its own catalogue names, so the screen says so permanently
/// rather than looking like a switch that started something. The second is that a withdrawn permission stays listed, because
/// revoking does not reach into another operator's database and the record is
/// what explains a peer that still has data. The third is that *what travels*
/// is a choice with two sentences and not a box nobody reads.
library;

import 'package:atril/domain/models/server.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/federation/widgets/replicas_screen.dart';
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
  ),
  isOrigin: true,
  active: true,
);

const KnownServer _peer = KnownServer(
  id: 'peer',
  descriptor: ServerDescriptor(
    domain: 'quire-b.example',
    baseUrl: 'https://quire-b.example',
    grpcAuthority: 'quire-b.example:9090',
  ),
  isOrigin: false,
  active: true,
);

/// A node in the catalogue that nothing can replicate to.
const KnownServer _undialable = KnownServer(
  id: 'undialable',
  descriptor: ServerDescriptor(
    domain: 'quire-c.example',
    baseUrl: 'https://quire-c.example',
  ),
  isOrigin: false,
  active: true,
);

ReplicaAuthorization _grant({
  String serverId = 'peer',
  String domain = 'quire-b.example',
  bool files = false,
  bool active = true,
}) => ReplicaAuthorization(
  id: 'grant',
  serverId: serverId,
  serverDomain: domain,
  authorizedAt: DateTime.utc(2026, 9),
  replicatesFiles: files,
  active: active,
);

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
        home: ReplicasScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('says what the permission does not reach, always', (
    WidgetTester tester,
  ) async {
    // C22. The other node is told at delivery and only listens to an origin
    // it already knows, and a screen that granted the permission and said
    // nothing would look like one where the copy is already flowing.
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer];

    await _pump(tester, federation);

    expect(
      find.textContaining('Aquele servidor só aceita se já conhecer o seu'),
      findsOneWidget,
    );
  });

  testWidgets('an empty federation says nobody rather than nothing', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin];

    await _pump(tester, federation);

    expect(
      find.text('Nenhum servidor guarda uma cópia dos seus dados.'),
      findsOneWidget,
    );
  });

  testWidgets('lists what each authorized node holds', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer]
      ..grants = <ReplicaAuthorization>[_grant(files: true)];

    await _pump(tester, federation);

    expect(find.text('quire-b.example'), findsOneWidget);
    expect(find.textContaining('Metadados e arquivos'), findsOneWidget);
  });

  testWidgets('a withdrawn permission stays, under its own heading', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer]
      ..grants = <ReplicaAuthorization>[_grant(active: false)];

    await _pump(tester, federation);

    expect(find.text('Guardaram uma cópia'), findsOneWidget);
    expect(
      find.textContaining('revogar não alcança o banco de outro operador'),
      findsOneWidget,
    );
  });

  testWidgets('a node that did not answer is said, not shown as empty', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'federation/replicas: list',
      );

    await _pump(tester, federation);

    expect(
      find.text(
        'Não foi possível ler as autorizações. O servidor não '
        'respondeu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('offers the nodes that could still hold a copy, and no others', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer, _undialable]
      ..grants = <ReplicaAuthorization>[_grant()];

    await _pump(tester, federation);
    await tester.tap(find.text('Autorizar um servidor'));
    await tester.pumpAndSettle();

    // The reader's own node is where their library already is, and the peer
    // that holds a copy already holds one.
    expect(find.text('quire-a.example'), findsNothing);
    expect(find.text('quire-c.example'), findsOneWidget);
    expect(
      find.text('Não publica endereço gRPC — nada replica para ele.'),
      findsOneWidget,
    );
  });

  testWidgets('what travels is two options with a sentence each', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer];

    await _pump(tester, federation);
    await tester.tap(find.text('Autorizar um servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();

    expect(find.text('O que quire-b.example vai guardar'), findsOneWidget);
    expect(find.textContaining('É a réplica barata'), findsOneWidget);
    expect(
      find.textContaining('Ocupa neste servidor o mesmo espaço'),
      findsOneWidget,
    );
  });

  testWidgets('the cheap replica is what is offered first', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer];

    await _pump(tester, federation);
    await tester.tap(find.text('Autorizar um servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar'));
    await tester.pumpAndSettle();

    // Metadata without the files is what a reader most often wants on a node
    // they do not own, so it is what a reader who reads neither sentence gets.
    expect(federation.authorized, <(String, bool)>[('peer', false)]);
    expect(
      find.text('quire-b.example pode guardar uma cópia.'),
      findsOneWidget,
    );
  });

  testWidgets('choosing the files sends the files', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer];

    await _pump(tester, federation);
    await tester.tap(find.text('Autorizar um servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quire-b.example'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metadados e arquivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar'));
    await tester.pumpAndSettle();

    expect(federation.authorized, <(String, bool)>[('peer', true)]);
  });

  testWidgets('revoking asks first, and says what it cannot undo', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer]
      ..grants = <ReplicaAuthorization>[_grant()];

    await _pump(tester, federation);
    await tester.tap(find.text('Revogar'));
    await tester.pumpAndSettle();

    expect(find.text('Revogar quire-b.example?'), findsOneWidget);
    expect(
      find.textContaining('revogar não apaga nada do banco de outro operador'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(federation.revoked, isEmpty);
  });

  testWidgets('a confirmed revocation stops the replication', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..catalogue = <KnownServer>[_origin, _peer]
      ..grants = <ReplicaAuthorization>[_grant()];

    await _pump(tester, federation);
    await tester.tap(find.text('Revogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Revogar'));
    await tester.pumpAndSettle();

    expect(federation.revoked, <String>['peer']);
    expect(find.text('quire-b.example não recebe mais nada.'), findsOneWidget);
    expect(find.text('Guardaram uma cópia'), findsOneWidget);
  });
}

/// The wizard, and the four things it has to say before it does anything.
///
/// It is a wizard because the operation cannot be undone, so what is pinned
/// here is the deliberation: that the identifier changes, that the replicas
/// have to be authorized again, that nothing is cleared, and that this device
/// only starts talking to the new node at the last step. The other half is the
/// devices — worked out when the wizard opens, because the call that names
/// them goes to the node this screen is about to stop talking to.
library;

import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/federation/widgets/migration_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
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

const CarriedDevices _two = CarriedDevices(
  named: true,
  devices: <CarriedDevice>[
    CarriedDevice(
      id: '11111111-1111-4111-8111-111111111111',
      isThisDevice: true,
      name: 'Celular',
      platform: 'android',
    ),
    CarriedDevice(
      id: '99999999-9999-4999-8999-999999999999',
      isThisDevice: false,
      name: 'Notebook',
      platform: 'linux',
    ),
  ],
);

const CarriedDevices _unnamed = CarriedDevices(
  named: false,
  devices: <CarriedDevice>[
    CarriedDevice(
      id: '11111111-1111-4111-8111-111111111111',
      isThisDevice: true,
      name: 'Celular',
      platform: 'android',
    ),
    CarriedDevice(
      id: '99999999-9999-4999-8999-999999999999',
      isThisDevice: false,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  FakeFederationRepository federation, {
  FakeAuthRepository? auth,
}) async {
  final reading = auth ?? FakeAuthRepository();

  // A tall surface, because the wizard is a form and the default 800x600 test
  // window puts its controls below the fold — which is a fact about the test
  // window and not about the screen.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(federation: federation, auth: reading),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MigrationScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
  reading.readers.add(Result<User?>.ok(_reader));
  await tester.pumpAndSettle();
}

/// Walks the wizard to the step at [index], filling the form on the way.
Future<void> _walkTo(
  WidgetTester tester,
  int index, {
  String domain = 'quire-b.example',
  String localName = 'ana',
}) async {
  for (var step = 0; step < index; step++) {
    if (step == 1) {
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), domain);
      await tester.enterText(fields.at(1), localName);
      await tester.enterText(fields.at(2), 'Ana Maria');
      await tester.enterText(fields.at(3), 'ana@example.com');
      await tester.enterText(fields.at(4), 'uma senha boa');
    }

    // A vertical stepper builds every step's controls, so the tap goes to the
    // one belonging to the step the reader is on.
    final next = find.text('Continuar').at(step);

    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('opens on what the move does, and what it cannot undo', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()..carried = _two;

    await _pump(tester, federation);

    expect(
      find.textContaining('sem que o atual precise concordar'),
      findsOneWidget,
    );
    expect(
      find.textContaining('@ana:quire-a.example passa a ser outro nome'),
      findsOneWidget,
    );
    expect(
      find.textContaining('precisam ser autorizados de novo'),
      findsOneWidget,
    );
    expect(find.text('Não dá para desfazer.'), findsOneWidget);
  });

  testWidgets('works the devices out when it opens, not when it needs them', (
    WidgetTester tester,
  ) async {
    // ListDevices is a call to the node being *left*, and the last thing this
    // screen does is stop talking to it. Reading later would make the names
    // depend on how long the reader spent on a form.
    final federation = FakeFederationRepository()..carried = _two;

    await _pump(tester, federation);

    expect(federation.migrations, isEmpty);
    await _walkTo(tester, 2);

    expect(find.text('Celular'), findsOneWidget);
    expect(find.text('Notebook'), findsOneWidget);
    expect(find.text('Este aparelho'), findsOneWidget);
  });

  testWidgets('says the connection only moves at the end', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()..carried = _two;

    await _pump(tester, federation);
    await _walkTo(tester, 1);

    expect(
      find.textContaining('só passa a falar com o novo servidor no último'),
      findsOneWidget,
    );
  });

  testWidgets('names the devices the node being left could not name', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()..carried = _unnamed;

    await _pump(tester, federation);
    await _walkTo(tester, 2);

    expect(
      find.textContaining('Os identificadores vieram do histórico'),
      findsOneWidget,
    );
    // Named from the identifier, so that two of them can be told apart in the
    // list the reader renames from afterwards.
    expect(find.text('Aparelho 11111111'), findsNothing);
    expect(find.text('Aparelho 99999999'), findsOneWidget);
  });

  testWidgets('the summary counts the devices and names the new identifier', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()..carried = _two;

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    expect(
      find.textContaining('@ana:quire-b.example passa a ser a sua conta'),
      findsOneWidget,
    );
    expect(find.textContaining('2 aparelhos'), findsOneWidget);
    expect(
      find.textContaining('Nada é apagado deste aparelho'),
      findsOneWidget,
    );
  });

  testWidgets('sends what the reader typed, carrying every device', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()..carried = _two;

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    await tester.ensureVisible(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();

    expect(federation.migrations, hasLength(1));

    final sent = federation.migrations.single;

    expect(sent.domain, 'quire-b.example');
    expect(sent.localName, 'ana');
    expect(sent.email, 'ana@example.com');
    expect(
      sent.devices.map((Object it) => (it as dynamic).id as String),
      <String>[
        '11111111-1111-4111-8111-111111111111',
        '99999999-9999-4999-8999-999999999999',
      ],
    );
    expect(find.text('Você agora é @ana:quire-b.example.'), findsOneWidget);
  });

  testWidgets('a device the node could not name travels under one anyway', (
    WidgetTester tester,
  ) async {
    // The name is invented and the identifier is not, which is the right way
    // round: the identifier is the half that cannot be recreated, and a device
    // carried under a name the reader does not recognize can be renamed.
    final federation = FakeFederationRepository()..carried = _unnamed;

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    await tester.ensureVisible(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();

    final sent = federation.migrations.single;

    expect(sent.devices.last.name, 'Aparelho 99999999');
    expect(sent.devices.last.platform, unknownPlatform);
  });

  testWidgets('a refusal about the form takes the reader back to it', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..carried = _two
      ..refusal = const AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the migration was refused before it was sent',
        op: 'federation/migration: migrate',
        fields: <FieldFailure>[
          FieldFailure('local_name', 'it must not be empty'),
        ],
      );

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    await tester.ensureVisible(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();

    // A vertical stepper shows one step's content at a time, so a field error
    // under a collapsed step is an error nobody sees.
    expect(
      find.text('Use letras minúsculas, números e . - _ entre eles.'),
      findsOneWidget,
    );
  });

  testWidgets('a refusal by the node says the device did not move', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..carried = _two
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node did not answer',
        op: 'federation/migration: migrate',
      );

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    await tester.ensureVisible(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A migração não aconteceu. Este aparelho continua no servidor '
        'de antes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a name already taken there is said in its own words', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..carried = _two
      ..refusal = const AppException(
        kind: ErrorKind.alreadyExists,
        message: 'that local name is taken',
        op: 'federation/migration: migrate',
      );

    await _pump(tester, federation);
    await _walkTo(tester, 3);

    await tester.ensureVisible(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar de servidor'));
    await tester.pumpAndSettle();

    expect(
      find.text('Este nome de usuário já existe naquele servidor.'),
      findsOneWidget,
    );
  });
}

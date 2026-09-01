/// The devices, and the two words this screen has to get right.
///
/// *Unbound* rather than *deleted*, because the row survives and is what gives
/// a name to an identifier the reader's own history carries. And *this device*
/// on the row that cannot unbind itself, because the node would carry that
/// request out and leave the reader with no session and nothing on screen to
/// undo it.
library;

import 'package:atril/domain/models/device.dart';
import 'package:atril/ui/account/widgets/devices_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

const String _thisDevice = '11111111-1111-4111-8111-111111111111';
const String _otherDevice = '99999999-9999-4999-8999-999999999999';

final Device _own = Device(
  id: _thisDevice,
  name: 'Celular',
  platform: 'android',
  active: true,
  lastSyncedAt: DateTime.utc(2026, 8, 30),
);

const Device _other = Device(
  id: _otherDevice,
  name: 'Notebook',
  platform: 'linux',
  active: true,
);

const Device _revoked = Device(
  id: '88888888-8888-4888-8888-888888888888',
  name: 'Tablet antigo',
  platform: 'android',
  active: false,
);

Future<void> _pump(WidgetTester tester, FakeAccountRepository account) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(accountRepository: account),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DevicesScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('says why the list exists at all', (WidgetTester tester) async {
    final account = FakeAccountRepository()..bound = <Device>[_own];

    await _pump(tester, account);

    expect(find.textContaining('nomeia o aparelho que a fez'), findsOneWidget);
  });

  testWidgets('marks the device the reader is holding', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own, _other];

    await _pump(tester, account);

    expect(find.text('Celular'), findsOneWidget);
    expect(find.text('Este aparelho'), findsOneWidget);
    expect(find.text('linux'), findsOneWidget);
  });

  testWidgets('a revoked device says unbound and not deleted', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own, _revoked];

    await _pump(tester, account);

    expect(find.text('Tablet antigo'), findsOneWidget);
    expect(find.text('Desvinculado'), findsOneWidget);
    expect(
      find.text(
        'Não pode mais escrever. A linha fica, porque as alterações '
        'que ele fez continuam nomeando-o.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a revoked device is offered nothing', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_revoked];

    await _pump(tester, account);

    expect(find.text('Renomear'), findsNothing);
    expect(find.text('Desvincular'), findsNothing);
  });

  testWidgets('this device is not offered an unbinding it would be refused', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own];

    await _pump(tester, account);

    expect(find.text('Renomear'), findsOneWidget);
    expect(find.text('Desvincular'), findsNothing);
  });

  testWidgets('a node that did not answer is said, not shown as empty', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'identity/device: list',
      );

    await _pump(tester, account);

    expect(
      find.text(
        'Não foi possível ler os seus aparelhos. O servidor não '
        'respondeu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renames a device, opening on the name it has', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own, _other];

    await _pump(tester, account);
    await tester.tap(find.text('Renomear').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Notebook',
    );

    await tester.enterText(find.byType(TextField), 'Notebook do trabalho');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(account.renamed, <(String, String)>[
      (_otherDevice, 'Notebook do trabalho'),
    ]);
    expect(find.text('Agora se chama Notebook do trabalho.'), findsOneWidget);
  });

  testWidgets('a blank name is faulted in the dialog, not at the node', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own];

    await _pump(tester, account);
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um nome.'), findsOneWidget);
    expect(account.renamed, isEmpty);
  });

  testWidgets('unbinding asks first, and says what stays', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own, _other];

    await _pump(tester, account);
    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();

    expect(find.text('Desvincular Notebook?'), findsOneWidget);
    expect(find.textContaining('a linha dele fica na lista'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(account.unbound, isEmpty);
  });

  testWidgets('a confirmed unbinding leaves the row behind', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()..bound = <Device>[_own, _other];

    await _pump(tester, account);
    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
    await tester.pumpAndSettle();

    expect(account.unbound, <String>[_otherDevice]);
    expect(find.text('Notebook não pode mais escrever.'), findsOneWidget);
    expect(find.text('Notebook'), findsOneWidget);
    expect(find.text('Desvinculado'), findsOneWidget);
  });
}

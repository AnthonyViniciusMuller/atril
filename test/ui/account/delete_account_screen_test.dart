/// Deleting the account, and the half of it a reader is most likely to assume
/// wrong.
///
/// What is pinned here is the second list: the peers that already hold a copy
/// are named rather than alluded to, and the books on this device are said to
/// stay. A deletion screen that only listed what it removes would be inviting
/// the reader to believe it reaches further than it can.
library;

import 'package:atril/data/repositories/account/account_repository_impl.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/ui/account/widgets/delete_account_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/utils/errors.dart';
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
  email: 'ana@example.com',
  createdAt: DateTime.utc(2026),
);

ReplicaAuthorization _grant(String domain) => ReplicaAuthorization(
  id: 'grant-$domain',
  serverId: domain,
  serverDomain: domain,
  authorizedAt: DateTime.utc(2026, 9),
  replicatesFiles: false,
  active: true,
);

Future<void> _pump(
  WidgetTester tester,
  FakeAccountRepository account, {
  FakeFederationRepository? federation,
}) async {
  final auth = FakeAuthRepository();

  // A tall surface: the two lists this screen is about push its control below
  // the fold of the default 800x600 test window, which is a fact about the
  // window rather than about the screen.
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(
        accountRepository: account,
        auth: auth,
        federation: federation ?? FakeFederationRepository(),
      ),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeleteAccountScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
  auth.readers.add(_reader);
  await tester.pumpAndSettle();
}

/// Taps the screen's own delete button.
Future<void> _press(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Excluir a minha conta'));
  await tester.pumpAndSettle();
}

/// Confirms in the dialog the screen's button opened.
Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Excluir a minha conta'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names the node it reaches', (WidgetTester tester) async {
    await _pump(tester, FakeAccountRepository());

    expect(find.text('O que a exclusão alcança'), findsOneWidget);
    expect(find.text('A sua conta em quire-a.example'), findsOneWidget);
  });

  testWidgets('says what it does not reach, in two parts', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeAccountRepository());

    expect(find.text('O que ela não alcança'), findsOneWidget);
    expect(
      find.textContaining('Excluir não entra no banco de outro operador'),
      findsOneWidget,
    );
    // The decision this app took about the local replica, said where the
    // reader is deciding: erasing it would destroy the only copy of whatever
    // the node never received.
    expect(
      find.textContaining('Os livros e as marcações neste aparelho'),
      findsOneWidget,
    );
  });

  testWidgets('names the peers that hold a copy where the node said who', (
    WidgetTester tester,
  ) async {
    final federation = FakeFederationRepository()
      ..grants = <ReplicaAuthorization>[
        _grant('quire-b.example'),
        _grant('quire-c.example'),
      ];

    await _pump(tester, FakeAccountRepository(), federation: federation);

    expect(
      find.text('Ainda com uma cópia: quire-b.example, quire-c.example'),
      findsOneWidget,
    );
  });

  testWidgets('a node that did not say who keeps the sentence anyway', (
    WidgetTester tester,
  ) async {
    // An empty list means *not known* and not *none*, so what disappears is
    // the names and never the claim.
    final federation = FakeFederationRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'federation/replicas: list',
      );

    await _pump(tester, FakeAccountRepository(), federation: federation);

    expect(
      find.textContaining('Excluir não entra no banco de outro operador'),
      findsOneWidget,
    );
    expect(find.textContaining('Ainda com uma cópia'), findsNothing);
  });

  testWidgets('points at the migration, which is the other thing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeAccountRepository());

    expect(
      find.textContaining('use Mudar de servidor de origem'),
      findsOneWidget,
    );
  });

  testWidgets('asks once more before it deletes', (WidgetTester tester) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);

    await tester.enterText(find.byType(TextField), 'uma senha boa');
    await _press(tester);

    expect(find.text('Não dá para desfazer.'), findsWidgets);
    expect(account.deletions, isEmpty);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(account.deletions, isEmpty);
  });

  testWidgets('deletes with the password the reader proved it with', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);

    await tester.enterText(find.byType(TextField), 'uma senha boa');
    await _press(tester);
    await _confirm(tester);

    expect(account.deletions, <String>['uma senha boa']);
    expect(
      find.text('A sua conta em quire-a.example foi excluída.'),
      findsOneWidget,
    );
  });

  testWidgets('a proof that did not match is said as itself', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()
      ..refusal = const AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the password does not match',
        code: codeWrongPassword,
        op: 'identity/user: delete',
      );

    await _pump(tester, account);

    await tester.enterText(find.byType(TextField), 'errada');
    await _press(tester);
    await _confirm(tester);

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
  });
}

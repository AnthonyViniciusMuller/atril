/// The reader's record, and the three proofs the contract asks for.
///
/// C14 is what this screen is shaped by: only the display name is written by a
/// mask, the address asks for the password because it is the channel recovery
/// goes through, and the password asks for itself. What is pinned here is that
/// the three stay three — a single form with one *save* button would demand a
/// password for the name as well, or accept one for none of it — and that the
/// reader is told, before they type anything, that changing a password signs
/// every device out.
library;

import 'package:atril/data/repositories/account/account_repository_impl.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/ui/account/widgets/account_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
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
  email: 'ana@example.com',
  createdAt: DateTime.utc(2026),
);

Future<void> _pump(
  WidgetTester tester,
  FakeAccountRepository account, {
  User? reader,
}) async {
  final auth = FakeAuthRepository();

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(accountRepository: account, auth: auth),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
  auth.readers.add(Result<User?>.ok(reader ?? _reader));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks the node when it opens, and shows what it holds', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);

    expect(account.reads, 1);
    expect(find.text('@ana:quire-a.example'), findsOneWidget);
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('offers the deletion last, and marks it as what it is', (
    WidgetTester tester,
  ) async {
    // A location of its own and not a dialog: what deletion reaches and does
    // not reach takes reading, and it is not a decision to put one tap away
    // from the name field.
    final account = FakeAccountRepository();

    await _pump(tester, account);

    expect(find.text('Excluir a conta'), findsOneWidget);
  });

  testWidgets('says why the identifier is not editable here', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);

    expect(find.textContaining('só muda mudando de servidor'), findsOneWidget);
  });

  testWidgets('a node that did not answer costs a line, not the screen', (
    WidgetTester tester,
  ) async {
    // What is on screen came from this device's own row, which is the last
    // thing the node told it.
    final account = FakeAccountRepository()
      ..refusal = const AppException(
        kind: ErrorKind.unavailable,
        message: 'the node is down',
        op: 'identity/user: read',
      );

    await _pump(tester, account);

    expect(
      find.text('Não foi possível ler a sua conta. O servidor não respondeu.'),
      findsOneWidget,
    );
    expect(find.text('@ana:quire-a.example'), findsOneWidget);
  });

  testWidgets('changes the display name and asks for no password', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);
    await tester.tap(find.text('Nome exibido'));
    await tester.pumpAndSettle();

    // One field and no proof: it is the only thing `UpdateUser` writes.
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ana M.');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(account.displayNames, <String>['Ana M.']);
    expect(find.text('Agora você aparece como Ana M..'), findsOneWidget);
  });

  testWidgets('a blank display name is faulted in the dialog', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);
    await tester.tap(find.text('Nome exibido'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um nome.'), findsOneWidget);
    expect(account.displayNames, isEmpty);
  });

  testWidgets('changing the address asks for the password, and says why', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);

    expect(find.textContaining('mudá-lo pede a sua senha'), findsOneWidget);

    await tester.tap(find.text('E-mail').first);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      find.textContaining('Um aviso é enviado para o endereço antigo'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(0), 'nova@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'uma senha boa');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(account.emails, <(String, String)>[
      ('uma senha boa', 'nova@example.com'),
    ]);
    expect(find.text('O e-mail agora é nova@example.com.'), findsOneWidget);
  });

  testWidgets('a proof that did not match is said as itself', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository()
      ..refusal = const AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the password does not match',
        code: codeWrongPassword,
        op: 'identity/user: email',
      );

    await _pump(tester, account);
    await tester.tap(find.text('E-mail').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'nova@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'errada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
  });

  testWidgets('warns that changing the password signs every device out', (
    WidgetTester tester,
  ) async {
    // The node ends every session of every device, its own use case says so
    // and the contract does not — so a reader who was not warned would
    // experience a correct decision as the app breaking.
    final account = FakeAccountRepository();

    await _pump(tester, account);

    expect(
      find.text(
        'Trocar a senha encerra a sua sessão em todos os aparelhos, '
        'inclusive neste.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Todas as suas sessões acabam'), findsOneWidget);
  });

  testWidgets('changes the password with both credentials', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);
    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'uma senha boa');
    await tester.enterText(find.byType(TextField).at(1), 'outra senha boa');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(account.passwords, <(String, String)>[
      ('uma senha boa', 'outra senha boa'),
    ]);
    expect(find.text('Senha trocada. Entre de novo.'), findsOneWidget);
  });

  testWidgets('a password the node would refuse is faulted before it is sent', (
    WidgetTester tester,
  ) async {
    final account = FakeAccountRepository();

    await _pump(tester, account);
    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'uma senha boa');
    await tester.enterText(find.byType(TextField).at(1), 'curta');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(
      find.text('A senha precisa de pelo menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(account.passwords, isEmpty);
  });

  testWidgets('a node with no address on record says so', (
    WidgetTester tester,
  ) async {
    // A node that only replicates a reader holds their row without an address
    // (C03), and this app shows what it was told rather than a blank.
    final account = FakeAccountRepository();

    await _pump(
      tester,
      account,
      reader: User(
        id: _reader.id,
        localName: _reader.localName,
        displayName: _reader.displayName,
        originServerDomain: _reader.originServerDomain,
        federatedId: _reader.federatedId,
        createdAt: _reader.createdAt,
      ),
    );

    expect(find.text('Nenhum e-mail registrado.'), findsOneWidget);
  });
}

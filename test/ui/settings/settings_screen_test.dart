/// The account section, and the way out of it.
library;

import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
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

Future<void> pump(
  WidgetTester tester,
  FakeAuthRepository auth, {
  FakeLibraryRepository? library,
  FakeSyncRepository? sync,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(auth: auth, library: library, sync: sync),
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
  _storage();

  testWidgets('gives the synchronization one line, and the way to more', (
    WidgetTester tester,
  ) async {
    // One line, because what a reader needs at a glance is the count:
    // everything else is a question they only ask once it has told them there
    // is something to ask about.
    final sync = FakeSyncRepository()..emit(const SyncState(pending: 2));

    addTearDown(sync.dispose);

    await pump(tester, FakeAuthRepository(), sync: sync);

    expect(find.text('2 changes waiting'), findsOneWidget);
    expect(find.text('See the state of the synchronization'), findsOneWidget);
  });

  testWidgets('offers the reader their account and their devices', (
    WidgetTester tester,
  ) async {
    await pump(tester, FakeAuthRepository());

    expect(find.text('Your account'), findsOneWidget);
    expect(find.text('Name, email and password.'), findsOneWidget);
    expect(find.text('Your devices'), findsOneWidget);
    expect(
      find.text('Which devices may write on your account.'),
      findsOneWidget,
    );
  });

  testWidgets('offers the federation, and says what is behind it', (
    WidgetTester tester,
  ) async {
    // A section and not a fourth destination: which nodes a reader federates
    // with is a property of the app rather than a place they navigate to.
    await pump(tester, FakeAuthRepository());

    expect(find.text('Federation'), findsOneWidget);
    expect(find.text('Known servers'), findsOneWidget);
    expect(find.text('Authorized replicas'), findsOneWidget);
    expect(find.text('Move to another server'), findsOneWidget);
    expect(
      find.text(
        'The servers your node knows, and the ones it may replicate '
        'to.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('names the reader by the whole federated identifier', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();

    await pump(tester, auth);
    auth.readers.add(Result<User?>.ok(_reader));
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
    auth.readers.add(Result<User?>.ok(_reader));
    await tester.pumpAndSettle();

    auth.readers.add(const Result<User?>.ok(null));
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

/// The storage section, whose two sentences are one mechanism.
void _storage() {
  testWidgets('says what it holds and nothing it cannot know', (
    WidgetTester tester,
  ) async {
    // A native install has no quota to report: nothing portable can ask a
    // volume how much room is left, and a number this app invented would be
    // worse than none.
    final library = FakeLibraryRepository()
      ..storageBudget = const StorageBudget(used: 300000);

    await pump(tester, FakeAuthRepository(), library: library);
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.scrollUntilVisible(find.text(l10n.storageUsed('300 kB')), 200);

    expect(find.text(l10n.storageUsed('300 kB')), findsOneWidget);
    expect(find.text(l10n.storageKeptExplanationNative), findsOneWidget);
  });

  testWidgets('spends a budget where the browser reports one', (
    WidgetTester tester,
  ) async {
    final library = FakeLibraryRepository()
      ..storageBudget = const StorageBudget(used: 500000000, quota: 2000000000);

    await pump(tester, FakeAuthRepository(), library: library);
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.scrollUntilVisible(
      find.text(l10n.storageUsedOfQuota('500 MB', '2 GB')),
      200,
    );

    expect(
      find.text(l10n.storageUsedOfQuota('500 MB', '2 GB')),
      findsOneWidget,
    );
    expect(find.text(l10n.storageKeptExplanationWeb), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('releases a book the reader asked to release', (
    WidgetTester tester,
  ) async {
    final library = FakeLibraryRepository()..kept.add('a');

    await pump(tester, FakeAuthRepository(), library: library);
    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[
        Ebook(
          id: 'a',
          title: 'Vidas Secas',
          format: EbookFormat.epub,
          contentHash: '0' * 64,
          importedAt: DateTime.utc(2026),
          revision: Revision(
            vectorClock: VectorClock.empty.tick('device'),
            updatedAt: DateTime.utc(2026),
            deviceId: 'device',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // The storage section is at the foot of the settings, below the sync and
    // federation ones, so on a phone-sized surface it has to be scrolled to
    // before it can be tapped.
    await tester.scrollUntilVisible(find.text(l10n.storageRelease), 200);
    await tester.ensureVisible(find.text(l10n.storageRelease));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.storageRelease));
    await tester.pumpAndSettle();

    expect(library.released, <String>['a']);
  });

  testWidgets('refuses to release the only copy, and says why', (
    WidgetTester tester,
  ) async {
    // The one gesture in this app that could destroy something a reader cannot
    // get back, refused where it would.
    final library = FakeLibraryRepository()
      ..kept.add('a')
      ..refusal = const AppException(
        kind: ErrorKind.failedPrecondition,
        code: codeNotYetSent,
      );

    await pump(tester, FakeAuthRepository(), library: library);
    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[
        Ebook(
          id: 'a',
          title: 'Vidas Secas',
          format: EbookFormat.epub,
          contentHash: '0' * 64,
          importedAt: DateTime.utc(2026),
          revision: Revision(
            vectorClock: VectorClock.empty.tick('device'),
            updatedAt: DateTime.utc(2026),
            deviceId: 'device',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // The storage section is at the foot of the settings, below the sync and
    // federation ones, so on a phone-sized surface it has to be scrolled to
    // before it can be tapped.
    await tester.scrollUntilVisible(find.text(l10n.storageRelease), 200);
    await tester.ensureVisible(find.text(l10n.storageRelease));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.storageRelease));
    await tester.pumpAndSettle();

    expect(find.text(l10n.storageNotYetSent), findsOneWidget);
  });
}

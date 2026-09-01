/// The form that edits a work: what it fills in, what it refuses, and what it
/// hands over untouched.
library;

import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/library/widgets/ebook_edit_screen.dart';
import 'package:atril/ui/library/widgets/ebook_screen.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';

late AppLocalizations l10n;

Ebook _ebook({Map<String, Object?> extra = const <String, Object?>{}}) => Ebook(
  id: _work,
  title: 'Vidas Secas',
  author: 'Graciliano Ramos',
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  extraMetadata: extra,
  importedAt: DateTime.utc(2026, 8, 31),
  revision: Revision(
    vectorClock: VectorClock.empty.tick(_device),
    updatedAt: DateTime.utc(2026, 8, 31),
    deviceId: _device,
  ),
);

Future<FakeLibraryRepository> pump(
  WidgetTester tester, {
  Map<String, Object?> extra = const <String, Object?>{},
}) async {
  final library = FakeLibraryRepository();

  tester.view
    ..physicalSize = const Size(900, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A router and not a bare `home`, because saving goes back to the work — and
  // a form tested without one would be a form whose one navigation is the part
  // nothing exercises.
  final router = GoRouter(
    initialLocation: Routes.editEbook(_work),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.ebook(_work),
        builder: (BuildContext context, GoRouterState state) =>
            const EbookScreen(ebookId: _work),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.ebookEditSegment,
            builder: (BuildContext context, GoRouterState state) =>
                const EbookEditScreen(ebookId: _work),
          ),
        ],
      ),
    ],
  );

  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(library: library),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();

  library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook(extra: extra)]));
  await tester.pumpAndSettle();

  return library;
}

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('fills itself in from the record', (WidgetTester tester) async {
    await pump(tester);

    expect(
      tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Vidas Secas'),
      ),
      isNotNull,
    );
    expect(find.text('Graciliano Ramos'), findsOneWidget);
  });

  testWidgets('hands the whole form over and lets the repository diff it', (
    WidgetTester tester,
  ) async {
    // The screen tracks no dirty flags. C17 is why the diffing belongs one
    // layer down: a screen with its own answer would disagree with the
    // repository's the first time a field was edited back to what it was.
    final library = await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Graciliano Ramos'),
      'Outro autor',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
    await tester.pumpAndSettle();

    final (id, edits) = library.edits.single;

    expect(id, _work);
    expect(edits.title, 'Vidas Secas');
    expect(edits.author, 'Outro autor');
  });

  testWidgets('refuses a work with no title, and names the field', (
    WidgetTester tester,
  ) async {
    // A work without a title is refused by the contract and by the column's
    // own check. The form refuses it first, so the reader is told which field
    // rather than which table.
    final library = await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vidas Secas'),
      '   ',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookTitleRequired), findsOneWidget);
    expect(library.edits, isEmpty);
  });

  testWidgets('reads an emptied field as one the reader cleared', (
    WidgetTester tester,
  ) async {
    // A form has no other way to say *there is no author*.
    final library = await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Graciliano Ramos'),
      '',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
    await tester.pumpAndSettle();

    expect(library.edits.single.$2.author, '');
  });

  group('the extra metadata', () {
    testWidgets('is edited as text where it is text', (
      WidgetTester tester,
    ) async {
      final library = await pump(
        tester,
        extra: const <String, Object?>{'series': 'Clássicos'},
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Clássicos'),
        'Outra série',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
      await tester.pumpAndSettle();

      expect(library.edits.single.$2.extraMetadata, <String, Object?>{
        'series': 'Outra série',
      });
    });

    testWidgets('is handed back untouched where it is not text', (
      WidgetTester tester,
    ) async {
      // `subjects` is a list, because that is what an EPUB carries. A form
      // that rendered it into a text box would turn it into a string the
      // moment the reader saved anything, and what the file said would be
      // gone.
      final library = await pump(
        tester,
        extra: const <String, Object?>{
          'subjects': <String>['Canudos', 'Sertão'],
        },
      );

      expect(find.text(l10n.ebookEditExtraNotText), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
      await tester.pumpAndSettle();

      expect(library.edits.single.$2.extraMetadata, <String, Object?>{
        'subjects': <String>['Canudos', 'Sertão'],
      });
    });

    testWidgets('drops a row the reader removed', (WidgetTester tester) async {
      final library = await pump(
        tester,
        extra: const <String, Object?>{'series': 'Clássicos'},
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
      await tester.pumpAndSettle();

      expect(library.edits.single.$2.extraMetadata, isEmpty);
    });

    testWidgets('adds a row the reader wrote', (WidgetTester tester) async {
      final library = await pump(tester);

      await tester.tap(find.widgetWithText(TextButton, l10n.ebookEditExtraAdd));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.ebookEditExtraName),
        'isbn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.ebookEditExtraValue),
        '9788535902778',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
      await tester.pumpAndSettle();

      expect(library.edits.single.$2.extraMetadata, <String, Object?>{
        'isbn': '9788535902778',
      });
    });
  });

  testWidgets('says the change was saved here, not on a server', (
    WidgetTester tester,
  ) async {
    // The promise the whole app is built on: the change is true on this device
    // now and reaches the node when the log is pushed.
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vidas Secas'),
      'Outro título',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookEditSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookEditSaved), findsOneWidget);
  });
}

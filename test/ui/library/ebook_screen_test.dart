/// One work's screen: what it says about the file, and what it says when the
/// book is gone.
library;

import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/library/widgets/ebook_screen.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';

late AppLocalizations l10n;

final Revision _revision = Revision(
  vectorClock: VectorClock.empty.tick(_device),
  updatedAt: DateTime.utc(2026, 8, 31),
  deviceId: _device,
);

Ebook _ebook({
  String title = 'Grande Sertão: Veredas',
  String? author = 'João Guimarães Rosa',
  String? publisher,
  String? language,
  int? sizeBytes,
  Map<String, Object?> extra = const <String, Object?>{},
}) => Ebook(
  id: _work,
  title: title,
  author: author,
  publisher: publisher,
  language: language,
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  sizeBytes: sizeBytes,
  extraMetadata: extra,
  importedAt: DateTime.utc(2026, 8, 31),
  revision: _revision,
);

ReadingPlace _place({required bool here, double? percent}) => ReadingPlace(
  work: _ebook(),
  locator: 'epubcfi(/6/4[ch1]!/4/2/2/1:0)',
  percent: percent,
  updatedAt: DateTime.utc(2026, 9, 1),
  onThisDevice: here,
);

Future<FakeLibraryRepository> pump(
  WidgetTester tester, {
  FakeReadingRepository? reading,
}) async {
  final library = FakeLibraryRepository();

  // Tall enough that the whole page is laid out at once. The screen is a list
  // and a shorter surface would simply not build the sections at the bottom,
  // which is a test scrolling rather than a test asserting.
  tester.view
    ..physicalSize = const Size(900, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A router and not a bare `home`, because deleting goes back to the shelf
  // and the undo runs after this route has been left. A screen tested without
  // one would be a screen whose one navigation is the part nothing exercises.
  final router = GoRouter(
    initialLocation: Routes.ebook(_work),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.library,
        builder: (BuildContext context, GoRouterState state) =>
            const LibraryScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.ebookSegment,
            builder: (BuildContext context, GoRouterState state) =>
                const EbookScreen(ebookId: _work),
          ),
        ],
      ),
    ],
  );

  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(library: library, reading: reading),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();

  return library;
}

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('lists where every one of the reader\'s devices stopped', (
    WidgetTester tester,
  ) async {
    // This is where RN01 is answered. The shelf's strip is about books and
    // shows one place per book, so *where are all of my devices in this one*
    // has this screen and nowhere else — and it says which device is this one
    // without naming any of the others, because nothing here stores them.
    final reading = FakeReadingRepository();
    addTearDown(reading.close);

    final library = await pump(tester, reading: reading);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    reading.emitPlaces(<ReadingPlace>[
      _place(here: false, percent: 80),
      _place(here: true, percent: 12),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookPlacesSection), findsOneWidget);
    expect(find.text(l10n.libraryContinueElsewhere), findsOneWidget);
    expect(find.text(l10n.libraryContinueHere), findsOneWidget);
    expect(find.text(l10n.libraryContinuePercent(80)), findsOneWidget);
    expect(find.text(l10n.libraryContinuePercent(12)), findsOneWidget);
  });

  testWidgets('says nothing about places in a book nobody has opened', (
    WidgetTester tester,
  ) async {
    // Absent and not empty. A section headed with a sentence and holding
    // nothing tells the reader something is missing, and nothing is: they have
    // not started the book.
    final reading = FakeReadingRepository();
    addTearDown(reading.close);

    final library = await pump(tester, reading: reading);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    reading.emitPlaces(const <ReadingPlace>[]);
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookPlacesSection), findsNothing);
  });

  testWidgets('names no percentage where the device could not compute one', (
    WidgetTester tester,
  ) async {
    // A device that cannot open the format still records where it stopped, so
    // the row is real and the proportion is not. A confident 0% would be a
    // claim nobody made.
    final reading = FakeReadingRepository();
    addTearDown(reading.close);

    final library = await pump(tester, reading: reading);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    reading.emitPlaces(<ReadingPlace>[_place(here: true)]);
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookPlaceNoPercent), findsOneWidget);
  });

  testWidgets('shows the work and what the file said about it', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[
        _ebook(publisher: 'José Olympio', language: 'pt-BR', sizeBytes: 300000),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('João Guimarães Rosa'), findsOneWidget);
    expect(find.text('José Olympio'), findsOneWidget);
    expect(find.text('pt-BR'), findsOneWidget);
    expect(find.text('300 kB'), findsOneWidget);
    // The format's own token, which is what the contract, the node's column
    // and this schema all spell. Translating it would name a format nothing
    // else calls that.
    expect(find.text('EPUB'), findsOneWidget);
  });

  testWidgets('says nothing at all before the first answer', (
    WidgetTester tester,
  ) async {
    // A screen opened at a location the reader typed has neither the book nor
    // its absence yet, and saying it was deleted before the query has run is a
    // lie one frame long.
    await pump(tester);

    expect(find.text(l10n.ebookNotFoundTitle), findsNothing);
  });

  testWidgets('says a work another device deleted is gone, and why', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookNotFoundTitle), findsOneWidget);
    expect(find.text(l10n.ebookNotFoundMessage), findsOneWidget);
  });

  group('where the bytes are', () {
    testWidgets('is on the server, for a work that arrived by sync', (
      WidgetTester tester,
    ) async {
      // The ordinary state of a book whose row came before its file, and in a
      // browser the ordinary state of every book the reader has not asked for.
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookFileOnServer), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.ebookDownload),
        findsOneWidget,
      );
    });

    testWidgets('is here and kept, for a book on a native install', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library
        ..downloaded.add(_work)
        ..kept.add(_work)
        ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookFileHere), findsOneWidget);
      expect(find.text(l10n.storageRelease), findsOneWidget);
    });

    testWidgets(
      'is here but not kept, which is a browser downloading to read',
      (WidgetTester tester) async {
        final library = await pump(tester);

        library
          ..downloaded.add(_work)
          ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
        await tester.pumpAndSettle();

        expect(find.text(l10n.ebookFileHereNotKept), findsOneWidget);
        expect(find.text(l10n.storageKeep), findsOneWidget);
      },
    );

    testWidgets('is only here, while the node has not received it', (
      WidgetTester tester,
    ) async {
      // Every freshly imported book, until the push that delivers the work and
      // the transfer that follows it. Saying so is what makes the refusal to
      // release make sense.
      final library = await pump(tester);

      library
        ..downloaded.add(_work)
        ..kept.add(_work)
        ..owed[_work] = 1000
        ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookFileWaiting), findsOneWidget);
    });
  });

  testWidgets('downloads the file when the reader asks', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookDownload));
    await tester.pumpAndSettle();

    expect(library.fetches, <String>[_work]);
  });

  testWidgets('says a node that does not hold the file is answering', (
    WidgetTester tester,
  ) async {
    // D02 makes metadata without files a legitimate replica, so this is a
    // sentence about the node rather than an apology from this app.
    final library = await pump(tester);

    library
      ..refusal = const AppException(
        kind: ErrorKind.notFound,
        code: codeContentNotFound,
      )
      ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l10n.ebookDownload));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookNotOnServer), findsOneWidget);
  });

  testWidgets('refuses to release the only copy, and says why', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library
      ..downloaded.add(_work)
      ..kept.add(_work)
      ..refusal = const AppException(
        kind: ErrorKind.failedPrecondition,
        code: codeNotYetSent,
      )
      ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.storageRelease));
    await tester.pumpAndSettle();

    expect(find.text(l10n.storageNotYetSent), findsOneWidget);
  });

  group('deleting', () {
    testWidgets('asks first, because the answer is not local', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookDeleteConfirmTitle), findsOneWidget);
      expect(library.deleted, isEmpty);
    });

    testWidgets('does nothing when the reader says no', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(EbookScreen)))
              .cancelButtonLabel,
        ),
      );
      await tester.pumpAndSettle();

      expect(library.deleted, isEmpty);
    });

    testWidgets('tombstones the work and offers the undo', (
      WidgetTester tester,
    ) async {
      // The undo is offered because it costs one operation carrying nothing: a
      // tombstone is a flag on a record that is still there.
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookDelete));
      await tester.pumpAndSettle();

      expect(library.deleted, <String>[_work]);
      expect(
        find.text(l10n.ebookDeleted('Grande Sertão: Veredas')),
        findsOneWidget,
      );
      expect(find.text(l10n.ebookDeleteUndo), findsOneWidget);
    });

    testWidgets('brings the work back when the reader undoes it', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.ebookDeleteUndo));
      await tester.pumpAndSettle();

      expect(library.restored, <String>[_work]);
      expect(
        find.text(l10n.ebookRestored('Grande Sertão: Veredas')),
        findsOneWidget,
      );
    });

    testWidgets('says so when the undo itself was refused', (
      WidgetTester tester,
    ) async {
      // The undo runs after this screen has gone, and what it answered used to
      // be discarded: a restore the node refused announced that the book was
      // back, over a shelf that did not have it.
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.ebookDelete));
      await tester.pumpAndSettle();

      library.refusal = Exception('the replica would not write');

      await tester.tap(find.text(l10n.ebookDeleteUndo));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.ebookRestoreFailed('Grande Sertão: Veredas')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.ebookRestored('Grande Sertão: Veredas')),
        findsNothing,
      );
    });
  });

  testWidgets('lists the shelves the work is filed under', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
    library.groupings.add(
      Result<List<Collection>>.ok(<Collection>[
        Collection(
          id: 'b',
          name: 'Para reler',
          kind: CollectionKind.collection,
          createdAt: DateTime.utc(2026),
          revision: _revision,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, 'Para reler'), findsOneWidget);
  });

  group('choosing shelves', () {
    testWidgets('offers every shelf, and marks the ones it is on', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      library.groupings.add(
        Result<List<Collection>>.ok(<Collection>[
          Collection(
            id: 'b',
            name: 'Para reler',
            kind: CollectionKind.collection,
            createdAt: DateTime.utc(2026),
            revision: _revision,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.ebookShelvesEdit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookShelvesDialogTitle), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        // The fake answers the same list for *every* shelf and for the ones
        // this work is on, which is a book already filed there.
        isTrue,
      );
    });

    testWidgets('files and unfiles as each mark is made', (
      WidgetTester tester,
    ) async {
      // Each mark is its own change and takes effect as it is made. A register
      // per pair is what makes that natural: filing a work and filing it again
      // are one request, so there is nothing to batch and nothing to undo if
      // the reader walks away half way through.
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      library.groupings.add(
        Result<List<Collection>>.ok(<Collection>[
          Collection(
            id: 'b',
            name: 'Para reler',
            kind: CollectionKind.collection,
            createdAt: DateTime.utc(2026),
            revision: _revision,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.ebookShelvesEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      expect(library.filings, <(String, String, bool)>[(_work, 'b', false)]);
    });

    testWidgets('says a refused mark where the mark was made', (
      WidgetTester tester,
    ) async {
      // Beside the list and while the dialog is open. The check that ran after
      // it closed was both too late and unreliable: the command clears its
      // result on the next toggle, so a refusal followed by a mark that worked
      // was reported as a success.
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      library.groupings.add(
        Result<List<Collection>>.ok(<Collection>[
          Collection(
            id: 'b',
            name: 'Para reler',
            kind: CollectionKind.collection,
            createdAt: DateTime.utc(2026),
            revision: _revision,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.ebookShelvesEdit));
      await tester.pumpAndSettle();

      library.refusal = Exception('the replica would not write');

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      // Still open, and saying so.
      expect(find.text(l10n.ebookShelvesDialogTitle), findsOneWidget);
      expect(find.text(l10n.ebookShelvesFailed), findsOneWidget);
    });

    testWidgets('says so when the reader has no shelves to choose from', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      library.groupings.add(const Result<List<Collection>>.ok(<Collection>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.ebookShelvesEdit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookShelvesNone), findsOneWidget);
    });
  });

  testWidgets('shows what the file carried that the contract does not name', (
    WidgetTester tester,
  ) async {
    // The keys are the metadata's own vocabulary and differ per file, so they
    // are shown as they were written rather than under a label this app
    // invented for them.
    final library = await pump(tester);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[
        _ebook(extra: const <String, Object?>{'series': 'Clássicos'}),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.ebookExtraSection), findsOneWidget);
    expect(find.text('series'), findsOneWidget);
    expect(find.text('Clássicos'), findsOneWidget);
  });
}

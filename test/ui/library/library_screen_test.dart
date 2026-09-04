/// The shelf, its two shapes, and the two things an empty one can mean.
library;

import 'dart:typed_data';

import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/ui/library/widgets/shelf.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

const String _device = '11111111-1111-4111-8111-111111111111';

final Revision _revision = Revision(
  vectorClock: VectorClock.empty.tick(_device),
  updatedAt: DateTime.utc(2026, 8, 31),
  deviceId: _device,
);

Ebook _work(String title, {String? author, String id = 'a'}) => Ebook(
  id: id,
  title: title,
  author: author,
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  importedAt: DateTime.utc(2026, 8, 31),
  revision: _revision,
);

Collection _grouping(String name, {String id = 'b'}) => Collection(
  id: id,
  name: name,
  kind: CollectionKind.collection,
  createdAt: DateTime.utc(2026, 8, 31),
  revision: _revision,
);

/// The strings the assertions below name, in the locale a test runs under.
///
/// It is loaded rather than written out, which is the idiom the onboarding
/// tests already use: an assertion spelling the Portuguese would pass in this
/// app's own language and fail the day somebody runs the suite under another,
/// and one spelling the English would be a test that never sees the template.
late AppLocalizations l10n;

/// What a test drives the screen with.
typedef Harness = ({FakeLibraryRepository library, FakeFilePicker picker});

/// The screen at [width] logical pixels, which is what decides its shape.
Future<Harness> pump(WidgetTester tester, {double width = 400}) async {
  final library = FakeLibraryRepository();
  final picker = FakeFilePicker();

  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(library: library, picker: picker),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LibraryScreen(),
      ),
    ),
  );
  await tester.pump();

  return (library: library, picker: picker);
}

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  for (final double scale in <double>[1.3, 2.0]) {
    for (final double width in <double>[400, 900]) {
      testWidgets('lays a shelf of ${width}px out at ${scale}x text', (
        WidgetTester tester,
      ) async {
        // `childAspectRatio: 0.52` was a cell that fitted a cover and two
        // lines at 100% and half of the second line at 130%. Nothing in this
        // suite had ever set a text size, which is why it went unnoticed
        // through five phases.
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final harness = await pump(tester, width: width);

        harness.library.works.add(
          Result<List<Ebook>>.ok(<Ebook>[
            _work('Grande Sertão: Veredas', author: 'Guimarães Rosa'),
            _work('Os Sertões', author: 'Euclides da Cunha', id: 'b'),
            _work('Iracema', author: 'José de Alencar', id: 'c'),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Os Sertões'), findsOneWidget);
        expect(tester.takeException(), isNull);

        if (width < gridWidth) {
          return;
        }

        // The stronger half of the claim, and the one an overflow check
        // misses: the cover is an `Expanded` above the two lines, so a cell
        // that reserved too little for the text did not overflow — it took the
        // room out of the cover and squashed a paperback into a postcard. The
        // cell reserves the labels, so the cover keeps its proportions.
        final Size cell = tester.getSize(find.byType(InkWell).first);
        final Size cover = tester.getSize(find.byType(AspectRatio).first);

        expect(cover.width / cover.height, closeTo(coverAspect, 0.01));
        // And it is the cell's full width. `AspectRatio` keeps its proportions
        // by narrowing when it is given too little height, so a cell that
        // reserved too little for the text did not overflow and did not
        // distort — it left a paperback floating in a column of white.
        expect(cover.width, closeTo(cell.width, 0.5));
      });
    }
  }

  testWidgets('waits without claiming the collection is empty', (
    WidgetTester tester,
  ) async {
    // The state before the first answer is neither empty nor full. It shows
    // nothing at all: a reader who has not been told anything must not be told
    // to start importing, and a spinner for the frame or two a local query
    // takes is a flash that reads as a failure.
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(l10n.libraryEmptyTitle), findsNothing);
    expect(find.text(l10n.libraryReadFailed), findsNothing);
  });

  testWidgets('tells a reader with no books what to do next', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);
  });

  testWidgets('is a list on a narrow window', (WidgetTester tester) async {
    final (:library, :picker) = await pump(tester, width: gridWidth - 1);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsWidgets);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Vidas Secas'), findsOneWidget);
  });

  testWidgets('is a grid on a wide one', (WidgetTester tester) async {
    final (:library, :picker) = await pump(tester, width: gridWidth + 200);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Vidas Secas'), findsOneWidget);
  });

  testWidgets('shows a cover that was extracted after the shelf asked', (
    WidgetTester tester,
  ) async {
    // The order a seeded device meets a book in: the row arrives from the
    // node, the shelf asks for a cover and is told there is none — truthfully
    // — and the file lands seconds later. A cell that took that first answer
    // as final left the reader looking at a placeholder over a book this
    // device had a picture of, on a screen that is never rebuilt because every
    // route is pushed over it.
    final (:library, :picker) = await pump(tester, width: gridWidth + 200);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);

    library.extractCover(
      'a',
      EpubCover(mediaType: 'image/png', bytes: Uint8List.fromList(_onePixel)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('names a work whose author the file did not say', (
    WidgetTester tester,
  ) async {
    // Absent and empty are different claims, and the screen says the first one
    // rather than showing a blank line the reader would read as a bug.
    final (:library, :picker) = await pump(tester);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Anônimo')]));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryUnknownAuthor), findsOneWidget);
  });

  testWidgets('asks a narrowed query when a shelf is chosen', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    library.groupings.add(
      Result<List<Collection>>.ok(<Collection>[_grouping('Para reler')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Para reler'));
    await tester.pumpAndSettle();

    expect(library.queries.last.collectionId, 'b');
  });

  testWidgets('distinguishes an empty shelf from an empty library', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
    library.groupings.add(
      Result<List<Collection>>.ok(<Collection>[_grouping('Para reler')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Para reler'));
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryFilterEmptyTitle), findsOneWidget);
    expect(find.text(l10n.libraryEmptyTitle), findsNothing);
  });

  testWidgets('offers the way back out of an empty shelf', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    library.groupings.add(
      Result<List<Collection>>.ok(<Collection>[_grouping('Para reler')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Para reler'));
    await tester.pumpAndSettle();

    // The chip and the button carry the same label, which is the point: the
    // way back to the whole collection is one thing said in two places.
    await tester.tap(find.text(l10n.libraryShowAll).last);
    await tester.pumpAndSettle();

    expect(library.queries.last.collectionId, isNull);
  });

  testWidgets('re-asks in the order the reader chose', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.librarySortTitle).last);
    await tester.pumpAndSettle();

    expect(library.queries.last.sort, LibrarySort.title);
  });

  testWidgets('opens the dialog when the reader asks for a book', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    // Both entry points are the same command: the button in the empty state
    // and the floating one, which is what the reader reaches for once there is
    // something on the shelf behind it.
    await tester.tap(find.widgetWithText(FilledButton, l10n.libraryImport));
    await tester.pumpAndSettle();

    expect(picker.opened, 1);
  });

  testWidgets('says nothing when the reader closes the dialog', (
    WidgetTester tester,
  ) async {
    // Cancelling is not a failure. A screen that apologized for it would be
    // apologizing for the reader's decision.
    final (:library, :picker) = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(library.imports, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('names the work that entered the collection', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    picker.file = const NamedFile('Vidas Secas.epub');
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(library.imports, hasLength(1));
    expect(find.text(l10n.libraryImported('Vidas Secas.epub')), findsOneWidget);
  });

  testWidgets('names the formats it takes when it cannot place a file', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    picker.file = const NamedFile('anotações.txt');
    library.refusal = const AppException(
      kind: ErrorKind.invalidArgument,
      code: codeUnsupportedFormat,
    );
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryImportUnsupported), findsOneWidget);
  });

  testWidgets('says so when an import fails for any other reason', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    picker.file = const NamedFile('Vidas Secas.epub');
    library.refusal = const AppException(kind: ErrorKind.internal);
    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryImportFailed), findsOneWidget);
  });

  group('searching', () {
    testWidgets('asks as the reader types, with nothing to wait for', (
      WidgetTester tester,
    ) async {
      // No debounce, because there is nothing to debounce: the answer is a
      // query over rows this device already holds, and a delay would be the
      // app pretending to wait for a network it is not talking to.
      final (:library, :picker) = await pump(tester);

      library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sertao');
      await tester.pumpAndSettle();

      expect(library.queries.last.term, 'sertao');
    });

    testWidgets('narrows to the format the reader chose', (
      WidgetTester tester,
    ) async {
      final (:library, :picker) = await pump(tester);

      library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF').last);
      await tester.pumpAndSettle();

      expect(library.queries.last.format, EbookFormat.pdf);
    });

    testWidgets('names what was asked for when nothing matches', (
      WidgetTester tester,
    ) async {
      // Three emptinesses and not one. *Nothing on this shelf* names a place;
      // *nothing found* names what was asked for.
      final (:library, :picker) = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'capitu');
      library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.libraryNoMatchesTitle), findsOneWidget);
      expect(find.text(l10n.libraryFilterEmptyTitle), findsNothing);
    });

    testWidgets('undoes every filter at once', (WidgetTester tester) async {
      // A reader looking at nothing should not have to undo three filters one
      // at a time to find out which of them was the problem.
      final (:library, :picker) = await pump(tester);

      library.works.add(Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]));
      library.groupings.add(
        Result<List<Collection>>.ok(<Collection>[_grouping('Para reler')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Para reler'));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'capitu');
      library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryClearFilters));
      await tester.pumpAndSettle();

      expect(library.queries.last.isNarrowed, isFalse);
    });

    testWidgets('clears the search when the field is closed', (
      WidgetTester tester,
    ) async {
      final (:library, :picker) = await pump(tester);

      library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'capitu');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(library.queries.last.term, isEmpty);
      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('says so when the replica itself cannot be read', (
    WidgetTester tester,
  ) async {
    final (:library, :picker) = await pump(tester);

    library.works.add(Result<List<Ebook>>.error(Exception('no such table')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryReadFailed), findsOneWidget);
    // The exception's own words are developer prose in one language, and are
    // logged rather than shown.
    expect(find.textContaining('no such table'), findsNothing);
  });
}

/// A one-pixel PNG, which is a picture Flutter will actually decode.
///
/// The bytes matter and their content does not: what the assertion is about is
/// that the cell asked again, and a cover that would not decode would fall
/// back to the same placeholder for a different reason.
const List<int> _onePixel = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];

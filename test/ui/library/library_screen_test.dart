/// The shelf, its two shapes, and the two things an empty one can mean.
library;

import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/library/widgets/library_screen.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

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

/// The screen at [width] logical pixels, which is what decides its shape.
Future<FakeLibraryRepository> pump(
  WidgetTester tester, {
  double width = 400,
}) async {
  final library = FakeLibraryRepository();

  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(library: library),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LibraryScreen(),
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
    final library = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);
  });

  testWidgets('is a list on a narrow window', (WidgetTester tester) async {
    final library = await pump(tester, width: gridWidth - 1);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsWidgets);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Vidas Secas'), findsOneWidget);
  });

  testWidgets('is a grid on a wide one', (WidgetTester tester) async {
    final library = await pump(tester, width: gridWidth + 200);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Vidas Secas'), findsOneWidget);
  });

  testWidgets('names a work whose author the file did not say', (
    WidgetTester tester,
  ) async {
    // Absent and empty are different claims, and the screen says the first one
    // rather than showing a blank line the reader would read as a bug.
    final library = await pump(tester);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[_work('Anônimo')]),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryUnknownAuthor), findsOneWidget);
  });

  testWidgets('asks a narrowed query when a shelf is chosen', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

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
    final library = await pump(tester);

    library.works.add(
      Result<List<Ebook>>.ok(<Ebook>[_work('Vidas Secas')]),
    );
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
    final library = await pump(tester);

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
    final library = await pump(tester);

    library.works.add(const Result<List<Ebook>>.ok(<Ebook>[]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.librarySortTitle).last);
    await tester.pumpAndSettle();

    expect(library.queries.last.sort, LibrarySort.title);
  });

  testWidgets('says so when the replica itself cannot be read', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.works.add(Result<List<Ebook>>.error(Exception('no such table')));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.libraryReadFailed),
      findsOneWidget,
    );
    // The exception's own words are developer prose in one language, and are
    // logged rather than shown.
    expect(find.textContaining('no such table'), findsNothing);
  });
}

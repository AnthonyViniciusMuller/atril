/// The shelves screen: two kinds kept apart, and what a deletion promises.
library;

import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/library/widgets/shelves_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fakes.dart';

const String _device = '11111111-1111-4111-8111-111111111111';

late AppLocalizations l10n;

Collection _grouping(
  String name, {
  String id = 'b',
  CollectionKind kind = CollectionKind.collection,
  String? description,
}) => Collection(
  id: id,
  name: name,
  kind: kind,
  description: description,
  createdAt: DateTime.utc(2026, 8, 31),
  revision: Revision(
    vectorClock: VectorClock.empty.tick(_device),
    updatedAt: DateTime.utc(2026, 8, 31),
    deviceId: _device,
  ),
);

Future<FakeLibraryRepository> pump(
  WidgetTester tester, {
  List<Collection> groupings = const <Collection>[],
  Map<String, int> counts = const <String, int>{},
}) async {
  final library = FakeLibraryRepository();

  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: fakeProviders(library: library),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShelvesScreen(),
      ),
    ),
  );
  await tester.pump();

  library.groupings.add(Result<List<Collection>>.ok(groupings));
  library.counts.add(Result<Map<String, int>>.ok(counts));
  await tester.pumpAndSettle();

  return library;
}

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('explains the one decision a reader has to take', (
    WidgetTester tester,
  ) async {
    // The difference between the two kinds is the only thing a reader has to
    // understand to make one, so it is said where they are about to.
    await pump(tester);

    expect(find.text(l10n.shelvesEmpty), findsOneWidget);
    expect(find.text(l10n.shelvesEmptyMessage), findsOneWidget);
  });

  testWidgets('does not blur a shelf and a category', (
    WidgetTester tester,
  ) async {
    // One structure with two meanings, and the place the difference exists is
    // this screen. A single list would be this app deciding the distinction
    // does not matter, which is not its decision to take.
    await pump(
      tester,
      groupings: <Collection>[
        _grouping('Para reler'),
        _grouping('Sertão', id: 'c', kind: CollectionKind.category),
      ],
    );

    // Twice, because the screen is called *Shelves* and so is the first of its
    // two sections: the title names the screen and the heading names what is
    // under it, and they read the same in both languages.
    expect(find.text(l10n.shelvesCollections), findsNWidgets(2));
    expect(find.text(l10n.shelvesCategories), findsOneWidget);
    expect(find.text('Para reler'), findsOneWidget);
    expect(find.text('Sertão'), findsOneWidget);
  });

  testWidgets('says how much is on each one', (WidgetTester tester) async {
    await pump(
      tester,
      groupings: <Collection>[_grouping('Para reler')],
      counts: <String, int>{'b': 3},
    );

    expect(find.textContaining(l10n.shelvesCount(3)), findsOneWidget);
  });

  testWidgets('creates the kind the reader chose', (WidgetTester tester) async {
    final library = await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesCreate));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Sertão');
    await tester.tap(find.text(l10n.shelvesKindCategory));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesSave));
    await tester.pumpAndSettle();

    expect(library.created.single.name, 'Sertão');
    expect(library.created.single.kind, CollectionKind.category);
  });

  testWidgets('refuses a grouping with no name, and names the field', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesCreate));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.shelvesNameRequired), findsOneWidget);
    expect(library.created, isEmpty);
  });

  testWidgets('edits the grouping the reader opened', (
    WidgetTester tester,
  ) async {
    final library = await pump(
      tester,
      groupings: <Collection>[_grouping('Para reler')],
    );

    await tester.tap(find.text('Para reler'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Reler');
    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesSave));
    await tester.pumpAndSettle();

    final (id, edits) = library.collectionEdits.single;

    expect(id, 'b');
    expect(edits.name, 'Reler');
  });

  testWidgets('promises the books stay, in the same breath', (
    WidgetTester tester,
  ) async {
    // The fear that stops somebody tidying their library is that a shelf takes
    // the books with it. It does not, and the message says so.
    final library = await pump(
      tester,
      groupings: <Collection>[_grouping('Para reler')],
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(library.deletedCollections, <String>['b']);
    expect(find.text(l10n.shelvesDeleted('Para reler')), findsOneWidget);
    expect(l10n.shelvesDeleted('Para reler'), contains('books'));
  });

  testWidgets('brings a grouping back when the reader undoes it', (
    WidgetTester tester,
  ) async {
    final library = await pump(
      tester,
      groupings: <Collection>[_grouping('Para reler')],
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.ebookDeleteUndo));
    await tester.pumpAndSettle();

    expect(library.restoredCollections, <String>['b']);
  });

  testWidgets('says so when a grouping cannot be saved', (
    WidgetTester tester,
  ) async {
    final library = await pump(tester);

    library.refusal = const AppException(kind: ErrorKind.internal);

    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesCreate));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Para reler');
    await tester.tap(find.widgetWithText(FilledButton, l10n.shelvesSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.shelvesSaveFailed), findsOneWidget);
  });
}

/// What the annotations screen shows, and what a mark leads back to.
///
/// The assertion the whole screen exists for is the last group's: a mark
/// navigates to the reader **at its own locator**, which is the only place in
/// this app that opens a book at somewhere other than where the device
/// stopped. Everything else here is the two scopes being one screen and the
/// three kinds staying three different things.
library;

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/annotations/widgets/annotations_screen.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

const String _bookId = 'aaaaaaaa-1111-4111-8111-111111111111';

AppLocalizations _pt() => lookupAppLocalizations(const Locale('pt', 'BR'));

Ebook _work({String id = _bookId, String title = 'Os Sertões'}) => Ebook(
  id: id,
  title: title,
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  importedAt: DateTime.utc(2026, 8, 1),
  revision: Revision.first('device', DateTime.utc(2026, 8, 1)),
);

MarkedPassage _passage({
  required String id,
  AnnotationKind kind = AnnotationKind.highlight,
  String? text,
  String locator = 'epubcfi(/6/14!/4/10,/2/1:1,/3:4)',
  Ebook? work,
}) => MarkedPassage(
  mark: Annotation(
    id: id,
    ebookId: (work ?? _work()).id,
    kind: kind,
    text: text,
    locator: locator,
    revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
  ),
  work: work ?? _work(),
);

/// The screen, under a router that records where a tap sends it.
Widget _app(FakeAnnotationRepository marks, {String? ebookId}) {
  final GoRouter router = GoRouter(
    initialLocation: '/marks',
    routes: <RouteBase>[
      GoRoute(
        path: '/marks',
        builder: (BuildContext context, GoRouterState state) =>
            AnnotationsScreen(ebookId: ebookId),
      ),
      GoRoute(
        path: '/library/:ebookId/read',
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          body: Text(
            'read ${state.pathParameters['ebookId']} '
            'at ${state.uri.queryParameters[Routes.locatorParameter]}',
          ),
        ),
      ),
    ],
  );

  return Provider<AnnotationRepository>.value(
    value: marks,
    child: MaterialApp.router(
      routerConfig: router,
      // Pinned rather than left to resolution, as every screen test here does:
      // the host reports its own locale and this app's first supported one is
      // pt_BR.
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('the two scopes', () {
    testWidgets('the whole library asks for every book', (
      WidgetTester tester,
    ) async {
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      expect(marks.scopes, <(String?, AnnotationKind?)>[(null, null)]);
      expect(find.text(_pt().navigationAnnotations), findsOneWidget);
    });

    testWidgets('one book narrows the same screen', (
      WidgetTester tester,
    ) async {
      // One screen and not two: the same question at two widths, so a second
      // list here would be a second place to fix the day a mark gains a field.
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks, ebookId: _bookId));
      await tester.pumpAndSettle();

      expect(marks.scopes, <(String?, AnnotationKind?)>[(_bookId, null)]);
      expect(find.text(_pt().annotationsInThisBook), findsOneWidget);
    });

    testWidgets('the book is named only where there is more than one', (
      WidgetTester tester,
    ) async {
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks, ebookId: _bookId));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', text: 'A terra é ingrata.'),
      ]);
      await tester.pumpAndSettle();

      expect(find.textContaining('Os Sertões'), findsNothing);
    });
  });

  group('the filter', () {
    testWidgets('is pushed down to the query and not applied here', (
      WidgetTester tester,
    ) async {
      // A screen that filtered in Dart would have read every mark in the
      // library to show three of them.
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_pt().annotationsNotes));
      await tester.pumpAndSettle();

      expect(marks.scopes.last, (null, AnnotationKind.note));
    });

    testWidgets('an empty filter is a different sentence from an empty shelf', (
      WidgetTester tester,
    ) async {
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      expect(find.text(_pt().annotationsEmptyTitle), findsOneWidget);

      await tester.tap(find.text(_pt().annotationsBookmarks));
      await tester.pumpAndSettle();

      expect(find.text(_pt().annotationsNoneOfThisKindTitle), findsOneWidget);

      await tester.tap(find.text(_pt().annotationsShowAll));
      await tester.pumpAndSettle();

      expect(find.text(_pt().annotationsEmptyTitle), findsOneWidget);
    });
  });

  group('a mark on the list', () {
    testWidgets('shows what it says, and what it is when it says nothing', (
      WidgetTester tester,
    ) async {
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', text: 'A terra é ingrata.'),
        _passage(id: 'two', kind: AnnotationKind.bookmark),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('A terra é ingrata.'), findsOneWidget);
      // A bookmark is a place and has nothing to say, so the card says which
      // kind of mark it is rather than showing an empty line.
      expect(find.text(_pt().annotationsBookmark), findsOneWidget);
    });

    testWidgets('leads back to its passage and to no other', (
      WidgetTester tester,
    ) async {
      // The point of the screen. The locator is what a mark is anchored by, and
      // it is the only thing in this app that opens a book anywhere but where
      // the device stopped.
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', text: 'A terra é ingrata.'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('A terra é ingrata.'));
      await tester.pumpAndSettle();

      expect(
        find.text('read $_bookId at epubcfi(/6/14!/4/10,/2/1:1,/3:4)'),
        findsOneWidget,
      );
    });

    testWidgets('is removed with an undo beside it', (
      WidgetTester tester,
    ) async {
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', text: 'A terra é ingrata.'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().annotationsActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().annotationsRemove));
      await tester.pumpAndSettle();

      expect(marks.removed, <String>['one']);

      await tester.tap(find.text(_pt().annotationsUndo));
      await tester.pumpAndSettle();

      expect(marks.restored, <String>['one']);
    });
  });

  group('writing on a mark', () {
    testWidgets('offers a highlight the passage it already stored', (
      WidgetTester tester,
    ) async {
      // So that promoting it to a note does not throw the words away behind
      // the reader's back: there is one text field, and what they are looking
      // at when they save is what is stored.
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', text: 'A terra é ingrata.'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().annotationsActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().annotationsAddNote));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'A terra é ingrata.',
      );
      expect(find.text(_pt().annotationsPassageGivesWay), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a seca é personagem');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerNoteSave));
      await tester.pumpAndSettle();

      expect(marks.reworded, <(String, String)>[
        ('one', 'a seca é personagem'),
      ]);
    });

    testWidgets('is not offered on a bookmark', (WidgetTester tester) async {
      // A bookmark is a place and has nothing to say, so there is nothing to
      // write on it.
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(_app(marks));
      await tester.pumpAndSettle();

      marks.emitPassages(<MarkedPassage>[
        _passage(id: 'one', kind: AnnotationKind.bookmark),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().annotationsActions));
      await tester.pumpAndSettle();

      expect(find.text(_pt().annotationsAddNote), findsNothing);
      expect(find.text(_pt().annotationsEdit), findsNothing);
      expect(find.text(_pt().annotationsRemove), findsOneWidget);
    });
  });

  testWidgets('a list that fails says so without claiming a deletion', (
    WidgetTester tester,
  ) async {
    final FakeAnnotationRepository marks = FakeAnnotationRepository();
    addTearDown(marks.close);

    await tester.pumpWidget(_app(marks));
    await tester.pumpAndSettle();

    marks.emitPassages(<MarkedPassage>[
      _passage(id: 'one', text: 'A terra é ingrata.'),
    ]);
    await tester.pumpAndSettle();

    marks.failPassages(Exception('the replica is unreadable'));
    await tester.pumpAndSettle();

    // The list is kept. A query that failed once says nothing about what the
    // reader has marked, and a screen that emptied itself would be reporting a
    // deletion that did not happen.
    expect(find.text('A terra é ingrata.'), findsOneWidget);
  });
}

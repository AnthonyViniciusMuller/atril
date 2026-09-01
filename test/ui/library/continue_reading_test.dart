/// The strip of books a reader is part-way through.
///
/// What is worth pinning here is the shape of the claim it makes: one card per
/// *device*, not one per book, and no name for a device that is not this one.
/// Both are decisions the roadmap argues and both would be easy to quietly
/// undo — collapsing the rows would look like tidying, and inventing a device
/// name would look like a feature.
library;

import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/library/widgets/continue_reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

Ebook _work(String id, String title) => Ebook(
  id: id,
  title: title,
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  importedAt: _at,
  revision: Revision(
    vectorClock: VectorClock.of(const <String, int>{'d': 1}),
    updatedAt: _at,
    deviceId: 'd',
  ),
);

ReadingPlace _place({
  required String id,
  required String title,
  required bool here,
  double? percent = 40,
  DateTime? at,
}) => ReadingPlace(
  work: _work(id, title),
  locator: 'epubcfi(/6/4[ch1]!/4/2/2/1:0)',
  percent: percent,
  updatedAt: at ?? _at,
  onThisDevice: here,
);

Widget _app(List<ReadingPlace> places) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ContinueReading(places: places)),
);

AppLocalizations _pt() => lookupAppLocalizations(const Locale('pt', 'BR'));

void main() {
  testWidgets('shows nothing at all when nothing has been read', (
    WidgetTester tester,
  ) async {
    // A reader who has imported books and opened none should see their shelf,
    // not an empty band above it explaining what would go there.
    await tester.pumpWidget(_app(const <ReadingPlace>[]));

    expect(find.text(_pt().libraryContinueReading), findsNothing);
  });

  testWidgets('shows one card per device, not one per book', (
    WidgetTester tester,
  ) async {
    // The decision RN01 asks for. A phone and a desktop in the same book are
    // two true statements, and collapsing them would be this application
    // choosing which of a reader's devices counts.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'a', title: 'Os Sertões', here: false),
        _place(id: 'a', title: 'Os Sertões', here: true, percent: 12),
      ]),
    );

    expect(find.text('Os Sertões'), findsNWidgets(2));
    expect(find.text(_pt().libraryContinueHere), findsOneWidget);
    expect(find.text(_pt().libraryContinueElsewhere), findsOneWidget);
  });

  testWidgets('says another device without naming it', (
    WidgetTester tester,
  ) async {
    // Nothing here stores the reader's other devices — ListDevices is phase
    // 12's to call — so *another device* is the whole honest answer, and a
    // name would be invented.
    await tester.pumpWidget(
      _app(<ReadingPlace>[_place(id: 'b', title: 'Iracema', here: false)]),
    );

    expect(find.text(_pt().libraryContinueElsewhere), findsOneWidget);
    expect(_pt().libraryContinueElsewhere, isNot(contains('{')));
  });

  testWidgets('shows the percentage, and omits it where there is none', (
    WidgetTester tester,
  ) async {
    // A device that cannot open the format still records where it stopped. A
    // confident 0% would be a claim this application cannot make.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'c', title: 'Macunaíma', here: true, percent: 42),
        _place(id: 'd', title: 'Memórias', here: true, percent: null),
      ]),
    );

    expect(find.text(_pt().libraryContinuePercent(42)), findsOneWidget);
    expect(find.text(_pt().libraryContinuePercent(0)), findsNothing);
  });

  testWidgets('a place with no percentage still draws a bar at zero', (
    WidgetTester tester,
  ) async {
    // The bar is the shape of the card and not the claim; the number is the
    // claim, and it is the number that is absent.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'e', title: 'Vidas Secas', here: true, percent: null),
      ]),
    );

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
  });

  testWidgets('keeps the order it was given', (WidgetTester tester) async {
    // The repository orders by when each position was written; the strip does
    // not reorder, so a reader's most recent book is the first one they reach.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'f', title: 'Primeiro', here: true),
        _place(id: 'g', title: 'Segundo', here: true),
      ]),
    );

    final Offset first = tester.getTopLeft(find.text('Primeiro'));
    final Offset second = tester.getTopLeft(find.text('Segundo'));

    expect(first.dx, lessThan(second.dx));
  });
}

/// The strip of books a reader is part-way through.
///
/// What is worth pinning here is the shape of the claim it makes: a card for
/// each place it is handed and no name for a device that is not this one. The
/// strip is handed one place per *book* — `watchContinueReading` is what
/// collapses them, and `reading_repository_test.dart` is what holds it to that
/// — so this file is about what the band does with the list, not about which
/// list it gets. Inventing a device name would look like a feature, which is
/// why the second claim is tested at all.
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

/// Runs [body] with the system text size set to [scale].
///
/// A reader who has turned their type up is the case a fixed height gets
/// wrong, and nothing in this suite had ever set one.
Future<void> atTextScale(
  WidgetTester tester,
  double scale,
  Future<void> Function() body,
) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await body();
}

void main() {
  for (final double scale in <double>[1.3, 2.0]) {
    testWidgets('lays out with the system text at ${scale}x', (
      WidgetTester tester,
    ) async {
      // The band was 116 pixels whatever the reader had set, and what is in it
      // is four lines of text and a bar. An overflow here is this app telling
      // somebody with poor eyesight that their setting is unsupported.
      await atTextScale(tester, scale, () async {
        await tester.pumpWidget(
          _app(<ReadingPlace>[
            _place(id: 'a', title: 'Grande Sertão: Veredas', here: true),
            _place(id: 'b', title: 'Os Sertões', here: false, percent: 60),
          ]),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      });
    });
  }

  testWidgets('tells a screen reader what its bar measures', (
    WidgetTester tester,
  ) async {
    // A bar with no label is a rectangle. The value is the same percentage the
    // card shows, because two wordings for one number would be two answers to
    // the same question.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'a', title: 'Os Sertões', here: true, percent: 42),
      ]),
    );
    await tester.pumpAndSettle();

    final LinearProgressIndicator bar = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .first;

    expect(bar.semanticsLabel, _pt().readingProgressLabel);
    expect(bar.semanticsValue, _pt().readingPercentValue(42));
  });

  testWidgets('shows nothing at all when nothing has been read', (
    WidgetTester tester,
  ) async {
    // A reader who has imported books and opened none should see their shelf,
    // not an empty band above it explaining what would go there.
    await tester.pumpWidget(_app(const <ReadingPlace>[]));

    expect(find.text(_pt().libraryContinueReading), findsNothing);
  });

  testWidgets('draws a card for each place and does not group them', (
    WidgetTester tester,
  ) async {
    // The band renders the list it is given and decides nothing: what reaches
    // it is already one place per book, and a widget that grouped as well
    // would be a second answer to a question the repository has answered.
    // Two books, two cards, each saying which device left it there.
    await tester.pumpWidget(
      _app(<ReadingPlace>[
        _place(id: 'a', title: 'Os Sertões', here: false),
        _place(id: 'b', title: 'Iracema', here: true, percent: 12),
      ]),
    );

    expect(find.text('Os Sertões'), findsOneWidget);
    expect(find.text('Iracema'), findsOneWidget);
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

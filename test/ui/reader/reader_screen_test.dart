/// What the reader's screen says, and what it lets a reader do.
///
/// The book itself cannot be rendered here — a host is a webview and there is
/// none in `flutter test` — so the host is a stand-in and what is checked is
/// everything around the page. That is the right half to test anyway: it is the
/// half this project wrote, the half that is translated, and the half where the
/// three ways a book does not open have to stay three different sentences.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/storage/reader_settings_store.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/reader/view_model/reader_view_model.dart';
import 'package:atril/ui/reader/widgets/reader_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../repository_fakes.dart';

const String _id = 'aaaaaaaa-1111-4111-8111-111111111111';

/// A host that renders a label instead of a book.
final class _FakeHost implements EpubHost {
  final StreamController<EpubPosition> _positions =
      StreamController<EpubPosition>.broadcast();
  final StreamController<EpubSelection> _selections =
      StreamController<EpubSelection>.broadcast();

  List<EpubChapter> contents = const <EpubChapter>[];
  final List<String> visited = <String>[];
  int turnsForward = 0;
  int turnsBack = 0;
  bool disposed = false;

  @override
  Widget view() => const Placeholder(key: Key('the page'));

  @override
  Future<void> open(EpubBook book, {String? at}) async {}

  @override
  Stream<EpubPosition> get positions => _positions.stream;

  @override
  Stream<EpubSelection> get selections => _selections.stream;

  @override
  Future<List<EpubChapter>> chapters() async => contents;

  @override
  Future<void> goTo(String locator) async => visited.add(locator);

  @override
  Future<void> nextPage() async => turnsForward++;

  @override
  Future<void> previousPage() async => turnsBack++;

  /// Every range painted over the page, in order, and every one wiped off it.
  final List<EpubMark> drawn = <EpubMark>[];
  final List<String> erased = <String>[];

  @override
  Future<void> draw(EpubMark mark) async => drawn.add(mark);

  @override
  Future<void> erase(String cfiRange, {bool underline = false}) async =>
      erased.add(cfiRange);

  @override
  Future<String> textOf(String cfiRange) async => '';

  /// Every style the host was asked for, in order.
  final List<EpubStyle> styles = <EpubStyle>[];

  @override
  Future<void> apply(EpubStyle style) async => styles.add(style);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positions.close();
    await _selections.close();
  }

  /// Reports a selection, as the engine would when a reader drags over a
  /// passage.
  void select(String cfiRange, String text) =>
      _selections.add(EpubSelection(cfiRange: cfiRange, text: text));

  /// Reports where the reader is, as the engine would.
  void moveTo(double percent) => _positions.add(
    EpubPosition(
      startCfi: 'epubcfi(/6/4!/4/2)',
      endCfi: 'epubcfi(/6/4!/4/8)',
      percent: percent,
    ),
  );
}

final class _FakeHosts implements EpubHostFactory {
  _FakeHosts(this.host);

  final _FakeHost host;

  @override
  EpubHost create() => host;
}

final class _FakeReading implements ReadingRepository {
  _FakeReading({this.failure});

  final Exception? failure;

  @override
  Future<Result<EpubBook>> openBook(String ebookId) async => failure != null
      ? Result<EpubBook>.error(failure!)
      : Result<EpubBook>.ok(
          EpubBook(ebookId: ebookId, bytes: Uint8List(4), title: 'Os Sertões'),
        );

  /// Every position the screen recorded, in order.
  final List<({String locator, double? percent})> saved =
      <({String locator, double? percent})>[];

  @override
  Future<Result<void>> saveProgress({
    required String ebookId,
    required String locator,
    double? percent,
  }) async {
    saved.add((locator: locator, percent: percent));

    return const Result<void>.ok(null);
  }

  @override
  Stream<Result<List<ReadingPlace>>> watchContinueReading({int limit = 20}) =>
      const Stream<Result<List<ReadingPlace>>>.empty();

  @override
  Stream<Result<List<ReadingPlace>>> watchPlacesIn(String ebookId) =>
      const Stream<Result<List<ReadingPlace>>>.empty();

  @override
  Future<Result<Ebook?>> ebook(String ebookId) async => Result<Ebook?>.ok(null);
}

/// A mark over [range], as the repository would answer with one.
Annotation _mark(
  String range, {
  AnnotationKind kind = AnnotationKind.highlight,
}) => Annotation(
  id: range,
  ebookId: _id,
  kind: kind,
  locator: range,
  revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
);

Widget _app(
  ReadingRepository reading,
  EpubHostFactory hosts, {
  ReaderSettingsStore? settings,
  AnnotationRepository? annotations,
}) => MultiProvider(
  providers: <SingleChildWidget>[
    Provider<ReadingRepository>.value(value: reading),
    Provider<AnnotationRepository>.value(
      value: annotations ?? FakeAnnotationRepository(),
    ),
    Provider<EpubHostFactory>.value(value: hosts),
    Provider<ReaderSettingsStore>.value(
      value: settings ?? MemoryReaderSettingsStore(),
    ),
  ],
  child: const MaterialApp(
    // Pinned rather than left to resolution. The test host reports its own
    // locale and this app's first supported one is pt_BR, so a test that read
    // its expectations from one and the widget from the other would pass or
    // fail depending on the machine.
    locale: Locale('pt', 'BR'),
    localizationsDelegates: <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: ReaderScreen(ebookId: _id),
  ),
);

AppLocalizations _pt() => lookupAppLocalizations(const Locale('pt', 'BR'));

/// How visible the chrome is.
double _chromeOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byKey(readerChromeKey)).opacity;

void main() {
  group('a book that opens', () {
    testWidgets('shows the page the host draws', (WidgetTester tester) async {
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('the page')), findsOneWidget);
    });

    testWidgets('the chrome starts visible', (WidgetTester tester) async {
      // A reader who has just opened a book needs the way back more than they
      // need the four lines the bar covers. Hiding it comes after the first
      // tap, not before it.
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      expect(find.byTooltip(_pt().readerBack), findsOneWidget);
    });

    testWidgets(
      'a tap on the page clears the chrome and another brings it back',
      (WidgetTester tester) async {
        final _FakeHost host = _FakeHost();

        await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
        await tester.pumpAndSettle();

        // The tap lands on the gesture detector over the page rather than on
        // the page itself, which is what a reader's finger does too.
        await tester.tap(
          find.byKey(const Key('the page')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Faded out rather than removed, so that the animation has something to
        // run over — but not reachable, which is what `IgnorePointer` is for.
        expect(_chromeOpacity(tester), 0);

        await tester.tap(
          find.byKey(const Key('the page')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(_chromeOpacity(tester), 1);
      },
    );

    testWidgets('the controls turn the page', (WidgetTester tester) async {
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerNextPage));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_pt().readerPreviousPage));
      await tester.pumpAndSettle();

      expect(host.turnsForward, 1);
      expect(host.turnsBack, 1);
    });

    testWidgets('the progress follows what the engine reports', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(42.4);
      await tester.pumpAndSettle();

      // Rounded where it is shown and not where it is stored: the record keeps
      // what the engine said.
      expect(find.text(_pt().readerProgress(42)), findsOneWidget);
    });

    testWidgets('the contents navigates by href and says when there is none', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost()
        ..contents = const <EpubChapter>[
          EpubChapter(
            title: 'Parte I',
            href: 'part1.xhtml',
            children: <EpubChapter>[
              EpubChapter(title: 'Capítulo 1', href: 'part1.xhtml#ch1'),
            ],
          ),
        ];

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerContents));
      await tester.pumpAndSettle();

      // Flat with an indent rather than a tree of disclosures: a contents is
      // read by looking down it.
      expect(find.text('Capítulo 1'), findsOneWidget);

      await tester.tap(find.text('Capítulo 1'));
      await tester.pumpAndSettle();

      // The fragment is part of the address; a chapter that lost it would
      // navigate to the top of the file it is in rather than to itself.
      expect(host.visited, <String>['part1.xhtml#ch1']);
    });

    testWidgets('a book with no contents says so rather than showing nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(_FakeHost())));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerContents));
      await tester.pumpAndSettle();

      // There are published books with no navigation document. An empty list
      // would leave a reader wondering whether it had failed to load.
      expect(find.text(_pt().readerContentsEmptyTitle), findsOneWidget);
    });

    testWidgets('closing the reader disposes the host', (
      WidgetTester tester,
    ) async {
      // A host owns a webview and a webview owns a process. One left behind is
      // a book still in memory and, on Linux, a CEF browser still running.
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(host.disposed, isTrue);
    });
  });

  group('where the reader stopped', () {
    testWidgets('is not recorded on every page turn', (
      WidgetTester tester,
    ) async {
      // A position written per turn would be an operation per turn — a log
      // nobody wants, pushed to a node nobody asked, and a vector clock
      // ticking through a chapter.
      final _FakeHost host = _FakeHost();
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(10);
      host.moveTo(20);
      host.moveTo(30);
      await tester.pump(const Duration(milliseconds: 500));

      expect(reading.saved, isEmpty);
    });

    testWidgets('is recorded once, at the page they stayed on', (
      WidgetTester tester,
    ) async {
      // Each turn replaces the last rather than queueing behind it, so a
      // reader flicking through a chapter writes one operation and not thirty
      // — and the one it writes is where they actually stopped.
      final _FakeHost host = _FakeHost();
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(10);
      await tester.pump(const Duration(seconds: 1));
      host.moveTo(20);
      await tester.pump(const Duration(seconds: 1));
      host.moveTo(30);

      await tester.pump(readingPositionDebounce);
      await tester.pumpAndSettle();

      expect(reading.saved, hasLength(1));
      expect(reading.saved.single.percent, 30);
    });

    testWidgets('carries the locator the engine gave, byte for byte', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(50);
      await tester.pump(readingPositionDebounce);
      await tester.pumpAndSettle();

      // The start of the page and not its end, because a reader resuming wants
      // the page they were on rather than the one after it.
      expect(reading.saved.single.locator, 'epubcfi(/6/4!/4/2)');
    });

    testWidgets('is recorded on the way out, before the debounce fires', (
      WidgetTester tester,
    ) async {
      // The case the debounce would otherwise lose entirely: a reader opens a
      // book, reads one page and closes it. Without this the only thing the
      // screen existed for is thrown away.
      final _FakeHost host = _FakeHost();
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(7);
      await tester.pump(const Duration(milliseconds: 100));

      expect(reading.saved, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(reading.saved, hasLength(1));
      expect(reading.saved.single.percent, 7);
    });

    testWidgets('a page already written is not written again on the way out', (
      WidgetTester tester,
    ) async {
      // Closing after the debounce has already fired should not append a
      // second identical operation to a log this device owes.
      final _FakeHost host = _FakeHost();
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.moveTo(64);
      await tester.pump(readingPositionDebounce);
      await tester.pumpAndSettle();

      expect(reading.saved, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(reading.saved, hasLength(1));
    });

    testWidgets('a book nobody turned a page in writes nothing', (
      WidgetTester tester,
    ) async {
      // Opening a book is not reading it. A position written on open would
      // move a bookmark a reader set on another device, simply because they
      // glanced at the first page here.
      final _FakeReading reading = _FakeReading();

      await tester.pumpWidget(_app(reading, _FakeHosts(_FakeHost())));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(reading.saved, isEmpty);
    });
  });

  group('the appearance a reader chooses', () {
    testWidgets('opens at what this device was last left at', (
      WidgetTester tester,
    ) async {
      // Applied before the book is handed over, so the first page a reader
      // sees is at the size they chose rather than at the default for an
      // instant.
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(
        _app(
          _FakeReading(),
          _FakeHosts(host),
          settings: MemoryReaderSettingsStore(
            const EpubStyle(fontSize: 150, theme: EpubTheme.sepia),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(host.styles, isNotEmpty);
      expect(host.styles.first.fontSize, 150);
      expect(host.styles.first.theme, EpubTheme.sepia);
    });

    testWidgets('applies as it is changed, with no apply button', (
      WidgetTester tester,
    ) async {
      // The thing being changed is visible behind the sheet. A dialog that
      // collected the choices and applied them on dismissal would be asking
      // somebody to imagine the result of a decision they can look at.
      final _FakeHost host = _FakeHost();
      final MemoryReaderSettingsStore settings = MemoryReaderSettingsStore();

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), settings: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerSettings));
      await tester.pumpAndSettle();

      final int before = host.styles.length;

      await tester.tap(find.text(_pt().readerThemeDark));
      await tester.pumpAndSettle();

      expect(host.styles.length, greaterThan(before));
      expect(host.styles.last.theme, EpubTheme.dark);
      // And remembered, so tomorrow's first page is this one.
      expect((await settings.read()).theme, EpubTheme.dark);
    });

    testWidgets('steps through the sizes rather than sliding between them', (
      WidgetTester tester,
    ) async {
      // A slider invites a reader to hunt for a value they cannot name and
      // cannot get back to.
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(
        _app(
          _FakeReading(),
          _FakeHosts(host),
          settings: MemoryReaderSettingsStore(const EpubStyle()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerSettings));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.byTooltip(_pt().readerFontSize).last);
      await tester.pumpAndSettle();

      // The next step up from the default, and not the default plus some
      // arbitrary increment.
      final int start = readerFontSizes.indexOf(const EpubStyle().fontSize);

      expect(host.styles.last.fontSize, readerFontSizes[start + 1]);
    });

    testWidgets('says that it applies to this device alone', (
      WidgetTester tester,
    ) async {
      // A reader who set up a phone and then opened the desktop should know
      // why it did not follow, and the reason is a decision rather than a
      // missing feature.
      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(_FakeHost())));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_pt().readerSettings));
      await tester.pumpAndSettle();

      expect(find.text(_pt().readerSettingsExplanation), findsOneWidget);
    });
  });

  group('a book that does not open', () {
    Future<void> pumpFailure(WidgetTester tester, String code) async {
      await tester.pumpWidget(
        _app(
          _FakeReading(
            failure: AppException(
              kind: ErrorKind.failedPrecondition,
              message: 'no',
              code: code,
              op: 'test',
            ),
          ),
          _FakeHosts(_FakeHost()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a file that is elsewhere is an offer, not an apology', (
      WidgetTester tester,
    ) async {
      await pumpFailure(tester, codeContentNotOnDevice);

      expect(find.text(_pt().readerNotOnDeviceTitle), findsOneWidget);
      expect(find.text(_pt().readerDownload), findsOneWidget);
    });

    testWidgets(
      'a format this build does not render leaves the book its life',
      (WidgetTester tester) async {
        await pumpFailure(tester, codeFormatNotReadable);

        expect(find.text(_pt().readerFormatTitle), findsOneWidget);
        // No retry: trying again cannot change what format the file is, and a
        // button that does nothing is worse than none.
        expect(find.text(_pt().readerRetry), findsNothing);
      },
    );

    testWidgets('anything else is the one case that apologizes', (
      WidgetTester tester,
    ) async {
      await pumpFailure(tester, 'something_else');

      expect(find.text(_pt().readerFailedTitle), findsOneWidget);
      expect(find.text(_pt().readerRetry), findsOneWidget);
    });

    testWidgets('the three refusals are three different sentences', (
      WidgetTester tester,
    ) async {
      // The point of the whole group. A screen that said "something went
      // wrong" for a book that is simply not downloaded would be apologizing
      // for working correctly.
      final Set<String> titles = <String>{
        _pt().readerNotOnDeviceTitle,
        _pt().readerFormatTitle,
        _pt().readerFailedTitle,
      };

      expect(titles, hasLength(3));
    });
  });

  group('marking a passage', () {
    const String range = 'epubcfi(/6/14!/4/10,/2/1:1,/3:4)';

    testWidgets('a selection raises the bar that acts on it', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      expect(find.byKey(readerSelectionKey), findsNothing);

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();

      expect(find.byKey(readerSelectionKey), findsOneWidget);
      expect(find.text(_pt().readerHighlight), findsOneWidget);
    });

    testWidgets('the bar stays when the chrome is tapped away', (
      WidgetTester tester,
    ) async {
      // A reader who selected a passage asked a question, and the tap that
      // clears the page controls must not take the answer with it.
      final _FakeHost host = _FakeHost();

      await tester.pumpWidget(_app(_FakeReading(), _FakeHosts(host)));
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('the page')), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_chromeOpacity(tester), 0);
      expect(find.byKey(readerSelectionKey), findsOneWidget);
    });

    testWidgets('highlighting carries the range and the words it covers', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();

      await tester.tap(find.text(_pt().readerHighlight));
      await tester.pumpAndSettle();

      expect(marks.highlighted, hasLength(1));
      expect(marks.highlighted.single.ebookId, _id);
      expect(marks.highlighted.single.cfiRange, range);
      expect(marks.highlighted.single.passage, 'A terra é ingrata.');

      // The bar goes once the mark is made; the reader has been answered.
      expect(find.byKey(readerSelectionKey), findsNothing);
    });

    testWidgets('a mark just made is offered back as an undo', (
      WidgetTester tester,
    ) async {
      // Offered rather than confirmed beforehand. Marking a passage is what a
      // reader came here to do, and a dialog in front of it would be the app
      // asking whether they meant the gesture they just made.
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerHighlight));
      await tester.pumpAndSettle();

      expect(find.text(_pt().readerHighlighted), findsOneWidget);

      await tester.tap(find.text(_pt().readerMarkUndo));
      await tester.pumpAndSettle();

      expect(marks.removed, <String>['mark-1']);
    });

    testWidgets('a refused mark says so and keeps the selection', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository()
        ..refusal = Exception('no');
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerHighlight));
      await tester.pumpAndSettle();

      expect(find.text(_pt().readerMarkFailed), findsOneWidget);
      // Kept, because a selection dropped after a failure leaves the reader
      // with nothing to try again on.
      expect(find.byKey(readerSelectionKey), findsOneWidget);
    });
  });

  group('noting a passage', () {
    const String range = 'epubcfi(/6/14!/4/10,/2/1:1,/3:4)';

    testWidgets('asks what the reader wants to say and keeps it', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();

      await tester.tap(find.text(_pt().readerNote));
      await tester.pumpAndSettle();

      expect(find.text(_pt().readerNoteTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a seca é personagem');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerNoteSave));
      await tester.pumpAndSettle();

      expect(marks.noted, hasLength(1));
      expect(marks.noted.single.cfiRange, range);
      expect(marks.noted.single.text, 'a seca é personagem');
      expect(find.text(_pt().readerNoted), findsOneWidget);
    });

    testWidgets('cannot be saved with nothing in it', (
      WidgetTester tester,
    ) async {
      // Disabled rather than refused afterwards. The rule is the contract's
      // and it is not a surprise worth springing on somebody who has just
      // typed nothing.
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerNote));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('abandoned, it marks nothing at all', (
      WidgetTester tester,
    ) async {
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      host.select(range, 'A terra é ingrata.');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerNote));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_pt().readerNoteCancel));
      await tester.pumpAndSettle();

      expect(marks.noted, isEmpty);
      expect(marks.highlighted, isEmpty);
      // The selection survives: nothing was decided, so nothing was answered.
      expect(find.byKey(readerSelectionKey), findsOneWidget);
    });
  });

  group('the marks over the page', () {
    testWidgets('are painted from the list and never from the gesture', (
      WidgetTester tester,
    ) async {
      // A mark made on another device arrives the same way one made here does,
      // and both are drawn by this code and no other.
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      marks.emitMarks(<Annotation>[_mark('one'), _mark('two')]);
      await tester.pumpAndSettle();

      expect(host.drawn.map((EpubMark mark) => mark.cfiRange), <String>[
        'one',
        'two',
      ]);

      marks.emitMarks(<Annotation>[_mark('two')]);
      await tester.pumpAndSettle();

      expect(host.erased, <String>['one']);
      // Redrawn nothing: what is already on the page stays on it, which is
      // what makes the reconciliation cheap enough to run per emission.
      expect(host.drawn, hasLength(2));
    });

    testWidgets('a bookmark is not painted over anything', (
      WidgetTester tester,
    ) async {
      // It is a position and covers no range, so there is nothing to draw. The
      // chrome is where it shows.
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      marks.emitMarks(<Annotation>[
        _mark('one', kind: AnnotationKind.bookmark),
      ]);
      await tester.pumpAndSettle();

      expect(host.drawn, isEmpty);
    });

    testWidgets('a list that fails leaves the book on screen', (
      WidgetTester tester,
    ) async {
      // The page is readable; what is missing is the paint over it. An error
      // banner across a book because a highlight did not draw would be worse
      // than the thing it reports.
      final _FakeHost host = _FakeHost();
      final FakeAnnotationRepository marks = FakeAnnotationRepository();
      addTearDown(marks.close);

      await tester.pumpWidget(
        _app(_FakeReading(), _FakeHosts(host), annotations: marks),
      );
      await tester.pumpAndSettle();

      marks.failMarks(Exception('the replica is unreadable'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('the page')), findsOneWidget);
      expect(find.text(_pt().readerFailedTitle), findsNothing);
    });
  });
}

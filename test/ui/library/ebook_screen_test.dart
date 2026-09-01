/// One work's screen: what it says about the file, and what it says when the
/// book is gone.
library;

import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/library/widgets/ebook_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

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

Future<FakeLibraryRepository> pump(WidgetTester tester) async {
  final library = FakeLibraryRepository();

  // Tall enough that the whole page is laid out at once. The screen is a list
  // and a shorter surface would simply not build the sections at the bottom,
  // which is a test scrolling rather than a test asserting.
  tester.view
    ..physicalSize = const Size(900, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(library: library),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EbookScreen(ebookId: _work),
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
      expect(find.widgetWithText(FilledButton, l10n.ebookDownload), findsOneWidget);
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

    testWidgets('is here but not kept, which is a browser downloading to read', (
      WidgetTester tester,
    ) async {
      final library = await pump(tester);

      library
        ..downloaded.add(_work)
        ..works.add(Result<List<Ebook>>.ok(<Ebook>[_ebook()]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ebookFileHereNotKept), findsOneWidget);
      expect(find.text(l10n.storageKeep), findsOneWidget);
    });

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

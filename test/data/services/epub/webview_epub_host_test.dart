/// What can be tested about a host without a webview.
///
/// A webview does not exist in `flutter test` and neither does the engine, so
/// what is exercised here is everything between the two vocabularies: the
/// translation each way, the refusals, and the one rule the port states as an
/// invariant — that a locator crosses unchanged.
///
/// That last one is worth being explicit about. The round-trip test two commits
/// later argues the claim across hosts; this argues it about *this* host, in
/// the only place a Dart test can reach it — the mapping. A CFI that arrived
/// intact at the engine's door is a CFI the engine's own implementation
/// answers about, and one that was trimmed on the way is not.
library;

import 'dart:typed_data';

import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/epub/webview_epub_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as fev;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the position the engine reports', () {
    test('carries both CFIs through byte for byte', () {
      // The invariant, at the one place this host could break it. A CFI with a
      // trailing space, an assertion in brackets and a character offset is
      // still exactly the string the engine said.
      const String start =
          'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05]/2/1:0)';
      const String end = 'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05]/3:10)';

      final EpubPosition position = epubPositionOf(
        fev.EpubLocation(startCfi: start, endCfi: end, progress: 0.5),
      );

      expect(position.startCfi, start);
      expect(position.endCfi, end);
    });

    test('reports a percentage out of a hundred, not out of one', () {
      // `progress.percent` is constrained to 0..100 on the node and on this
      // device; the engine answers 0..1. Getting this wrong stores a book the
      // reader is half way through as one they have barely started.
      expect(
        epubPositionOf(
          fev.EpubLocation(startCfi: 'a', endCfi: 'b', progress: 0.5),
        ).percent,
        50,
      );
    });

    test('clamps a progress past the end of a short spine', () {
      // A page past the end of a short spine has been seen to report slightly
      // over 1, and the column's CHECK would refuse it.
      expect(
        epubPositionOf(
          fev.EpubLocation(startCfi: 'a', endCfi: 'b', progress: 1.02),
        ).percent,
        100,
      );
    });

    test('reports nothing where the engine has not finished computing', () {
      // A book whose location index is still generating reports 0 — for two
      // minutes, on a book of a thousand sections — and this host used to
      // write that down as a percentage. `epubPercentOf` says why it is an
      // absence: the same 0 arrives on the reader's first page, nothing
      // revises it once the index lands, and the wrong one of the two
      // replicates to every other device the reader owns.
      expect(
        epubPositionOf(
          fev.EpubLocation(startCfi: 'a', endCfi: 'b', progress: 0),
        ).percent,
        isNull,
      );
      expect(
        epubPositionOf(
          fev.EpubLocation(startCfi: 'a', endCfi: 'b', progress: -0.01),
        ).percent,
        isNull,
      );
    });
  });

  group('the reading palette', () {
    test('following the system resolves against the app, both ways', () {
      // A reader who put their device in dark mode has already said what they
      // want, and an app that made them say it again would have ignored the
      // first answer.
      expect(
        epubPaletteOf(EpubTheme.followSystem, Brightness.dark).background,
        epubPaletteOf(EpubTheme.dark, Brightness.light).background,
      );
      expect(
        epubPaletteOf(EpubTheme.followSystem, Brightness.light).background,
        epubPaletteOf(EpubTheme.light, Brightness.dark).background,
      );
    });

    test('an explicit theme ignores the system', () {
      // Sepia is the case that proves it: it is neither of the two the system
      // can ask for, so a reader who chose it has to keep it in both.
      expect(
        epubPaletteOf(EpubTheme.sepia, Brightness.dark).background,
        epubPaletteOf(EpubTheme.sepia, Brightness.light).background,
      );
    });

    test('every theme is legible: the text is not the ground', () {
      for (final EpubTheme theme in EpubTheme.values) {
        for (final Brightness brightness in Brightness.values) {
          final EpubPalette palette = epubPaletteOf(theme, brightness);

          expect(
            palette.foreground,
            isNot(palette.background),
            reason: '$theme in $brightness prints its text on itself',
          );
          expect(
            palette.link,
            isNot(palette.background),
            reason: '$theme in $brightness hides its links',
          );
        }
      }
    });
  });

  group('a colour as the engine wants it', () {
    test('is six hex digits behind a hash, alpha dropped', () {
      // The page's opacity is the container's business and not the CSS's: a
      // body rule carrying an alpha would fight the decoration behind it.
      expect(cssColor(const Color(0xFF121212)), '#121212');
      expect(cssColor(const Color(0x80F4ECD8)), '#f4ecd8');
    });

    test('pads a colour whose channels are small', () {
      // The bug this catches is `toRadixString` dropping leading zeros, which
      // turns black into `#0` and a stylesheet into a broken one.
      expect(cssColor(const Color(0xFF000000)), '#000000');
      expect(cssColor(const Color(0xFF0A0B0C)), '#0a0b0c');
    });
  });

  group('the table of contents', () {
    test('keeps its nesting and its hrefs', () {
      final EpubChapter chapter = epubChapterOf(
        fev.EpubChapter(
          title: 'Parte I',
          href: 'part1.xhtml',
          id: 'p1',
          subitems: <fev.EpubChapter>[
            fev.EpubChapter(
              title: 'Capítulo 1',
              href: 'part1.xhtml#ch1',
              id: 'c1',
              subitems: <fev.EpubChapter>[],
            ),
          ],
        ),
      );

      expect(chapter.title, 'Parte I');
      expect(chapter.children, hasLength(1));
      // The fragment is part of the address and a chapter that lost it would
      // navigate to the top of the file it is in rather than to itself.
      expect(chapter.children.single.href, 'part1.xhtml#ch1');
    });
  });

  group('a host that has been closed', () {
    test('refuses every command rather than failing silently', () async {
      final WebviewEpubHost host = WebviewEpubHost();
      await host.dispose();

      // A screen that was disposed while a page turn was in flight is the
      // ordinary case, and a command that quietly did nothing would leave the
      // caller waiting on a future nobody completes.
      expect(() => host.nextPage(), throwsA(isA<Exception>()));
      expect(
        () => host.goTo('epubcfi(/6/4!/4/2/2)'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => host.open(EpubBook(ebookId: 'e', bytes: Uint8List(0))),
        throwsA(isA<Exception>()),
      );
    });

    test('disposing twice is not an error', () async {
      // The reader screen disposes its host, and so does the view model that
      // owns it; whichever runs second should not throw on the way out.
      final WebviewEpubHost host = WebviewEpubHost();

      await host.dispose();
      await expectLater(host.dispose(), completes);
    });
  });

  group('asking about a book before one is open', () {
    test('is a precondition failure and not an empty answer', () async {
      // An empty table of contents and no book at all are different things,
      // and a screen shown the first would render a contents pane that is
      // simply wrong rather than one that is waiting.
      final WebviewEpubHost host = WebviewEpubHost();
      addTearDown(host.dispose);

      expect(() => host.chapters(), throwsA(isA<Exception>()));
    });
  });
}

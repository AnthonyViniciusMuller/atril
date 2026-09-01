/// The value types the port is written in.
///
/// An interface has nothing to test, but the values crossing it do — and one
/// of them has the trap every `copyWith` over a nullable field has: passing
/// `null` to mean *clear this* is indistinguishable from passing nothing at
/// all. `EpubStyle.fontFamily` is nullable and its `null` is a decision — leave
/// the book's own face alone — so the clearing is a flag and this is what says
/// the flag works.
library;

import 'package:atril/data/services/epub/epub_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpubStyle', () {
    const EpubStyle serif = EpubStyle(fontFamily: 'Literata', fontSize: 120);

    test('copyWith replaces only what it was given', () {
      final EpubStyle bigger = serif.copyWith(fontSize: 140);

      expect(bigger.fontSize, 140);
      expect(bigger.fontFamily, 'Literata');
      expect(bigger.lineHeight, serif.lineHeight);
      expect(bigger.theme, serif.theme);
    });

    test('a null family means unchanged, and clearing it is a flag', () {
      // The trap: `copyWith(fontFamily: null)` cannot mean *clear it*, because
      // that is exactly what an omitted argument looks like. A reader turning
      // the override off is a different request from one changing the size,
      // and it has to be spelled differently.
      expect(serif.copyWith(fontFamily: null).fontFamily, 'Literata');
      expect(serif.copyWith(clearFontFamily: true).fontFamily, isNull);
    });

    test('clearing wins over a family given in the same call', () {
      // Nobody should write this, and if they do it should not silently keep a
      // face the caller asked twice to be rid of.
      expect(
        serif.copyWith(fontFamily: 'Georgia', clearFontFamily: true).fontFamily,
        isNull,
      );
    });

    test('two styles with the same fields are the same style', () {
      // It is what lets the reader's settings be applied on change and not on
      // every rebuild: the host is asked to restyle the page when the value
      // differs, and a type without equality would restyle it on every frame.
      expect(const EpubStyle(), const EpubStyle());
      expect(const EpubStyle().hashCode, const EpubStyle().hashCode);
      expect(serif, isNot(const EpubStyle()));
      expect(serif.copyWith(fontSize: 120), serif);
    });

    test('the default leaves the book its own face and follows the system', () {
      // Both defaults are decisions rather than omissions. A book that set a
      // face usually set it for a reason, and a reader who put their device in
      // dark mode has already said what they want.
      expect(const EpubStyle().fontFamily, isNull);
      expect(const EpubStyle().theme, EpubTheme.followSystem);
    });
  });

  group('EpubPosition', () {
    test('carries the page it was measured on, start first', () {
      // The start and not the end, because a reader resuming wants the page
      // they were on rather than the one after it.
      const EpubPosition page = EpubPosition(
        startCfi: 'epubcfi(/6/4[chap01]!/4/2/2[p1]/1:0)',
        endCfi: 'epubcfi(/6/4[chap01]!/4/2/10[p9]/1:44)',
        percent: 12.5,
      );

      expect(page.startCfi, startsWith('epubcfi('));
      expect(page.toString(), contains('12.5%'));
    });
  });
}

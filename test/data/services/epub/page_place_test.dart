/// The estimate a page's place in the spine gives.
library;

import 'package:atril/data/services/epub/engine.dart';
import 'package:atril/data/services/epub/page_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the script that reports a page\'s place', () {
    test('rides the engine\'s own event and reports the two numbers', () {
      final String script = pagePlaceScript();

      expect(script, contains("rendition.on('relocated'"));
      expect(script, contains('book.spine.length'));
      expect(script, contains('book.locations.total'));
      expect(script, contains("callHandler('$pagePlaceHandler'"));
    });

    test('reports the page already on screen when it was injected', () {
      // The hosts inject after the book has rendered, so the first relocation
      // is usually already past. Without this the reader would see no number
      // until they turned a page, which is the failure it exists to end.
      expect(pagePlaceScript(), contains('rendition.location'));
    });

    test('does nothing when injected twice', () {
      // A reader who reopens a book should not get two of every report.
      expect(pagePlaceScript(), contains('if (window.$pagePlaceFlag)'));
      expect(pagePlaceScript(), contains('window.$pagePlaceFlag = true'));
    });

    test('reads the engine\'s internals defensively, one at a time', () {
      // `book.spine` and `book.locations` are the engine's internals rather
      // than its documented surface. A build that renamed either should cost
      // the estimate and not the page the reader is looking at.
      expect(
        'try'.allMatches(pagePlaceScript()).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('is named apart from the glue\'s own messages', () {
      // The namespace is shared with `relocated`, `selection` and the rest, and
      // a collision would be this app quietly answering for the package.
      expect(pagePlaceHandler, startsWith('atril'));
      expect(EpubGlue.all, isNot(contains(pagePlaceHandler)));
    });
  });

  group('what the place says about how far through the book it is', () {
    test('is the section out of the spine', () {
      expect(epubSpinePercentOf(index: 0, spine: 4), 0);
      expect(epubSpinePercentOf(index: 1, spine: 4), 25);
      expect(epubSpinePercentOf(index: 3, spine: 4), 75);
    });

    test('is honest about a book of a thousand sections', () {
      // The book this was found on. Twelve page turns move the reader two
      // sections of 1182, and 0.17% is what that is — a bar that barely moves
      // here is the truth about the book and not a fault in the measurement.
      expect(epubSpinePercentOf(index: 2, spine: 1182), closeTo(0.169, 0.001));
    });

    test('says nothing where there is nothing to divide by', () {
      // A rendition with no spine yet, and a section index the engine gives as
      // -1 for a page it could not place.
      expect(epubSpinePercentOf(index: 0, spine: 0), isNull);
      expect(epubSpinePercentOf(index: -1, spine: 10), isNull);
    });

    test('never leaves the range the column allows', () {
      // `progress.percent` carries a CHECK on both sides of the federation.
      expect(epubSpinePercentOf(index: 40, spine: 10), 100);
    });
  });
}

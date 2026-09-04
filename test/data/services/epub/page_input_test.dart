/// What the page reports, and what this build makes of it.
///
/// The script itself is JavaScript running inside a document no Dart test
/// mounts, so what is pinned here is the part that is Dart's: the mapping from
/// a DOM key name to the reader's vocabulary, and the two decisions the script
/// is generated with. The behaviour of the listeners was measured in a browser
/// against the pinned engine — `page_input.dart` records what came out.
library;

import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/epub/page_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('epubPageEventOfKey', () {
    test('reads the three keys that turn a page forward', () {
      for (final String key in <String>['ArrowRight', 'PageDown', ' ']) {
        expect(epubPageEventOfKey(key), EpubPageEvent.forward, reason: key);
      }
    });

    test('reads the two that turn one back', () {
      for (final String key in <String>['ArrowLeft', 'PageUp']) {
        expect(epubPageEventOfKey(key), EpubPageEvent.back, reason: key);
      }
    });

    test('reads escape', () {
      expect(epubPageEventOfKey('Escape'), EpubPageEvent.dismiss);
    });

    test('reads the older spellings some engines still send', () {
      // `Spacebar` and `Esc` are the pre-standard names, and a webview old
      // enough to send them is a webview this app still runs on.
      expect(epubPageEventOfKey('Spacebar'), EpubPageEvent.forward);
      expect(epubPageEventOfKey('Esc'), EpubPageEvent.dismiss);
    });

    test('drops a key the reader has no control bound to', () {
      // The script forwards whatever it saw rather than carrying a second copy
      // of this list, so the ordinary case is a key that means nothing here.
      for (final String key in <String>['a', 'Shift', 'F5', 'ArrowUp', '']) {
        expect(epubPageEventOfKey(key), isNull, reason: key);
      }
    });
  });

  group('pageInputScript', () {
    test('reports a tap under the name the hosts listen for', () {
      expect(pageInputScript(withKeys: false), contains("'$pageTapHandler'"));
    });

    test('listens for a key only where it was asked to', () {
      // The flag is the whole difference between the Linux host and the other
      // five: a texture inside the Flutter tree gets the key event as well, so
      // forwarding it there would turn two pages for one press.
      expect(pageInputScript(withKeys: true), contains('var withKeys = true;'));
      expect(
        pageInputScript(withKeys: false),
        contains('var withKeys = false;'),
      );
    });

    test('guards against being injected twice', () {
      // Both hosts inject it per book rather than per page, and a reader who
      // reopens a book would otherwise get two of every event.
      expect(
        pageInputScript(withKeys: true),
        contains('if (window.$pageInputFlag) { return; }'),
      );
    });

    test('goes through the bridge the host already installed', () {
      // Not a channel of its own. `flutter_inappwebview.callHandler` is what
      // the glue uses and what every host already answers, so the page has one
      // way out and not two.
      expect(
        pageInputScript(withKeys: true),
        contains('window.flutter_inappwebview.callHandler'),
      );
    });

    test('registers on every document the engine renders into', () {
      // A book is rendered into a nested document per section, and an event
      // does not cross out of one. The hook is the engine's own door for
      // running something in each.
      expect(
        pageInputScript(withKeys: true),
        contains('rendition.hooks.content.register'),
      );
    });
  });
}

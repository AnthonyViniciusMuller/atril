/// The pin, as a test.
///
/// This is the only thing standing between "one engine" as an argument in
/// `architecture.md` and one engine as a fact about the build. `pubspec.yaml`
/// constrains the package to an exact version, which stops a `pub upgrade`
/// moving the renderer; nothing stops a republished version, a patched pub
/// cache or a vendored copy somebody edited. Hashing what the bundle actually
/// holds is what notices.
///
/// The failure it guards against is worth stating, because it is not a crash.
/// A different `epub.js` still opens the book, still renders the page and
/// still answers with a CFI — one that a device running the old engine may
/// resolve a paragraph away. The reader sees a highlight in the wrong place
/// weeks later and there is nothing in the log to connect it to a dependency
/// bump. So the check is cheap, total, and here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:atril/data/services/epub/engine.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `rootBundle` reads through the asset manifest the test harness builds, so
  // the binding has to exist before the first load.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the pinned engine', () {
    test('every asset the host page reaches has the digest it is pinned at', () async {
      final wrong = <String, String>{};

      for (final MapEntry<String, String> pinned
          in EpubEngine.assetDigests.entries) {
        final ByteData bytes = await loadEngineAsset(pinned.key);
        final String actual = sha256
            .convert(
              bytes.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              ),
            )
            .toString();

        if (actual != pinned.value) {
          wrong[pinned.key] = actual;
        }
      }

      expect(
        wrong,
        isEmpty,
        reason:
            'The EPUB engine in the bundle is not the one this app is pinned '
            'to. A locator written by the pinned renderer is not guaranteed to '
            'resolve under this one, and the annotations that already carry '
            'those locators have been replicated. Establish that the new bytes '
            'resolve the corpus in locator_round_trip_test.dart before '
            'updating the digests in engine.dart.',
      );
    });

    test('the pinned version matches the one pubspec.yaml resolves', () async {
      // Read from the lock file rather than the pubspec: what ships is what
      // was resolved, and a range loosened by accident would still satisfy the
      // pubspec while resolving to something else.
      final String lock = await File('pubspec.lock').readAsString();

      expect(
        lock,
        contains('version: "${EpubEngine.packageVersion}"'),
        reason:
            'engine.dart names ${EpubEngine.packageVersion} and the lock file '
            'resolves another version of ${EpubEngine.package}.',
      );
    });

    test('the host page loads the renderer and the glue, and nothing remote', () async {
      final String page = utf8.decode(
        (await loadEngineAsset(EpubEngine.hostPage)).buffer.asUint8List(),
      );

      // The engine is loaded from the bundle and never from a CDN. A renderer
      // fetched at run time is a renderer that changes under a locator, and it
      // is a book that will not open on a train.
      //
      // The comments come out first, and that is not the check being softened.
      // The page carries two commented-out CDN tags — jQuery and a swipe
      // plugin the package stopped using — and a check that read them would be
      // red on a page that fetches nothing, which is a check somebody deletes.
      // What matters is the markup a browser executes.
      final String markup = page.replaceAll(
        RegExp(r'<!--.*?-->', dotAll: true),
        '',
      );

      expect(
        RegExp(r'''<script[^>]+src\s*=\s*["']https?://''').hasMatch(markup),
        isFalse,
        reason: 'the host page loads a script over the network',
      );

      expect(page, contains('epub.js'));
      expect(page, contains('epubView.js'));
    });

    test('every pinned asset is reachable under the path the page uses', () {
      final Map<String, String> served = engineAssetsByPath();

      // The Linux host serves these by path, because a CEF webview has no
      // asset protocol to be handed. The relative `src` attributes in the host
      // page resolve against `html/`, so the two files it names one directory
      // up have to be there under `dist/`.
      expect(served['html/swipe.html'], EpubEngine.hostPage);
      expect(served['dist/epub.js'], EpubEngine.renderer);
      expect(served['html/epubView.js'], EpubEngine.glue);
      expect(served.length, EpubEngine.assetDigests.length);
      expect(
        served.keys.every((String path) => !path.startsWith('/')),
        isTrue,
        reason:
            'a served path is what a URL is built from and must be relative',
      );
    });
  });
}

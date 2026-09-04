/// The bridge the Linux host shims, and the shape of what crosses it.
///
/// CEF does not exist in `flutter test`, so what is exercised here is the half
/// of this host that is a protocol rather than a webview: the shim that makes
/// the pinned glue work unchanged, and the encoding of what goes over it.
///
/// It matters more than the equivalent test for the other host, because this is
/// the one place where Atril spells the glue's function names itself rather
/// than getting them from a package's controller. A name misspelled here is a
/// call into nothing on one target and a working call on five, which is exactly
/// the shape of divergence this phase is arranged to prevent.
library;

import 'package:atril/data/services/epub/desktop_epub_host.dart';
import 'package:atril/data/services/epub/engine.dart';
import 'package:atril/data/services/epub/engine_server.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bridge shim', () {
    test('provides exactly the two things the glue expects', () {
      // `epubView.js` talks through `window.flutter_inappwebview.callHandler`
      // and announces itself on `flutterInAppWebViewPlatformReady`. Neither is a
      // webview feature — they are one package's convention — which is why any
      // host can provide them and why this one must.
      expect(epubBridgeShim, contains('window.flutter_inappwebview'));
      expect(epubBridgeShim, contains('callHandler'));
    });

    test('does not overwrite a bridge that is already there', () {
      // On a target where the real plugin installed one, a shim that replaced
      // it would break the host it was injected into. The guard is what makes
      // this safe to inject at load start without knowing who else has run.
      expect(epubBridgeShim, contains('if (window.flutter_inappwebview)'));
    });

    test('sends through the channel this host actually registers', () {
      // The name is interpolated rather than written twice, and this is what
      // says so: two literals agree until one of them is edited, and the
      // failure would be a page that renders and never reports a position.
      expect(epubBridgeShim, contains('$epubBridgeChannel({'));
    });

    test('hands the channel an object and lets it do the encoding', () {
      // `webview_cef` implements a channel as `external.JavaScriptChannel`,
      // which `JSON.stringify`s whatever it is handed before the message leaves
      // the render process. A string handed to it arrived as JSON *containing*
      // JSON: `jsonDecode` answered with a `String` rather than a map, so
      // `decodeBridgeMessage` dropped every message the page ever sent and no
      // book opened on Linux at all.
      expect(epubBridgeShim, isNot(contains('JSON.stringify')));
      expect(
        decodeBridgeMessage('"{\\"handler\\": \\"readyToLoad\\"}"'),
        isNull,
        reason: 'encoding it twice is what a dropped message looks like',
      );
    });

    test('survives a channel that is not installed yet', () {
      // The shim is injected at load start and the channel is installed a
      // moment later. Nothing should call it in that window — the readiness
      // event is dispatched last, deliberately — but a shim that threw would
      // take the glue's own listener down with it.
      expect(epubBridgeShim, contains('try {'));
      expect(epubBridgeShim, contains('catch (e)'));
    });

    test('answers with a promise, as the convention documents', () {
      // The glue never reads it. It is returned because `callHandler` is
      // documented to, and a host that quietly changed the contract would be a
      // host the next version of the glue could break against.
      expect(epubBridgeShim, contains('Promise.resolve'));
    });
  });

  group('a message the host does not understand', () {
    // Everything crossing this bridge is a string somebody else's JavaScript
    // wrote, and it arrives in a platform callback with no `await` above it:
    // a decode that threw was an unhandled error in the zone rather than a
    // message this host declined to read.
    test('is dropped rather than thrown out of the callback', () {
      expect(decodeBridgeMessage('{'), isNull);
      expect(decodeBridgeMessage(''), isNull);
      expect(decodeBridgeMessage('not json at all'), isNull);
    });

    test('is dropped when it is json but not an object', () {
      // A page under the glue can call `callHandler` with anything, and the
      // shim stringifies whatever it is given.
      expect(decodeBridgeMessage('[1, 2, 3]'), isNull);
      expect(decodeBridgeMessage('42'), isNull);
      expect(decodeBridgeMessage('null'), isNull);
      expect(decodeBridgeMessage('"a string"'), isNull);
    });

    test('an object is handed over as it was written', () {
      expect(
        decodeBridgeMessage('{"handler":"rendered","args":[]}'),
        <String, Object?>{'handler': 'rendered', 'args': <Object?>[]},
      );
      expect(decodeBridgeMessage('{"reply":7,"value":null}'), <String, Object?>{
        'reply': 7,
        'value': null,
      });
    });
  });

  group('a host that has been closed', () {
    test('refuses every command rather than failing silently', () async {
      final DesktopEpubHost host = DesktopEpubHost();
      await host.dispose();

      expect(() => host.nextPage(), throwsA(isA<Exception>()));
      expect(
        () => host.goTo('epubcfi(/6/4!/4/2/2)'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => host.textOf('epubcfi(/6/4!/4,/2,/4)'),
        throwsA(isA<Exception>()),
      );
    });

    test('refuses a request as fast as it refuses a command', () async {
      // A host with no page yet is the same state for both, and it was not
      // answered the same way: the request path sent through a helper that did
      // nothing when there was no webview, so a `textOf` waited the full
      // thirty seconds for a reply nobody was going to send.
      final DesktopEpubHost host = DesktopEpubHost();
      addTearDown(host.dispose);

      await expectLater(
        host.textOf('epubcfi(/6/4!/4,/2,/4)'),
        throwsA(
          isA<AppException>().having(
            (AppException it) => it.code,
            'code',
            'epub_not_ready',
          ),
        ),
      );
    });

    test('disposing twice is not an error', () async {
      final DesktopEpubHost host = DesktopEpubHost();

      await host.dispose();
      await expectLater(host.dispose(), completes);
    });

    test(
      'asking about a book before one is open is a precondition failure',
      () {
        final DesktopEpubHost host = DesktopEpubHost();
        addTearDown(host.dispose);

        expect(() => host.chapters(), throwsA(isA<Exception>()));
      },
    );
  });

  group('the styling both hosts share', () {
    test('is computed from the same palette on either side of the port', () {
      // The two hosts build the same `body` rule from the same colours, because
      // they drive the same glue. If they diverged, a reader's page would be one
      // colour on Linux and another everywhere else — which is cosmetic, unlike
      // a locator, but is the same class of mistake.
      final EpubPalette sepia = epubPaletteOf(EpubTheme.sepia, Brightness.dark);

      expect(cssColor(sepia.background), '#f4ecd8');
      expect(sepia.foreground, isNot(sepia.background));
    });
  });

  group('what a host will accept as a place to open at', () {
    test('a CFI is recognized and anything else is not', () {
      // Both hosts refuse a non-CFI locator before handing it to the engine,
      // and both then open at the beginning rather than failing: a position
      // replicated from a device that was reading a PDF is a legitimate row and
      // a meaningless instruction.
      expect(
        EpubEngine.looksLikeCfi('epubcfi(/6/4[ch1]!/4/2/2[p1]/1:0)'),
        isTrue,
      );
      expect(EpubEngine.looksLikeCfi('page=42'), isFalse);
      expect(EpubEngine.looksLikeCfi(''), isFalse);
      // A shape check and not a parser: this is deliberately all it knows, and
      // the file says why at length.
      expect(EpubEngine.looksLikeCfi('epubcfi(anything at all)'), isTrue);
    });
  });
}

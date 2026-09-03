/// The engine, over a socket.
///
/// This one *can* be tested properly, and that is worth taking: it is an
/// `HttpServer` and a `HttpClient`, both of which exist in `flutter test`, so
/// what the Linux host will be given is exercised here rather than argued for.
///
/// What matters is that the bytes served are the bytes pinned. The whole
/// "one engine" claim rests on the Linux host loading the same file the other
/// five do, and this is the only place in the chain where the file passes
/// through code this project wrote.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atril/data/services/epub/engine.dart';
import 'package:atril/data/services/epub/engine_server.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EngineServer server;

  setUpAll(() async {
    // `TestWidgetsFlutterBinding` installs an `HttpOverrides` that answers every
    // request with a 400 and makes no connection, which is the right default for
    // a widget test and exactly wrong here: what is under test *is* an HTTP
    // server, and the loopback socket it binds is not a network request in the
    // sense that override is protecting against. Clearing it is what lets this
    // file exercise the thing the Linux host will actually be given.
    HttpOverrides.global = null;
    server = await EngineServer.shared();
  });

  tearDownAll(() async {
    await server.close();
  });

  Future<HttpClientResponse> get(String path) async {
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(
      Uri.parse('${server.origin}$path'),
    );
    final HttpClientResponse response = await request.close();

    client.close();

    return response;
  }

  group('the engine server', () {
    test('binds the loopback address and nothing else', () {
      // There is no case in which another machine should be able to read this,
      // and saying so to the operating system is better than saying it in a
      // comment.
      expect(server.origin, startsWith('http://127.0.0.1:'));
    });

    test('serves the host page at the URL it advertises', () async {
      final HttpClientResponse response = await get(
        Uri.parse(server.hostPageUrl).path,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'text/html');
    });

    test('serves every pinned asset, byte for byte', () async {
      // The claim the whole phase rests on, at the one point in the chain where
      // this project's own code touches the file. A server that transcoded, or
      // that served a stale copy, would be a second engine.
      for (final MapEntry<String, String> pinned
          in EpubEngine.assetDigests.entries) {
        final String path = pinned.key.substring(
          EpubEngine.assetRoot.length + 1,
        );
        final HttpClientResponse response = await get('/$path');

        expect(response.statusCode, HttpStatus.ok, reason: path);

        final List<int> bytes = <int>[
          for (final List<int> chunk in await response.toList()) ...chunk,
        ];

        expect(
          sha256.convert(bytes).toString(),
          pinned.value,
          reason: '$path was not served as it is pinned',
        );
      }
    });

    test('tells a browser what each file is', () async {
      // A script served as `text/plain` is a script a browser refuses to run,
      // which would be the engine failing to load with nothing in the log.
      expect(
        (await get('/dist/epub.js')).headers.contentType?.mimeType,
        'text/javascript',
      );
      expect(
        (await get('/html/examples.css')).headers.contentType?.mimeType,
        'text/css',
      );
    });

    test('lets a host keep what cannot change under it', () async {
      // The engine is an asset of this build, served at an origin that exists
      // only while this process does. `no-cache` asked the host to revalidate
      // before every use, which is a conditional request per asset per book
      // against a server with no answer for one.
      final HttpClientResponse response = await get('/dist/epub.js');

      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        engineCacheControl,
      );
      expect(engineCacheControl, isNot(contains('no-cache')));

      await response.drain<void>();
    });

    test('serves the engine and refuses the rest of the bundle', () async {
      // The page rendering in this webview is a file somebody else wrote. It
      // reaching the reader's own assets by asking for them would be this
      // server handing a book the application's insides, so what is served is
      // exactly the closure `engine.dart` pins and nothing adjacent to it.
      expect(
        (await get('/html/themes.css')).statusCode,
        HttpStatus.notFound,
        reason: 'a package asset outside the pinned set was served',
      );
      expect(
        (await get('/assets/licenses/epub.js.LICENSE')).statusCode,
        HttpStatus.notFound,
      );
      expect((await get('/../../../pubspec.yaml')).statusCode, isNot(200));
    });

    test('answers a write with a refusal rather than acting on it', () async {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.postUrl(
        Uri.parse(server.hostPageUrl),
      );
      final HttpClientResponse response = await request.close();

      client.close();

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('is one server however many hosts ask for it', () async {
      // A reader with four books open is four hosts, and four sockets serving
      // identical files would be three more than the argument needs.
      final EngineServer again = await EngineServer.shared();

      expect(identical(again, server), isTrue);
      expect(again.origin, server.origin);
    });

    test('the page it serves can find its own scripts', () async {
      // The host page names its scripts by relative path, so the server has to
      // answer at exactly the paths those resolve to. It is the one thing that
      // would fail silently: a missing script is a blank page.
      final HttpClientResponse page = await get(
        Uri.parse(server.hostPageUrl).path,
      );
      final String html = utf8.decode(<int>[
        for (final List<int> chunk in await page.toList()) ...chunk,
      ]);
      final Uri base = Uri.parse(server.hostPageUrl);

      final Iterable<String> sources = RegExp(
        r'''<script[^>]+src\s*=\s*["']([^"']+)["']''',
      ).allMatches(html).map((RegExpMatch m) => m.group(1)!);

      expect(sources, isNotEmpty);

      for (final String source in sources) {
        if (source.startsWith('http')) {
          continue;
        }

        expect(
          (await get(base.resolve(source).path)).statusCode,
          HttpStatus.ok,
          reason:
              'the host page asks for $source and the server has no such '
              'path',
        );
      }
    });
  });

  group('a book on offer', () {
    // The book crosses to the engine over this socket rather than through the
    // source of a script. Three transient copies of a whole file, each larger
    // than the file, is what the other way cost.
    Uint8List bytes() =>
        Uint8List.fromList(<int>[for (int i = 0; i < 1024; i++) i % 256]);

    test('is served whole, at the url it was offered under', () async {
      final Uint8List book = bytes();
      final String url = server.offer(book);

      expect(url, startsWith(server.origin));

      final HttpClientResponse response = await get(Uri.parse(url).path);

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/epub+zip');
      expect(<int>[
        for (final List<int> chunk in await response.toList()) ...chunk,
      ], book);
    });

    test('answers once and never again', () async {
      // A URL that stops working after it has been read is one a page that
      // outlived the reader who opened it cannot replay.
      final String url = server.offer(bytes());

      expect((await get(Uri.parse(url).path)).statusCode, HttpStatus.ok);

      final HttpClientResponse again = await get(Uri.parse(url).path);

      expect(again.statusCode, HttpStatus.notFound);

      await again.drain<void>();
    });

    test('is not guessable, and an invented path is not a book', () async {
      final String url = server.offer(bytes());
      final HttpClientResponse response = await get('/book/deadbeef');

      expect(response.statusCode, HttpStatus.notFound);
      expect(Uri.parse(url).path, isNot('/book/deadbeef'));

      await response.drain<void>();
      server.withdraw(url);
    });

    test('withdrawn, it is not held for the life of the process', () async {
      // A reader who closed the screen before the page came up. The book is a
      // whole file in memory, and nothing else would ever remove it.
      final String url = server.offer(bytes());

      server.withdraw(url);

      final HttpClientResponse response = await get(Uri.parse(url).path);

      expect(response.statusCode, HttpStatus.notFound);

      await response.drain<void>();
    });

    test('does not shadow the engine it is served beside', () async {
      // Two namespaces on one origin: the engine's paths are what the host
      // page's relative script tags resolve to, and none of them starts where
      // a book does.
      final String url = server.offer(bytes());

      expect(Uri.parse(url).path, startsWith('/book/'));
      expect(
        engineAssetsByPath().keys.any((String it) => it.startsWith('book/')),
        isFalse,
      );

      server.withdraw(url);
    });
  });

  group('the asset a host loads', () {
    test('is read whole, with its offset respected', () async {
      // `rootBundle.load` can hand back a view into a larger buffer, and a
      // caller that ignored `offsetInBytes` would hash and serve the wrong
      // bytes — on a good day, somebody else's asset.
      final ByteData data = await loadEngineAsset(EpubEngine.renderer);
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      expect(
        sha256.convert(bytes).toString(),
        EpubEngine.assetDigests[EpubEngine.renderer],
      );
    });
  });
}

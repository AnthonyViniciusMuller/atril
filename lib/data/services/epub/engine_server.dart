/// The engine, served over a loopback socket.
///
/// The Linux host is the one target with no way to hand a webview an asset. A
/// `flutter_inappwebview` build has `initialFile`, a browser has the bundle's
/// own URL space, and CEF has neither: it takes a URL. So the pinned assets are
/// served — from the bundle, over `127.0.0.1`, on a port the operating system
/// chose — and the host page's relative `<script src="../dist/epub.js">`
/// resolves against that origin exactly as it does against any other.
///
/// **The bytes are the bundle's and nothing is copied to disk.** A temporary
/// directory would have been the other way to give CEF a URL, and it would have
/// been the engine in a second place — one that survives the process, that a
/// reader could edit, and whose contents `engine_test.dart` does not hash. What
/// is served here is what that test pins.
///
/// **It is one server for the whole application, not one per book.** A reader
/// who opens four books opens four hosts, and four sockets serving identical
/// files would be three more than the argument needs. It starts on the first
/// open and lives as long as the process, which is the same lifetime the engine
/// has.
///
/// It binds the loopback address and nothing else. There is no case in which
/// another machine should be able to read this, and `InternetAddress.loopbackIPv4`
/// is what says so to the operating system rather than in a comment.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'engine.dart';

final _log = loggerFor('data/epub');

/// The operation a failure here reports under.
const String opEngineServer = 'epub/engine server';

/// Where the engine is served from, for a host that can only be given a URL.
final class EngineServer {
  EngineServer._(this._server, this.origin);

  static Future<EngineServer>? _starting;

  final HttpServer _server;

  /// The origin the host page is under, as `http://127.0.0.1:<port>`.
  final String origin;

  /// The URL of the page a host should open.
  String get hostPageUrl =>
      '$origin/${EpubEngine.hostPage.substring(EpubEngine.assetRoot.length + 1)}';

  /// The books on offer, by the path each was offered under.
  final Map<String, Uint8List> _books = <String, Uint8List>{};

  /// A URL the page can fetch [bytes] from, once.
  ///
  /// **It is how a book crosses to the engine without being copied three
  /// times.** The other way — the one this replaced — was base64 into a
  /// string, that string into JSON, and the JSON into the source of a script:
  /// three transient copies of a whole book beside the one the view model
  /// holds, each of them larger than the file. A fetch over the loopback
  /// socket that is already serving the engine costs the copy the socket
  /// makes and nothing else, and the page does the decoding it was going to do
  /// anyway.
  ///
  /// The path is unguessable and the entry is removed the first time it is
  /// read. Neither is what keeps a book private — the server binds the
  /// loopback address and answers nobody else — but a URL that stops working
  /// once it has been used is one that cannot be replayed by a page that
  /// outlived the reader who opened it.
  String offer(Uint8List bytes) {
    final String path =
        '$_bookPathPrefix/${_random.nextInt(1 << 32).toRadixString(16)}'
        '${_random.nextInt(1 << 32).toRadixString(16)}';

    _books[path] = bytes;

    return '$origin$path';
  }

  /// Takes back an offer nobody read, so a book that never loaded is not held
  /// for the life of the process.
  void withdraw(String url) => _books.remove(Uri.parse(url).path);

  /// The one server, started if it is not running.
  ///
  /// The future is remembered rather than the server, so that two hosts opening
  /// at once wait on one bind instead of racing to make two.
  static Future<EngineServer> shared({AssetBundle? bundle}) =>
      _starting ??= _start(bundle ?? rootBundle);

  static Future<EngineServer> _start(AssetBundle bundle) async {
    try {
      // Port zero: the operating system picks a free one. A fixed port would
      // be a second copy of this application failing to start, and on a shared
      // machine it would be somebody else's process answering for the engine.
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final EngineServer engine = EngineServer._(
        server,
        'http://${server.address.address}:${server.port}',
      );

      unawaited(engine._serve(bundle));
      _log.info('the epub engine is served from ${engine.origin}');

      return engine;
    } on SocketException catch (error) {
      _starting = null;

      throw AppException(
        kind: ErrorKind.unavailable,
        message: 'the epub engine could not be served on the loopback address',
        code: 'engine_server_bind_failed',
        op: opEngineServer,
        cause: error,
      );
    }
  }

  Future<void> _serve(AssetBundle bundle) async {
    final Map<String, String> assets = engineAssetsByPath();

    await for (final HttpRequest request in _server) {
      // A book, before the engine: it is the one thing served here that is not
      // an asset, and it is read once and forgotten.
      final Uint8List? book = request.method == 'GET'
          ? _books.remove(request.uri.path)
          : null;

      if (book != null) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('application', 'epub+zip')
          // Never cached: it is offered once, at a path that will not answer
          // again, and it is the reader's own file.
          ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
          ..add(book);

        await request.response.close();
        continue;
      }

      // Only what the engine is. The map is the closure `engine.dart` pins, so
      // a request for anything else is not a file this server has decided to
      // withhold — it is a file that is not part of the engine, and answering
      // 404 is the truth. It also means a book cannot reach the rest of the
      // bundle by asking for it, which matters because the thing rendering in
      // this webview is a file somebody else wrote.
      final String path = request.uri.path.replaceFirst(RegExp('^/'), '');
      final String? key = assets[path];

      if (key == null || request.method != 'GET') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }

      try {
        final ByteData bytes = await loadEngineAsset(key, bundle: bundle);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = _typeOf(path)
          // The engine cannot change while the process runs — it is an asset —
          // so the page and its scripts are cached for the session and the
          // second book a reader opens does not re-read them off the bundle.
          //
          // It said `no-cache` and meant the opposite: that directive asks the
          // browser to revalidate before every use, which is a conditional
          // request per asset per book against a server that cannot answer 304.
          // A lifetime is what the sentence above describes, and it cannot
          // outlive the process it is talking about: the port is chosen at bind
          // time, so the next run of the app is a different origin and nothing
          // cached here is reachable from it.
          ..headers.set(HttpHeaders.cacheControlHeader, engineCacheControl)
          ..add(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
      } on Object catch (error) {
        _log.warning('the engine asset $key could not be read', error);
        request.response.statusCode = HttpStatus.internalServerError;
      }

      await request.response.close();
    }
  }

  /// Stops serving.
  ///
  /// It exists for the tests and for a clean shutdown; nothing in the running
  /// application calls it, because the engine's lifetime is the process's.
  Future<void> close() async {
    _starting = null;
    _books.clear();
    await _server.close(force: true);
  }
}

/// Where a book on offer is served from, under the engine's own origin.
///
/// It is a prefix no engine asset has, so the two namespaces cannot collide:
/// the assets are served under the paths the host page's relative `src`
/// attributes resolve to, and none of them starts here.
const String _bookPathPrefix = '/book';

/// Where the unguessable half of a book's path comes from.
final Random _random = Random.secure();

/// How long a host may keep an engine asset without asking again.
///
/// An hour is longer than a reading session and shorter than nothing, and the
/// exact number matters less than the directive: what is being served is an
/// asset out of this build's own bundle, at an origin that exists only while
/// this process does.
const String engineCacheControl = 'max-age=3600, immutable';

/// The media type a browser needs to be told, by extension.
///
/// A script served as `text/plain` is a script a browser refuses to execute,
/// which would be the engine not loading with nothing in the log to say why.
ContentType _typeOf(String path) {
  if (path.endsWith('.html')) {
    return ContentType.html;
  }
  if (path.endsWith('.js')) {
    return ContentType('text', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.css')) {
    return ContentType('text', 'css', charset: 'utf-8');
  }
  if (path.endsWith('.gif')) {
    return ContentType('image', 'gif');
  }

  return ContentType.binary;
}

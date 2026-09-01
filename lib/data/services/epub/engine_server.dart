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
          ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
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
    await _server.close(force: true);
  }
}

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

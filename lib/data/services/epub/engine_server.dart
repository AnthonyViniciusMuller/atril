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
import 'dart:convert';
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

  /// The pages handed out, by the identifier each was handed out under.
  ///
  /// A host waits on its own entry and the page itself completes it, by asking
  /// for [_readyPath] as the last thing the document does.
  final Map<String, Completer<void>> _sessions = <String, Completer<void>>{};

  /// A page for one host, and the moment that page has finished loading.
  ///
  /// **It is a handshake and not a guess, and that is the whole of it.**
  /// `webview_cef` offers Dart no dependable moment at which the document
  /// exists: `initialize()` returns fifty milliseconds after the browser was
  /// created and long before it has navigated, and the load callbacks arrive
  /// through a method channel whose bookkeeping the plugin fills in *after* the
  /// first of them can already have fired. Both of the things a host must do to
  /// a *live* document were being done against that guess, and both lost:
  ///
  /// * the JavaScript channel, which the plugin installs by assigning a global
  ///   in the current context — so a navigation afterwards throws it away and
  ///   nothing the page says is ever heard;
  /// * the `flutterInAppWebViewPlatformReady` event, which the glue answers
  ///   with `readyToLoad` — and which is heard by nobody until `epubView.js`
  ///   has run, because that is where the listener is registered.
  ///
  /// So the page says when it is there, over the socket that is already serving
  /// it, and the host does both of those things afterwards.
  EngineSession openSession() {
    final Completer<void> loaded = Completer<void>();
    final String id = _token();

    _sessions[id] = loaded;

    return EngineSession._(
      id,
      '$hostPageUrl?$engineSessionQuery=$id',
      loaded.future,
    );
  }

  /// Forgets a session, so a reader who closed the screen before the page came
  /// up is not an entry held for the life of the process.
  void closeSession(EngineSession session) => _sessions.remove(session.id);

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
    final String path = '$_bookPathPrefix/${_token()}';

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

      // The page announcing that it has loaded. It carries no body and it is
      // not a file: what it is for is the completer on the other side of it.
      if (request.method == 'GET' && request.uri.path == _readyPath) {
        final Completer<void>? loaded = _sessions.remove(
          request.uri.queryParameters[engineSessionQuery] ?? '',
        );

        if (loaded != null && !loaded.isCompleted) {
          loaded.complete();
        }

        request.response.statusCode = loaded == null
            ? HttpStatus.notFound
            : HttpStatus.noContent;
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
        final Uint8List body = key == EpubEngine.hostPage
            ? withBridgeShim(
                bytes,
                session: request.uri.queryParameters[engineSessionQuery],
              )
            : bytes.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              );

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
          ..add(body);
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
    _sessions.clear();
    await _server.close(force: true);
  }
}

/// Where a book on offer is served from, under the engine's own origin.
///
/// It is a prefix no engine asset has, so the two namespaces cannot collide:
/// the assets are served under the paths the host page's relative `src`
/// attributes resolve to, and none of them starts here.
const String _bookPathPrefix = '/book';

/// Where a page says that it has loaded.
///
/// As with a book, it is a path no engine asset has, so the announcement and
/// the engine cannot be asking for the same thing.
const String _readyPath = '/ready';

/// The query parameter naming which host a page belongs to.
///
/// It is a query and not a path because the page is still the pinned document
/// at the pinned path — the server reads this to know whose announcement to
/// write into it, and the asset lookup, which reads the path alone, is
/// untouched.
const String engineSessionQuery = 'session';

/// Where the unguessable half of a book's or a session's path comes from.
final Random _random = Random.secure();

/// An identifier no page can guess.
String _token() =>
    '${_random.nextInt(1 << 32).toRadixString(16)}'
    '${_random.nextInt(1 << 32).toRadixString(16)}';

/// One host's page, and the moment that page announced itself.
final class EngineSession {
  const EngineSession._(this.id, this.pageUrl, this.loaded);

  /// The identifier the page announces under.
  final String id;

  /// The URL the host opens.
  final String pageUrl;

  /// Completed when the document exists and every script under it has run.
  final Future<void> loaded;
}

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

/// The name the glue's messages arrive under.
///
/// `webview_cef` installs a channel as a global function of this name, so it
/// has to be something no page would define for itself. The glue never sees it:
/// what the glue calls is `window.flutter_inappwebview.callHandler`, and the
/// shim below is what turns one into the other.
const String epubBridgeChannel = 'AtrilEpubBridge';

/// The shim that makes the pinned glue work unchanged under CEF.
///
/// `epubView.js` talks to Flutter through `window.flutter_inappwebview
/// .callHandler(name, ...args)` and waits for a `flutterInAppWebViewPlatformReady`
/// event before it announces itself. Neither is a webview feature — they are
/// this one package's convention — so any host can provide them, and the
/// browser host in `flutter_epub_viewer` provides exactly the same two things
/// over `dart:js_interop`.
///
/// **It is served inside the page, and injected at load start as well.** The
/// injection alone was not enough, and the reason is worth writing down:
/// `webview_cef` delivers `onLoadStart` — the callback it injects load-start
/// user scripts from — native-to-Flutter off the platform thread, which Flutter
/// warns about and which may drop the message. A dropped `onLoadStart` is a
/// shim that never exists, so the glue's `callHandler` is undefined, so
/// `readyToLoad` is never sent and the book never loads. Serving it in the
/// document removes that dependency: the shim is there as soon as the page
/// parses, before any script under it runs.
///
/// It is idempotent — it returns early when `window.flutter_inappwebview` is
/// already set — so the load-start injection is kept and is simply a no-op when
/// the served copy got there first.
///
/// The channel function it calls is installed separately and slightly later,
/// which is safe: the reference is resolved inside the call and the first call
/// cannot happen until the readiness event is dispatched, which the host does
/// last.
///
/// **What crosses is an object and never a string.** `webview_cef` implements a
/// channel as `external.JavaScriptChannel`, which `JSON.stringify`s whatever it
/// is handed before the message leaves the render process. A string handed to
/// it therefore arrived as JSON *containing* JSON, `jsonDecode` answered with a
/// `String` rather than a map, and [decodeBridgeMessage] dropped every message
/// the page ever sent — a page that rendered, a book that never opened and one
/// line in the log per position. Handing over the object is what makes the
/// encoding happen once.
const String epubBridgeShim =
    '''
(function () {
  if (window.flutter_inappwebview) { return; }
  window.flutter_inappwebview = {
    callHandler: function (name) {
      var args = Array.prototype.slice.call(arguments, 1);
      try {
        $epubBridgeChannel({ handler: name, args: args });
      } catch (e) {
        console.log('the epub bridge is not installed yet: ' + e);
      }
      // The glue never reads this, and returning a promise keeps it honest
      // about the shape flutter_inappwebview documents.
      return Promise.resolve(null);
    }
  };
})();
''';

/// The script by which a page tells its host that it is there.
///
/// **It is a request and not a bridge call**, because the bridge is one of the
/// two things this announcement exists to order: the channel it would go over
/// is installed by the host *after* this arrives. A `fetch` needs nothing but
/// the document, and the document is the thing being announced.
///
/// It is added at the end of the body, after `<script src="epubView.js">`, so
/// that by the time the host answers by dispatching the readiness event the
/// glue's listener for it has been registered.
///
/// The retries are for a socket that refused one connection, not for a server
/// that is not there: a page that cannot reach its own origin is a book that
/// will not open, and the host's deadline is what says so.
String epubReadyAnnouncement(String session) {
  final String url = jsonEncode('$_readyPath?$engineSessionQuery=$session');

  return '''
(function () {
  function announce(left) {
    fetch($url).catch(function () {
      if (left > 0) { setTimeout(function () { announce(left - 1); }, 100); }
    });
  }
  announce(10);
})();
''';
}

/// [page] with the bridge shim inlined ahead of everything it loads, and — for
/// a page a host is waiting on — the announcement that it has.
///
/// The shim goes immediately after `<head>`, which is before the script tags
/// that follow it, so `window.flutter_inappwebview` exists by the time the glue
/// runs. The announcement goes immediately before `</body>`, which is *after*
/// them, so the glue's listener is registered by the time the host answers it.
/// The two ends of the document are the two ends of the ordering.
///
/// A page with no `<head>` is served unchanged rather than guessed at: the host
/// page is pinned by digest, so that case is a bundle that is not the engine,
/// and the load will fail loudly on its own. A page asked for with no session —
/// a browser pointed at the origin, a test — is served without an announcement,
/// because there is nobody waiting for one.
Uint8List withBridgeShim(ByteData page, {String? session}) {
  final Uint8List bytes = page.buffer.asUint8List(
    page.offsetInBytes,
    page.lengthInBytes,
  );
  final String html = utf8.decode(bytes);
  final int head = html.indexOf('<head>');

  if (head < 0) {
    return bytes;
  }

  final int at = head + '<head>'.length;
  String served =
      '${html.substring(0, at)}\n<script>$epubBridgeShim</script>'
      '${html.substring(at)}';

  if (session != null) {
    final int body = served.lastIndexOf('</body>');

    if (body >= 0) {
      served =
          '${served.substring(0, body)}'
          '<script>${epubReadyAnnouncement(session)}</script>\n'
          '${served.substring(body)}';
    }
  }

  return Uint8List.fromList(utf8.encode(served));
}

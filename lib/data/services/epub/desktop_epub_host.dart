/// The engine in a CEF texture, which is Linux and only Linux.
///
/// Linux is the one target with no webview a Flutter plugin can embed. GTK's
/// WebKit is not offscreen-renderable in the way an embedder needs, and
/// `flutter_inappwebview`'s Linux implementation is built on WPE WebKit, which
/// neither Ubuntu nor Debian package — `tool/no_wpe_webview` is where that is
/// argued and declined. So this target runs CEF, rendered to a Flutter texture
/// by `webview_cef`.
///
/// **It is the same engine, the same page and the same bridge.** That is the
/// whole claim and it is worth being precise about how it is kept:
///
/// * the *engine* is the pinned asset set `engine.dart` names, served over a
///   loopback socket by `engine_server.dart` because CEF can be given a URL and
///   nothing else;
/// * the *page* is `swipe.html`, loaded from that origin, with its relative
///   script tags resolving exactly as they do under any other host;
/// * the *bridge* is `window.flutter_inappwebview.callHandler`, which the glue
///   calls and which this file shims onto a CEF JavaScript channel — the same
///   shim, in shape, that the package's own browser host installs into its
///   `<iframe>`.
///
/// So the difference between this host and the webview one is what draws the
/// pixels and what carries a string across the process boundary. Nothing above
/// that differs, and in particular no CFI is produced, parsed or altered here.
///
/// **The calls are made by name, into the pinned glue.** The webview host gets
/// those names from the package's Dart controller; this one spells them itself,
/// because there is no controller on this side of the bridge. They are the same
/// names, they are compile-time constants, and they cannot change under this
/// file without `engine_test.dart` going red — the glue is pinned by digest.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart' as cef;

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'engine.dart';
import 'engine_server.dart';
import 'epub_host.dart';
import 'page_input.dart';
import 'page_place.dart';

final _log = loggerFor('data/epub');

/// The operation a failure in this file reports under.
const String opDesktopEpubHost = 'epub/desktop host';

/// One message from the glue, decoded, or `null` where it was not one.
///
/// **Everything crossing this bridge is a string somebody else's JavaScript
/// wrote.** The glue is pinned by digest and is not the worry; what is, is that
/// a page under it can call `window.flutter_inappwebview.callHandler` with
/// anything at all, and that a future version of the glue could answer a shape
/// this file does not expect. `jsonDecode` on such a string throws, and it was
/// throwing out of a platform callback — where there is no `await` above it to
/// catch anything, so it became an unhandled error in the zone rather than a
/// message the host declined to understand.
///
/// It is a function and not a method so that the one part of this file a test
/// can reach without CEF is the part that reads what CEF hands over.
@visibleForTesting
Map<String, Object?>? decodeBridgeMessage(String message) {
  try {
    final Object? decoded = jsonDecode(message);

    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    _log.warning(
      'the epub bridge sent a ${decoded.runtimeType}, not an object',
    );

    return null;
  } on FormatException catch (error) {
    _log.warning('the epub bridge sent something that is not json', error);

    return null;
  }
}

/// The glue's `selection` arguments as the port's selection.
///
/// **The range comes first and the passage second.** Every call site in
/// `epubView.js` is `callHandler('selection', cfiRange, text, rect, xpath)`,
/// and this host read the first two the other way round: a highlight taken on
/// Linux was stored with the CFI where the passage belongs and the passage
/// where the CFI belongs, so the annotations list showed a card reading
/// `epubcfi(/6/8!/4/80,/1:0,/1:108)` and the mark it named could never be
/// found on the page again. The five webview targets receive the same two
/// values already named by the package's own model, which is why this was
/// wrong here and nowhere else.
///
/// It is a function and not a method for the reason [decodeBridgeMessage] is.
@visibleForTesting
EpubSelection? epubSelectionOf(List<Object?> args) {
  if (args.length < 2) {
    return null;
  }

  final Object? cfi = args[0];
  final Object? text = args[1];

  return cfi is String && text is String
      ? EpubSelection(cfiRange: cfi, text: text)
      : null;
}

/// The engine, hosted by CEF and rendered to a Flutter texture.
final class DesktopEpubHost implements EpubHost {
  /// A host for one book on one screen.
  DesktopEpubHost();

  final StreamController<EpubPosition> _positions =
      StreamController<EpubPosition>.broadcast();
  final StreamController<EpubSelection> _selections =
      StreamController<EpubSelection>.broadcast();
  final StreamController<EpubPageEvent> _pageEvents =
      StreamController<EpubPageEvent>.broadcast();
  final ValueNotifier<cef.WebViewController?> _webview =
      ValueNotifier<cef.WebViewController?>(null);

  final Map<int, Completer<Object?>> _pending = <int, Completer<Object?>>{};
  int _nextRequest = 1;

  /// Completed when the glue has announced itself, which is after the view has
  /// been built and CEF has loaded the page.
  ///
  /// It exists from construction and not from the view's `initState`, so that
  /// an `open()` which arrives before the view is mounted waits for it rather
  /// than finding nothing to wait on and refusing at once. The screen mounts
  /// the view from its first frame, and this is what makes the host not depend
  /// on that ordering.
  final Completer<void> _ready = Completer<void>();
  Completer<void>? _opened;
  Completer<List<EpubChapter>>? _chapters;
  EpubBook? _book;

  /// The URL the book was offered at, so a host that is closed before the page
  /// fetched it can take the offer back.
  String? _offered;

  /// The page this host was given, so a screen closed before that page loaded
  /// does not leave the server holding an announcement nobody will make.
  EngineSession? _session;

  /// Whether a book has been handed to the engine.
  bool _sent = false;

  String? _initialCfi;

  EpubStyle _style = const EpubStyle();
  Brightness _brightness = Brightness.light;
  bool _disposed = false;

  @override
  Widget view() => _DesktopEpubView(host: this);

  @override
  Future<void> open(EpubBook book, {String? at}) async {
    _refuseIfDisposed();

    // Refused here rather than handed to the engine, for the reason the webview
    // host gives: a position replicated from a device reading another format is
    // a legitimate row and a meaningless instruction, and opening at the
    // beginning is the right answer rather than an error.
    _initialCfi = at != null && EpubEngine.looksLikeCfi(at) ? at : null;

    if (at != null && _initialCfi == null) {
      _log.fine('$at is not a CFI; opening ${book.ebookId} at the beginning');
    }

    _book = book;
    _sent = false;
    final Completer<void> opened = Completer<void>();
    _opened = opened;
    _chapters = Completer<List<EpubChapter>>();

    // The page is loaded once per host and the book is handed to it over the
    // bridge, rather than the page being reloaded per book. It is what the
    // other host does — a webview whose source changed under it — and it is
    // also what keeps the engine's own state, its location index included, from
    // being rebuilt for a reader who went back to a book they had open.
    //
    // The wait for the page is under the same deadline as the wait for the
    // book: a view that is never mounted, or a CEF that never comes up, is a
    // book that did not open and not a future nobody completes.
    await _ready.future.timeout(epubOpenTimeout, onTimeout: _openTimedOut);
    await _sendBook();

    return opened.future.timeout(epubOpenTimeout, onTimeout: _openTimedOut);
  }

  Never _openTimedOut() => throw AppException(
    kind: ErrorKind.deadlineExceeded,
    message: 'the book did not open within ${epubOpenTimeout.inSeconds}s',
    code: codeEpubOpenTimeout,
    op: opDesktopEpubHost,
  );

  @override
  Stream<EpubPosition> get positions => _positions.stream;

  @override
  Stream<EpubSelection> get selections => _selections.stream;

  @override
  Stream<EpubPageEvent> get pageEvents => _pageEvents.stream;

  @override
  Future<List<EpubChapter>> chapters() {
    final Completer<List<EpubChapter>>? pending = _chapters;

    if (pending == null) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'no book is open',
        code: 'epub_not_open',
        op: opDesktopEpubHost,
      );
    }

    return pending.future.timeout(
      epubOpenTimeout,
      onTimeout: () => const <EpubChapter>[],
    );
  }

  @override
  Future<void> goTo(String locator) => _call(EpubGlue.goTo, <Object?>[locator]);

  @override
  Future<void> nextPage() => _call(EpubGlue.next);

  @override
  Future<void> previousPage() => _call(EpubGlue.previous);

  @override
  Future<void> draw(EpubMark mark) => mark.underline
      ? _call(EpubGlue.addUnderline, <Object?>[mark.cfiRange])
      : _call(EpubGlue.addHighlight, <Object?>[
          mark.cfiRange,
          cssColor(mark.color),
          '${mark.opacity}',
        ]);

  @override
  Future<void> erase(String cfiRange, {bool underline = false}) => _call(
    underline ? EpubGlue.removeUnderline : EpubGlue.removeHighlight,
    <Object?>[cfiRange],
  );

  @override
  Future<String> textOf(String cfiRange) async {
    // The same glue function the webview host reaches, for the same reason: it
    // takes a range, and splitting a range into its two ends would be parsing a
    // CFI in Dart.
    final Object? result = await _request(EpubGlue.extractText, <Object?>[
      cfiRange,
    ]);

    if (result is Map && result['text'] is String) {
      return result['text'] as String;
    }

    throw AppException(
      kind: ErrorKind.notFound,
      message: 'the passage at $cfiRange is not in this book',
      code: 'epub_range_not_found',
      op: opDesktopEpubHost,
    );
  }

  @override
  Future<void> apply(EpubStyle style) async {
    _style = style;

    if (_disposed || _webview.value == null || !_sent) {
      return;
    }

    await _applyToEngine();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    for (final Completer<Object?> pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(
          const AppException(
            kind: ErrorKind.canceled,
            message: 'the reader was closed while a request was in flight',
            code: 'epub_host_disposed',
            op: opDesktopEpubHost,
          ),
        );
      }
    }

    _pending.clear();

    final String? offered = _offered;
    final EngineSession? session = _session;

    if (offered != null || session != null) {
      // A book nobody fetched and a page that never announced itself — a reader
      // who closed the screen while it was all still coming up — are taken back
      // rather than left on the server for the life of the process.
      final EngineServer server = await EngineServer.shared();

      if (offered != null) {
        server.withdraw(offered);
        _offered = null;
      }

      if (session != null) {
        server.closeSession(session);
        _session = null;
      }
    }

    await _webview.value?.dispose();
    _webview.dispose();
    await _positions.close();
    await _selections.close();
    await _pageEvents.close();
  }

  /// Hands the book to the engine.
  ///
  /// **The page fetches it; nothing splices a book into a script.** The bytes
  /// were base64-encoded, then JSON-encoded, then interpolated into the source
  /// of the call — three transient copies of a whole book, each larger than the
  /// file, beside the one the view model already holds. They are offered on the
  /// loopback socket that is already serving the engine instead, at a path that
  /// answers once, and what crosses the bridge is a URL.
  ///
  /// **The engine is untouched.** It is the same glue function, called by the
  /// same name with the same options: `loadBook` takes a byte array as it is
  /// and normalizes a string to one, so this is an argument it already
  /// accepted. What changed is how this host gets a book to it.
  Future<void> _sendBook() async {
    final EpubBook? book = _book;

    if (book == null) {
      return;
    }

    final EngineServer server = await EngineServer.shared();
    final String url = server.offer(book.bytes);

    _offered = url;
    _sent = true;
    // Dropped here: the engine has been told where to find it, and a book kept
    // in this object for nothing is what this whole change is about.
    _book = null;

    final EpubPalette palette = epubPaletteOf(_style.theme, _brightness);
    final Map<String, Object?> options = <String, Object?>{
      'cfi': _initialCfi ?? '',
      'manager': 'continuous',
      'flow': 'paginated',
      'spread': _style.spread == EpubSpread.none ? 'none' : 'auto',
      'snap': true,
      // False here for the reason it is false in the other host: a reader's
      // library holds files they were given, and a book whose scripts run is
      // a book running code inside this application.
      'allowScriptedContent': false,
      'direction': 'ltr',
      'useCustomSwipe': false,
      'backgroundColor': '',
      'foregroundColor': '',
      'fontSize': (epubBaseFontSizePx * _style.fontSize / 100).round(),
      'clearSelectionOnPageChange': true,
      'selectAnnotationRange': false,
      'customCss': _css(palette),
      // The selection-polling fallbacks are for iOS's iframes. CEF fires
      // `selectionchange` like any other Chromium, and polling it would be
      // work done on every frame to answer a question the browser answers.
      'usePolling': false,
    };

    await _evaluate('''
        fetch(${jsonEncode(url)})
          .then(function (response) { return response.arrayBuffer(); })
          .then(function (bytes) {
            ${EpubGlue.loadBook}(new Uint8Array(bytes), ${jsonEncode(options)});
          })
          .catch(function (error) {
            $epubBridgeChannel({
              handler: 'displayError',
              args: [String(error)]
            });
          });
      ''');
  }

  Future<void> _applyToEngine() async {
    await _call(EpubGlue.setFontSize, <Object?>[
      epubBaseFontSizePx * _style.fontSize / 100,
    ]);
    await _call(EpubGlue.setSpread, <Object?>[
      _style.spread == EpubSpread.none ? 'none' : 'auto',
    ]);
    await _call(EpubGlue.updateTheme, <Object?>[
      '',
      '',
      _css(epubPaletteOf(_style.theme, _brightness)),
    ]);
  }

  /// The rule set the page is styled with.
  ///
  /// One `body` rule carrying everything, colours included, for the reason the
  /// webview host builds it the same way: the glue assigns custom CSS over the
  /// rules it built from the colour arguments, so a `body` rule split between
  /// the two loses whichever was written first. The two hosts share the
  /// arrangement because they share the glue.
  Map<String, Object?> _css(EpubPalette palette) => <String, Object?>{
    'body': <String, String>{
      'color': cssColor(palette.foreground),
      'background': 'transparent',
      'line-height': '${_style.lineHeight}',
      'padding-left': '${_style.marginPercent}%',
      'padding-right': '${_style.marginPercent}%',
      if (_style.fontFamily != null) 'font-family': _style.fontFamily!,
    },
    'a': <String, String>{'color': cssColor(palette.link)},
  };

  /// Calls a glue function and does not wait for an answer.
  Future<void> _call(String name, [List<Object?> args = const <Object?>[]]) =>
      _evaluate('$name(${_arguments(args)});');

  /// Runs [source] in the page, or refuses because there is no page.
  ///
  /// Both kinds of call go through it, and that is the fix rather than the
  /// tidying it looks like: the request path used to send through a helper that
  /// did nothing at all when the webview was null, so a `textOf` before the
  /// page existed waited the full thirty seconds for a reply nobody was ever
  /// going to send, where the same state refused a page turn at once.
  Future<void> _evaluate(String source) {
    _refuseIfDisposed();

    final cef.WebViewController? webview = _webview.value;

    if (webview == null) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'the reader is not ready',
        code: 'epub_not_ready',
        op: opDesktopEpubHost,
      );
    }

    return webview.executeJavaScript(source);
  }

  /// Calls a glue function and waits for what it answers.
  ///
  /// CEF's `evaluateJavascript` returns what an expression evaluates to and a
  /// promise is not its value, so a function that answers asynchronously — and
  /// every interesting one does — has to reply over the bridge instead. The
  /// request carries an identifier and the reply carries it back, which is the
  /// same shape the package's own bridge uses on the other five targets.
  Future<Object?> _request(
    String name, [
    List<Object?> args = const <Object?>[],
  ]) {
    _refuseIfDisposed();

    final int id = _nextRequest++;
    final Completer<Object?> reply = Completer<Object?>();

    // Sent before the completer is registered, so that a refusal — no page yet,
    // a host that has been closed — leaves nothing behind in the map waiting
    // for an answer that was never asked for.
    final Future<void> sent = _evaluate('''
        Promise.resolve($name(${_arguments(args)})).then(
          function (value) {
            $epubBridgeChannel({ reply: $id, value: value });
          },
          function (error) {
            $epubBridgeChannel({ reply: $id, error: String(error) });
          }
        );
      ''');

    _pending[id] = reply;
    unawaited(sent);

    return reply.future.timeout(
      epubOpenTimeout,
      onTimeout: () {
        _pending.remove(id);

        throw AppException(
          kind: ErrorKind.deadlineExceeded,
          message: '$name did not answer',
          code: 'epub_request_timeout',
          op: opDesktopEpubHost,
        );
      },
    );
  }

  /// The arguments as a JavaScript argument list.
  ///
  /// Every value is JSON, which is what makes an argument safe where the
  /// function name is not: a book's title carrying a quotation mark is a value
  /// and not code. The names are compile-time constants in this file for
  /// exactly that reason.
  static String _arguments(List<Object?> args) =>
      args.map(jsonEncode).join(', ');

  /// One message from the glue, or one reply to a request.
  void _onMessage(cef.JavascriptMessage message) {
    final Map<String, Object?>? decoded = decodeBridgeMessage(message.message);

    if (decoded == null) {
      return;
    }

    final Object? reply = decoded['reply'];

    if (reply is int) {
      final Completer<Object?>? pending = _pending.remove(reply);

      if (pending != null && !pending.isCompleted) {
        final Object? error = decoded['error'];

        if (error != null) {
          pending.completeError(
            AppException(
              kind: ErrorKind.internal,
              message: 'the engine answered with an error: $error',
              code: 'epub_engine_error',
              op: opDesktopEpubHost,
            ),
          );
        } else {
          pending.complete(decoded['value']);
        }
      }

      return;
    }

    // Read rather than cast. A handler that is not a string and arguments that
    // are not a list are a message this host does not understand, and `as`
    // would make that a crash instead of a shrug.
    final Object? handler = decoded['handler'];
    final Object? args = decoded['args'];

    if (handler is! String) {
      _log.warning('the epub bridge sent a message naming no handler');

      return;
    }

    _onHandler(handler, args is List<Object?> ? args : const <Object?>[]);
  }

  /// One `callHandler` from the glue.
  ///
  /// The names are the package's own, because the glue is the package's own.
  /// Only the ones this port needs are answered; the rest — the touch and
  /// selection-lifecycle notifications the mobile hosts use to place a context
  /// menu — reach here and are ignored, which is the same thing the browser
  /// host does with the ones it has no use for.
  void _onHandler(String handler, List<Object?> args) {
    switch (handler) {
      case 'readyToLoad':
        if (!_ready.isCompleted) {
          _ready.complete();
        }
      case 'rendered':
        if (_opened?.isCompleted == false) {
          _opened!.complete();
        }
        unawaited(_applyToEngine());
        unawaited(_watchPageInput());
      case 'chapters':
        unawaited(_onChapters());
      case 'relocated':
        _onRelocated(args.isEmpty ? null : args.first);
      case 'locationLoaded':
        unawaited(_reread());
      case 'selection':
        _onSelection(args);
      case 'displayError':
        _failOpening();
      case pageTapHandler:
        if (!_pageEvents.isClosed) {
          _pageEvents.add(EpubPageEvent.tapped);
        }
      case pageKeyHandler:
        _onPageKey(args);
      case pagePlaceHandler:
        _onPlace(args.isEmpty ? null : args.first);
      default:
        break;
    }
  }

  /// Makes the page report a tap on it.
  ///
  /// **Keys are not forwarded here, and that is the difference between this
  /// host and the other one.** The engine is a CEF texture inside the Flutter
  /// tree on this target, so `webview_cef` takes the pointer but the key event
  /// reaches Flutter first and the reader's screen already binds it — a page
  /// that also reported it would turn two pages for one press. On the five
  /// webview targets Flutter receives no key at all once the page has focus,
  /// which is what [pageInputScript] is for there.
  ///
  /// It is injected after the book has rendered rather than with the bridge
  /// shim at load start, because the script registers a hook on `rendition` and
  /// there is no rendition until a book has been handed over. Injecting it
  /// again on a second book is free: the script returns at its first line.
  ///
  /// The channel it reports on is this host's own, so there is nothing to
  /// register — [_onHandler] already answers every message the page sends.
  Future<void> _watchPageInput() async {
    final cef.WebViewController? webview = _webview.value;

    if (webview == null || _disposed) {
      return;
    }

    try {
      await webview.executeJavaScript(pageInputScript(withKeys: false));
      await webview.executeJavaScript(pagePlaceScript());
    } on Object catch (error) {
      // Not fatal and not shown, for the reason the webview host gives: the
      // book is readable and the chrome's controls all work, and what is lost
      // is one gesture.
      _log.warning('the page could not be asked to report input', error);
    }
  }

  void _onPageKey(List<Object?> args) {
    if (_pageEvents.isClosed || args.isEmpty) {
      return;
    }

    final Object? key = args.first;

    if (key is! String) {
      return;
    }

    final EpubPageEvent? event = epubPageEventOfKey(key);

    if (event != null) {
      _pageEvents.add(event);
    }
  }

  /// Reads the contents, now that the engine says it has parsed one.
  ///
  /// **The notification carries nothing.** `epubView.js` parses the navigation
  /// document, keeps the list in the page, and announces `chapters` with an
  /// empty argument list; the list itself is fetched with [EpubGlue.chapters].
  /// This host used to read the notification's arguments, find none, and
  /// complete every book with an empty contents — which is a contents sheet
  /// that says the book has none, on Linux and on Linux alone, because the
  /// other five targets go through the package's own handler and it asks.
  ///
  /// A request that fails answers empty rather than leaving the sheet waiting
  /// out the timeout: the reader is looking at the book either way, and what
  /// is lost is a list this host could not get.
  Future<void> _onChapters() async {
    final Completer<List<EpubChapter>>? pending = _chapters;

    if (pending == null || pending.isCompleted) {
      return;
    }

    Object? raw;

    try {
      raw = await _request(EpubGlue.chapters);
    } on Object catch (error) {
      _log.warning('the engine would not say what the contents is', error);
    }

    if (pending.isCompleted) {
      return;
    }

    pending.complete(
      raw is List<Object?>
          ? raw
                .whereType<Map<Object?, Object?>>()
                .map(_chapterOf)
                .toList(growable: false)
          : const <EpubChapter>[],
    );
  }

  /// One entry of the contents, as the glue serialized it.
  ///
  /// It is rebuilt through the package's own type rather than into the port's
  /// directly, so that the two hosts read the same shape through the same
  /// mapping and a change to one is a change to both.
  EpubChapter _chapterOf(Map<Object?, Object?> raw) => EpubChapter(
    title: raw['title'] as String? ?? '',
    href: raw['href'] as String? ?? '',
    children: (raw['subitems'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(_chapterOf)
        .toList(growable: false),
  );

  /// Asks the engine where the reader is, now that it can say how far in.
  ///
  /// **The engine announces its location index and nothing here used to
  /// listen.** Building that index means parsing every section of the book —
  /// over two minutes for a work of a thousand of them — and until it exists
  /// the percentage in every position report is absent. The page does not move
  /// when the index lands, so no further report is coming: without this the
  /// reader's progress stays unknown until they happen to turn a page, and a
  /// reader who stopped to read one is left looking at a bar that never fills.
  ///
  /// It re-reads rather than patching the last position, because the two
  /// numbers in a report belong together: `getCurrentLocation` answers with the
  /// page's edges and its percentage from one reading, exactly as `relocated`
  /// does, and this host maps both through the same function.
  ///
  /// A failure is a line in the log. The book is on screen, the reader is
  /// reading it, and what is lost is a number that was already missing.
  Future<void> _reread() async {
    try {
      _onRelocated(await _request(EpubGlue.currentLocation));
    } on Object catch (error) {
      _log.warning('the engine would not say where the reader is', error);
    }
  }

  /// The page's place in the spine, as the injected reporter last said.
  ///
  /// Held rather than asked for, because it arrives with the relocation it
  /// describes: the reporter is registered synchronously on the engine's own
  /// event and the glue's handler waits on two promises before it sends, so
  /// this is already the current page's by the time the position lands.
  double? _estimate;

  void _onPlace(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return;
    }

    final Object? index = raw['index'];
    final Object? spine = raw['spine'];

    if (index is! num || spine is! num) {
      return;
    }

    _estimate = epubSpinePercentOf(
      index: index.toInt(),
      spine: spine.toInt(),
    );
  }

  void _onRelocated(Object? raw) {
    if (raw is! Map<Object?, Object?> || _positions.isClosed) {
      return;
    }

    final Object? start = raw['startCfi'];
    final Object? end = raw['endCfi'];

    if (start is! String || end is! String) {
      return;
    }

    // A progress that is not a number is a page whose location index has not
    // finished generating, reported as `null` or as a string by a glue this
    // file does not get to choose. Neither is that number nor the zero the
    // engine reports in the same state a percentage, and `epubPercentOf` is
    // where the two hosts agree on saying so.
    _positions.add(
      EpubPosition(
        startCfi: start,
        endCfi: end,
        // The engine's own answer whenever it has one, and the spine's when it
        // does not. `page_place.dart` argues the estimate and why it loses.
        percent: epubPercentOf(raw['progress']) ?? _estimate,
      ),
    );
  }

  void _onSelection(List<Object?> args) {
    final EpubSelection? selected = epubSelectionOf(args);

    if (selected != null && !_selections.isClosed) {
      _selections.add(selected);
    }
  }

  void _failOpening() {
    final Completer<void>? pending = _opened;

    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        const AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the engine could not display this book',
          code: codeEpubDisplayFailed,
          op: opDesktopEpubHost,
        ),
      );
    }
  }

  void _refuseIfDisposed() {
    if (_disposed) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'the reader has been closed',
        code: 'epub_host_disposed',
        op: opDesktopEpubHost,
      );
    }
  }
}

/// The widget that gives the engine a texture.
class _DesktopEpubView extends StatefulWidget {
  const _DesktopEpubView({required this.host});

  final DesktopEpubHost host;

  @override
  State<_DesktopEpubView> createState() => _DesktopEpubViewState();
}

class _DesktopEpubViewState extends State<_DesktopEpubView> {
  Object? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Brightness brightness = Theme.of(context).brightness;

    if (brightness != widget.host._brightness) {
      widget.host._brightness = brightness;
      unawaited(widget.host.apply(widget.host._style));
    }
  }

  /// Brings up CEF, the engine's server and the bridge, in that order.
  ///
  /// **Everything that touches the document waits for the document.** CEF is
  /// given a URL and navigates to it on its own time: `initialize()` answers a
  /// browser, not a page. So the page is asked to say when it is there — over
  /// the engine's own socket, which needs nothing but the document — and the
  /// two things that have to happen *to* a live page happen after it does.
  /// Both used to be guesses against a fifty-millisecond delay inside the
  /// plugin, and both lost: `setJavaScriptChannels` is an assignment to a
  /// global that the navigation then discarded, and the readiness event was
  /// dispatched before `epubView.js` had registered the listener for it. A
  /// reader saw a blank page and, thirty seconds later, a timeout.
  Future<void> _start() async {
    try {
      // The manager is a singleton and initializing it twice is not an error,
      // but it is a round trip to the platform, so a second reader screen waits
      // on the first rather than asking again.
      final cef.WebviewManager manager = cef.WebviewManager();
      await manager.initialize();

      final EngineServer server = await EngineServer.shared();
      final EngineSession session = server.openSession();

      widget.host._session = session;

      final cef.WebViewController webview = manager.createWebView(
        injectUserScripts: cef.InjectUserScripts()
          ..add(
            cef.UserScript(epubBridgeShim, cef.ScriptInjectTime.LOAD_START),
          ),
      );

      await webview.initialize(session.pageUrl);

      // The page, saying so itself. Nothing below this line would reach the
      // document that is going to render the book without it.
      await session.loaded;

      // Installed now rather than above, because the plugin installs a channel
      // by assigning a global in whatever context exists when it is asked, and
      // before this the context was the one CEF was about to navigate away
      // from.
      await webview.setJavaScriptChannels(<cef.JavascriptChannel>{
        cef.JavascriptChannel(
          name: epubBridgeChannel,
          onMessageReceived: widget.host._onMessage,
        ),
      });

      if (!mounted) {
        await webview.dispose();
        return;
      }

      // Handed to the host before the glue is woken, and deliberately: the
      // glue answers the event below with `readyToLoad`, which is what lets
      // `open()` send the book, and the send refuses when the host holds no
      // webview yet. Dispatching first would be a race the reader loses on a
      // fast machine.
      widget.host._webview.value = webview;

      // Last: the glue announces itself on this event, and the announcement is
      // what asks for the book. The listener it reaches was registered while
      // the page was loading, which is what the wait above is for.
      await webview.executeJavaScript(
        "window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));",
      );
    } on Object catch (error, trace) {
      _log.severe('the CEF reader could not be started', error, trace);

      if (mounted) {
        setState(() => _failure = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final EpubPalette palette = epubPaletteOf(
      widget.host._style.theme,
      widget.host._brightness,
    );

    if (_failure != null) {
      // The chrome above decides what a reader is told; what this owes it is a
      // ground of the right colour rather than a widget apologizing in English.
      return ColoredBox(color: palette.background);
    }

    return ValueListenableBuilder<cef.WebViewController?>(
      valueListenable: widget.host._webview,
      builder:
          (BuildContext context, cef.WebViewController? webview, Widget? _) =>
              webview == null
              ? ColoredBox(color: palette.background)
              : ColoredBox(
                  color: palette.background,
                  child: cef.WebView(webview),
                ),
    );
  }
}

/// Where a [DesktopEpubHost] comes from.
final class DesktopEpubHostFactory implements EpubHostFactory {
  /// The factory the provider graph holds on Linux.
  const DesktopEpubHostFactory();

  @override
  EpubHost create() => DesktopEpubHost();
}

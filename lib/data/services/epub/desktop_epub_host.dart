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

final _log = loggerFor('data/epub');

/// The operation a failure in this file reports under.
const String opDesktopEpubHost = 'epub/desktop host';

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
/// It is injected at load start so that it exists before the glue runs. The
/// channel function it calls is installed separately and slightly later, which
/// is safe: the reference is resolved inside the call and the first call cannot
/// happen until the readiness event is dispatched, which this file does last.
const String epubBridgeShim =
    '''
(function () {
  if (window.flutter_inappwebview) { return; }
  window.flutter_inappwebview = {
    callHandler: function (name) {
      var args = Array.prototype.slice.call(arguments, 1);
      try {
        $epubBridgeChannel(JSON.stringify({ handler: name, args: args }));
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

/// Every function this host calls inside the pinned glue.
///
/// They are named here rather than written at the call sites because this is
/// the one place in the application that spells the glue's own vocabulary. The
/// webview host does not: it goes through the package's Dart controller, which
/// spells these same names on its side. So a name that is wrong *here* is a
/// call into nothing on Linux and a working call on the other five — a
/// divergence between hosts that no compiler and no other test would catch.
///
/// `locator_round_trip_test.dart` checks every one of them against the glue the
/// bundle actually holds, which is a file pinned by digest. A renamed function
/// upstream is therefore a red build rather than a target that silently stops
/// turning pages.
abstract final class EpubGlue {
  /// Hands the engine a book and the options it is displayed under.
  static const String loadBook = 'loadBook';

  /// Moves to a CFI or a chapter href — the engine tells them apart.
  static const String goTo = 'toCfi';

  /// The next page, and the previous one.
  static const String next = 'next';

  /// As [next], backwards. It is `previous` and not `prev`: the package's
  /// controller method is `prev` and the function it calls is this, which is
  /// exactly the kind of near-miss the check exists for.
  static const String previous = 'previous';

  /// Draws a filled mark over a range, and an underline under one.
  static const String addHighlight = 'addHighlight';

  /// As [addHighlight], underlined. The capital L is the glue's.
  static const String addUnderline = 'addUnderLine';

  /// Removes what the two above draw.
  static const String removeHighlight = 'removeHighlight';

  /// As [removeHighlight], for an underline.
  static const String removeUnderline = 'removeUnderLine';

  /// Sets the root type size, in CSS pixels.
  static const String setFontSize = 'setFontSize';

  /// One page or two.
  static const String setSpread = 'setSpread';

  /// The colours and the custom rules the page is styled with.
  static const String updateTheme = 'updateTheme';

  /// The text a CFI range covers.
  ///
  /// It is the glue's internal helper and not its public `getTextFromCfi`,
  /// which takes two end CFIs and builds the range itself. What an annotation
  /// stores is the range, already built, and splitting one back into its ends
  /// would be parsing a CFI in Dart.
  static const String extractText = '_extractText';

  /// All of them, for the check that they exist.
  static const Set<String> all = <String>{
    loadBook,
    goTo,
    next,
    previous,
    addHighlight,
    addUnderline,
    removeHighlight,
    removeUnderline,
    setFontSize,
    setSpread,
    updateTheme,
    extractText,
  };
}

/// The engine, hosted by CEF and rendered to a Flutter texture.
final class DesktopEpubHost implements EpubHost {
  /// A host for one book on one screen.
  DesktopEpubHost();

  final StreamController<EpubPosition> _positions =
      StreamController<EpubPosition>.broadcast();
  final StreamController<EpubSelection> _selections =
      StreamController<EpubSelection>.broadcast();
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

    if (_disposed || _webview.value == null || _book == null) {
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
    await _webview.value?.dispose();
    _webview.dispose();
    await _positions.close();
    await _selections.close();
  }

  /// Hands the book to the engine.
  ///
  /// The bytes go as base64 for the reason the package's native path uses it: a
  /// decimal array literal spliced into a script is roughly three times the
  /// size, and this crosses a process boundary. The glue accepts either and
  /// calls `atob` on a string.
  Future<void> _sendBook() async {
    final EpubBook? book = _book;

    if (book == null) {
      return;
    }

    final EpubPalette palette = epubPaletteOf(_style.theme, _brightness);

    await _call(EpubGlue.loadBook, <Object?>[
      base64.encode(book.bytes),
      <String, Object?>{
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
      },
    ]);
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
  Future<void> _call(String name, [List<Object?> args = const <Object?>[]]) {
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

    return webview.executeJavaScript('$name(${_arguments(args)});');
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
    _pending[id] = reply;

    unawaited(
      _call2('''
        Promise.resolve($name(${_arguments(args)})).then(
          function (value) {
            $epubBridgeChannel(JSON.stringify({ reply: $id, value: value }));
          },
          function (error) {
            $epubBridgeChannel(JSON.stringify({ reply: $id, error: String(error) }));
          }
        );
      '''),
    );

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

  Future<void> _call2(String source) async {
    await _webview.value?.executeJavaScript(source);
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
    final Object? decoded = jsonDecode(message.message);

    if (decoded is! Map<String, Object?>) {
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

    _onHandler(
      decoded['handler'] as String? ?? '',
      decoded['args'] as List<Object?>? ?? const <Object?>[],
    );
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
      case 'chapters':
        _onChapters(args.isEmpty ? const <Object?>[] : args.first);
      case 'relocated':
        _onRelocated(args.isEmpty ? null : args.first);
      case 'selection':
        _onSelection(args);
      case 'displayError':
        _failOpening();
      default:
        break;
    }
  }

  void _onChapters(Object? raw) {
    final Completer<List<EpubChapter>>? pending = _chapters;

    if (pending == null || pending.isCompleted || raw is! List<Object?>) {
      return;
    }

    pending.complete(
      raw
          .whereType<Map<Object?, Object?>>()
          .map(_chapterOf)
          .toList(growable: false),
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

  void _onRelocated(Object? raw) {
    if (raw is! Map<Object?, Object?> || _positions.isClosed) {
      return;
    }

    final Object? start = raw['startCfi'];
    final Object? end = raw['endCfi'];

    if (start is! String || end is! String) {
      return;
    }

    _positions.add(
      EpubPosition(
        startCfi: start,
        endCfi: end,
        percent: ((raw['progress'] as num? ?? 0) * 100)
            .clamp(0, 100)
            .toDouble(),
      ),
    );
  }

  void _onSelection(List<Object?> args) {
    if (args.length < 2 || _selections.isClosed) {
      return;
    }

    final Object? text = args[0];
    final Object? cfi = args[1];

    if (text is String && cfi is String) {
      _selections.add(EpubSelection(cfiRange: cfi, text: text));
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
  Future<void> _start() async {
    try {
      // The manager is a singleton and initializing it twice is not an error,
      // but it is a round trip to the platform, so a second reader screen waits
      // on the first rather than asking again.
      final cef.WebviewManager manager = cef.WebviewManager();
      await manager.initialize();

      final EngineServer server = await EngineServer.shared();
      final cef.WebViewController webview = manager.createWebView(
        injectUserScripts: cef.InjectUserScripts()
          ..add(
            cef.UserScript(epubBridgeShim, cef.ScriptInjectTime.LOAD_START),
          ),
      );

      await webview.initialize(server.hostPageUrl);
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
      // what asks for the book. Dispatching it before the channel existed would
      // be a `readyToLoad` nobody heard.
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

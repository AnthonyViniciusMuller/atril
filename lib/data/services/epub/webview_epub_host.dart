/// The engine in a webview, which is five of the six targets.
///
/// `flutter_epub_viewer` carries the engine on Android, iOS, macOS and Windows
/// through `flutter_inappwebview`, and in a browser through a same-origin
/// `<iframe>` driven over `dart:js_interop`. **That is one implementation of
/// [EpubHost] and not two**, and the roadmap carried it as two commits on the
/// assumption that the web path needed writing. It needed checking: the package
/// splits internally on `dart.library.io` and both branches answer the same
/// `EpubWebViewController`, so a second class over it would have the same body.
///
/// Windows is among the four native targets and not on CEF, because the
/// package selects its native path on the *library* rather than on a platform
/// list — so a target `flutter_inappwebview` supports is a target this file
/// reaches with nothing written for it.
///
/// **What this file is, is a mapping.** The package already exposes a CFI for
/// the position, for navigation, for a highlight and for extracting a range;
/// none of that is re-implemented here and none of it could be. What is here is
/// the translation between that vocabulary and the port's, and the places the
/// translation is not mechanical are commented where they happen.
///
/// The calls out go by name into the pinned glue rather than through
/// `EpubController`'s methods, which is the one place this file departs from
/// the package's Dart API and is argued at [WebviewEpubHost._call]: those
/// methods drop the future the bridge answers with, and a refusal that nothing
/// can catch is a crash rather than a mark that did not draw. It is the same
/// thing the Linux host does, through [EpubGlue], for the same names.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as fev;

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'engine.dart';
import 'epub_host.dart';
import 'page_input.dart';

final _log = loggerFor('data/epub');

/// The operation a failure in this file reports under.
const String opEpubHost = 'epub/webview host';

/// The engine, hosted by whichever webview this platform has.
final class WebviewEpubHost implements EpubHost {
  /// A host for one book on one screen.
  WebviewEpubHost();

  final fev.EpubController _controller = fev.EpubController();

  final StreamController<EpubPosition> _positions =
      StreamController<EpubPosition>.broadcast();
  final StreamController<EpubSelection> _selections =
      StreamController<EpubSelection>.broadcast();
  final StreamController<EpubPageEvent> _pageEvents =
      StreamController<EpubPageEvent>.broadcast();

  /// What the view is currently asked to render, or `null` before the first
  /// [open].
  ///
  /// It is a [ValueNotifier] because `EpubViewer` takes its source as a widget
  /// property and reads it when it is built: opening a book is therefore a
  /// rebuild, not a call, and this is what the view listens to.
  final ValueNotifier<_Rendering?> _rendering = ValueNotifier<_Rendering?>(
    null,
  );

  Completer<void>? _opened;
  Completer<List<EpubChapter>>? _chapters;

  EpubStyle _style = const EpubStyle();
  Brightness _brightness = Brightness.light;
  bool _disposed = false;

  @override
  Widget view() => _WebviewEpubView(host: this);

  @override
  Future<void> open(EpubBook book, {String? at}) {
    _refuseIfDisposed();

    // A locator this host cannot resolve is refused *here*, where the failure
    // can say so, rather than handed to the engine to fail somewhere inside
    // itself. It is the one place `looksLikeCfi` earns its keep: a position
    // replicated from a device that was reading a different format is a
    // legitimate row and a meaningless instruction.
    //
    // It is not an error, though. Opening at the beginning is what a reader
    // who has never opened this book gets, and it is the right answer for one
    // whose bookmark this build cannot use.
    final String? start = at != null && EpubEngine.looksLikeCfi(at) ? at : null;

    if (at != null && start == null) {
      _log.fine('$at is not a CFI; opening ${book.ebookId} at the beginning');
    }

    final Completer<void> opened = Completer<void>();
    _opened = opened;
    _chapters = Completer<List<EpubChapter>>();
    _rendering.value = _Rendering(book: book, initialCfi: start);

    return opened.future.timeout(
      epubOpenTimeout,
      onTimeout: () => throw AppException(
        kind: ErrorKind.deadlineExceeded,
        message: 'the book did not open within ${epubOpenTimeout.inSeconds}s',
        code: codeEpubOpenTimeout,
        op: opEpubHost,
      ),
    );
  }

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
        op: opEpubHost,
      );
    }

    // A book with no navigation document is a book with no contents, and the
    // package answers with an empty list rather than failing — so the timeout
    // here is about a bridge that never replied, not about a book that has
    // nothing to say.
    return pending.future.timeout(
      epubOpenTimeout,
      onTimeout: () => const <EpubChapter>[],
    );
  }

  @override
  Future<void> goTo(String locator) =>
      // Straight through, unchanged. A CFI and a chapter href are told apart by
      // the engine and not here: a caller — or a host — that had to distinguish
      // them would be one parsing a CFI.
      _call(EpubGlue.goTo, <Object?>[locator]);

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

  /// Calls the glue by name, and waits for it.
  ///
  /// **The waiting is the point.** `EpubController`'s own methods hand the
  /// bridge a call and drop the future it answers with, so a refusal from the
  /// engine — a CFI it cannot resolve in the section on screen is the ordinary
  /// one — surfaces as an unhandled asynchronous error rather than as a
  /// rejected future. Nothing can catch that: it arrives long after the call
  /// site returned, in whatever zone the app is running in, and on the web it
  /// takes the page down. Awaiting the same call here makes the refusal a
  /// thrown exception at the point of the mark, where `ReaderViewModel`'s
  /// repaint already catches it and writes the line it means to write — the
  /// book stays on screen and a highlight that would not draw does not banner
  /// the page.
  ///
  /// The names are [EpubGlue]'s, which is where the argument for spelling them
  /// at all is made: the asset is pinned by digest in `engine.dart` and the
  /// package to an exact version in the pubspec, and
  /// `locator_round_trip_test.dart` checks every one of them against the glue
  /// the bundle actually holds — so a rename upstream is a red build rather
  /// than a reader whose highlights quietly stopped drawing.
  Future<Object?> _call(
    String function, [
    List<Object?> args = const <Object?>[],
  ]) {
    _refuseIfDisposed();

    if (_controller.webViewController == null || _rendering.value == null) {
      // No book is rendering, so there is nothing to say it to. It is the
      // refusal `EpubController.checkEpubLoaded` makes, made here because this
      // file no longer goes through the methods that make it.
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'no book is open',
        code: 'epub_not_open',
        op: opEpubHost,
      );
    }

    return _controller.webViewController!.callAsync(function, args);
  }

  @override
  Future<String> textOf(String cfiRange) async {
    _refuseIfDisposed();

    // The call with no counterpart on the controller at all, even now that the
    // others go by name too. `EpubController.extractText` takes a *start* and
    // an *end* CFI and builds the range itself; what an annotation stores is
    // the range, already built. Splitting one back into its two ends would be
    // parsing a CFI in Dart — the single thing this phase exists to prevent —
    // so the range goes to the glue function that takes a range.
    final Object? result = await _call(EpubGlue.extractText, <Object?>[
      cfiRange,
    ]);

    if (result is Map && result['text'] is String) {
      return result['text'] as String;
    }

    throw AppException(
      kind: ErrorKind.notFound,
      message: 'the passage at $cfiRange is not in this book',
      code: 'epub_range_not_found',
      op: opEpubHost,
    );
  }

  @override
  Future<void> apply(EpubStyle style) async {
    _style = style;

    if (_disposed || _rendering.value == null) {
      // Nothing is rendering yet, so the style is held and applied by the view
      // when it builds. A reader who changed the type size and then opened a
      // book should get the size they chose on the first page, not the second.
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
    _rendering.dispose();
    await _positions.close();
    await _selections.close();
    await _pageEvents.close();
  }

  /// The style as the engine is told it, with [EpubTheme.followSystem]
  /// resolved.
  ///
  /// The resolution happens where there is a `BuildContext` and the answer is
  /// remembered here, so that a reader who changes their device to dark while
  /// the book is open gets a dark page without touching the setting.
  Future<void> _applyToEngine() async {
    await _controller.setFontSize(
      fontSize: epubBaseFontSizePx * _style.fontSize / 100,
    );
    await _controller.setSpread(spread: epubSpreadOf(_style.spread));
    await _controller.updateTheme(theme: _theme());
  }

  /// Makes the page report what the reader does on it.
  ///
  /// **Both halves are needed and the order between them matters.** The
  /// handlers are what the bridge dispatches a message to — an unregistered
  /// name is dropped on both branches of the package — and the script is what
  /// sends one, so registering after injecting would lose whatever the reader
  /// did in between.
  ///
  /// The script is evaluated rather than served, because on these five targets
  /// the document is the package's own asset and not a file this app writes.
  /// `eval` is reached through the controller's `callMethod`, which is a
  /// property lookup on the frame's window in a browser and an interpolated
  /// call on the four native targets — the same door for all five, and the
  /// package's own documented one. It costs `unsafe-eval` to any future
  /// Content-Security-Policy on the web target, which is the trade and is worth
  /// naming: nothing here is fetched, the script is a compile-time constant of
  /// this application, and the alternative was reaching into another package's
  /// `<iframe>` through the DOM on one target and not the others.
  ///
  /// Keys are forwarded here and not on Linux, for the reason
  /// [pageInputScript] gives: a texture inside the Flutter tree gets them
  /// twice, a webview gets them not at all.
  Future<void> _watchPageInput() async {
    // The type is inferred rather than written: `EpubWebViewController` is the
    // package's own interface and is not among the names its library exports,
    // so naming it would mean importing a `src/` path.
    final webview = _controller.webViewController;

    if (webview == null || _disposed) {
      return;
    }

    webview.addHandler(pageTapHandler, (List<dynamic> _) => _onPageTap());
    webview.addHandler(pageKeyHandler, _onPageKey);

    try {
      await webview.callMethod('eval', <Object?>[
        pageInputScript(withKeys: true),
      ]);
    } on Object catch (error) {
      // Not fatal and not shown. The book is on screen and every control in
      // the chrome still works; what is lost is the tap and the keyboard, and
      // a banner across a page the reader can still read would be worse than
      // the line this writes.
      _log.warning('the page could not be asked to report input', error);
    }
  }

  void _onPageTap() {
    if (!_pageEvents.isClosed) {
      _pageEvents.add(EpubPageEvent.tapped);
    }
  }

  void _onPageKey(List<dynamic> args) {
    if (_pageEvents.isClosed || args.isEmpty) {
      return;
    }

    // Read rather than cast, for the reason the Linux host gives about its own
    // bridge: a key that is not a string is a message this host does not
    // understand, and `as` would make that a crash instead of a shrug.
    final Object? key = args.first;

    if (key is! String) {
      return;
    }

    final EpubPageEvent? event = epubPageEventOfKey(key);

    if (event != null) {
      _pageEvents.add(event);
    }
  }

  /// The engine's theme for the current style.
  ///
  /// Everything goes through `customCss` and nothing through the package's
  /// `foregroundColor`, and that is not a preference. The glue builds its rule
  /// set from the colours first and then `Object.assign`s the custom CSS over
  /// it — so a custom `body` rule, which is where line height and the family
  /// belong, would silently drop the colour that had been set separately. One
  /// source for the whole `body` rule is the only arrangement with no order
  /// dependence in it.
  fev.EpubTheme _theme() {
    final EpubPalette palette = epubPaletteOf(_style.theme, _brightness);

    return fev.EpubTheme.custom(
      // The page's ground is painted by the Flutter container behind the
      // webview rather than by the book, because the package renders with a
      // transparent background — so a body rule alone would leave the margins
      // showing whatever was underneath.
      backgroundDecoration: BoxDecoration(color: palette.background),
      customCss: <String, dynamic>{
        'body': <String, String>{
          'color': cssColor(palette.foreground),
          'background': 'transparent',
          'line-height': '${_style.lineHeight}',
          'padding-left': '${_style.marginPercent}%',
          'padding-right': '${_style.marginPercent}%',
          if (_style.fontFamily != null) 'font-family': _style.fontFamily!,
        },
        // Links keep their own colour rather than inheriting the body's, which
        // would make a footnote marker invisible in a dark theme.
        'a': <String, String>{'color': cssColor(palette.link)},
      },
    );
  }

  void _refuseIfDisposed() {
    if (_disposed) {
      throw const AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'the reader has been closed',
        code: 'epub_host_disposed',
        op: opEpubHost,
      );
    }
  }

  void _onRelocated(fev.EpubLocation location) {
    if (_positions.isClosed) {
      return;
    }

    _positions.add(epubPositionOf(location));
  }

  void _onSelected(fev.EpubTextSelection selection) {
    if (_selections.isClosed) {
      return;
    }

    _selections.add(
      EpubSelection(
        cfiRange: selection.selectionCfi,
        text: selection.selectedText,
      ),
    );
  }

  void _onChapters(List<fev.EpubChapter> chapters) {
    final Completer<List<EpubChapter>>? pending = _chapters;

    if (pending != null && !pending.isCompleted) {
      pending.complete(chapters.map(epubChapterOf).toList(growable: false));
    }
  }

  void _onLoaded() {
    final Completer<void>? pending = _opened;

    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }

    // The page cannot report a tap or a key until something is listening for
    // one, so the handlers go on before the script that calls them.
    unawaited(_watchPageInput());

    // The style the reader chose is applied after the book is on screen and
    // not through the initial display settings, because those carry a type
    // size and none of the rest — the leading, the margins and the family are
    // CSS the engine only accepts once there is a rendition to accept it.
    unawaited(_applyToEngine());
  }
}

/// What the view is asked to render.
final class _Rendering {
  const _Rendering({required this.book, this.initialCfi});

  final EpubBook book;
  final String? initialCfi;
}

/// The package's location as the port's position.
///
/// The engine reports progress from 0 to 1 and `progress.percent` is
/// constrained to 0..100 on both sides of the federation, so the conversion
/// happens once, here, rather than at each place a percentage is written down.
/// The clamp is not defensive tidiness: a book whose location index has not
/// finished generating reports a progress of 0, and one asked about a page
/// past the end of a short spine has been seen to report slightly over 1.
@visibleForTesting
EpubPosition epubPositionOf(fev.EpubLocation location) => EpubPosition(
  startCfi: location.startCfi,
  endCfi: location.endCfi,
  percent: (location.progress * 100).clamp(0, 100).toDouble(),
);

/// The package's spread for the port's.
@visibleForTesting
fev.EpubSpread epubSpreadOf(EpubSpread spread) => switch (spread) {
  EpubSpread.none => fev.EpubSpread.none,
  EpubSpread.auto => fev.EpubSpread.auto,
};

/// The package's chapter as the port's, with its children.
@visibleForTesting
EpubChapter epubChapterOf(fev.EpubChapter chapter) => EpubChapter(
  title: chapter.title,
  href: chapter.href,
  children: chapter.subitems.map(epubChapterOf).toList(growable: false),
);

/// The widget that gives the engine a DOM.
///
/// It is private because the port is what anything outside this directory
/// holds: a screen that named this type would be a screen that knows which
/// platform it is on.
class _WebviewEpubView extends StatefulWidget {
  const _WebviewEpubView({required this.host});

  final WebviewEpubHost host;

  @override
  State<_WebviewEpubView> createState() => _WebviewEpubViewState();
}

class _WebviewEpubViewState extends State<_WebviewEpubView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // `followSystem` is resolved here because this is where a `BuildContext`
    // exists, and it is re-resolved on every dependency change so that a
    // reader who switches their device to dark while the book is open gets a
    // dark page without opening the settings.
    final Brightness brightness = Theme.of(context).brightness;

    if (brightness != widget.host._brightness) {
      widget.host._brightness = brightness;
      unawaited(widget.host.apply(widget.host._style));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Rendering?>(
      valueListenable: widget.host._rendering,
      builder: (BuildContext context, _Rendering? rendering, Widget? _) {
        final EpubPalette palette = epubPaletteOf(
          widget.host._style.theme,
          widget.host._brightness,
        );

        if (rendering == null) {
          // Nothing has been opened yet. The ground is painted in the reading
          // palette rather than left transparent, so that opening a book in a
          // dark theme does not flash white first.
          return ColoredBox(color: palette.background);
        }

        return fev.EpubViewer(
          // The key is the book, so that opening a second one rebuilds the
          // viewer rather than asking a webview that is already showing
          // something to change its source underneath itself.
          key: ValueKey<String>(rendering.book.ebookId),
          epubController: widget.host._controller,
          epubSource: fev.EpubSource.fromData(rendering.book.bytes),
          initialCfi: rendering.initialCfi,
          displaySettings: fev.EpubDisplaySettings(
            fontSize: (epubBaseFontSizePx * widget.host._style.fontSize / 100)
                .round(),
            spread: epubSpreadOf(widget.host._style.spread),
            flow: fev.EpubFlow.paginated,
            // Left false, and this is a security decision rather than a
            // default nobody changed. A reader's library holds files they were
            // given, and on the web the rendering context is a same-origin
            // iframe — so a book whose scripts ran could reach the host page,
            // and through it this application. Nothing an EPUB does for a
            // reader is worth that.
            allowScriptedContent: false,
            snap: true,
            theme: widget.host._theme(),
          ),
          onEpubLoaded: widget.host._onLoaded,
          onChaptersLoaded: widget.host._onChapters,
          onRelocated: widget.host._onRelocated,
          onTextSelected: widget.host._onSelected,
        );
      },
    );
  }
}

/// Where a [WebviewEpubHost] comes from.
final class WebviewEpubHostFactory implements EpubHostFactory {
  /// The factory the provider graph holds on the five targets this host
  /// reaches.
  const WebviewEpubHostFactory();

  @override
  EpubHost create() => WebviewEpubHost();
}

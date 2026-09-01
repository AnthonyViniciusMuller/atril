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
/// the translation between that vocabulary and the port's, and the two places
/// the translation is not mechanical are commented where they happen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as fev;

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'engine.dart';
import 'epub_host.dart';

final _log = loggerFor('data/epub');

/// The operation a failure in this file reports under.
const String opEpubHost = 'epub/webview host';

/// How long a book gets to open before the reader is told it did not.
///
/// A webview that never calls back leaves a reader looking at a spinner with
/// no way to tell that from a slow book, and the ones that are slow are large
/// and on a phone. Half a minute is long enough to be unfair to neither.
const Duration epubOpenTimeout = Duration(seconds: 30);

/// The type size, in CSS pixels, that [EpubStyle.fontSize] is a percentage of.
///
/// The engine's own knob is `rendition.themes.fontSize`, which takes a length
/// and sets it on the root — so the book's own relative units still scale
/// beneath it and a heading the author asked to be large stays large. Sixteen
/// is the browser default and the number the percentage is therefore honest
/// about: 100% is the size the book would have had.
const double epubBaseFontSizePx = 16;

/// The engine, hosted by whichever webview this platform has.
final class WebviewEpubHost implements EpubHost {
  /// A host for one book on one screen.
  WebviewEpubHost();

  final fev.EpubController _controller = fev.EpubController();

  final StreamController<EpubPosition> _positions =
      StreamController<EpubPosition>.broadcast();
  final StreamController<EpubSelection> _selections =
      StreamController<EpubSelection>.broadcast();

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
        code: 'epub_open_timeout',
        op: opEpubHost,
      ),
    );
  }

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
  Future<void> goTo(String locator) async {
    _refuseIfDisposed();
    // Straight through, unchanged. A CFI and a chapter href are told apart by
    // the engine and not here: a caller — or a host — that had to distinguish
    // them would be one parsing a CFI.
    _controller.display(cfi: locator);
  }

  @override
  Future<void> nextPage() async {
    _refuseIfDisposed();
    _controller.next();
  }

  @override
  Future<void> previousPage() async {
    _refuseIfDisposed();
    _controller.prev();
  }

  @override
  Future<void> draw(EpubMark mark) async {
    _refuseIfDisposed();

    if (mark.underline) {
      _controller.addUnderline(cfi: mark.cfiRange);
      return;
    }

    _controller.addHighlight(
      cfi: mark.cfiRange,
      color: mark.color,
      opacity: mark.opacity,
    );
  }

  @override
  Future<void> erase(String cfiRange, {bool underline = false}) async {
    _refuseIfDisposed();

    if (underline) {
      _controller.removeUnderline(cfi: cfiRange);
      return;
    }

    _controller.removeHighlight(cfi: cfiRange);
  }

  @override
  Future<String> textOf(String cfiRange) async {
    _refuseIfDisposed();

    // The one call in this file that reaches past the package's Dart API, and
    // it is deliberate. `EpubController.extractText` takes a *start* and an
    // *end* CFI and builds the range itself; what an annotation stores is the
    // range, already built. Splitting one back into its two ends would be
    // parsing a CFI in Dart — the single thing this phase exists to prevent —
    // so the range goes to the glue function that takes a range.
    //
    // It is safe to name because the glue is pinned by digest in `engine.dart`
    // and the package by an exact version in the pubspec: this function cannot
    // be renamed under us without the engine test going red first. The name is
    // a compile-time constant, which is the invariant the bridge documents.
    final Object? result = await _controller.webViewController?.callAsync(
      '_extractText',
      <Object?>[cfiRange],
    );

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

/// The colours one reading theme is drawn in.
final class EpubPalette {
  const EpubPalette({
    required this.background,
    required this.foreground,
    required this.link,
  });

  final Color background;
  final Color foreground;
  final Color link;
}

/// The palette for [theme], resolving [EpubTheme.followSystem] against
/// [brightness].
///
/// They are here and not in `ui/core/themes` on purpose. These are the colours
/// of a *page*, chosen against paper rather than against the app's surfaces: a
/// reading ground that matched the application's background would be a book
/// printed on the same card as the shelf it came off. Sepia is the clearest
/// case — it is nothing the Material scheme has a name for, and readers ask
/// for it by name.
@visibleForTesting
EpubPalette epubPaletteOf(EpubTheme theme, Brightness brightness) =>
    switch (theme) {
      EpubTheme.followSystem =>
        brightness == Brightness.dark
            ? epubPaletteOf(EpubTheme.dark, brightness)
            : epubPaletteOf(EpubTheme.light, brightness),
      EpubTheme.light => const EpubPalette(
        background: Color(0xFFFFFFFF),
        foreground: Color(0xFF1A1A1A),
        link: Color(0xFF1A4F8B),
      ),
      EpubTheme.sepia => const EpubPalette(
        background: Color(0xFFF4ECD8),
        foreground: Color(0xFF3B2F1E),
        link: Color(0xFF7A4A16),
      ),
      EpubTheme.dark => const EpubPalette(
        background: Color(0xFF121212),
        foreground: Color(0xFFE0E0E0),
        link: Color(0xFF8AB4F8),
      ),
    };

/// [color] as the `#rrggbb` the engine's CSS wants.
@visibleForTesting
String cssColor(Color color) =>
    '#${((color.toARGB32()) & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

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

/// What gives the engine a DOM, and the only thing the reader feature knows
/// about it.
///
/// **This file names no webview.** There is one engine — `engine.dart` says
/// which — and the platforms differ in what runs it: a native webview on four
/// targets, a same-origin `<iframe>` in a browser, a CEF texture on Linux. A
/// port is what keeps that a fact about `data/services/epub` rather than a
/// condition inside the reader's screen, and it is what lets the round-trip
/// test talk about "a host" at all.
///
/// **A locator crosses this port unchanged, in both directions.** That is the
/// port's one real invariant and it is worth stating as a rule rather than
/// leaving it to each implementation to observe: a host reports the CFI the
/// engine gave it and passes back the CFI it was handed, with no normalizing,
/// no trimming and no re-encoding. Two hosts that each "tidied" a locator
/// slightly differently would be two CFI implementations wearing one interface
/// — which is the failure the whole phase is arranged around, arriving by the
/// back door. `locator_round_trip_test.dart` pins it.
///
/// **The failures are exceptions, not `Result`.** This is a service, and the
/// rule `architecture.md` states is that a failure becomes a value at the layer
/// boundary above — which for the reader is the view model, where every action
/// is a `Command` that already carries an error. An [AppException] from here
/// reaches a reader as the sentence a `Command` is holding.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// A book, as a host is given it.
///
/// **The bytes, whole, and not a stream or a path.** epub.js reads a zip and a
/// zip is read by seeking in it, so there is nothing to stream into: the
/// engine wants the file. A path is worse — the web target has none, and on
/// the four native ones the file lives in a blob store addressed by digest
/// rather than in a directory the webview could be pointed at.
///
/// It costs a book held in memory while it is open, and on the native hosts a
/// second transient copy while it crosses the bridge as base64. That is the
/// price of the engine being the same file on six platforms, and it is paid
/// once per open rather than per page.
final class EpubBook {
  /// The work [bytes] are the file of.
  const EpubBook({required this.ebookId, required this.bytes, this.title});

  /// The work this app calls it, which is what a position is written against.
  final String ebookId;

  /// The file.
  final Uint8List bytes;

  /// What the reader's library calls it, for the chrome around the page.
  ///
  /// It is the record's title and deliberately not the one inside the file:
  /// the reader may have corrected it, and RF05 is what let them.
  final String? title;

  @override
  String toString() => 'EpubBook($ebookId, ${bytes.length} bytes)';
}

/// Where the reader is in a book.
///
/// The two CFIs are the visible page's edges and [percent] is derived from
/// them by the engine's own location index. All three come from one report,
/// because they are one answer: a percentage taken at a different moment from
/// the locator beside it would describe a different page.
final class EpubPosition {
  /// The page running from [startCfi] to [endCfi], [percent] of the way in.
  const EpubPosition({
    required this.startCfi,
    required this.endCfi,
    required this.percent,
  });

  /// The CFI of the first thing on the page.
  ///
  /// This is the value that is written to `progress.locator` and replicated.
  /// It is the start and not the end because a reader resuming wants the page
  /// they were on rather than the one after it.
  final String startCfi;

  /// The CFI of the last thing on the page.
  final String endCfi;

  /// How far through the book, 0 to 100.
  ///
  /// Stored beside the locator rather than derived on demand, because a device
  /// that cannot open the format can still show it — which is the whole reason
  /// `progress.percent` is a column.
  final double percent;

  @override
  String toString() =>
      'EpubPosition($startCfi, ${percent.toStringAsFixed(1)}%)';
}

/// An entry in the book's table of contents.
final class EpubChapter {
  /// The chapter [title], at [href], with [children] beneath it.
  const EpubChapter({
    required this.title,
    required this.href,
    this.children = const <EpubChapter>[],
  });

  /// What the book calls it.
  final String title;

  /// Where it is, as the book's own manifest addresses it.
  ///
  /// It is not a CFI and is not stored anywhere: a table of contents is read
  /// out of the file every time the book is opened, so an href is a handle
  /// that lives as long as the screen does. Nothing replicated is ever an
  /// href, which is why this type is not in `domain/`.
  final String href;

  /// The entries below it, which are empty for a flat contents.
  final List<EpubChapter> children;

  @override
  String toString() => 'EpubChapter($title)';
}

/// What the reader has selected in the page.
final class EpubSelection {
  /// The passage [text] runs over [cfiRange].
  const EpubSelection({required this.cfiRange, required this.text});

  /// The range, as a CFI. It is what an annotation is anchored to.
  final String cfiRange;

  /// What it says, which is what a note quotes and what an export carries.
  final String text;

  @override
  String toString() => 'EpubSelection($cfiRange)';
}

/// A mark drawn over a range of the page.
///
/// It is what the host *draws* and not what the reader *made*: an annotation is
/// a replicated record with a revision on it, and this is the paint. Phase 10
/// is where the two meet, and keeping them apart is what lets a host be handed
/// a highlight without knowing that annotations exist.
final class EpubMark {
  /// The mark over [cfiRange], drawn in [color] at [opacity].
  const EpubMark({
    required this.cfiRange,
    required this.color,
    this.opacity = 0.3,
    this.underline = false,
  });

  /// The range it covers.
  final String cfiRange;

  /// What colour to draw it.
  final Color color;

  /// How solid, 0 to 1. A highlight a reader cannot read through is a
  /// highlight that hid the sentence it was about.
  final double opacity;

  /// Whether to underline rather than fill.
  final bool underline;

  @override
  String toString() => 'EpubMark($cfiRange)';
}

/// How a page is laid out, as the reader set it.
///
/// It is deliberately not replicated and there is no field in the contract for
/// it: type size is about this screen, on this device, held this far from a
/// reader's face. Phase 9 keeps it in `shared_preferences` beside the window's
/// size, for the reason `architecture.md` gives there — the drift database
/// holds what replicates, and this does not.
final class EpubStyle {
  /// The page at [fontSize] percent, in [theme].
  const EpubStyle({
    this.fontSize = 100,
    this.lineHeight = 1.5,
    this.marginPercent = 8,
    this.theme = EpubTheme.followSystem,
    this.fontFamily,
    this.spread = EpubSpread.auto,
  });

  /// Type size, as a percentage of the book's own.
  ///
  /// A percentage and not a point size, because an EPUB sets its own type in
  /// relative units and a book that asked for a large heading should still get
  /// one when the reader turns everything up.
  final double fontSize;

  /// The leading, as a multiple of the type size.
  final double lineHeight;

  /// How much of the page's width is margin, per side.
  final double marginPercent;

  /// The reading theme.
  final EpubTheme theme;

  /// The family to render in, or `null` to leave the book's own choice alone.
  ///
  /// `null` is the default and is a decision rather than an omission: a book
  /// that set a face usually set it for a reason, and overriding it by default
  /// would be this app deciding it knows better about every book at once.
  final String? fontFamily;

  /// Whether to lay the book out as one page or two.
  final EpubSpread spread;

  /// This style with the fields [other] names replaced.
  EpubStyle copyWith({
    double? fontSize,
    double? lineHeight,
    double? marginPercent,
    EpubTheme? theme,
    String? fontFamily,
    bool clearFontFamily = false,
    EpubSpread? spread,
  }) => EpubStyle(
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    marginPercent: marginPercent ?? this.marginPercent,
    theme: theme ?? this.theme,
    fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
    spread: spread ?? this.spread,
  );

  @override
  bool operator ==(Object other) =>
      other is EpubStyle &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.marginPercent == marginPercent &&
      other.theme == theme &&
      other.fontFamily == fontFamily &&
      other.spread == spread;

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineHeight,
    marginPercent,
    theme,
    fontFamily,
    spread,
  );

  @override
  String toString() => 'EpubStyle(${fontSize.round()}%, $theme)';
}

/// The colours a page is read in.
enum EpubTheme {
  /// Whatever the rest of the app is showing.
  ///
  /// It is the default because a reader who set their device to dark at night
  /// has already said what they want, and an app that made them say it twice
  /// would be an app that ignored the first answer.
  followSystem,

  /// Dark text on white.
  light,

  /// Dark text on a warm ground, which is the one setting that is neither of
  /// the other two and which readers ask for by name.
  sepia,

  /// Light text on near-black.
  dark,
}

/// One page at a time, or two.
enum EpubSpread {
  /// One page, whatever the window is.
  none,

  /// Two where there is room for two, which is what a wide desktop window has
  /// and a phone never does.
  auto,
}

/// The engine, and the DOM this platform gives it.
///
/// One instance renders one book on one screen. It is created per reader
/// screen rather than shared, because it owns a webview and a webview owns a
/// process: two books open at once are two hosts, and closing the screen is
/// what disposes of one.
abstract interface class EpubHost {
  /// The widget that gives the engine somewhere to draw.
  ///
  /// It is placed by the reader's chrome and is the only thing in this
  /// interface that is not a command. Everything around the page — the bar,
  /// the contents, the progress — is a Flutter widget over this one and never
  /// markup inside it, so that the parts of the reader that are not the book
  /// are localized, themed and tested like the rest of the app.
  Widget view();

  /// Opens [book], replacing whatever was open.
  ///
  /// It completes when the engine has the book and can answer about it, which
  /// is before the first page has necessarily been laid out. [positions] is
  /// what says where the reader ended up.
  ///
  /// [at] is where to open it: a CFI this reader's device or another one wrote.
  /// A locator that does not resolve is not a failure — a book edited between
  /// two versions can legitimately no longer contain the passage — and the host
  /// opens at the beginning instead, which [positions] then reports.
  Future<void> open(EpubBook book, {String? at});

  /// Where the reader is, as that changes.
  ///
  /// It reports on every relocation, which is every page turn, and it is the
  /// caller that decides what is worth writing down. Phase 9's position
  /// tracking debounces it, because a change per page turn would be an
  /// operation log nobody wants.
  Stream<EpubPosition> get positions;

  /// What the reader has selected, as they select it.
  Stream<EpubSelection> get selections;

  /// The book's table of contents, once the engine has parsed it.
  Future<List<EpubChapter>> chapters();

  /// Moves to [locator].
  ///
  /// A CFI, or a chapter's href from [chapters]. Both are what the engine
  /// accepts and the distinction is the engine's to make, which is the point:
  /// a caller that had to tell them apart would be a caller parsing a CFI.
  Future<void> goTo(String locator);

  /// The next page, and the previous one.
  Future<void> nextPage();

  /// As [nextPage], backwards.
  Future<void> previousPage();

  /// Draws [mark] over the page.
  ///
  /// It is idempotent per range: drawing the same range twice leaves one mark,
  /// because the caller is a list of annotations being reconciled against what
  /// is on screen and not a sequence of gestures.
  Future<void> draw(EpubMark mark);

  /// Removes the mark over [cfiRange].
  Future<void> erase(String cfiRange, {bool underline = false});

  /// What [cfiRange] says.
  ///
  /// It is how a note quotes the passage it is about, and how an export
  /// carries one. It is asked of the engine rather than remembered from the
  /// selection that made it, so that a mark made on another device — which
  /// arrived as a CFI and nothing else — can still be shown with its text.
  Future<String> textOf(String cfiRange);

  /// Applies [style] to the page.
  Future<void> apply(EpubStyle style);

  /// Releases the webview, the engine and the book.
  Future<void> dispose();
}

/// Where a host comes from.
///
/// It is a factory and not an instance in the provider graph, because a host
/// owns a webview and a book: one per reader screen, disposed with it. The
/// graph holds the thing that can make them, exactly as it holds a
/// `FilePicker` rather than a file.
abstract interface class EpubHostFactory {
  /// A host for one book on one screen.
  EpubHost create();
}

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
String cssColor(Color color) =>
    '#${((color.toARGB32()) & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The bytes of a book, for a caller that has a stream.
///
/// It is here because both hosts want the same thing and the blob store answers
/// with a stream: epub.js reads a zip by seeking in it, so the file has to be
/// whole before it crosses the bridge.
Future<Uint8List> collectBook(Stream<List<int>> bytes) async {
  final BytesBuilder builder = BytesBuilder(copy: false);

  await for (final List<int> chunk in bytes) {
    builder.add(chunk);
  }

  return builder.takeBytes();
}

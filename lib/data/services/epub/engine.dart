/// The one EPUB engine, named and pinned.
///
/// **There is exactly one renderer in this application and this file says
/// where it is.** epub.js ships as an asset of `flutter_epub_viewer`, and the
/// three hosts phase 9 builds — a native webview, a browser `<iframe>` and a
/// CEF texture on Linux — all load *these* bytes. Nothing in `lib/` implements
/// a CFI, in Dart or otherwise.
///
/// The reason is the locator. A CFI is written into `annotations.locator` and
/// `progress.locator`, replicated to the reader's other devices, and resolved
/// there by whatever renderer that device runs. Two implementations of "where
/// is this passage" would agree almost always, and the disagreements would
/// arrive — silently, a long way from their cause — as a highlight on the
/// wrong paragraph after a sync. One engine is not an optimization; it is the
/// only way the round trip can be argued at all.
///
/// **It is loaded from the bundle and never from a network.** An offline-first
/// reader that cannot open a book on a train has missed the point, and a
/// renderer fetched at run time is a renderer that changes under a locator
/// that was written down last month.
///
/// **The pin is the digest and not the version string.** `pubspec.yaml`
/// constrains the package to one exact version, which stops `pub upgrade`
/// moving the renderer; [assetDigests] is what notices if it moved anyway —
/// a republished version, a patched pub cache, a vendored copy somebody
/// edited. `engine_test.dart` reads every key out of the bundle and hashes it,
/// so the engine changing is a red build rather than a discovery.
///
/// The digests deliberately cover the whole reachable set and not just
/// `epub.js`. [hostPage] pulls in JSZip, the stylesheet and the glue that
/// drives the renderer, and a locator is produced by all of them together:
/// `epubView.js` is what asks epub.js where the page starts and hands the
/// answer back across the bridge, so a change there moves the locator exactly
/// as a change to the renderer would.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the engine lives in the asset bundle, and what it is.
abstract final class EpubEngine {
  /// The package the engine is vendored inside.
  ///
  /// Atril reads another package's assets on purpose. They are published under
  /// the `packages/<name>/…` keys the bundle exposes for exactly this, which
  /// is also how that package's own web host reaches them — so this is the
  /// documented door and not a way round the front of one.
  static const String package = 'flutter_epub_viewer';

  /// The version `pubspec.yaml` pins, spelled here so the two can be checked
  /// against each other.
  static const String packageVersion = '2.0.0';

  /// The upstream release of the renderer itself.
  ///
  /// epub.js reports `EPUBJS_VERSION = "0.3"` and nothing finer, and the
  /// bundled build does not match any published `epubjs` tarball byte for byte
  /// — the package carries its own build. So the version is provenance and
  /// [assetDigests] is the identity: what this app runs is *these bytes*,
  /// whatever they would have been called upstream.
  static const String engineVersion = '0.3';

  /// The version of JSZip beneath it, which is what unzips the book.
  static const String zipVersion = '3.1.5';

  /// The directory the engine's files live under.
  static const String assetRoot = 'packages/$package/lib/assets/webpage';

  /// The page that loads the engine and the glue over it.
  ///
  /// Every host opens this one document. The webview hosts hand it to the
  /// platform's webview and the Linux host serves it over a loopback socket,
  /// but it is the same file with the same scripts under it, which is the
  /// whole of the "one engine, several hosts" claim.
  static const String hostPage = '$assetRoot/html/swipe.html';

  /// The renderer.
  static const String renderer = '$assetRoot/dist/epub.js';

  /// The glue that drives it and reports a position back across the bridge.
  static const String glue = '$assetRoot/html/epubView.js';

  /// Every asset [hostPage] reaches, and the digest each one must have.
  ///
  /// Lowercase hex sha-256, the same form `ebooks.content_hash` uses. The map
  /// is the closure of what the page loads: the two scripts it names, the
  /// stylesheet, the image that stylesheet names, and the two glue files.
  ///
  /// `epub.js.map` is not among them and `themes.css` is not either. The first
  /// is read by a browser's devtools and never by the engine; the second is
  /// shipped by the package and referenced by nothing, so pinning it would be
  /// pinning a file whose contents cannot reach a locator.
  static const Map<String, String> assetDigests = <String, String>{
    hostPage:
        'cbbacbfd24aa0b686091b751af9c4481a9ba63a5168679f1e7bf66b8ffd58b07',
    renderer:
        'e452039eecc20d5bfcff2bc536a270ba5aecde56b6c5a521275d15b454907679',
    glue: '9c0f8be17589e3b61c09ab15a8f98a4381ba25d02d149b4c1f03ee9db8333fcb',
    '$assetRoot/dist/jszip.min.js':
        '7ef717214503c66c23aa100dfa2e97e29c20ecf200506d41b9d51adc36dcf389',
    '$assetRoot/html/epub_cfi_utils.js':
        '9a30c52c1feeff7ad883f85605a6863ed97b1b8a891737f90c74a0b85350aa7b',
    '$assetRoot/html/examples.css':
        'e606f01179e98e8c9e85d438211272411b90ccf39d58d7a04a213a58c255b5c8',
    '$assetRoot/html/ajax-loader.gif':
        '483c4a0396691993a641ec409c44b8b7e1daab0ae7e2b2944c4bc59520bb7655',
  };

  /// The licences of the code this app redistributes inside that package.
  ///
  /// Flutter registers the `LICENSE` of every package it resolves, so the
  /// package author's BSD-3 text is already in the about box. epub.js and
  /// JSZip are not packages here — they are files vendored into that one, and
  /// a licence covering the vendoring author's work says nothing about theirs.
  /// Registering them is what makes a shipped build honest about the code it
  /// actually contains, and it is one call because `LicenseRegistry` takes a
  /// stream and reads it lazily: nothing is loaded unless a reader opens the
  /// licences page.
  ///
  /// It is called from the entry points, beside the other things that have to
  /// happen once before `runApp`.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(const <String>[
        'epub.js',
      ], await rootBundle.loadString('assets/licenses/epub.js.LICENSE'));
      yield LicenseEntryWithLineBreaks(const <String>[
        'JSZip',
      ], await rootBundle.loadString('assets/licenses/jszip.LICENSE'));
    });
  }

  /// Whether [locator] is shaped like an EPUB CFI.
  ///
  /// It is a *shape* check and emphatically not a parser. Parsing a CFI is the
  /// engine's job and writing a second parser here would be the second
  /// implementation this whole file exists to prevent — this only tells a CFI
  /// apart from the other things `locator` can hold, which is a page number in
  /// a PDF or a locator a later version of this app has learned to write.
  ///
  /// The one place it earns its keep is a device refusing to *resolve* what it
  /// cannot: a position replicated from a phone that was reading an EPUB means
  /// nothing to a host asked to open a DjVu, and saying so is better than
  /// handing epub.js a string it will fail on somewhere inside itself.
  static bool looksLikeCfi(String locator) =>
      locator.startsWith('epubcfi(') && locator.endsWith(')');
}

/// The bytes of one engine asset, read from the bundle.
///
/// It is here rather than at each call site because the Linux host serves the
/// whole directory and the test hashes it, and both want the same thing: the
/// asset, unmodified, with no `String` decoding in between. A `ByteData` is
/// what `rootBundle` answers with and what both callers want.
Future<ByteData> loadEngineAsset(String key, {AssetBundle? bundle}) =>
    (bundle ?? rootBundle).load(key);

/// The engine's asset keys, in a form a directory server can index.
///
/// The Linux host has no asset protocol to hand a webview, so it serves these
/// over a loopback socket under the paths [EpubEngine.hostPage] resolves its
/// relative `src` attributes against. Deriving the map here keeps the two
/// halves — what is pinned and what is served — from drifting apart.
@visibleForTesting
Map<String, String> engineAssetsByPath() => <String, String>{
  for (final String key in EpubEngine.assetDigests.keys)
    key.substring(EpubEngine.assetRoot.length + 1): key,
};

/// The correctness claim the whole split rests on.
///
/// A CFI authored on a phone is written to `progress.locator` or
/// `annotations.locator`, replicated, and resolved on a desktop by whatever
/// host that machine runs. If the two disagree, the reader gets a highlight on
/// the wrong paragraph weeks later, with nothing in any log connecting it to
/// its cause. This file is what stands between the phase's argument and that.
///
/// **What can be proved here, and what cannot.** A real round trip would open a
/// book under two hosts and compare what each resolves — and a host is a
/// webview, which does not exist in `flutter test` on any platform. So the
/// claim is not asserted directly. It is decomposed into the three things it is
/// actually made of, each of which *is* checkable, and which together leave no
/// room for the hosts to disagree:
///
/// 1. **There is one implementation of "where is this passage".** Not two that
///    agree; one. The engine is a pinned asset set, every host loads those same
///    keys, and no Dart in this repository parses or constructs a CFI.
/// 2. **A locator crosses each port unchanged.** Whatever the engine says
///    arrives at the database byte for byte, and whatever the database holds
///    arrives back at the engine byte for byte. This is where a host could
///    quietly become a second implementation — by trimming, normalizing or
///    re-encoding — and it is checked against a corpus rather than asserted.
/// 3. **Both hosts drive that one implementation through the same names.** The
///    webview host gets them from the package's controller; the Linux host
///    spells them itself, and that is the single asymmetry this phase
///    introduced. A name wrong there is a call into nothing on one target.
///
/// Given all three, the hosts cannot disagree about a locator, because there is
/// only one thing that has an opinion about one and both are asking it the same
/// question.
library;

import 'dart:convert';
import 'dart:io';

import 'package:atril/data/services/epub/engine.dart';
import 'package:atril/data/services/epub/engine_server.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/epub/webview_epub_host.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as fev;
import 'package:flutter_test/flutter_test.dart';

/// Locators of the shapes epub.js actually produces.
///
/// They are not invented: each is a form the specification defines and the
/// engine emits — a plain step path, one carrying id assertions, a character
/// offset, a range with a shared parent, an indirection into a spine item, a
/// text-location assertion, and one with a percentage in it. The awkward ones
/// are deliberate, because a host that "cleaned up" a locator would most likely
/// do it to a bracket, a comma or a colon.
const List<String> cfiCorpus = <String>[
  'epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/3:10)',
  'epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/1:0)',
  'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05]/3:10)',
  // A range: one base, two paths, two commas that must survive.
  'epubcfi(/6/4[chap01ref]!/4[body01]/10[para05],/2/1:1,/3:4)',
  // An id assertion carrying a character that means something in a CFI.
  'epubcfi(/6/4[chap01ref,/2,/4]!/4/2/2)',
  // A text-location assertion, which carries a bracketed comparison.
  'epubcfi(/6/4[chap01ref]!/4/2/2[para;s=b])',
  // Spatial and temporal offsets, which are legal and rare.
  'epubcfi(/6/4[chap01ref]!/4/2/2@0:10)',
  'epubcfi(/6/4[chap01ref]!/4/2/2~23.5@0:10)',
  // The shortest thing that is still a CFI.
  'epubcfi(/2)',
  // A step path deep enough that nothing would want to retype it.
  'epubcfi(/6/242[x-chapter-24]!/4/2/144/2/6/2/1:238)',
];

/// Whether [source] contains Dart that takes a locator apart.
///
/// It is a named function and not a regular expression inline in a test,
/// because a check like this one fails in exactly one way: by matching nothing
/// and passing forever. `architecture.md` says so about the write-path test's
/// pinned list, and it is truer here — there is nothing in a clean tree for
/// this to match, so a detector that had quietly stopped working would look
/// identical to a codebase obeying the rule. It is therefore exercised against
/// samples of both kinds below.
///
/// What it looks for is a locator being *read*: split, indexed, sliced or
/// rewritten. Comparing two locators is fine and so is passing one along; what
/// is forbidden is Dart forming an opinion about what is inside one.
bool dissectsALocator(String source) {
  final String code = source
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  return RegExp(
    r"""(?:epubcfi|cfi|locator|CFI)\w*\s*\.\s*"""
    r"""(?:split|substring|indexOf|lastIndexOf|replaceAll|replaceFirst"""
    r"""|codeUnitAt|codeUnits|characters)\s*[(.]""",
    caseSensitive: false,
  ).hasMatch(code);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('there is one implementation of where a passage is', () {
    test('no Dart in this application parses or builds a CFI', () async {
      // The rule `architecture.md` states, enforced rather than trusted. A
      // second CFI implementation would not fail a build or a type check — it
      // would agree almost always — so the only thing that can catch one is a
      // check that looks for it.
      //
      // What it looks for is Dart that takes a locator apart. `engine.dart`'s
      // `looksLikeCfi` is the one thing allowed to notice the wrapper, and it
      // is exempt by name because it is a shape check that reads no step.
      final List<String> offenders = <String>[];

      await for (final FileSystemEntity entity in Directory(
        'lib',
      ).list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        // `engine.dart` is the one exemption, and it is exempt because
        // `looksLikeCfi` reads the wrapper and no step inside it. It is named
        // rather than pattern-matched so that adding a second exemption is a
        // decision somebody writes down.
        if (dissectsALocator(await entity.readAsString()) &&
            !entity.path.endsWith('epub/engine.dart')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These files take a locator apart in Dart. A CFI is the engine\'s '
            'to read: a second implementation would agree almost always and '
            'disagree as annotations landing on the wrong paragraph after a '
            'sync. See docs/architecture.md.',
      );
    });

    test('the check for that would notice if it happened', () {
      // The check above passes on a clean tree, which is also what it would do
      // if it had stopped working. So it is shown a locator being taken apart,
      // in each of the shapes a second implementation would start as.
      expect(
        dissectsALocator("final steps = cfi.split('/');"),
        isTrue,
        reason: 'splitting a CFI into its steps is a parser beginning',
      );
      expect(
        dissectsALocator("locator.substring(8, locator.length - 1)"),
        isTrue,
        reason: 'unwrapping a CFI by offset is reading its syntax',
      );
      expect(
        dissectsALocator("if (cfiRange.indexOf(',') > 0) {"),
        isTrue,
        reason: 'finding the comma is finding where a range divides',
      );
      expect(
        dissectsALocator("startCfi.replaceAll('[', '')"),
        isTrue,
        reason: 'stripping assertions is rewriting a locator',
      );

      // And the things that are not parsing: comparing, storing, passing on.
      expect(dissectsALocator('if (cfi == other.cfi) {'), isFalse);
      expect(dissectsALocator('await host.goTo(locator);'), isFalse);
      expect(dissectsALocator("locator.isEmpty ? null : locator"), isFalse);
      expect(dissectsALocator("row.locator = position.startCfi;"), isFalse);
    });

    test('every host loads the same pinned engine', () {
      // The webview hosts hand the platform's webview the asset key directly
      // and the Linux host serves the same key over a socket. Both start from
      // this map, which `engine_test.dart` hashes against the bundle and
      // `engine_server_test.dart` hashes against the wire.
      expect(EpubEngine.assetDigests, contains(EpubEngine.renderer));
      expect(EpubEngine.assetDigests, contains(EpubEngine.glue));
      expect(EpubEngine.assetDigests, contains(EpubEngine.hostPage));

      // Every served path resolves back to a pinned key, so there is no route
      // by which a host could be given an engine file the pin does not cover.
      for (final MapEntry<String, String> served
          in engineAssetsByPath().entries) {
        expect(EpubEngine.assetDigests, contains(served.value));
      }
    });
  });

  group('a locator crosses a port unchanged', () {
    test(
      'the webview host reports what the engine said, byte for byte',
      () async {
        // Where the engine's answer becomes a row. A host that trimmed, or that
        // normalized a bracket, would be authoring a locator of its own.
        for (final String cfi in cfiCorpus) {
          final EpubPosition position = epubPositionOf(
            fev.EpubLocation(startCfi: cfi, endCfi: cfi, progress: 0.5),
          );

          expect(position.startCfi, cfi, reason: 'start of $cfi');
          expect(position.endCfi, cfi, reason: 'end of $cfi');
        }
      },
    );

    test('a locator survives the JSON both hosts carry it through', () {
      // The Linux host sends arguments as JSON and receives its replies the
      // same way, and the webview host's bridge does too. A CFI is full of
      // characters JSON has opinions about — brackets, commas, colons — so the
      // encoding is exercised rather than assumed.
      for (final String cfi in cfiCorpus) {
        expect(jsonDecode(jsonEncode(cfi)), cfi);
        // As it is spliced into a call, which is how it reaches the glue.
        expect(jsonDecode('[${jsonEncode(cfi)}]'), <String>[cfi]);
      }
    });

    test(
      'a host refuses a locator it cannot resolve, and does not repair one',
      () {
        // The only decision a host makes about a locator is whether to hand it
        // over at all, and it decides on the wrapper alone. Anything more would
        // be a Dart CFI parser wearing a smaller hat.
        for (final String cfi in cfiCorpus) {
          expect(EpubEngine.looksLikeCfi(cfi), isTrue, reason: cfi);
        }

        // A position replicated from a device that was reading another format.
        expect(EpubEngine.looksLikeCfi('page=42'), isFalse);
        expect(EpubEngine.looksLikeCfi('42'), isFalse);
      },
    );
  });

  group('both hosts drive that engine through the same names', () {
    late Set<String> defined;

    setUpAll(() async {
      // Read from the bundle rather than from the pub cache: what a host will
      // load is the asset, and the asset is what is pinned.
      final String glue = utf8.decode(
        (await loadEngineAsset(EpubEngine.glue)).buffer.asUint8List(),
      );

      defined = RegExp(
        r'^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(',
        multiLine: true,
      ).allMatches(glue).map((RegExpMatch match) => match.group(1)!).toSet();
    });

    test('the glue was read at all', () {
      // The same vacuity trap as the check above: if the regex stopped matching
      // the glue, `defined` would be empty, every name would be "missing", and
      // the test below would fail loudly — which is the right direction. This
      // is here for the opposite mistake, a pattern that matched everything.
      expect(defined, hasLength(greaterThan(20)));
      expect(defined, contains(EpubGlue.loadBook));
    });

    test('the glue defines every function the Linux host calls', () {
      // The asymmetry this phase introduced. The webview host reaches the glue
      // through the package's controller, which is typed and compiled; the
      // Linux host spells the names itself, and a wrong one is a call into
      // nothing on exactly one target.
      final Set<String> missing = EpubGlue.all.difference(defined);

      expect(
        missing,
        isEmpty,
        reason:
            'The Linux host calls these and the pinned glue does not define '
            'them. Linux would stop turning pages while the other five targets '
            'carried on, which is precisely the divergence this phase forbids.',
      );
    });

    test('the near-miss the naming is most likely to make is checked', () {
      // The package's controller method is `prev` and the glue function it
      // calls is `previous`; the underline functions carry a capital L in the
      // middle. Both are the sort of thing a careful person gets wrong once.
      expect(defined, contains(EpubGlue.previous));
      expect(defined, isNot(contains('prev')));
      expect(defined, contains(EpubGlue.addUnderline));
      expect(defined, isNot(contains('addUnderline')));
    });

    test('the glue still announces itself the way both bridges expect', () async {
      // Both non-package hosts — the browser's iframe shim and the Linux one —
      // provide `window.flutter_inappwebview.callHandler` and dispatch a
      // readiness event, because that is what the glue waits for. If the glue
      // stopped waiting for it, both would hang on a page that never asks for
      // a book, and the digest pin is what makes that a checkable claim.
      final String glue = utf8.decode(
        (await loadEngineAsset(EpubEngine.glue)).buffer.asUint8List(),
      );

      expect(glue, contains('flutterInAppWebViewPlatformReady'));
      expect(glue, contains("callHandler('readyToLoad')"));
      expect(glue, contains("callHandler('relocated'"));

      // And the Linux shim provides exactly those two things.
      expect(epubBridgeShim, contains('window.flutter_inappwebview'));
      expect(epubBridgeShim, contains('callHandler'));
    });
  });
}

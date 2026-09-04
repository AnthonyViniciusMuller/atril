/// What the reader does *on the page*, forwarded back out of it.
///
/// **The page is not Flutter's to hear, and on five targets it hears nothing.**
/// The engine renders into a webview — a native one on four targets, a
/// same-origin `<iframe>` in a browser — and a webview is a platform view: the
/// browser hands a click to the `<iframe>` and Flutter's glass pane never sees
/// it, so a `GestureDetector` wrapped around the page receives nothing at all.
/// Worse, that click moves DOM focus *into* the book's document, and a key
/// event fires in the document that has focus and does not cross into its
/// parent — so from the first tap onwards the reader's arrow keys, space,
/// PageUp/PageDown and Escape stop reaching the app. The reader is left with a
/// page that does not turn and controls that do not answer, which is what this
/// file exists to fix.
///
/// Measured, not assumed. In a browser build of the reader's own arrangement —
/// a `Focus` with a key handler over a translucent `GestureDetector` over the
/// engine's `<iframe>` — a key before any click reaches Flutter, a click on the
/// page reaches nothing, and no key reaches Flutter afterwards.
///
/// **So the page reports them itself.** [pageInputScript] is injected into the
/// engine's own document and forwards two things back over the bridge that is
/// already there: a tap, and a key the reader's controls are bound to. They
/// arrive as [EpubPageEvent]s on `EpubHost.pageEvents` and the view model
/// dispatches them to the same commands the chrome's buttons use, so there is
/// one set of controls and two ways in rather than two implementations.
///
/// **It is injected and not vendored.** `engine.dart` says why the renderer is
/// pinned by digest and never edited: a locator is produced by the glue and the
/// renderer together, so a patched copy is a second CFI implementation with
/// extra steps. This script touches neither. It registers a listener through
/// `rendition.hooks.content`, which is the engine's own documented door for
/// running something in each rendered document, and reports what it sees.
library;

import 'epub_host.dart';

/// The message a tap on the page arrives under.
///
/// The names are prefixed because they share a namespace with the glue's own
/// `callHandler` messages — `selection`, `relocated`, `readyToLoad` and the
/// rest — and a collision would be this file quietly answering for the package.
const String pageTapHandler = 'atrilTap';

/// The message a key pressed inside the page arrives under.
const String pageKeyHandler = 'atrilKey';

/// The global the script sets so that injecting it twice does nothing.
const String pageInputFlag = '__atrilPageInput';

/// [key] — a DOM `KeyboardEvent.key` — as the event it means, or `null` where
/// it is a key the reader's controls are not bound to.
///
/// The names are the DOM's and are spelled here rather than in the script,
/// which forwards whatever it saw: a key this build does not use costs one
/// message and is dropped here, and the set the reader's controls answer to
/// stays a Dart list beside the screen that also binds it.
EpubPageEvent? epubPageEventOfKey(String key) => switch (key) {
  'ArrowRight' || 'PageDown' || ' ' || 'Spacebar' => EpubPageEvent.forward,
  'ArrowLeft' || 'PageUp' => EpubPageEvent.back,
  'Escape' || 'Esc' => EpubPageEvent.dismiss,
  _ => null,
};

/// The script that reports a tap and a key out of the engine's page.
///
/// [withKeys] is false for the Linux host and true for the other five, and the
/// difference is not a preference. On Linux the engine is a CEF *texture* inside
/// the Flutter tree, so Flutter receives the key first and the reader's screen
/// already handles it; forwarding it as well would turn one page press into two.
/// On the five webview targets Flutter receives nothing once the page has focus,
/// which is the whole reason this file exists.
///
/// What it does not report is as deliberate as what it does:
///
/// * **A click on a link is the book's.** A reader following a footnote asked
///   the book for something, not the app, and the chrome should not move under
///   them while it answers.
/// * **A click that ends a selection is the selection's.** The engine reports a
///   selection through its own `selection` message and the reader's next move is
///   one of the actions that appear for it, so a tap that also toggled the
///   chrome away would take those actions off screen.
///
/// It is written as ES5 in a string because it is evaluated inside a document
/// this project does not compile, and it is idempotent — a second injection
/// returns at the first line — because the hosts inject it once per book and a
/// reader who reopens one should not get two of every event.
String pageInputScript({required bool withKeys}) =>
    '''
(function () {
  if (window.$pageInputFlag) { return; }
  window.$pageInputFlag = true;

  var withKeys = ${withKeys ? 'true' : 'false'};

  function send(name, arg) {
    try {
      window.flutter_inappwebview.callHandler(name, arg);
    } catch (e) {
      // The bridge is the host's and is installed before the book loads. A
      // throw here is a page that outlived its host, and a reader gesture is
      // not worth an error nobody can act on.
    }
  }

  function isLink(node) {
    while (node) {
      if (node.tagName === 'A' && node.getAttribute('href')) { return true; }
      node = node.parentElement;
    }
    return false;
  }

  function hasSelection(doc) {
    try {
      var selection = doc.defaultView.getSelection();
      return !!(selection && selection.rangeCount > 0 && selection.toString());
    } catch (e) {
      return false;
    }
  }

  function onClick(event) {
    if (isLink(event.target)) { return; }
    if (hasSelection(event.target.ownerDocument || document)) { return; }
    send('$pageTapHandler', null);
  }

  function onKey(event) {
    // Reported by name and judged in Dart. The page does not know which keys
    // the reader's controls are bound to, and a list of them here would be a
    // second copy of one that already exists beside the screen.
    send('$pageKeyHandler', event.key);
  }

  function watch(doc) {
    if (!doc || doc.$pageInputFlag) { return; }
    doc.$pageInputFlag = true;
    doc.addEventListener('click', onClick, true);
    if (withKeys) { doc.addEventListener('keydown', onKey, true); }
  }

  // The page itself, for a tap on the margin either side of the text.
  watch(document);

  // And every document the engine renders a section into. The hook is the
  // engine's own and runs for each one as it is created; the sweep after it is
  // for the sections that were already on screen when this was injected.
  if (typeof rendition !== 'undefined' && rendition) {
    rendition.hooks.content.register(function (contents) {
      watch(contents.document);
    });

    try {
      rendition.getContents().forEach(function (contents) {
        watch(contents.document);
      });
    } catch (e) {
      // `getContents` throws on a rendition with nothing displayed yet, which
      // is a book whose first section the hook above will catch anyway.
    }
  }
})();
''';

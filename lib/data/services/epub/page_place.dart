/// Where in the book a page is, when the engine cannot yet say.
///
/// **A percentage comes from the engine's location index, and that index costs
/// the whole book.** Building it means unzipping and parsing every section:
/// measured at 135 seconds and 8325 locations for a work of 1182 sections.
/// Until it resolves the engine answers 0 for every page, which is not a
/// position — `epubPercentOf` is where that is turned into an absence — and a
/// reader is left with a bar that never fills for the first minutes of a book,
/// or for the whole of a session shorter than that.
///
/// **The spine is the answer the engine has from the start.** It knows which
/// section the page is in and how many there are before it has read a word of
/// any of them, and that ratio is a real measurement of how far through the
/// book the reader is. It is coarser than the index — a section, not a
/// paragraph — and the coarseness is self-correcting in the direction that
/// matters: a book of a thousand sections is where the index takes minutes and
/// where a section is 0.08% of the whole, and a book of ten fat chapters is
/// where a section is a tenth of the book and the index lands in about a
/// second. The estimate is worst exactly where it is needed least.
///
/// It is replaced the moment the real number exists. Every position report
/// carries both, the host prefers the engine's own, and `locationLoaded` is
/// what asks for a fresh one as soon as there is a better answer to give.
///
/// **It is injected and not vendored**, for the reason `page_input.dart` gives
/// beside it: the renderer is pinned by digest because a locator is produced by
/// the glue and the engine together, and a patched copy would be a second
/// implementation of one. This reads two numbers the engine already computed
/// and reports them. It writes nothing, resolves nothing, and parses no CFI.
library;

/// The message a page's place in the spine arrives under.
///
/// Prefixed like the other two this app injects, because the namespace is
/// shared with the glue's own `relocated`, `selection` and `readyToLoad`, and a
/// collision would be this file quietly answering for the package.
const String pagePlaceHandler = 'atrilPlace';

/// The global the script sets so that injecting it twice does nothing.
const String pagePlaceFlag = '__atrilPagePlace';

/// The script that reports which section of the spine the page is in.
///
/// It rides the engine's own `relocated` event rather than polling, so a report
/// arrives for the same page turns the glue reports — and it is registered
/// synchronously, where the glue's own handler waits on two CFI-to-XPath
/// promises before it sends, so the spine facts are already with the host when
/// the position they belong to arrives.
///
/// ES5 in a string, for the reason `page_input.dart` is: it is evaluated inside
/// a document this project does not compile.
String pagePlaceScript() =>
    '''
(function () {
  if (window.$pagePlaceFlag) { return; }
  window.$pagePlaceFlag = true;

  function send(place) {
    try {
      window.flutter_inappwebview.callHandler('$pagePlaceHandler', place);
    } catch (e) {
      // The bridge is the host's and is installed before the book loads. A
      // throw here is a page that outlived its host, and an estimate is not
      // worth an error nobody can act on.
    }
  }

  function report(location) {
    if (!location || !location.start) { return; }

    var spine = -1;
    var indexed = false;

    // Read defensively and separately. These are the engine's internals rather
    // than its documented surface, and a build that renamed either should cost
    // the estimate and not the page the reader is looking at.
    try { spine = book.spine.length; } catch (e) {}
    try { indexed = book.locations.total > 0; } catch (e) {}

    send({
      index: location.start.index,
      spine: spine,
      // Sent so that the host can tell *the engine says zero because it cannot
      // say* from *the engine says zero because the reader is at the front*.
      indexed: indexed
    });
  }

  if (typeof rendition !== 'undefined' && rendition) {
    rendition.on('relocated', report);

    // The page already on screen when this was injected. The hosts inject
    // after the book has rendered, so the first relocation is usually already
    // past — and without this the reader would see nothing until they turned a
    // page, which is the failure this whole file is here to end.
    try {
      if (rendition.location) { report(rendition.location); }
    } catch (e) {
      // A rendition with nothing displayed yet. The event above will catch it.
    }
  }
})();
''';

/// What a page's place in the spine says about how far through the book it is,
/// or `null` where it says nothing.
///
/// [index] is the section the page is in and [spine] is how many there are.
/// The first section is 0 and answers 0%, which is the truthful reading: a
/// reader at the front of the book has not gone through any of it.
///
/// It is a fraction of the *sections* and not of the text, so a book whose
/// sections differ wildly in length is reported unevenly. That is the trade
/// named in this library's own documentation, and it is why the engine's index
/// wins the moment it exists.
double? epubSpinePercentOf({required int index, required int spine}) {
  if (spine <= 0 || index < 0) {
    return null;
  }

  return (index / spine * 100).clamp(0, 100).toDouble();
}

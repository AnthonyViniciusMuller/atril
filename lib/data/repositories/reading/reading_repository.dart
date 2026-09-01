/// Opening a book, as the reader's screen sees it.
///
/// It is a second repository beside `LibraryRepository` rather than four more
/// methods on it, and the reason is what each one is *about*. The library is
/// the reader's collection: what is in it, what it is called, where it is
/// filed, whether its bytes are here. This is one book, open, and where the
/// reader is inside it — which is a different question, with a different
/// lifetime, asked by one screen.
///
/// **It answers from the local replica and the local blob store, and reaches
/// no node.** A book that needed a network to open would be a book that cannot
/// be read on a train, which is the one thing UC04 cannot be. Bringing the
/// bytes onto the device is `LibraryRepository.downloadEbook`, it happens
/// before this, and it is where the network lives.
library;

import '../../../domain/models/ebook.dart';
import '../../../utils/result.dart';
import '../../services/epub/epub_host.dart';

/// The stable code of a work whose bytes this device does not hold.
///
/// It is a *not yet* and not a failure. A book listed and not downloaded is
/// the ordinary state of a work on a fresh device, and in a browser it is the
/// ordinary state of every book the reader has not asked to keep — so the
/// screen offers to fetch it rather than apologizing.
const String codeContentNotOnDevice = 'content_not_on_device';

/// The stable code of a format this build cannot open.
///
/// EPUB is the one format phase 9 renders. The other four import, list,
/// synchronize and show a percentage, and a reader who opens one is told what
/// this build can do rather than shown an empty page — which is the honest
/// shape of the promise the roadmap made.
const String codeFormatNotReadable = 'format_not_readable';

/// One book, open.
abstract interface class ReadingRepository {
  /// UC04. The work [ebookId] names, ready to be handed to a host.
  ///
  /// It fails with [codeFormatNotReadable] for a work this build does not
  /// render and with [codeContentNotOnDevice] for one whose file is not here.
  /// Both are states a screen has something useful to say about, which is why
  /// they are codes rather than one message.
  ///
  /// The bytes are read whole, because epub.js reads a zip by seeking in it.
  /// `EpubBook` carries the reasoning and the cost.
  Future<Result<EpubBook>> openBook(String ebookId);

  /// The record itself, for the chrome around the page.
  ///
  /// It is here rather than read through `LibraryRepository` so that the
  /// reader's screen has one thing to hold. What it needs is the title — the
  /// record's, which the reader may have corrected, and not the one inside the
  /// file.
  Future<Result<Ebook?>> ebook(String ebookId);
}

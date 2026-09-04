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

/// The stable code of a work this device no longer holds a row for.
///
/// Another device deleted it while this one was showing it, the tombstone
/// arrived, and there is nothing to open. It is the same state the book's own
/// screen names, and the reader is told the same thing here.
const String codeEbookNotFound = 'ebook_not_found';

/// The stable code of a file too large for this build to read whole.
///
/// epub.js reads a zip by seeking in it, so the file is held in memory while
/// it is open, and the implementation names the size where this build stops.
/// Retrying reads the same bytes again, so the refusal offers nothing to
/// press.
const String codeEbookTooLarge = 'ebook_too_large';

/// Where one device stopped in one work, as a screen shows it.
///
/// **Every device's position is its own row and its own answer.** RN01 asks for
/// that and C05 is what makes it correct: a position belongs to one work and
/// one device and is written by that device alone, so a phone and a desktop
/// disagreeing about where the reader is are not in conflict — they are two
/// true statements. Nothing merges them, and [watchPlacesIn] is where all of
/// them are answered.
///
/// **Which of them a screen shows is the screen's question and not this
/// one's.** *Where are my devices in this book* wants every row, and the
/// book's own screen asks it. *What is there to come back to* is a question
/// about books, and three appliances in the middle of one novel are one thing
/// to come back to — so [watchContinueReading] answers with the place each
/// work was last left at. Neither is a merge: both hand back a row exactly one
/// device wrote.
final class ReadingPlace {
  /// The place [work] was left at.
  const ReadingPlace({
    required this.work,
    required this.locator,
    required this.updatedAt,
    required this.onThisDevice,
    this.percent,
  });

  /// The work it is in.
  final Ebook work;

  /// Where the reader stopped, in the format-independent form the schema
  /// stores. It is a CFI for an EPUB and crosses this layer unchanged.
  final String locator;

  /// How far through, 0 to 100, or `null` where nothing could compute it.
  final double? percent;

  /// When it was written, on the hybrid clock.
  final DateTime updatedAt;

  /// Whether this device is the one that wrote it.
  ///
  /// It is a flag and not a device name, and the difference is a thing this
  /// application genuinely does not know: nothing here stores the reader's
  /// other devices. `ListDevices` exists in the contract and phase 12 is what
  /// calls it, so until then *another device* is the whole of the honest
  /// answer — and saying that is better than inventing a name for it.
  final bool onThisDevice;

  /// How far through, as a fraction, for a control that wants one.
  double get fraction => (percent ?? 0) / 100;

  @override
  String toString() => 'ReadingPlace(${work.id}, $percent%)';
}

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

  /// UC04. Where this device stopped in [ebookId], or `null` where it has not
  /// stopped anywhere in it yet.
  ///
  /// **It is this device's own row and deliberately not the furthest or the
  /// most recent of them.** Every device's position is its own answer (RN01,
  /// C05), and a reader who opens a book on the machine they were reading it
  /// on expects the page they left — not the one their phone reached on the
  /// train, which would move them without being asked. Which position to
  /// *offer* is a decision the shelf makes with all of them, and
  /// [watchPlacesIn] is what it makes it from.
  ///
  /// The locator crosses this layer unchanged, like every other. It is not
  /// checked against the format here: a position replicated from a device
  /// reading something else is a legitimate row and a meaningless instruction,
  /// and the host is where that is recognized — it opens at the beginning and
  /// reports so, which is the same answer a reader who never opened the book
  /// gets.
  Future<Result<String?>> resumeAt(String ebookId);

  /// UC04. Records where this device stopped in [ebookId].
  ///
  /// **It is authored as an operation like every other change** — never through
  /// `UpdateReadingProgress`, which C21 makes useless: a position written
  /// through the node's API reaches the reader's other devices never. The
  /// author decides whether this is the first position this device has written,
  /// because C05 makes that answerable: a position has exactly one writer, so a
  /// record this device has never stamped is a record that does not exist.
  ///
  /// [percent] is stored even where the locator is one this build could not
  /// resolve, because a device that cannot open a DjVu can still say the reader
  /// is forty percent through it — which is what the column is for.
  ///
  /// **The caller debounces.** This writes an operation every time it is
  /// called, and a page turn is a call: `ReaderViewModel` is where the rate is
  /// decided, because it is what sees the turns.
  Future<Result<void>> saveProgress({
    required String ebookId,
    required String locator,
    double? percent,
  });

  /// UC04. The place each of this reader's books was last left at, most recent
  /// first — one per work, whichever device left it there.
  ///
  /// It is what *continue reading* is built from, and one row per work is what
  /// that question has one of: a reader whose phone and laptop are both in the
  /// middle of one novel has one novel to carry on with, not two. The row is
  /// still one device's — [onThisDevice] says whether it is this one's — and
  /// every device's row is answered by [watchPlacesIn], which is where RN01's
  /// *show them all* lives.
  ///
  /// [limit] therefore counts books. A strip with room for twenty of them
  /// should hold twenty, and not three views of the same one.
  ///
  /// A tombstoned work is left out. A reader who deleted a book has said they
  /// are not reading it.
  Stream<Result<List<ReadingPlace>>> watchContinueReading({int limit});

  /// Where this reader's devices are in one work, most recent first.
  ///
  /// Every device that has stopped anywhere in it, and no collapsing: this is
  /// the answer RN01 asks for, and the book's own screen is what shows it.
  Stream<Result<List<ReadingPlace>>> watchPlacesIn(String ebookId);

  /// The record itself, for the chrome around the page.
  ///
  /// It is here rather than read through `LibraryRepository` so that the
  /// reader's screen has one thing to hold. What it needs is the title — the
  /// record's, which the reader may have corrected, and not the one inside the
  /// file.
  Future<Result<Ebook?>> ebook(String ebookId);
}

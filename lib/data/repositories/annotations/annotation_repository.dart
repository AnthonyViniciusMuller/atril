/// What the reader marked, as every screen above this line sees it (UC05).
///
/// It is a third repository beside the library's and the reader's, and the
/// division is the one those two already draw: the library is the collection,
/// reading is where somebody got to in a book, and this is what they wrote
/// down. A mark outlives the session that made it, is read on a screen that is
/// not the book's, and is exported on its own — three things a method on
/// `ReadingRepository` would have dragged into a file about one open book.
///
/// **It answers from the local replica and reaches no node.** Every mark is
/// authored as an operation and pushed, exactly as a work or a grouping is, and
/// `CreateAnnotation`, `UpdateAnnotation` and `DeleteAnnotation` are never
/// called — C21 is why: a mark made through the node's API writes the node's
/// table, appends nothing to its log, and reaches the reader's other devices
/// never.
///
/// **The single text field carries two different things, and that is the
/// contract's shape rather than this app's choice.** An annotation has one
/// nullable `text`, so:
///
/// - a **highlight** carries the passage it covers, captured from the selection
///   that made it. The engine had the words at that moment and no other layer
///   ever will — the annotations screen lists marks from books that are not
///   open, and an export runs with no engine at all — so a highlight that
///   stored nothing would be a row that can only ever be shown as a CFI;
/// - a **note** carries the reader's own words, which the contract requires to
///   be present because a note without them is an empty note;
/// - a **bookmark** carries nothing. It is a position and the position is the
///   whole of it.
library;

import '../../../domain/models/annotation.dart';
import '../../../utils/result.dart';

/// The stable code of a mark this device does not hold.
const String codeMarkNotFound = 'annotation_not_found';

/// The stable code of a note whose words are empty.
///
/// It is refused here rather than at the column, so that the refusal names the
/// note and not the table. A note is the reader speaking, and a note with
/// nothing in it is the one mark that cannot mean anything.
const String codeNoteWithoutText = 'note_without_text';

/// What the reader has marked.
abstract interface class AnnotationRepository {
  /// UC05. The marks in one work, most recent first.
  ///
  /// It is what the reader's screen draws over the page, so a mark another
  /// device removed leaves the stream and the paint goes with it.
  ///
  /// The order is when each mark was made and deliberately not where it is in
  /// the book: two CFIs are compared by parsing them, and a CFI parser in Dart
  /// is the second implementation `architecture.md` forbids.
  Stream<Result<List<Annotation>>> watchMarksIn(String ebookId);

  /// UC05. Marks a passage the reader selected.
  ///
  /// [cfiRange] is the range the engine reported and it crosses every layer
  /// unchanged — this is the value replicated to the reader's other devices,
  /// and the one thing phase 9's single engine exists to keep resolvable.
  ///
  /// [passage] is what the range says, as the selection reported it. It is
  /// stored rather than resolved later because the screen that lists marks
  /// across the library has no engine and no open book to ask.
  Future<Result<Annotation>> highlight({
    required String ebookId,
    required String cfiRange,
    String? passage,
  });

  /// UC05. Marks a passage and says something about it.
  ///
  /// A note is a highlight the reader wrote on, and [text] is what they wrote.
  /// It is required rather than optional because the contract requires it, and
  /// the contract is right: a note with nothing in it is an empty note, and the
  /// mark that would be left is the highlight the reader already had.
  ///
  /// The passage itself is not kept. There is one text field on the record and
  /// the reader's own words are what belongs in it — the passage is addressed
  /// by [cfiRange], which is what the engine resolves when the book is open.
  ///
  /// It is refused with [codeNoteWithoutText] where the words are blank.
  Future<Result<Annotation>> note({
    required String ebookId,
    required String cfiRange,
    required String text,
  });

  /// UC05. Marks a place the reader wants to come back to.
  ///
  /// A bookmark carries no text and covers no range: [locator] is a *position*
  /// and not a selection, which is why nothing is painted over the page for it
  /// and why it is the one kind of mark a reader can make without touching the
  /// text first.
  ///
  /// It is deliberately not the same record as a reading position, and the
  /// difference is who wrote it and what it means. A position is where a device
  /// stopped, it has exactly one writer per device (C05), and it is overwritten
  /// on the next page. A bookmark is a place the reader chose, it belongs to the
  /// reader rather than to the device, and nothing overwrites it.
  Future<Result<Annotation>> bookmark({
    required String ebookId,
    required String locator,
  });

  /// UC05. Removes a mark.
  ///
  /// A tombstone and never a deletion, like every other removal here: a row
  /// removed outright is resurrected by the first replica that had not yet
  /// heard about the removal.
  Future<Result<void>> removeMark(String annotationId);

  /// UC05, undone. Brings a removed mark back.
  ///
  /// It is one operation carrying no fields, which is what a tombstone makes
  /// cheap — and it is why the removal above is offered with an undo rather
  /// than with a confirmation.
  Future<Result<void>> restoreMark(String annotationId);
}

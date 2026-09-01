/// The cover this device extracted from a file it holds.
///
/// It replicates to nobody, and that is the whole design. A cover is not in
/// the contract — there is no field for it on `Ebook` and no call that carries
/// one — because it is not a claim about the work: it is a picture that was
/// inside the file, and a device holding the file can produce it again. So a
/// device that downloads a book later extracts its own cover, and one that
/// never downloads it shows the placeholder, which is the honest answer to
/// *what does this book look like* when the bytes are somewhere else.
///
/// It is a table and not the blob store for two reasons. The store is keyed by
/// a digest, and a digest is what identifies a *book* across the federation —
/// a cover in there would be counted in the storage budget the reader is shown
/// and listed among the files they are choosing whether to keep. And a cover is
/// small enough that sqlite is the right place for it, where it is deleted with
/// the work by the same cascade that reaches every other row about it.
library;

import 'package:drift/drift.dart';

import 'library.dart';

/// The largest cover this device keeps.
///
/// A cover is shown at a couple of hundred pixels and a publisher's is
/// occasionally a print-resolution scan. Past this the picture is dropped and
/// the placeholder is shown, which costs a reader an image and saves every
/// query over this table from carrying a megabyte it never renders.
const int maxCoverBytes = 4 * 1024 * 1024;

/// One work's cover.
@DataClassName('EbookCoverRow')
class EbookCovers extends Table {
  /// The work it belongs to.
  ///
  /// It is the primary key, so a work has one cover: the file carried one
  /// picture and there is nothing to choose between. The cascade is what makes
  /// the row disappear with the work rather than outliving it.
  TextColumn get ebookId =>
      text().references(Ebooks, #id, onDelete: KeyAction.cascade)();

  /// What the manifest said the image is.
  TextColumn get mediaType => text().withLength(min: 1, max: 100)();

  /// The image.
  BlobColumn get bytes => blob()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{ebookId};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(bytes) > 0 AND length(bytes) <= $maxCoverBytes)',
  ];
}

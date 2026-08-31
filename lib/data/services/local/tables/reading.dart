/// What the reader wrote in a work, and where they stopped in it.
///
/// The two tables here replicate and reconcile differently, and the difference
/// is C05. An annotation is edited from any of the reader's devices — a note
/// started on a phone and finished on a tablet is the ordinary case — so two
/// versions of it really can be concurrent and it carries the full
/// [RevisionColumns]. A reading position belongs to one work and one device and
/// is written by that device alone, so its versions are totally ordered by that
/// device's own counter and can never conflict.
///
/// That is why `progress` does not use the mixin. It is not a smaller revision:
/// the device is the row's own key rather than a tie-break, and a tombstone
/// would be a deletion with no meaning, since a reader who stops reading a work
/// leaves their position where it was. A table that offered a tie-break would
/// invite the reconciler to apply one where nothing ties.
library;

import 'package:drift/drift.dart';

import '../converters.dart';
import 'constraints.dart';
import 'library.dart';
import 'revision.dart';

/// What kind of mark the reader left.
///
/// A note is text the reader wrote; a highlight and a bookmark are about the
/// passage and carry text only if they were given one.
const List<String> annotationKinds = <String>['note', 'highlight', 'bookmark'];

/// Something the reader wrote, and the passage it is attached to.
@DataClassName('AnnotationRow')
@TableIndex(name: 'annotations_ebook', columns: <Symbol>{#ebookId})
class Annotations extends Table with RevisionColumns {
  /// The identifier the device that made the mark minted.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// The work the mark is in.
  ///
  /// A mark is made in a work and stays in it: it is not among the fields an
  /// update may write, because a note that moved between books would be a note
  /// about a passage that is not there.
  TextColumn get ebookId =>
      text().references(Ebooks, #id, onDelete: KeyAction.cascade)();

  /// One of [annotationKinds].
  TextColumn get kind => text().withLength(min: 1, max: 20)();

  /// Required for a note, which is otherwise an empty note; optional on the
  /// other two.
  ///
  /// The column is named `text` because that is what the contract, the delta
  /// and the node's own column call it. The getter cannot be: it would shadow
  /// the column builder it is declared with.
  TextColumn get content => text().named('text').nullable()();

  /// The passage, expressed so that it survives the format: a CFI in an EPUB, a
  /// page in a PDF.
  ///
  /// It is the one value in this schema that is authored by a renderer rather
  /// than by the app, and it is replicated to the reader's other devices, which
  /// is the whole reason phase 9 insists on one CFI implementation across the
  /// six targets. Two of them would disagree here, and the disagreement would
  /// arrive as a highlight on the wrong paragraph.
  TextColumn get locator => text().withLength(min: 1, max: 255)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    oneOf('kind', annotationKinds),
    'CHECK (length(trim(locator)) > 0)',
    // A note with no text is an empty note; the other two are about the
    // passage and carry text only when the reader added one.
    "CHECK (kind <> 'note' OR length(trim(coalesce(text, ''))) > 0)",
  ];
}

/// Where one device stopped in one work.
///
/// One row per work and device, as Quadro 21 specifies and C05 explains: the
/// grain is what makes the record conflict-free, because it gives the row
/// exactly one writer. A device never writes another device's position, and the
/// vector clock here is a version counter for recognizing a position already
/// seen rather than a conflict resolver.
///
/// Which position to show the reader — the furthest, the most recent, or a
/// prompt asking which to resume from — is this app's decision to make, and it
/// needs every device's row to make it. That is what RN01 asks for and why the
/// rows are kept rather than collapsed.
@DataClassName('ProgressRow')
class Progress extends Table {
  /// The surrogate identifier this device minted for the pair below.
  ///
  /// It is provenance and not identity, exactly as a filing's is (C18): the
  /// record is addressed across the federation by `(ebook_id, device_id)`, and
  /// a device that forgot the identifier it minted would mint another on every
  /// write.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// The work the position is in.
  TextColumn get ebookId =>
      text().references(Ebooks, #id, onDelete: KeyAction.cascade)();

  /// The device the position belongs to, and half of the row's natural key.
  ///
  /// It is not a tie-break. Nothing here ever ties, and the column is not the
  /// `device_id` [RevisionColumns] carries even though it is spelled the same:
  /// that one is whichever device wrote last, and this one is whose position
  /// this is.
  TextColumn get deviceId => text().withLength(min: 36, max: 36)();

  /// Where the reader stopped, in the same format-independent form an
  /// annotation's passage uses.
  TextColumn get locator => text().withLength(min: 1, max: 255)();

  /// How far through, 0 to 100.
  ///
  /// Derived from the locator and stored anyway, so that a device which cannot
  /// open a format can still report that the reader is forty percent through
  /// it. It is absent where nothing could compute it.
  RealColumn get percent => real().nullable()();

  /// The causal version. Because the row has one writer it always has exactly
  /// one entry, and it grows by one on every write.
  TextColumn get vectorClock => text().map(const VectorClockConverter())();

  /// When the position was written, on the hybrid clock.
  IntColumn get updatedAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{ebookId, deviceId},
  ];

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(trim(locator)) > 0)',
    'CHECK (percent IS NULL OR (percent >= 0 AND percent <= 100))',
  ];
}

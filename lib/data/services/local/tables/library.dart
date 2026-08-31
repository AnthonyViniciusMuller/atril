/// The reader's collection: the works they hold, the groupings they file them
/// under, and which work is filed under which.
///
/// These three replicate, so each carries [RevisionColumns] and each is written
/// only by the reconciler or the operation author — never by a view, and never
/// by a call to the node. `architecture.md` states that rule and C21 is why it
/// is not a preference.
///
/// The node's own `library` schema is the shape these follow, minus the column
/// this side has no use for: there is no `user_id` anywhere here, because a
/// device holds one reader's collection and a column that could hold a second
/// reader's would be a column something eventually filters on wrongly.
library;

import 'package:drift/drift.dart';

import '../converters.dart';
import 'constraints.dart';
import 'revision.dart';

/// The formats UC02 admits, as the delta spells them.
///
/// They are the contract's enumerators in the vocabulary the delta and the
/// node's own column use — lowercase, unprefixed — because the same names have
/// to travel through the contract, the node's schema and this one. An unknown
/// value is refused here rather than stored: a work whose format nothing can
/// name is a work no screen can decide what to do with.
const List<String> ebookFormats = <String>[
  'epub',
  'pdf',
  'mobi',
  'djvu',
  'cbz',
];

/// The two kinds of grouping RF05 offers over one structure.
const List<String> collectionKinds = <String>['collection', 'category'];

/// A work in the reader's collection.
@DataClassName('EbookRow')
@TableIndex(name: 'ebooks_content_hash', columns: <Symbol>{#contentHash})
class Ebooks extends Table with RevisionColumns {
  /// The identifier the device that imported the work minted, and the one
  /// every annotation and every reading position references. It travels: a
  /// work is created once, and no replica ever mints another for it.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// What the work is called.
  TextColumn get title => text().withLength(min: 1, max: 255)();

  /// Absent rather than empty when the file did not say. A work whose author is
  /// unknown and one whose author is the empty string are different claims, and
  /// the contract spells the difference with `optional`.
  TextColumn get author => text().withLength(max: 255).nullable()();

  /// Absent rather than empty, as [author] is.
  TextColumn get publisher => text().withLength(max: 255).nullable()();

  /// Absent rather than empty, as [author] is.
  TextColumn get language => text().withLength(max: 20).nullable()();

  /// One of [ebookFormats].
  TextColumn get format => text().withLength(min: 1, max: 10)();

  /// The digest of the file, lowercase hex sha-256.
  ///
  /// It is what identifies the bytes across the whole federation — the same
  /// work imported by two devices converges on one stored object — and it is
  /// deliberately not a reference to anything this device holds. A device that
  /// has the row and not the file is the ordinary state of a book that has not
  /// been downloaded yet.
  TextColumn get contentHash => text().withLength(min: 64, max: 64)();

  /// The length of the file, absent until something has seen it.
  IntColumn get sizeBytes => integer().nullable()();

  /// The metadata a format carries and the contract does not name — series,
  /// ISBN, subjects (RF05).
  ///
  /// It is an object and never a scalar, which the check below enforces as the
  /// node's `jsonb` constraint does. It is stored as the text the delta carried
  /// rather than decoded, because per-field reconciliation replaces this field
  /// whole and nothing here reads inside it.
  TextColumn get extraMetadata => text().nullable()();

  /// When the work entered the collection. A wall clock instant the reader is
  /// shown, and not the hybrid one the merge orders by.
  IntColumn get importedAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    oneOf('format', ebookFormats),
    "CHECK (length(trim(title)) > 0)",
    "CHECK (content_hash GLOB '[0-9a-f]*' AND length(content_hash) = 64)",
    'CHECK (size_bytes IS NULL OR size_bytes > 0)',
    "CHECK (extra_metadata IS NULL OR json_type(extra_metadata) = 'object')",
  ];
}

/// A grouping the reader defined over their collection.
@DataClassName('CollectionRow')
class Collections extends Table with RevisionColumns {
  /// The identifier the device that created the grouping minted.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// What the reader called it.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// One of [collectionKinds]. A collection is a grouping the reader defined
  /// and a category is a subject they filed under; they are one structure with
  /// two meanings, which is what lets RF05 offer both without a second entity.
  TextColumn get kind => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('collection'))();

  /// What the reader said it is for, if anything.
  TextColumn get description => text().nullable()();

  /// When it was created, on a wall clock.
  IntColumn get createdAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    oneOf('kind', collectionKinds),
    "CHECK (length(trim(name)) > 0)",
  ];
}

/// Which work is filed under which grouping.
///
/// The pair is the record and the row is a handle on it. C06 and C18 together
/// are why: the schema makes `(ebook_id, collection_id)` unique because two
/// offline devices will otherwise file the same work under the same shelf
/// twice, and each replica mints its own surrogate identifier for the row, so
/// what identifies the record across the federation is the pair the delta
/// carries and not the id the operation names.
///
/// Filing a work and filing it again are therefore the same request: the row is
/// reused and its tombstone flipped, never inserted a second time. That also
/// means a deletion of a pair this device has never held is still written,
/// tombstone and all — dropping it would file the work again the moment this
/// device heard about the filing the deletion undid.
@DataClassName('EbookCollectionRow')
@TableIndex(
  name: 'ebook_collections_collection',
  columns: <Symbol>{#collectionId},
)
class EbookCollections extends Table with RevisionColumns {
  /// The surrogate identifier this device minted for the pair. It is
  /// provenance, not identity.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// The work.
  TextColumn get ebookId =>
      text().references(Ebooks, #id, onDelete: KeyAction.cascade)();

  /// The grouping.
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{ebookId, collectionId},
  ];
}

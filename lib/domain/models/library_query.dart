/// What the reader has asked to see of their collection.
///
/// It is a value rather than a set of parameters because the same question is
/// asked by three things that must not disagree: the screen that shows the
/// works, the count beside a grouping's name, and the empty state — which has
/// to tell a reader with no books at all apart from one whose filter matches
/// nothing. A query object is what makes *nothing here* and *nothing like
/// that* two different answers.
///
/// Nothing in it reaches a node. The collection is on this device, so
/// narrowing it is a question about rows this app already holds, and the
/// answer is the same whether or not there is a network. UC01's read is the
/// one place this app calls `ListEbooks` and it is called once, to seed a
/// device that has just been bound.
library;

/// The order a reader asked their collection in.
///
/// The three are what a shelf is sorted by, and the default is not
/// alphabetical: a library that grows by importing is one whose newest arrival
/// is the thing most likely to be looked for, and a reader who wants the
/// alphabet asks for it.
enum LibrarySort {
  /// Newest arrival first.
  recentlyImported,

  /// By title.
  title,

  /// By author, with the works whose author the file did not say last.
  ///
  /// Last and not first, and not under some rendering of *unknown*: an absent
  /// author is a fact about the file and sorting it into the As would put it
  /// among the names of real people.
  author,
}

/// A question about the reader's collection.
final class LibraryQuery {
  /// The collection in [sort] order, narrowed to what is filed under
  /// [collectionId] when there is one.
  const LibraryQuery({
    this.sort = LibrarySort.recentlyImported,
    this.collectionId,
  });

  /// The order to answer in.
  final LibrarySort sort;

  /// The grouping to narrow to, or `null` for the whole collection.
  ///
  /// It is the identifier and not the grouping, because a query outlives the
  /// row it names: a reader looking at a shelf that another device has just
  /// deleted is asking about an identifier that resolves to nothing, and that
  /// is an empty answer rather than a failure.
  final String? collectionId;

  /// Whether the query narrows the collection at all.
  ///
  /// It is what separates the two empty states. A reader with no books is
  /// shown what to do next; a reader whose filter matches nothing is shown the
  /// filter.
  bool get isNarrowed => collectionId != null;

  /// This query in [sort] order.
  LibraryQuery orderedBy(LibrarySort sort) =>
      LibraryQuery(sort: sort, collectionId: collectionId);

  /// This query narrowed to [collectionId], or widened to the whole collection
  /// where it is `null`.
  LibraryQuery within(String? collectionId) =>
      LibraryQuery(sort: sort, collectionId: collectionId);

  @override
  bool operator ==(Object other) =>
      other is LibraryQuery &&
      other.sort == sort &&
      other.collectionId == collectionId;

  @override
  int get hashCode => Object.hash(sort, collectionId);

  @override
  String toString() =>
      'LibraryQuery($sort${collectionId == null ? '' : ', in $collectionId'})';
}

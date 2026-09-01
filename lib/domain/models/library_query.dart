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

import 'ebook.dart';

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
  /// The collection in [sort] order, narrowed by whichever of [collectionId],
  /// [format] and [term] are given.
  const LibraryQuery({
    this.sort = LibrarySort.recentlyImported,
    this.collectionId,
    this.format,
    this.term = '',
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

  /// The format to narrow to, or `null` for every format.
  ///
  /// A work whose format this build cannot name is never matched by one, which
  /// is right: the filter is *show me the EPUBs*, and a work this app cannot
  /// name the format of is not one of them by any reading.
  final EbookFormat? format;

  /// What the reader typed, matched against the title and the author.
  ///
  /// It is the whole of the search, and it is matched against the same folded
  /// key the shelf is ordered by — so a reader who types `sertao` finds
  /// *Sertão* and finds it where they expected. A search that matched
  /// differently from the way the results are sorted would be two answers to
  /// one question.
  final String term;

  /// Whether the query narrows the collection at all.
  ///
  /// It is what separates the two empty states. A reader with no books is
  /// shown what to do next; a reader whose filter matches nothing is shown the
  /// filter, and offered the way out of it.
  bool get isNarrowed =>
      collectionId != null || format != null || term.trim().isNotEmpty;

  /// Whether the reader is searching rather than only filtering.
  ///
  /// The two empty answers read differently: *nothing on this shelf* names a
  /// place, and *nothing matches* names what was asked for.
  bool get isSearching => term.trim().isNotEmpty;

  /// This query in [sort] order.
  LibraryQuery orderedBy(LibrarySort sort) => _with(sort: sort);

  /// This query narrowed to [collectionId], or widened to the whole collection
  /// where it is `null`.
  LibraryQuery within(String? collectionId) =>
      _with(collectionId: collectionId, clearCollection: collectionId == null);

  /// This query narrowed to [format], or widened to every format.
  LibraryQuery ofFormat(EbookFormat? format) =>
      _with(format: format, clearFormat: format == null);

  /// This query matching [term].
  LibraryQuery matching(String term) => _with(term: term);

  /// The same order, and nothing narrowing it.
  ///
  /// It is what the way out of an empty result runs: a reader looking at
  /// nothing should not have to undo three filters one at a time to find out
  /// which of them was the problem.
  LibraryQuery get widened => LibraryQuery(sort: sort);

  LibraryQuery _with({
    LibrarySort? sort,
    String? collectionId,
    EbookFormat? format,
    String? term,
    bool clearCollection = false,
    bool clearFormat = false,
  }) => LibraryQuery(
    sort: sort ?? this.sort,
    collectionId: clearCollection ? null : collectionId ?? this.collectionId,
    format: clearFormat ? null : format ?? this.format,
    term: term ?? this.term,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryQuery &&
      other.sort == sort &&
      other.collectionId == collectionId &&
      other.format == format &&
      other.term == term;

  @override
  int get hashCode => Object.hash(sort, collectionId, format, term);

  @override
  String toString() =>
      'LibraryQuery($sort'
      '${collectionId == null ? '' : ', in $collectionId'}'
      '${format == null ? '' : ', $format'}'
      '${term.isEmpty ? '' : ', "$term"'})';
}

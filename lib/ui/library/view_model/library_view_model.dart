/// What the library screen knows.
///
/// It is the first view model over a *stream* rather than over a call, and the
/// difference is the whole of what phase 3 was for. The collection is not
/// fetched: it is watched, out of the local replica, so a work that arrives by
/// synchronization while the reader is looking at the shelf appears without
/// anything asking for it — and a work the reader imports appears the same way,
/// through the same subscription, because the import writes to the database the
/// screen is already reading.
///
/// That is also why there is no refresh action anywhere on this screen. There
/// is nothing to refresh: the answer is a query over rows this device holds,
/// and it is as current as the last thing that wrote one.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../domain/models/library_query.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/library');

/// The state of the library screen.
final class LibraryViewModel extends ChangeNotifier {
  /// The view model over [library], starting from [query].
  LibraryViewModel({required this.library, LibraryQuery? query})
    : _query = query ?? const LibraryQuery() {
    _subscribe();
    _groupings = library.watchCollections().listen(_onCollections);
    _counts = library.watchFilingCounts().listen(_onCounts);
  }

  /// Where the collection is read from.
  final LibraryRepository library;

  LibraryQuery _query;
  StreamSubscription<Result<List<Ebook>>>? _works;
  late final StreamSubscription<Result<List<Collection>>> _groupings;
  late final StreamSubscription<Result<Map<String, int>>> _counts;

  List<Ebook>? _ebooks;
  List<Collection> _collections = const <Collection>[];
  Map<String, int> _filingCounts = const <String, int>{};
  Exception? _error;

  /// What the screen is currently asking for.
  LibraryQuery get query => _query;

  /// The works, or `null` while the first answer has not arrived.
  ///
  /// `null` and empty are deliberately different. A device that has just been
  /// opened has not yet been told anything, and a device that has been told
  /// there is nothing is a reader with no books — and only the second one is
  /// shown an empty state telling them what to do next.
  List<Ebook>? get ebooks => _ebooks;

  /// The reader's groupings, for the filter above the shelf.
  List<Collection> get collections => _collections;

  /// How many works are filed under each grouping, by identifier.
  Map<String, int> get filingCounts => _filingCounts;

  /// Why the collection could not be read, or `null`.
  ///
  /// It survives the next answer only until there is one: a query that failed
  /// and then succeeded is a screen that should stop apologizing.
  Exception? get error => _error;

  /// Whether the reader holds no works at all, as opposed to none matching the
  /// filter.
  ///
  /// The two are different screens. A reader with nothing is told how to start;
  /// a reader whose shelf is empty is told which shelf, and offered the way
  /// back to the whole collection.
  bool get isEmpty => (_ebooks?.isEmpty ?? false) && !_query.isNarrowed;

  /// Shows the collection in [sort] order.
  void sortBy(LibrarySort sort) => _ask(_query.orderedBy(sort));

  /// Narrows the collection to [collectionId], or widens it to all of it.
  void showCollection(String? collectionId) => _ask(_query.within(collectionId));

  @override
  void dispose() {
    unawaited(_works?.cancel());
    unawaited(_groupings.cancel());
    unawaited(_counts.cancel());
    super.dispose();
  }

  void _ask(LibraryQuery query) {
    if (query == _query) {
      return;
    }

    _query = query;

    // The rows already shown are kept while the next answer is built. Clearing
    // them would blank the shelf for a frame on every change of sort order,
    // which reads as the collection having been lost and found again.
    _subscribe();
    notifyListeners();
  }

  void _subscribe() {
    unawaited(_works?.cancel());

    _works = library.watchEbooks(_query).listen((Result<List<Ebook>> result) {
      switch (result) {
        case Ok<List<Ebook>>(:final value):
          _ebooks = value;
          _error = null;
        case Error<List<Ebook>>(:final error):
          _log.warning('the collection could not be read', error);
          _error = error;
      }

      notifyListeners();
    });
  }

  void _onCollections(Result<List<Collection>> result) {
    if (result case Ok<List<Collection>>(:final value)) {
      _collections = value;

      // A shelf the reader was looking at can be deleted on another device.
      // The query then names an identifier that resolves to nothing, which
      // would be an empty screen with a filter the reader cannot see or clear.
      if (_query.collectionId case final String narrowed
          when !value.any((collection) => collection.id == narrowed)) {
        _ask(_query.within(null));
      }

      notifyListeners();
    }
  }

  void _onCounts(Result<Map<String, int>> result) {
    if (result case Ok<Map<String, int>>(:final value)) {
      _filingCounts = value;
      notifyListeners();
    }
  }
}

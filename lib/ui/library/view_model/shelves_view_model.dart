/// What the shelves screen knows (UC03).
///
/// The groupings and the counts are two streams and not one query, because
/// they change for different reasons: a shelf is renamed by the reader or by
/// another device, and a count moves every time a book is filed anywhere. One
/// combined query would wake the whole screen on either.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../domain/models/collection.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// One grouping being created or edited.
///
/// The identifier is what tells the two apart, and it is `null` for a grouping
/// that does not exist yet — which is also what the form's title reads.
typedef ShelfDraft = ({String? id, CollectionEdits edits});

/// The state of the shelves screen.
final class ShelvesViewModel extends ChangeNotifier {
  /// The view model over [library].
  ShelvesViewModel({required this.library}) {
    save = Command1<void, ShelfDraft>(_save);
    remove = Command1<void, String>(library.deleteCollection.of);

    _groupings = library.watchCollections().listen(_onGroupings);
    _counts = library.watchFilingCounts().listen(_onCounts);
  }

  /// Where the groupings live.
  final LibraryRepository library;

  /// Creates a grouping, or records what changed about one.
  ///
  /// One command for both, because they are one form and one decision: what
  /// separates them is whether the draft names a grouping that already exists.
  late final Command1<void, ShelfDraft> save;

  /// Tombstones a grouping. The works survive it.
  late final Command1<void, String> remove;

  late final StreamSubscription<Result<List<Collection>>> _groupings;
  late final StreamSubscription<Result<Map<String, int>>> _counts;

  List<Collection>? _all;
  Map<String, int> _filingCounts = const <String, int>{};

  /// Every grouping, or `null` before the first answer.
  List<Collection>? get all => _all;

  /// The groupings the reader put together.
  ///
  /// A collection and a category are one structure with two meanings, and the
  /// screen is what keeps them apart — so the split is here, where it can be
  /// tested, rather than in a widget that filters as it builds.
  List<Collection> get collections => _of(CollectionKind.collection);

  /// The subjects the reader files works under.
  List<Collection> get categories => _of(CollectionKind.category);

  /// How many works are filed under each grouping, by identifier.
  Map<String, int> get filingCounts => _filingCounts;

  /// Whether the reader has defined nothing at all.
  bool get isEmpty => _all?.isEmpty ?? false;

  /// Brings back the grouping [collectionId] names.
  Future<Result<void>> undoRemoval(String collectionId) =>
      library.restoreCollection(collectionId);

  @override
  void dispose() {
    unawaited(_groupings.cancel());
    unawaited(_counts.cancel());
    super.dispose();
  }

  /// A grouping whose kind this build cannot name is shown with the
  /// collections.
  ///
  /// It is what a node running a later version legitimately sends, and the
  /// reader is better served by seeing a shelf they can open than by a shelf
  /// that is nowhere on the screen.
  List<Collection> _of(CollectionKind kind) => <Collection>[
    for (final grouping in _all ?? const <Collection>[])
      if (grouping.kind == kind ||
          (grouping.kind == null && kind == CollectionKind.collection))
        grouping,
  ];

  Future<Result<void>> _save(ShelfDraft draft) async {
    final id = draft.id;

    if (id == null) {
      return switch (await library.createCollection(draft.edits)) {
        Ok<Collection>() => const Result<void>.ok(null),
        Error<Collection>(:final error) => Result<void>.error(error),
      };
    }

    return library.editCollection(id, draft.edits);
  }

  void _onGroupings(Result<List<Collection>> result) {
    if (result case Ok<List<Collection>>(:final value)) {
      _all = value;
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

extension on Future<Result<void>> Function(String) {
  /// The call itself, which a `Command1` takes as its action.
  Future<Result<void>> of(String id) => this(id);
}

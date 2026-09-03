/// What the screen of one work knows.
///
/// It watches four things and they change independently: the record, where its
/// bytes are, which shelves it is on, and the cover this device extracted. The
/// record arrives by synchronization, the bytes by a transfer, the shelves by
/// either — so a screen built from one snapshot of all four would be a screen
/// that goes stale while the reader is looking at it.
///
/// **The work becomes `null` rather than failing.** Another device can delete
/// a book the reader is looking at, the tombstone arrives, the reconciler
/// applies it, and this screen now has nothing to show. That is a state and not
/// an error, and it is the difference between telling a reader *this book was
/// deleted* and telling them something went wrong.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/services/content/content_downloader.dart';
import '../../../data/services/epub/epub_metadata.dart';
import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../../utils/cancellation.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/library');

/// The state of one work's screen.
final class EbookViewModel extends ChangeNotifier {
  /// The view model over [library], about the work [ebookId] names.
  EbookViewModel({required this.library, required this.ebookId}) {
    save = Command1<void, EbookEdits>(
      (EbookEdits edits) => library.editEbook(ebookId, edits),
    );
    delete = Command0<void>(library.deleteEbook.of(ebookId));
    restore = Command0<void>(library.restoreEbook.of(ebookId));
    file = Command1<void, ({String collectionId, bool filed})>(
      (({String collectionId, bool filed}) change) => library.fileEbook(
        ebookId: ebookId,
        collectionId: change.collectionId,
        filed: change.filed,
      ),
    );
    _allShelves = library.watchCollections().listen(_onAllShelves);
    keep = Command0<void>(_keep);
    release = Command0<void>(library.releaseEbook.of(ebookId));
    download = Command0<void>(_download);

    _work = library.watchEbook(ebookId).listen(_onWork);
    _content = library.watchContent(ebookId).listen(_onContent);
    _shelves = library.watchCollectionsOf(ebookId).listen(_onShelves);

    unawaited(_loadCover());
  }

  /// Where the work is read from.
  final LibraryRepository library;

  /// The work this screen is about.
  final String ebookId;

  /// RF05. Records what the reader changed about the work.
  ///
  /// It is a `Command1` and not a method for the reason every action in this
  /// app is one: the button that runs it has to know whether it is running,
  /// and a screen that tracked that itself would be tracking it in one of
  /// several places.
  late final Command1<void, EbookEdits> save;

  /// UC01, delete. Tombstones the work.
  ///
  /// It is a tombstone and never a removal, which is what makes the undo one
  /// operation carrying nothing rather than a record to rebuild.
  late final Command0<void> delete;

  /// UC01, undo. Lifts the tombstone [delete] wrote.
  ///
  /// **It is run after this screen has gone**, which is the one thing worth
  /// saying about it: the undo is offered in the message that follows the
  /// deletion, and by then the reader is back on the shelf and this view model
  /// has been disposed. That is safe because a `Command` disposed mid-run
  /// finishes its action and keeps its result, and tells nobody — which is a
  /// property this phase gave it. What it replaces is the screen reaching for
  /// the repository itself and discarding what it answered, so an undo that
  /// the node refused announced that the book was back.
  late final Command0<void> restore;

  /// UC03. Files the work under a grouping, or takes it out of one.
  ///
  /// One command and two directions, because membership is a register per pair
  /// and not a row that is appended: what the change decides is which way the
  /// register goes, and there is nothing between the two (C06).
  late final Command1<void, ({String collectionId, bool filed})> file;

  /// Brings the file onto this device and keeps it.
  late final Command0<void> keep;

  /// Stops keeping the file, and removes it.
  ///
  /// It is refused while the node has not received the file: a work whose
  /// bytes are still queued is on this device and nowhere else.
  late final Command0<void> release;

  /// Brings the file onto this device without changing what is kept.
  late final Command0<void> download;

  late final StreamSubscription<Result<Ebook?>> _work;
  late final StreamSubscription<Result<ContentState>> _content;
  late final StreamSubscription<Result<List<Collection>>> _shelves;
  late final StreamSubscription<Result<List<Collection>>> _allShelves;

  Ebook? _ebook;
  bool _loaded = false;
  ContentState _state = const ContentState(onThisDevice: false, kept: false);
  List<Collection> _collections = const <Collection>[];
  List<Collection> _all = const <Collection>[];
  EpubCover? _cover;
  DownloadProgress? _progress;
  Cancellation? _cancellation;

  /// The work, or `null` while it has not arrived or no longer exists.
  Ebook? get ebook => _ebook;

  /// Whether the first answer has come back.
  ///
  /// It is what separates *not yet* from *not here*: a screen opened at a
  /// location the reader typed has neither, and telling them the book was
  /// deleted before the query has run would be a lie a frame long.
  bool get isLoaded => _loaded;

  /// Where the bytes are.
  ContentState get content => _state;

  /// The shelves this work is filed under.
  List<Collection> get collections => _collections;

  /// Every shelf the reader has, which is what the chooser offers.
  ///
  /// It is a second stream over the same table and not a filter of the first:
  /// the first answers *where is this book*, and a chooser needs *where could
  /// it go*. Deriving one from the other would need the whole collection and a
  /// join this screen has no reason to run.
  List<Collection> get allCollections => _all;

  /// Whether this work is filed under [collectionId].
  bool isFiledUnder(String collectionId) =>
      _collections.any((Collection shelf) => shelf.id == collectionId);

  /// The cover this device extracted, or `null`.
  EpubCover? get cover => _cover;

  /// How far a download in flight has got, or `null`.
  DownloadProgress? get progress => _progress;

  /// Gives up on a download in flight.
  void cancelDownload() => _cancellation?.cancel();

  @override
  void dispose() {
    // A download in flight outlives nothing: the screen is going away and the
    // staged object goes with it, because a fragment has no name in a store
    // keyed by what the bytes are.
    _cancellation?.cancel();
    unawaited(_work.cancel());
    unawaited(_content.cancel());
    unawaited(_shelves.cancel());
    unawaited(_allShelves.cancel());
    // The commands are disposed with the model, `restore` included: it may be
    // run after this point, and a disposed command runs and keeps its result.
    save.dispose();
    delete.dispose();
    restore.dispose();
    file.dispose();
    keep.dispose();
    release.dispose();
    download.dispose();
    super.dispose();
  }

  Future<Result<void>> _keep() => _fetching(
    (Cancellation cancel) =>
        library.keepEbook(ebookId, cancel: cancel, onProgress: _onProgress),
  );

  Future<Result<void>> _download() async {
    final result = await _fetching(
      (Cancellation cancel) async => switch (await library.downloadEbook(
        ebookId,
        cancel: cancel,
        onProgress: _onProgress,
      )) {
        Ok<EbookContent>() => const Result<void>.ok(null),
        Error<EbookContent>(:final error) => Result<void>.error(error),
      },
    );

    return result;
  }

  /// Runs [transfer] under a cancellation the screen can raise.
  Future<Result<void>> _fetching(
    Future<Result<void>> Function(Cancellation cancel) transfer,
  ) async {
    final cancel = Cancellation();

    _cancellation = cancel;

    try {
      return await transfer(cancel);
    } finally {
      _cancellation = null;
      _progress = null;
      notifyListeners();
    }
  }

  Future<void> _onProgress(DownloadProgress progress) async {
    _progress = progress;
    notifyListeners();
  }

  Future<void> _loadCover() async {
    if (await library.cover(ebookId) case Ok<EpubCover?>(:final value)) {
      _cover = value;
      notifyListeners();
    }
  }

  void _onWork(Result<Ebook?> result) {
    switch (result) {
      case Ok<Ebook?>(:final value):
        final arrived = _ebook == null && value != null;

        _ebook = value;
        _loaded = true;

        // The file may have arrived with the row, on a device that was seeded
        // or synchronized: the cover is extracted from a file this device
        // holds, so it is worth asking again once there is a work to ask about.
        if (arrived && _cover == null) {
          unawaited(_loadCover());
        }
      case Error<Ebook?>(:final error):
        _log.warning('the work $ebookId could not be read', error);
        _loaded = true;
    }

    notifyListeners();
  }

  void _onContent(Result<ContentState> result) {
    if (result case Ok<ContentState>(:final value)) {
      final arrived = !_state.onThisDevice && value.onThisDevice;

      _state = value;

      // A cover is extracted from the file, so the moment the bytes land there
      // may be one to read.
      if (arrived && _cover == null) {
        unawaited(_loadCover());
      }

      notifyListeners();
    }
  }

  void _onAllShelves(Result<List<Collection>> result) {
    if (result case Ok<List<Collection>>(:final value)) {
      _all = value;
      notifyListeners();
    }
  }

  void _onShelves(Result<List<Collection>> result) {
    if (result case Ok<List<Collection>>(:final value)) {
      _collections = value;
      notifyListeners();
    }
  }
}

extension on Future<Result<void>> Function(String) {
  /// The call, bound to one work, so that a `Command0` can be built from it.
  Future<Result<void>> Function() of(String ebookId) =>
      () => this(ebookId);
}

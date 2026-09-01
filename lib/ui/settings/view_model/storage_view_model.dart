/// What the storage section knows.
///
/// It is the reader's answer to *is this book here when the network is not*,
/// asked once per book and shown against a budget where there is one. The
/// section exists on all six targets and says different things on two of them,
/// which is the same mechanism with two defaults rather than two features:
/// a native install keeps everything and offers to release, a browser keeps
/// nothing until asked.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/library_repository.dart';
import '../../../data/services/storage/blob_storage.dart';
import '../../../domain/models/ebook.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The state of the storage section.
final class StorageViewModel extends ChangeNotifier {
  /// The view model over [library].
  StorageViewModel({required this.library}) {
    release = Command1<void, String>(_release);
    _kept = library.watchKeptEbooks().listen(_onKept);
    refresh = Command0<StorageBudget>(_read)..execute();
  }

  /// Where the files and the decisions live.
  final LibraryRepository library;

  /// Reads what the store holds and may hold.
  ///
  /// It is a command that is executed rather than a stream, because the answer
  /// comes from the platform and not from a table: a browser is asked
  /// `navigator.storage.estimate()` and there is nothing to watch. It is run
  /// again after a release, which is the only thing on this screen that
  /// changes the number.
  late final Command0<StorageBudget> refresh;

  /// Stops keeping one work's file.
  late final Command1<void, String> release;

  late final StreamSubscription<Result<List<Ebook>>> _kept;

  StorageBudget _budget = StorageBudget.unknown;
  List<Ebook> _books = const <Ebook>[];

  /// What the store holds, and may hold where anything can say.
  StorageBudget get budget => _budget;

  /// The works whose files this device is holding.
  List<Ebook> get books => _books;

  @override
  void dispose() {
    unawaited(_kept.cancel());
    super.dispose();
  }

  Future<Result<StorageBudget>> _read() async {
    final result = await library.storage();

    if (result case Ok<StorageBudget>(:final value)) {
      _budget = value;
    }

    return result;
  }

  Future<Result<void>> _release(String ebookId) async {
    final result = await library.releaseEbook(ebookId);

    // The number is read again rather than adjusted by the size of what was
    // released: a store that deduplicates has no obligation to shrink by what
    // a caller thought it was giving back, and a screen that did the
    // subtraction itself would be a second accounting of the same disk.
    await refresh.execute();

    return result;
  }

  void _onKept(Result<List<Ebook>> result) {
    if (result case Ok<List<Ebook>>(:final value)) {
      _books = value;
      notifyListeners();
    }
  }
}

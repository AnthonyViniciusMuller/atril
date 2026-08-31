/// The storage budget in a browser, which is the one that is spent.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../../utils/logging.dart';
import 'blob_store.dart';
import 'storage_budget.dart';

final _log = loggerFor('data/storage');

/// What the origin is holding and what the browser will let it hold.
///
/// The usage reported here is the browser's, not the store's, and the two are
/// deliberately different numbers: the browser counts everything this origin
/// keeps — the replica, the WebAssembly build of sqlite, the app itself — and
/// that is what its quota is measured against. A budget that showed only the
/// books would tell a reader they have room they do not have.
///
/// A browser that answers neither is reported as unmeasured rather than as
/// empty. Nothing then refuses a download that the browser itself has not
/// refused, which is the only honest thing to do with a number nobody gave.
Future<StorageBudget> readStorageBudget(BlobStore store) async {
  try {
    final estimate = await web.window.navigator.storage.estimate().toDart;

    return StorageBudget(
      used: estimate.usage,
      quota: estimate.quota == 0 ? null : estimate.quota,
    );
  } on Object catch (failure) {
    _log.warning('this browser did not answer for its storage', failure);

    return StorageBudget(used: await store.usedBytes());
  }
}

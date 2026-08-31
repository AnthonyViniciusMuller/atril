/// The database in a browser.
///
/// A browser has no file to open, so drift runs sqlite compiled to WebAssembly
/// in a worker over a virtual file system — the origin-private one where it
/// exists, IndexedDB where it does not. Both of those need two files served
/// beside the app, and the commit that adds them is the one that writes this
/// connection.
///
/// Until then this is a placeholder rather than a fallback. An in-memory
/// database would be worse than nothing: the web build would open, the reader
/// would import a book, and the replica would be gone at the next reload with
/// no error anywhere. Failing to open says what is missing.
library;

import 'package:drift/drift.dart';

/// The name of the database, which on the web is a name and not a path.
const String defaultDatabaseName = 'atril';

/// Refuses to open, because the worker assets are not here yet.
QueryExecutor openConnection({String name = defaultDatabaseName}) {
  throw UnsupportedError(
    'the web build has no local replica until sqlite3.wasm and '
    'drift_worker.js are served beside it',
  );
}

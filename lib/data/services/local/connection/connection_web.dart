/// The database in a browser: sqlite compiled to WebAssembly, over whichever
/// virtual file system this browser can offer.
///
/// There is no file to open, so drift probes what the browser has and picks
/// the most durable of four backings — the origin-private file system in a
/// shared worker, the same file system without one, IndexedDB, and memory —
/// then keeps whichever one an existing database was already written with, so
/// that a browser update does not strand a reader's replica in a store nothing
/// reads any more.
///
/// Two of those four are not storage a reader should be told nothing about.
/// IndexedDB without the locks that make it safe across tabs can lose the last
/// writes of a session, and memory loses everything at the next reload, so the
/// choice is reported here rather than discovered — and [replicaIsDurable] is
/// what the offline-pinning screen of phase 8 asks before promising a reader
/// that a book will still be there. The five native targets answer the same
/// two questions from their own file, so nothing above this directory has to
/// know which of them replied.
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../../../../utils/logging.dart';

final _log = loggerFor('data/local');

/// The name of the database, which in a browser is a name and not a path.
const String defaultDatabaseName = 'atril';

/// Where the WebAssembly build of sqlite is served from, relative to the page.
///
/// It is served beside the app and never fetched from a CDN, for the reason
/// the roadmap gives about the reader: a build that reaches the network to
/// open its own database is a build that cannot open it on a train.
final Uri _sqlite3Uri = Uri.parse('sqlite3.wasm');

/// Where drift's worker is served from. It has to be the file built from the
/// same drift release as the package: `make web-assets` refreshes both, and
/// `make web-assets-check` is what fails when only one of them moved.
final Uri _driftWorkerUri = Uri.parse('drift_worker.js');

/// What is holding the replica, named as drift names it, or `unopened` before
/// the first connection.
String get replicaStorage => _storage?.name ?? 'unopened';

/// Whether what it gave survives a reload.
///
/// It is false in memory, and false for the IndexedDB implementation drift
/// marks unsafe: that one is a store shared between tabs with no lock over it,
/// so a second tab can drop writes the reader watched land in the first.
bool get replicaIsDurable => switch (_storage) {
  WasmStorageImplementation.opfsShared ||
  WasmStorageImplementation.opfsLocks ||
  WasmStorageImplementation.sharedIndexedDb => true,
  WasmStorageImplementation.unsafeIndexedDb ||
  WasmStorageImplementation.inMemory ||
  null => false,
};

WasmStorageImplementation? _storage;

/// The local replica, opened over the most durable storage this browser has.
QueryExecutor openConnection({String name = defaultDatabaseName}) {
  return LazyDatabase(() async {
    final opened = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: _sqlite3Uri,
      driftWorkerUri: _driftWorkerUri,
      // A reader whose browser learned the origin-private file system between
      // two visits should have their replica moved into it, rather than left
      // in the store that was second best when they first opened the app.
      moveExistingIndexedDbToOpfs: true,
    );

    _storage = opened.chosenImplementation;

    if (replicaIsDurable) {
      _log.fine('the local replica is on ${opened.chosenImplementation.name}');
    } else {
      _log.warning(
        'this browser cannot store the local replica durably: '
        '${opened.chosenImplementation.name}, missing '
        '${opened.missingFeatures.map((feature) => feature.name).join(', ')}',
      );
    }

    return opened.resolvedExecutor;
  });
}

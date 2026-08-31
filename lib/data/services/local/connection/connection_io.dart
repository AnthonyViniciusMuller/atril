/// The database on the five native targets: a file in the directory the
/// platform sets aside for application data.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../utils/logging.dart';

final _log = loggerFor('data/local');

/// The name of the file, without its extension.
const String defaultDatabaseName = 'atril';

/// The local replica, opened lazily on a background isolate.
///
/// Three decisions are worth stating.
///
/// It is *application support* and not *documents*. The replica is this app's
/// working state and not a document the reader is meant to find, browse or
/// hand to another program; on iOS and macOS the documents directory is
/// exactly that, and on Android it is shared storage. A device that put its
/// database there would be inviting a file manager to delete half of a
/// reader's library.
///
/// It is opened on a background isolate. Every query this app makes is on the
/// path of a frame — the library grid, the reader's own position, the sync
/// loop writing while a page scrolls — and drift's own isolate is what keeps
/// the I/O off the thread drawing them.
///
/// The temporary directory is handed to sqlite explicitly. Android does not
/// give a process a writable `/tmp`, so sqlite falls back to one it cannot
/// write and reports `SQLITE_IOERR_GETTEMPPATH` from whichever statement first
/// needed to spill — a vacuum, a large sort, a `WAL` checkpoint. It is set
/// inside the isolate because that is where the statement runs.
QueryExecutor openConnection({String name = defaultDatabaseName}) {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(path.join(directory.path, '$name.sqlite'));
    final temporary = (await getTemporaryDirectory()).path;

    await file.parent.create(recursive: true);
    _log.fine('opening the local replica at ${file.path}');

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: () async => sqlite3.tempDirectory = temporary,
    );
  });
}

/// What is holding the replica. On a native target it is a file, and there is
/// nothing further to say about it.
String get replicaStorage => 'file';

/// Whether the replica survives being closed and reopened.
///
/// It always does here. The counterpart in `connection_web.dart` is where the
/// answer can be no, and this getter exists so that a caller — the offline
/// pinning of phase 8 — asks the question once rather than asking whether it
/// is running in a browser.
bool get replicaIsDurable => true;

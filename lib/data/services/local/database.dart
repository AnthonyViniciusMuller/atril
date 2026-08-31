/// The local replica: the one place in the app that holds the reader's
/// collection.
///
/// Everything a reader sees is read from here, and every change they make is
/// written here first. That is not a cache and it is not an optimization; it
/// is the mechanism, for the reason
/// [`architecture.md`](../../../../docs/architecture.md) sets out under C21 —
/// a change made through the node's write RPCs appends nothing to the log and
/// therefore reaches no other replica, while the same change authored here and
/// pushed reaches all of them.
///
/// The tables arrive over the commits that follow this one: identity, the
/// library, what the reader wrote and where they stopped, the log this device
/// owes, and the causal state that makes authoring the next change correct.
/// What this file holds is the part that is true of all of them — the version
/// the schema is at, how it gets there, and what is switched on before the
/// first statement runs.
library;

import 'package:drift/drift.dart';

import 'connection/connection.dart';

part 'database.g.dart';

/// The reader's replica.
///
/// It is constructed with an executor rather than opening one itself, so that
/// a test can hand it an in-memory database and the entry point can hand it
/// the platform's. The default is what the platform gives.
@DriftDatabase(tables: <Type>[])
class AtrilDatabase extends _$AtrilDatabase {
  /// The replica over [executor], or over the platform's own connection.
  AtrilDatabase([QueryExecutor? executor])
    : super(executor ?? openConnection());

  /// The version of the schema this build expects.
  ///
  /// It stays at one for the whole of the phase that builds the schema up. A
  /// version number is a promise to a database that already exists somewhere,
  /// and until this app has been installed by anybody there is no such
  /// database: bumping it per table would record a migration path nothing has
  /// ever travelled and that would have to be maintained afterwards.
  @override
  int get schemaVersion => 1;

  /// How the schema is created, how it moves between versions, and what is
  /// switched on for every connection.
  ///
  /// `foreign_keys` is off by default in sqlite and has to be asked for on
  /// every connection, not once per database. The replica leans on it: an
  /// annotation names a work, a filing names both halves of the pair it is,
  /// and a delete that cascades is the only thing that keeps a removed work
  /// from leaving rows nothing can reach. It is set outside a transaction,
  /// because sqlite ignores the pragma inside one.
  ///
  /// The upgrade path refuses rather than guesses. There is no released
  /// version below this one, so a database that claims to be at one is a file
  /// this app did not write, and creating tables over it would produce a
  /// replica that is half somebody else's.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      throw StateError(
        'the local replica is at schema version $from and this build expects '
        '$to, which is a database this app did not write',
      );
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

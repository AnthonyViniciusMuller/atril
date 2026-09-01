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
/// The tables arrive over the commits of this phase: identity, the
/// library, what the reader wrote and where they stopped, the log this device
/// owes, and the causal state that makes authoring the next change correct.
/// What this file holds is the part that is true of all of them — the version
/// the schema is at, how it gets there, and what is switched on before the
/// first statement runs.
library;

import 'package:drift/drift.dart';

import '../../../utils/logging.dart';

// The generated part of this library names the types the converters in
// `converters.dart` map columns onto, so their imports belong here rather than
// only where the tables declare them.
import '../../../domain/crdt/vector_clock.dart';
import 'connection/connection.dart';
import 'converters.dart';
import 'dao/identity_dao.dart';
import 'dao/library_dao.dart';
import 'dao/records_dao.dart';
import 'dao/sync_dao.dart';
import 'tables/covers.dart';
import 'tables/identity.dart';
import 'tables/library.dart';
import 'tables/reading.dart';
import 'tables/records.dart';
import 'tables/sync.dart';

part 'database.g.dart';

final _log = loggerFor('data/local');

/// The reader's replica.
///
/// It is constructed with an executor rather than opening one itself, so that
/// a test can hand it an in-memory database and the entry point can hand it
/// the platform's. The default is what the platform gives.
@DriftDatabase(
  tables: <Type>[
    BoundDevice,
    SignedInReader,
    KnownServers,
    ClockFloor,
    Ebooks,
    Collections,
    EbookCollections,
    EbookCovers,
    Annotations,
    Progress,
    PendingOperations,
    NodeCursors,
    AppliedOperations,
    RecordVersions,
  ],
  daos: <Type>[IdentityDao, LibraryDao, SyncDao, RecordsDao],
)
class AtrilDatabase extends _$AtrilDatabase {
  /// The replica over [executor], or over the platform's own connection.
  AtrilDatabase([QueryExecutor? executor])
    : super(executor ?? openConnection());

  /// The version of the schema this build expects.
  ///
  /// It stayed at one for the whole of the phase that built the schema up: a
  /// version number is a promise to a database that already exists somewhere,
  /// and while the tables of one phase were still arriving there was no such
  /// database to promise anything to.
  ///
  /// There is one now — every development install made while that phase was
  /// worked — and the library adds tables of its own to it. So the number
  /// starts moving here, one step per table, and each step is exactly what
  /// [migration] says it is.
  @override
  int get schemaVersion => 2;

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
  /// **Every version so far only adds.** No column has been dropped, renamed
  /// or retyped since version one, and every table added since is one this
  /// device keeps for itself — a cover it extracted, a transfer it is part way
  /// through, a book it was told to keep. So the upgrade is `createAll`, whose
  /// statements are `CREATE TABLE IF NOT EXISTS`: it builds what is missing
  /// and touches nothing that is there, which is the whole of the difference
  /// between one version and the next.
  ///
  /// It is written this way deliberately rather than as a `case` per step. A
  /// switch would claim there is a decision to make at each version, and there
  /// is not — the day a column changes, this becomes a stepped migration and
  /// the change is visible in the diff instead of hidden in a branch nobody
  /// took.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      _log.info('the local replica moves from schema version $from to $to');

      await m.createAll();
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

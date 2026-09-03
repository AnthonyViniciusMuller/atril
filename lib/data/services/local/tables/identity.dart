/// Who this device is, who is signed in on it, and the nodes it knows about.
///
/// Nothing in this file replicates. These four tables are the device's own
/// state — the identity its vector-clock entries are counted under, the reader
/// whose collection the replica holds, the catalogue the federation is reached
/// through, and the floor the hybrid clock resumes from — and none of them
/// appears in an operation or in the contract's `TargetEntity`.
///
/// Two of the four are a single row, and say so in SQL rather than by
/// convention: a device has one identity and one reader signed in at a time,
/// and a second row would be a state nothing in the app knows how to read.
///
/// The row classes are suffixed `Row`. A row is what the database returns, and
/// the domain model of the same thing is a different type that arrives with the
/// repository that maps it; keeping the two names apart is what stops a widget
/// from being handed a table.
library;

import 'package:drift/drift.dart';

import '../converters.dart';

/// The key of the row a single-row table holds.
///
/// It is written explicitly on every insert rather than defaulted, because
/// sqlite would not apply the default: an `INTEGER PRIMARY KEY` column is an
/// alias for the rowid, so a row inserted without one is given the next rowid
/// — one, not zero — and the constraint below would refuse it. The check is
/// what makes the second row impossible; this is what makes the first one
/// legal.
const int singleRow = 0;

/// The identity this device writes under, and the key its vector-clock entries
/// are counted by.
///
/// **It survives logout.** That is the rule this table exists to enforce and
/// the reason it references nothing: a device that forgot its identifier and
/// asked the node for a new one would start a second clock entry that never
/// merges with the first, and every write it had already authored would be
/// attributed to a device nothing has heard of. Logging out clears the session
/// and the session alone — this row and the replica stay.
@DataClassName('BoundDeviceRow')
class BoundDevice extends Table {
  /// The single row, spelled as a column so that sqlite is what refuses a
  /// second one. See [singleRow].
  IntColumn get onlyRow => integer()();

  /// The identifier the node minted when this device was bound, in canonical
  /// lowercase text. It is the key of this device's entry in every vector
  /// clock in the replica.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// What the reader calls this device, as it was sent at binding.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// `android`, `ios`, `web`, `linux`, `macos` or `windows`. It is free-form in
  /// the contract on purpose, so that a seventh does not need the node
  /// redeployed, and it is free-form here for the same reason.
  TextColumn get platform => text().withLength(min: 1, max: 40)();

  /// When the binding happened. A wall clock reading, shown to a reader on the
  /// device screen and never compared against a hybrid one.
  IntColumn get boundAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{onlyRow};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (only_row = 0)',
    "CHECK (id = lower(id))",
  ];
}

/// The reader signed in on this device.
///
/// It is a single row because the app has one signed-in reader, and it is kept
/// through a logout for the same reason the device is: the replica it describes
/// is still here, and a reader who signs back in on the same device should find
/// their library rather than an empty one.
@DataClassName('ReaderRow')
class SignedInReader extends Table {
  /// The single row. See [singleRow].
  IntColumn get onlyRow => integer()();

  /// The reader's identifier at their origin node, in canonical lowercase text.
  TextColumn get id => text().withLength(min: 36, max: 36)();

  /// The first half of the federated identifier, constrained by the node to
  /// `^[a-z0-9]([a-z0-9._-]{0,62}[a-z0-9])?$`. It is not re-checked here: the
  /// node is what admits a name, and a device that refused one the node had
  /// accepted could not store the reader it is signed in as.
  TextColumn get localName => text().withLength(min: 1, max: 64)();

  /// What the reader calls themselves, and the only name meant to be shown.
  TextColumn get displayName => text().withLength(min: 1, max: 120)();

  /// The node that authenticates this reader (RN08), which is the second half
  /// of their identifier.
  ///
  /// It is the domain and not an identifier, because the domain is what this
  /// device can always know: it is what the reader typed, what the `.well-known`
  /// lookup was addressed to, and what `LoginResponse.User.origin_server_domain`
  /// answers with. See [KnownServers.domain].
  TextColumn get originServerDomain =>
      text().references(KnownServers, #domain, onDelete: KeyAction.restrict)();

  /// `@local_name:domain`, as the node assembled it. It is stored rather than
  /// composed here so that every client renders the identifier the same way.
  TextColumn get federatedId => text().withLength(min: 3, max: 320)();

  /// Absent on a node that only replicates this reader, and absent from every
  /// reply but their own (RN09, C03).
  TextColumn get email => text().withLength(max: 255).nullable()();

  /// When the account was created, as the node reports it.
  IntColumn get createdAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{onlyRow};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (only_row = 0)',
    "CHECK (id = lower(id))",
  ];
}

/// The nodes this device knows how to reach.
///
/// It is the catalogue UC12 shows and the discovery document writes into: one
/// row per federation domain, holding what `ServerDescriptor` publishes about
/// it. A node is here because the reader added it, because it is where they are
/// signed in, or because it replicates them.
///
/// The certificate fingerprint is stored even though this device never presents
/// one. It is a digest of the public key rather than of the certificate (C12),
/// it is what a *peer* pins for node-to-node mTLS, and the known-servers screen
/// shows it so that a reader authorizing a replica can see what they are
/// authorizing and notice when it rotates.
@DataClassName('ServerRow')
@TableIndex.sql(
  // At most one node may be the origin, and sqlite is what says so. A device
  // with two would have two answers to the second half of the reader's own
  // identifier.
  //
  // `IF NOT EXISTS`, because the schema's upgrade is `createAll` and drift
  // adds the clause to tables and views and not to indexes: an index issued
  // without it fails the upgrade of every database that already has it, which
  // is every database that was ever at version one.
  'CREATE UNIQUE INDEX IF NOT EXISTS known_servers_origin '
  'ON known_servers (is_origin) WHERE is_origin',
)
class KnownServers extends Table {
  /// The federation domain, which is the authority a lookup is addressed to,
  /// the second half of every identifier hosted there, and the key this device
  /// addresses a node by.
  ///
  /// It is the primary key and the node's own identifier is not, because a node
  /// discovered directly has no identifier to be keyed by: the client discovery
  /// document publishes `base_url` and `grpc` and nothing else, and the id in
  /// `federation.servers` is a value only the node itself can report. The domain
  /// is what a reader types, what the lookup is addressed to and what every
  /// federated identifier carries, so it is the one name for a node that exists
  /// at every point in this app's life.
  TextColumn get domain => text().withLength(min: 1, max: 255)();

  /// The identifier the node calls itself by, once something has heard it say
  /// so.
  ///
  /// It is null on a node this device discovered for itself and is filled in by
  /// `ListKnownServers`, which is the only call that reports it. It is
  /// provenance rather than an address: nothing here resolves a node by it, and
  /// a node that answered with a different one would be a node that had been
  /// reinstalled rather than a second node.
  TextColumn get remoteId => text().withLength(min: 36, max: 36).nullable()();

  /// Where the node answers, which is deliberately separate from the domain: a
  /// node may be identified by one host and served from another.
  TextColumn get baseUrl => text().withLength(min: 1, max: 255)();

  /// Where it publishes the keys its tokens are signed with.
  TextColumn get jwksUri => text().withLength(max: 255).nullable()();

  /// `spki-sha256:<base64>`, the key a peer pins. Absent on a node whose
  /// document publishes none.
  TextColumn get certificateFingerprint =>
      text().withLength(max: 128).nullable()();

  /// The authority to dial for gRPC, as `host:port`.
  ///
  /// It is published separately from the base URL because the two are only the
  /// same address where a gateway collapses them (D06). It is absent on a node
  /// this device can record and cannot dial — and, on the web, it is not what
  /// is dialled at all: a browser reaches the gateway the environment names,
  /// because this authority is the one a *peer* dials for replication.
  TextColumn get grpcAuthority => text().withLength(max: 255).nullable()();

  /// Whether this is the node the reader is signed in at.
  BoolColumn get isOrigin => boolean().withDefault(const Constant(false))();

  /// When this device last read the node's discovery document. A key that has
  /// rotated is found by asking again, and this is what says how long ago that
  /// was.
  IntColumn get discoveredAt =>
      integer().map(const InstantConverter()).nullable()();

  /// False once the reader has removed the node from their catalogue. The row
  /// stays either way, because a revoked replica that still holds a copy is
  /// something the reader should keep being able to see.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{domain};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (domain = lower(domain))",
    "CHECK (remote_id IS NULL OR remote_id = lower(remote_id))",
  ];
}

/// The floor this device's hybrid logical clock resumes from.
///
/// Phase 2 left it behind the `HybridClockStore` port for exactly this: a stamp
/// is synchronous and a database is not, so the clock reads the floor once at
/// startup and writes it behind each stamp. This is the row it writes to.
///
/// The node's own clock keeps its floor in memory and argues that a restart is
/// survivable because the per-record floor still holds. A phone restarts far
/// more often than a node and authors operations other replicas will order
/// against, so this device persists it and begins a launch having observed what
/// it had observed.
@DataClassName('ClockFloorRow')
class ClockFloor extends Table {
  /// The single row. See [singleRow].
  IntColumn get onlyRow => integer()();

  /// The greatest instant this device has stamped or seen.
  IntColumn get observedAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{onlyRow};

  @override
  List<String> get customConstraints => <String>['CHECK (only_row = 0)'];
}

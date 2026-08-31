/// Reading and writing the four tables that say who this device is.
library;

import 'package:drift/drift.dart';

import '../../../../domain/models/server.dart';
import '../database.dart';
import '../tables/identity.dart';

part 'identity_dao.g.dart';

/// The device's own identity, the reader signed in on it, the catalogue of
/// nodes, and the hybrid clock's floor.
///
/// It is one accessor over four tables because the four are one question —
/// *whose device is this and what can it reach* — and because three of them are
/// written together exactly once, when a device is bound: the node it was bound
/// at, the reader it was bound for, and the identity it was given.
@DriftAccessor(
  tables: <Type>[BoundDevice, SignedInReader, KnownServers, ClockFloor],
)
class IdentityDao extends DatabaseAccessor<AtrilDatabase>
    with _$IdentityDaoMixin {
  /// The accessor over [database].
  IdentityDao(super.database);

  /// This device's identity, or `null` on a device that has never been bound.
  Future<BoundDeviceRow?> device() => select(boundDevice).getSingleOrNull();

  /// [device], as it changes.
  Stream<BoundDeviceRow?> watchDevice() =>
      select(boundDevice).watchSingleOrNull();

  /// The identifier this device's vector-clock entries are counted under.
  ///
  /// Everything that authors a change asks for this, and a device that answers
  /// `null` is a device that must not author one: an operation carrying no
  /// author is refused by the node (RN10) and, worse, would be a clock entry
  /// nothing could attribute.
  Future<String?> deviceId() async => (await device())?.id;

  /// Records the identity the node gave this device at binding.
  ///
  /// It overwrites, because a device is bound once and rebinding under a
  /// different identifier is the failure this row exists to prevent — the
  /// caller passes the identifier it already had, and the node returns the
  /// same one.
  Future<void> bindDevice({
    required String id,
    required String name,
    required String platform,
    required DateTime at,
  }) => into(boundDevice).insertOnConflictUpdate(
    BoundDeviceCompanion.insert(
      onlyRow: const Value<int>(singleRow),
      id: id.toLowerCase(),
      name: name,
      platform: platform,
      boundAt: at,
    ),
  );

  /// The reader signed in on this device, or `null` before the first login.
  ///
  /// A logout does not clear it. The replica it describes is still here, and a
  /// reader signing back in on the same device should find their library
  /// rather than an empty one.
  Future<ReaderRow?> reader() => select(signedInReader).getSingleOrNull();

  /// [reader], as it changes.
  Stream<ReaderRow?> watchReader() =>
      select(signedInReader).watchSingleOrNull();

  /// Records the reader this device is signed in as.
  Future<void> rememberReader({
    required String id,
    required String localName,
    required String displayName,
    required String originServerDomain,
    required String federatedId,
    required DateTime createdAt,
    String? email,
  }) => into(signedInReader).insertOnConflictUpdate(
    SignedInReaderCompanion.insert(
      onlyRow: const Value<int>(singleRow),
      id: id.toLowerCase(),
      localName: localName,
      displayName: displayName,
      originServerDomain: originServerDomain.toLowerCase(),
      federatedId: federatedId,
      createdAt: createdAt,
      email: Value<String?>(email),
    ),
  );

  /// Every node in the catalogue, the reader's own first and the rest by
  /// domain.
  Future<List<ServerRow>> servers() => _catalogue().get();

  /// [servers], as they change.
  Stream<List<ServerRow>> watchServers() => _catalogue().watch();

  /// The node hosting the reader signed in here, or `null` before the first
  /// login.
  Future<ServerRow?> originServer() => (select(
    knownServers,
  )..where((server) => server.isOrigin)).getSingleOrNull();

  /// The node this device knows at [domain], or `null` for one it has never
  /// discovered.
  Future<ServerRow?> server(String domain) =>
      (select(knownServers)..where(
            (server) => server.domain.equals(canonicalServerDomain(domain)),
          ))
          .getSingleOrNull();

  /// Records what a discovery document said about a node.
  ///
  /// The domain is the key, so a document read twice updates one row rather
  /// than adding a second.
  Future<void> rememberServer(ServerRow server) =>
      into(knownServers).insertOnConflictUpdate(server);

  /// Records what [descriptor] said about a node, keeping what this device
  /// already knew that the document does not carry.
  ///
  /// The client document publishes `base_url` and `grpc` and nothing else, so a
  /// re-discovery must not clear the fingerprint, the keys or the node's own
  /// identifier: those come from `ListKnownServers`, they are still true, and a
  /// lookup that wiped them would be this device forgetting what it was told by
  /// reading something that was never going to mention it.
  Future<void> rememberDescriptor(
    ServerDescriptor descriptor, {
    required DateTime at,
  }) => into(knownServers).insert(
    KnownServersCompanion.insert(
      domain: canonicalServerDomain(descriptor.domain),
      baseUrl: descriptor.baseUrl,
      grpcAuthority: Value<String?>(descriptor.grpcAuthority),
      jwksUri: Value<String?>(descriptor.jwksUri),
      certificateFingerprint: Value<String?>(descriptor.certificateFingerprint),
      discoveredAt: Value<DateTime>(at),
    ),
    onConflict: DoUpdate<$KnownServersTable, ServerRow>(
      (_) => KnownServersCompanion(
        baseUrl: Value<String>(descriptor.baseUrl),
        grpcAuthority: Value<String?>(descriptor.grpcAuthority),
        discoveredAt: Value<DateTime>(at),
        active: const Value<bool>(true),
      ),
    ),
  );

  /// Makes the node at [domain] the one the reader is signed in at, and no
  /// other.
  ///
  /// The two writes are one transaction because the index that keeps a device
  /// from having two origins would refuse the second of them on its own.
  Future<void> markOrigin(String domain) => transaction(() async {
    await (update(knownServers)..where((server) => server.isOrigin)).write(
      const KnownServersCompanion(isOrigin: Value<bool>(false)),
    );

    await (update(knownServers)..where(
          (server) => server.domain.equals(canonicalServerDomain(domain)),
        ))
        .write(const KnownServersCompanion(isOrigin: Value<bool>(true)));
  });

  /// The greatest instant this device had observed when it last ran, or `null`
  /// on a device that has never run.
  Future<DateTime?> loadClockFloor() async =>
      (await select(clockFloor).getSingleOrNull())?.observedAt;

  /// Records [instant] as the floor the clock resumes from.
  Future<void> saveClockFloor(DateTime instant) =>
      into(clockFloor).insertOnConflictUpdate(
        ClockFloorCompanion.insert(
          onlyRow: const Value<int>(singleRow),
          observedAt: instant,
        ),
      );

  /// The catalogue in the order it is shown: the reader's own node first,
  /// because it is the one they are named at, and the rest by domain.
  SimpleSelectStatement<$KnownServersTable, ServerRow> _catalogue() =>
      select(knownServers)..orderBy(<OrderClauseGenerator<$KnownServersTable>>[
        (server) =>
            OrderingTerm(expression: server.isOrigin, mode: OrderingMode.desc),
        (server) => OrderingTerm(expression: server.domain),
      ]);
}

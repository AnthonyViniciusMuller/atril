/// The hybrid clock's floor, in the local database.
library;

import '../../../domain/crdt/hybrid_clock.dart';
import 'dao/identity_dao.dart';

/// [HybridClockStore] over the row the identity tables set aside for it.
///
/// Phase 2 declared the port and left the implementation for the schema, for a
/// reason worth restating where it is finally filled in: stamping is
/// synchronous — it happens in the middle of authoring an operation and cannot
/// await anything — while a database is not. So the clock reads the floor once
/// at startup through [load] and writes it behind each stamp through [save],
/// and neither call is on the path of a write.
///
/// It is a class of its own rather than a method pair on the DAO because the
/// port belongs to `domain/crdt` and the DAO belongs to the database. This is
/// the adapter between them, and it holds nothing else.
final class LocalHybridClockStore implements HybridClockStore {
  /// The store over [identity].
  const LocalHybridClockStore(this._identity);

  final IdentityDao _identity;

  @override
  Future<DateTime?> load() => _identity.loadClockFloor();

  @override
  Future<void> save(DateTime instant) => _identity.saveClockFloor(instant);
}

/// Emptying the replica of a device that has changed hands.
///
/// It is the exact counterpart of [`seed.dart`](seed.dart), and it exists for
/// the one thing that file's rule does not cover. The replica deliberately
/// survives a logout — a reader who signs back in on the same device should
/// find their library rather than an empty one — and that is right for exactly
/// as long as it is the *same* reader. When somebody else signs in on this
/// device, every row here was written for a person who is not in front of it,
/// and leaving them would show one reader another reader's books.
///
/// **What goes.** The reader's collection, everything this device wrote about
/// it, the log it owes about it, the causal state that log is ordered by, and
/// the files themselves. Nothing here belongs to a device; all of it belongs to
/// the reader whose session just ended for good.
///
/// **What stays, and why.** The catalogue of nodes is a directory of servers
/// rather than a fact about a reader: it holds what discovery documents and
/// `ListKnownServers` published — addresses, keys, fingerprints — it is
/// re-mirrored from the node on every visit to the federation screen, and the
/// row the arriving reader's own origin needs is very likely already one of
/// them. The hybrid clock's floor stays because it is a promise this *device*
/// made about instants it has already stamped, and moving it backwards would
/// let the next stamp repeat one. The device's binding stays because the
/// sign-in that calls this overwrites it a moment later with the identifier
/// the node just minted.
///
/// **The bytes go too, and that is not a silent eviction.** `BlobStore.remove`
/// carries a rule — nothing in this app evicts a book without the reader
/// asking — and the rule is about a library staying whole under its owner's
/// feet. This is the other case: the owner is gone, the rows naming these
/// digests have just been deleted, and what would be left is an unreachable
/// copy of somebody else's books on a device they no longer have.
library;

import '../../../utils/logging.dart';
import '../local/database.dart';
import '../storage/blob_storage.dart';

final _log = loggerFor('data/sync');

/// What empties the replica of a device a different reader is signing in on.
///
/// It is a port for the same reason `ReplicaSeed` is one: the sign-in that
/// calls it is what a test wants to watch, and a test should be able to see
/// that the erasure happened without a filesystem behind it.
abstract interface class ReplicaErasure {
  /// Removes the reader's collection, the log about it, and its files.
  Future<void> erase();
}

/// Empties the replica.
final class ReplicaEraser implements ReplicaErasure {
  /// The eraser over [database] and [blobs].
  ReplicaEraser({required this.database, required this.blobs});

  /// The replica being emptied.
  final AtrilDatabase database;

  /// Where the books themselves are.
  final BlobStore blobs;

  @override
  Future<void> erase() async {
    // One transaction, because a replica half emptied is worse than either
    // end of it: the arriving reader would see some of the previous reader's
    // shelves and none of the operations that explain them.
    //
    // The order is children before parents. Every one of these foreign keys
    // cascades, so most of these statements have nothing left to delete by the
    // time they run — they are written out anyway, because a table that is
    // only ever emptied as a side effect of another one is a table the next
    // person to add a foreign key can silently leave behind.
    await database.transaction(() async {
      await database.delete(database.ebookCovers).go();
      await database.delete(database.ebookCollections).go();
      await database.delete(database.annotations).go();
      await database.delete(database.progress).go();
      await database.delete(database.ebooks).go();
      await database.delete(database.collections).go();

      await database.delete(database.refusedOperations).go();
      await database.delete(database.appliedOperations).go();
      await database.delete(database.pendingOperations).go();
      await database.delete(database.recordVersions).go();
      await database.delete(database.nodeCursors).go();

      await database.delete(database.contentUploads).go();
      await database.delete(database.contentPins).go();

      // Last of the tables, and the one that makes the rest true: while this
      // row is here, this device says it holds a library for the reader it
      // names.
      await database.delete(database.signedInReader).go();
    });

    final held = await blobs.digests();

    for (final digest in held) {
      await blobs.remove(digest);
    }

    _log.info('the replica was emptied, and ${held.length} files with it');
  }
}

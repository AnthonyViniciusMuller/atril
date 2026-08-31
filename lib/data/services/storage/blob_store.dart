/// Where the e-book files live, keyed by the digest of their bytes.
///
/// The digest is not a name this app chose. It is what identifies the bytes
/// across the whole federation — `Ebook.content_hash` on the wire,
/// `library.ebook_contents.content_hash` on the node — so the same work
/// imported by two devices, or by two readers on one node, converges on a
/// single stored object. A store keyed by anything else would hold the same
/// book twice and have no way to know.
///
/// The metadata row and the bytes are deliberately not tied together. A device
/// that holds the row and not the file is the ordinary state of a book that has
/// not been downloaded yet, and on the web it is the ordinary state of every
/// book the reader has not asked to keep. Nothing here knows about `ebooks`,
/// and nothing in `ebooks` references this.
library;

import 'dart:typed_data';

import '../../../utils/errors.dart';

/// The operation these failures are reported under.
const String opBlobStore = 'data/storage: blob';

/// The stable code of a digest that names nothing this device holds.
const String codeBlobMissing = 'blob_missing';

/// The stable code of a write whose bytes did not hash to what was declared.
const String codeBlobCorrupt = 'blob_corrupt';

/// The bytes of the reader's books, on whichever store this platform has.
///
/// Two implementations sit behind it — a filesystem on the five native targets
/// and the origin-private file system in a browser — and they are chosen by a
/// conditional export rather than at run time, because `dart:io` does not parse
/// for the web target and `package:web` does not parse for the others.
abstract interface class BlobStore {
  /// Whether this device holds the bytes [contentHash] names.
  Future<bool> contains(String contentHash);

  /// How long they are, or `null` if they are not here.
  Future<int?> sizeOf(String contentHash);

  /// The bytes, in chunks, starting at [from].
  ///
  /// It is a stream and not a `Uint8List` because a book is large enough to be
  /// worth not holding twice: the upload of phase 8 hashes what it reads as it
  /// reads it, and the reader opens a file it never fully materializes.
  ///
  /// [from] is what makes a resumed upload possible: the caller continues from
  /// the offset the node said it expects.
  ///
  /// It fails with [ErrorKind.notFound] on a digest this device does not hold.
  Stream<Uint8List> read(String contentHash, {int from});

  /// Begins writing an object whose digest is not known yet.
  ///
  /// Import computes the digest *while* streaming the file, so the bytes cannot
  /// be addressed until the last of them has been read. A write is therefore
  /// staged and then published under the digest the caller computed, which is
  /// also what makes it atomic: a store never holds a partial object under a
  /// digest, because the digest is only attached once the object is whole.
  Future<BlobWrite> beginWrite();

  /// Removes what [contentHash] names, and reports whether it was there.
  ///
  /// It is never called on the reader's behalf without their asking. Nothing in
  /// this app evicts silently — a book that vanished between two openings is
  /// the one failure an offline-first library cannot explain away.
  Future<bool> remove(String contentHash);

  /// Every digest this device holds.
  Future<List<String>> digests();

  /// What the store is holding, in bytes.
  Future<int> usedBytes();
}

/// An object being written, before it has a name.
abstract interface class BlobWrite {
  /// Appends [chunk].
  Future<void> add(List<int> chunk);

  /// Publishes what has been written under [contentHash], and answers with the
  /// number of bytes stored.
  ///
  /// A digest that is already here is not written twice: the staged object is
  /// discarded and the length of what was already stored is returned, which is
  /// the deduplication the whole scheme exists for.
  Future<int> commit(String contentHash);

  /// Discards what has been written. Calling it after [commit] does nothing.
  Future<void> abort();
}

/// Writing an object whose digest the caller already knows.
extension BlobStoreWriting on BlobStore {
  /// Writes [bytes] under [contentHash].
  ///
  /// It is what a download uses: the node was asked for a digest, so there is
  /// nothing to compute. An import cannot use it, because it does not know the
  /// digest until it has read the file.
  Future<int> put(String contentHash, Stream<List<int>> bytes) async {
    final write = await beginWrite();

    try {
      await for (final chunk in bytes) {
        await write.add(chunk);
      }

      return await write.commit(contentHash);
    } on Object {
      await write.abort();

      rethrow;
    }
  }
}

/// The failure raised for a digest this device does not hold.
AppException blobMissing(String contentHash) => AppException(
  kind: ErrorKind.notFound,
  message: 'this device does not hold the bytes of $contentHash',
  code: codeBlobMissing,
  op: opBlobStore,
);

/// Whether [value] is a digest this store can be keyed by.
///
/// It is checked before a name is built out of it, and that is not pedantry: a
/// digest is used as a file name, so a value carrying a separator would name a
/// path of somebody else's choosing.
bool isContentHash(String value) =>
    value.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

/// The failure raised for a digest that is not one.
AppException notAContentHash(String value) => AppException(
  kind: ErrorKind.invalidArgument,
  message: 'a blob is addressed by a lowercase hex sha-256',
  code: codeBlobCorrupt,
  op: opBlobStore,
).withField('content_hash', 'is not a sha-256 digest: $value');

/// A [BlobStore] that keeps the bytes in a map.
///
/// The two real stores are chosen by conditional export — a filesystem on the
/// five native targets, the origin-private file system in a browser — and both
/// are tested where they live. What everything *above* them needs is a store
/// that behaves the way the interface says: staged until it has a digest,
/// keyed by that digest, and deduplicating a file it already holds. This is
/// that store, and it is deliberately in `test/` rather than in `lib/`: a
/// memory implementation shipped in the app is one a provider can be wired to
/// by accident, and a library that lost its books on relaunch is the one
/// failure an offline-first app cannot explain away.
library;

import 'dart:typed_data';

import 'package:atril/data/services/storage/blob_storage.dart';

/// The bytes of the reader's books, in memory.
final class MemoryBlobStore implements BlobStore {
  /// What it is holding, by digest.
  final Map<String, Uint8List> objects = <String, Uint8List>{};

  /// How many writes were staged and never published, which is what a failed
  /// import must leave behind and nothing else.
  int aborted = 0;

  @override
  Future<bool> contains(String contentHash) async =>
      objects.containsKey(contentHash);

  @override
  Future<int?> sizeOf(String contentHash) async =>
      objects[contentHash]?.length;

  @override
  Stream<Uint8List> read(String contentHash, {int from = 0}) async* {
    final bytes = objects[contentHash];

    if (bytes == null) {
      throw blobMissing(contentHash);
    }

    yield Uint8List.sublistView(bytes, from);
  }

  @override
  Future<BlobWrite> beginWrite() async => _MemoryWrite(this);

  @override
  Future<bool> remove(String contentHash) async =>
      objects.remove(contentHash) != null;

  @override
  Future<List<String>> digests() async => objects.keys.toList();

  @override
  Future<int> usedBytes() async => objects.values.fold<int>(
    0,
    (int total, Uint8List bytes) => total + bytes.length,
  );
}

final class _MemoryWrite implements BlobWrite {
  _MemoryWrite(this._store);

  final MemoryBlobStore _store;
  final BytesBuilder _staged = BytesBuilder();
  bool _done = false;

  @override
  Future<void> add(List<int> chunk) async => _staged.add(chunk);

  @override
  Future<int> commit(String contentHash) async {
    if (!isContentHash(contentHash)) {
      throw notAContentHash(contentHash);
    }

    _done = true;

    // Deduplication, which is the whole reason a store is keyed by a digest:
    // the object already here *is* the object being written, so the staged
    // copy is dropped and the length of what was already stored is answered.
    final held = _store.objects[contentHash];

    if (held != null) {
      return held.length;
    }

    final bytes = _staged.takeBytes();

    _store.objects[contentHash] = bytes;

    return bytes.length;
  }

  @override
  Future<void> abort() async {
    if (_done) {
      return;
    }

    _done = true;
    _store.aborted++;
  }
}

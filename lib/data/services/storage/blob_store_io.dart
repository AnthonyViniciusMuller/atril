/// The e-book bytes on the five native targets: files under the application's
/// own support directory.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../utils/logging.dart';
import 'blob_store.dart';

final _log = loggerFor('data/storage');

/// How much is read at a time. It is a compromise between the number of
/// syscalls and the peak this holds for a book being hashed on a phone.
const int blobChunkBytes = 64 * 1024;

/// The bytes, as files named by their digest.
///
/// The layout is two hex characters of the digest as a directory and the rest
/// as the file, which is what keeps a directory listing usable on a filesystem
/// that slows down with tens of thousands of entries in one place.
///
/// A write is staged in a neighbouring `.part` file and renamed into place. The
/// rename is what makes it atomic: a device interrupted mid-download leaves a
/// partial file that nothing can address, rather than a complete-looking object
/// under a digest whose bytes are not there — and an object that *is* addressed
/// by a digest has been hashed, so this is the only guarantee the caller needs.
final class FileBlobStore implements BlobStore {
  /// The store under [root].
  FileBlobStore(this._root);

  /// The store under the directory the platform sets aside for this app's data.
  ///
  /// Application support and not documents, for the reason the database gives:
  /// on iOS and macOS the documents directory is the reader's to browse, and on
  /// Android it is shared storage. A library that lived there would be a
  /// library a file manager can take apart.
  static Future<FileBlobStore> open({String name = 'blobs'}) async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(path.join(support.path, name));

    await root.create(recursive: true);
    _log.fine('the blob store is at ${root.path}');

    return FileBlobStore(root);
  }

  final Directory _root;

  // It is `async` rather than a bare `Future` for a reason a caller would
  // otherwise meet as a crash: a digest that is not one is refused by
  // [_fileOf], and a method that returned the future of a call that had
  // already thrown would raise synchronously out of something the caller is
  // awaiting.
  @override
  Future<bool> contains(String contentHash) async =>
      _fileOf(contentHash).exists();

  @override
  Future<int?> sizeOf(String contentHash) async {
    final file = _fileOf(contentHash);

    return await file.exists() ? file.length() : null;
  }

  @override
  Stream<Uint8List> read(String contentHash, {int from = 0}) async* {
    final file = _fileOf(contentHash);

    if (!await file.exists()) {
      throw blobMissing(contentHash);
    }

    yield* file
        .openRead(from)
        .map((chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
  }

  @override
  Future<BlobWrite> beginWrite() async {
    await _root.create(recursive: true);

    final staged = File(
      path.join(
        _root.path,
        '${DateTime.now().microsecondsSinceEpoch}-$hashCode.part',
      ),
    );

    return _FileBlobWrite(staged, _fileOf);
  }

  @override
  Future<bool> remove(String contentHash) async {
    final file = _fileOf(contentHash);

    if (!await file.exists()) {
      return false;
    }

    await file.delete();

    return true;
  }

  @override
  Future<List<String>> digests() async {
    if (!await _root.exists()) {
      return <String>[];
    }

    final held = <String>[];

    await for (final entry in _root.list(recursive: true)) {
      if (entry is! File) {
        continue;
      }

      final digest =
          path.basename(path.dirname(entry.path)) + path.basename(entry.path);

      if (isContentHash(digest)) {
        held.add(digest);
      }
    }

    return held..sort();
  }

  @override
  Future<int> usedBytes() async {
    if (!await _root.exists()) {
      return 0;
    }

    var used = 0;

    await for (final entry in _root.list(recursive: true)) {
      if (entry is File) {
        // A staged write counts. It is space the volume is not offering
        // anybody else, and a budget that ignored it would be a budget that is
        // wrong exactly while a large download is running.
        used += await entry.length();
      }
    }

    return used;
  }

  File _fileOf(String contentHash) {
    if (!isContentHash(contentHash)) {
      throw notAContentHash(contentHash);
    }

    return File(
      path.join(
        _root.path,
        contentHash.substring(0, 2),
        contentHash.substring(2),
      ),
    );
  }
}

final class _FileBlobWrite implements BlobWrite {
  _FileBlobWrite(this._staged, this._destination);

  final File _staged;
  final File Function(String contentHash) _destination;

  IOSink? _sink;
  bool _closed = false;

  @override
  Future<void> add(List<int> chunk) async {
    final sink = _sink ??= _staged.openWrite();

    sink.add(chunk);

    // The sink buffers, and a book is larger than the buffer. Flushing per
    // chunk is what keeps the peak the size of a chunk rather than the size of
    // the file.
    await sink.flush();
  }

  @override
  Future<int> commit(String contentHash) async {
    final destination = _destination(contentHash);

    await _close();

    if (await destination.exists()) {
      // The same file is already here, imported by another device or by this
      // reader twice. That is the deduplication the digest exists for, and the
      // staged copy is what goes.
      await _discard();

      return destination.length();
    }

    await destination.parent.create(recursive: true);
    await _staged.rename(destination.path);

    return destination.length();
  }

  @override
  Future<void> abort() async {
    await _close();
    await _discard();
  }

  Future<void> _close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    final sink = _sink;

    if (sink != null) {
      await sink.flush();
      await sink.close();
    }
  }

  Future<void> _discard() async {
    if (await _staged.exists()) {
      await _staged.delete();
    }
  }
}

/// The blob store this platform has.
Future<BlobStore> openBlobStore() => FileBlobStore.open();

/// Whether this platform can keep a book at all.
///
/// It always can here. The browser is where the answer can be no — a page
/// without the origin-private file system has nowhere to put a book — and the
/// counterpart in `blob_store_web.dart` is what says so. Phase 8 asks this
/// before offering a reader a control that keeps one.
Future<bool> blobStoreIsSupported() async => true;

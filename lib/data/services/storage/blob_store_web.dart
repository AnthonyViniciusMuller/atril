/// The e-book bytes in a browser: the origin-private file system.
///
/// It is the same store drift keeps the replica in, and it is the only one a
/// page has that holds a hundred megabytes without asking. What it is not is
/// *guaranteed*: a browser may evict an origin's storage under pressure, which
/// is why phase 8 makes keeping a book on the web an explicit per-book choice
/// against a visible budget rather than something the app does quietly.
///
/// A browser that has no origin-private file system has nowhere to put a book
/// at all. That is reported rather than worked around — the library still
/// lists, syncs and shows progress, and a book streams on open — because the
/// alternative is a promise about a train the app cannot keep.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'blob_store.dart';

final _log = loggerFor('data/storage');

/// How much is read at a time, matching the native store's chunk.
const int blobChunkBytes = 64 * 1024;

/// The prefix of a staged write, which is never a digest and so can never be
/// mistaken for a stored object.
const String _stagedPrefix = 'staging-';

/// The bytes, as files in the origin-private file system.
///
/// The names are flat: one file per digest, and a staged write under a name
/// that could not be one. Publishing moves the staged file where the platform
/// can move it and copies it where it cannot — `FileSystemFileHandle.move` is
/// the newer half of the file system standard, and a browser without it is a
/// browser that copies a book once at the end of an import rather than one that
/// cannot import.
final class OpfsBlobStore implements BlobStore {
  /// The store over [root].
  OpfsBlobStore(this._root);

  /// The store in a subdirectory of the origin-private file system.
  static Future<OpfsBlobStore> open({String name = 'blobs'}) async {
    final root = await _originPrivateRoot();

    if (root == null) {
      throw AppException(
        kind: ErrorKind.unimplemented,
        message: 'this browser has no origin-private file system',
        op: opBlobStore,
      );
    }

    final blobs = await root
        .getDirectoryHandle(
          name,
          web.FileSystemGetDirectoryOptions(create: true),
        )
        .toDart;

    _log.fine('the blob store is the origin-private file system');

    return OpfsBlobStore(blobs);
  }

  final web.FileSystemDirectoryHandle _root;

  @override
  Future<bool> contains(String contentHash) async =>
      await _handleOf(contentHash) != null;

  @override
  Future<int?> sizeOf(String contentHash) async {
    final handle = await _handleOf(contentHash);

    if (handle == null) {
      return null;
    }

    return (await handle.getFile().toDart).size;
  }

  @override
  Stream<Uint8List> read(String contentHash, {int from = 0}) async* {
    final handle = await _handleOf(contentHash);

    if (handle == null) {
      throw blobMissing(contentHash);
    }

    final file = await handle.getFile().toDart;

    // The bytes are read in slices rather than as one buffer. A book is large
    // enough that materializing it would be the largest allocation the tab
    // ever makes, and the callers — the upload, the reader — want it in pieces
    // anyway.
    var offset = max(from, 0);

    while (offset < file.size) {
      final end = min(offset + blobChunkBytes, file.size);
      final slice = file.slice(offset, end);
      final buffer = await slice.arrayBuffer().toDart;

      yield buffer.toDart.asUint8List();

      offset = end;
    }
  }

  @override
  Future<BlobWrite> beginWrite() async {
    final name =
        '$_stagedPrefix${DateTime.now().microsecondsSinceEpoch}-$hashCode';
    final handle = await _root
        .getFileHandle(name, web.FileSystemGetFileOptions(create: true))
        .toDart;
    final writable = await handle.createWritable().toDart;

    return _OpfsBlobWrite(this, name, handle, writable);
  }

  @override
  Future<bool> remove(String contentHash) async {
    if (await _handleOf(contentHash) == null) {
      return false;
    }

    await _removeEntry(contentHash);

    return true;
  }

  @override
  Future<List<String>> digests() async {
    final held = <String>[];

    for (final name in await _names()) {
      if (isContentHash(name)) {
        held.add(name);
      }
    }

    return held..sort();
  }

  @override
  Future<int> usedBytes() async {
    var used = 0;

    for (final name in await _names()) {
      final handle = await _fileHandle(name);

      if (handle != null) {
        // A staged write counts, for the reason the native store gives: it is
        // space the origin is spending, and a budget that ignored it would be
        // wrong exactly while a large import is running.
        used += (await handle.getFile().toDart).size;
      }
    }

    return used;
  }

  Future<web.FileSystemFileHandle?> _handleOf(String contentHash) {
    if (!isContentHash(contentHash)) {
      throw notAContentHash(contentHash);
    }

    return _fileHandle(contentHash);
  }

  Future<web.FileSystemFileHandle?> _fileHandle(String name) async {
    try {
      return await _root.getFileHandle(name).toDart;
    } on Object {
      // The only way to ask whether an entry is there is to ask for it: a
      // browser answers a missing one by rejecting, and a rejection here is
      // that answer rather than a failure.
      return null;
    }
  }

  Future<void> _removeEntry(String name) =>
      _root.removeEntry(name).toDart.then((_) {});

  /// Every entry in the directory, staged writes included.
  ///
  /// The directory is an async iterable, which `package:web` does not type
  /// because the IDL it is generated from does not describe one. Walking it by
  /// hand is what the two callers above need and is all that is done with it.
  Future<List<String>> _names() async {
    final iterator = (_root as JSObject).callMethod<JSObject>('keys'.toJS);
    final names = <String>[];

    while (true) {
      final step = await iterator
          .callMethod<JSPromise<JSObject>>('next'.toJS)
          .toDart;

      if ((step.getProperty<JSBoolean>('done'.toJS)).toDart) {
        return names;
      }

      names.add((step.getProperty<JSString>('value'.toJS)).toDart);
    }
  }
}

final class _OpfsBlobWrite implements BlobWrite {
  _OpfsBlobWrite(this._store, this._name, this._handle, this._writable);

  final OpfsBlobStore _store;
  final String _name;
  final web.FileSystemFileHandle _handle;
  final web.FileSystemWritableFileStream _writable;

  bool _closed = false;

  @override
  Future<void> add(List<int> chunk) async {
    final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);

    await _writable.write(bytes.toJS).toDart;
  }

  @override
  Future<int> commit(String contentHash) async {
    if (!isContentHash(contentHash)) {
      throw notAContentHash(contentHash);
    }

    await _close();

    final held = await _store.sizeOf(contentHash);

    if (held != null) {
      // Already here, imported by another device or by this reader twice. The
      // digest is what makes that recognizable, and the staged copy is what
      // goes.
      await abort();

      return held;
    }

    final size = (await _handle.getFile().toDart).size;

    await _publishAs(contentHash);

    return size;
  }

  @override
  Future<void> abort() async {
    await _close();

    try {
      await _store._removeEntry(_name);
    } on Object catch (failure) {
      // A staged file that cannot be removed is space, not corruption: it is
      // named so that nothing will ever read it as an object.
      _log.warning('a staged blob was left behind', failure);
    }
  }

  Future<void> _close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    try {
      await _writable.close().toDart;
    } on Object catch (failure) {
      _log.fine('the staged blob was already closed: $failure');
    }
  }

  /// Gives the staged file its name.
  ///
  /// `move` is what makes this atomic, and where a browser does not have it the
  /// bytes are copied and the staged file removed. The copy is chunked for the
  /// reason everything else here is: a book is not something to hold in memory
  /// twice.
  Future<void> _publishAs(String contentHash) async {
    if (_handle.has('move')) {
      await _handle
          .callMethod<JSPromise<JSAny?>>('move'.toJS, contentHash.toJS)
          .toDart;

      return;
    }

    final destination = await _store._root
        .getFileHandle(contentHash, web.FileSystemGetFileOptions(create: true))
        .toDart;
    final sink = await destination.createWritable().toDart;
    final staged = await _handle.getFile().toDart;

    var offset = 0;

    while (offset < staged.size) {
      final end = min(offset + blobChunkBytes, staged.size);
      final buffer = await staged.slice(offset, end).arrayBuffer().toDart;

      await sink.write(buffer.toDart.asUint8List().toJS).toDart;

      offset = end;
    }

    await sink.close().toDart;
    await abort();
  }
}

/// The root of the origin-private file system, or `null` where the browser has
/// none — an insecure context, or one where storage is switched off.
Future<web.FileSystemDirectoryHandle?> _originPrivateRoot() async {
  try {
    return await web.window.navigator.storage.getDirectory().toDart;
  } on Object catch (failure) {
    _log.warning('this browser has no origin-private file system', failure);

    return null;
  }
}

/// The blob store this platform has.
Future<BlobStore> openBlobStore() => OpfsBlobStore.open();

/// Whether this browser can keep a book at all.
Future<bool> blobStoreIsSupported() async => await _originPrivateRoot() != null;

/// Sending a file to the node, a chunk at a time (UC02).
///
/// **Atril uses the chunked shape on all six targets and never
/// `UploadEbookContent`.** D11 records the property that decides it: an upload
/// addressed by an offset can be resumed and a client stream cannot — one that
/// dies at nine tenths starts again from nothing. That is worth more on the
/// mobile network RNF01 and RNF07 are written about than one code path is worth
/// avoiding, and it means every platform exercises the path a browser has no
/// alternative to.
///
/// **The transfer is about bytes and not about a book.** `BeginEbookUpload`
/// names a digest, a length and a media type, and no work at all — the object
/// is shared between every work that names it, which is what makes the same
/// file imported by two readers one stored object.
///
/// **And that is exactly what C16 constrains.** Because the call carries no
/// work identifier, the node has nothing to check it against, so it checks the
/// only thing it can: whether the calling reader already holds a work naming
/// the digest. The flow the contract describes is `CreateEbook`, read
/// `content_missing`, then upload — and Atril never calls `CreateEbook`. The
/// work reaches the node when the log is pushed, so **an upload cannot succeed
/// until the operation that created the work has been delivered.** The node
/// answers a failed precondition with [codeUnclaimedContent], and that is a
/// *not yet* and not a failure: nothing about the file is wrong, and the same
/// call after the next push succeeds. The roadmap said an import queues its
/// operation and sends its bytes "without either waiting for the other", and
/// half of that is false — the record does not wait for the bytes, and the
/// bytes wait for the record.
library;

import 'dart:typed_data';

import '../../../domain/models/ebook.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../api/library_api.dart';
import '../storage/blob_storage.dart';

final _log = loggerFor('data/content');

/// The operation an upload reports under.
const String opUploadContent = 'library/content: send';

/// The node's code for a digest no work of this reader's names (C16).
///
/// It is the answer to *not yet*, and the caller's response is to leave the
/// transfer queued rather than to give up on it: what changes the answer is
/// the push that delivers the work, not anything about the file.
const String codeUnclaimedContent = 'unclaimed_content';

/// The node's code for a file larger than it accepts.
const String codeUploadTooLarge = 'upload_too_large';

/// The code of a chunk the node was not expecting.
const String codeUploadOutOfStep = 'upload_out_of_step';

/// How much of a file travels in one call.
///
/// gRPC refuses a message over four megabytes by default and a chunk is not
/// the only thing in one, so the size is a fraction of that rather than a
/// fraction of the file: a client that sized its chunks by the file would work
/// on every book it was tested with and fail on the atlas. It is the reference
/// client's own number, which is not a coincidence — the two send to the same
/// node under the same limit.
const int uploadChunkBytes = 256 * 1024;

/// How an upload ended.
enum UploadOutcome {
  /// This device sent the bytes and the node now holds them.
  sent,

  /// The node already had them, so nothing was sent.
  ///
  /// It happens far more often than a client might expect — another device of
  /// the same reader, or another reader on the same node, sent the same file —
  /// and it is the deduplication a digest-addressed store exists for, not a
  /// case to apologize for.
  alreadyHeld,
}

/// Sends the bytes of one digest to the node.
final class ContentUploader {
  /// The uploader over [api] and [blobs].
  ///
  /// [chunkBytes] is a parameter so that a test can watch more than one chunk
  /// travel without building a file of a megabyte.
  ContentUploader({
    required this.api,
    required this.blobs,
    this.chunkBytes = uploadChunkBytes,
  });

  /// The calls. None of them writes a replicable record: an upload is about
  /// content, and content does not replicate.
  final LibraryApi api;

  /// Where this device keeps the bytes.
  final BlobStore blobs;

  /// How much travels in one call.
  final int chunkBytes;

  /// Sends what [contentHash] names, declaring it as [mediaType].
  ///
  /// The length is this device's own reading of the stored object and not
  /// anything a directory entry said: it is what the node checks the transfer
  /// against, so it has to describe the bytes that will actually arrive.
  ///
  /// It throws an [AppException] rather than answering a `Result`, which is
  /// what everything under `data/services` does — the repository above is the
  /// layer boundary, and the boundary is where a failure becomes a value.
  Future<UploadOutcome> upload(
    String contentHash, {
    required String mediaType,
  }) async {
    final size = await blobs.sizeOf(contentHash);

    if (size == null) {
      throw AppException(
        kind: ErrorKind.failedPrecondition,
        message: 'this device does not hold the bytes of $contentHash',
        code: codeBlobMissing,
        op: opUploadContent,
      );
    }

    // The whole declaration is checked here, before a byte travels: the
    // digest, the length and the media type, and — C16 — whether a work of
    // this reader's names the digest at all.
    final started = await api.beginUpload(
      EbookContent(
        contentHash: contentHash,
        sizeBytes: size,
        mediaType: mediaType,
      ),
    );

    if (started.alreadyHeld) {
      _log.fine('the node already holds $contentHash');

      return UploadOutcome.alreadyHeld;
    }

    await _send(started.uploadId, contentHash, size);

    final finished = await api.finishUpload(started.uploadId);

    _log.fine('sent $contentHash: ${finished.content}');

    return finished.alreadyHeld ? UploadOutcome.alreadyHeld : UploadOutcome.sent;
  }

  /// Puts every chunk of [contentHash] into the upload [uploadId] names.
  Future<void> _send(String uploadId, String contentHash, int size) async {
    var offset = 0;

    await for (final chunk in _chunked(blobs.read(contentHash))) {
      final received = await api.putChunk(
        uploadId: uploadId,
        offset: offset,
        chunk: chunk,
      );

      // A chunk that did not land is not an error on the wire: the node
      // answers with the offset it *is* expecting, and a caller that ignored
      // that would finish an upload the node holds a prefix of and be told at
      // the end that the digest does not match. Continuing from what arrived
      // is the commit below this one; refusing to go on is what makes the
      // difference visible until then.
      if (received != offset + chunk.length) {
        throw AppException(
          kind: ErrorKind.failedPrecondition,
          message:
              'the node holds $received bytes of $contentHash and this '
              'device sent the chunk at $offset',
          code: codeUploadOutOfStep,
          op: opUploadContent,
        );
      }

      offset = received;
    }

    if (offset != size) {
      // The stored object is shorter or longer than `sizeOf` said. It is this
      // device's own store disagreeing with itself, and finishing would have
      // the node refuse the digest with no useful explanation.
      throw AppException(
        kind: ErrorKind.internal,
        message: 'the store answered $offset bytes for $contentHash, not $size',
        code: codeBlobCorrupt,
        op: opUploadContent,
      );
    }
  }

  /// [source], regrouped into pieces of at most [chunkBytes].
  ///
  /// The blob store reads in whatever size suits the platform, and the node is
  /// sent what suits gRPC. Buffering here is what keeps the two independent —
  /// and it holds one chunk at a time and never the file.
  Stream<Uint8List> _chunked(Stream<Uint8List> source) async* {
    final held = BytesBuilder(copy: false);

    await for (final piece in source) {
      held.add(piece);

      while (held.length >= chunkBytes) {
        final bytes = held.takeBytes();

        yield Uint8List.sublistView(bytes, 0, chunkBytes);
        held.add(Uint8List.sublistView(bytes, chunkBytes));
      }
    }

    if (held.isNotEmpty) {
      yield held.takeBytes();
    }
  }
}

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

/// How many times an upload may be told to continue from somewhere else
/// without getting anywhere.
///
/// A node answering an offset this device then sends from, twice, and the same
/// offset again, is not a transfer that is being resumed: it is one that is
/// looping. The bound is what turns that into a failure a caller sees instead
/// of a call that never returns.
const int maxUploadRestarts = 3;

/// The node's code for an upload it is not holding.
///
/// It is a session that was never begun here, or one that has been finished,
/// abandoned or expired — and, because D11 stages the bytes in a file held in
/// the process, it is also what a node restart looks like to a device still
/// holding the identifier. So it is not a failure of the transfer: it is a
/// beginning, and every call is written to fall back to `BeginEbookUpload`.
const String codeNoSuchUpload = 'no_such_upload';

/// Where an upload has got to.
final class UploadProgress {
  /// [sentBytes] of [totalBytes] delivered into the upload [uploadId] names.
  const UploadProgress({
    required this.uploadId,
    required this.sentBytes,
    required this.totalBytes,
  });

  /// The session the node opened, which is what a resumed transfer names.
  final String uploadId;

  /// How many bytes the node holds, by its own account and not this device's.
  final int sentBytes;

  /// How many there are in all.
  final int totalBytes;

  /// How far through, between zero and one.
  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;

  @override
  String toString() => 'UploadProgress($uploadId, $sentBytes/$totalBytes)';
}

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
    String? resuming,
    Future<void> Function(UploadProgress progress)? onProgress,
  }) async {
    final size = await blobs.sizeOf(contentHash);

    if (size == null) {
      // Not found and not a failed precondition: nothing that happens later
      // makes a file this device does not have appear, so a queue that read
      // this as *not yet* would wait on it forever.
      throw AppException(
        kind: ErrorKind.notFound,
        message: 'this device does not hold the bytes of $contentHash',
        code: codeBlobMissing,
        op: opUploadContent,
      );
    }

    // A session this device was part way through, continued. What it is worth
    // is a large book on a mobile network: the node keeps what arrived, so the
    // transfer picks up at nine tenths instead of at nothing.
    if (resuming != null) {
      final outcome = await _resume(
        resuming,
        contentHash,
        size,
        onProgress: onProgress,
      );

      if (outcome != null) {
        return outcome;
      }

      _log.fine('the node is not holding $resuming; beginning again');
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

    // Reported before a byte travels, because the identifier is the thing a
    // later launch resumes with: a device told about it only once a chunk had
    // landed would forget every session that opened and then lost its
    // connection — which is the case the whole shape exists for.
    await onProgress?.call(
      UploadProgress(
        uploadId: started.uploadId,
        sentBytes: 0,
        totalBytes: size,
      ),
    );

    return _deliver(
      started.uploadId,
      contentHash,
      size,
      onProgress: onProgress,
    );
  }

  /// Continues [uploadId], or answers `null` if the node is not holding it.
  ///
  /// `null` and not a failure: an expired session, a finished one and a node
  /// that has been restarted are all the same answer, and what the caller does
  /// about it is begin again. D11 stages the bytes in a temporary file held in
  /// the process, so a node restart really does invalidate a session this
  /// device is still holding — which is why an identifier remembered across a
  /// launch is a hint and never an assumption.
  Future<UploadOutcome?> _resume(
    String uploadId,
    String contentHash,
    int size, {
    Future<void> Function(UploadProgress progress)? onProgress,
  }) async {
    try {
      // Where the node is, asked with a chunk of no bytes. A chunk at an
      // offset the node is not expecting is not written and the reply carries
      // the offset it *is* expecting, so this costs one call and no transfer —
      // where sending the first real chunk and being told it landed nowhere
      // would cost a quarter of a megabyte on the network this whole shape
      // exists for.
      final at = await api.putChunk(
        uploadId: uploadId,
        offset: 0,
        chunk: const <int>[],
      );

      _log.fine('the node holds $at bytes of $contentHash');

      return await _deliver(
        uploadId,
        contentHash,
        size,
        from: at,
        onProgress: onProgress,
      );
    } on AppException catch (error) {
      if (error.kind == ErrorKind.notFound) {
        return null;
      }

      rethrow;
    }
  }

  Future<UploadOutcome> _deliver(
    String uploadId,
    String contentHash,
    int size, {
    int from = 0,
    Future<void> Function(UploadProgress progress)? onProgress,
  }) async {
    try {
      await _send(
        uploadId,
        contentHash,
        size,
        from: from,
        onProgress: onProgress,
      );

      final finished = await api.finishUpload(uploadId);

      _log.fine('sent $contentHash: ${finished.content}');

      // Another upload of the same file finished while this one was arriving.
      // The bytes are identical by construction, since the digest is the key,
      // so it is the answer this caller wanted reached by somebody else.
      return finished.alreadyHeld
          ? UploadOutcome.alreadyHeld
          : UploadOutcome.sent;
    } on Object catch (error) {
      await _abandon(uploadId, error);

      rethrow;
    }
  }

  /// Tells the node to release an upload this device has given up on.
  ///
  /// A caller that never says so is not a leak — the node ends an upload
  /// nobody has sent to for long enough — but a client that has given up
  /// should say so rather than leave a partial file on somebody else's disk
  /// until it expires.
  ///
  /// It never throws. The upload is already being abandoned; a failure to say
  /// so is not a second thing for the caller to handle, and reporting it would
  /// replace the reason the transfer stopped with the reason the courtesy did.
  Future<void> discard(String uploadId) async {
    try {
      await api.discardUpload(uploadId);
    } on Object catch (error) {
      _log.fine('the upload $uploadId could not be discarded', error);
    }
  }

  /// Discards [uploadId] unless [error] is worth resuming from.
  ///
  /// The distinction is the whole point of the chunked shape. A connection
  /// that dropped is a transfer to continue — the node keeps what arrived and
  /// this device asks again — so the session is *left standing*. Anything else
  /// is this call having no business finishing: the store contradicted itself,
  /// the node refused the declaration, the reader cancelled. Those release the
  /// bytes.
  Future<void> _abandon(String uploadId, Object error) async {
    final kind = error is AppException ? error.kind : ErrorKind.unknown;

    const resumable = <ErrorKind>{
      ErrorKind.unavailable,
      ErrorKind.deadlineExceeded,
      ErrorKind.canceled,
      ErrorKind.unknown,
    };

    if (resumable.contains(kind)) {
      _log.fine('the upload $uploadId stopped and is left standing');

      return;
    }

    await discard(uploadId);
  }

  /// Puts every chunk of [contentHash] into the upload [uploadId] names,
  /// continuing from wherever the node says it is.
  ///
  /// This is the property the client stream did not have. A `PutEbookChunk`
  /// reply carries `received_bytes`, which is how many bytes the node holds
  /// and therefore the offset the next chunk must carry — so a caller that
  /// finds it somewhere other than where it thought reads the file again from
  /// *there*, and one that lost a reply and repeated a chunk is told the node
  /// did not write it twice rather than corrupting the file.
  Future<void> _send(
    String uploadId,
    String contentHash,
    int size, {
    int from = 0,
    Future<void> Function(UploadProgress progress)? onProgress,
  }) async {
    var offset = from;
    var stalled = 0;

    while (offset < size) {
      final reached = await _sendFrom(
        uploadId,
        contentHash,
        offset,
        onProgress: onProgress,
        size: size,
      );

      if (reached > size) {
        throw AppException(
          kind: ErrorKind.internal,
          message:
              'the node holds $reached bytes of $contentHash, which is more '
              'than the $size this device declared',
          code: codeUploadOutOfStep,
          op: opUploadContent,
        );
      }

      if (reached == offset) {
        // A pass that moved nothing. Once is the node telling this device
        // where it really is; three times is a loop, and a caller stuck in one
        // is worse off than a caller told the transfer failed.
        if (++stalled > maxUploadRestarts) {
          throw AppException(
            kind: ErrorKind.failedPrecondition,
            message: 'the upload of $contentHash made no progress past $offset',
            code: codeUploadOutOfStep,
            op: opUploadContent,
          );
        }
      } else {
        stalled = 0;
      }

      if (reached < offset) {
        _log.fine(
          'the node holds $reached of $contentHash; sending from there',
        );
      }

      offset = reached;
    }
  }

  /// Sends [contentHash] from [from], and answers where the node ended up.
  ///
  /// It stops at the first chunk the node did not write, because from that
  /// point on every offset this device would send is wrong: the reply is the
  /// truth and the caller reads the file again from it.
  Future<int> _sendFrom(
    String uploadId,
    String contentHash,
    int from, {
    required int size,
    Future<void> Function(UploadProgress progress)? onProgress,
  }) async {
    var offset = from;

    await for (final chunk in _chunked(blobs.read(contentHash, from: from))) {
      final received = await api.putChunk(
        uploadId: uploadId,
        offset: offset,
        chunk: chunk,
      );

      // Reported from the node's own count and never from this device's. It is
      // the number a restart continues from, and a device that recorded what
      // it *sent* would resume past bytes that never landed.
      // Awaited, not fired and forgotten. What the caller does with it is
      // write the offset a later launch will resume from, and a write that had
      // not landed when the connection dropped is a transfer that starts again
      // from nothing.
      await onProgress?.call(
        UploadProgress(
          uploadId: uploadId,
          sentBytes: received,
          totalBytes: size,
        ),
      );

      if (received != offset + chunk.length) {
        return received;
      }

      offset = received;
    }

    return offset;
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

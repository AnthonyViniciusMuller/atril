/// Fetching a work's bytes from the node into this device's store.
///
/// It is the mirror of the upload and it is *not* its mirror image, which is
/// the finding this file records. `DownloadEbookContentRequest` carries an
/// e-book identifier and nothing else — **no offset, and no range** — so the
/// node has no way to be asked for the second half of a file. The roadmap
/// called the download resumable and it is not: an interrupted one starts
/// again from the beginning, and there is nothing in the contract to fix that
/// with. What the contract does give is the description *first*, before any
/// bytes, so a client knows the digest and the length in advance — and that is
/// what this file spends: it verifies what arrived rather than trusting it, and
/// reports progress against a total it actually knows.
///
/// Three things follow from the shape rather than from a preference.
///
/// **Nothing partial is ever stored.** The write is staged and published under
/// a digest at the end, so a download that dies at nine tenths leaves the store
/// exactly as it was. A device that kept the fragment would have a file it
/// could not name, since the name is what the bytes are.
///
/// **A node that does not hold the file is answering, not failing.** D02 makes
/// metadata without files a legitimate replica — the cheap copy a reader is
/// most likely to want on a node they do not own — so `content_not_found` is a
/// state to show and not an error to retry.
///
/// **Cancelling discards.** A reader who stops a download has stopped wanting
/// the book on this device, and there is no half of it worth keeping.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../domain/models/ebook.dart';
import '../../../utils/cancellation.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../api/library_api.dart';
import '../storage/blob_storage.dart';

final _log = loggerFor('data/content');

/// The operation a download reports under.
const String opDownloadContent = 'library/content: fetch';

/// The node's code for a work whose file it does not hold.
///
/// It is a legitimate state and not a failure (D02): a node may replicate this
/// reader's records without their files, which is the cheap copy a reader is
/// most likely to want on a node they do not own.
const String codeContentNotFound = 'content_not_found';

/// The code of a transfer whose bytes were not what the node said they were.
const String codeDownloadCorrupt = 'download_digest_mismatch';

/// How far a download has got.
final class DownloadProgress {
  /// [receivedBytes] of [totalBytes] arrived for the work [ebookId].
  const DownloadProgress({
    required this.ebookId,
    required this.receivedBytes,
    required this.totalBytes,
  });

  /// The work being fetched.
  final String ebookId;

  /// How many bytes have arrived.
  final int receivedBytes;

  /// How many the node said there are.
  final int totalBytes;

  /// How far through, between zero and one.
  double get fraction =>
      totalBytes == 0 ? 0 : (receivedBytes / totalBytes).clamp(0, 1);

  @override
  String toString() =>
      'DownloadProgress($ebookId, $receivedBytes/$totalBytes)';
}

/// Brings a work's bytes onto this device.
final class ContentDownloader {
  /// The downloader over [api] and [blobs].
  const ContentDownloader({required this.api, required this.blobs});

  /// The call. It writes no replicable record: content does not replicate.
  final LibraryApi api;

  /// Where the bytes are kept.
  final BlobStore blobs;

  /// Fetches the file of [ebookId], which the work says is [expectedHash].
  ///
  /// A digest this device already holds is not fetched at all — the store is
  /// keyed by what the bytes are, so a book whose file arrived with another
  /// work of the same digest is already here. That is the same deduplication
  /// the upload gets for nothing, read the other way round.
  ///
  /// [cancel] is checked between chunks, which for a stream of sixty-four
  /// kilobyte messages is as often as a reader could notice.
  Future<EbookContent> download({
    required String ebookId,
    required String expectedHash,
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    final held = await blobs.sizeOf(expectedHash);

    if (held != null) {
      _log.fine('this device already holds $expectedHash');

      return EbookContent(
        contentHash: expectedHash,
        sizeBytes: held,
        // Nothing on this device records what a stored object *is*: the store
        // is keyed by the digest and holds bytes. The work's format is what a
        // caller has, and it is what the media type was derived from when the
        // file was imported or declared.
        mediaType: '',
      );
    }

    EbookContent? described;
    var received = 0;

    final write = await blobs.beginWrite();

    // Hashed as it arrives, for the reason the import hashes as it reads: the
    // digest is what the object will be stored under, and `commit` names an
    // object rather than checking one. A truncated or altered transfer stored
    // under a name that promises otherwise is precisely what the digest exists
    // to prevent, and the only place to notice is here.
    Digest? computed;

    final hashing = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback(
        (List<Digest> digests) => computed = digests.single,
      ),
    );

    try {
      await for (final message in api.downloadContent(ebookId)) {
        // Broken out of rather than thrown out of, which is what *cancels* the
        // call: leaving the loop ends the subscription and the stream with it,
        // where an exception thrown from inside it would abandon a stream the
        // transport is still holding open.
        if (cancel?.isCancelled ?? false) {
          break;
        }

        switch (message) {
          case EbookDownloadStart(:final content):
            described = content;

            _log.fine('the node holds $content for $ebookId');
          case EbookDownloadChunk(:final bytes):
            hashing.add(bytes);
            await write.add(bytes);
            received += bytes.length;

            await onProgress?.call(
              DownloadProgress(
                ebookId: ebookId,
                receivedBytes: received,
                totalBytes: described?.sizeBytes ?? 0,
              ),
            );
        }
      }

      cancel?.throwIfCancelled(op: opDownloadContent);

      if (described == null) {
        // The contract sends the description first and always. A stream that
        // ended without one is a node this app cannot agree with about what it
        // just received.
        throw AppException(
          kind: ErrorKind.internal,
          message: 'the download of $ebookId described nothing',
          code: codeDownloadCorrupt,
          op: opDownloadContent,
        );
      }

      if (described.contentHash != expectedHash) {
        // The work names one file and the node sent another. Storing it would
        // give this device bytes no record of its own points at.
        throw AppException(
          kind: ErrorKind.failedPrecondition,
          message:
              'the node sent ${described.contentHash} for $ebookId, which '
              'names $expectedHash',
          code: codeDownloadCorrupt,
          op: opDownloadContent,
        );
      }

      hashing.close();

      if ('${computed!}' != expectedHash) {
        // What arrived is not what was asked for. It is the case the whole
        // scheme exists to catch, and the answer is to store nothing: an
        // object under a name that lies about it would be a book that opens as
        // gibberish on this device and nowhere else.
        throw AppException(
          kind: ErrorKind.internal,
          message:
              'the bytes of $ebookId hashed to $computed and the work names '
              '$expectedHash',
          code: codeDownloadCorrupt,
          op: opDownloadContent,
        );
      }

      final stored = await write.commit(expectedHash);

      if (stored != described.sizeBytes) {
        _log.warning(
          'the node said ${described.sizeBytes} bytes for $ebookId '
          'and $stored arrived',
        );
      }

      return described;
    } on Object {
      // Nothing partial is kept. The store never holds a fragment under a
      // digest, because the digest is only attached once the object is whole,
      // and a reader who cancelled has stopped wanting the book here at all.
      await write.abort();

      rethrow;
    }
  }
}

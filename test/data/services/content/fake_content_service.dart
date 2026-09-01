/// A node that receives files and hands them back.
///
/// It extends the seed's fake rather than replacing it, so every call this app
/// must never make is still a `GrpcError.unimplemented` — the fake is an
/// assertion as much as the tests are. What it adds is the four calls of the
/// chunked upload and the download, with the node's own behaviour where that
/// behaviour is the point:
///
/// * a chunk at an offset the node is not expecting is **not written**, and the
///   reply carries the offset it does expect — which is what a caller that lost
///   a connection continues from and what one that lost a reply is told;
/// * a digest the reader has no work naming is refused with C16's
///   `unclaimed_content`, which is a *not yet* and not a failure of the file;
/// * a session it is not holding is a `not_found`, which is what a node restart
///   or an expiry looks like to a caller still holding an identifier.
///
/// One thing does not survive the trip and is worth knowing before reading a
/// test against it: `package:grpc`'s Dart **server** does not write
/// `grpc-status-details-bin`, so the `ErrorInfo` attached below never reaches
/// the client and the failure arrives carrying its status code and no reason.
/// The node is Go, `internal/shared/grpcx` does attach it, and
/// `errors_test.dart` is where the reason surviving is pinned. A test here
/// asserts on the kind.
library;

import 'dart:typed_data';

import 'package:atril/data/services/api/generated/google/rpc/error_details.pb.dart';
import 'package:atril/data/services/api/generated/quire/v1/library.pbgrpc.dart'
    as lib;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import '../sync/fake_library_service.dart';

/// The node's code for a digest no work of the caller's names.
const String unclaimedContent = 'unclaimed_content';

/// The node's code for an upload it is not holding.
const String noSuchUpload = 'no_such_upload';

/// One upload in progress.
final class StagedUpload {
  /// The upload of [declared].
  StagedUpload(this.declared);

  /// What the caller said it was sending.
  final lib.EbookContent declared;

  /// What has arrived so far.
  final BytesBuilder received = BytesBuilder();

  /// How many bytes that is, and therefore the offset the next chunk carries.
  int get offset => received.length;
}

/// A node that takes files.
final class FakeContentService extends FakeLibraryService {
  /// The digests the caller has a work naming (C16).
  ///
  /// Empty by default, which is a device that has imported a book and not yet
  /// pushed the operation that created it — the ordinary state of this app
  /// between an import and the next synchronization.
  final Set<String> claimed = <String>{};

  /// What the node already holds, by digest.
  final Map<String, Uint8List> held = <String, Uint8List>{};

  /// The uploads it is part way through, by identifier.
  final Map<String, StagedUpload> uploads = <String, StagedUpload>{};

  /// Every chunk it was offered, as `(offset, length)`, including the ones it
  /// refused to write.
  final List<(int, int)> chunks = <(int, int)>[];

  /// Every upload a caller abandoned.
  final List<String> discarded = <String>[];

  /// How many bytes to swallow before answering — a connection that dropped
  /// with the chunk half sent, from the caller's point of view.
  ///
  /// The node keeps what arrived, which is the whole property the chunked
  /// shape has and the stream did not.
  int dropAfter = -1;

  /// How many bytes to accept before refusing the rest as too large.
  ///
  /// It is the node's ceiling met part way through a transfer, which is a
  /// refusal and not an interruption: no amount of waiting makes the file
  /// smaller, so the caller has no business finishing and says so.
  int refuseAfter = -1;

  var _next = 0;

  @override
  Future<lib.BeginEbookUploadResponse> beginEbookUpload(
    ServiceCall call,
    lib.BeginEbookUploadRequest request,
  ) async {
    final content = request.content;

    if (!claimed.contains(content.contentHash)) {
      throw GrpcError.custom(
        StatusCode.failedPrecondition,
        'no work of yours names that file',
        <ErrorInfo>[ErrorInfo(reason: unclaimedContent, domain: 'quire.v1')],
      );
    }

    final already = held[content.contentHash];

    if (already != null) {
      return lib.BeginEbookUploadResponse(
        alreadyHeld: true,
        content: lib.EbookContent(
          contentHash: content.contentHash,
          sizeBytes: Int64(already.length),
          mediaType: content.mediaType,
        ),
      );
    }

    final id = 'upload-${++_next}';

    uploads[id] = StagedUpload(content);

    return lib.BeginEbookUploadResponse(uploadId: id);
  }

  @override
  Future<lib.PutEbookChunkResponse> putEbookChunk(
    ServiceCall call,
    lib.PutEbookChunkRequest request,
  ) async {
    final upload = uploads[request.uploadId];

    if (upload == null) {
      throw GrpcError.custom(
        StatusCode.notFound,
        'this node is not holding that upload',
        <ErrorInfo>[ErrorInfo(reason: noSuchUpload, domain: 'quire.v1')],
      );
    }

    chunks.add((request.offset.toInt(), request.chunk.length));

    if (refuseAfter >= 0 &&
        upload.offset + request.chunk.length > refuseAfter) {
      throw GrpcError.resourceExhausted(
        'the file is larger than this node accepts',
      );
    }

    // Nothing is written at an offset the node is not expecting, and the reply
    // carries the truth. That is what lets a caller that lost a connection
    // continue from what arrived, and one that lost a reply and sent the same
    // chunk again be told so rather than corrupt the file.
    if (request.offset.toInt() == upload.offset) {
      upload.received.add(request.chunk);
    }

    if (dropAfter >= 0 && upload.offset >= dropAfter) {
      dropAfter = -1;

      // The bytes arrived and the answer did not. It is indistinguishable, to
      // the caller, from a chunk that never landed — which is exactly why the
      // offset is sent rather than assumed.
      throw GrpcError.unavailable('the connection dropped');
    }

    return lib.PutEbookChunkResponse(receivedBytes: Int64(upload.offset));
  }

  @override
  Future<lib.FinishEbookUploadResponse> finishEbookUpload(
    ServiceCall call,
    lib.FinishEbookUploadRequest request,
  ) async {
    final upload = uploads.remove(request.uploadId);

    if (upload == null) {
      throw GrpcError.custom(
        StatusCode.notFound,
        'this node is not holding that upload',
        <ErrorInfo>[ErrorInfo(reason: noSuchUpload, domain: 'quire.v1')],
      );
    }

    final bytes = upload.received.takeBytes();
    final already = held.containsKey(upload.declared.contentHash);

    held[upload.declared.contentHash] = bytes;

    return lib.FinishEbookUploadResponse(
      alreadyHeld: already,
      content: lib.EbookContent(
        contentHash: upload.declared.contentHash,
        sizeBytes: Int64(bytes.length),
        mediaType: upload.declared.mediaType,
      ),
    );
  }

  /// Which digest each work names, so a download can be asked for by work.
  final Map<String, String> works = <String, String>{};

  /// How many bytes to send before the stream fails, or `-1` to send it all.
  int cutAfter = -1;

  /// What the node claims the file is, overriding the digest it sends under.
  ///
  /// It is how a test reaches the one case the digest exists to catch: a node
  /// answering with bytes that are not what it says they are.
  String? misdescribe;

  /// How many bytes travel in one message, as the node's own controller does.
  int downloadChunk = 64;

  /// How long the node waits between messages.
  ///
  /// Nought by default, which delivers a small file in one flight. A test
  /// about cancelling needs a transfer that is actually still going when the
  /// reader changes their mind, and a pause is what a node reading a file off
  /// an object store has anyway.
  Duration downloadPause = Duration.zero;

  @override
  Stream<lib.DownloadEbookContentResponse> downloadEbookContent(
    ServiceCall call,
    lib.DownloadEbookContentRequest request,
  ) async* {
    final digest = works[request.ebookId];
    final bytes = digest == null ? null : held[digest];

    if (bytes == null) {
      // A node may replicate this reader's records without their files, which
      // is the cheap copy a reader is most likely to want on a node they do
      // not own (D02). It is a state and not a failure.
      throw GrpcError.custom(
        StatusCode.notFound,
        'this node does not hold that file',
        <ErrorInfo>[
          ErrorInfo(reason: 'content_not_found', domain: 'quire.v1'),
        ],
      );
    }

    yield lib.DownloadEbookContentResponse(
      content: lib.EbookContent(
        contentHash: misdescribe ?? digest,
        sizeBytes: Int64(bytes.length),
        mediaType: 'application/epub+zip',
      ),
    );

    var sent = 0;

    for (var at = 0; at < bytes.length; at += downloadChunk) {
      final to = (at + downloadChunk).clamp(0, bytes.length);

      if (cutAfter >= 0 && sent >= cutAfter) {
        throw GrpcError.unavailable('the connection dropped');
      }

      if (downloadPause > Duration.zero) {
        await Future<void>.delayed(downloadPause);
      }

      yield lib.DownloadEbookContentResponse(
        chunk: Uint8List.sublistView(bytes, at, to),
      );
      sent = to;
    }
  }

  @override
  Future<lib.DiscardEbookUploadResponse> discardEbookUpload(
    ServiceCall call,
    lib.DiscardEbookUploadRequest request,
  ) async {
    discarded.add(request.uploadId);
    uploads.remove(request.uploadId);

    return lib.DiscardEbookUploadResponse();
  }
}

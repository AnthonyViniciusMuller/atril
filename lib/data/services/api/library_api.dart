/// `LibraryService`, minus every call that writes a record.
///
/// The service offers eleven write RPCs and this client exposes none of them.
/// C21 is why, and it is not a preference: `UpdateEbook` writes the node's
/// table and appends nothing to its operation log, so a change made that way
/// reaches the reader's other devices and every authorized replica — never.
/// The same change authored locally and pushed reaches all of them. A test in
/// phase 7 walks `lib/` and fails if anything in this app calls one.
///
/// What is left is the two kinds of call that are not writes to a replicable
/// record:
///
/// **The reads**, used once per device: seeding a freshly bound device before
/// its first pull. After that the local replica is the truth and the operation
/// log is how it changes.
///
/// **The bytes**, which do not replicate at all. A file is addressed by its
/// digest and the record only names one, so an upload and a download are about
/// content and not about a work — which is what lets an import queue its
/// operation and send its file without either waiting for the other.
library;

import 'package:fixnum/fixnum.dart';

import '../../../domain/models/collection.dart';
import '../../../domain/models/ebook.dart';
import '../../model/library_mapper.dart';
import 'api_client.dart';
import 'generated/quire/v1/library.pbgrpc.dart' as pb;

/// The operation the collection's reads report under.
const String opEbooks = 'library/ebooks: list';

/// The operation the groupings' reads report under.
const String opCollections = 'library/collections: list';

/// The operation an upload reports under.
const String opUpload = 'library/content: upload';

/// The operation a download reports under.
const String opDownload = 'library/content: download';

/// One page of the reader's collection.
final class EbookPage {
  /// The page, and the token that continues it.
  const EbookPage({required this.ebooks, required this.nextPageToken});

  /// The works on this page. Tombstoned ones are never listed: a client
  /// rebuilding its state needs them and gets them from `SyncService`, which
  /// is where the history lives.
  final List<Ebook> ebooks;

  /// What to send next, or the empty string at the end.
  final String nextPageToken;

  /// Whether there is another page.
  bool get hasMore => nextPageToken.isNotEmpty;
}

/// What `BeginEbookUpload` answered.
final class UploadStart {
  /// The upload named [uploadId], or the answer that there is nothing to send.
  const UploadStart({
    required this.uploadId,
    required this.alreadyHeld,
    this.content,
  });

  /// Names the upload, and is sent with every chunk. It is empty when the node
  /// already holds the file.
  final String uploadId;

  /// Whether the node already had the bytes.
  ///
  /// It is true far more often than a client might expect — the same file
  /// imported on a second device, or by a second reader on this node, is
  /// already there — and it is the deduplication a digest-addressed store
  /// exists for.
  final bool alreadyHeld;

  /// The file as the node holds it, populated only when [alreadyHeld].
  final EbookContent? content;
}

/// What `FinishEbookUpload` answered.
final class UploadFinish {
  /// The stored object, and whether somebody else finished it first.
  const UploadFinish({required this.content, required this.alreadyHeld});

  /// The file as the node now holds it.
  final EbookContent content;

  /// True when another upload of the same file finished while this one was
  /// arriving. The bytes are identical by construction, since the digest is
  /// the key, so it is the answer the caller wanted reached by somebody else.
  final bool alreadyHeld;
}

/// `LibraryService`, as this app is allowed to call it.
final class LibraryApi extends ApiClient {
  /// The client over the channel this node is dialled on.
  LibraryApi({
    required super.channel,
    required super.session,
    super.reachability,
  });

  late final pb.LibraryServiceClient _stub = pb.LibraryServiceClient(
    channel,
    interceptors: interceptors,
  );

  /// UC01, read. One page of the reader's collection, optionally narrowed to
  /// the works filed under one grouping.
  ///
  /// A page size of zero asks the node to choose, which is what a caller that
  /// has no opinion should send rather than a number it invented.
  Future<EbookPage> listEbooks({
    int pageSize = 0,
    String pageToken = '',
    String? collectionId,
  }) => call(opEbooks, () async {
    final request = pb.ListEbooksRequest(
      pageSize: pageSize,
      pageToken: pageToken,
    );

    if (collectionId != null) {
      request.collectionId = collectionId;
    }

    final answer = await _stub.listEbooks(request);

    return EbookPage(
      ebooks: <Ebook>[for (final ebook in answer.ebooks) ebookOf(ebook)],
      nextPageToken: answer.nextPageToken,
    );
  });

  /// UC03, read. The reader's groupings, optionally narrowed to the ones one
  /// work is filed under.
  ///
  /// Not paginated, and the contract says why: a reader defines shelves by
  /// hand and there are as many of them as they had patience for.
  Future<List<Collection>> listCollections({String? ebookId}) =>
      call(opCollections, () async {
        final request = pb.ListCollectionsRequest();

        if (ebookId != null) {
          request.ebookId = ebookId;
        }

        return <Collection>[
          for (final collection in (await _stub.listCollections(
            request,
          )).collections)
            collectionOf(collection),
        ];
      });

  /// UC02. Declares what is about to be sent.
  ///
  /// The node checks the whole declaration here, before a byte travels, and
  /// answers that it already holds the file where it does. Atril uses this
  /// shape on all six targets and never `UploadEbookContent`: D11 notes the
  /// property that decides it — an upload addressed by an offset resumes, and
  /// a client stream that died at nine tenths starts again from nothing.
  Future<UploadStart> beginUpload(EbookContent content) =>
      call(opUpload, () async {
        final answer = await _stub.beginEbookUpload(
          pb.BeginEbookUploadRequest(content: wireContent(content)),
        );

        return UploadStart(
          uploadId: answer.uploadId,
          alreadyHeld: answer.alreadyHeld,
          content: answer.alreadyHeld ? contentOf(answer.content) : null,
        );
      });

  /// The bytes, one call at a time, each at the offset it continues from.
  ///
  /// The answer is how many bytes the node now holds, and therefore the offset
  /// the next chunk must carry. A caller that finds it unchanged sent a chunk
  /// the node was not expecting — which is how a caller that lost a reply
  /// repeats one without the node appending it twice.
  Future<int> putChunk({
    required String uploadId,
    required int offset,
    required List<int> chunk,
  }) => call(
    opUpload,
    () async => (await _stub.putEbookChunk(
      pb.PutEbookChunkRequest(
        uploadId: uploadId,
        offset: Int64(offset),
        chunk: chunk,
      ),
    )).receivedBytes.toInt(),
  );

  /// Ends the upload. The node checks what arrived against what was declared,
  /// and records that it holds it.
  Future<UploadFinish> finishUpload(String uploadId) =>
      call(opUpload, () async {
        final answer = await _stub.finishEbookUpload(
          pb.FinishEbookUploadRequest(uploadId: uploadId),
        );

        return UploadFinish(
          content: contentOf(answer.content),
          alreadyHeld: answer.alreadyHeld,
        );
      });

  /// Abandons an upload, releasing what the node was holding.
  ///
  /// A caller that never sends it is not a leak — the node ends an upload
  /// nobody has sent to for long enough — but a client that has given up
  /// should say so rather than leave a file on the node until it expires.
  Future<void> discardUpload(String uploadId) => call(
    opUpload,
    () => _stub.discardEbookUpload(
      pb.DiscardEbookUploadRequest(uploadId: uploadId),
    ),
  );

  /// Streams the bytes of a work back: the description first, then the chunks.
  ///
  /// A node that replicates this reader without their files answers that it
  /// does not hold them, and that is a legitimate state rather than an error —
  /// metadata without the files is the cheap replica a reader is most likely
  /// to want on a node they do not own.
  Stream<EbookDownload> downloadContent(String ebookId) => listen(
    opDownload,
    _stub
        .downloadEbookContent(pb.DownloadEbookContentRequest(ebookId: ebookId))
        .map(downloadOf),
  );
}

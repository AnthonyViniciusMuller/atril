/// A node that answers the four read calls a seed makes, out of lists.
///
/// It answers those four and refuses everything else, which is the assertion
/// this file exists to make as much as the tests are: a seed uses the read
/// calls, and touching a write RPC is a `GrpcError.unimplemented` rather than
/// something a test has to notice.
library;

import 'package:atril/data/services/api/generated/quire/v1/library.pbgrpc.dart'
    as lib;
import 'package:atril/data/services/api/generated/quire/v1/reading.pbgrpc.dart'
    as reading;
import 'package:grpc/grpc.dart';

/// The node's `LibraryService`, as far as a seed is concerned.
final class FakeLibraryService extends lib.LibraryServiceBase {
  /// The reader's works.
  final List<lib.Ebook> ebooks = <lib.Ebook>[];

  /// The reader's groupings.
  final List<lib.Collection> collections = <lib.Collection>[];

  /// Which works are filed under which grouping, by identifier.
  final Map<String, List<String>> filings = <String, List<String>>{};

  /// Every page a caller asked for, as `(collectionId, pageToken)`.
  final List<(String, String)> pages = <(String, String)>[];

  /// How many works a page holds, so that a test can make the seed paginate.
  int pageSize = 100;

  @override
  Future<lib.ListEbooksResponse> listEbooks(
    ServiceCall call,
    lib.ListEbooksRequest request,
  ) async {
    pages.add((
      request.hasCollectionId() ? request.collectionId : '',
      request.pageToken,
    ));

    final wanted = request.hasCollectionId()
        ? <lib.Ebook>[
            for (final ebook in ebooks)
              if (filings[request.collectionId]?.contains(ebook.id) ?? false)
                ebook,
          ]
        : ebooks;

    final from = request.pageToken.isEmpty ? 0 : int.parse(request.pageToken);
    final to = (from + pageSize).clamp(0, wanted.length);

    return lib.ListEbooksResponse(
      ebooks: wanted.sublist(from, to),
      nextPageToken: to < wanted.length ? '$to' : '',
    );
  }

  @override
  Future<lib.ListCollectionsResponse> listCollections(
    ServiceCall call,
    lib.ListCollectionsRequest request,
  ) async => lib.ListCollectionsResponse(collections: collections);

  @override
  Future<lib.CreateEbookResponse> createEbook(
    ServiceCall call,
    lib.CreateEbookRequest request,
  ) async => _refuse();

  @override
  Future<lib.GetEbookResponse> getEbook(
    ServiceCall call,
    lib.GetEbookRequest request,
  ) async => _refuse();

  @override
  Future<lib.UpdateEbookResponse> updateEbook(
    ServiceCall call,
    lib.UpdateEbookRequest request,
  ) async => _refuse();

  @override
  Future<lib.DeleteEbookResponse> deleteEbook(
    ServiceCall call,
    lib.DeleteEbookRequest request,
  ) async => _refuse();

  @override
  Future<lib.UploadEbookContentResponse> uploadEbookContent(
    ServiceCall call,
    Stream<lib.UploadEbookContentRequest> request,
  ) async => _refuse();

  @override
  Future<lib.BeginEbookUploadResponse> beginEbookUpload(
    ServiceCall call,
    lib.BeginEbookUploadRequest request,
  ) async => _refuse();

  @override
  Future<lib.PutEbookChunkResponse> putEbookChunk(
    ServiceCall call,
    lib.PutEbookChunkRequest request,
  ) async => _refuse();

  @override
  Future<lib.FinishEbookUploadResponse> finishEbookUpload(
    ServiceCall call,
    lib.FinishEbookUploadRequest request,
  ) async => _refuse();

  @override
  Future<lib.DiscardEbookUploadResponse> discardEbookUpload(
    ServiceCall call,
    lib.DiscardEbookUploadRequest request,
  ) async => _refuse();

  @override
  Stream<lib.DownloadEbookContentResponse> downloadEbookContent(
    ServiceCall call,
    lib.DownloadEbookContentRequest request,
  ) => _refuse();

  @override
  Future<lib.CreateCollectionResponse> createCollection(
    ServiceCall call,
    lib.CreateCollectionRequest request,
  ) async => _refuse();

  @override
  Future<lib.GetCollectionResponse> getCollection(
    ServiceCall call,
    lib.GetCollectionRequest request,
  ) async => _refuse();

  @override
  Future<lib.UpdateCollectionResponse> updateCollection(
    ServiceCall call,
    lib.UpdateCollectionRequest request,
  ) async => _refuse();

  @override
  Future<lib.DeleteCollectionResponse> deleteCollection(
    ServiceCall call,
    lib.DeleteCollectionRequest request,
  ) async => _refuse();

  @override
  Future<lib.AddEbookToCollectionResponse> addEbookToCollection(
    ServiceCall call,
    lib.AddEbookToCollectionRequest request,
  ) async => _refuse();

  @override
  Future<lib.RemoveEbookFromCollectionResponse> removeEbookFromCollection(
    ServiceCall call,
    lib.RemoveEbookFromCollectionRequest request,
  ) async => _refuse();
}

/// The node's `ReadingService`, as far as a seed is concerned.
final class FakeReadingService extends reading.ReadingServiceBase {
  /// The reader's marks, by work.
  final Map<String, List<reading.Annotation>> annotations =
      <String, List<reading.Annotation>>{};

  /// Every device's position, by work.
  final Map<String, List<reading.ReadingProgress>> progress =
      <String, List<reading.ReadingProgress>>{};

  @override
  Future<reading.ListAnnotationsResponse> listAnnotations(
    ServiceCall call,
    reading.ListAnnotationsRequest request,
  ) async => reading.ListAnnotationsResponse(
    annotations: annotations[request.ebookId] ?? const <reading.Annotation>[],
  );

  @override
  Future<reading.ListReadingProgressResponse> listReadingProgress(
    ServiceCall call,
    reading.ListReadingProgressRequest request,
  ) async => reading.ListReadingProgressResponse(
    progress: progress[request.ebookId] ?? const <reading.ReadingProgress>[],
  );

  @override
  Future<reading.CreateAnnotationResponse> createAnnotation(
    ServiceCall call,
    reading.CreateAnnotationRequest request,
  ) async => _refuse();

  @override
  Future<reading.GetAnnotationResponse> getAnnotation(
    ServiceCall call,
    reading.GetAnnotationRequest request,
  ) async => _refuse();

  @override
  Future<reading.UpdateAnnotationResponse> updateAnnotation(
    ServiceCall call,
    reading.UpdateAnnotationRequest request,
  ) async => _refuse();

  @override
  Future<reading.DeleteAnnotationResponse> deleteAnnotation(
    ServiceCall call,
    reading.DeleteAnnotationRequest request,
  ) async => _refuse();

  @override
  Future<reading.UpdateReadingProgressResponse> updateReadingProgress(
    ServiceCall call,
    reading.UpdateReadingProgressRequest request,
  ) async => _refuse();
}

/// What every call this app must never make answers with.
Never _refuse() => throw GrpcError.unimplemented('a seed calls no write rpc');

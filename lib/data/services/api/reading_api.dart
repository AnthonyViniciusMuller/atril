/// `ReadingService`, minus every call that writes a record.
///
/// As with `LibraryService`, the writes are absent for the reason C21 gives:
/// `CreateAnnotation` and `UpdateReadingProgress` change the node's tables and
/// append nothing to its log, so a mark made that way reaches none of the
/// reader's other devices. Every mark and every position is authored locally
/// and pushed.
///
/// What is left is the two reads, and they are used once: seeding a freshly
/// bound device before its first pull.
library;

import '../../../domain/models/annotation.dart';
import '../../model/reading_mapper.dart';
import 'api_client.dart';
import 'generated/quire/v1/reading.pbgrpc.dart' as pb;

/// The operation the marks' reads report under.
const String opAnnotations = 'reading/annotations: list';

/// The operation the positions' reads report under.
const String opProgress = 'reading/progress: list';

/// One page of what the reader wrote in one work.
final class AnnotationPage {
  /// The page, and the token that continues it.
  const AnnotationPage({
    required this.annotations,
    required this.nextPageToken,
  });

  /// The marks on this page. Tombstoned ones are not listed.
  final List<Annotation> annotations;

  /// What to send next, or the empty string at the end.
  final String nextPageToken;

  /// Whether there is another page.
  bool get hasMore => nextPageToken.isNotEmpty;
}

/// `ReadingService`, as this app is allowed to call it.
final class ReadingApi extends ApiClient {
  /// The client over the channel this node is dialled on.
  ReadingApi({
    required super.connection,
    required super.session,
    super.reachability,
  });

  pb.ReadingServiceClient get _stub =>
      pb.ReadingServiceClient(channel, interceptors: interceptors);

  /// UC04, read. Everything written in one work.
  Future<AnnotationPage> listAnnotations({
    required String ebookId,
    int pageSize = 0,
    String pageToken = '',
  }) => call(opAnnotations, () async {
    final answer = await _stub.listAnnotations(
      pb.ListAnnotationsRequest(
        ebookId: ebookId,
        pageSize: pageSize,
        pageToken: pageToken,
      ),
    );

    return AnnotationPage(
      annotations: <Annotation>[
        for (final annotation in answer.annotations) annotationOf(annotation),
      ],
      nextPageToken: answer.nextPageToken,
    );
  });

  /// UC05, RN01. Every device's position in one work.
  ///
  /// Every device's, and not the furthest or the most recent: which of those
  /// to show — or whether to ask the reader — is a decision the client makes,
  /// so the node deliberately does not make it by returning one row.
  Future<List<ReadingProgress>> listReadingProgress(String ebookId) => call(
    opProgress,
    () async => <ReadingProgress>[
      for (final progress in (await _stub.listReadingProgress(
        pb.ListReadingProgressRequest(ebookId: ebookId),
      )).progress)
        progressOf(progress),
    ],
  );
}

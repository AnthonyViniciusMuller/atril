@TestOn('vm')
/// Sending a file: what is declared, what travels, and what C16 refuses.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import '../storage/memory_blob_store.dart';
import 'fake_content_service.dart';

/// The digest of [bytes], which the store computes as it writes them.
Future<String> store(MemoryBlobStore blobs, List<int> bytes) async =>
    (await blobs.store(Stream<List<int>>.value(bytes))).contentHash;

void main() {
  late FakeContentService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late MemoryBlobStore blobs;
  late ContentUploader uploader;

  setUp(() async {
    node = FakeContentService();
    server = Server.create(services: <Service>[node]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    session = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => throw StateError('an upload needs no refresh'),
    );
    blobs = MemoryBlobStore();

    uploader = ContentUploader(
      api: LibraryApi(connection: connection, session: session),
      blobs: blobs,
      // Small enough that a file of a few hundred bytes travels in pieces,
      // which is the only way the offsets are exercised at all.
      chunkBytes: 64,
    );
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
  });

  test('sends the file the node does not have', () async {
    final bytes = List<int>.generate(200, (index) => index % 256);
    final digest = await store(blobs, bytes);

    node.claimed.add(digest);

    final outcome = await uploader.upload(
      digest,
      mediaType: 'application/epub+zip',
    );

    expect(outcome, UploadOutcome.sent);
    expect(node.held[digest], Uint8List.fromList(bytes));
  });

  test('carries every chunk at the offset it continues from', () async {
    final digest = await store(blobs, List<int>.filled(200, 7));

    node.claimed.add(digest);

    await uploader.upload(digest, mediaType: 'application/epub+zip');

    // Four calls of at most sixty-four bytes, each starting where the last
    // ended. The offset is sent rather than assumed, which is the whole
    // property the client stream did not have.
    expect(node.chunks, <(int, int)>[(0, 64), (64, 64), (128, 64), (192, 8)]);
  });

  test('declares the length this device counted', () async {
    final digest = await store(blobs, List<int>.filled(200, 7));

    node.claimed.add(digest);

    await uploader.upload(digest, mediaType: 'application/epub+zip');

    expect(node.held[digest]?.length, 200);
  });

  test('sends nothing when the node already holds the file', () async {
    // Another device of the same reader, or another reader on the same node,
    // sent the same bytes. It is the deduplication a digest-addressed store
    // exists for and not a case to apologize for.
    final digest = await store(blobs, <int>[1, 2, 3]);

    node.claimed.add(digest);
    node.held[digest] = Uint8List.fromList(<int>[1, 2, 3]);

    final outcome = await uploader.upload(
      digest,
      mediaType: 'application/epub+zip',
    );

    expect(outcome, UploadOutcome.alreadyHeld);
    expect(node.chunks, isEmpty);
  });

  test('is refused until the work that names the file has been pushed', () async {
    // C16. The upload carries a digest and no work, so the node checks the
    // only thing it can: whether the caller already has a work naming it. This
    // app never calls CreateEbook, so the work arrives with the log — and
    // until it does, this is the answer. It is a *not yet*: nothing about the
    // file is wrong, and the same call after the next push succeeds.
    final digest = await store(blobs, <int>[1, 2, 3]);

    //
    // The assertion is on the kind and not on the reason, and that is a limit
    // of this harness rather than of the mapping: `package:grpc`'s Dart server
    // does not write `grpc-status-details-bin`, so the `ErrorInfo` the fake
    // attaches never leaves it. The node is Go and does send it, and
    // `errors_test.dart` pins the reason surviving the trip.
    await expectLater(
      uploader.upload(digest, mediaType: 'application/epub+zip'),
      throwsA(
        isA<AppException>().having(
          (e) => e.kind,
          'kind',
          ErrorKind.failedPrecondition,
        ),
      ),
    );
    expect(node.chunks, isEmpty);
  });

  test('succeeds on the same call once the work has been pushed', () async {
    final digest = await store(blobs, <int>[1, 2, 3]);

    await expectLater(
      uploader.upload(digest, mediaType: 'application/epub+zip'),
      throwsA(isA<AppException>()),
    );

    node.claimed.add(digest);

    expect(
      await uploader.upload(digest, mediaType: 'application/epub+zip'),
      UploadOutcome.sent,
    );
  });

  test('refuses a digest this device does not hold', () async {
    await expectLater(
      uploader.upload('0' * 64, mediaType: 'application/epub+zip'),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', codeBlobMissing),
      ),
    );
  });
}

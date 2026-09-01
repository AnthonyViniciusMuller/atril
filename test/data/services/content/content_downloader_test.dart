@TestOn('vm')
/// Fetching a file: what is verified, what is discarded, and what is not an
/// error.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/utils/cancellation.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import '../storage/memory_blob_store.dart';
import 'fake_content_service.dart';

const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';

void main() {
  late FakeContentService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late MemoryBlobStore blobs;
  late ContentDownloader downloader;

  /// Puts [bytes] on the node under the work [_work] names, and answers with
  /// the digest the work therefore carries.
  Future<String> onNode(List<int> bytes) async {
    final aside = MemoryBlobStore();
    final stored = await aside.store(Stream<List<int>>.value(bytes));

    node.held[stored.contentHash] = Uint8List.fromList(bytes);
    node.works[_work] = stored.contentHash;

    return stored.contentHash;
  }

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
      refresher: () => throw StateError('a download needs no refresh'),
    );
    blobs = MemoryBlobStore();

    downloader = ContentDownloader(
      api: LibraryApi(connection: connection, session: session),
      blobs: blobs,
    );
  });

  tearDown(() async {
    // The server first. A client connection torn down while the node is still
    // pushing frames into a stream this test cancelled trips a debug assertion
    // inside `package:http2` — a fact about the transport under test
    // conditions rather than about this app, and letting the node stop first
    // is what avoids arranging it.
    await server.shutdown();
    await connection.shutdown();
    await session.dispose();
  });

  test('brings the file onto this device', () async {
    final bytes = List<int>.generate(200, (index) => index % 256);
    final digest = await onNode(bytes);

    final content = await downloader.download(
      ebookId: _work,
      expectedHash: digest,
    );

    expect(content.sizeBytes, 200);
    expect(blobs.objects[digest], Uint8List.fromList(bytes));
  });

  test('reports how far it has got, against a total it knows', () async {
    // The description arrives before the bytes, so the fraction is real from
    // the first chunk rather than a bar that fills at the end.
    final digest = await onNode(List<int>.filled(200, 7));
    final seen = <double>[];

    await downloader.download(
      ebookId: _work,
      expectedHash: digest,
      onProgress: (DownloadProgress progress) async =>
          seen.add(progress.fraction),
    );

    expect(seen, <double>[0.32, 0.64, 0.96, 1.0]);
  });

  test('does not fetch a file this device already holds', () async {
    // The store is keyed by what the bytes are, so a book whose file arrived
    // with another work of the same digest is already here. It is the same
    // deduplication the upload gets, read the other way round.
    final digest = await onNode(<int>[1, 2, 3]);

    await blobs.store(Stream<List<int>>.value(<int>[1, 2, 3]));

    final content = await downloader.download(
      ebookId: 'a work that is not on the node at all',
      expectedHash: digest,
    );

    expect(content.contentHash, digest);
  });

  group('what is not stored', () {
    test('is anything from a transfer that was cut off', () async {
      // The download is not resumable — `DownloadEbookContentRequest` carries
      // an e-book identifier and no offset — so what an interrupted one costs
      // is starting again, and keeping a fragment would buy nothing: the store
      // is keyed by the digest, and a fragment has no name.
      final digest = await onNode(List<int>.filled(200, 7));

      node.cutAfter = 64;

      await expectLater(
        downloader.download(ebookId: _work, expectedHash: digest),
        throwsA(isA<AppException>()),
      );

      expect(blobs.objects, isEmpty);
      expect(blobs.aborted, 1);
    });

    test('is bytes that are not what the work names', () async {
      // The case the whole scheme exists to catch. `commit` names an object
      // rather than checking one, so the digest is computed here as the bytes
      // arrive — the alternative is a book that opens as gibberish on this
      // device and nowhere else.
      final digest = await onNode(List<int>.filled(100, 7));

      node.held[digest] = Uint8List.fromList(List<int>.filled(100, 9));

      await expectLater(
        downloader.download(ebookId: _work, expectedHash: digest),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeDownloadCorrupt,
          ),
        ),
      );
      expect(blobs.objects, isEmpty);
    });

    test('is a file the node described as something else', () async {
      final digest = await onNode(List<int>.filled(100, 7));

      node.misdescribe = 'f' * 64;

      await expectLater(
        downloader.download(ebookId: _work, expectedHash: digest),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeDownloadCorrupt,
          ),
        ),
      );
      expect(blobs.objects, isEmpty);
    });

    test('is what arrived before the reader changed their mind', () async {
      final digest = await onNode(List<int>.filled(400, 7));
      final cancel = Cancellation();

      // A transfer that is still going when the reader changes their mind,
      // which is the only kind there is anything to cancel about.
      node.downloadPause = const Duration(milliseconds: 5);

      await expectLater(
        downloader.download(
          ebookId: _work,
          expectedHash: digest,
          cancel: cancel,
          onProgress: (DownloadProgress progress) async {
            if (progress.receivedBytes >= 128) {
              cancel.cancel();
            }
          },
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            ErrorKind.canceled,
          ),
        ),
      );

      // A reader who stopped a download has stopped wanting the book here, and
      // there is no half of it worth keeping.
      expect(blobs.objects, isEmpty);
      expect(blobs.aborted, 1);
    });
  });

  test('says the node does not hold the file, which is a state', () async {
    // D02 makes metadata without files a legitimate replica — the cheap copy a
    // reader is most likely to want on a node they do not own — so this is
    // something to show a reader rather than something to retry.
    await expectLater(
      downloader.download(ebookId: _work, expectedHash: '0' * 64),
      throwsA(
        isA<AppException>().having((e) => e.kind, 'kind', ErrorKind.notFound),
      ),
    );
  });
}

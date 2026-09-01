@TestOn('vm')
/// The outbox for files: what survives a restart, what waits, and what stops.
library;

import 'dart:io';

import 'package:atril/data/services/api/library_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/content/content_uploader.dart';
import 'package:atril/data/services/content/upload_queue.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import '../storage/memory_blob_store.dart';
import 'fake_content_service.dart';

final DateTime _at = DateTime.utc(2026, 9);

void main() {
  late FakeContentService node;
  late Server server;
  late NodeConnection connection;
  late SessionHolder session;
  late MemoryBlobStore blobs;
  late AtrilDatabase database;
  late UploadQueue queue;

  /// A queue over the same database and store, as a later launch would build
  /// one. It is what makes *survives a restart* something a test can watch:
  /// everything in memory is new and only the table is not.
  UploadQueue relaunch() => UploadQueue(
    database: database,
    uploader: ContentUploader(
      api: LibraryApi(connection: connection, session: session),
      blobs: blobs,
      chunkBytes: 64,
    ),
    now: () => _at,
  );

  /// Puts [bytes] in the store and tells the queue the node is owed them.
  Future<String> owe(List<int> bytes) async {
    final stored = await blobs.store(Stream<List<int>>.value(bytes));

    await queue.owe(
      contentHash: stored.contentHash,
      mediaType: 'application/epub+zip',
      sizeBytes: stored.sizeBytes,
    );

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
      refresher: () => throw StateError('an upload needs no refresh'),
    );
    blobs = MemoryBlobStore();
    database = AtrilDatabase(NativeDatabase.memory());
    queue = relaunch();
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
  });

  test('sends what is owed and stops owing it', () async {
    final digest = await owe(List<int>.filled(200, 7));

    node.claimed.add(digest);

    expect((await queue.run()).sent, 1);
    expect(node.held[digest]?.length, 200);
    expect(await database.transfersDao.pending(), isEmpty);
  });

  test('owes one file for two works imported from it', () async {
    // The object is shared between every work that names the digest, so a
    // reader who imported the same book twice owes one transfer — and the
    // second import must not reset an offset the node is part way through.
    final digest = await owe(List<int>.filled(100, 7));

    await queue.owe(
      contentHash: digest,
      mediaType: 'application/epub+zip',
      sizeBytes: 100,
    );

    expect(await database.transfersDao.pending(), hasLength(1));
  });

  test('waits rather than failing while the work has not been pushed', () async {
    // C16, and it is not an edge case: this app never calls CreateEbook, so
    // the *first* attempt of every freshly imported book answers this. An
    // import that lost its file because it happened on a train would be the
    // alternative.
    await owe(<int>[1, 2, 3]);

    final run = await queue.run();

    expect(run.waiting, 1);
    expect(run.failed, 0);
    expect(await database.transfersDao.pending(), hasLength(1));
  });

  test('sends it on the next pass once the work has been pushed', () async {
    final digest = await owe(<int>[1, 2, 3]);

    await queue.run();
    node.claimed.add(digest);

    expect((await queue.run()).sent, 1);
    expect(await database.transfersDao.pending(), isEmpty);
  });

  test('carries an interrupted upload across a restart', () async {
    // The whole of this commit. Everything in memory is thrown away between
    // the two passes and only the table survives, which is what closing the
    // app does to a transfer of a two-hundred-megabyte book.
    final digest = await owe(List<int>.filled(200, 7));

    node.claimed.add(digest);
    node.dropAfter = 64;

    expect((await queue.run()).waiting, 1);

    final owed = (await database.transfersDao.pending()).single;

    // The session was recorded before a byte travelled, which is what makes it
    // resumable at all. The offset was not: the reply that would have said
    // sixty-four is the one the connection lost, so this row says nought while
    // the node is holding sixty-four bytes.
    //
    // That is the design and not a gap. The row is a hint, the node's own
    // count is the authority, and the probe below is what asks it — a device
    // that had written down what it *sent* would resume past bytes that never
    // landed and find out at the digest, after the whole file had travelled.
    expect(owed.uploadId, isNotNull);
    expect(owed.sentBytes, 0);
    expect(node.uploads[owed.uploadId]?.offset, 64);

    node.chunks.clear();

    final relaunched = relaunch();

    expect((await relaunched.run()).sent, 1);
    expect(node.held[digest]?.length, 200);
    // The session was continued rather than begun again: the bytes already on
    // the node did not travel a second time.
    expect(node.chunks.first, (0, 0));
    expect(node.chunks.skip(1), <(int, int)>[(64, 64), (128, 64), (192, 8)]);
  });

  test('begins again when the node is no longer holding the session', () async {
    // D11 stages an upload in a file held in the node's process, so a restart
    // or an expiry invalidates a session this device still remembers. The
    // remembered identifier is a hint and never an assumption.
    final digest = await owe(List<int>.filled(100, 7));

    node.claimed.add(digest);
    node.dropAfter = 64;

    await queue.run();

    // The node forgets everything it was holding, as a restart would.
    node.uploads.clear();

    expect((await relaunch().run()).sent, 1);
    expect(node.held[digest]?.length, 100);
  });

  test('records why a transfer is still waiting', () async {
    final digest = await owe(<int>[1, 2, 3]);

    await queue.run();

    final owed = (await database.transfersDao.pending()).single;

    expect(owed.attempts, 1);
    expect(owed.attemptedAt, _at);
    expect(owed.contentHash, digest);
  });

  test('answers for every file rather than stopping at the first', () async {
    // A queue that gave up at the first failure would leave every book behind
    // one unsendable one waiting on it.
    final sendable = await owe(List<int>.filled(100, 7));

    await owe(List<int>.filled(120, 9));

    node.claimed.add(sendable);

    final run = await queue.run();

    expect(run.sent, 1);
    expect(run.waiting, 1);
  });

  test('does not start a second pass while one is running', () async {
    // The caller that would have been queued is a launch, a resume or a reader
    // tapping *try again*, and by the time the first pass ends it will have
    // covered what the second was going to send.
    final digest = await owe(List<int>.filled(2000, 7));

    node.claimed.add(digest);

    final first = queue.run();
    final second = await queue.run();

    expect(second.isEmpty, isTrue);
    expect((await first).sent, 1);
  });

  test('forgets a transfer the node turned out to already hold', () async {
    // Another device of the reader's sent the same file, or another reader on
    // the node had imported the same book. It is the answer this device wanted
    // reached by somebody else, and it is not a lesser one.
    final digest = await owe(<int>[1, 2, 3]);

    node.claimed.add(digest);
    node.held[digest] = await blobs.read(digest).first;

    expect((await queue.run()).sent, 1);
    expect(await database.transfersDao.pending(), isEmpty);
    expect(node.chunks, isEmpty);
  });
}

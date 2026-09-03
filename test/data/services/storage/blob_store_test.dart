/// The filesystem store, which is what five of the six targets run.
///
/// The browser's store is the same interface over the origin-private file
/// system and cannot be exercised here: it needs a page. What is checked here
/// is everything the two share — the addressing, the staging, the
/// deduplication and the refusal of a name that is not a digest — so that the
/// web implementation has a specification to be read against rather than only a
/// browser to be tried in.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atril/data/services/storage/blob_store.dart';
import 'package:atril/data/services/storage/blob_store_io.dart';
import 'package:atril/utils/errors.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

FileBlobStore open() {
  final root = Directory.systemTemp.createTempSync('atril-blobs');

  addTearDown(() => root.deleteSync(recursive: true));

  return FileBlobStore(root);
}

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

String _digest(String text) => sha256.convert(utf8.encode(text)).toString();

Future<int> _store(BlobStore store, String text) =>
    store.put(_digest(text), Stream<List<int>>.value(_bytes(text)));

Future<List<int>> _read(BlobStore store, String digest, {int from = 0}) async {
  final read = <int>[];

  await for (final chunk in store.read(digest, from: from)) {
    read.addAll(chunk);
  }

  return read;
}

void main() {
  const String work = 'os sertões';

  group('the blob store', () {
    test('holds bytes under the digest that identifies them', () async {
      final store = open();

      expect(await store.contains(_digest(work)), isFalse);
      expect(await _store(store, work), _bytes(work).length);

      expect(await store.contains(_digest(work)), isTrue);
      expect(await _read(store, _digest(work)), _bytes(work));
      expect(await store.sizeOf(_digest(work)), _bytes(work).length);
      expect(await store.digests(), <String>[_digest(work)]);
    });

    test('holds the same file once, however often it is imported', () async {
      final store = open();

      await _store(store, work);
      await _store(store, work);

      expect(await store.digests(), hasLength(1));
      expect(await store.usedBytes(), _bytes(work).length);
    });

    test('reads from an offset, which is what resumes an upload', () async {
      final store = open();

      await _store(store, work);

      expect(
        await _read(store, _digest(work), from: 3),
        _bytes(work).sublist(3),
      );
    });

    test(
      'answers a digest it does not hold with a failure that says so',
      () async {
        final store = open();

        await expectLater(
          store.read(_digest(work)).drain<void>(),
          throwsA(
            isA<AppException>()
                .having((e) => e.kind, 'kind', ErrorKind.notFound)
                .having((e) => e.code, 'code', codeBlobMissing),
          ),
        );

        expect(await store.sizeOf(_digest(work)), isNull);
        expect(await store.remove(_digest(work)), isFalse);
      },
    );

    test('refuses a name that is not a digest', () async {
      final store = open();

      await expectLater(
        store.contains('../../etc/passwd'),
        throwsA(isA<AppException>()),
      );
    });

    test(
      'removes what the reader asked to release, and nothing else',
      () async {
        final store = open();

        await _store(store, work);
        await _store(store, 'grande sertão');

        expect(await store.remove(_digest(work)), isTrue);
        expect(await store.digests(), <String>[_digest('grande sertão')]);
      },
    );
  });

  group('what the store announces', () {
    test('is what it published and what it removed, by digest', () async {
      // A download writes here and to no table, so this is the only way a
      // screen watching a work can learn that its file has arrived.
      final store = open();
      final heard = <String>[];
      final listening = store.changes.listen(heard.add);

      await _store(store, work);
      await store.remove(_digest(work));
      await Future<void>.delayed(Duration.zero);

      expect(heard, <String>[_digest(work), _digest(work)]);
      await listening.cancel();
    });

    test('is nothing for a write that changed nothing', () async {
      // A second import of a file already here is discarded, and the set of
      // what is held did not move — which is the fact a listener waits on.
      final store = open();
      final heard = <String>[];
      final listening = store.changes.listen(heard.add);

      await _store(store, work);
      await _store(store, work);
      await store.remove(_digest('never stored'));
      await Future<void>.delayed(Duration.zero);

      expect(heard, <String>[_digest(work)]);
      await listening.cancel();
    });
  });

  group('a staged write', () {
    test('is not addressable until it is published', () async {
      final store = open();
      final write = await store.beginWrite();

      await write.add(_bytes(work));

      expect(
        await store.contains(_digest(work)),
        isFalse,
        reason: 'a digest addresses bytes that have been hashed whole',
      );

      await write.commit(_digest(work));

      expect(await store.contains(_digest(work)), isTrue);
    });

    test('leaves nothing behind when it is abandoned', () async {
      final store = open();
      final write = await store.beginWrite();

      await write.add(_bytes(work));
      await write.abort();

      expect(await store.digests(), isEmpty);
      expect(await store.usedBytes(), 0);
    });

    test('counts against the budget while it is still running', () async {
      final store = open();
      final write = await store.beginWrite();

      await write.add(_bytes(work));

      expect(
        await store.usedBytes(),
        _bytes(work).length,
        reason: 'it is space the volume is not offering anybody else',
      );

      await write.abort();
    });

    test('is discarded where the bytes are already held', () async {
      final store = open();

      await _store(store, work);

      final write = await store.beginWrite();

      await write.add(_bytes(work));

      expect(await write.commit(_digest(work)), _bytes(work).length);
      expect(await store.usedBytes(), _bytes(work).length);
    });
  });
}

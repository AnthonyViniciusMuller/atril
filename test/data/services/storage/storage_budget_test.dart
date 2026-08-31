import 'dart:convert';
import 'dart:io';

import 'package:atril/data/services/storage/blob_store.dart';
import 'package:atril/data/services/storage/blob_store_io.dart';
import 'package:atril/data/services/storage/storage_budget.dart';
import 'package:atril/data/services/storage/storage_budget_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

FileBlobStore open() {
  final root = Directory.systemTemp.createTempSync('atril-budget');

  addTearDown(() => root.deleteSync(recursive: true));

  return FileBlobStore(root);
}

Future<int> store(BlobStore store, String text) => store.put(
  sha256.convert(utf8.encode(text)).toString(),
  Stream<List<int>>.value(utf8.encode(text)),
);

void main() {
  group('the budget', () {
    test('reports what the store holds', () async {
      final blobs = open();

      expect((await readStorageBudget(blobs)).used, 0);

      final written = await store(blobs, 'os sertões');

      expect((await readStorageBudget(blobs)).used, written);
    });

    test(
      'reports no total on a native target, and says it is unmeasured',
      () async {
        final budget = await readStorageBudget(open());

        expect(budget.quota, isNull);
        expect(budget.available, isNull);
        expect(budget.isMeasured, isFalse);
      },
    );

    test('does not refuse a download nothing has refused', () async {
      final budget = await readStorageBudget(open());

      expect(
        budget.fits(1 << 40),
        isTrue,
        reason: 'a store with no known limit knows of nothing to refuse',
      );
    });
  });

  group('a measured budget', () {
    test('answers what is left', () {
      const budget = StorageBudget(used: 400, quota: 1000);

      expect(budget.available, 600);
      expect(budget.isMeasured, isTrue);
      expect(budget.fits(600), isTrue);
      expect(budget.fits(601), isFalse);
    });

    test('never reports less than nothing left', () {
      const budget = StorageBudget(used: 1200, quota: 1000);

      expect(budget.available, 0);
      expect(budget.fits(1), isFalse);
    });
  });
}

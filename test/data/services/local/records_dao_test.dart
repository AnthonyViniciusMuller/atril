import 'package:atril/data/services/local/dao/records_dao.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/record_key.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _other = '22222222-2222-4222-8222-222222222222';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _shelf = 'bbbbbbbb-1111-4111-8111-111111111111';
const String _minted = 'cccccccc-1111-4111-8111-111111111111';
const String _second = 'dddddddd-1111-4111-8111-111111111111';

RecordsDao open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database.recordsDao;
}

void main() {
  group('the version of a record', () {
    test('is the empty clock for one this device has not touched', () async {
      final records = open();

      expect(
        await records.clockOf(RecordKey.record(TargetEntity.ebook, _work)),
        VectorClock.empty,
      );
    });

    test('is what the next change is stamped on top of', () async {
      final records = open();
      final key = RecordKey.record(TargetEntity.ebook, _work);

      await records.remember(
        key,
        recordId: _work,
        clock: VectorClock.of(<String, int>{_device: 2}),
      );

      expect(
        (await records.clockOf(key)).tick(_device),
        VectorClock.of(<String, int>{_device: 3}),
      );
    });

    test('is merged with what arrives, never replaced by it', () async {
      final records = open();
      final key = RecordKey.record(TargetEntity.annotation, _work);

      // What this device authored and has not pushed.
      await records.remember(
        key,
        recordId: _work,
        clock: VectorClock.of(<String, int>{_device: 3}),
      );

      // What a node answered, which has not heard of that write.
      await records.remember(
        key,
        recordId: _work,
        clock: VectorClock.of(<String, int>{_other: 5}),
      );

      expect(
        await records.clockOf(key),
        VectorClock.of(<String, int>{_device: 3, _other: 5}),
      );
    });
  });

  group('the identifier of an associative record', () {
    test('is minted once and reused on every write', () async {
      final records = open();
      final key = RecordKey.filing(ebookId: _work, collectionId: _shelf);

      expect(await records.identifierFor(key, mint: () => _minted), _minted);

      await records.remember(
        key,
        recordId: _minted,
        clock: VectorClock.empty.tick(_device),
      );

      expect(
        await records.identifierFor(key, mint: () => _second),
        _minted,
        reason: 'a device that minted another would name one record twice',
      );
    });

    test('does not change when a node answers with its own', () async {
      final records = open();
      final key = RecordKey.position(ebookId: _work);

      await records.remember(
        key,
        recordId: _minted,
        clock: VectorClock.empty.tick(_device),
      );
      await records.remember(
        key,
        recordId: _second,
        clock: VectorClock.of(<String, int>{_device: 2}),
      );

      expect((await records.versionOf(key))?.recordId, _minted);
    });

    test('addresses a filing by its pair and a position by its work', () {
      expect(
        RecordKey.filing(ebookId: _work, collectionId: _shelf).identity,
        '$_work:$_shelf',
      );
      expect(RecordKey.position(ebookId: _work).identity, _work);
      expect(
        RecordKey.filing(ebookId: _work, collectionId: _shelf),
        RecordKey.filing(ebookId: _work, collectionId: _shelf),
      );
    });
  });
}

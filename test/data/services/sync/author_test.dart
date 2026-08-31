/// Authoring a change: what is stamped, what is written, and what is owed.
library;

import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/sync/author.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/record_key.dart';
import 'package:atril/utils/errors.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _here = '11111111-1111-4111-8111-111111111111';
const String _there = '22222222-2222-4222-8222-222222222222';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _shelf = 'bbbbbbbb-1111-4111-8111-111111111111';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

const Map<String, Object?> _import = <String, Object?>{
  fieldTitle: 'Grande Sertão: Veredas',
  fieldFormat: 'epub',
  fieldContentHash: _hash,
};

/// A device whose wall clock is whatever the test last set it to.
final class _Wall {
  DateTime at = _at;

  DateTime read() => at;
}

typedef _Fixture = ({
  AtrilDatabase database,
  OperationAuthor author,
  Reconciler reconciler,
  HybridClock clock,
  _Wall wall,
});

int _minted = 0;

String _nextId() =>
    '${(++_minted).toString().padLeft(8, '0')}'
    '-1111-4111-8111-111111111111';

Future<_Fixture> _open({String? device = _here}) async {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  if (device != null) {
    await database.identityDao.bindDevice(
      id: device,
      name: 'o telefone',
      platform: 'android',
      at: _at,
    );
  }

  final wall = _Wall();
  final clock = HybridClock(wall: wall.read);
  final reconciler = Reconciler(database, clock);

  return (
    database: database,
    author: OperationAuthor(
      database: database,
      clock: clock,
      reconciler: reconciler,
      mint: _nextId,
    ),
    reconciler: reconciler,
    clock: clock,
    wall: wall,
  );
}

/// An operation as another device would have pushed it.
Operation _remote({
  required String targetId,
  TargetEntity entity = TargetEntity.ebook,
  OperationKind kind = OperationKind.insert,
  Map<String, Object?> delta = _import,
  int counter = 1,
  Duration at = Duration.zero,
}) => Operation(
  id: _nextId(),
  deviceId: _there,
  entity: entity,
  targetId: targetId,
  kind: kind,
  delta: delta,
  vectorClock: VectorClock.of(<String, int>{_there: counter}),
  createdAt: _at.add(at),
);

void main() {
  group('a change this device authors', () {
    test('creates the record and is owed to a node', () async {
      final fixture = await _open();

      final operation = await fixture.author.write(
        Change.insert(TargetEntity.ebook, _work, _import),
      );

      expect(operation.deviceId, _here);
      expect(operation.entity, TargetEntity.ebook);
      expect(operation.targetId, _work);
      expect(operation.vectorClock, VectorClock.of(<String, int>{_here: 1}));

      final stored = await fixture.database
          .select(fixture.database.ebooks)
          .getSingle();

      expect(stored.title, 'Grande Sertão: Veredas');
      expect(stored.deviceId, _here);
      expect(stored.updatedAt, operation.createdAt);

      final pending = await fixture.database.syncDao.pending();

      expect(pending.map((change) => change.id), <String>[operation.id]);
      expect(pending.single.delta, _import);
    });

    test(
      'is recorded as applied, so the node echoing it changes nothing',
      () async {
        final fixture = await _open();

        final operation = await fixture.author.write(
          Change.insert(TargetEntity.ebook, _work, _import),
        );

        final verdict = await fixture.reconciler.reconcile(operation);

        expect(verdict.outcome, ReconcileOutcome.duplicate);
      },
    );

    test('ticks the version this device last saw, and not the row', () async {
      final fixture = await _open();

      // Another device created the work at a version this one has to build on.
      await fixture.reconciler.reconcile(_remote(targetId: _work, counter: 4));

      final operation = await fixture.author.write(
        Change.update(TargetEntity.ebook, _work, <String, Object?>{
          fieldTitle: 'Sagarana',
        }),
      );

      expect(
        operation.vectorClock,
        VectorClock.of(<String, int>{_there: 4, _here: 1}),
      );

      final stored = await fixture.database
          .select(fixture.database.ebooks)
          .getSingle();

      expect(stored.title, 'Sagarana');
      expect(stored.deviceId, _here);
    });

    test('keeps the fields its delta does not name', () async {
      final fixture = await _open();

      await fixture.author.write(
        Change.insert(TargetEntity.ebook, _work, <String, Object?>{
          ..._import,
          fieldAuthor: 'João Guimarães Rosa',
        }),
      );
      await fixture.author.write(
        Change.update(TargetEntity.ebook, _work, <String, Object?>{
          fieldTitle: 'Sagarana',
        }),
      );

      final stored = await fixture.database
          .select(fixture.database.ebooks)
          .getSingle();

      expect(stored.title, 'Sagarana');
      expect(stored.author, 'João Guimarães Rosa');
    });

    test('records the version the next change is stamped on', () async {
      final fixture = await _open();

      await fixture.author.write(
        Change.insert(TargetEntity.collection, _shelf, <String, Object?>{
          fieldName: 'Para reler',
        }),
      );

      final version = await fixture.database.recordsDao.versionOf(
        RecordKey.record(TargetEntity.collection, _shelf),
      );

      expect(version, isNotNull);
      expect(version!.recordId, _shelf);
      expect(version.vectorClock, VectorClock.of(<String, int>{_here: 1}));
    });

    test('tombstones rather than removes', () async {
      final fixture = await _open();

      await fixture.author.write(
        Change.insert(TargetEntity.ebook, _work, _import),
      );
      final removal = await fixture.author.write(
        Change.delete(TargetEntity.ebook, _work),
      );

      expect(removal.kind, OperationKind.delete);
      expect(removal.delta, isEmpty);

      final stored = await fixture.database
          .select(fixture.database.ebooks)
          .getSingle();

      expect(stored.deleted, isTrue);
      expect(stored.title, 'Grande Sertão: Veredas');
    });
  });

  group('the instant a change carries', () {
    test('is later than every change before it', () async {
      final fixture = await _open();

      final first = await fixture.author.write(
        Change.insert(TargetEntity.ebook, _work, _import),
      );
      final second = await fixture.author.write(
        Change.update(TargetEntity.ebook, _work, <String, Object?>{
          fieldTitle: 'Sagarana',
        }),
      );

      expect(second.createdAt.isAfter(first.createdAt), isTrue);
    });

    test('is later than the version it was derived from, whatever the wall '
        'clock says', () async {
      final fixture = await _open();

      // A row the device holds at an instant it never observed, which is what a
      // seed leaves behind: the node's timestamp went into the replica and not
      // into this device's clock.
      await fixture.reconciler.reconcile(
        _remote(targetId: _work, at: const Duration(days: 30)),
      );

      // And a wall clock that has not caught up with it.
      fixture.wall.at = _at;

      final operation = await fixture.author.write(
        Change.update(TargetEntity.ebook, _work, <String, Object?>{
          fieldTitle: 'Sagarana',
        }),
      );

      expect(
        operation.createdAt.isAfter(_at.add(const Duration(days: 30))),
        isTrue,
      );
    });
  });

  group('a change that cannot be authored', () {
    test('is refused on a device that has never been bound', () async {
      final fixture = await _open(device: null);

      await expectLater(
        fixture.author.write(Change.insert(TargetEntity.ebook, _work, _import)),
        throwsA(
          isA<AppException>()
              .having((f) => f.kind, 'kind', ErrorKind.failedPrecondition)
              .having((f) => f.code, 'code', 'device_not_bound'),
        ),
      );
    });

    test('is refused when it claims no field', () async {
      final fixture = await _open();

      await fixture.author.write(
        Change.insert(TargetEntity.ebook, _work, _import),
      );

      await expectLater(
        fixture.author.write(
          Change.update(TargetEntity.ebook, _work, const <String, Object?>{}),
        ),
        throwsA(
          isA<AppException>().having((f) => f.code, 'code', 'empty_delta'),
        ),
      );

      expect(await fixture.database.syncDao.pendingCount(), 1);
    });

    test('leaves nothing behind when the replica refuses it', () async {
      final fixture = await _open();

      await expectLater(
        fixture.author.write(
          Change.update(TargetEntity.ebook, _work, <String, Object?>{
            fieldTitle: 'Sagarana',
          }),
        ),
        throwsA(
          isA<AppException>().having((f) => f.code, 'code', 'change_refused'),
        ),
      );

      expect(
        await fixture.database.select(fixture.database.ebooks).get(),
        isEmpty,
      );
      expect(await fixture.database.syncDao.pendingCount(), 0);
      expect(await fixture.database.recordsDao.versions(), isEmpty);
    });
  });
}

import 'dart:async';

import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// A wall clock a test drives, including backwards.
class _Wall {
  _Wall(this.reading);

  DateTime reading;

  DateTime call() => reading;
}

/// A store that records what the clock asked it to keep.
class _RecordingStore implements HybridClockStore {
  _RecordingStore({this.floor});

  final DateTime? floor;
  final List<DateTime> saved = <DateTime>[];

  /// Held open by a test that wants to see what the clock does while a write
  /// is in flight.
  Completer<void>? gate;

  @override
  Future<DateTime?> load() async => floor;

  @override
  Future<void> save(DateTime instant) async {
    saved.add(instant);

    await gate?.future;
  }
}

/// A store whose writes fail, which is a full disk or a database that was
/// closed under the clock.
class _FailingStore implements HybridClockStore {
  @override
  Future<DateTime?> load() async => null;

  @override
  Future<void> save(DateTime instant) async {
    throw StateError('the database is closed');
  }
}

DateTime _at(
  int year, [
  int month = 1,
  int day = 1,
  int hour = 0,
  int minute = 0,
  int second = 0,
]) => DateTime.utc(year, month, day, hour, minute, second);

void main() {
  group('HybridClock.now', () {
    test('reads the wall clock when it is ahead of the floor', () {
      final wall = _Wall(_at(2026, 8, 31, 12));
      final clock = HybridClock(wall: wall.call);

      expect(clock.now(), _at(2026, 8, 31, 12));
    });

    test('stamps in UTC whatever zone the wall clock reads in', () {
      final local = DateTime(2026, 8, 31, 12);
      final clock = HybridClock(wall: () => local);

      final stamped = clock.now();

      expect(stamped.isUtc, isTrue);
      expect(stamped, local.toUtc());
    });

    test('steps past the floor when the wall clock has not moved', () {
      // This is the rule itself: t = max(wall, observed + one step).
      final wall = _Wall(_at(2026, 8, 31, 12));
      final clock = HybridClock(wall: wall.call);

      final first = clock.now();
      final second = clock.now();
      final third = clock.now();

      expect(second, first.add(clockResolution));
      expect(third, second.add(clockResolution));
    });

    test('never goes backwards when the wall clock does', () {
      // A device whose clock is corrected while the app is open, which is the
      // condition the whole type exists for.
      final wall = _Wall(_at(2026, 8, 31, 12));
      final clock = HybridClock(wall: wall.call);

      final before = clock.now();
      wall.reading = _at(2026, 8, 31, 11);
      final after = clock.now();

      expect(after.isAfter(before), isTrue);
      expect(after, before.add(clockResolution));
    });

    test('follows the wall clock once it has moved past the floor', () {
      final wall = _Wall(_at(2026, 8, 31, 12));
      final clock = HybridClock(wall: wall.call);

      clock.now();
      wall.reading = _at(2026, 8, 31, 13);

      expect(clock.now(), _at(2026, 8, 31, 13));
    });

    test('is monotone on a wall clock with millisecond resolution', () {
      // A browser reads a JavaScript Date, so a thousand writes inside one
      // millisecond all see the same instant. The step is what separates them,
      // and the values stay inside the millisecond they were made in.
      final millisecond = _at(2026, 8, 31, 12);
      final clock = HybridClock(wall: () => millisecond);

      final stamps = <DateTime>[
        for (var write = 0; write < 1000; write++) clock.now(),
      ];

      expect(stamps.toSet(), hasLength(1000));

      for (var index = 1; index < stamps.length; index++) {
        expect(stamps[index].isAfter(stamps[index - 1]), isTrue);
      }

      expect(
        stamps.last.difference(millisecond),
        const Duration(milliseconds: 1) - clockResolution,
      );
    });

    test('advances what the clock reports as observed', () {
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));

      expect(
        clock.observed,
        DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true),
      );

      final stamped = clock.now();

      expect(clock.observed, stamped);
      expect(
        clock.observed,
        stamped,
        reason: 'reading it twice advances nothing',
      );
    });
  });

  group('HybridClock.observe', () {
    test('adopts a later instant, so the next stamp is after it', () {
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));
      final peer = _at(2026, 8, 31, 12, 2);

      expect(clock.observe(peer), isTrue);
      expect(clock.observed, peer);
      expect(clock.now(), peer.add(clockResolution));
    });

    test('ignores an instant it is already past', () {
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));
      final stamped = clock.now();

      expect(clock.observe(_at(2026, 8, 31, 11)), isTrue);
      expect(clock.observed, stamped);
    });

    test('adopts an instant in another zone as its UTC value', () {
      // Both readings are local, so the test says nothing about the offset of
      // the machine it runs on — only that what the clock keeps is UTC.
      final local = DateTime(2026, 8, 31, 12);
      final clock = HybridClock(wall: () => local);
      final peer = local.add(const Duration(minutes: 1));

      expect(clock.observe(peer), isTrue);
      expect(clock.observed, peer.toUtc());
      expect(clock.observed.isUtc, isTrue);
    });

    test('refuses an instant further ahead than the drift allows', () {
      // A peer with a clock a year fast would otherwise take this device with
      // it, and every tie against a correctly stamped write would go to
      // whichever record had been poisoned.
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));
      final broken = _at(2027, 8, 31, 12);

      expect(clock.observe(broken), isFalse);
      expect(
        clock.observed,
        DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true),
      );
      expect(clock.now(), _at(2026, 8, 31, 12));
    });

    test('adopts an instant inside the drift', () {
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));
      final ahead = _at(2026, 8, 31, 12, 4);

      expect(clock.observe(ahead), isTrue);
      expect(clock.observed, ahead);
    });
  });

  group('HybridClock.restore', () {
    test('resumes from the floor the store holds', () async {
      // A device whose wall clock is behind what it already stamped. Without
      // the floor it would stamp the same instants a second time.
      final floor = _at(2026, 8, 31, 12);
      final store = _RecordingStore(floor: floor);

      final clock = await HybridClock.restore(
        store: store,
        wall: () => _at(2026, 8, 31, 11),
      );

      expect(clock.observed, floor);
      expect(clock.now(), floor.add(clockResolution));
    });

    test('starts from the wall clock when nothing was kept', () async {
      final clock = await HybridClock.restore(
        store: _RecordingStore(),
        wall: () => _at(2026, 8, 31, 12),
      );

      expect(clock.now(), _at(2026, 8, 31, 12));
    });
  });

  group('the floor it persists', () {
    test('is written after a stamp', () async {
      final store = _RecordingStore();
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12), store: store);

      final stamped = clock.now();
      await pumpEventQueue();

      expect(store.saved, <DateTime>[stamped]);
    });

    test('is written after an adopted observation', () async {
      final store = _RecordingStore();
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12), store: store);
      final peer = _at(2026, 8, 31, 12, 1);

      expect(clock.observe(peer), isTrue);
      await pumpEventQueue();

      expect(store.saved, <DateTime>[peer]);
    });

    test('is not written for an observation that changed nothing', () async {
      final store = _RecordingStore();
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12), store: store);

      clock.now();
      await pumpEventQueue();
      store.saved.clear();

      expect(
        clock.observe(_at(2026, 8, 31, 11)),
        isTrue,
        reason: 'an instant already covered is still an instant it accepted',
      );
      await pumpEventQueue();

      expect(store.saved, isEmpty);
    });

    test('is written once for a burst, carrying the greatest instant', () async {
      // What has to survive a restart is the greatest instant, and every value
      // between it and the one being written is already covered by it. A burst
      // of annotations costs two writes rather than one per annotation.
      final store = _RecordingStore()..gate = Completer<void>();
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12), store: store);

      final first = clock.now();
      await pumpEventQueue();

      expect(store.saved, <DateTime>[first]);

      clock.now();
      clock.now();
      final last = clock.now();

      store.gate!.complete();
      await pumpEventQueue();

      expect(store.saved, <DateTime>[first, last]);
    });

    test('reports a failed write without failing the stamp', () async {
      final failures = <Object>[];
      final clock = HybridClock(
        wall: () => _at(2026, 8, 31, 12),
        store: _FailingStore(),
        onStoreError: (error, stackTrace) => failures.add(error),
      );

      final stamped = clock.now();
      await pumpEventQueue();

      expect(stamped, _at(2026, 8, 31, 12));
      expect(failures, hasLength(1));
      expect(failures.single, isStateError);
    });

    test('keeps writing after a failure', () async {
      final failures = <Object>[];
      final clock = HybridClock(
        wall: () => _at(2026, 8, 31, 12),
        store: _FailingStore(),
        onStoreError: (error, stackTrace) => failures.add(error),
      );

      clock.now();
      await pumpEventQueue();
      clock.now();
      await pumpEventQueue();

      expect(failures, hasLength(2));
    });

    test('is not asked for by a clock built without a store', () async {
      final clock = HybridClock(wall: () => _at(2026, 8, 31, 12));

      clock.now();
      await pumpEventQueue();

      expect(clock.observed, _at(2026, 8, 31, 12));
    });
  });
}

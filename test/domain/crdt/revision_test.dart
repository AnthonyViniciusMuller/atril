import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two devices, spelled as they are stored: a canonical lowercase identifier,
/// which is the key a clock entry is counted under and the value the tie-break
/// compares.
const String _phone = '11111111-1111-4111-8111-111111111111';
const String _laptop = '22222222-2222-4222-8222-222222222222';

DateTime _at(int minute, [int second = 0, int microsecond = 0]) =>
    DateTime.utc(2026, 8, 31, 12, minute, second, 0, microsecond);

void main() {
  group('Revision.first', () {
    test('observes one event, from the authoring device alone', () {
      final revision = Revision.first(_phone, _at(0));

      expect(revision.vectorClock, VectorClock.empty.tick(_phone));
      expect(revision.deviceId, _phone);
      expect(revision.updatedAt, _at(0));
      expect(revision.deleted, isFalse);
    });

    test('stamps in UTC', () {
      final revision = Revision.first(_phone, DateTime(2026, 8, 31, 12));

      expect(revision.updatedAt.isUtc, isTrue);
      expect(revision.updatedAt, DateTime(2026, 8, 31, 12).toUtc());
    });
  });

  group('Revision.next', () {
    test('ticks the clock, so the new version dominates the old', () {
      final first = Revision.first(_phone, _at(0));
      final second = first.next(_phone, _at(1));

      expect(second.vectorClock[_phone], 2);
      expect(second.vectorClock.happensAfter(first.vectorClock), isTrue);
      expect(second.supersedes(first), isTrue);
      expect(first.supersedes(second), isFalse);
    });

    test('records the device whose write the record now reflects', () {
      // C10: it is not the device that created the record.
      final first = Revision.first(_phone, _at(0));
      final second = first.next(_laptop, _at(1));

      expect(second.deviceId, _laptop);
      expect(second.vectorClock[_phone], 1);
      expect(second.vectorClock[_laptop], 1);
    });

    test('stamps past the previous version when the clock ran backwards', () {
      // The per-record half of C01. Without it a causally later version could
      // carry an earlier instant, and the tie-break relation would have a cycle.
      final first = Revision.first(_phone, _at(1));
      final second = first.next(_phone, _at(0));

      expect(second.updatedAt, first.updatedAt.add(clockResolution));
      expect(second.updatedAt.isAfter(first.updatedAt), isTrue);
    });

    test('stamps past the previous version when the instant repeats', () {
      final first = Revision.first(_phone, _at(0));
      final second = first.next(_phone, _at(0));
      final third = second.next(_phone, _at(0));

      expect(second.updatedAt, first.updatedAt.add(clockResolution));
      expect(third.updatedAt, second.updatedAt.add(clockResolution));
    });

    test('takes the reading when it is already past the floor', () {
      final first = Revision.first(_phone, _at(0));
      final second = first.next(_phone, _at(5));

      expect(second.updatedAt, _at(5));
    });

    test('leaves the revision it was derived from alone', () {
      final first = Revision.first(_phone, _at(0));

      first.next(_laptop, _at(1));

      expect(first.deviceId, _phone);
      expect(first.vectorClock, VectorClock.empty.tick(_phone));
    });

    test('does not clear the tombstone', () {
      // A record is undeleted by a write that says so, not by any write that
      // happens to follow the deletion.
      final deleted = Revision.first(_phone, _at(0)).tombstone(_phone, _at(1));
      final written = deleted.next(_phone, _at(2));

      expect(written.deleted, isTrue);
    });
  });

  group('Revision.tombstone and Revision.restore', () {
    test('a deletion is a write, and reconciles like one', () {
      final present = Revision.first(_phone, _at(0));
      final deleted = present.tombstone(_phone, _at(1));

      expect(deleted.deleted, isTrue);
      expect(deleted.supersedes(present), isTrue);
      expect(deleted.vectorClock[_phone], 2);
    });

    test('a restore is a write that says the record is present again', () {
      final deleted = Revision.first(_phone, _at(0)).tombstone(_phone, _at(1));
      final restored = deleted.restore(_laptop, _at(2));

      expect(restored.deleted, isFalse);
      expect(restored.supersedes(deleted), isTrue);
      expect(restored.deviceId, _laptop);
    });
  });

  group('Revision.zero', () {
    test('has no causal history', () {
      expect(Revision.zero.isZero, isTrue);
    });

    test('is what a record that has been written once is not', () {
      expect(Revision.first(_phone, _at(0)).isZero, isFalse);
    });

    test('is superseded by any revision', () {
      expect(Revision.first(_phone, _at(0)).supersedes(Revision.zero), isTrue);
      expect(Revision.zero.supersedes(Revision.first(_phone, _at(0))), isFalse);
    });
  });

  group('supersedes', () {
    test('consults the clock and nothing else where it decides', () {
      // The later version wins on the tie-break fields too, so this only shows
      // the clock deciding if the fields point the other way: the loser carries
      // the later instant and the larger device identifier.
      final first = Revision(
        vectorClock: VectorClock.of(const <String, int>{_phone: 1}),
        updatedAt: _at(9),
        deviceId: _laptop,
      );
      final second = Revision(
        vectorClock: VectorClock.of(const <String, int>{_phone: 2}),
        updatedAt: _at(0),
        deviceId: _phone,
      );

      expect(second.vectorClock.happensAfter(first.vectorClock), isTrue);
      expect(second.supersedes(first), isTrue);
      expect(first.supersedes(second), isFalse);
    });

    test('is false for two revisions describing the same version', () {
      // A strict order: an operation that adds nothing to what the record
      // already reflects is superseded rather than applied.
      final revision = Revision.first(_phone, _at(0));
      final same = Revision(
        vectorClock: revision.vectorClock,
        updatedAt: revision.updatedAt,
        deviceId: revision.deviceId,
      );

      expect(revision.supersedes(same), isFalse);
      expect(same.supersedes(revision), isFalse);
    });

    test('breaks a concurrent pair on the later instant', () {
      final base = Revision.first(_phone, _at(0));
      final mine = base.next(_phone, _at(1));
      final theirs = base.next(_laptop, _at(2));

      expect(mine.vectorClock.isConcurrentWith(theirs.vectorClock), isTrue);
      expect(theirs.supersedes(mine), isTrue);
      expect(mine.supersedes(theirs), isFalse);
    });

    test('breaks an equal instant on the device identifier', () {
      // Two devices that have never heard of each other can stamp the same
      // microsecond. Any fixed rule settles them, provided every replica
      // applies the same one.
      final base = Revision.first(_phone, _at(0));
      final mine = base.next(_phone, _at(1));
      final theirs = base.next(_laptop, _at(1));

      expect(mine.updatedAt.isAtSameMomentAs(theirs.updatedAt), isTrue);
      expect(
        theirs.supersedes(mine),
        isTrue,
        reason: '$_laptop sorts after $_phone',
      );
      expect(mine.supersedes(theirs), isFalse);
    });

    test('decides a concurrent pair the same way from either side', () {
      final base = Revision.first(_phone, _at(0));
      final mine = base.next(_phone, _at(1));
      final theirs = base.next(_laptop, _at(2));

      expect(mine.merge(theirs), theirs);
      expect(theirs.merge(mine), theirs);
    });
  });

  group('merge', () {
    test('keeps the version that survives, whole', () {
      final base = Revision.first(_phone, _at(0));
      final later = base.next(_phone, _at(1));

      expect(base.merge(later), later);
      expect(later.merge(base), later);
    });

    test('keeps this one when neither supersedes the other', () {
      final revision = Revision.first(_phone, _at(0));
      final same = Revision(
        vectorClock: revision.vectorClock,
        updatedAt: revision.updatedAt,
        deviceId: revision.deviceId,
      );

      expect(identical(revision.merge(same), revision), isTrue);
    });

    test('is idempotent', () {
      final revision = Revision.first(_phone, _at(0));

      expect(revision.merge(revision), revision);
    });
  });

  group('Revision equality', () {
    test('compares every field', () {
      final revision = Revision.first(_phone, _at(0));

      expect(
        revision,
        Revision(
          vectorClock: VectorClock.empty.tick(_phone),
          updatedAt: _at(0),
          deviceId: _phone,
        ),
      );
      expect(
        revision.hashCode,
        Revision(
          vectorClock: VectorClock.empty.tick(_phone),
          updatedAt: _at(0),
          deviceId: _phone,
        ).hashCode,
      );
      expect(revision, isNot(revision.tombstone(_phone, _at(1))));
    });

    test('compares the instant and not the zone it is written in', () {
      final local = DateTime(2026, 8, 31, 12);

      expect(
        Revision(
          vectorClock: VectorClock.empty.tick(_phone),
          updatedAt: local,
          deviceId: _phone,
        ),
        Revision(
          vectorClock: VectorClock.empty.tick(_phone),
          updatedAt: local.toUtc(),
          deviceId: _phone,
        ),
      );
    });
  });

  group('Version', () {
    test('first observes one event from its only writer', () {
      final version = Version.first(_phone, _at(0));

      expect(version.vectorClock, VectorClock.empty.tick(_phone));
      expect(version.updatedAt, _at(0));
      expect(version.vectorClock.length, 1);
    });

    test('next ticks the clock and stamps past the previous instant', () {
      final first = Version.first(_phone, _at(1));
      final second = first.next(_phone, _at(0));

      expect(second.vectorClock[_phone], 2);
      expect(second.updatedAt, first.updatedAt.add(clockResolution));
    });

    test('supersedes only where the clock says so', () {
      final first = Version.first(_phone, _at(0));
      final second = first.next(_phone, _at(1));

      expect(second.supersedes(first), isTrue);
      expect(first.supersedes(second), isFalse);
      expect(first.supersedes(first), isFalse);
    });

    test('leaves a concurrent pair alone rather than breaking a tie', () {
      // C05: a progress row has one writer, so a concurrent pair is a row
      // written by a device that had no business writing it. Neither
      // supersedes, and merge keeps what is here until somebody looks.
      final base = Version.first(_phone, _at(0));
      final mine = base.next(_phone, _at(1));
      final theirs = base.next(_laptop, _at(9));

      expect(mine.vectorClock.isConcurrentWith(theirs.vectorClock), isTrue);
      expect(mine.supersedes(theirs), isFalse);
      expect(theirs.supersedes(mine), isFalse);
      expect(mine.merge(theirs), mine);
      expect(theirs.merge(mine), theirs);
    });

    test('merge keeps the later version', () {
      final first = Version.first(_phone, _at(0));
      final second = first.next(_phone, _at(1));

      expect(first.merge(second), second);
      expect(second.merge(first), second);
    });

    test('zero has no causal history', () {
      expect(Version.zero.isZero, isTrue);
      expect(Version.first(_phone, _at(0)).isZero, isFalse);
    });

    test('compares by clock and instant', () {
      expect(
        Version.first(_phone, _at(0)),
        Version(vectorClock: VectorClock.empty.tick(_phone), updatedAt: _at(0)),
      );
      expect(
        Version.first(_phone, _at(0)).hashCode,
        Version(
          vectorClock: VectorClock.empty.tick(_phone),
          updatedAt: _at(0),
        ).hashCode,
      );
    });
  });
}

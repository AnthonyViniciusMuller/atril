import 'package:atril/domain/crdt/ordering.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VectorClock', () {
    test('the empty clock has observed nothing', () {
      expect(VectorClock.empty.isEmpty, isTrue);
      expect(VectorClock.empty.isNotEmpty, isFalse);
      expect(VectorClock.empty.length, 0);
      expect(VectorClock.empty['a'], 0);
      expect(VectorClock.empty.devices, isEmpty);
    });

    test('a device never seen is counted at zero', () {
      final clock = VectorClock.of(const <String, int>{'a': 2});

      expect(clock['b'], 0);
    });

    test('a device at zero and a device absent are the same history', () {
      final counted = VectorClock.of(const <String, int>{'a': 1, 'b': 0});
      final absent = VectorClock.of(const <String, int>{'a': 1});

      expect(counted, absent);
      expect(counted.hashCode, absent.hashCode);
      expect(counted.length, 1);
      expect(counted.compare(absent), Ordering.equal);
      expect(counted.toJson(), absent.toJson());
    });

    test('a negative counter is refused rather than dropped', () {
      expect(
        () => VectorClock.of(const <String, int>{'a': -1}),
        throwsArgumentError,
      );
    });

    test('the map it was built from cannot change it afterwards', () {
      final counters = <String, int>{'a': 1};
      final clock = VectorClock.of(counters);

      counters['a'] = 99;
      counters['b'] = 5;

      expect(clock['a'], 1);
      expect(clock['b'], 0);
    });

    test('tick advances one device and leaves the rest alone', () {
      final clock = VectorClock.of(const <String, int>{'a': 1, 'b': 3});
      final ticked = clock.tick('a');

      expect(ticked['a'], 2);
      expect(ticked['b'], 3);
      expect(clock['a'], 1, reason: 'tick returns a new clock');
    });

    test('tick starts a device the clock had never seen', () {
      expect(VectorClock.empty.tick('a')['a'], 1);
    });

    test('merge takes the larger counter of each device', () {
      final one = VectorClock.of(const <String, int>{'a': 3, 'b': 1});
      final other = VectorClock.of(const <String, int>{'b': 4, 'c': 2});

      final merged = one.merge(other);

      expect(merged['a'], 3);
      expect(merged['b'], 4);
      expect(merged['c'], 2);
    });

    test('merge leaves both operands alone', () {
      final one = VectorClock.of(const <String, int>{'a': 1});
      final other = VectorClock.of(const <String, int>{'b': 1});

      one.merge(other);

      expect(one, VectorClock.of(const <String, int>{'a': 1}));
      expect(other, VectorClock.of(const <String, int>{'b': 1}));
    });

    group('compare', () {
      test('reports equal for the same history', () {
        final one = VectorClock.of(const <String, int>{'a': 1, 'b': 2});
        final other = VectorClock.of(const <String, int>{'b': 2, 'a': 1});

        expect(one.compare(other), Ordering.equal);
        expect(one, other);
      });

      test('reports before for a history the other extends', () {
        final earlier = VectorClock.of(const <String, int>{'a': 1});
        final later = earlier.tick('a').tick('b');

        expect(earlier.compare(later), Ordering.before);
        expect(earlier.happensBefore(later), isTrue);
        expect(later.compare(earlier), Ordering.after);
        expect(later.happensAfter(earlier), isTrue);
      });

      test('reports concurrent when each observed what the other did not', () {
        final one = VectorClock.of(const <String, int>{'a': 2, 'b': 1});
        final other = VectorClock.of(const <String, int>{'a': 1, 'b': 2});

        expect(one.compare(other), Ordering.concurrent);
        expect(one.isConcurrentWith(other), isTrue);
        expect(other.isConcurrentWith(one), isTrue);
      });

      test('reports concurrent for two clocks over disjoint devices', () {
        final one = VectorClock.empty.tick('a');
        final other = VectorClock.empty.tick('b');

        expect(one.compare(other), Ordering.concurrent);
      });

      test('the empty clock precedes anything that observed something', () {
        final clock = VectorClock.empty.tick('a');

        expect(VectorClock.empty.compare(clock), Ordering.before);
        expect(clock.compare(VectorClock.empty), Ordering.after);
        expect(VectorClock.empty.compare(VectorClock.empty), Ordering.equal);
      });
    });

    test('dominates covers everything the other has observed', () {
      final clock = VectorClock.of(const <String, int>{'a': 2, 'b': 1});

      expect(
        clock.dominates(VectorClock.of(const <String, int>{'a': 1})),
        isTrue,
      );
      expect(clock.dominates(clock), isTrue, reason: 'equal dominates');
      expect(clock.dominates(clock.tick('a')), isFalse);
      expect(
        clock.dominates(VectorClock.of(const <String, int>{'c': 1})),
        isFalse,
        reason: 'concurrent does not dominate',
      );
    });

    group('json', () {
      test('encodes the devices in a stable order', () {
        final clock = VectorClock.of(const <String, int>{
          'c': 1,
          'a': 2,
          'b': 3,
        });

        expect(clock.toJson().keys, <String>['a', 'b', 'c']);
      });

      test('round trips a history unchanged', () {
        final clock = VectorClock.of(const <String, int>{'a': 2, 'b': 5});

        expect(VectorClock.fromJson(clock.toJson()), clock);
      });

      test('an empty object decodes to the empty clock', () {
        expect(
          VectorClock.fromJson(const <String, Object?>{}),
          VectorClock.empty,
        );
      });

      test('decoding drops the entries at zero', () {
        expect(
          VectorClock.fromJson(const <String, Object?>{'a': 1, 'b': 0}),
          VectorClock.of(const <String, int>{'a': 1}),
        );
      });

      test('a counter that is not an integer is a format exception', () {
        expect(
          () => VectorClock.fromJson(const <String, Object?>{'a': '1'}),
          throwsFormatException,
        );
      });

      test('equal histories encode to equal maps', () {
        final one = VectorClock.of(const <String, int>{'a': 1, 'b': 2});
        final other = VectorClock.empty.tick('b').tick('a').tick('b');

        expect(one, other);
        expect(other.toJson(), one.toJson());
      });
    });

    test('renders its devices in a stable order', () {
      final clock = VectorClock.of(const <String, int>{'b': 2, 'a': 1});

      expect(clock.toString(), '{a:1 b:2}');
      expect(VectorClock.empty.toString(), '{}');
    });
  });

  group('Ordering', () {
    test('reversed is the relation seen from the other operand', () {
      expect(Ordering.before.reversed, Ordering.after);
      expect(Ordering.after.reversed, Ordering.before);
      expect(Ordering.equal.reversed, Ordering.equal);
      expect(Ordering.concurrent.reversed, Ordering.concurrent);
    });

    test('every relation has a label', () {
      for (final ordering in Ordering.values) {
        expect(ordering.label, isNotEmpty);
        expect(ordering.toString(), ordering.label);
      }
    });
  });
}

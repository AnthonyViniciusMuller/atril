import 'dart:math';

import 'package:atril/domain/crdt/ordering.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// The merge laws are what make offline reconciliation work at all. Replicas
/// exchange state in whatever order the network allows, more than once, and in
/// batches grouped differently on each side; convergence is guaranteed only
/// because the join is idempotent, commutative and associative, which is
/// precisely the statement that the outcome depends on none of the three.
///
/// These are the properties `crdt/merge_laws_test.go` checks on the node,
/// written again here against the same laws and generated the same way. That
/// they are checked twice is the point: the node and this client each hold a
/// replica, and a client whose join disagreed with the node's would converge on
/// a different library while both sides believed they had merged.
///
/// The generation is Quire's: a small device alphabet and low counters, so that
/// clocks overlap often enough for concurrency to be generated at all, and a
/// fixed seed, so that a failure is reproducible and CI does not flake.

/// How many random cases each law is checked against.
const int _iterations = 2000;

/// The seed, fixed. Change it to explore a different corner of the space.
const int _seed = 0x5175697265; // "Quire"

/// Drawn from a small alphabet on purpose: clocks must overlap often, or
/// concurrency would almost never be generated.
const int _deviceCount = 4;

/// Kept low for the same reason.
const int _maxCounter = 5;

/// The generator for one property, seeded deterministically from its name so
/// that two properties do not walk the same sequence.
Random _random(String property) => Random(_seed ^ property.length);

/// The device at [index] of the alphabet the clocks are built over.
String _deviceAt(int index) => String.fromCharCode('a'.codeUnitAt(0) + index);

/// A device drawn from that alphabet.
String _device(Random random) => _deviceAt(random.nextInt(_deviceCount));

/// A clock over the small alphabet, including the empty clock and clocks with
/// explicit zero entries.
VectorClock _randomClock(Random random) {
  final counters = <String, int>{};

  for (var device = 0; device < _deviceCount; device++) {
    if (random.nextInt(3) == 0) {
      continue;
    }

    counters[_deviceAt(device)] = random.nextInt(_maxCounter);
  }

  return VectorClock.of(counters);
}

/// Three clocks in causal order, each derived from the last by a few ticks.
///
/// Random triples almost never happen to be causally ordered, so the properties
/// about happens-before need histories built on purpose.
({VectorClock first, VectorClock second, VectorClock third}) _randomChain(
  Random random,
) {
  final first = _randomClock(random);

  var second = first;
  for (var tick = 0; tick <= random.nextInt(3); tick++) {
    second = second.tick(_device(random));
  }

  var third = second;
  for (var tick = 0; tick <= random.nextInt(3); tick++) {
    third = third.tick(_device(random));
  }

  return (first: first, second: second, third: third);
}

void main() {
  group('the join', () {
    test('is commutative', () {
      // Two replicas reconciling the same pair of states must reach the same
      // result, whichever of them received the other's state.
      final random = _random('commutative');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);

        expect(
          left.merge(right),
          right.merge(left),
          reason: 'merging $left and $right depended on the order',
        );
      }
    });

    test('is associative', () {
      // A replica may receive three states in one batch or in three, grouped
      // any way. The grouping must not change where it lands.
      final random = _random('associative');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final first = _randomClock(random);
        final second = _randomClock(random);
        final third = _randomClock(random);

        expect(
          first.merge(second).merge(third),
          first.merge(second.merge(third)),
          reason: 'merging $first, $second and $third depended on the grouping',
        );
      }
    });

    test('is idempotent', () {
      // Replication retries, and a redelivered operation must be a no-op. This
      // is what makes at-least-once delivery sufficient.
      final random = _random('idempotent');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final clock = _randomClock(random);

        expect(clock.merge(clock), clock, reason: '$clock merged into itself');
      }
    });

    test('has the empty clock as its identity', () {
      // A device that has never written must not perturb what it merges into.
      final random = _random('identity');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final clock = _randomClock(random);

        expect(clock.merge(VectorClock.empty), clock);
        expect(VectorClock.empty.merge(clock), clock);
      }
    });

    test('is the least upper bound', () {
      // The result must dominate both operands and must add nothing neither of
      // them had: an over-eager join would make a device claim to have seen
      // events it never received.
      final random = _random('least upper bound');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);
        final merged = left.merge(right);

        expect(merged.dominates(left), isTrue);
        expect(merged.dominates(right), isTrue);

        for (final device in merged.devices) {
          expect(
            merged[device],
            max(left[device], right[device]),
            reason: '$merged invented events for $device',
          );
        }
      }
    });

    test('absorbs a clock that is already dominated', () {
      // If a peer's state is already covered, merging it changes nothing. It is
      // the property the sync loop relies on to skip a pull.
      final random = _random('absorbs');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final chain = _randomChain(random);

        expect(chain.first.merge(chain.second), chain.second);
      }
    });
  });

  group('the causal order', () {
    test('is antisymmetric', () {
      // Two replicas looking at the same pair must not disagree about which
      // came first, or reconciliation would be direction-dependent.
      final random = _random('antisymmetric');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);

        expect(right.compare(left), left.compare(right).reversed);
      }
    });

    test('agrees with the join', () {
      // The causal order and the lattice order have to be the same order: a
      // happens before b exactly when joining a into b changes nothing and the
      // two are not already equal.
      final random = _random('agrees');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);

        final absorbed = left.merge(right) == right && left != right;

        expect(
          left.happensBefore(right),
          absorbed,
          reason: 'the order and the join disagree about $left and $right',
        );
      }
    });

    test('is transitive', () {
      // Without transitivity the causal order is not an order, and the whole
      // reconciliation argument collapses.
      final random = _random('transitive');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final chain = _randomChain(random);

        expect(
          chain.first.happensBefore(chain.second),
          isTrue,
          reason: 'the generated chain is not causal',
        );
        expect(chain.second.happensBefore(chain.third), isTrue);
        expect(chain.first.happensBefore(chain.third), isTrue);
      }
    });

    test('holds in exactly one relation for any pair', () {
      // The four orderings must partition every pair. A pair matching none, or
      // more than one, would leave the reconciler without a rule to apply.
      final random = _random('exactly one');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);

        final holding = <bool>[
          left == right,
          left.happensBefore(right),
          left.happensAfter(right),
          left.isConcurrentWith(right),
        ].where((holds) => holds).length;

        expect(
          holding,
          1,
          reason: '$holding relations hold between $left and $right',
        );
        expect(
          left.compare(right),
          isIn(Ordering.values),
          reason: 'the relation is one of the four',
        );
      }
    });
  });

  group('the operations', () {
    test('leave a tick causally after the clock it advanced', () {
      // A write must be causally after the state it was made on, or the node
      // that receives it could discard it as stale.
      final random = _random('tick is after');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final clock = _randomClock(random);
        final ticked = clock.tick(_device(random));

        expect(clock.happensBefore(ticked), isTrue);
        expect(ticked.merge(clock), ticked);
      }
    });

    test('do not mutate their operands', () {
      // Value semantics are what stop one record's clock from being advanced by
      // a merge performed somewhere else entirely.
      final random = _random('no mutation');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final left = _randomClock(random);
        final right = _randomClock(random);
        final beforeLeft = left.toString();
        final beforeRight = right.toString();

        left
          ..merge(right)
          ..compare(right)
          ..tick('a')
          ..toJson();

        expect(left.toString(), beforeLeft);
        expect(right.toString(), beforeRight);
      }
    });

    test('preserve the history across a json round trip', () {
      final random = _random('round trip');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final original = _randomClock(random);

        expect(VectorClock.fromJson(original.toJson()), original);
      }
    });

    test('encode equal histories to equal json', () {
      // Canonical encoding is what lets a stored clock be compared without
      // being decoded.
      final random = _random('canonical');

      for (var iteration = 0; iteration < _iterations; iteration++) {
        final clock = _randomClock(random);

        // The same history, reached another way: rebuilt through a map that
        // names every device of the alphabet, so that the devices this clock
        // never saw are present at zero rather than absent.
        final equivalent = VectorClock.of(<String, int>{
          for (var device = 0; device < _deviceCount; device++)
            _deviceAt(device): clock[_deviceAt(device)],
        });

        expect(equivalent, clock);
        expect(equivalent.toJson(), clock.toJson());
        expect(equivalent.toString(), clock.toString());
      }
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:atril/data/services/api/reachability.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeReachability', () {
    test('starts optimistic, because nothing has been tried yet', () async {
      final reachability = NodeReachability();

      expect(reachability.isReachable, isTrue);
      expect(await reachability.changes.first, isTrue);

      await reachability.dispose();
    });

    test('a call that never arrived marks the node unreachable', () async {
      final reachability = NodeReachability();
      final seen = <bool>[];
      final watching = reachability.changes.listen(seen.add);

      reachability.recordFailure(
        const AppException(kind: ErrorKind.unavailable),
      );
      await pumpEventQueue();

      expect(reachability.isReachable, isFalse);
      expect(seen, <bool>[true, false]);

      await watching.cancel();
      await reachability.dispose();
    });

    test(
      'a deadline that passed with no reply counts as unreachable',
      () async {
        final reachability = NodeReachability();

        reachability.recordFailure(
          const AppException(kind: ErrorKind.deadlineExceeded),
        );

        expect(reachability.isReachable, isFalse);

        await reachability.dispose();
      },
    );

    test('a refusal is an answer, and an answer is evidence', () async {
      final reachability = NodeReachability();

      reachability.recordFailure(
        const AppException(kind: ErrorKind.unavailable),
      );
      expect(reachability.isReachable, isFalse);

      // A NOT_FOUND is a node that received the request and decided. Reading
      // it as a network failure would be this device concluding it is offline
      // from a node telling it something.
      reachability.recordFailure(const AppException(kind: ErrorKind.notFound));

      expect(reachability.isReachable, isTrue);

      await reachability.dispose();
    });

    test('an answered call restores the conclusion', () async {
      final reachability = NodeReachability();

      reachability.recordFailure(
        const AppException(kind: ErrorKind.unavailable),
      );
      reachability.recordAnswer();

      expect(reachability.isReachable, isTrue);

      await reachability.dispose();
    });

    test('reports a change once and not per call', () async {
      final reachability = NodeReachability();
      final seen = <bool>[];
      final watching = reachability.changes.listen(seen.add);

      for (var attempt = 0; attempt < 3; attempt++) {
        reachability.recordFailure(
          const AppException(kind: ErrorKind.unavailable),
        );
      }

      await pumpEventQueue();

      expect(seen, <bool>[true, false]);

      await watching.cancel();
      await reachability.dispose();
    });

    test('no interface at all is proof, without spending a call', () async {
      final radio = StreamController<bool>();
      final reachability = NodeReachability(radio: radio.stream);

      radio.add(false);
      await pumpEventQueue();

      expect(reachability.isReachable, isFalse);

      await radio.close();
      await reachability.dispose();
    });

    test('an interface appearing is a hint and not a conclusion', () async {
      final radio = StreamController<bool>();
      final reachability = NodeReachability(radio: radio.stream);
      final hints = <void>[];
      final watching = reachability.retryHints.listen(hints.add);

      radio.add(false);
      await pumpEventQueue();

      radio.add(true);
      await pumpEventQueue();

      // The radio reports a radio and not a route: what it has said is that a
      // retry stopped being pointless, not that one will work.
      expect(hints, hasLength(1));
      expect(reachability.isReachable, isFalse);

      await watching.cancel();
      await radio.close();
      await reachability.dispose();
    });

    test('hints nothing while the node is answering', () async {
      final radio = StreamController<bool>();
      final reachability = NodeReachability(radio: radio.stream);
      final hints = <void>[];
      final watching = reachability.retryHints.listen(hints.add);

      radio.add(true);
      await pumpEventQueue();

      expect(hints, isEmpty);

      await watching.cancel();
      await radio.close();
      await reachability.dispose();
    });

    // A Linux host with no system D-Bus is the case that found this: the
    // plugin reaches NetworkManager over it, and the subscription answers with
    // a SocketException. Without a handler that is an unhandled error in the
    // zone — a crash report for the one signal this class is documented not to
    // draw a conclusion from.
    test('a radio that cannot be read is not a node that failed', () async {
      final radio = StreamController<bool>();
      final reachability = NodeReachability(radio: radio.stream);

      radio.addError(const SocketException('there is no system bus'));
      await pumpEventQueue();

      expect(reachability.isReachable, isTrue);

      // And it goes on listening: the platform may answer the next one.
      radio.add(false);
      await pumpEventQueue();

      expect(reachability.isReachable, isFalse);

      await radio.close();
      await reachability.dispose();
    });

    test('says nothing once it has been disposed of', () async {
      final reachability = NodeReachability();

      await reachability.dispose();

      reachability.recordFailure(
        const AppException(kind: ErrorKind.unavailable),
      );

      expect(reachability.isReachable, isTrue);
    });
  });
}

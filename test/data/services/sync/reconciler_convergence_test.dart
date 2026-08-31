/// The claim the whole design rests on, checked rather than asserted: two
/// replicas that saw the same writes in different orders hold the same records.
///
/// ## What is shuffled, and what is not
///
/// Every order a replica can legitimately receive is an order **consistent with
/// causality**. That is not a simplification of the test — it is what the
/// transport guarantees and what the merge needs. A node allocates its
/// positions inside the writing transaction, so a caller that has seen position
/// N has seen every position below it; a device pushes its own log in the order
/// it authored it. An operation therefore never arrives before one it causally
/// follows, and the generator below produces exactly those orders: every
/// permutation in which each change comes after the changes it observed.
///
/// ## The boundary C17 draws
///
/// Concurrent writes claiming *different* fields of one record are the case
/// this schema cannot settle, and C17 in `quire/docs/tcc-corrections.md` says
/// why: there is one revision per row, so there is nowhere to record that the
/// title came from one write and the author from another. The last group in
/// this file pins that consequence as behaviour rather than leaving it as
/// folklore — Atril reproduces it deliberately, because a client that resolved
/// it differently from the node would disagree with the node, which is a worse
/// failure than the one C17 describes.
library;

import 'dart:math';

import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _a = 'aaaaaaaa-0000-4000-8000-000000000001';
const String _b = 'bbbbbbbb-0000-4000-8000-000000000002';
const String _c = 'cccccccc-0000-4000-8000-000000000003';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
const String _locator = 'epubcfi(/6/14!/4/10/1:1)';

final DateTime _origin = DateTime.utc(2026);

/// One change in a generated log, with the changes it observed.
///
/// The dependencies are not bookkeeping: they are what makes a shuffle an order
/// a replica could actually receive.
final class Change {
  const Change(this.operation, {this.after = const <String>{}});

  final Operation operation;
  final Set<String> after;
}

/// A log, and every order it can legitimately arrive in.
final class Log {
  Log(this.changes);

  final List<Change> changes;

  /// One order consistent with causality, chosen by [random].
  List<Operation> shuffled(Random random) {
    final applied = <String>{};
    final remaining = <Change>[...changes];
    final ordered = <Operation>[];

    while (remaining.isNotEmpty) {
      final ready = remaining
          .where((change) => change.after.every(applied.contains))
          .toList();

      final next = ready[random.nextInt(ready.length)];

      ordered.add(next.operation);
      applied.add(next.operation.id);
      remaining.remove(next);
    }

    return ordered;
  }
}

int _minted = 0;

String _id() =>
    '${(++_minted).toString().padLeft(8, '0')}-9999-4999-8999-999999999999';

Operation _op({
  required TargetEntity entity,
  required String targetId,
  required String device,
  required Map<String, int> clock,
  OperationKind kind = OperationKind.update,
  Map<String, Object?> delta = const <String, Object?>{},
  int minutes = 0,
}) => Operation(
  id: _id(),
  deviceId: device,
  entity: entity,
  targetId: targetId,
  kind: kind,
  delta: delta,
  vectorClock: VectorClock.of(clock),
  createdAt: _origin.add(Duration(minutes: minutes)),
);

/// The whole replica as one comparable value.
///
/// Every replicated column is in it, including the revision: two databases that
/// held the same records under different causal versions would converge on the
/// next write and not on this one, and a test that compared only what a reader
/// sees would not notice.
Future<String> _state(AtrilDatabase database) async {
  final lines = <String>[];

  for (final row in await database.select(database.ebooks).get()) {
    lines.add(
      'ebook ${row.id} "${row.title}" author=${row.author} '
      'deleted=${row.deleted} clock=${row.vectorClock} '
      'at=${row.updatedAt.toIso8601String()} by=${row.deviceId}',
    );
  }

  for (final row in await database.select(database.collections).get()) {
    lines.add(
      'collection ${row.id} "${row.name}" deleted=${row.deleted} '
      'clock=${row.vectorClock}',
    );
  }

  for (final row in await database.select(database.ebookCollections).get()) {
    lines.add(
      'filing ${row.ebookId}/${row.collectionId} deleted=${row.deleted} '
      'clock=${row.vectorClock}',
    );
  }

  for (final row in await database.select(database.annotations).get()) {
    lines.add(
      'annotation ${row.id} "${row.content}" at=${row.locator} '
      'deleted=${row.deleted} clock=${row.vectorClock}',
    );
  }

  for (final row in await database.select(database.progress).get()) {
    lines.add(
      'progress ${row.ebookId}/${row.deviceId} ${row.locator} '
      '${row.percent} clock=${row.vectorClock}',
    );
  }

  lines.sort();

  return lines.join('\n');
}

/// Applies [operations] to a fresh replica and returns what it holds.
Future<String> _replay(List<Operation> operations) async {
  final database = AtrilDatabase(NativeDatabase.memory());
  final reconciler = Reconciler(database, HybridClock(wall: () => _origin));

  addTearDown(database.close);

  await reconciler.reconcileAll(operations);

  final state = await _state(database);

  await database.close();

  return state;
}

/// A log of one work, one grouping and everything that can be written about
/// them, with three devices writing concurrently.
///
/// The concurrent writes here are ones this design settles: two readers
/// editing the same title on two devices, and a third removing the work. The
/// condition that makes an order-independent answer possible is narrow and
/// worth naming — the write that wins claims every field its concurrent rivals
/// claimed, so nothing a loser wrote can survive in one order and not in
/// another. A pair that claims *different* fields is the case C17 leaves open,
/// and it is in its own group below rather than here.
Log _log() {
  final work = 'dddddddd-0000-4000-8000-00000000000a';
  final shelf = 'dddddddd-0000-4000-8000-00000000000b';
  final mark = 'dddddddd-0000-4000-8000-00000000000c';

  final imported = _op(
    entity: TargetEntity.ebook,
    targetId: work,
    device: _a,
    kind: OperationKind.insert,
    clock: <String, int>{_a: 1},
    delta: <String, Object?>{
      fieldTitle: 'o título importado',
      fieldFormat: 'epub',
      fieldContentHash: _hash,
    },
  );

  // Two devices retitle the work while neither has heard from the other. The
  // instants decide, and the devices decide the instants that are equal.
  final retitledHere = _op(
    entity: TargetEntity.ebook,
    targetId: work,
    device: _a,
    clock: <String, int>{_a: 2},
    delta: <String, Object?>{fieldTitle: 'o título de A'},
    minutes: 10,
  );
  final retitledThere = _op(
    entity: TargetEntity.ebook,
    targetId: work,
    device: _b,
    clock: <String, int>{_a: 1, _b: 1},
    delta: <String, Object?>{fieldTitle: 'o título de B'},
    minutes: 20,
  );

  // A third device removes the work, concurrently with both retitlings. A
  // deletion is a write like any other and reconciles like one.
  final removed = _op(
    entity: TargetEntity.ebook,
    targetId: work,
    device: _c,
    kind: OperationKind.delete,
    clock: <String, int>{_a: 1, _c: 1},
    minutes: 15,
  );

  final grouping = _op(
    entity: TargetEntity.collection,
    targetId: shelf,
    device: _b,
    kind: OperationKind.insert,
    clock: <String, int>{_b: 2},
    delta: <String, Object?>{fieldName: 'Para reler'},
  );

  // Two devices file the same pair and a third unfiles it, each naming the row
  // by the identifier it minted for itself (C18). All three are the same
  // record.
  final filedHere = _op(
    entity: TargetEntity.ebookCollection,
    targetId: 'eeeeeeee-0000-4000-8000-00000000000a',
    device: _a,
    kind: OperationKind.insert,
    clock: <String, int>{_a: 3},
    delta: <String, Object?>{fieldEbookId: work, fieldCollectionId: shelf},
    minutes: 30,
  );
  final filedThere = _op(
    entity: TargetEntity.ebookCollection,
    targetId: 'eeeeeeee-0000-4000-8000-00000000000b',
    device: _b,
    kind: OperationKind.insert,
    clock: <String, int>{_b: 3},
    delta: <String, Object?>{fieldEbookId: work, fieldCollectionId: shelf},
    minutes: 31,
  );
  final unfiled = _op(
    entity: TargetEntity.ebookCollection,
    targetId: 'eeeeeeee-0000-4000-8000-00000000000c',
    device: _c,
    kind: OperationKind.delete,
    clock: <String, int>{_c: 2},
    delta: <String, Object?>{fieldEbookId: work, fieldCollectionId: shelf},
    minutes: 32,
  );

  final noted = _op(
    entity: TargetEntity.annotation,
    targetId: mark,
    device: _a,
    kind: OperationKind.insert,
    clock: <String, int>{_a: 4},
    delta: <String, Object?>{
      fieldEbookId: work,
      fieldKind: 'note',
      fieldLocator: _locator,
      fieldText: 'a primeira nota',
    },
    minutes: 40,
  );
  final rewrittenHere = _op(
    entity: TargetEntity.annotation,
    targetId: mark,
    device: _a,
    clock: <String, int>{_a: 5},
    delta: <String, Object?>{fieldText: 'a nota de A'},
    minutes: 50,
  );
  final rewrittenThere = _op(
    entity: TargetEntity.annotation,
    targetId: mark,
    device: _b,
    clock: <String, int>{_a: 4, _b: 4},
    delta: <String, Object?>{fieldText: 'a nota de B'},
    minutes: 45,
  );

  // Two devices in the same work: two rows, one writer each, and nothing to
  // reconcile between them (C05).
  final stoppedHere = _op(
    entity: TargetEntity.readingProgress,
    targetId: 'ffffffff-0000-4000-8000-00000000000a',
    device: _a,
    kind: OperationKind.insert,
    clock: <String, int>{_a: 6},
    delta: <String, Object?>{
      fieldEbookId: work,
      fieldLocator: _locator,
      fieldPercent: 12.5,
    },
    minutes: 60,
  );
  final stoppedThere = _op(
    entity: TargetEntity.readingProgress,
    targetId: 'ffffffff-0000-4000-8000-00000000000b',
    device: _b,
    kind: OperationKind.insert,
    clock: <String, int>{_b: 5},
    delta: <String, Object?>{
      fieldEbookId: work,
      fieldLocator: _locator,
      fieldPercent: 80,
    },
    minutes: 61,
  );

  return Log(<Change>[
    Change(imported),
    Change(retitledHere, after: <String>{imported.id}),
    Change(retitledThere, after: <String>{imported.id}),
    Change(removed, after: <String>{imported.id}),
    Change(grouping),
    Change(filedHere, after: <String>{imported.id, grouping.id}),
    Change(filedThere, after: <String>{imported.id, grouping.id}),
    Change(unfiled, after: <String>{imported.id, grouping.id}),
    Change(noted, after: <String>{imported.id}),
    Change(rewrittenHere, after: <String>{noted.id}),
    Change(rewrittenThere, after: <String>{noted.id}),
    Change(stoppedHere, after: <String>{imported.id}),
    Change(stoppedThere, after: <String>{imported.id}),
  ]);
}

void main() {
  group('a log applied in every order a replica could receive it', () {
    test('reaches one state', () async {
      final log = _log();
      final random = Random(20260314);

      final first = await _replay(log.shuffled(random));

      expect(first, isNotEmpty);

      for (var attempt = 0; attempt < 40; attempt++) {
        expect(
          await _replay(log.shuffled(random)),
          first,
          reason:
              'two replicas that saw the same writes in different orders '
              'must hold the same records (RNF03)',
        );
      }
    });

    test(
      'settles the concurrent writes on the tie-break, not on arrival',
      () async {
        final state = await _replay(_log().shuffled(Random(1)));

        // Of the three concurrent writes to the work, the deletion at 15 past
        // loses to the retitling at 20 past, which is the later instant.
        expect(state, contains('"o título de B"'));
        expect(state, contains('ebook'));
        expect(state, contains('deleted=false'));
      },
    );
  });

  group('a tombstone', () {
    test('is a write, and the later write wins whichever way round', () async {
      final work = 'dddddddd-0000-4000-8000-0000000000f0';

      final imported = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _a,
        kind: OperationKind.insert,
        clock: <String, int>{_a: 1},
        delta: <String, Object?>{
          fieldTitle: 'um título',
          fieldFormat: 'epub',
          fieldContentHash: _hash,
        },
      );
      final removed = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _a,
        kind: OperationKind.delete,
        clock: <String, int>{_a: 2},
        minutes: 10,
      );
      // A device that had not heard about the deletion writes again. It is
      // concurrent with it, later on the tie-break, and therefore restores the
      // record — which is exactly what a tombstone is for: a row removed
      // outright could not have been reasoned about at all.
      final rewritten = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _b,
        clock: <String, int>{_a: 1, _b: 1},
        delta: <String, Object?>{fieldTitle: 'um título revisto'},
        minutes: 20,
      );

      final forwards = await _replay(<Operation>[imported, removed, rewritten]);
      final backwards = await _replay(<Operation>[
        imported,
        rewritten,
        removed,
      ]);

      expect(forwards, backwards);
      expect(forwards, contains('deleted=false'));
      expect(forwards, contains('"um título revisto"'));
    });

    test('survives a replica that had not heard about it', () async {
      final work = 'dddddddd-0000-4000-8000-0000000000f1';

      final imported = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _a,
        kind: OperationKind.insert,
        clock: <String, int>{_a: 1},
        delta: <String, Object?>{
          fieldTitle: 'um título',
          fieldFormat: 'epub',
          fieldContentHash: _hash,
        },
      );
      final removed = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _a,
        kind: OperationKind.delete,
        clock: <String, int>{_a: 2},
        minutes: 30,
      );
      final stale = _op(
        entity: TargetEntity.ebook,
        targetId: work,
        device: _b,
        clock: <String, int>{_a: 1, _b: 1},
        delta: <String, Object?>{fieldTitle: 'escrito antes de saber'},
        minutes: 10,
      );

      final forwards = await _replay(<Operation>[imported, removed, stale]);
      final backwards = await _replay(<Operation>[imported, stale, removed]);

      // The tombstone is what is being checked, and it holds either way round:
      // the deletion is the later write, so the record stays removed whether
      // the stale write arrived before it or after. The title the two orders
      // hold is not the same, and that is the C17 case in the group below —
      // the stale write claims a field the deletion does not.
      expect(forwards, contains('deleted=true'));
      expect(backwards, contains('deleted=true'));
    });
  });

  group('two concurrent writes to different fields of one record', () {
    test(
      'do not converge, which is C17 and not a fault of this port',
      () async {
        final work = 'dddddddd-0000-4000-8000-0000000000f2';

        final imported = _op(
          entity: TargetEntity.ebook,
          targetId: work,
          device: _a,
          kind: OperationKind.insert,
          clock: <String, int>{_a: 1},
          delta: <String, Object?>{
            fieldTitle: 'o título importado',
            fieldFormat: 'epub',
            fieldContentHash: _hash,
          },
        );
        final retitled = _op(
          entity: TargetEntity.ebook,
          targetId: work,
          device: _a,
          clock: <String, int>{_a: 2},
          delta: <String, Object?>{fieldTitle: 'um título novo'},
          minutes: 10,
        );
        final attributed = _op(
          entity: TargetEntity.ebook,
          targetId: work,
          device: _b,
          clock: <String, int>{_a: 1, _b: 1},
          delta: <String, Object?>{fieldAuthor: 'quem escreveu'},
          minutes: 20,
        );

        final titleFirst = await _replay(<Operation>[
          imported,
          retitled,
          attributed,
        ]);
        final authorFirst = await _replay(<Operation>[
          imported,
          attributed,
          retitled,
        ]);

        // Both hold the author, because the write that carried it wins the
        // tie-break either way. They disagree about the title: applied first it
        // is still there, applied second it is dropped with the operation that
        // carried it.
        expect(titleFirst, contains('author=quem escreveu'));
        expect(authorFirst, contains('author=quem escreveu'));
        expect(titleFirst, contains('"um título novo"'));
        expect(authorFirst, contains('"o título importado"'));
        expect(
          titleFirst,
          isNot(authorFirst),
          reason:
              'one revision per row cannot record that the title came from '
              'one write and the author from another — C17, open upstream, and '
              'reproduced here deliberately: a client that settled it '
              'differently would disagree with the node',
        );
      },
    );
  });
}

import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/sync/delta.dart';
import 'package:atril/data/services/sync/reconciler.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/record_key.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _here = '11111111-1111-4111-8111-111111111111';
const String _there = '22222222-2222-4222-8222-222222222222';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _shelf = 'bbbbbbbb-1111-4111-8111-111111111111';
const String _mark = 'cccccccc-1111-4111-8111-111111111111';
const String _filing = 'dddddddd-1111-4111-8111-111111111111';
const String _spot = 'eeeeeeee-1111-4111-8111-111111111111';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
const String _locator = 'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05]/1:1)';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

int _minted = 0;

/// An operation identifier, distinct per call, so that a test never has two
/// changes the reconciler would answer as one.
String _nextId() =>
    '${(++_minted).toString().padLeft(8, '0')}'
    '-1111-4111-8111-111111111111';

({AtrilDatabase database, Reconciler reconciler}) open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return (
    database: database,
    reconciler: Reconciler(database, HybridClock(wall: () => _at)),
  );
}

Operation _op({
  required TargetEntity entity,
  required String targetId,
  OperationKind kind = OperationKind.insert,
  Map<String, Object?> delta = const <String, Object?>{},
  String device = _here,
  int counter = 1,
  Duration at = Duration.zero,
}) => Operation(
  id: _nextId(),
  deviceId: device,
  entity: entity,
  targetId: targetId,
  kind: kind,
  delta: delta,
  vectorClock: VectorClock.of(<String, int>{device: counter}),
  createdAt: _at.add(at),
);

Operation _import({
  int counter = 1,
  Duration at = Duration.zero,
  String device = _here,
}) => _op(
  entity: TargetEntity.ebook,
  targetId: _work,
  delta: const <String, Object?>{
    fieldTitle: 'Grande Sertão: Veredas',
    fieldFormat: 'epub',
    fieldContentHash: _hash,
  },
  device: device,
  counter: counter,
  at: at,
);

Operation _shelfInsert() => _op(
  entity: TargetEntity.collection,
  targetId: _shelf,
  delta: const <String, Object?>{fieldName: 'Para reler'},
);

void main() {
  group('a work', () {
    test('is created by the operation that imported it', () async {
      final (:database, :reconciler) = open();

      expect((await reconciler.reconcile(_import())).isApplied, isTrue);

      final stored = await database.select(database.ebooks).getSingle();

      expect(stored.title, 'Grande Sertão: Veredas');
      expect(stored.deviceId, _here);
      expect(stored.importedAt, _at);
      expect(stored.deleted, isFalse);
    });

    test('is refused an update before the insert it depends on', () async {
      final (:database, :reconciler) = open();

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldTitle: 'Sagarana'},
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(await database.select(database.ebooks).get(), isEmpty);
    });

    test('keeps every field the delta does not name', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldAuthor: 'João Guimarães Rosa'},
          counter: 2,
          at: const Duration(minutes: 1),
        ),
      );

      final stored = await database.select(database.ebooks).getSingle();

      expect(stored.author, 'João Guimarães Rosa');
      expect(stored.title, 'Grande Sertão: Veredas');
      expect(stored.contentHash, _hash);
    });

    test('clears the field a delta names as null', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldAuthor: 'Rosa'},
          counter: 2,
          at: const Duration(minutes: 1),
        ),
      );
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldAuthor: null},
          counter: 3,
          at: const Duration(minutes: 2),
        ),
      );

      expect(
        (await database.select(database.ebooks).getSingle()).author,
        isNull,
      );
    });

    test(
      'is tombstoned by a deletion and resurrected by a later write',
      () async {
        final (:database, :reconciler) = open();

        await reconciler.reconcile(_import());
        await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebook,
            targetId: _work,
            kind: OperationKind.delete,
            counter: 2,
            at: const Duration(minutes: 1),
          ),
        );

        expect(
          (await database.select(database.ebooks).getSingle()).deleted,
          isTrue,
        );

        await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebook,
            targetId: _work,
            kind: OperationKind.update,
            delta: const <String, Object?>{fieldTitle: 'Sagarana'},
            counter: 3,
            at: const Duration(minutes: 2),
          ),
        );

        final stored = await database.select(database.ebooks).getSingle();

        expect(stored.deleted, isFalse);
        expect(stored.title, 'Sagarana');
      },
    );

    test('refuses a delta that leaves out what the record needs', () async {
      final reconciler = open().reconciler;

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          delta: const <String, Object?>{fieldTitle: 'Sagarana'},
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains(fieldFormat));
    });
  });

  group('a delivery the replica cannot hold', () {
    // Every one of these is a `CHECK` on a table. Left to the schema, each
    // would throw out of the reconciler, the page would abort with the cursor
    // unmoved, and the device would reconnect into the same operation for
    // ever. Refused here, each is a verdict the batch goes on past.
    Future<Verdict> ebook(Map<String, Object?> delta) =>
        open().reconciler.reconcile(
          _op(entity: TargetEntity.ebook, targetId: _work, delta: delta),
        );

    test('a work in a format this build cannot name', () async {
      final verdict = await ebook(<String, Object?>{
        fieldTitle: 'Sagarana',
        fieldFormat: 'txt',
        fieldContentHash: _hash,
      });

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains(fieldFormat));
    });

    test('a grouping of a kind this build cannot name', () async {
      final verdict = await open().reconciler.reconcile(
        _op(
          entity: TargetEntity.collection,
          targetId: _shelf,
          delta: const <String, Object?>{
            fieldName: 'Para reler',
            fieldKind: 'shelf',
          },
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains(fieldKind));
    });

    test('a mark of a kind this build cannot name', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'underline',
            fieldLocator: _locator,
          },
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains(fieldKind));
      expect(await database.select(database.annotations).get(), isEmpty);
    });

    test('a note with nothing in it', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'note',
            fieldLocator: _locator,
            fieldText: '   ',
          },
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(await database.select(database.annotations).get(), isEmpty);
    });

    test('an update that leaves a note with nothing in it', () async {
      // The row after the write is what the schema checks, so the change is
      // read against the row: clearing the text of a note, or turning a
      // highlight into a note without saying what it says.
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'highlight',
            fieldLocator: _locator,
          },
          counter: 2,
        ),
      );

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldKind: 'note'},
          counter: 3,
          at: const Duration(minutes: 1),
        ),
      );

      expect(verdict.isRejected, isTrue);

      final stored = await database.select(database.annotations).getSingle();

      expect(stored.kind, 'highlight');
    });

    test('a position past the end of the work', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _spot,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldLocator: _locator,
            fieldPercent: 101,
          },
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains(fieldPercent));
      expect(await database.select(database.progress).get(), isEmpty);
    });

    test('a constraint the readers do not know is still a verdict', () async {
      // The net under the readers. The digest's alphabet is a `CHECK` nothing
      // above the table validates, so this reaches sqlite — and comes back as
      // a refusal rather than an exception, with the transaction intact and
      // the next operation applied.
      final (:database, :reconciler) = open();

      final verdicts = await reconciler.reconcileAll(<Operation>[
        _op(
          entity: TargetEntity.ebook,
          targetId: _shelf,
          delta: <String, Object?>{
            fieldTitle: 'Sagarana',
            fieldFormat: 'epub',
            fieldContentHash: 'z' * 64,
          },
        ),
        _import(),
      ]);

      expect(verdicts.first.isRejected, isTrue);
      expect(verdicts.first.detail, contains('content_hash'));
      expect(verdicts.last.isApplied, isTrue);
      expect(await database.select(database.ebooks).get(), hasLength(1));
    });

    test('a value past the length its column declares', () async {
      // drift checks a declared length in Dart before the statement is built,
      // which is a third way out of the reconciler and is closed the same way.
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'bookmark',
            fieldLocator: 'epubcfi(${'/2' * 200})',
          },
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains('locator'));
      expect(await database.select(database.annotations).get(), isEmpty);
    });

    test('a column the row is too long for is still a verdict', () async {
      // The other half of the net: a length drift checks before the statement
      // runs, which arrives as its own exception and not as sqlite's.
      final verdict = await open().reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: 'short',
          delta: _import().delta,
        ),
      );

      expect(verdict.isRejected, isTrue);
      expect(verdict.detail, contains('id'));
    });

    test('is refused again when it is delivered again', () async {
      // A refusal is not recorded as applied: the same operation by two
      // routes is refused twice, at the cost of one decode, so that a build
      // that grows the field would not skip it.
      final reconciler = open().reconciler;
      final refused = _op(
        entity: TargetEntity.ebook,
        targetId: _work,
        delta: const <String, Object?>{
          fieldTitle: 'Sagarana',
          fieldFormat: 'txt',
          fieldContentHash: _hash,
        },
      );

      expect((await reconciler.reconcile(refused)).isRejected, isTrue);
      expect((await reconciler.reconcile(refused)).isRejected, isTrue);
    });
  });

  group('the merge', () {
    test('leaves the record alone when the change is superseded', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldTitle: 'the later write'},
          counter: 3,
          at: const Duration(minutes: 2),
        ),
      );

      final late = await reconciler.reconcile(
        _op(
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldTitle: 'the earlier write'},
          counter: 2,
          at: const Duration(minutes: 1),
        ),
      );

      expect(late.outcome, ReconcileOutcome.superseded);
      expect(
        (await database.select(database.ebooks).getSingle()).title,
        'the later write',
      );
    });

    test(
      'breaks a concurrent tie on the instant, and then on the device',
      () async {
        final (:database, :reconciler) = open();

        await reconciler.reconcile(_import());

        // Two devices that have each seen the import and neither each other.
        final ours = Operation(
          id: _nextId(),
          deviceId: _here,
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldTitle: 'ours'},
          vectorClock: VectorClock.of(<String, int>{_here: 2}),
          createdAt: _at.add(const Duration(minutes: 1)),
        );
        final theirs = Operation(
          id: _nextId(),
          deviceId: _there,
          entity: TargetEntity.ebook,
          targetId: _work,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldTitle: 'theirs'},
          vectorClock: VectorClock.of(<String, int>{_here: 1, _there: 1}),
          createdAt: _at.add(const Duration(minutes: 2)),
        );

        await reconciler.reconcile(ours);
        expect((await reconciler.reconcile(theirs)).isApplied, isTrue);

        expect(
          (await database.select(database.ebooks).getSingle()).title,
          'theirs',
          reason: 'the later instant wins a tie the clocks cannot order',
        );
      },
    );

    test('answers a redelivered operation as a duplicate', () async {
      final (:database, :reconciler) = open();

      final imported = _import();

      expect((await reconciler.reconcile(imported)).isApplied, isTrue);
      expect(
        (await reconciler.reconcile(imported)).outcome,
        ReconcileOutcome.duplicate,
      );
      expect(await database.select(database.ebooks).get(), hasLength(1));
    });
  });

  group('a filing', () {
    Future<Reconciler> openWithPair() async {
      final reconciler = open().reconciler;

      await reconciler.reconcile(_import());
      await reconciler.reconcile(_shelfInsert());

      return reconciler;
    }

    test(
      'is a register on the pair, whatever identifier names the row',
      () async {
        final (:database, :reconciler) = open();

        await reconciler.reconcile(_import());
        await reconciler.reconcile(_shelfInsert());
        await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebookCollection,
            targetId: _filing,
            delta: const <String, Object?>{
              fieldEbookId: _work,
              fieldCollectionId: _shelf,
            },
          ),
        );

        // Another device filed the same pair, under the identifier it minted.
        await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebookCollection,
            targetId: _spot,
            kind: OperationKind.delete,
            delta: const <String, Object?>{
              fieldEbookId: _work,
              fieldCollectionId: _shelf,
            },
            device: _there,
            counter: 1,
            at: const Duration(minutes: 1),
          ),
        );

        final rows = await database.select(database.ebookCollections).get();

        expect(rows, hasLength(1), reason: 'the pair is the record (C06, C18)');
        expect(rows.single.id, _filing);
        expect(rows.single.deleted, isTrue);
      },
    );

    test(
      'is written even when the deletion is the first thing heard',
      () async {
        final reconciler = await openWithPair();

        await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebookCollection,
            targetId: _filing,
            kind: OperationKind.delete,
            delta: const <String, Object?>{
              fieldEbookId: _work,
              fieldCollectionId: _shelf,
            },
          ),
        );

        expect(
          (await reconciler.reconcile(
            _op(
              entity: TargetEntity.ebookCollection,
              targetId: _spot,
              delta: const <String, Object?>{
                fieldEbookId: _work,
                fieldCollectionId: _shelf,
              },
              device: _there,
              at: const Duration(minutes: 1),
            ),
          )).isApplied,
          isTrue,
        );
      },
    );

    test(
      'is refused when it names a work this device has never heard of',
      () async {
        final reconciler = open().reconciler;

        final verdict = await reconciler.reconcile(
          _op(
            entity: TargetEntity.ebookCollection,
            targetId: _filing,
            delta: const <String, Object?>{
              fieldEbookId: _work,
              fieldCollectionId: _shelf,
            },
          ),
        );

        expect(verdict.isRejected, isTrue);
      },
    );
  });

  group('a mark', () {
    test('is applied into the work it names', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'note',
            fieldLocator: _locator,
            fieldText: 'reler o trecho do vaqueiro',
          },
        ),
      );

      final stored = await database.select(database.annotations).getSingle();

      expect(stored.ebookId, _work);
      expect(stored.content, 'reler o trecho do vaqueiro');
    });

    test('cannot be moved between works by an update', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldKind: 'highlight',
            fieldLocator: _locator,
          },
        ),
      );
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.annotation,
          targetId: _mark,
          kind: OperationKind.update,
          delta: const <String, Object?>{fieldEbookId: _shelf},
          counter: 2,
          at: const Duration(minutes: 1),
        ),
      );

      expect(
        (await database.select(database.annotations).getSingle()).ebookId,
        _work,
      );
    });
  });

  group('a reading position', () {
    test('is one row per device, and every device keeps its own', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      for (final (device, row) in <(String, String)>[
        (_here, _spot),
        (_there, _filing),
      ]) {
        await reconciler.reconcile(
          _op(
            entity: TargetEntity.readingProgress,
            targetId: row,
            delta: const <String, Object?>{
              fieldEbookId: _work,
              fieldLocator: _locator,
              fieldPercent: 40.5,
            },
            device: device,
          ),
        );
      }

      expect(await database.select(database.progress).get(), hasLength(2));
    });

    test('merges on the causal order alone, with no tie to break', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _spot,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldLocator: _locator,
            fieldPercent: 40,
          },
          counter: 1,
        ),
      );

      final older = await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _spot,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldLocator: 'epubcfi(/6/2!/4/1:0)',
            fieldPercent: 2,
          },
          counter: 1,
          at: const Duration(hours: 1),
        ),
      );

      expect(older.outcome, ReconcileOutcome.superseded);
      expect(
        (await database.select(database.progress).getSingle()).percent,
        40,
      );
    });

    test('cannot be removed', () async {
      final reconciler = open().reconciler;

      await reconciler.reconcile(_import());

      final verdict = await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _spot,
          kind: OperationKind.delete,
          delta: const <String, Object?>{fieldEbookId: _work},
        ),
      );

      expect(verdict.isRejected, isTrue);
    });
  });

  group('the causal state', () {
    test('remembers the version of every record it applied', () async {
      final (:database, :reconciler) = open();

      await reconciler.reconcile(_import());

      expect(
        await database.recordsDao.clockOf(
          RecordKey.record(TargetEntity.ebook, _work),
        ),
        VectorClock.of(<String, int>{_here: 1}),
      );
    });

    test('remembers a position only when it is this device own', () async {
      final (:database, :reconciler) = open();

      await database.identityDao.bindDevice(
        id: _here,
        name: 'the tablet',
        platform: 'linux',
        at: _at,
      );

      await reconciler.reconcile(_import());
      await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _filing,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldLocator: _locator,
          },
          device: _there,
        ),
      );

      expect(
        await database.recordsDao.versions(),
        hasLength(1),
        reason:
            'only the work has been remembered, not the other device'
            ' position',
      );

      await reconciler.reconcile(
        _op(
          entity: TargetEntity.readingProgress,
          targetId: _spot,
          delta: const <String, Object?>{
            fieldEbookId: _work,
            fieldLocator: _locator,
          },
          device: _here,
        ),
      );

      expect(
        await database.recordsDao.versionOf(RecordKey.position(ebookId: _work)),
        isNotNull,
      );
    });
  });
}

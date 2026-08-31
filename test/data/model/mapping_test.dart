import 'package:atril/data/model/identity_mapper.dart';
import 'package:atril/data/model/library_mapper.dart';
import 'package:atril/data/model/mapping.dart';
import 'package:atril/data/model/operation_mapper.dart';
import 'package:atril/data/model/reading_mapper.dart';
import 'package:atril/data/services/api/generated/quire/v1/auth.pb.dart'
    as auth;
import 'package:atril/data/services/api/generated/quire/v1/common.pb.dart'
    as common;
import 'package:atril/data/services/api/generated/quire/v1/library.pb.dart'
    as lib;
import 'package:atril/data/services/api/generated/quire/v1/reading.pb.dart'
    as reading;
import 'package:atril/data/services/api/generated/quire/v1/sync.pb.dart'
    as sync;
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/device.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/utils/errors.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

common.VectorClock wireClock(Map<String, int> counters) => common.VectorClock(
  entries: <MapEntry<String, Int64>>[
    for (final entry in counters.entries)
      MapEntry(entry.key, Int64(entry.value)),
  ],
);

common.HybridTimestamp stamp(int micros) =>
    common.HybridTimestamp(unixMicros: Int64(micros));

void main() {
  group('the causal values', () {
    test('a clock survives the wire in both directions', () {
      final clock = VectorClock.of(<String, int>{'a': 3, 'b': 1});

      expect(vectorClockOf(wireVectorClock(clock)), clock);
    });

    test('an entry at zero and an absent device are one history', () {
      // The canonical form is what makes the same history compare equal
      // however it was built, and a node drops its zeroes on the way out.
      expect(
        vectorClockOf(wireClock(<String, int>{'a': 1, 'b': 0})),
        VectorClock.of(<String, int>{'a': 1}),
      );
    });

    test('a counter that is not a count is refused', () {
      // uint64 on the wire, int64 in Dart: a value past 2^63 comes back
      // negative, and a clock that swallowed it would compare equal to a
      // history it is not.
      expect(
        () => vectorClockOf(
          common.VectorClock(
            entries: <MapEntry<String, Int64>>[
              MapEntry('a', Int64.parseInt('-1')),
            ],
          ),
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', ErrorKind.invalidArgument)
              .having((e) => e.code, 'code', codeMalformedValue),
        ),
      );
    });

    test('a hybrid instant keeps its microseconds and stays in UTC', () {
      final instant = instantOf(stamp(1759320000123456));

      expect(instant.microsecondsSinceEpoch, 1759320000123456);
      expect(instant.isUtc, isTrue);
      expect(wireInstant(instant).unixMicros.toInt(), 1759320000123456);
    });

    test('a revision carries the tie-break and the tombstone', () {
      final revision = revisionOf(
        common.Revision(
          vectorClock: wireClock(<String, int>{'DEVICE-A': 2}),
          updatedAt: stamp(1700000000000000),
          deviceId: 'DEVICE-A',
          deleted: true,
        ),
      );

      expect(revision.vectorClock['DEVICE-A'], 2);
      expect(revision.deviceId, 'device-a');
      expect(revision.deleted, isTrue);
    });
  });

  group('the identity values', () {
    test('an absent address is absent and not empty', () {
      // A node that only replicates this reader holds the row without one
      // (C03), and proto3 answers the empty string unless it is asked.
      expect(userOf(auth.User(id: 'r', localName: 'reader')).email, isNull);
      expect(
        userOf(auth.User(id: 'r', localName: 'reader', email: '')).email,
        '',
      );
    });

    test('a device that has never synchronized says so', () {
      expect(deviceOf(auth.Device(id: 'd', active: true)).lastSyncedAt, isNull);
      expect(
        deviceOf(
          auth.Device(
            id: 'd',
            active: true,
            lastSyncedAt: Timestamp.fromDateTime(DateTime.utc(2026, 5, 1)),
          ),
        ).lastSyncedAt,
        DateTime.utc(2026, 5, 1),
      );
    });

    test(
      'a binding carries the identifier this device already writes under',
      () {
        // Omitting it is the one mistake this app cannot recover from: the node
        // would mint a second identifier and this device would start a
        // vector-clock entry that never merges with the first.
        expect(
          wireDeviceBinding(
            const DeviceBinding(
              deviceId: 'd-1',
              name: 'phone',
              platform: 'android',
            ),
          ).deviceId,
          'd-1',
        );
      },
    );
  });

  group('the library values', () {
    test('an unknown format is a work this build cannot open', () {
      final ebook = ebookOf(
        lib.Ebook(
          id: 'E-1',
          title: 'Grande Sertão: Veredas',
          contentHash: 'A' * 64,
          format: lib.EbookFormat.EBOOK_FORMAT_UNSPECIFIED,
          revision: common.Revision(deviceId: 'd'),
        ),
      );

      // Listed, synchronized and kept; not opened. That is what the nullable
      // field is for, and it is what lets a node running a later contract add
      // a format without this build refusing the work.
      expect(ebook.format, isNull);
      expect(ebook.id, 'e-1');
      expect(ebook.contentHash, 'a' * 64);
    });

    test('what the file did not say is absent and not empty', () {
      final ebook = ebookOf(
        lib.Ebook(
          id: 'e',
          title: 'a work',
          contentHash: 'b' * 64,
          format: lib.EbookFormat.EBOOK_FORMAT_EPUB,
          revision: common.Revision(deviceId: 'd'),
        ),
      );

      expect(ebook.author, isNull);
      expect(ebook.publisher, isNull);
      expect(ebook.language, isNull);
      expect(ebook.sizeBytes, isNull);
      expect(ebook.extraMetadata, isEmpty);
      expect(ebook.format, EbookFormat.epub);
    });

    test('the extra metadata is the object the format carried', () {
      final ebook = ebookOf(
        lib.Ebook(
          id: 'e',
          title: 'a work',
          contentHash: 'c' * 64,
          revision: common.Revision(deviceId: 'd'),
          extraMetadata: Struct()
            ..mergeFromProto3Json(<String, Object?>{
              'isbn': '978-85-01-00000-0',
              'subjects': <String>['ficção', 'sertão'],
            }),
        ),
      );

      expect(ebook.extraMetadata['isbn'], '978-85-01-00000-0');
      expect(ebook.extraMetadata['subjects'], <String>['ficção', 'sertão']);
    });

    test('a download says which half of the oneof arrived', () {
      expect(
        downloadOf(
          lib.DownloadEbookContentResponse(
            content: lib.EbookContent(
              contentHash: 'd' * 64,
              sizeBytes: Int64(12),
              mediaType: 'application/epub+zip',
            ),
          ),
        ),
        isA<EbookDownloadStart>(),
      );
      expect(
        downloadOf(lib.DownloadEbookContentResponse(chunk: <int>[1, 2, 3])),
        isA<EbookDownloadChunk>(),
      );
    });

    test('a download carrying neither half is refused', () {
      // The contract has no third case, so one arriving means this device and
      // the node disagree about the shape of the stream — and continuing would
      // be writing bytes of unknown provenance under a digest.
      expect(
        () => downloadOf(lib.DownloadEbookContentResponse()),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('the reading values', () {
    test('a position carries a version and no tie-break', () {
      final progress = progressOf(
        reading.ReadingProgress(
          ebookId: 'E-1',
          deviceId: 'D-1',
          locator: 'epubcfi(/6/4!/4/2)',
          percent: 40.5,
          vectorClock: wireClock(<String, int>{'d-1': 7}),
          updatedAt: stamp(1700000000000000),
        ),
      );

      expect(progress.ebookId, 'e-1');
      expect(progress.deviceId, 'd-1');
      expect(progress.percent, 40.5);
      expect(progress.version.vectorClock['d-1'], 7);
    });

    test('a bookmark without text is not a note with an empty one', () {
      final bookmark = annotationOf(
        reading.Annotation(
          id: 'a',
          ebookId: 'e',
          kind: reading.AnnotationKind.ANNOTATION_KIND_BOOKMARK,
          locator: 'epubcfi(/6/4!/4/2)',
          revision: common.Revision(deviceId: 'd'),
        ),
      );

      expect(bookmark.kind, AnnotationKind.bookmark);
      expect(bookmark.text, isNull);
    });
  });

  group('the operation', () {
    final operation = Operation(
      id: 'op-1',
      deviceId: 'd-1',
      entity: TargetEntity.ebook,
      targetId: 'e-1',
      kind: OperationKind.update,
      delta: <String, Object?>{'title': 'a new title', 'author': null},
      vectorClock: VectorClock.of(<String, int>{'d-1': 4}),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        1700000000000000,
        isUtc: true,
      ),
    );

    test(
      'survives the wire, keeping a cleared field apart from an absent one',
      () {
        final back = operationOf(wireOperation(operation));

        expect(back.id, 'op-1');
        expect(back.entity, TargetEntity.ebook);
        expect(back.kind, OperationKind.update);
        expect(back.vectorClock, operation.vectorClock);
        expect(back.createdAt, operation.createdAt);

        // The whole of per-field reconciliation is here: a field the delta does
        // not name keeps whatever device wrote it last, and a field named as
        // null is one the reader cleared.
        expect(back.claims('title'), isTrue);
        expect(back.claims('author'), isTrue);
        expect(back.delta['author'], isNull);
        expect(back.claims('publisher'), isFalse);
      },
    );

    test('carries no position, in either direction', () {
      // A position is one node's order for one reader's log. The sender cannot
      // know a number the receiver has not allocated, and on the way back it
      // belongs to the cursor rather than to the operation.
      expect(wireOperation(operation).position.toInt(), 0);
    });

    test('an entity this build cannot name is refused', () {
      expect(
        () => operationOf(
          sync.Operation(
            id: 'op',
            deviceId: 'd',
            targetEntity: sync.TargetEntity.TARGET_ENTITY_UNSPECIFIED,
            operation: sync.OperationKind.OPERATION_KIND_INSERT,
          ),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.fields.single.name,
            'field',
            'target_entity',
          ),
        ),
      );
    });

    test('a kind this build cannot name is refused', () {
      expect(
        () => operationOf(
          sync.Operation(
            id: 'op',
            deviceId: 'd',
            targetEntity: sync.TargetEntity.TARGET_ENTITY_EBOOK,
            operation: sync.OperationKind.OPERATION_KIND_UNSPECIFIED,
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test(
      'a verdict this build cannot name is read as unknown, not refused',
      () {
        // A node running a later contract may answer with an outcome this build
        // has no name for, and the batch it belongs to is still worth reading.
        final result = operationResultOf(
          sync.OperationResult(
            operationId: 'OP-1',
            outcome: sync.OperationOutcome.OPERATION_OUTCOME_UNSPECIFIED,
          ),
        );

        expect(result.operationId, 'op-1');
        expect(result.outcome, isNull);
      },
    );

    test('the four outcomes say which retire the operation', () {
      expect(OperationOutcome.applied.retiresTheOperation, isTrue);
      expect(OperationOutcome.duplicate.retiresTheOperation, isTrue);
      expect(OperationOutcome.superseded.retiresTheOperation, isTrue);
      expect(OperationOutcome.rejected.retiresTheOperation, isFalse);
    });
  });
}

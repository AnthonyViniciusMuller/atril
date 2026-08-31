import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _other = '22222222-2222-4222-8222-222222222222';
const String _work = 'aaaaaaaa-1111-4111-8111-111111111111';
const String _mark = 'bbbbbbbb-1111-4111-8111-111111111111';
const String _position = 'cccccccc-1111-4111-8111-111111111111';
const String _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
const String _locator = 'epubcfi(/6/14[chap05ref]!/4[body01]/10[para05]/1:1)';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26, 535, 897);

AtrilDatabase open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

Future<AtrilDatabase> openWithWork() async {
  final database = open();

  await database
      .into(database.ebooks)
      .insert(
        EbooksCompanion.insert(
          id: _work,
          title: 'Grande Sertão: Veredas',
          format: 'epub',
          contentHash: _hash,
          importedAt: _at,
          vectorClock: VectorClock.empty.tick(_device),
          updatedAt: _at,
          deviceId: _device,
        ),
      );

  return database;
}

AnnotationsCompanion _annotation({
  String id = _mark,
  String kind = 'highlight',
  Value<String?> content = const Value<String?>.absent(),
}) => AnnotationsCompanion.insert(
  id: id,
  ebookId: _work,
  kind: kind,
  content: content,
  locator: _locator,
  vectorClock: VectorClock.empty.tick(_device),
  updatedAt: _at,
  deviceId: _device,
);

ProgressCompanion _progress({
  String id = _position,
  String device = _device,
  Value<double?> percent = const Value<double?>(40.5),
}) => ProgressCompanion.insert(
  id: id,
  ebookId: _work,
  deviceId: device,
  locator: _locator,
  percent: percent,
  vectorClock: VectorClock.empty.tick(device),
  updatedAt: _at,
);

void main() {
  group('an annotation', () {
    test(
      'carries the full revision, because two devices may edit it',
      () async {
        final database = await openWithWork();

        await database.into(database.annotations).insert(_annotation());

        final stored = await database.select(database.annotations).getSingle();

        expect(stored.deviceId, _device);
        expect(stored.deleted, isFalse);
        expect(stored.vectorClock, VectorClock.empty.tick(_device));
      },
    );

    test('is refused as a note with nothing written in it', () async {
      final database = await openWithWork();

      await expectLater(
        database.into(database.annotations).insert(_annotation(kind: 'note')),
        throwsA(isA<SqliteException>()),
      );

      await database
          .into(database.annotations)
          .insert(
            _annotation(
              kind: 'note',
              content: const Value<String?>('para reler'),
            ),
          );
    });

    test('goes with the work it was made in', () async {
      final database = await openWithWork();

      await database.into(database.annotations).insert(_annotation());
      await (database.delete(
        database.ebooks,
      )..where((ebook) => ebook.id.equals(_work))).go();

      expect(await database.select(database.annotations).get(), isEmpty);
    });
  });

  group('a reading position', () {
    test('is one row per work and device', () async {
      final database = await openWithWork();

      await database.into(database.progress).insert(_progress());

      await expectLater(
        database
            .into(database.progress)
            .insert(_progress(id: 'dddddddd-1111-4111-8111-111111111111')),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'keeps every device its own, because RN01 asks for all of them',
      () async {
        final database = await openWithWork();

        await database.into(database.progress).insert(_progress());
        await database
            .into(database.progress)
            .insert(
              _progress(
                id: 'dddddddd-1111-4111-8111-111111111111',
                device: _other,
              ),
            );

        expect(await database.select(database.progress).get(), hasLength(2));
      },
    );

    test('holds a proportion only where one makes sense', () async {
      final database = await openWithWork();

      await database
          .into(database.progress)
          .insert(_progress(percent: const Value<double?>(null)));

      await expectLater(
        database
            .into(database.progress)
            .insert(
              _progress(
                id: 'dddddddd-1111-4111-8111-111111111111',
                device: _other,
                percent: const Value<double?>(140),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}

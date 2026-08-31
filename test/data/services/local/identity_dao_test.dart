import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/local/hybrid_clock_store.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _reader = '22222222-2222-4222-8222-222222222222';
const String _node = '33333333-3333-4333-8333-333333333333';
const String _peer = '44444444-4444-4444-8444-444444444444';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26, 535, 897);

ServerRow _server({
  String id = _node,
  String domain = 'quire.example',
  bool isOrigin = false,
}) => ServerRow(
  id: id,
  domain: domain,
  baseUrl: 'https://$domain',
  isOrigin: isOrigin,
  active: true,
);

AtrilDatabase open() {
  final database = AtrilDatabase(NativeDatabase.memory());

  addTearDown(database.close);

  return database;
}

void main() {
  group('the bound device', () {
    test('is what a change is authored under once it has been bound', () async {
      final identity = open().identityDao;

      expect(await identity.deviceId(), isNull);

      await identity.bindDevice(
        id: _device,
        name: 'the reading tablet',
        platform: 'android',
        at: _at,
      );

      expect(await identity.deviceId(), _device);
    });

    test('is one row, and sqlite is what says so', () async {
      final database = open();

      await database.identityDao.bindDevice(
        id: _device,
        name: 'the reading tablet',
        platform: 'android',
        at: _at,
      );

      await expectLater(
        database.customStatement(
          'INSERT INTO bound_device (only_row, id, name, platform, bound_at) '
          "VALUES (1, '$_reader', 'another', 'ios', 0)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'is replaced rather than joined when the node answers again',
      () async {
        final identity = open().identityDao;

        for (final name in <String>['the tablet', 'the renamed tablet']) {
          await identity.bindDevice(
            id: _device,
            name: name,
            platform: 'android',
            at: _at,
          );
        }

        final device = await identity.device();

        expect(device?.name, 'the renamed tablet');
        expect(await identity.select(identity.boundDevice).get(), hasLength(1));
      },
    );
  });

  group('the reader', () {
    test('cannot be stored without the node they are named at', () async {
      final identity = open().identityDao;

      await expectLater(
        identity.rememberReader(
          id: _reader,
          localName: 'ana',
          displayName: 'Ana',
          originServerId: _node,
          federatedId: '@ana:quire.example',
          createdAt: _at,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('is stored once the node is in the catalogue', () async {
      final identity = open().identityDao;

      await identity.rememberServer(_server(isOrigin: true));
      await identity.rememberReader(
        id: _reader,
        localName: 'ana',
        displayName: 'Ana',
        originServerId: _node,
        federatedId: '@ana:quire.example',
        createdAt: _at,
      );

      final reader = await identity.reader();

      expect(reader?.federatedId, '@ana:quire.example');
      expect(reader?.email, isNull);
      expect((await identity.originServer())?.domain, 'quire.example');
    });
  });

  group('the catalogue', () {
    test('admits one origin, and moving it is one transaction', () async {
      final identity = open().identityDao;

      await identity.rememberServer(_server(isOrigin: true));
      await identity.rememberServer(_server(id: _peer, domain: 'peer.example'));

      await identity.markOrigin(_peer);

      expect((await identity.originServer())?.id, _peer);
    });

    test('refuses a second origin written behind the dao', () async {
      final database = open();

      await database.identityDao.rememberServer(_server(isOrigin: true));

      await expectLater(
        database.identityDao.rememberServer(
          _server(id: _peer, domain: 'peer.example', isOrigin: true),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('shows the reader their own node first', () async {
      final identity = open().identityDao;

      await identity.rememberServer(_server(id: _peer, domain: 'aaa.example'));
      await identity.rememberServer(_server(isOrigin: true));

      expect(
        (await identity.servers()).map((server) => server.domain),
        <String>['quire.example', 'aaa.example'],
      );
    });
  });

  group('the hybrid clock floor', () {
    test('round-trips to the microsecond', () async {
      final identity = open().identityDao;

      await identity.saveClockFloor(_at);

      expect(await identity.loadClockFloor(), _at);
      expect(
        (await identity.loadClockFloor())?.microsecondsSinceEpoch,
        _at.microsecondsSinceEpoch,
      );
    });

    test('is what a fresh launch resumes the clock from', () async {
      final store = LocalHybridClockStore(open().identityDao);
      final past = DateTime.utc(2020);

      await store.save(_at);

      final clock = await HybridClock.restore(store: store, wall: () => past);

      expect(clock.now().isAfter(_at), isTrue);
    });

    test('is nothing at all on a device that has never run', () async {
      expect(await LocalHybridClockStore(open().identityDao).load(), isNull);
    });
  });
}

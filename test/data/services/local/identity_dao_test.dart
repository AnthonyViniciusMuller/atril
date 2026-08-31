import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/local/hybrid_clock_store.dart';
import 'package:atril/domain/crdt/hybrid_clock.dart';
import 'package:atril/domain/models/server.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const String _device = '11111111-1111-4111-8111-111111111111';
const String _reader = '22222222-2222-4222-8222-222222222222';
const String _remote = '33333333-3333-4333-8333-333333333333';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26, 535, 897);

ServerRow _server({
  String domain = 'quire.example',
  String? remoteId,
  String? certificateFingerprint,
  bool isOrigin = false,
}) => ServerRow(
  domain: domain,
  remoteId: remoteId,
  baseUrl: 'https://$domain',
  certificateFingerprint: certificateFingerprint,
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
          originServerDomain: 'quire.example',
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
        originServerDomain: 'quire.example',
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
      await identity.rememberServer(_server(domain: 'peer.example'));

      await identity.markOrigin('peer.example');

      expect((await identity.originServer())?.domain, 'peer.example');
    });

    test('refuses a second origin written behind the dao', () async {
      final database = open();

      await database.identityDao.rememberServer(_server(isOrigin: true));

      await expectLater(
        database.identityDao.rememberServer(
          _server(domain: 'peer.example', isOrigin: true),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('records what a client document said, and no more', () async {
      final identity = open().identityDao;

      await identity.rememberDescriptor(
        const ServerDescriptor(
          domain: 'Quire.Example',
          baseUrl: 'https://quire.example',
          grpcAuthority: 'quire.example:9090',
        ),
        at: _at,
      );

      final server = await identity.server('quire.example');

      expect(server?.domain, 'quire.example');
      expect(server?.grpcAuthority, 'quire.example:9090');
      expect(server?.discoveredAt, _at);
      // The client document carries neither, and a row that claimed otherwise
      // would be this device inventing what a peer is pinned against.
      expect(server?.remoteId, isNull);
      expect(server?.certificateFingerprint, isNull);
    });

    test('keeps what a client document cannot mention', () async {
      // ListKnownServers is the only call that reports a node's own identifier
      // and its pin. A re-discovery must not wipe them by reading a document
      // that was never going to carry them.
      final identity = open().identityDao;

      await identity.rememberServer(
        _server(remoteId: _remote, certificateFingerprint: 'spki-sha256:AAAA'),
      );
      await identity.rememberDescriptor(
        const ServerDescriptor(
          domain: 'quire.example',
          baseUrl: 'https://quire.example',
          grpcAuthority: 'quire.example:9091',
        ),
        at: _at,
      );

      final server = await identity.server('quire.example');

      expect(server?.remoteId, _remote);
      expect(server?.certificateFingerprint, 'spki-sha256:AAAA');
      expect(server?.grpcAuthority, 'quire.example:9091');
    });

    test('shows the reader their own node first', () async {
      final identity = open().identityDao;

      await identity.rememberServer(_server(domain: 'aaa.example'));
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

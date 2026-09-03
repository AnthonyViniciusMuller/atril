@TestOn('vm')
/// Moving to another origin server: what travels, what is replaced, and what
/// is deliberately left alone.
///
/// The last of the three is the one worth a suite. A migration that cleared
/// the outbox or the causal state would look like it had worked and would have
/// completed itself by discarding exactly what was being migrated — so the
/// assertions here are as much about the rows that did *not* change as about
/// the ones that did.
library;

import 'dart:io';

import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/data/repositories/federation/federation_repository_impl.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/server/server_repository_impl.dart';
import 'package:atril/data/services/api/auth_api.dart';
import 'package:atril/data/services/api/federation_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/device.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/record_key.dart';
import 'package:atril/data/model/identity_mapper.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide Server;
import 'package:grpc/grpc.dart' as grpc show Server;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../services/api/fake_auth_service.dart';
import '../../services/api/fake_federation_service.dart';

const String _thisDevice = '11111111-1111-4111-8111-111111111111';
const String _otherDevice = '99999999-9999-4999-8999-999999999999';
const String _reader = '22222222-2222-4222-8222-222222222222';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

void main() {
  late FakeFederationService node;
  late FakeAuthService leaving;
  late grpc.Server server;
  late AtrilDatabase database;
  late NodeConnection connection;
  late SessionHolder session;
  late ServerRepository servers;
  late FederationRepository federation;

  setUp(() async {
    node = FakeFederationService();
    leaving = FakeAuthService();
    server = grpc.Server.create(services: <Service>[node, leaving]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    database = AtrilDatabase(NativeDatabase.memory());
    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );

    late final AuthApi auth;
    session = SessionHolder(store: MemorySessionStore(), refresher: () => auth);
    auth = AuthApi(connection: connection, session: session);

    servers = ServerRepositoryImpl(
      discovery: WellKnownDiscovery(
        client: MockClient(
          (http.Request request) async => http.Response(
            '{"quire.client":{"base_url":"https://${request.url.host}",'
            '"grpc":"${request.url.host}:9090"}}',
            200,
          ),
        ),
      ),
      identity: database.identityDao,
      connection: connection,
      // Both nodes live on the loopback port this test opened, exactly as the
      // local federation's two nodes live where the flavour says rather than
      // where they publish.
      endpointFor: (_) => NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
      clock: () => _at,
    );

    federation = FederationRepositoryImpl(
      federation: FederationApi(connection: connection, session: session),
      identity: database.identityDao,
      auth: auth,
      records: database.recordsDao,
      sync: database.syncDao,
      servers: servers,
      session: session,
      clock: () => _at,
    );

    // A device that has been signed in at quire-a.example for a while: bound,
    // with a reader, a change it still owes and a record whose clock names a
    // second device.
    await servers.choose(const ServerChoice(fakeOriginDomain));
    await database.identityDao.bindDevice(
      id: _thisDevice,
      name: 'Celular',
      platform: 'android',
      at: _at,
    );
    await servers.adoptOrigin(fakeOriginDomain);
    await database.identityDao.rememberReader(
      id: _reader,
      localName: 'ana',
      displayName: 'Ana Maria',
      originServerDomain: fakeOriginDomain,
      federatedId: '@ana:$fakeOriginDomain',
      createdAt: _at,
    );
    await session.begin(_sessionAt(leaving));
  });

  tearDown(() async {
    await session.dispose();
    await connection.shutdown();
    await server.shutdown();
    await database.close();
  });

  /// A change this device authored and has not handed over.
  Future<void> owe() => database.syncDao.append(
    Operation(
      id: '00000001-1111-4111-8111-111111111111',
      deviceId: _thisDevice,
      entity: TargetEntity.ebook,
      targetId: 'aaaaaaaa-1111-4111-8111-111111111111',
      kind: OperationKind.insert,
      delta: const <String, Object?>{'title': 'Sagarana'},
      vectorClock: VectorClock.of(const <String, int>{_thisDevice: 1}),
      createdAt: _at,
    ),
  );

  /// A record whose history names a device this one has never been told about.
  Future<void> rememberOther() => database.recordsDao.remember(
    RecordKey.record(
      TargetEntity.ebook,
      'aaaaaaaa-1111-4111-8111-111111111111',
    ),
    recordId: 'aaaaaaaa-1111-4111-8111-111111111111',
    clock: VectorClock.of(const <String, int>{_thisDevice: 1, _otherDevice: 3}),
  );

  HomeServerMigration migration({List<Device> devices = const <Device>[]}) =>
      HomeServerMigration(
        domain: FakeFederationService.migratedDomain,
        localName: 'ana',
        displayName: 'Ana Maria',
        email: 'ana@example.com',
        password: 'uma senha boa',
        devices: devices,
      );

  group('the devices a migration carries', () {
    test('are named by the node being left, while it answers', () async {
      leaving.devices.addAll(
        <Object>[
          const Device(
            id: _thisDevice,
            name: 'Celular',
            platform: 'android',
            active: true,
          ),
          const Device(
            id: _otherDevice,
            name: 'Notebook',
            platform: 'linux',
            active: true,
          ),
        ].map((Object it) => wireDevice(it as Device)),
      );

      final carried = await federation.devicesToCarry();

      expect(carried, isA<Ok<CarriedDevices>>());

      final value = (carried as Ok<CarriedDevices>).value;

      expect(value.named, isTrue);
      expect(value.devices.first.id, _thisDevice);
      expect(value.devices.first.isThisDevice, isTrue);
      expect(value.devices.last.name, 'Notebook');
    });

    test('come out of the replica when that node does not answer', () async {
      // The scenario UC16 exists for: the previous node is unavailable. What
      // is lost is the names; what survives is the identifiers, which is the
      // half that cannot be recreated.
      await rememberOther();
      leaving.refusal = GrpcError.unavailable('the node being left is down');

      final carried = await federation.devicesToCarry();
      final value = (carried as Ok<CarriedDevices>).value;

      expect(value.named, isFalse);
      expect(value.devices.first.id, _thisDevice);
      expect(
        value.devices.map((CarriedDevice it) => it.id),
        containsAll(<String>[_thisDevice, _otherDevice]),
      );
      expect(value.devices.last.name, isNull);
    });
  });

  group('the call', () {
    test('puts this device first, whatever the caller passed', () async {
      // C20: the contract carries no field naming the calling device, the
      // session comes back for the first in the list, and the order is the
      // only thing a client controls. The vendored .proto does not say so.
      await federation.migrate(
        migration(
          devices: <Device>[
            const Device(
              id: _otherDevice,
              name: 'Notebook',
              platform: 'linux',
              active: true,
            ),
          ],
        ),
      );

      expect(node.migrations.single.devices.first.id, _thisDevice);
      expect(node.migrations.single.devices.last.id, _otherDevice);
    });

    test('carries this device even when nothing was passed', () async {
      await federation.migrate(migration());

      expect(node.migrations.single.devices, hasLength(1));
      expect(node.migrations.single.devices.single.id, _thisDevice);
    });

    test('names one device once', () async {
      await federation.migrate(
        migration(
          devices: <Device>[
            const Device(
              id: _thisDevice,
              name: 'Celular',
              platform: 'android',
              active: true,
            ),
          ],
        ),
      );

      expect(node.migrations.single.devices, hasLength(1));
    });

    test('records the identifier being left as provenance', () async {
      await federation.migrate(migration());

      expect(
        node.migrations.single.previousFederatedId,
        '@ana:$fakeOriginDomain',
      );
    });

    test(
      'refuses what the node would refuse, before anything travels',
      () async {
        final refused = await federation.migrate(
          HomeServerMigration(
            domain: 'not a domain',
            localName: 'Ana Maria',
            displayName: '',
            email: 'nowhere',
            password: 'short',
            devices: const <Device>[],
          ),
        );

        expect(refused, isA<Error<User>>());
        expect(
          ((refused as Error<User>).error as AppException).fields.map(
            (FieldFailure it) => it.name,
          ),
          containsAll(<String>[
            'domain',
            'local_name',
            'display_name',
            'email',
            'password',
          ]),
        );
        expect(node.migrations, isEmpty);
      },
    );
  });

  group('what the migration leaves behind', () {
    test('the reader is the one the new node named', () async {
      final moved = await federation.migrate(migration());

      expect(moved, isA<Ok<User>>());

      final row = await database.identityDao.reader();

      expect(row!.federatedId, '@ana:${FakeFederationService.migratedDomain}');
      expect(row.originServerDomain, FakeFederationService.migratedDomain);
    });

    test('this device keeps the identifier it writes under', () async {
      await federation.migrate(migration());

      // The whole of C11 read from this side: an identifier that changed would
      // start a second clock entry that never merges with the first.
      expect(await database.identityDao.deviceId(), _thisDevice);
    });

    test(
      'the new node is the origin and this device is pointed at it',
      () async {
        await federation.migrate(migration());

        final origin = await database.identityDao.originServer();

        expect(origin!.domain, FakeFederationService.migratedDomain);
      },
    );

    test('the session is the one the new node issued', () async {
      await federation.migrate(migration());

      expect(
        await session.accessToken(),
        FakeFederationService.migratedAccessToken,
      );
    });

    test('the outbox is untouched', () async {
      await owe();

      await federation.migrate(migration());

      // What the device pushes to the new node is exactly this. Clearing it
      // would have completed the migration by discarding what was migrated.
      expect(await database.syncDao.pendingCount(), 1);
    });

    test('the causal state is untouched', () async {
      await rememberOther();

      await federation.migrate(migration());

      final version = await database.recordsDao.versionOf(
        RecordKey.record(
          TargetEntity.ebook,
          'aaaaaaaa-1111-4111-8111-111111111111',
        ),
      );

      expect(version, isNotNull);
      expect(version!.vectorClock[_otherDevice], 3);
    });

    test('the cursor for the new node starts at nothing', () async {
      // A position is a number in that node's log. The log it is about to
      // write for this reader is empty, and a number left over from an earlier
      // conversation with the same address would skip everything the migration
      // is about to put there.
      // A row this device could only have because it talked to that address
      // before — which is exactly the case the drop exists for.
      await database.identityDao.rememberDescriptor(
        const ServerDescriptor(
          domain: FakeFederationService.migratedDomain,
          baseUrl: 'https://${FakeFederationService.migratedDomain}',
        ),
        at: _at,
      );
      await database.syncDao.advanceCursor(
        FakeFederationService.migratedDomain,
        42,
        at: _at,
      );

      await federation.migrate(migration());

      expect(
        await database.syncDao.cursor(FakeFederationService.migratedDomain),
        0,
      );
    });
  });

  group('a migration that failed', () {
    test('leaves this device signed in where it was', () async {
      node.refusal = GrpcError.alreadyExists('that name is taken there');

      final refused = await federation.migrate(migration());

      expect(refused, isA<Error<User>>());

      // The state that would otherwise be unrecoverable: a device pointed at a
      // node it has no account on, holding a session for one it no longer
      // dials, failing every call for a reason nothing on screen explains.
      final origin = await database.identityDao.originServer();

      expect(origin!.domain, fakeOriginDomain);

      final row = await database.identityDao.reader();

      expect(row!.federatedId, '@ana:$fakeOriginDomain');
      expect(await session.accessToken(), leaving.accessToken);
    });
  });
}

/// The session [node] currently issues, as a device that has just signed in
/// would hold it.
Session _sessionAt(FakeAuthService node) => Session(
  accessToken: node.accessToken,
  accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  refreshToken: node.refreshToken,
  refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
);

@TestOn('vm')
/// Signing in: what is bound, what is recorded, and in what order.
library;

import 'dart:io';

import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/auth/auth_repository_impl.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/server/server_repository_impl.dart';
import 'package:atril/data/services/api/auth_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../services/api/fake_auth_service.dart';

const String _existing = '11111111-1111-4111-8111-111111111111';
final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

void main() {
  late FakeAuthService service;
  late Server server;
  late AtrilDatabase database;
  late NodeConnection connection;
  late SessionHolder session;
  late ServerRepository servers;
  late AuthRepository auth;

  setUp(() async {
    service = FakeAuthService();
    server = Server.create(services: <Service>[service]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    database = AtrilDatabase(NativeDatabase.memory());
    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );

    late final AuthApi built;
    session = SessionHolder(
      store: MemorySessionStore(),
      refresher: () => built,
    );
    built = AuthApi(connection: connection, session: session);

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
      // The same override `Environment.endpointFor` makes for the local
      // federation: the document says where a node lives on the internet, and
      // this node lives on a loopback port a test opened.
      endpointFor: (_) => NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
      clock: () => _at,
    );

    auth = AuthRepositoryImpl(
      auth: built,
      identity: database.identityDao,
      servers: servers,
      session: session,
      platform: 'linux',
      clock: () => _at,
    );

    // Every sign-in is at a node the reader chose a moment earlier.
    await servers.choose(const ServerChoice('quire-a.example'));
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await session.dispose();
    await database.close();
  });

  const Credentials credentials = Credentials(
    identifier: 'reader',
    password: 'a passphrase',
    deviceName: 'Atril on Linux',
  );

  test('binds a device that has none and remembers the identifier', () async {
    final result = await auth.signIn(credentials);

    expect(result.errorOrNull, isNull);
    expect(result.valueOrNull?.federatedId, '@reader:quire-a.example');

    // The identifier every vector-clock entry this device authors is counted
    // by. Losing it is the one mistake this app cannot recover from.
    expect(await database.identityDao.deviceId(), fakeMintedDeviceId);

    final device = await database.identityDao.device();
    expect(device?.platform, 'linux');
    expect(device?.boundAt, _at);
  });

  test('carries the identifier a bound device already writes under', () async {
    await database.identityDao.bindDevice(
      id: _existing,
      name: 'the reading tablet',
      platform: 'android',
      at: _at,
    );

    await auth.signIn(credentials);

    // The node answers with the identifier it was sent, and a device that had
    // omitted it would have been given a second one — starting a clock entry
    // that never merges with the first.
    expect(await database.identityDao.deviceId(), _existing);
  });

  test('records the reader and the node they are named at', () async {
    await auth.signIn(credentials);

    final reader = await database.identityDao.reader();

    expect(reader?.federatedId, '@reader:quire-a.example');
    expect(reader?.email, 'reader@quire-a.example');
    expect(reader?.originServerDomain, 'quire-a.example');
    expect(
      (await database.identityDao.originServer())?.domain,
      'quire-a.example',
    );
  });

  test('adopts the session last', () async {
    expect(await session.isSignedIn, isFalse);

    await auth.signIn(credentials);

    // The shell reads this to decide whether the reader may see their library.
    // A device it believed was signed in but that could not say who as would
    // be a library it could not fill.
    expect(await session.isSignedIn, isTrue);
    expect(session.current?.accessToken, service.accessToken);
  });

  test('sends the device name the screen chose', () async {
    await auth.signIn(credentials);

    expect((await database.identityDao.device())?.name, 'Atril on Linux');
  });

  test('a refusal leaves the device signed out and unbound', () async {
    // A port nothing is listening on, which is what a node that is down looks
    // like from here.
    await connection.connectTo(
      NodeEndpoint(authority: '127.0.0.1:1', transportSecurity: false),
    );

    final result = await auth.signIn(credentials);

    expect(result.errorOrNull, isA<AppException>());
    expect(await session.isSignedIn, isFalse);
    expect(await database.identityDao.deviceId(), isNull);
    expect(await database.identityDao.reader(), isNull);
  });

  test('an origin the device never discovered is refused', () async {
    // A node answering for a domain nothing looked up, on a device that has
    // chosen nothing, is a claim with no record behind it.
    final orphan = ServerRepositoryImpl(
      discovery: WellKnownDiscovery(
        client: MockClient((http.Request request) async {
          throw http.ClientException('no route', request.url);
        }),
      ),
      identity: database.identityDao,
      connection: connection,
      endpointFor: NodeEndpoint.of,
      clock: () => _at,
    );

    final result = await orphan.adoptOrigin('somewhere.example');

    expect(
      result.errorOrNull,
      isA<AppException>().having((e) => e.code, 'code', codeUnknownOrigin),
    );
  });

  test(
    'an origin under another name is recorded from what was found',
    () async {
      // A node identified by one host and served from another, or an apex
      // redirecting to a canonical name. It answered the calls this device has
      // been making, so what it publishes is what was already looked up.
      final result = await servers.adoptOrigin('www.quire-a.example');

      expect(result.valueOrNull?.domain, 'www.quire-a.example');
      expect(result.valueOrNull?.baseUrl, 'https://quire-a.example');
      expect(
        (await database.identityDao.originServer())?.domain,
        'www.quire-a.example',
      );
    },
  );
}

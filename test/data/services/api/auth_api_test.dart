@TestOn('vm')
library;

import 'dart:io';

import 'package:atril/data/services/api/auth_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/device.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

import 'fake_auth_service.dart';

void main() {
  late FakeAuthService service;
  late Server server;
  late NodeConnection connection;
  late MemorySessionStore store;
  late SessionHolder holder;
  late AuthApi api;

  setUp(() async {
    service = FakeAuthService();
    server = Server.create(services: <Service>[service]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    store = MemorySessionStore();

    // The cycle the composition root closes: the session authorizes the calls
    // of the client that refreshes it.
    late final AuthApi built;
    holder = SessionHolder(store: store, refresher: () => built);

    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    built = AuthApi(connection: connection, session: holder);
    api = built;
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
  });

  test(
    'a sign-in answers with the session, the reader and the device',
    () async {
      final signIn = await api.login(
        identifier: 'reader',
        password: 'a passphrase',
        device: const DeviceBinding(name: 'a laptop', platform: 'linux'),
      );

      expect(signIn.session.accessToken, 'access-1');
      expect(signIn.user.federatedId, '@reader:quire-a.example');
      expect(signIn.user.email, 'reader@quire-a.example');
      expect(signIn.user.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));

      // A device being bound for the first time learns the identifier its
      // vector-clock entries are counted under from here.
      expect(signIn.device.id, 'd-minted');
      expect(signIn.device.name, 'a laptop');
    },
  );

  test('signing in does not adopt the session by itself', () async {
    await api.login(
      identifier: 'reader',
      password: 'a passphrase',
      device: const DeviceBinding(name: 'a laptop', platform: 'linux'),
    );

    // Adopting it is the onboarding flow's decision, with the reader in front
    // of it, and it is what writes the credential.
    expect(await store.read(), isNull);
    expect(holder.current, isNull);
  });

  test('an authenticated call carries the session once it has begun', () async {
    final signIn = await api.login(
      identifier: 'reader@quire-a.example',
      password: 'a passphrase',
      device: const DeviceBinding(
        deviceId: 'd-1',
        name: 'a laptop',
        platform: 'linux',
      ),
    );
    await holder.begin(signIn.session);

    final user = await api.getUser();

    expect(user.localName, 'reader');
    expect(service.presented.last, 'Bearer access-1');
    expect(signIn.device.id, 'd-1');
  });

  test('a refusal arrives as the vocabulary, naming the operation', () async {
    await expectLater(
      api.registerUser(
        localName: 'reader',
        displayName: 'A Reader',
        email: 'reader@quire-a.example',
        password: 'a passphrase',
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', ErrorKind.unimplemented)
            .having((e) => e.op, 'op', opRegister),
      ),
    );
  });

  test(
    'the client refreshes through itself when the node refuses a token',
    () async {
      final signIn = await api.login(
        identifier: 'reader',
        password: 'a passphrase',
        device: const DeviceBinding(name: 'a laptop', platform: 'linux'),
      );
      await holder.begin(signIn.session);

      service.expireAccessToken();

      final user = await api.getUser();

      expect(user.localName, 'reader');
      expect(service.refreshes, 1);
      expect(service.presented.last, 'Bearer access-2');
      expect((await store.read())?.refreshToken, 'refresh-2');
    },
  );
}

@TestOn('vm')
/// The reader's devices: what is asked of the node, and the one thing this
/// device refuses on its own.
library;

import 'dart:io';

import 'package:atril/data/model/identity_mapper.dart';
import 'package:atril/data/repositories/account/account_repository.dart';
import 'package:atril/data/repositories/account/account_repository_impl.dart';
import 'package:atril/data/services/api/auth_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/device.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide Server;
import 'package:grpc/grpc.dart' as grpc show Server;

import '../../services/api/fake_auth_service.dart';

const String _thisDevice = '11111111-1111-4111-8111-111111111111';
const String _otherDevice = '99999999-9999-4999-8999-999999999999';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

void main() {
  late FakeAuthService node;
  late grpc.Server server;
  late AtrilDatabase database;
  late NodeConnection connection;
  late SessionHolder session;
  late AccountRepository account;

  setUp(() async {
    node = FakeAuthService();
    server = grpc.Server.create(services: <Service>[node]);
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

    await session.begin(
      Session(
        accessToken: node.accessToken,
        accessTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 5),
        ),
        refreshToken: node.refreshToken,
        refreshTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(days: 30),
        ),
      ),
    );

    await database.identityDao.bindDevice(
      id: _thisDevice,
      name: 'Celular',
      platform: 'android',
      at: _at,
    );

    node.devices.addAll(
      <Device>[
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
      ].map(wireDevice),
    );

    account = AccountRepositoryImpl(auth: auth, identity: database.identityDao);
  });

  tearDown(() async {
    session.dispose();
    await connection.shutdown();
    await server.shutdown();
    await database.close();
  });

  test('asks for the unbound devices too', () async {
    await account.devices();

    // A revoked device's row survives and its clock entry survives with it.
    // This list is the only place an identifier the history carries gets a
    // name, so hiding the row would make the history unreadable.
    expect(node.listedDevices, <bool>[true]);
  });

  test('says which of them is this one', () async {
    final bound = await account.devices();

    expect(bound, isA<Ok<BoundDevices>>());
    expect((bound as Ok<BoundDevices>).value.thisDevice, _thisDevice);
    expect(bound.value.devices, hasLength(2));
  });

  test('renames a device, and only its name', () async {
    final renamed = await account.renameDevice(
      deviceId: _otherDevice,
      name: '  Notebook do trabalho ',
    );

    expect(renamed, isA<Ok<Device>>());
    expect(node.renamed, <(String, String)>[
      (_otherDevice, 'Notebook do trabalho'),
    ]);
  });

  test('refuses a blank name before anything travels', () async {
    final renamed = await account.renameDevice(
      deviceId: _otherDevice,
      name: '',
    );

    expect(
      renamed,
      isA<Error<Device>>().having(
        (Error<Device> it) => (it.error as AppException).code,
        'code',
        codeInvalidDeviceName,
      ),
    );
    expect(node.renamed, isEmpty);
  });

  test('renaming this device keeps its own row in step', () async {
    // The row is what the next binding sends and what the sync surface names,
    // so a name changed at the node and not here would be two names for one
    // device.
    await account.renameDevice(deviceId: _thisDevice, name: 'Celular novo');

    final own = await database.identityDao.device();

    expect(own!.name, 'Celular novo');
    expect(own.id, _thisDevice);
  });

  test('unbinds another device', () async {
    final revoked = await account.revokeDevice(_otherDevice);

    expect(revoked, isA<Ok<void>>());
    expect(node.unbound, <String>[_otherDevice]);
  });

  test('refuses to unbind the device asking', () async {
    // The node cannot tell this request apart from any other and would carry
    // it out, ending this session and every future one with nothing left on
    // screen to undo the act.
    final revoked = await account.revokeDevice(_thisDevice);

    expect(
      revoked,
      isA<Error<void>>().having(
        (Error<void> it) => (it.error as AppException).code,
        'code',
        codeCannotRevokeThisDevice,
      ),
    );
    expect(node.unbound, isEmpty);
  });

  test(
    'a node that did not answer is a failure and not an empty list',
    () async {
      node.refusal = GrpcError.unavailable('the node is down');

      expect(await account.devices(), isA<Error<BoundDevices>>());
    },
  );
}

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
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/domain/models/user.dart';
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

    // The reader's row references the node they are hosted at, so the
    // catalogue has to know it before anything can be written about them.
    await database.identityDao.rememberDescriptor(
      const ServerDescriptor(
        domain: 'quire-a.example',
        baseUrl: 'https://quire-a.example',
      ),
      at: _at,
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

    account = AccountRepositoryImpl(
      auth: auth,
      identity: database.identityDao,
      session: session,
    );
  });

  tearDown(() async {
    session.dispose();
    await connection.shutdown();
    await server.shutdown();
    await database.close();
  });

  group('the reader\'s record', () {
    test('is written into this device\'s own row when it is read', () async {
      final read = await account.readAccount();

      expect(read, isA<Ok<User>>());

      final row = await database.identityDao.reader();

      expect(row!.email, 'reader@example.com');
      expect(row.displayName, 'A leitora');
    });

    test('names only the display name in the mask', () async {
      // The address is a credential in its own right and the password is
      // another; C14 is why neither is a field here, and why a mask could not
      // have said so.
      await account.changeDisplayName('  Ana Maria  ');

      expect(node.updated, hasLength(1));
      expect(node.updated.single.$1.toList(), <String>['display_name']);
      expect(node.updated.single.$2, 'Ana Maria');
    });

    test('a blank display name is refused before anything travels', () async {
      final renamed = await account.changeDisplayName('   ');

      expect(renamed, isA<Error<User>>());
      expect(node.updated, isEmpty);
    });

    test('changing the address proves it with the password', () async {
      final changed = await account.changeEmail(
        password: node.password,
        email: 'ana@example.com',
      );

      expect(changed, isA<Ok<User>>());
      expect(node.emails, <(String, String)>[
        (node.password, 'ana@example.com'),
      ]);

      final row = await database.identityDao.reader();

      expect(row!.email, 'ana@example.com');
    });

    test('a proof that did not match comes back as itself', () async {
      final changed = await account.changeEmail(
        password: 'not the password',
        email: 'ana@example.com',
      );

      expect(
        changed,
        isA<Error<User>>().having(
          (Error<User> it) => (it.error as AppException).code,
          'code',
          codeWrongPassword,
        ),
      );
    });

    test('an address somebody else holds here is reported as such', () async {
      final changed = await account.changeEmail(
        password: node.password,
        email: FakeAuthService.registeredEmail,
      );

      expect(
        changed,
        isA<Error<User>>().having(
          (Error<User> it) => (it.error as AppException).code,
          'code',
          'email_registered',
        ),
      );
    });

    test('changing the password ends this session too', () async {
      // The node ends every session of every device. Its own use case says so
      // and the contract does not, so a client that kept the credential would
      // present one the node has already thrown away on every call it makes.
      final changed = await account.changePassword(
        currentPassword: node.password,
        newPassword: 'outra senha boa',
      );

      expect(changed, isA<Ok<void>>());
      expect(await session.credential(), isNull);
    });

    test('a password the node would refuse never reaches it', () async {
      final changed = await account.changePassword(
        currentPassword: node.password,
        newPassword: 'curta',
      );

      expect(changed, isA<Error<void>>());
      expect(node.passwords, isEmpty);
      expect(await session.credential(), isNotNull);
    });

    test('a wrong current password leaves the session alone', () async {
      final changed = await account.changePassword(
        currentPassword: 'not the password',
        newPassword: 'outra senha boa',
      );

      expect(changed, isA<Error<void>>());
      expect(await session.credential(), isNotNull);
    });
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

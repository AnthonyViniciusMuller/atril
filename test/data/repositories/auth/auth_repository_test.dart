@TestOn('vm')
/// Signing in: what is bound, what is recorded, and in what order.
library;

import 'dart:io';

import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/auth/auth_repository_impl.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/server/server_repository_impl.dart';
import 'package:atril/data/services/api/auth_api.dart';
import 'package:atril/data/services/api/generated/quire/v1/auth.pb.dart'
    as node;
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/data/services/local/dao/identity_dao.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/data/services/sync/erase.dart';
import 'package:atril/data/services/sync/seed.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

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

  test('binds again when the node has no record of the identifier', () async {
    await database.identityDao.bindDevice(
      id: _existing,
      name: 'the reading tablet',
      platform: 'android',
      at: _at,
    );

    // The account was deleted and made again, or the node was restored from a
    // backup older than the binding. Either way the identifier this device has
    // been writing under is one the node cannot find.
    service.forgottenDevices.add(_existing);

    final result = await auth.signIn(credentials);

    expect(result.errorOrNull, isNull);

    // Presented first, because that is the rule; sent again without it only
    // once the node had said it does not have it.
    expect(service.boundAs, <String?>[_existing, null]);
    expect(await database.identityDao.deviceId(), fakeMintedDeviceId);
  });

  test('refuses a second time rather than binding in a loop', () async {
    await database.identityDao.bindDevice(
      id: _existing,
      name: 'the reading tablet',
      platform: 'android',
      at: _at,
    );

    // A node answering `device_not_found` to everything, which the real one
    // cannot do. It is how this asks what the client does when the answer that
    // provokes a second attempt is also the answer to the second.
    service.forgetsEveryDevice = true;

    final result = await auth.signIn(credentials);

    expect(result.errorOrNull, isA<AppException>());
    expect(service.boundAs, hasLength(2));
    expect(await session.isSignedIn, isFalse);
  });

  // A revoked device is one the node still holds and has deliberately unbound.
  // Binding it again would be this client undoing a decision the reader made
  // on another device, so the refusal is passed to them instead.
  test('does not bind again when the device was revoked', () async {
    await database.identityDao.bindDevice(
      id: _existing,
      name: 'the reading tablet',
      platform: 'android',
      at: _at,
    );

    service.revokedDevices.add(_existing);

    final result = await auth.signIn(credentials);

    expect(result.errorOrNull, isA<AppException>());
    expect((result.errorOrNull as AppException?)?.code, 'device_revoked');
    expect(service.boundAs, <String?>[_existing]);

    // Still the identifier it writes under: nothing was forgotten.
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

  group('registration', () {
    const Registration valid = Registration(
      localName: 'ana',
      displayName: 'Ana Maria',
      email: 'ana@quire-a.example',
      password: 'a passphrase',
    );

    test('creates the reader and signs nobody in', () async {
      final result = await auth.register(valid);

      expect(result.errorOrNull, isNull);

      // A registration is an account on a node, not a reader on this device:
      // what makes this device that reader's is the login that follows.
      expect(await session.isSignedIn, isFalse);
      expect(await database.identityDao.reader(), isNull);
    });

    test('folds the local name to the form uniqueness is decided on', () async {
      // The node folds too. Doing it here as well is what registers a reader
      // who capitalizes their own name instead of rejecting them.
      final result = await auth.register(
        const Registration(
          localName: '  Ana  ',
          displayName: 'Ana Maria',
          email: 'ana@quire-a.example',
          password: 'a passphrase',
        ),
      );

      expect(result.errorOrNull, isNull);
    });

    test('reports every violation it found, before anything travels', () async {
      // A form that reported one field at a time would make the reader submit
      // four times to learn four things this device already knew.
      final result = await auth.register(
        const Registration(
          localName: 'Ana Maria',
          displayName: '',
          email: 'ana',
          password: 'short',
        ),
      );

      final refusal = result.errorOrNull! as AppException;

      expect(refusal.kind, ErrorKind.invalidArgument);
      expect(
        refusal.fields.map((FieldFailure failure) => failure.name),
        <String>['local_name', 'display_name', 'email', 'password'],
      );
    });
  });

  group('seeding', () {
    /// A seeder that records what it was asked to fill.
    late List<String> seeded;

    AuthRepository withSeeder({bool failing = false}) {
      seeded = <String>[];

      return AuthRepositoryImpl(
        auth: AuthApi(connection: connection, session: session),
        identity: database.identityDao,
        servers: servers,
        session: session,
        platform: 'linux',
        seeder: _RecordingSeeder(seeded, failing),
        clock: () => _at,
      );
    }

    test(
      'fills the replica of a device being bound for the first time',
      () async {
        final repository = withSeeder();

        await repository.signIn(credentials);

        expect(seeded, <String>[fakeMintedDeviceId]);
      },
    );

    test('does not fill one that was already bound', () async {
      // A device that has signed in here before holds the replica already, and
      // re-seeding it would be asking the node to repeat a history this
      // device's own log can reconstruct.
      await database.identityDao.bindDevice(
        id: _existing,
        name: 'the reading tablet',
        platform: 'android',
        at: _at,
      );

      final repository = withSeeder();

      await repository.signIn(credentials);

      expect(seeded, isEmpty);
    });

    test('signs the reader in even when the seed fails', () async {
      // The reader is signed in — the node said so, and everything that makes
      // this device theirs is written. A failed seed costs a library that
      // fills in later; refusing the login would cost a reader who cannot get
      // in because one page of their annotations timed out.
      final repository = withSeeder(failing: true);

      final result = await repository.signIn(credentials);

      expect(result.errorOrNull, isNull);
      expect(await session.isSignedIn, isTrue);
    });
  });

  group('a device that changes hands', () {
    /// The second reader, at the same node.
    ///
    /// The pair is what identifies them — an account is named at a node, and
    /// two nodes mint identifiers without consulting each other — so a test
    /// about a *different* reader has to move the identifier and not only the
    /// name.
    final node.User other = node.User(
      id: fakeOtherReaderId,
      localName: 'outra',
      displayName: 'Outra leitora',
      originServerDomain: 'quire-a.example',
      federatedId: '@outra:quire-a.example',
      email: 'outra@quire-a.example',
      createdAt: Timestamp.fromDateTime(DateTime.utc(2026, 6, 1)),
    );

    late List<String> erased;
    late List<String> seeded;

    AuthRepository withReplica({bool erasable = true}) {
      erased = <String>[];
      seeded = <String>[];

      return AuthRepositoryImpl(
        auth: AuthApi(connection: connection, session: session),
        identity: database.identityDao,
        servers: servers,
        session: session,
        platform: 'linux',
        seeder: _RecordingSeeder(seeded, false),
        eraser: erasable ? _RecordingEraser(erased) : null,
        clock: () => _at,
      );
    }

    test('empties the replica the reader before them left', () async {
      final repository = withReplica();
      await repository.signIn(credentials);
      await repository.signOut();

      // A second person signs in on the same device, which the node answers
      // by refusing the binding the first one wrote under.
      service.admits = other;

      final result = await repository.signIn(credentials);

      expect(result.valueOrNull?.federatedId, '@outra:quire-a.example');
      expect(erased, hasLength(1));

      // And the replica is filled again, for the reader who is now here.
      expect(seeded, hasLength(2));
      expect((await database.identityDao.reader())?.id, fakeOtherReaderId);
    });

    test('keeps it for the reader who signs back in', () async {
      final repository = withReplica();
      await repository.signIn(credentials);
      await repository.signOut();

      final result = await repository.signIn(credentials);

      // The replica surviving a logout is the whole point of the rule the
      // erasure is an exception to: this reader's library is still theirs.
      expect(result.errorOrNull, isNull);
      expect(erased, isEmpty);
    });

    test('keeps it for a reader who has renamed themselves', () async {
      final repository = withReplica();
      await repository.signIn(credentials);

      // The same account under another local name, which is a thing UC06 lets
      // a reader do. Comparing federated identifiers would empty the replica
      // of somebody who had merely renamed themselves.
      service.admits = service.admits.deepCopy()
        ..localName = 'rebatizada'
        ..federatedId = '@rebatizada:quire-a.example';

      await repository.signIn(credentials);

      expect(erased, isEmpty);
      expect(
        (await database.identityDao.reader())?.federatedId,
        '@rebatizada:quire-a.example',
      );
    });

    test('refuses the sign-in it cannot empty the replica for', () async {
      final repository = withReplica(erasable: false);
      await repository.signIn(credentials);
      await repository.signOut();

      service.admits = other;

      final result = await repository.signIn(credentials);

      // The opposite of what a failed seed does, and deliberately: a seed that
      // did not run costs a library that fills in later, while signing this
      // reader in over the last one's shelves is the failure the erasure
      // exists to prevent.
      expect((result.errorOrNull! as AppException).code, codeReplicaNotEmptied);
      expect(await session.isSignedIn, isFalse);

      // And nothing was written for the reader who was refused. The device
      // still holds the first one's identity, which is what it still holds a
      // library for.
      expect((await database.identityDao.reader())?.id, fakeReaderId);
    });
  });

  group('signing out', () {
    test('clears the session and nothing else', () async {
      await auth.signIn(credentials);

      final result = await auth.signOut();

      expect(result.errorOrNull, isNull);
      expect(await session.isSignedIn, isFalse);

      // Logging out is not unbinding. The reader who signs back in here should
      // find their library, and a device that forgot its identifier would
      // start a vector-clock entry that never merges with the first.
      expect(await database.identityDao.deviceId(), fakeMintedDeviceId);
      expect(await database.identityDao.reader(), isNotNull);
      expect(
        (await database.identityDao.originServer())?.domain,
        'quire-a.example',
      );
    });

    test('presents the credential rather than the session', () async {
      await auth.signIn(credentials);
      final held = service.refreshToken;

      await auth.signOut();

      // A device whose access token has already expired can still end its
      // session, which is why Logout takes the credential.
      expect(service.loggedOut, <String>[held]);
    });

    test('signs the device out even when the node cannot be told', () async {
      await auth.signIn(credentials);
      await connection.connectTo(
        NodeEndpoint(authority: '127.0.0.1:1', transportSecurity: false),
      );

      final result = await auth.signOut();

      // A reader who asks to sign out on a train is signed out. What survives
      // a failed call is a credential nobody holds.
      expect(result.errorOrNull, isNull);
      expect(await session.isSignedIn, isFalse);
    });

    test(
      'tells nobody anything on a device that was never signed in',
      () async {
        await auth.signOut();

        expect(service.loggedOut, isEmpty);
        expect(await session.isSignedIn, isFalse);
      },
    );

    test('reports the reader the shell should name', () async {
      expect((await auth.reader().first).valueOrNull, isNull);

      await auth.signIn(credentials);

      expect(
        (await auth.reader().first).valueOrNull?.federatedId,
        '@reader:quire-a.example',
      );
    });

    test('reports a failure below it as a result, not as a throw', () async {
      // Every boundary in this app carries a `Result`, and this one used to
      // hand back a raw stream: a failure would either be thrown into the view
      // model listening or arrive as a stream that stopped, which looks
      // exactly like a device nobody is signed in on. The failure raised here
      // is an `Error` and not an `Exception` on purpose — the catch used to be
      // `on Exception`, which a `StateError` from a DAO walks straight past.
      final broken = AuthRepositoryImpl(
        auth: AuthApi(connection: connection, session: session),
        identity: _BrokenIdentityDao(database),
        servers: servers,
        session: session,
        platform: 'linux',
        clock: () => _at,
      );

      final answer = await broken.reader().first;

      expect(answer, isA<Error<User?>>());
      expect(
        ((answer as Error<User?>).error as AppException).kind,
        ErrorKind.unknown,
      );
    });
  });

  group('recovering a password', () {
    test('asks the node to send a credential', () async {
      final result = await auth.requestPasswordRecovery(
        '  Ana@Quire-A.example  ',
      );

      expect(result.errorOrNull, isNull);
      expect(service.recoveries, <String>['Ana@Quire-A.example']);
    });

    test(
      'refuses an address that is not one before anything travels',
      () async {
        // The shape of what was typed is a different question from who exists,
        // and it is safe to answer.
        final result = await auth.requestPasswordRecovery('ana');

        expect(
          result.errorOrNull,
          isA<AppException>().having((e) => e.code, 'code', codeInvalidEmail),
        );
        expect(service.recoveries, isEmpty);
      },
    );

    test('spends the credential and sets the password', () async {
      final result = await auth.resetPassword(
        recoveryToken: FakeAuthService.recoveryToken,
        newPassword: 'a new passphrase',
      );

      expect(result.errorOrNull, isNull);
      expect(service.reset, <String>['a new passphrase']);
    });

    test(
      'ends this device\'s session, which the node has ended anyway',
      () async {
        await auth.signIn(credentials);
        expect(await session.isSignedIn, isTrue);

        await auth.resetPassword(
          recoveryToken: FakeAuthService.recoveryToken,
          newPassword: 'a new passphrase',
        );

        // The node ended every session of every device. Keeping this one would
        // be presenting a credential it has already thrown away, on every call.
        expect(await session.isSignedIn, isFalse);
      },
    );

    test(
      'refuses a reset with no credential and one with a short password',
      () async {
        final missing = await auth.resetPassword(
          recoveryToken: '   ',
          newPassword: 'a new passphrase',
        );

        expect(
          missing.errorOrNull,
          isA<AppException>().having((e) => e.code, 'code', codeNoCredential),
        );

        final short = await auth.resetPassword(
          recoveryToken: FakeAuthService.recoveryToken,
          newPassword: 'short',
        );

        expect(
          short.errorOrNull,
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeInvalidPassword,
          ),
        );
        expect(service.reset, isEmpty);
      },
    );
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

/// An eraser that records having been asked to empty the replica.
final class _RecordingEraser implements ReplicaErasure {
  _RecordingEraser(this._erased);

  final List<String> _erased;

  @override
  Future<void> erase() async => _erased.add('erased');
}

/// A seeder that records the devices it was asked to fill.
final class _RecordingSeeder implements ReplicaSeed {
  _RecordingSeeder(this._seeded, this._failing);

  final List<String> _seeded;
  final bool _failing;

  @override
  Future<SeedSummary> seed({required String deviceId}) async {
    _seeded.add(deviceId);

    if (_failing) {
      throw const AppException(kind: ErrorKind.unavailable);
    }

    return const SeedSummary(
      ebooks: 0,
      collections: 0,
      filings: 0,
      annotations: 0,
      positions: 0,
    );
  }
}

/// An identity DAO whose reader stream fails with an `Error`.
///
/// It is an `Error` and not an `Exception` deliberately: `dart:core`'s `Error`
/// hierarchy is what a `StateError` from a query belongs to, and it is exactly
/// what a catch written `on Exception` lets past.
final class _BrokenIdentityDao extends IdentityDao {
  _BrokenIdentityDao(super.database);

  @override
  Stream<ReaderRow?> watchReader() =>
      Stream<ReaderRow?>.error(StateError('the replica is not readable'));
}

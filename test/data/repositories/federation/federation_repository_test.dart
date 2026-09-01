@TestOn('vm')
/// The catalogue: what is asked of the node, and what is kept locally.
///
/// The repository holds nothing, so what is worth asserting is the pair —
/// the call that was made, and the row the answer left behind. The second
/// half is the one a screen never shows and a launch depends on: `remote_id`
/// is reported by `ListKnownServers` and by nothing else, and it is what a
/// replica grant is addressed by.
library;

import 'dart:io';

import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/data/repositories/federation/federation_repository_impl.dart';
import 'package:atril/data/services/api/federation_api.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide Server;
import 'package:grpc/grpc.dart' as grpc show Server;

import '../../services/api/fake_federation_service.dart';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

void main() {
  late FakeFederationService node;
  late grpc.Server server;
  late AtrilDatabase database;
  late NodeConnection connection;
  late FederationRepository federation;

  setUp(() async {
    node = FakeFederationService();
    server = grpc.Server.create(services: <Service>[node]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    database = AtrilDatabase(NativeDatabase.memory());
    connection = NodeConnection(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );

    federation = FederationRepositoryImpl(
      federation: FederationApi(
        connection: connection,
        session: SessionHolder(
          store: MemorySessionStore(),
          refresher: () => throw StateError('no refresh in this test'),
        ),
      ),
      identity: database.identityDao,
      clock: () => _at,
    );
  });

  tearDown(() async {
    await connection.shutdown();
    await server.shutdown();
    await database.close();
  });

  group('the catalogue', () {
    test('asks for the deactivated nodes too', () async {
      await federation.servers();

      // The screen carries the switch that deactivates one, so a list that
      // hid them would have no way back from the state its own control
      // produces.
      expect(node.listed, <bool>[true]);
    });

    test('answers with what the node holds', () async {
      final catalogue = await federation.servers();

      expect(catalogue, isA<Ok<List<KnownServer>>>());
      expect(
        (catalogue as Ok<List<KnownServer>>).value.single.descriptor.domain,
        fakeOriginDomain,
      );
      expect(catalogue.value.single.isOrigin, isTrue);
    });

    test(
      'records what the node reported, the node\'s own id included',
      () async {
        await federation.servers();

        final row = await database.identityDao.server(fakeOriginDomain);

        expect(row, isNotNull);
        expect(row!.remoteId, fakeLocalServerId);
        expect(row.certificateFingerprint, 'spki-sha256:AAAA');
        expect(row.jwksUri, isNotNull);
      },
    );

    test(
      'a node that did not answer is a failure and not an empty list',
      () async {
        node.refusal = GrpcError.unavailable('the node is down');

        final catalogue = await federation.servers();

        expect(catalogue, isA<Error<List<KnownServer>>>());
      },
    );
  });

  group('adding a node', () {
    test('refuses a malformed domain before anything travels', () async {
      final added = await federation.addServer('not a domain');

      expect(added, isA<Error<KnownServer>>());
      expect(
        (added as Error<KnownServer>).error,
        isA<AppException>().having(
          (AppException it) => it.code,
          'code',
          codeInvalidDomain,
        ),
      );
      expect(node.added, isEmpty);
    });

    test('folds the case of what was typed', () async {
      await federation.addServer('  Quire-B.Example ');

      expect(node.added, <String>['quire-b.example']);
    });

    test('records the node it added, with the key that was pinned', () async {
      final added = await federation.addServer('quire-b.example');

      expect(added, isA<Ok<KnownServer>>());

      final row = await database.identityDao.server('quire-b.example');

      expect(row!.certificateFingerprint, 'spki-sha256:BBBB');
      expect(row.grpcAuthority, 'quire-b.example:9090');
    });

    test('a domain the node already knows is refused as such', () async {
      final added = await federation.addServer(fakeOriginDomain);

      expect(
        added,
        isA<Error<KnownServer>>().having(
          (Error<KnownServer> it) => (it.error as AppException).kind,
          'kind',
          ErrorKind.alreadyExists,
        ),
      );
    });
  });

  group('refreshing a node', () {
    test('reports a key that moved rather than applying it quietly', () async {
      await federation.addServer('quire-b.example');
      final added = await database.identityDao.server('quire-b.example');

      node.fingerprintChanges = true;
      final refreshed = await federation.refreshServer(added!.remoteId!);

      expect(refreshed, isA<Ok<ServerRefresh>>());
      expect((refreshed as Ok<ServerRefresh>).value.fingerprintChanged, isTrue);
    });

    test('records the key the node now pins, changed or not', () async {
      await federation.addServer('quire-b.example');
      final added = await database.identityDao.server('quire-b.example');

      node.fingerprintChanges = true;
      await federation.refreshServer(added!.remoteId!);

      final row = await database.identityDao.server('quire-b.example');

      expect(row!.certificateFingerprint, 'spki-sha256:CCCC');
    });
  });

  group('the switch', () {
    test('sends only what the contract lets a reader write', () async {
      await federation.addServer('quire-b.example');
      final added = await database.identityDao.server('quire-b.example');

      await federation.setActive(serverId: added!.remoteId!, active: false);

      expect(node.updated, <(String, bool)>[(added.remoteId!, false)]);

      final row = await database.identityDao.server('quire-b.example');

      expect(row!.active, isFalse);
    });
  });

  group('forgetting a node', () {
    test('leaves the row and marks it inactive', () async {
      await federation.addServer('quire-b.example');
      final added = await database.identityDao.server('quire-b.example');

      final forgotten = await federation.forgetServer(
        KnownServer(
          id: added!.remoteId!,
          descriptor: const ServerDescriptor(
            domain: 'quire-b.example',
            baseUrl: 'https://quire-b.example',
          ),
          isOrigin: false,
          active: true,
        ),
      );

      expect(forgotten, isA<Ok<void>>());
      expect(node.removed, <String>[added.remoteId!]);

      // The row stays: it is what explains a peer that still holds a copy,
      // and the reader's own row references a domain besides.
      final row = await database.identityDao.server('quire-b.example');

      expect(row, isNotNull);
      expect(row!.active, isFalse);
    });

    test('a node that refuses leaves the row alone', () async {
      await federation.addServer('quire-b.example');
      final added = await database.identityDao.server('quire-b.example');

      node.refusal = GrpcError.failedPrecondition('a replica names it');

      final forgotten = await federation.forgetServer(
        KnownServer(
          id: added!.remoteId!,
          descriptor: const ServerDescriptor(
            domain: 'quire-b.example',
            baseUrl: 'https://quire-b.example',
          ),
          isOrigin: false,
          active: true,
        ),
      );

      expect(forgotten, isA<Error<void>>());

      final row = await database.identityDao.server('quire-b.example');

      expect(row!.active, isTrue);
    });
  });
}

/// Choosing a node: what is looked up, what is recorded, and what is dialled.
library;

import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/server/server_repository_impl.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/data/services/local/database.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final DateTime _at = DateTime.utc(2026, 3, 14, 15, 9, 26);

/// A discovery client answering every lookup with a document for the host it
/// was addressed at.
WellKnownDiscovery answering({int status = 200}) => WellKnownDiscovery(
  client: MockClient(
    (http.Request request) async => http.Response(
      '{"quire.client":{"base_url":"https://${request.url.host}",'
      '"grpc":"${request.url.host}:9090"}}',
      status,
    ),
  ),
);

void main() {
  late AtrilDatabase database;
  late NodeConnection connection;

  setUp(() {
    database = AtrilDatabase(NativeDatabase.memory());
    connection = NodeConnection(NodeEndpoint());
    addTearDown(database.close);
  });

  ServerRepositoryImpl repositoryOver(WellKnownDiscovery discovery) =>
      ServerRepositoryImpl(
        discovery: discovery,
        identity: database.identityDao,
        connection: connection,
        endpointFor: NodeEndpoint.of,
        clock: () => _at,
      );

  test('a fresh install is pointed at nobody', () async {
    final repository = repositoryOver(answering());

    expect((await repository.current()).valueOrNull, isNull);
  });

  test('a choice is looked up, recorded and dialled together', () async {
    final repository = repositoryOver(answering());

    final result = await repository.choose(
      const ServerChoice('quire-a.example'),
    );

    expect(result.valueOrNull?.domain, 'quire-a.example');

    // Recorded: the next launch has to find it.
    final row = await database.identityDao.server('quire-a.example');
    expect(row?.grpcAuthority, 'quire-a.example:9090');
    expect(row?.discoveredAt, _at);

    // Dialled: a node recorded and not dialled is a row nothing acts on.
    expect(connection.endpoint.authority, 'quire-a.example:9090');

    // And it is what the screen is now told about.
    expect((await repository.current()).valueOrNull?.domain, 'quire-a.example');
  });

  test('a node the build already knows is looked up where it lives', () async {
    final addressed = <Uri>[];
    final repository = repositoryOver(
      WellKnownDiscovery(
        client: MockClient((http.Request request) async {
          addressed.add(request.url);

          return http.Response(
            '{"quire.client":{"base_url":"http://quire-a.example",'
            '"grpc":"quire-a.example:9090"}}',
            200,
          );
        }),
      ),
    );

    await repository.choose(
      ServerChoice(
        'quire-a.example',
        discovery: Uri.parse('http://127.0.0.1:18080'),
      ),
    );

    // `make dev-up` publishes addresses that resolve inside its compose
    // network; the document itself is on a loopback port.
    expect(addressed.single.host, '127.0.0.1');
    expect(addressed.single.port, 18080);
  });

  test('a domain that is not a node changes nothing', () async {
    final repository = repositoryOver(answering(status: 404));

    final result = await repository.choose(const ServerChoice('example.com'));

    expect(
      result.errorOrNull,
      isA<AppException>().having((e) => e.code, 'code', codeNotAQuireServer),
    );
    expect(await database.identityDao.server('example.com'), isNull);
    expect(connection.endpoint.authority, isNull);
  });

  test('a launch is pointed at the node the reader signed in at', () async {
    await database.identityDao.rememberDescriptor(
      const ServerDescriptor(
        domain: 'quire-a.example',
        baseUrl: 'https://quire-a.example',
        grpcAuthority: 'quire-a.example:9090',
      ),
      at: _at,
    );
    await database.identityDao.markOrigin('quire-a.example');

    final repository = repositoryOver(answering());

    // Nothing was chosen in this run, so the answer comes out of the
    // catalogue — which is the only record a cold start has.
    expect((await repository.current()).valueOrNull?.domain, 'quire-a.example');
  });
}

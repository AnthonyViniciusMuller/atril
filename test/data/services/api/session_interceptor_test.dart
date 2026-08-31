@TestOn('vm')
library;

import 'dart:io';

import 'package:atril/data/services/api/generated/quire/v1/auth.pbgrpc.dart'
    as pb;
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/api/session_interceptor.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide ClientChannel;
import 'package:grpc/service_api.dart' show ClientChannel;

import 'fake_auth_service.dart';

/// The refresher the session uses, over the same client the interceptor is
/// attached to.
///
/// It is what `auth_api.dart` will be, reduced to the one call: the session
/// depends on a port and not on the client, and the client depends on the
/// session for its credential, so something has to close the loop and it is
/// the composition rather than either of them.
final class _Refresher implements SessionRefresher {
  _Refresher(this._client);

  final pb.AuthServiceClient Function() _client;

  @override
  Future<Session> refreshSession(String refreshToken) async {
    final answer = await _client().refreshSession(
      pb.RefreshSessionRequest(refreshToken: refreshToken),
    );

    return sessionOf(answer.session);
  }
}

/// The wire session as the domain holds it, which is `data/model`'s job from
/// the next commit and is written by hand here.
Session sessionOf(pb.Session session) => Session(
  accessToken: session.accessToken,
  accessTokenExpiresAt: session.accessTokenExpiresAt.toDateTime(toLocal: false),
  refreshToken: session.refreshToken,
  refreshTokenExpiresAt: session.refreshTokenExpiresAt.toDateTime(
    toLocal: false,
  ),
);

void main() {
  late FakeAuthService service;
  late Server server;
  late ClientChannel channel;
  late pb.AuthServiceClient client;
  late MemorySessionStore store;
  late SessionHolder holder;

  Future<void> start({SessionCredential? held}) async {
    service = FakeAuthService();
    server = Server.create(services: <Service>[service]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    store = MemorySessionStore(held);
    holder = SessionHolder(store: store, refresher: _Refresher(() => client));

    channel = openChannel(
      NodeEndpoint(
        authority: '127.0.0.1:${server.port}',
        transportSecurity: false,
      ),
    );
    client = pb.AuthServiceClient(
      channel,
      interceptors: <ClientInterceptor>[SessionInterceptor(holder)],
    );
  }

  tearDown(() async {
    await channel.shutdown();
    await server.shutdown();
  });

  test('a public method carries no credential', () async {
    await start();

    await client.login(pb.LoginRequest(localName: 'reader'));

    // Nothing to present, and nothing asked for: a device logging in is a
    // device that has no session yet, and asking the session for a token here
    // is what would make refreshing recursive.
    expect(service.presented, <String?>[null]);
  });

  test('an authenticated method carries the bearer token', () async {
    await start();

    final login = await client.login(pb.LoginRequest(localName: 'reader'));
    await holder.begin(sessionOf(login.session));

    final user = await client.getUser(pb.GetUserRequest());

    expect(user.user.localName, 'reader');
    expect(service.presented.last, 'Bearer access-1');
    expect(service.refreshes, 0);
  });

  test('a cold start exchanges the stored credential first', () async {
    await start(
      held: SessionCredential(
        refreshToken: 'refresh-1',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      ),
    );

    final user = await client.getUser(pb.GetUserRequest());

    expect(user.user.localName, 'reader');
    expect(service.refreshes, 1);
    expect(service.presented, <String?>[null, 'Bearer access-2']);
    expect((await store.read())?.refreshToken, 'refresh-2');
  });

  test('a refused credential is refreshed and the call made again', () async {
    await start();

    final login = await client.login(pb.LoginRequest(localName: 'reader'));
    await holder.begin(sessionOf(login.session));

    // The node stops accepting the token this device holds, without the token
    // having reached its stated expiry. Only the node can know that, so the
    // refusal is the signal.
    service.expireAccessToken();

    final user = await holder.retrying(
      () => client.getUser(pb.GetUserRequest()),
    );

    expect(user.user.localName, 'reader');
    expect(service.refreshes, 1);
    expect(service.presented, <String?>[
      null,
      'Bearer access-1',
      null,
      'Bearer access-2',
    ]);
  });
}

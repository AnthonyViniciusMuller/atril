import 'dart:async';

import 'package:atril/data/services/api/grpc_status.dart';
import 'package:atril/data/services/api/session.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// A refresher that answers with a session numbered by how often it was asked.
final class _Refresher implements SessionRefresher {
  _Refresher({this.accepts = 'refresh-1'});

  /// The credential this refresher will exchange. Anything else is refused as
  /// a consumed one is.
  String accepts;

  int calls = 0;

  /// Held open so that a test can prove two callers wait on one exchange.
  Completer<void>? gate;

  @override
  Future<Session> refreshSession(String refreshToken) async {
    calls++;

    final open = gate;

    if (open != null) {
      await open.future;
    }

    if (refreshToken != accepts) {
      throw const GrpcError.unauthenticated('the credential was consumed');
    }

    accepts = 'refresh-${calls + 1}';

    return _sessionNamed(calls + 1);
  }
}

Session _sessionNamed(
  int number, [
  Duration lifetime = const Duration(minutes: 5),
]) {
  final now = DateTime.now().toUtc();

  return Session(
    accessToken: 'access-$number',
    accessTokenExpiresAt: now.add(lifetime),
    refreshToken: 'refresh-$number',
    refreshTokenExpiresAt: now.add(const Duration(days: 30)),
  );
}

void main() {
  group('SessionHolder', () {
    test('holds no token before anything has signed in', () async {
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => _Refresher(),
      );

      expect(await holder.isSignedIn, isFalse);
      expect(await holder.accessToken(), isNull);
    });

    test('offers the token a login returned', () async {
      final store = MemorySessionStore();
      final holder = SessionHolder(store: store, refresher: () => _Refresher());

      await holder.begin(_sessionNamed(1));

      expect(await holder.accessToken(), 'access-1');
      expect(await holder.isSignedIn, isTrue);
      expect((await store.read())?.refreshToken, 'refresh-1');
    });

    test('exchanges the stored credential on a cold start', () async {
      // Nothing but the refresh credential survives a restart: an access token
      // written to disk would outlive nothing useful.
      final store = MemorySessionStore(
        SessionCredential(
          refreshToken: 'refresh-1',
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
        ),
      );
      final refresher = _Refresher();
      final holder = SessionHolder(store: store, refresher: () => refresher);

      expect(await holder.accessToken(), 'access-2');
      expect(refresher.calls, 1);
    });

    test('writes the rotated credential before adopting the session', () async {
      final store = MemorySessionStore();
      final holder = SessionHolder(store: store, refresher: () => _Refresher());

      await holder.begin(_sessionNamed(1, const Duration(seconds: 1)));
      await holder.accessToken();

      // The credential presented is consumed by the call that presents it, so
      // the one on disk has to be its replacement and not the one that was
      // just spent.
      expect((await store.read())?.refreshToken, 'refresh-2');
    });

    test('refreshes a token that is about to expire', () async {
      final refresher = _Refresher();
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => refresher,
      );

      // Inside the margin, so it is stale even though it has not expired: a
      // call sent with it would arrive after it had.
      await holder.begin(_sessionNamed(1, const Duration(seconds: 5)));

      expect(await holder.accessToken(), 'access-2');
      expect(refresher.calls, 1);
    });

    test('refreshes once for two callers that arrive together', () async {
      final refresher = _Refresher()..gate = Completer<void>();
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => refresher,
      );

      await holder.begin(_sessionNamed(1, const Duration(seconds: 1)));

      final first = holder.accessToken();
      final second = holder.accessToken();

      refresher.gate!.complete();

      expect(await first, 'access-2');
      expect(await second, 'access-2');

      // Two exchanges would mean the second presenting a credential the first
      // had already consumed, which is what the node treats as a credential
      // that was copied.
      expect(refresher.calls, 1);
    });

    test('signs the device out when the credential is refused', () async {
      final store = MemorySessionStore();
      final holder = SessionHolder(
        store: store,
        refresher: () => _Refresher(accepts: 'something else'),
      );

      await holder.begin(_sessionNamed(1, const Duration(seconds: 1)));

      await expectLater(holder.accessToken(), throwsA(isA<GrpcError>()));
      expect(await store.read(), isNull);
      expect(await holder.isSignedIn, isFalse);
    });

    test('does not ask about a credential that has already expired', () async {
      final refresher = _Refresher();
      final store = MemorySessionStore(
        SessionCredential(
          refreshToken: 'refresh-1',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        ),
      );
      final holder = SessionHolder(store: store, refresher: () => refresher);

      expect(await holder.isSignedIn, isFalse);
      expect(await holder.accessToken(), isNull);
      expect(refresher.calls, 0);
      expect(await store.read(), isNull);
    });

    test('refuses a refresh that lands after a sign-out', () async {
      // `end()` cannot cancel a call already in the air, so the reply arrives
      // for a session the reader has ended — by signing out, or by a password
      // change that ends every session of every device. Adopting it would
      // write a live credential back and announce a signed-out device as
      // signed in, which the shell's redirect reads: the reader would be put
      // back into the library they had just left.
      final store = MemorySessionStore();
      final refresher = _Refresher()..gate = Completer<void>();
      final holder = SessionHolder(store: store, refresher: () => refresher);

      final announced = <bool>[];
      final listening = holder.signedIn.listen(announced.add);

      await holder.begin(_sessionNamed(1, const Duration(seconds: 1)));

      // In flight, and held there.
      final refreshing = holder.accessToken();

      await holder.end();

      refresher.gate!.complete();

      expect(await refreshing, isNull);
      expect(refresher.calls, 1);
      expect(await store.read(), isNull);
      expect(holder.current, isNull);
      expect(await holder.isSignedIn, isFalse);

      await Future<void>.delayed(Duration.zero);

      // Signed in, then out, and not in again.
      expect(announced, <bool>[true, false]);

      await listening.cancel();
    });

    test('adopts a refresh that lands while the session is live', () async {
      // The other side of the generation check: a refresh that was not
      // outlived by anything still takes.
      final store = MemorySessionStore();
      final refresher = _Refresher()..gate = Completer<void>();
      final holder = SessionHolder(store: store, refresher: () => refresher);

      await holder.begin(_sessionNamed(1, const Duration(seconds: 1)));

      final refreshing = holder.accessToken();

      refresher.gate!.complete();

      expect(await refreshing, 'access-2');
      expect((await store.read())?.refreshToken, 'refresh-2');
      expect(await holder.isSignedIn, isTrue);
    });

    test('forgets the credential on logout', () async {
      final store = MemorySessionStore();
      final holder = SessionHolder(store: store, refresher: () => _Refresher());

      await holder.begin(_sessionNamed(1));
      await holder.end();

      expect(await store.read(), isNull);
      expect(holder.current, isNull);
      expect(await holder.accessToken(), isNull);
    });

    test('compares the expiry against the clock it was given', () async {
      final refresher = _Refresher();
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => refresher,
        clock: () => DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      await holder.begin(_sessionNamed(1));

      // An hour into the future the token issued for five minutes is stale.
      expect(await holder.accessToken(), 'access-2');
    });
  });

  group('SessionHolder.retrying', () {
    test('passes a call that succeeds through untouched', () async {
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => _Refresher(),
      );

      var calls = 0;

      expect(
        await holder.retrying(() async {
          calls++;

          return 'answered';
        }),
        'answered',
      );
      expect(calls, 1);
    });

    test(
      'refreshes and retries once when the node refuses the credential',
      () async {
        final refresher = _Refresher();
        final holder = SessionHolder(
          store: MemorySessionStore(),
          refresher: () => refresher,
        );

        await holder.begin(_sessionNamed(1));

        var calls = 0;

        final answer = await holder.retrying(() async {
          calls++;

          if (calls == 1) {
            throw const GrpcError.unauthenticated('expired');
          }

          return 'answered';
        });

        expect(answer, 'answered');
        expect(calls, 2);
        expect(refresher.calls, 1);
        expect(await holder.accessToken(), 'access-2');
      },
    );

    test('gives up on a second refusal rather than looping', () async {
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => _Refresher(),
      );

      await holder.begin(_sessionNamed(1));

      var calls = 0;

      await expectLater(
        holder.retrying(() async {
          calls++;

          throw const GrpcError.unauthenticated('refused whatever we send');
        }),
        throwsA(isA<GrpcError>()),
      );
      expect(calls, 2);
    });

    test('does not refresh for a failure the credential cannot fix', () async {
      final refresher = _Refresher();
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => refresher,
      );

      await holder.begin(_sessionNamed(1));

      await expectLater(
        holder.retrying(
          () async => throw const GrpcError.notFound('nothing here'),
        ),
        throwsA(isA<GrpcError>()),
      );
      expect(refresher.calls, 0);
    });

    test('does not retry a call made while signed out', () async {
      final holder = SessionHolder(
        store: MemorySessionStore(),
        refresher: () => _Refresher(),
      );

      var calls = 0;

      await expectLater(
        holder.retrying(() async {
          calls++;

          throw const GrpcError.unauthenticated('no token was sent');
        }),
        throwsA(isA<GrpcError>()),
      );

      // There is nothing to refresh with, so the second attempt would present
      // exactly what the first did.
      expect(calls, 1);
    });
  });
}

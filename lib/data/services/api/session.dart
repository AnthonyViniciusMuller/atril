/// The session this device is signed in under, and the two things that keep it
/// alive: a refresh when the access token is stale, and one retry when the
/// node says it already was.
///
/// It sits between the session store, which holds the credential between two
/// runs of the app, and the auth client, which is what exchanges it. Both are
/// ports declared here rather than imports of the implementations, so that
/// this file depends on nothing that dials anything: the refresher is
/// implemented by the auth client in `auth_api.dart`, and the store by
/// whichever one the platform has.
///
/// Three properties are the whole of it.
///
/// **The refresh credential rotates.** `RefreshSession` consumes the
/// credential presented and the reply carries its replacement, so a device
/// that refreshed and did not write the new one has ended its own session. The
/// write happens before the new session is adopted, for that reason.
///
/// **A refresh is single-flight.** Two calls that both meet a stale token must
/// produce one refresh and not two, because the second would present a
/// credential the first has already consumed — which is exactly what the node
/// treats as a credential that was copied.
///
/// **A refused refresh ends the session here.** A credential the node will not
/// take is not a failure to retry: it was consumed, revoked, or it expired, and
/// a device that kept it would ask again on every call for as long as it ran.
library;

import 'dart:async';

import '../../../domain/models/session.dart';
import '../../../utils/logging.dart';
import '../storage/session_store.dart';
import 'grpc_status.dart';

final _log = loggerFor('data/api');

/// What exchanges a refresh credential for a session.
///
/// It is a port and not the auth client itself, because the auth client holds
/// this object: the interceptor that authorizes its calls is the one below,
/// and an import in the other direction would be a cycle rather than a
/// dependency.
abstract interface class SessionRefresher {
  /// The session [refreshToken] buys, whose own refresh credential replaces
  /// the one presented.
  Future<Session> refreshSession(String refreshToken);
}

/// The session this device holds.
///
/// It is not a repository and has no view model above it: what it exposes is
/// the credential a call carries, which is a concern of the transport and of
/// nothing higher. Phase 6's onboarding calls [begin] and [end]; everything
/// else asks for a token and does not know what it cost.
final class SessionHolder {
  /// The session kept in [store] and refreshed through [refresher].
  ///
  /// [clock] is the wall clock the expiry instants are compared against, and
  /// it is a parameter so that a test does not have to wait for a token to
  /// expire. It is deliberately not the hybrid clock: these instants are
  /// `google.protobuf.Timestamp` and mean the time of day, and comparing them
  /// against a logical one would be comparing two different quantities.
  SessionHolder({
    required this.store,
    required this.refresher,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Where the credential is kept between two runs of the app.
  final SessionStore store;

  /// What exchanges it for a session, resolved when it is needed rather than
  /// held.
  ///
  /// The indirection is a real cycle and not a style: the client that
  /// refreshes is the same client whose other calls this session authorizes,
  /// so one of the two has to be reachable later rather than at construction.
  /// A `late final` at the composition root is what closes it, and the port
  /// stays an interface either way.
  final SessionRefresher Function() refresher;

  final DateTime Function() _clock;

  /// The live session, which exists only while this process does.
  Session? _session;

  /// The credential as the store holds it, once it has been read.
  SessionCredential? _credential;

  /// Whether the store has been read. It is separate from [_credential] being
  /// null, which is the answer of a store that has been read and holds
  /// nothing.
  bool _loaded = false;

  /// The refresh in flight, which is what makes a refresh single-flight.
  Future<Session?>? _refreshing;

  /// Whether this device holds a credential it could still exchange.
  ///
  /// It is the question the shell's redirect asks, and it is answered without
  /// a round trip on purpose: a device that has been offline for a month
  /// should open its library rather than a spinner, and one whose credential
  /// expired while it was away should be told so rather than discovering it at
  /// the first sync.
  Future<bool> get isSignedIn async {
    final credential = await _readCredential();

    return credential != null && !credential.hasExpiredAt(_clock());
  }

  /// The session in memory, which is `null` until something has refreshed or
  /// signed in.
  Session? get current => _session;

  /// Adopts the session a login, a registration or a migration returned.
  Future<void> begin(Session session) async {
    await _adopt(session);
    _log.info(
      'the session begins, refresh until ${session.refreshTokenExpiresAt}',
    );
  }

  /// Forgets the session and the credential behind it.
  ///
  /// It clears this and nothing else. The device identity, the reader's row
  /// and the whole local replica survive a logout, because the reader who
  /// signs back in on this device should find their library rather than an
  /// empty one — and because a device that forgot its identifier would start a
  /// vector-clock entry that never merges with the first.
  Future<void> end() async {
    _session = null;
    _credential = null;
    _loaded = true;

    await store.clear();
    _log.info('the session ends');
  }

  /// The access token a call should present, or `null` when this device is
  /// signed out.
  ///
  /// It refreshes where the token is absent or too close to its expiry to be
  /// worth sending, and where a refresh is already in flight it waits for that
  /// one rather than starting a second.
  Future<String?> accessToken() async {
    final live = _session;

    if (live != null && live.isFreshAt(_clock())) {
      return live.accessToken;
    }

    final refreshed = await _refresh(live?.accessToken);

    return refreshed?.accessToken;
  }

  /// Runs [call], and runs it once more if the node answered
  /// `UNAUTHENTICATED`.
  ///
  /// The second attempt is safe for every call in this contract: a request
  /// refused for its credential was refused by the interceptor before the
  /// handler ran, so nothing it would have done has been done. What is *not*
  /// retried is a second refusal — a call that fails again after a successful
  /// refresh is being refused for a reason the credential cannot fix, and
  /// retrying it in a loop would be this client hammering a node that has
  /// already answered.
  ///
  /// It takes a raw call and not a mapped one: the mapping onto the error
  /// vocabulary happens outside this, so what arrives here is still a
  /// `GrpcError` carrying the code the node sent.
  Future<T> retrying<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on GrpcError catch (error) {
      if (error.code != StatusCode.unauthenticated) {
        rethrow;
      }

      _log.fine('the node refused a credential; refreshing once');

      final refreshed = await _refresh(_session?.accessToken);

      if (refreshed == null) {
        rethrow;
      }

      return await call();
    }
  }

  /// The refresh in flight, or a new one.
  ///
  /// [presented] is the access token the caller had already tried. A caller
  /// that presented a token which is no longer the live one arrived after
  /// somebody else's refresh had already landed, and gets that session rather
  /// than provoking another — which matters because a second refresh would
  /// present a credential the first has consumed.
  Future<Session?> _refresh(String? presented) {
    final live = _session;

    if (live != null && presented != null && live.accessToken != presented) {
      return Future<Session?>.value(live);
    }

    final inFlight = _refreshing;

    if (inFlight != null) {
      return inFlight;
    }

    final started = _exchange();
    _refreshing = started;

    return started;
  }

  /// One exchange of the stored credential for a session.
  Future<Session?> _exchange() async {
    try {
      final credential = await _readCredential();

      if (credential == null) {
        return null;
      }

      if (credential.hasExpiredAt(_clock())) {
        _log.info('the refresh credential expired at ${credential.expiresAt}');
        await end();

        return null;
      }

      final session = await refresher().refreshSession(credential.refreshToken);
      await _adopt(session);

      return session;
    } on GrpcError catch (error) {
      // A credential the node will not take is a session that is over: it was
      // consumed, revoked or expired, and keeping it would mean asking again
      // on every call for as long as this process runs.
      if (error.code == StatusCode.unauthenticated) {
        _log.info('the node refused the refresh credential');
        await end();
      }

      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  /// Takes a session on, writing its credential before adopting it.
  ///
  /// The order is the rotation the contract requires: the credential presented
  /// is already consumed by the time the reply arrives, so a device that
  /// adopted the session and then failed to write its replacement would hold,
  /// in memory only, the sole credential able to obtain another session.
  Future<void> _adopt(Session session) async {
    final credential = session.credential;

    await store.write(credential);

    _credential = credential;
    _loaded = true;
    _session = session;
  }

  /// The stored credential, read once and remembered.
  Future<SessionCredential?> _readCredential() async {
    if (_loaded) {
      return _credential;
    }

    _credential = await store.read();
    _loaded = true;

    return _credential;
  }
}

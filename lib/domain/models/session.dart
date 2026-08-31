/// What a device is issued when the reader signs in, and what it presents
/// afterwards.
///
/// The contract splits the credential in two and the split is the whole design
/// (RNF11). The access token is a short-lived JWT, verified by signature
/// against the keys the node publishes, so it is stored on neither side and
/// cannot be revoked before it expires — which is why it is short. The refresh
/// credential is opaque and long-lived, only its digest is stored on the node,
/// and presenting it is what revocation acts on.
///
/// The two halves are held in different places here for the same reason. The
/// access token lives in memory: it outlives nothing useful, and a JWT written
/// to disk is a JWT that survives the process for no gain. The refresh
/// credential is what [SessionCredential] carries into the session store, and
/// it is what says, on the next cold start, that this device is signed in.
library;

/// How long before its stated expiry an access token stops being offered.
///
/// A token that expires while the request carrying it is in flight is refused
/// by the node and costs a round trip to discover. The margin is what avoids
/// that, and it is deliberately larger than any plausible clock skew between a
/// device and its node: both are wall clocks and nothing here synchronizes
/// them.
const Duration accessTokenMargin = Duration(seconds: 30);

/// A session, as the node issued it.
final class Session {
  /// The session carrying both halves and the instants they expire at.
  const Session({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  /// The short-lived JWT every authenticated call presents.
  final String accessToken;

  /// When the node stops accepting it. A wall clock instant, and not the
  /// hybrid one a write is stamped with.
  final DateTime accessTokenExpiresAt;

  /// The opaque credential a new session is obtained with. It is consumed by
  /// the call that presents it, and the reply carries its replacement.
  final String refreshToken;

  /// When the refresh credential itself expires, after which the reader signs
  /// in again.
  final DateTime refreshTokenExpiresAt;

  /// The half of the session that is worth persisting.
  SessionCredential get credential => SessionCredential(
    refreshToken: refreshToken,
    expiresAt: refreshTokenExpiresAt,
  );

  /// Whether the access token is still worth presenting at [now].
  ///
  /// It answers false [accessTokenMargin] before the stated expiry, so that a
  /// call is not sent with a credential that will have expired by the time it
  /// arrives.
  bool isFreshAt(DateTime now) =>
      now.toUtc().add(accessTokenMargin).isBefore(accessTokenExpiresAt.toUtc());

  /// Whether the refresh credential has expired at [now], which is the end of
  /// the session rather than a call to refresh.
  bool hasEndedAt(DateTime now) => credential.hasExpiredAt(now);

  /// The session, with nothing in it that could be replayed if it were logged.
  @override
  String toString() =>
      'Session(access until $accessTokenExpiresAt, '
      'refresh until $refreshTokenExpiresAt)';
}

/// The persisted half of a session: the credential a new one is obtained with.
final class SessionCredential {
  /// The credential and the instant it expires at.
  const SessionCredential({
    required this.refreshToken,
    required this.expiresAt,
  });

  /// The opaque credential.
  final String refreshToken;

  /// When it stops being accepted.
  final DateTime expiresAt;

  /// Whether it has expired at [now].
  ///
  /// A device holding an expired credential is signed out and does not know it
  /// yet. Asking here rather than finding out from the node is what keeps a
  /// device that has been offline for a month from opening with a round trip
  /// it already knows the answer to.
  bool hasExpiredAt(DateTime now) => !now.toUtc().isBefore(expiresAt.toUtc());

  /// The credential, without the credential.
  @override
  String toString() => 'SessionCredential(until $expiresAt)';
}

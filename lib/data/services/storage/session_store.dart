/// Where the refresh credential is kept between two runs of the app.
///
/// It holds one thing and holds it for one reason: a device that is signed in
/// has a credential it can exchange for a session, and a device that has none
/// is a device the shell sends to onboarding. Everything else about the reader
/// — who they are, which node they belong to, what their library holds — is in
/// the local database, which is why signing out clears this and nothing else.
///
/// The **device identity is deliberately not here.** It lives in the local
/// database and survives a logout, because a device that forgot the identifier
/// it was bound under would start a second vector-clock entry that never
/// merges with the first.
///
/// The interface is what the session takes; the implementations arrive with
/// the platform that has one, and a test uses [MemorySessionStore] rather than
/// a keychain that is not there.
library;

import '../../../domain/models/session.dart';

/// The operation a session store reports its failures under.
const String opSessionStore = 'data/storage: session';

/// Where the refresh credential is kept.
///
/// Every method is asynchronous because every platform's own store is: a
/// keychain is a system call and a browser's storage is not synchronous
/// either from Dart's side.
abstract interface class SessionStore {
  /// The credential this device holds, or `null` when it holds none.
  Future<SessionCredential?> read();

  /// Replaces what is held.
  ///
  /// It is called on every refresh and not only on login, because the contract
  /// rotates: the credential presented is consumed and the reply carries its
  /// replacement, so a device that failed to write the new one has ended its
  /// own session.
  Future<void> write(SessionCredential credential);

  /// Forgets the credential. It is what logging out does, and what a rejected
  /// refresh does on the device's own initiative.
  Future<void> clear();
}

/// A store that holds the credential for as long as the process runs.
///
/// It is what a test signs in against, and it is the honest answer for a
/// platform with nowhere to keep a secret — one run of the app, and the reader
/// signs in again.
final class MemorySessionStore implements SessionStore {
  /// The empty store, or one already holding [credential].
  MemorySessionStore([this._credential]);

  SessionCredential? _credential;

  @override
  Future<SessionCredential?> read() async => _credential;

  @override
  Future<void> write(SessionCredential credential) async {
    _credential = credential;
  }

  @override
  Future<void> clear() async {
    _credential = null;
  }
}

/// Who is signed in on this device, and how they got there.
///
/// UC07 is the whole of it, and the part worth stating twice is the binding.
/// A device asking for a session carries the identifier it already writes
/// under, and a device that has none is given one — which is the identifier
/// every vector-clock entry it ever authors is counted by. Losing it is the one
/// mistake this app cannot recover from, so it is written to the local database
/// before the session is adopted and it survives a logout.
library;

import '../../../domain/models/user.dart';
import '../../../utils/result.dart';

/// What a reader hands over to sign in.
final class Credentials {
  /// The reader at [identifier], proving it with [password], on a device the
  /// node should call [deviceName] if it is binding it for the first time.
  const Credentials({
    required this.identifier,
    required this.password,
    required this.deviceName,
  });

  /// Either half of what identifies the reader to their own node: the local
  /// name, or the address.
  ///
  /// Which of the two is decided by the client and not by the node — a local
  /// name cannot contain an `@` and an address must — and the contract spells
  /// the choice as a `oneof` precisely so that a server is not left parsing it.
  final String identifier;

  /// The password, which reaches nothing but the node.
  final String password;

  /// What the reader's device list should call this device.
  ///
  /// It is sent on every login and read by the node only when it is binding a
  /// device for the first time. It comes from the screen rather than from here
  /// because it is a user-visible string, and those live in the ARB.
  final String deviceName;

  /// The credentials, without the credential.
  @override
  String toString() => 'Credentials($identifier, $deviceName)';
}

/// What a reader hands over to create an account.
final class Registration {
  /// The account `@localName` at the node this device is talking to.
  const Registration({
    required this.localName,
    required this.displayName,
    required this.email,
    required this.password,
  });

  /// The first half of the federated identifier. The second half is not a
  /// parameter: it is which node the call was addressed to.
  final String localName;

  /// What the reader calls themselves, and the only name meant to be shown.
  final String displayName;

  /// The address recovery is sent to (UC08).
  final String email;

  /// The password, which reaches nothing but the node.
  final String password;

  /// The registration, without the credential.
  @override
  String toString() => 'Registration($localName)';
}

/// The reader signed in on this device.
abstract interface class AuthRepository {
  /// UC14. Creates the reader on the node this device is talking to.
  ///
  /// It does not sign them in, because the node does not: `RegisterUser`
  /// answers with the reader and no session, so what follows a registration is
  /// a login like anybody else's.
  ///
  /// The four inputs are checked here before anything travels, against the same
  /// rules the node publishes. It is not distrust of the node — the node checks
  /// them again and is the only authority on a name being *taken* — it is that
  /// a reader who typed a capital letter into a local name should be told so by
  /// the field, and not by a round trip.
  Future<Result<User>> register(Registration registration);

  /// Signs [credentials] in, binds this device, and adopts the session.
  ///
  /// Everything it writes it writes before the session is adopted: the device
  /// identity, the node the reader is hosted at, and the reader's own row. A
  /// device that adopted the session first and then failed would be a device
  /// the shell believes is signed in and that cannot say who as.
  Future<Result<User>> signIn(Credentials credentials);

  /// UC08, first half. Asks the node to send a recovery credential to
  /// [email].
  ///
  /// It answers the same way whether or not the address is registered there,
  /// and this client keeps that promise: nothing it returns and nothing the
  /// screen shows distinguishes the two. An interface that helpfully said *no
  /// such account* would turn a recovery form into a way of finding out who
  /// has one.
  ///
  /// The address is checked for shape before it is sent, which is a different
  /// question and is safe to answer: it is about what was typed and not about
  /// who exists.
  Future<Result<void>> requestPasswordRecovery(String email);

  /// UC08, second half. Spends [recoveryToken] and sets [newPassword].
  ///
  /// It ends every session of every one of the reader's devices, which is the
  /// point: a password is reset by somebody who has lost control of the old
  /// one, and leaving the sessions it opened alive would leave whoever took it
  /// signed in.
  Future<Result<void>> resetPassword({
    required String recoveryToken,
    required String newPassword,
  });

  /// The reader signed in on this device, and `null` on one where nobody is.
  ///
  /// It is a stream because the answer changes without anybody on this screen
  /// asking: a refresh credential the node refuses signs the device out, and a
  /// surface naming the reader has to stop naming them.
  ///
  /// It is read from the local database and not from the node, which is what
  /// makes it correct offline. A logged-out device still has a row here, and
  /// that is deliberate — see [signOut].
  Stream<User?> reader();

  /// Ends the session on this device, and on this device alone (RN07).
  ///
  /// It clears the session and nothing else. The device identity, the local
  /// replica and the log this device still owes all stay, because logging out
  /// is not unbinding: the reader who signs back in here should find their
  /// library rather than an empty one, and a device that forgot its identifier
  /// would start a vector-clock entry that never merges with the first.
  ///
  /// The local half always happens. A reader who asks to sign out on a train
  /// is signed out; the node's copy of the credential is revoked when the node
  /// can be reached, and the credential itself is destroyed here either way, so
  /// what survives a failed call is a credential nobody holds.
  Future<Result<void>> signOut();
}

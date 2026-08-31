/// [AuthRepository] over the node's `AuthService`, the local identity tables
/// and the session holder.
library;

import '../../../domain/models/device.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/errors.dart';
import '../../services/api/session.dart';
import '../../services/local/dao/identity_dao.dart';
import '../../services/local/database.dart';
import '../server/server_repository.dart';
import 'auth_repository.dart';

final _log = loggerFor('data/auth');

/// The operation a sign-in reports under.
const String opSignIn = 'identity/session: sign in';

/// The operation a registration reports under.
const String opRegisterUser = 'identity/user: register';

/// The operation a request for a recovery credential reports under.
const String opRecoverPassword = 'identity/user: request recovery';

/// The operation a password reset reports under.
const String opResetPassword = 'identity/user: reset password';

/// The node's code for a reset that presents nothing.
const String codeNoCredential = 'no_credential';

/// The node's code for a recovery credential it will not take.
///
/// One answer for four states — never issued, already spent, expired, or for
/// somebody else — because which of them it was is a fact about an account the
/// caller has not proved anything about.
const String codeInvalidCredential = 'invalid_credential';

/// The reader signed in on this device.
final class AuthRepositoryImpl implements AuthRepository {
  /// The repository over [auth], [identity], [servers] and [session].
  ///
  /// [platform] is what this device binds under, read at the edge because a
  /// repository that asked the framework what platform it was on could not be
  /// tested as any other.
  AuthRepositoryImpl({
    required this.auth,
    required this.identity,
    required this.servers,
    required this.session,
    required this.platform,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The node's `AuthService`.
  final AuthApi auth;

  /// The device's own identity tables.
  final IdentityDao identity;

  /// The catalogue, which is what learns where the reader is hosted.
  ///
  /// It is another repository and that is deliberate rather than a shortcut: a
  /// login is one behaviour, and *which node the reader is named at* is a fact
  /// about the catalogue that only a login can establish. Splitting it into a
  /// use case would put one call in a layer of its own.
  final ServerRepository servers;

  /// The session this device holds.
  final SessionHolder session;

  /// The platform string sent at binding.
  final String platform;

  final DateTime Function() _clock;

  @override
  Future<Result<User>> register(Registration registration) async {
    final localName = canonicalLocalName(registration.localName);
    final displayName = registration.displayName.trim();
    final email = registration.email.trim();

    // Every violation and not the first one: a form that reported one field at
    // a time would make the reader submit four times to learn four things the
    // client already knew.
    final refused = <String, String>{
      if (localNameViolation(localName) case final String why)
        'local_name': why,
      if (displayNameViolation(displayName) case final String why)
        'display_name': why,
      if (emailViolation(email) case final String why) 'email': why,
      if (passwordViolation(registration.password) case final String why)
        'password': why,
    };

    if (refused.isNotEmpty) {
      return Result<User>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the registration was refused before it was sent',
          op: opRegisterUser,
        ).withFields(<FieldFailure>[
          for (final MapEntry<String, String> entry in refused.entries)
            FieldFailure(entry.key, entry.value),
        ]),
      );
    }

    try {
      final user = await auth.registerUser(
        localName: localName,
        displayName: displayName,
        email: email,
        password: registration.password,
      );

      // Nothing is written here. A registration is an account on a node, not a
      // reader on this device: what makes this device that reader's is the
      // login that follows, and a row written now would describe somebody
      // nobody has proved they are.
      _log.info('${user.federatedId} was created');

      return Result<User>.ok(user);
    } on Exception catch (error) {
      return Result<User>.error(failureFrom(error, op: opRegisterUser));
    }
  }

  @override
  Future<Result<void>> requestPasswordRecovery(String email) async {
    final address = email.trim();
    final violation = emailViolation(address);

    if (violation != null) {
      return Result<void>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the address "$address" $violation',
          code: codeInvalidEmail,
          op: opRecoverPassword,
        ).withField('email', violation),
      );
    }

    try {
      await auth.requestPasswordRecovery(address);

      return const Result<void>.ok(null);
    } on Exception catch (error) {
      return Result<void>.error(failureFrom(error, op: opRecoverPassword));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String recoveryToken,
    required String newPassword,
  }) async {
    final token = recoveryToken.trim();
    final violation = passwordViolation(newPassword);

    if (token.isEmpty) {
      return Result<void>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the reset presents no recovery credential',
          code: codeNoCredential,
          op: opResetPassword,
        ).withField('recovery_token', 'it must not be empty'),
      );
    }

    if (violation != null) {
      return Result<void>.error(
        AppException(
          kind: ErrorKind.invalidArgument,
          message: 'the new password $violation',
          code: codeInvalidPassword,
          op: opResetPassword,
        ).withField('password', violation),
      );
    }

    try {
      await auth.resetPassword(recoveryToken: token, newPassword: newPassword);

      // Every session of every device is over, including this one's if it had
      // one. Clearing it here is what stops this device from presenting a
      // credential the node has already thrown away on every call it makes.
      await session.end();

      return const Result<void>.ok(null);
    } on Exception catch (error) {
      return Result<void>.error(failureFrom(error, op: opResetPassword));
    }
  }

  @override
  Stream<User?> reader() => identity.watchReader().map(
    (ReaderRow? row) => row == null
        ? null
        : User(
            id: row.id,
            localName: row.localName,
            displayName: row.displayName,
            originServerDomain: row.originServerDomain,
            federatedId: row.federatedId,
            createdAt: row.createdAt,
            email: row.email,
          ),
  );

  @override
  Future<Result<void>> signOut() async {
    final held = await session.credential();

    // Presented rather than inferred from the session: a device whose access
    // token has already expired can still end its session, and one that has
    // made no call since it started holds no session in memory at all.
    if (held != null && !held.hasExpiredAt(_clock())) {
      try {
        await auth.logout(held.refreshToken);
      } on Exception catch (error) {
        // Reported and not returned. The reader asked to sign out, and a node
        // that could not be told is a node holding a credential that will
        // exist nowhere else a moment from now.
        _log.warning('the node was not told about the sign-out', error);
      }
    }

    await session.end();

    return const Result<void>.ok(null);
  }

  @override
  Future<Result<User>> signIn(Credentials credentials) async {
    try {
      // The identifier this device already writes under, if it has one.
      // Omitting it on a device that has one is the mistake the whole design
      // is most vulnerable to: the node would mint a second identifier and
      // this device would start a vector-clock entry that never merges with
      // the first.
      final bound = await identity.deviceId();

      final signIn = await auth.login(
        identifier: credentials.identifier.trim(),
        password: credentials.password,
        device: DeviceBinding(
          deviceId: bound,
          name: credentials.deviceName,
          platform: platform,
        ),
      );

      final at = _clock();

      await identity.bindDevice(
        id: signIn.device.id,
        name: signIn.device.name,
        platform: signIn.device.platform,
        at: at,
      );

      // The node the reader is *named* at, which is what the reader's row has
      // to reference and what a later launch dials.
      final origin = await servers.adoptOrigin(signIn.user.originServerDomain);

      if (origin case Error<ServerDescriptor>(:final error)) {
        return Result<User>.error(error);
      }

      await identity.rememberReader(
        id: signIn.user.id,
        localName: signIn.user.localName,
        displayName: signIn.user.displayName,
        originServerDomain: signIn.user.originServerDomain,
        federatedId: signIn.user.federatedId,
        createdAt: signIn.user.createdAt,
        email: signIn.user.email,
      );

      // Last, and only once everything above has been written. The shell reads
      // this to decide whether the reader may see their library, and a device
      // it believed was signed in but that could not say who as would be a
      // library it could not fill.
      await session.begin(signIn.session);

      _log.info(
        '${signIn.user.federatedId} is signed in on ${signIn.device.id}',
      );

      return Result<User>.ok(signIn.user);
    } on Exception catch (error) {
      return Result<User>.error(failureFrom(error, op: opSignIn));
    }
  }
}

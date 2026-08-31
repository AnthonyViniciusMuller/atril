/// [AuthRepository] over the node's `AuthService`, the local identity tables
/// and the session holder.
library;

import '../../../domain/models/device.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/errors.dart';
import '../../services/api/session.dart';
import '../../services/local/dao/identity_dao.dart';
import '../server/server_repository.dart';
import 'auth_repository.dart';

final _log = loggerFor('data/auth');

/// The operation a sign-in reports under.
const String opSignIn = 'identity/session: sign in';

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

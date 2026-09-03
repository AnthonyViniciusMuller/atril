/// The node this device synchronizes with, asked for once.
///
/// The pull, the stream and the watch each need the same fact — the domain of
/// the node this device is signed in at — and each has to refuse the same way
/// when there is none, because a device bound nowhere cannot synchronize and
/// no retry changes that. It was three copies of the lookup and three of the
/// refusal; the only thing that ever differed between them is which operation
/// the failure is reported under, which is what [SyncOrigin.originDomain]
/// takes.
library;

import '../../../utils/errors.dart';
import '../local/database.dart';

/// The code a caller that is signed in nowhere is refused with.
const String noOriginServer = 'no_origin_server';

/// Where this device's replica is asked which node it belongs to.
extension SyncOrigin on AtrilDatabase {
  /// The domain of the node this device is signed in at.
  ///
  /// It throws an [AppException] reported under [op] where there is none, which
  /// is a missing precondition and not a failure of the call: the device has
  /// nothing to synchronize with until a reader signs in.
  Future<String> originDomain({required String op}) async {
    final origin = await identityDao.originServer();

    if (origin == null) {
      throw AppException(
        kind: ErrorKind.failedPrecondition,
        message:
            'this device is not signed in at any node and cannot '
            'synchronize',
        code: noOriginServer,
        op: op,
      );
    }

    return origin.domain;
  }
}

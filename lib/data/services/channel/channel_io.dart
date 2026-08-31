/// The channel on the five native targets: gRPC over HTTP/2.
library;

import 'package:grpc/grpc.dart' as grpc;
import 'package:grpc/service_api.dart' show ClientChannel;

import '../../../utils/logging.dart';
import 'endpoint.dart';

final _log = loggerFor('data/channel');

/// How long a connection with no calls on it is kept before it is dropped.
///
/// It is longer than `grpc`'s own default of five minutes because this client
/// holds a synchronization stream open and reconnects on a bounded backoff:
/// dropping the connection under an idle stream costs a handshake to say
/// nothing, and a device on a mobile network pays for the handshake twice.
const Duration channelIdleTimeout = Duration(minutes: 15);

/// The channel [endpoint] is dialled over.
///
/// The certificate authority is optional and is the whole reason it is a
/// parameter rather than a constant: the local federation `make dev-up` starts
/// answers under a self-signed certificate, and a build that could only trust
/// the platform's store could not be pointed at it. Where none is given the
/// platform's store decides, which is what a production node is dialled under.
///
/// It fails with [ErrorKind.failedPrecondition] on a node whose discovery
/// document published no `grpc` authority — a node this device can record and
/// cannot dial, which the contract admits by marking the field `optional`.
ClientChannel openChannel(NodeEndpoint endpoint) {
  final host = endpoint.host;
  final port = endpoint.port;

  if (host == null || port == null) {
    throw endpoint.undialable('native');
  }

  final certificates = endpoint.certificateAuthority;

  final credentials = switch ((endpoint.transportSecurity, certificates)) {
    (false, _) => const grpc.ChannelCredentials.insecure(),
    (true, null) => const grpc.ChannelCredentials.secure(),
    (true, final List<int> pem) => grpc.ChannelCredentials.secure(
      certificates: pem,
    ),
  };

  _log.fine(
    'dialling $host:$port over http/2, '
    '${credentials.isSecure ? 'tls' : 'in clear text'}'
    '${certificates == null ? '' : ', trusting a pinned authority'}',
  );

  return grpc.ClientChannel(
    host,
    port: port,
    options: grpc.ChannelOptions(
      credentials: credentials,
      idleTimeout: channelIdleTimeout,
    ),
  );
}

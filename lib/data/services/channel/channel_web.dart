/// The channel in a browser: gRPC-Web, translated by the node's own gateway.
library;

import 'package:grpc/grpc_web.dart';
import 'package:grpc/service_api.dart' show ClientChannel;

import '../../../utils/logging.dart';
import 'endpoint.dart';

final _log = loggerFor('data/channel');

/// The channel [endpoint] is dialled over.
///
/// It is the gateway's URL and not the node's gRPC authority, and D10 is why:
/// what a node publishes is the address a peer dials for replication, over
/// HTTP/2 with a client certificate, and neither half of that is available to
/// a page. Quire's own Istio gateway inserts `envoy.filters.http.grpc_web` on
/// the terminated port and answers the same methods in a framing a browser can
/// send, so what changes here is the address and the framing and nothing about
/// the contract.
///
/// The certificate authority [NodeEndpoint] may carry is ignored, because
/// there is nothing to do with it: a page cannot add to the browser's trust
/// store, and against `make dev-up` it does not need to — the gRPC-Web lane is
/// plain HTTP on a loopback address, which a browser treats as a secure
/// context.
///
/// It fails with [ErrorKind.failedPrecondition] when nothing named a gateway,
/// which is a configuration this build cannot dial rather than a node that is
/// down.
ClientChannel openChannel(NodeEndpoint endpoint) {
  final gateway = endpoint.gateway;

  if (gateway == null) {
    throw endpoint.undialable('web');
  }

  _log.fine('dialling $gateway over grpc-web');

  return GrpcWebClientChannel.xhr(gateway);
}

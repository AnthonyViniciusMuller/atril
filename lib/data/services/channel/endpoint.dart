/// Where a node answers, in the two forms the two lanes dial it by.
///
/// A node has one address in the contract and two here, because the six
/// targets do not reach it the same way. The five native builds dial the
/// `grpc` authority the node's own discovery document publishes — `host:port`,
/// over HTTP/2, under TLS. A browser cannot dial it at all: gRPC over HTTP/2
/// is not something a page can speak, so it addresses the gateway that
/// translates gRPC-Web, which is a separate address the environment names.
/// [`architecture.md`](../../../../docs/architecture.md) says why the
/// descriptor cannot answer for both — what it publishes is the authority a
/// *peer* dials for replication, and a browser is not a peer.
///
/// One value carries both, and each half of the conditional export in
/// `channel.dart` reads the field its platform can dial. That is deliberate:
/// the configuration is one struct, written once and compiled six times, and a
/// field that only some targets read costs less than a configuration that has
/// to know which target it is being compiled for.
library;

import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';

/// The operation the channel reports its failures under.
const String opChannel = 'data/channel: open';

/// The stable code of an authority this device cannot dial.
const String codeUnusableAuthority = 'unusable_grpc_authority';

/// The stable code of a node with no address for the lane this build runs on.
///
/// It is not a fault of the reader's and not a network failure: it is a node
/// whose discovery document published no `grpc` authority, which the contract
/// admits with `optional` and describes as a node this instance can record and
/// cannot replicate to. A browser reaches the same state when nothing named a
/// gateway for it.
const String codeUndialable = 'node_not_dialable';

/// The address of one node, as each lane needs it.
final class NodeEndpoint {
  /// The endpoint dialled at [authority] natively and at [gateway] in a
  /// browser.
  ///
  /// [authority] is `host:port` — the form `ServerDescriptor.grpc` publishes,
  /// with the port spelled out. It is parsed here rather than at the first
  /// call, so that a node the configuration cannot dial is a failure where the
  /// configuration is read and not one that surfaces halfway through a sync.
  ///
  /// [certificateAuthority] is the PEM of the authority to trust instead of
  /// the platform's own, which is what makes the self-signed local federation
  /// dialable. It is read by the native lane alone: a browser's trust store is
  /// the browser's, and a page cannot add to it.
  factory NodeEndpoint({
    String? authority,
    Uri? gateway,
    List<int>? certificateAuthority,
    bool transportSecurity = true,
  }) {
    final dialled = authority == null ? null : _split(authority);

    return NodeEndpoint._(
      authority: authority,
      host: dialled?.host,
      port: dialled?.port,
      gateway: gateway,
      certificateAuthority: certificateAuthority,
      transportSecurity: transportSecurity,
    );
  }

  /// The endpoint a node described by [descriptor] is dialled at.
  ///
  /// Both lanes are filled from the one document, and each half of the
  /// conditional export reads the field its platform can dial. The native lane
  /// dials `grpc`, which is what the node published for the purpose. A browser
  /// dials the base URL, because that is the origin the node answers HTTP on
  /// and therefore the address its gateway translates gRPC-Web at — the `grpc`
  /// authority is what a *peer* dials for replication, over HTTP/2 with a
  /// client certificate, and a page has neither.
  ///
  /// [certificateAuthority] is the local federation's, and is `null` for every
  /// node a reader ever types: a production node is dialled under the
  /// platform's own trust store.
  factory NodeEndpoint.of(
    ServerDescriptor descriptor, {
    List<int>? certificateAuthority,
  }) => NodeEndpoint(
    authority: descriptor.grpcAuthority,
    gateway: Uri.tryParse(descriptor.baseUrl),
    certificateAuthority: certificateAuthority,
  );

  const NodeEndpoint._({
    required this.authority,
    required this.host,
    required this.port,
    required this.gateway,
    required this.certificateAuthority,
    required this.transportSecurity,
  });

  /// `host:port`, as the node published it, or `null` for a node that
  /// published none.
  final String? authority;

  /// The host half of [authority], without the brackets an IPv6 literal is
  /// written in.
  final String? host;

  /// The port half of [authority].
  final int? port;

  /// Where the gRPC-Web gateway answers, which is what a browser dials.
  ///
  /// Against `make dev-up` it is `http://127.0.0.1:18090` for the first node
  /// and `:28090` for the second — plain HTTP, because a loopback origin is a
  /// secure context and the development certificates are self-signed.
  final Uri? gateway;

  /// The PEM of the certificate authority the native lane trusts instead of
  /// the platform's own, or `null` to use the platform's.
  final List<int>? certificateAuthority;

  /// Whether the native lane is TLS. It is false only where the transport is
  /// already secured by something else — a loopback address, or a sidecar.
  final bool transportSecurity;

  /// The failure raised when the lane this build runs on has no address.
  AppException undialable(String lane) => AppException(
    kind: ErrorKind.failedPrecondition,
    message: 'this node published no address a $lane build can dial',
    code: codeUndialable,
    op: opChannel,
  );

  /// The two halves of [authority], or the failure that says why it is not an
  /// authority.
  ///
  /// A bare host is refused rather than defaulted to 443. The contract spells
  /// the field `host:port` and the field is what a node published about
  /// itself, so a missing port is a node saying something this client cannot
  /// act on — and a guess would be dialling somewhere nobody named.
  static ({String host, int port}) _split(String authority) {
    final value = authority.trim();

    if (value.isEmpty) {
      throw _notAnAuthority(authority, 'is empty');
    }

    if (value.contains('://')) {
      throw _notAnAuthority(authority, 'is a URL and not a host:port');
    }

    final separator = value.startsWith('[')
        ? _afterBracket(authority, value)
        : value.indexOf(':');

    if (separator < 0 || separator == value.length - 1) {
      throw _notAnAuthority(authority, 'names no port');
    }

    final host = value.substring(0, separator);
    final port = int.tryParse(value.substring(separator + 1));

    if (host.isEmpty) {
      throw _notAnAuthority(authority, 'names no host');
    }

    if (port == null || port < 1 || port > 65535) {
      throw _notAnAuthority(
        authority,
        'names no port a socket can be opened on',
      );
    }

    // The brackets are the notation an IPv6 literal is written in inside an
    // authority, and they are not part of the address a socket is opened on.
    return (
      host: host.startsWith('[') ? host.substring(1, host.length - 1) : host,
      port: port,
    );
  }

  /// The index of the port separator of a bracketed IPv6 authority.
  static int _afterBracket(String authority, String value) {
    final close = value.indexOf(']');

    if (close < 0) {
      throw _notAnAuthority(authority, 'opens a bracket it does not close');
    }

    return value.indexOf(':', close);
  }

  static AppException _notAnAuthority(String authority, String reason) =>
      AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the gRPC authority "$authority" $reason',
        code: codeUnusableAuthority,
        op: opChannel,
      ).withField('grpc', reason);

  /// The endpoint, without the certificate it may be carrying.
  @override
  String toString() =>
      'NodeEndpoint(${authority ?? '-'}, gateway: ${gateway ?? '-'}, '
      'tls: $transportSecurity, ca: ${certificateAuthority == null ? 'platform' : 'pinned'})';
}

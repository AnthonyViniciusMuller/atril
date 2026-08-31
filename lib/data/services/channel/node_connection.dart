/// The node this app is currently talking to, and the one place that changes
/// when the reader chooses a different one.
///
/// A build starts pointed at whatever its [Environment] named — nothing, for a
/// shipped one — and a device is pointed at a node twice in its life: when the
/// reader picks one during onboarding, and on every launch afterwards, at the
/// node the local catalogue records as their origin. Neither of those moments
/// can be the moment the graph is built, so the endpoint is held here and the
/// five API clients read the channel through it.
///
/// **Nothing is dialled until a call is made.** A device with no session
/// reaches onboarding without opening a socket to a node nobody has chosen,
/// which is the property `config/dependencies.dart` used to get from a lazy
/// provider and now gets from this object regardless of when it is read.
///
/// **It is a supplier and not a `ClientChannel`.** The obvious shape is a
/// channel that forwards to whichever one is live, and it is not available:
/// `ClientChannel.createCall` returns a `ClientCall` and
/// `onConnectionStateChanged` a `ConnectionState`, and `package:grpc` publishes
/// both of those types through `grpc.dart` alone — the library that also
/// exports the HTTP/2 channel and therefore `dart:io`, which does not parse for
/// the web target. An implementation of the interface could not name its own
/// signatures on all six targets. So the indirection sits one level up: a
/// client asks for the channel when it makes a call, and a stub is built around
/// the answer rather than around a channel captured at construction.
library;

import 'package:grpc/service_api.dart' show ClientChannel;

import '../../../utils/logging.dart';
import 'channel.dart';

final _log = loggerFor('data/channel');

/// What opens a channel to an endpoint. It is a parameter so that a test can
/// watch a connection being re-pointed without a node to point it at.
typedef ChannelFactory = ClientChannel Function(NodeEndpoint endpoint);

/// The node this device is talking to.
final class NodeConnection {
  /// The connection to [endpoint], opening its channel through [open].
  NodeConnection(this._endpoint, {ChannelFactory? open})
    : _open = open ?? openChannel;

  final ChannelFactory _open;

  NodeEndpoint _endpoint;
  ClientChannel? _channel;

  /// Where this device is currently pointed.
  NodeEndpoint get endpoint => _endpoint;

  /// Whether a channel is open, which is what a test asserts instead of
  /// watching a socket.
  bool get isOpen => _channel != null;

  /// The channel a call is made over, opened the first time one is.
  ///
  /// It throws where the endpoint has no address the lane this build runs on
  /// can dial, which is [NodeEndpoint.undialable] and is a failure of the
  /// configuration rather than of the node.
  ClientChannel get channel => _channel ??= _open(_endpoint);

  /// Points this device at [endpoint], closing the channel it was using.
  ///
  /// The old channel is shut down and not terminated: a call already in flight
  /// is allowed to finish, because the reader who changed nodes did not ask for
  /// the reply to the request they made a moment ago to be thrown away.
  ///
  /// Re-pointing at the node already dialled does nothing, so a reader who taps
  /// the same server twice does not pay for a second handshake.
  Future<void> connectTo(NodeEndpoint endpoint) async {
    if (endpoint.authority == _endpoint.authority &&
        endpoint.gateway == _endpoint.gateway) {
      _endpoint = endpoint;

      return;
    }

    _log.info('pointing at $endpoint');

    final open = _channel;

    _channel = null;
    _endpoint = endpoint;

    await open?.shutdown();
  }

  /// Closes the channel, if one was ever opened.
  Future<void> shutdown() async {
    final open = _channel;

    _channel = null;

    await open?.shutdown();
  }
}

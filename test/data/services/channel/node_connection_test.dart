/// The node this device is talking to, and what happens when it changes.
library;

import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/service_api.dart'
    show CallOptions, ClientChannel, ClientMethod;

/// A channel that dials nothing and records that it was asked to close.
final class _FakeChannel implements ClientChannel {
  _FakeChannel(this.endpoint);

  final NodeEndpoint endpoint;
  bool isShutDown = false;

  @override
  Future<void> shutdown() async => isShutDown = true;

  @override
  Future<void> terminate() async => isShutDown = true;

  @override
  Never createCall<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
  ) => throw UnimplementedError();

  @override
  Never get onConnectionStateChanged => throw UnimplementedError();
}

void main() {
  final opened = <_FakeChannel>[];

  ClientChannel open(NodeEndpoint endpoint) {
    final channel = _FakeChannel(endpoint);
    opened.add(channel);

    return channel;
  }

  setUp(opened.clear);

  NodeEndpoint at(String host) => NodeEndpoint(
    authority: '$host:9090',
    gateway: Uri.parse('https://$host'),
  );

  test('dials nothing until a call is made', () {
    final connection = NodeConnection(at('quire-a.example'), open: open);

    expect(connection.isOpen, isFalse);
    expect(opened, isEmpty);

    connection.channel;

    expect(connection.isOpen, isTrue);
    expect(opened, hasLength(1));
  });

  test('opens one channel however often it is asked for', () {
    final connection = NodeConnection(at('quire-a.example'), open: open);

    expect(identical(connection.channel, connection.channel), isTrue);
    expect(opened, hasLength(1));
  });

  test('closes the old channel when it is pointed somewhere else', () async {
    final connection = NodeConnection(at('quire-a.example'), open: open);
    final first = connection.channel;

    await connection.connectTo(at('quire-b.example'));

    expect(opened.single.isShutDown, isTrue);
    expect(connection.isOpen, isFalse);
    expect(connection.endpoint.authority, 'quire-b.example:9090');
    expect(identical(connection.channel, first), isFalse);
  });

  test('does not re-dial the node it is already pointed at', () async {
    final connection = NodeConnection(at('quire-a.example'), open: open);
    final first = connection.channel;

    await connection.connectTo(at('quire-a.example'));

    expect(identical(connection.channel, first), isTrue);
    expect(opened, hasLength(1));
  });

  test('closes nothing it never opened', () async {
    final connection = NodeConnection(at('quire-a.example'), open: open);

    await connection.connectTo(at('quire-b.example'));
    await connection.shutdown();

    expect(opened, isEmpty);
  });

  test('refuses a node with no address this lane can dial', () {
    // A node whose document published no `grpc` authority is one this device
    // can record and cannot dial, and the failure is named rather than a
    // connection to somewhere nobody chose.
    final connection = NodeConnection(NodeEndpoint());

    expect(
      () => connection.channel,
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', ErrorKind.failedPrecondition)
            .having((e) => e.code, 'code', codeUndialable),
      ),
    );
  });

  group('NodeEndpoint.of', () {
    test('fills both lanes from one document', () {
      final endpoint = NodeEndpoint.of(
        const ServerDescriptor(
          domain: 'quire-a.example',
          baseUrl: 'https://quire-a.example',
          grpcAuthority: 'quire-a.example:9090',
        ),
      );

      // The native lane dials what the node published for the purpose; a
      // browser dials the origin it answers HTTP on, because the `grpc`
      // authority is what a peer dials for replication and a page is not one.
      expect(endpoint.host, 'quire-a.example');
      expect(endpoint.port, 9090);
      expect(endpoint.gateway, Uri.parse('https://quire-a.example'));
    });

    test('leaves the native lane empty for a node that published no grpc', () {
      final endpoint = NodeEndpoint.of(
        const ServerDescriptor(
          domain: 'quire-a.example',
          baseUrl: 'https://quire-a.example',
        ),
      );

      expect(endpoint.authority, isNull);
      expect(endpoint.gateway, isNotNull);
    });
  });
}

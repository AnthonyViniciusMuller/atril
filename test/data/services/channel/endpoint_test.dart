import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeEndpoint', () {
    test('splits the authority a node publishes', () {
      final endpoint = NodeEndpoint(authority: '127.0.0.1:19090');

      expect(endpoint.host, '127.0.0.1');
      expect(endpoint.port, 19090);
    });

    test('drops the brackets an ipv6 literal is written in', () {
      final endpoint = NodeEndpoint(authority: '[::1]:9090');

      expect(endpoint.host, '::1');
      expect(endpoint.port, 9090);
    });

    test('refuses an authority that names no port', () {
      // The contract publishes host:port, so a bare host is a node saying
      // something this client cannot act on. Defaulting to 443 would be
      // dialling somewhere nobody named.
      expect(
        () => NodeEndpoint(authority: 'quire.example'),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', ErrorKind.invalidArgument)
              .having((e) => e.code, 'code', codeUnusableAuthority)
              .having((e) => e.fields.single.name, 'field', 'grpc'),
        ),
      );
    });

    test('refuses a URL where an authority belongs', () {
      expect(
        () => NodeEndpoint(authority: 'https://quire.example:443'),
        throwsA(isA<AppException>()),
      );
    });

    test('refuses an unbracketed ipv6 literal, which names no port either', () {
      expect(
        () => NodeEndpoint(authority: '::1:9090'),
        throwsA(isA<AppException>()),
      );
    });

    test('refuses a port no socket can be opened on', () {
      expect(
        () => NodeEndpoint(authority: 'quire.example:0'),
        throwsA(isA<AppException>()),
      );
      expect(
        () => NodeEndpoint(authority: 'quire.example:70000'),
        throwsA(isA<AppException>()),
      );
      expect(
        () => NodeEndpoint(authority: 'quire.example:https'),
        throwsA(isA<AppException>()),
      );
    });

    test('holds no dialable address when the node published none', () {
      const gateway = 'http://127.0.0.1:18090';
      final endpoint = NodeEndpoint(gateway: Uri.parse(gateway));

      expect(endpoint.host, isNull);
      expect(endpoint.port, isNull);
      expect(endpoint.gateway.toString(), gateway);
    });

    test('keeps the certificate out of what it prints', () {
      final endpoint = NodeEndpoint(
        authority: '127.0.0.1:19090',
        certificateAuthority: 'a secret'.codeUnits,
      );

      expect(endpoint.toString(), isNot(contains('secret')));
      expect(endpoint.toString(), contains('pinned'));
    });
  });

  group('openChannel', () {
    test('dials the authority on the lane this build has', () async {
      final channel = openChannel(NodeEndpoint(authority: '127.0.0.1:19090'));

      // Nothing is dialled until a call is made, so this asserts the channel
      // was built rather than that a node is up.
      await channel.shutdown();
    });

    test('refuses a node with no address for this lane', () {
      expect(
        () => openChannel(NodeEndpoint()),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', ErrorKind.failedPrecondition)
              .having((e) => e.code, 'code', codeUndialable),
        ),
      );
    });
  });
}

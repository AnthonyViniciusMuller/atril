/// What each flavour is pointed at.
///
/// The production case is the one worth a test: it knows no node, and the
/// claim being made is that dialling nothing *fails by name* rather than
/// connecting somewhere nobody chose. A regression there would be an install
/// that silently talks to whichever host a default guessed at.
library;

import 'package:atril/config/environment.dart';
import 'package:atril/data/services/channel/channel.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('a production build', () {
    final environment = Environment.production();

    test('knows no node and offers none', () {
      expect(environment.federation, isEmpty);
      expect(environment.isDevelopment, isFalse);
      expect(environment.initialEndpoint.authority, isNull);
      expect(environment.initialEndpoint.gateway, isNull);
    });

    test('refuses to dial by name rather than guessing an address', () {
      expect(
        () => openChannel(environment.initialEndpoint),
        throwsA(
          isA<AppException>()
              .having(
                (AppException it) => it.kind,
                'kind',
                ErrorKind.failedPrecondition,
              )
              .having((AppException it) => it.code, 'code', codeUndialable),
        ),
      );
    });
  });

  group('a development build', () {
    test('knows both nodes of the local federation', () {
      final environment = Environment.development();

      expect(environment.isDevelopment, isTrue);
      expect(
        environment.federation.map((KnownNode node) => node.domain),
        <String>['quire-a.example', 'quire-b.example'],
      );

      // The three ports of `make dev-up`: the native lane, the browser's
      // gateway, and the discovery documents. They are three addresses and
      // not one derived from another.
      final first = environment.federation.first;

      expect(first.endpoint.authority, '127.0.0.1:19090');
      expect(first.endpoint.gateway, Uri.parse('http://127.0.0.1:18090'));
      expect(first.discovery, Uri.parse('http://127.0.0.1:18080'));

      expect(environment.initialEndpoint, same(first.endpoint));
    });

    test('carries the certificate authority into every node', () {
      const pem = <int>[1, 2, 3];
      final environment = Environment.development(certificateAuthority: pem);

      for (final node in environment.federation) {
        expect(node.endpoint.certificateAuthority, pem);
      }
    });

    test('dials the first node without a certificate too', () {
      // A development build against a node the platform already trusts is a
      // legitimate configuration, and it is what a web build always is.
      expect(
        () => openChannel(Environment.development().initialEndpoint),
        returnsNormally,
      );
    });
  });

  group('where a build dials a node', () {
    const ServerDescriptor published = ServerDescriptor(
      domain: 'quire-a.example',
      // What `make dev-up` actually publishes, and neither half of it resolves
      // on a host running this app.
      baseUrl: 'http://quire-a.example',
      grpcAuthority: 'quire-a.example:9090',
    );

    test('is the flavour\'s address for a node of the local federation', () {
      final endpoint = Environment.development().endpointFor(published);

      expect(endpoint.authority, '127.0.0.1:19090');
      expect(endpoint.gateway, Uri.parse('http://127.0.0.1:18090'));
    });

    test('is what the node published, for every other node', () {
      final endpoint = Environment.production().endpointFor(published);

      expect(endpoint.authority, 'quire-a.example:9090');
      expect(endpoint.gateway, Uri.parse('http://quire-a.example'));
    });

    test('knows the local federation by domain and nothing else by it', () {
      final development = Environment.development();

      expect(development.knownNode('Quire-B.Example')?.label, 'Node B');
      expect(development.knownNode('quire.example'), isNull);
      expect(Environment.production().knownNode('quire-a.example'), isNull);
    });
  });

  group('the log level', () {
    test('is louder in development than in production', () {
      // Skipped where the build was told what to log: the point is the
      // flavour's default, and a flag overriding both is the behaviour one
      // line down in `Environment`.
      if (configuredLogLevel.isNotEmpty) {
        return;
      }

      expect(Environment.production().logLevel, Level.INFO);
      expect(Environment.development().logLevel, Level.FINE);
    });
  });
}

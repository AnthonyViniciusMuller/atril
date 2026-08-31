/// The `.well-known` lookup, against a node that answers and against the six
/// ways one does not.
library;

import 'dart:convert';

import 'package:atril/data/services/discovery/well_known.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The document a Quire node publishes for a reader's application.
String clientDocument({
  String baseUrl = 'https://quire-a.example',
  String? grpc = 'quire-a.example:9090',
}) => jsonEncode(<String, Object?>{
  clientDocumentKey: <String, Object?>{'base_url': baseUrl, 'grpc': ?grpc},
});

/// A client answering every request with [body] under [status].
MockClient answering(
  String body, {
  int status = 200,
  Map<String, String> headers = const <String, String>{},
  void Function(http.Request request)? onRequest,
}) => MockClient((http.Request request) async {
  onRequest?.call(request);

  return http.Response(body, status, headers: headers, request: request);
});

void main() {
  group('discover', () {
    test('reads the client document over https', () async {
      final seen = <Uri>[];
      final discovery = WellKnownDiscovery(
        client: answering(
          clientDocument(),
          onRequest: (http.Request request) => seen.add(request.url),
        ),
      );

      final descriptor = await discovery.discover('quire-a.example');

      expect(
        seen.single,
        Uri.parse('https://quire-a.example/.well-known/quire/client'),
      );
      expect(descriptor.domain, 'quire-a.example');
      expect(descriptor.baseUrl, 'https://quire-a.example');
      expect(descriptor.grpcAuthority, 'quire-a.example:9090');
    });

    test('reads the client document and never the server one', () async {
      final seen = <Uri>[];
      final discovery = WellKnownDiscovery(
        client: answering(
          clientDocument(),
          onRequest: (http.Request request) => seen.add(request.url),
        ),
      );

      await discovery.discover('quire-a.example');

      expect(seen.single.path, '/.well-known/quire/client');
      expect(seen.single.path, isNot(contains('server')));
    });

    test('sends no header of any kind', () async {
      // The gateway admits GET on /.well-known/* and not OPTIONS, so a header
      // a browser would preflight is refused 403 — which reads as an
      // authorization failure and is really a request shape.
      final headers = <Map<String, String>>[];
      final discovery = WellKnownDiscovery(
        client: answering(
          clientDocument(),
          onRequest: (http.Request request) => headers.add(request.headers),
        ),
      );

      await discovery.discover('quire-a.example');

      expect(headers.single, isEmpty);
    });

    test('folds the case and the space of what the reader typed', () async {
      final seen = <Uri>[];
      final discovery = WellKnownDiscovery(
        client: answering(
          clientDocument(),
          onRequest: (http.Request request) => seen.add(request.url),
        ),
      );

      final descriptor = await discovery.discover('  Quire-A.Example  ');

      expect(seen.single.host, 'quire-a.example');
      expect(descriptor.domain, 'quire-a.example');
    });

    test('reports a node that publishes no grpc authority as absent', () async {
      final discovery = WellKnownDiscovery(
        client: answering(clientDocument(grpc: null)),
      );

      final descriptor = await discovery.discover('quire-a.example');

      expect(descriptor.grpcAuthority, isNull);
    });

    test(
      'carries neither the keys nor the pin, which are the peer\'s',
      () async {
        // internal/shared/wellknown puts jwks_uri and cert_fingerprint in the
        // server document alone. A descriptor from here has neither, and it is
        // not a lookup that half-failed.
        final discovery = WellKnownDiscovery(
          client: answering(clientDocument()),
        );

        final descriptor = await discovery.discover('quire-a.example');

        expect(descriptor.jwksUri, isNull);
        expect(descriptor.certificateFingerprint, isNull);
      },
    );

    test(
      'refuses a domain that is not a host before anything travels',
      () async {
        var called = false;
        final discovery = WellKnownDiscovery(
          client: MockClient((http.Request request) async {
            called = true;

            return http.Response('', 200);
          }),
        );

        await expectLater(
          discovery.discover('https://quire-a.example'),
          throwsA(
            isA<AppException>()
                .having((e) => e.kind, 'kind', ErrorKind.invalidArgument)
                .having((e) => e.fields.single.name, 'field', 'domain'),
          ),
        );
        expect(called, isFalse);
      },
    );
  });

  group('discoverAt', () {
    test('reads the document at an address the build already knows', () async {
      final seen = <Uri>[];
      final discovery = WellKnownDiscovery(
        client: answering(
          clientDocument(baseUrl: 'http://quire-a.example'),
          onRequest: (http.Request request) => seen.add(request.url),
        ),
      );

      final descriptor = await discovery.discoverAt(
        Uri.parse('http://127.0.0.1:18080'),
        domain: 'quire-a.example',
      );

      expect(
        seen.single,
        Uri.parse('http://127.0.0.1:18080/.well-known/quire/client'),
      );
      // The domain is the one asked for and never the one in the body, so that
      // a node cannot answer for an authority it was not addressed at.
      expect(descriptor.domain, 'quire-a.example');
    });
  });

  group('what a lookup refuses', () {
    test('a host that is not a node', () async {
      final discovery = WellKnownDiscovery(
        client: answering('not found', status: 404),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', codeNotAQuireServer)
              .having((e) => e.kind, 'kind', ErrorKind.failedPrecondition),
        ),
      );
    });

    test('a body that is not json', () async {
      final discovery = WellKnownDiscovery(client: answering('<html>'));

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeNotAQuireServer,
          ),
        ),
      );
    });

    test('a document with no quire.client object', () async {
      final discovery = WellKnownDiscovery(
        client: answering(jsonEncode(<String, Object?>{'quire.server': 1})),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeNotAQuireServer,
          ),
        ),
      );
    });

    test('a document naming no base url', () async {
      final discovery = WellKnownDiscovery(
        client: answering(
          jsonEncode(<String, Object?>{
            clientDocumentKey: <String, Object?>{'grpc': 'a:9090'},
          }),
        ),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeNotAQuireServer,
          ),
        ),
      );
    });

    test('a body that does not stop', () async {
      final discovery = WellKnownDiscovery(
        client: MockClient.streaming((
          http.BaseRequest request,
          http.ByteStream body,
        ) async {
          final endless = Stream<List<int>>.periodic(
            Duration.zero,
            (_) => List<int>.filled(1 << 16, 0x20),
          );

          return http.StreamedResponse(endless, 200);
        }),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeNotAQuireServer,
          ),
        ),
      );
    });

    test('a domain that does not answer', () async {
      final discovery = WellKnownDiscovery(
        client: MockClient((http.Request request) async {
          throw http.ClientException('no route to host', request.url);
        }),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', codeDiscoveryUnreachable)
              .having((e) => e.kind, 'kind', ErrorKind.unavailable)
              .having((e) => e.isRetryable, 'retryable', isTrue),
        ),
      );
    });
  });

  group('redirects', () {
    test('follows one that stays on https', () async {
      final seen = <Uri>[];
      final discovery = WellKnownDiscovery(
        client: MockClient((http.Request request) async {
          seen.add(request.url);

          if (request.url.host == 'example.com') {
            return http.Response(
              '',
              301,
              headers: <String, String>{
                'location': 'https://quire-a.example/.well-known/quire/client',
              },
            );
          }

          return http.Response(clientDocument(), 200);
        }),
      );

      final descriptor = await discovery.discover('example.com');

      expect(seen, hasLength(2));
      // The descriptor still names the domain that was asked for.
      expect(descriptor.domain, 'example.com');
    });

    test('refuses one that downgrades to plain http', () async {
      final discovery = WellKnownDiscovery(
        client: answering(
          '',
          status: 302,
          headers: <String, String>{'location': 'http://quire-a.example/x'},
        ),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', codeInsecureDiscovery)
              .having(
                (e) => e.fields.single.reason,
                'reason',
                contains('plain http'),
              ),
        ),
      );
    });

    test('refuses a chain longer than it will walk', () async {
      var hop = 0;
      final discovery = WellKnownDiscovery(
        client: MockClient((http.Request request) async {
          hop++;

          return http.Response(
            '',
            302,
            headers: <String, String>{'location': 'https://hop$hop.example/d'},
          );
        }),
      );

      await expectLater(
        discovery.discover('example.com'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            codeInsecureDiscovery,
          ),
        ),
      );
      expect(hop, maxRedirects + 1);
    });
  });

  group('serverDomainViolation', () {
    test('admits a host, with or without a port', () {
      expect(serverDomainViolation('quire-a.example'), isNull);
      expect(serverDomainViolation('quire-a.example:9090'), isNull);
      expect(serverDomainViolation('a'), isNull);
    });

    test('refuses what a lookup could not be addressed to', () {
      expect(serverDomainViolation(''), isNotNull);
      expect(serverDomainViolation('Quire-A.Example'), isNotNull);
      expect(serverDomainViolation('-quire.example'), isNotNull);
      expect(serverDomainViolation('quire.example-'), isNotNull);
      expect(serverDomainViolation('quire_a.example'), isNotNull);
      expect(serverDomainViolation('quire-a.example:'), isNotNull);
      expect(serverDomainViolation('quire-a.example:abc'), isNotNull);
      expect(serverDomainViolation('quire-a.example:123456'), isNotNull);
      expect(serverDomainViolation('a' * 256), isNotNull);
    });
  });
}

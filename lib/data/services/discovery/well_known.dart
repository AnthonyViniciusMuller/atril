/// The `.well-known` lookup: a domain a reader typed, and what the node
/// answering for it publishes to a reader's application.
///
/// It is the one call in this app that is not gRPC, and it is the only one a
/// device can make before it has a node — which is the whole of UC13 and RF14.
/// `FederationApi.discoverServer` asks a node this device is *already* signed
/// in at to resolve a domain; this is what a fresh install does instead, when
/// there is nobody to ask.
///
/// Three constraints shape every line of it, and each is a claim checked
/// against [`../quire`](../../../../../quire) rather than assumed.
///
/// **It reads `quire/client` and not `quire/server`.** They are two documents
/// and the difference is who is asking. A peer reads the server document and
/// learns the key to pin for node-to-node mTLS; a reader's application reads
/// the client one. Atril is the second, so what it gets back is `base_url` and
/// `grpc` and *nothing else* — `internal/shared/wellknown/wellknown.go` puts
/// `jwks_uri` and `cert_fingerprint` in the server document alone. A
/// descriptor from here therefore carries neither, and that is not a lookup
/// that half-failed: they are values this device has no use for and no
/// business reading.
///
/// **It sends no header of any kind.** Not `Accept`, not `X-Requested-With`,
/// nothing. The node answers both documents with `Access-Control-Allow-Origin:
/// *`, so they are readable cross-origin with no help from the gateway — but
/// the gateway's authorization policy admits `GET` on `/.well-known/*` and not
/// `OPTIONS`, so a request carrying a header a browser would preflight is
/// refused `403`, which reads as an authorization failure and is really a
/// request shape.
///
/// **A typed domain is looked up over HTTPS and is never downgraded.** The pin
/// a peer is checked against is a value read out of a document, so the
/// document is exactly as trustworthy as the channel it arrived on. A build
/// that already knows an address — the local federation of a debug build —
/// uses [discoverAt] instead, which is a deliberate address the configuration
/// named rather than a scheme this lookup gave up on.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';

final _log = loggerFor('data/discovery');

/// The operation a lookup reports under.
const String opWellKnown = 'federation/discovery: look up';

/// The path RFC 8615 puts the reader's document at, which is what makes the
/// lookup predictable from the domain alone.
const String clientDocumentPath = '/.well-known/quire/client';

/// The key the document is under, as Matrix keys its own so that a document
/// can gain a second service without any reader having to change.
const String clientDocumentKey = 'quire.client';

/// The stable code of a domain that answered with something that is not a
/// Quire discovery document — including a domain that answered `404`, which is
/// a host that is not a node.
const String codeNotAQuireServer = 'not_a_quire_server';

/// The stable code of a domain that did not answer at all.
const String codeDiscoveryUnreachable = 'discovery_unreachable';

/// The stable code of a lookup this device refused to make or to follow.
const String codeInsecureDiscovery = 'insecure_discovery';

/// How long a lookup is given before it is abandoned.
///
/// It is short because there is a reader waiting on it with a form in front of
/// them, and because the failure it produces is one they can act on: a domain
/// that has not answered in ten seconds is one they should check the spelling
/// of.
const Duration discoveryTimeout = Duration(seconds: 10);

/// How much of a body is read before the lookup gives up on it.
///
/// The document is two short strings. A megabyte is three orders of magnitude
/// more than one, and without a bound a host could answer with an endless body
/// and hold this device's memory for as long as it kept writing.
const int maxDocumentBytes = 1 << 20;

/// How far a lookup is followed.
///
/// Two is the redirect deployments actually use — an apex to a canonical host
/// — and a chain longer than that is either a loop or a lookup being walked
/// somewhere nobody addressed.
const int maxRedirects = 2;

/// The `.well-known` client.
///
/// It holds an [http.Client] rather than making one per call so that a test
/// can hand it `MockClient` and so that the five native targets keep one
/// connection pool across the two or three lookups an onboarding makes.
final class WellKnownDiscovery {
  /// The client, over [client] and bounded by [timeout].
  WellKnownDiscovery({http.Client? client, this.timeout = discoveryTimeout})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// How long a lookup is given.
  final Duration timeout;

  /// What the node answering for [typed] publishes for a reader's application.
  ///
  /// The lookup is `https://<domain>/.well-known/quire/client` and it is
  /// nothing else: a domain is what the reader typed, and this is the address
  /// RFC 8615 says the document is at.
  ///
  /// It is `async` and not a plain `Future`-returning method so that a domain
  /// refused here arrives at the caller the way a domain refused by the node
  /// does — as a failed future, never as a synchronous throw out of the call
  /// that built it.
  Future<ServerDescriptor> discover(String typed) async {
    final domain = canonicalServerDomain(typed);
    final violation = serverDomainViolation(domain);

    if (violation != null) {
      throw AppException(
        kind: ErrorKind.invalidArgument,
        message: 'the server domain "$domain" $violation',
        code: codeNotAQuireServer,
        op: opWellKnown,
      ).withField('domain', violation);
    }

    return await discoverAt(Uri.parse('https://$domain'), domain: domain);
  }

  /// The same document, at an [origin] this build already knows.
  ///
  /// It exists for the local federation, whose nodes publish a `base_url` and
  /// a `grpc` authority that resolve inside the compose network and nowhere
  /// else — `http://quire-a.example` is not an address a host can reach, and
  /// `http://127.0.0.1:18080` is. A production build never calls it: there is
  /// no address a reader could give that is not the domain itself.
  ///
  /// [domain] is what the descriptor reports and is not read from the body, so
  /// that a node cannot answer for an authority it was not addressed at.
  Future<ServerDescriptor> discoverAt(
    Uri origin, {
    required String domain,
  }) async {
    final document = await _fetch(origin.replace(path: clientDocumentPath));
    final endpoint = document[clientDocumentKey];

    if (endpoint is! Map<String, Object?>) {
      throw _notADocument('it published no "$clientDocumentKey" object');
    }

    final baseUrl = endpoint['base_url'];
    final grpc = endpoint['grpc'];

    if (baseUrl is! String || baseUrl.isEmpty) {
      throw _notADocument('its "$clientDocumentKey" names no base_url');
    }

    _log.fine('$domain answers at $baseUrl, grpc ${grpc ?? '-'}');

    // Three of the five fields a `ServerDescriptor` can carry are absent, and
    // permanently: the client document publishes neither the signing keys nor
    // the pin, because neither is a value a reader's application checks
    // anything against. A device that wanted them would be reading the
    // document written for a peer.
    return ServerDescriptor(
      domain: domain,
      baseUrl: baseUrl,
      grpcAuthority: grpc is String && grpc.isNotEmpty ? grpc : null,
    );
  }

  /// Releases the connection pool, where this object opened one.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// The document at [address], as the JSON object it has to be.
  Future<Map<String, Object?>> _fetch(Uri address) async {
    var target = address;

    for (var followed = 0; ; followed++) {
      final response = await _send(target);
      final location = _redirectOf(response);

      if (location == null) {
        return _decode(response, target);
      }

      if (followed == maxRedirects) {
        throw _refused('it was redirected more than $maxRedirects times');
      }

      final next = target.resolveUri(location);

      // A lookup that began over TLS and ends in the clear is a lookup whose
      // answer anybody on the path could have written, and the answer is what
      // this device is about to record a node's address from.
      if (address.scheme == 'https' && next.scheme != 'https') {
        throw _refused('it was redirected to plain http');
      }

      target = next;
    }
  }

  /// One request, carrying no header and no body.
  Future<http.StreamedResponse> _send(Uri address) async {
    // `followRedirects` is false so that the scheme of each hop is this
    // client's decision rather than the platform's. A browser refuses the
    // request outright instead of reporting the redirect — `BrowserClient`
    // asks `fetch` for `redirect: 'error'` — which is the same answer arriving
    // as a transport failure, and is the strictest of the two.
    final request = http.Request('GET', address)
      ..followRedirects = false
      ..persistentConnection = true;

    try {
      return await _client.send(request).timeout(timeout);
    } on TimeoutException catch (error) {
      throw AppException(
        kind: ErrorKind.deadlineExceeded,
        message: 'the lookup of $address was not answered in $timeout',
        code: codeDiscoveryUnreachable,
        op: opWellKnown,
        cause: error,
      );
    } on Exception catch (error) {
      throw AppException(
        kind: ErrorKind.unavailable,
        message: 'the lookup of $address was not answered',
        code: codeDiscoveryUnreachable,
        op: opWellKnown,
        cause: error,
      );
    }
  }

  /// Where [response] redirects to, or `null` when it does not redirect.
  Uri? _redirectOf(http.StreamedResponse response) {
    if (response.statusCode < 300 || response.statusCode > 399) {
      return null;
    }

    final location = response.headers['location'];

    if (location == null || location.isEmpty) {
      throw _notADocument(
        'it answered the lookup with status ${response.statusCode} '
        'and no location',
      );
    }

    final next = Uri.tryParse(location);

    if (next == null) {
      throw _notADocument('it redirected the lookup somewhere unaddressable');
    }

    return next;
  }

  /// The body of [response], bounded and parsed.
  Future<Map<String, Object?>> _decode(
    http.StreamedResponse response,
    Uri address,
  ) async {
    final body = await _read(response);

    if (response.statusCode != 200) {
      // Every status is one answer here. A 404 is a host that is not a node
      // and a 500 is a node that cannot say what it is; neither leaves this
      // call with a description, and telling the two apart would only invite a
      // caller to retry the one that will keep failing.
      throw _notADocument(
        'it answered the lookup with status ${response.statusCode}',
      );
    }

    final Object? document;

    try {
      document = jsonDecode(utf8.decode(body));
    } on FormatException {
      throw _notADocument(
        'it answered the lookup with something that is not json',
      );
    }

    if (document is! Map<String, Object?>) {
      throw _notADocument(
        'it answered the lookup with something that is not a json object',
      );
    }

    _log.finer('read ${body.length} bytes from $address');

    return document;
  }

  /// The body, refusing one that does not stop.
  Future<List<int>> _read(http.StreamedResponse response) async {
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);

      if (bytes.length > maxDocumentBytes) {
        throw _notADocument(
          'it answered the lookup with more than $maxDocumentBytes bytes',
        );
      }
    }

    return bytes;
  }

  AppException _notADocument(String reason) => AppException(
    kind: ErrorKind.failedPrecondition,
    message: 'that domain does not publish a usable quire discovery document',
    code: codeNotAQuireServer,
    op: opWellKnown,
  ).withField('domain', reason);

  AppException _refused(String reason) => AppException(
    kind: ErrorKind.failedPrecondition,
    message: 'this device will not follow that lookup',
    code: codeInsecureDiscovery,
    op: opWellKnown,
  ).withField('domain', reason);
}

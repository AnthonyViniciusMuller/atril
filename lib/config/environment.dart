/// The configuration surface of the app: one struct, compiled six times.
///
/// It is one struct for the reason Quire gives about `os.Getenv` on the other
/// side. A value read from the environment where it is *used* is a value that
/// cannot be set in a test, cannot be listed anywhere, and cannot be found by
/// anybody wondering what this build is pointed at. So the flags are read
/// here, at the edge, and everything below is handed the answer.
///
/// Two flavours and no third. The guide's sample has a staging one; this app
/// has exactly two nodes it ever points at — a production one and the local
/// federation `make dev-up` starts next door — and a third entry point would
/// be a third configuration nobody maintains.
///
/// The compile-time flags this app reads are named here and in
/// `main_development.dart`, and there are two of them: `ATRIL_LOG_LEVEL`, and
/// the development certificate authority the dev entry point is given. Nothing
/// below `main` reads either.
library;

import 'package:logging/logging.dart';

import '../data/services/channel/channel.dart';
import '../domain/models/server.dart';
import '../utils/logging.dart';

/// A node this build already knows how to reach.
///
/// It exists for one screen: phase 6's server selection, where the local
/// federation is reachable in one tap in a debug build. A production build
/// knows none, and the reader types a domain like everybody else.
final class KnownNode {
  /// The node named [label], answering for [domain].
  const KnownNode({
    required this.label,
    required this.domain,
    required this.discovery,
    required this.endpoint,
  });

  /// What the selection screen calls it.
  ///
  /// It is not localized, and that is not an oversight: it is the name of a
  /// development node, shown only in a debug build, and `Node A` is what the
  /// compose file next door calls it.
  final String label;

  /// The domain the node answers for, which is the half of a reader's
  /// `@local_name:server` identifier that says where they are.
  final String domain;

  /// Where its `/.well-known/quire/client` document is served from.
  ///
  /// Against `make dev-up` the discovery documents are on a different port
  /// from both gRPC lanes, so it is a third address and not derivable from
  /// either.
  final Uri discovery;

  /// How this build dials it, in the two forms the two lanes need.
  final NodeEndpoint endpoint;
}

/// What this build is pointed at.
final class Environment {
  const Environment._({
    required this.name,
    required this.logLevel,
    required this.initialEndpoint,
    required this.federation,
  });

  /// The configuration of a shipped build.
  ///
  /// It knows no node. That is correct and not a gap: a production install
  /// learns where to talk from the reader, who types a domain that phase 6
  /// resolves through `/.well-known/quire/client`. Until then
  /// [initialEndpoint] carries no address, and dialling it fails by the name
  /// `NodeEndpoint` gives that state rather than by connecting somewhere
  /// nobody named.
  factory Environment.production() => Environment._(
    name: 'production',
    logLevel: logLevelFrom(configuredLogLevel),
    initialEndpoint: NodeEndpoint(),
    federation: const <KnownNode>[],
  );

  /// The configuration of a build pointed at `make dev-up` next door.
  ///
  /// [certificateAuthority] is the PEM of the self-signed authority the local
  /// federation's certificates are issued under, which is what makes the
  /// native lane dialable against it. It is a parameter and not a constant
  /// read here because the certificates are *generated* on the other side —
  /// `make dev-certs` runs before every `make dev-up` and they are not
  /// committed — so a copy vendored into this repository would be stale by the
  /// next run. `main_development.dart` is where it comes in.
  factory Environment.development({List<int>? certificateAuthority}) {
    final nodes = <KnownNode>[
      KnownNode(
        label: 'Node A',
        domain: 'quire-a.example',
        discovery: Uri.parse('http://127.0.0.1:18080'),
        endpoint: NodeEndpoint(
          authority: '127.0.0.1:19090',
          gateway: Uri.parse('http://127.0.0.1:18090'),
          certificateAuthority: certificateAuthority,
        ),
      ),
      KnownNode(
        label: 'Node B',
        domain: 'quire-b.example',
        discovery: Uri.parse('http://127.0.0.1:28080'),
        endpoint: NodeEndpoint(
          authority: '127.0.0.1:29090',
          gateway: Uri.parse('http://127.0.0.1:28090'),
          certificateAuthority: certificateAuthority,
        ),
      ),
    ];

    return Environment._(
      name: 'development',
      logLevel: logLevelFrom(configuredLogLevel, fallback: Level.FINE),
      initialEndpoint: nodes.first.endpoint,
      federation: nodes,
    );
  }

  /// Which of the two this is, for the log and for a settings screen that
  /// should never claim to be the other.
  final String name;

  /// The level below which a record is dropped.
  ///
  /// The flavour decides the default — a shipped build says what happened and
  /// a development one says what it is doing — and `ATRIL_LOG_LEVEL`
  /// overrides both, in either direction.
  final Level logLevel;

  /// The node this build dials until the reader has chosen one.
  ///
  /// It is deliberately not `null` for a production build. An absent endpoint
  /// and an endpoint with no address are the same state, and `NodeEndpoint`
  /// already has a name and a message for the second — *this node published no
  /// address a native build can dial* — while a `null` would be a check every
  /// caller has to remember to write.
  final NodeEndpoint initialEndpoint;

  /// The nodes this build offers in one tap, which is empty in production.
  final List<KnownNode> federation;

  /// Whether this build knows about the local federation.
  bool get isDevelopment => federation.isNotEmpty;

  /// The node in [federation] answering for [domain], or `null`.
  KnownNode? knownNode(String domain) {
    final wanted = canonicalServerDomain(domain);

    for (final node in federation) {
      if (node.domain == wanted) {
        return node;
      }
    }

    return null;
  }

  /// Where this build dials the node [descriptor] describes.
  ///
  /// A node of the local federation is dialled at the address the flavour
  /// names, and not at the one it publishes about itself: `make dev-up` gives
  /// both nodes a `base_url` of `http://quire-a.example` and a `grpc` of
  /// `quire-a.example:9090`, which resolve inside the compose network and
  /// nowhere a host running this app can reach. Every other node is dialled at
  /// what its own document said.
  NodeEndpoint endpointFor(ServerDescriptor descriptor) =>
      knownNode(descriptor.domain)?.endpoint ?? NodeEndpoint.of(descriptor);

  @override
  String toString() =>
      'Environment($name, log: ${logLevel.name}, node: $initialEndpoint)';
}

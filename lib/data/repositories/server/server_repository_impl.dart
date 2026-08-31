/// [ServerRepository] over the `.well-known` lookup, the catalogue and the
/// connection.
library;

import '../../../domain/models/server.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';
import '../../services/api/errors.dart';
import '../../services/channel/channel.dart';
import '../../services/discovery/well_known.dart';
import '../../services/local/dao/identity_dao.dart';
import 'server_repository.dart';

final _log = loggerFor('data/servers');

/// The operation this repository reports its failures under.
const String opChooseServer = 'federation/servers: choose';

/// The operation adopting an origin reports under.
const String opAdoptOrigin = 'federation/servers: adopt origin';

/// The stable code of a reader hosted at a node this device has never reached.
const String codeUnknownOrigin = 'unknown_origin_server';

/// The node this device talks to, over what published it and what recorded it.
final class ServerRepositoryImpl implements ServerRepository {
  /// The repository over [discovery], [identity] and [connection].
  ///
  /// [endpointFor] is where a build dials the node a document describes, which
  /// is `Environment.endpointFor` at the composition root. It is a function and
  /// not the environment itself so that nothing under `data/` imports the
  /// configuration it is configured by.
  ServerRepositoryImpl({
    required this.discovery,
    required this.identity,
    required this.connection,
    required this.endpointFor,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The `.well-known` lookup, which is the only thing here that leaves the
  /// device.
  final WellKnownDiscovery discovery;

  /// The catalogue a discovered node is recorded in.
  final IdentityDao identity;

  /// What the choice points somewhere else.
  final NodeConnection connection;

  /// Where this build dials the node a document describes.
  final NodeEndpoint Function(ServerDescriptor descriptor) endpointFor;

  final DateTime Function() _clock;

  /// The node chosen in this run of the app.
  ///
  /// It is held here and not in the catalogue because a choice is not yet a
  /// fact about this device: what the catalogue records is that the node was
  /// discovered, and what makes one of its rows the reader's own is a login.
  /// A reader who picks a node and closes the app has not signed in anywhere.
  ServerDescriptor? _chosen;

  @override
  Future<Result<ServerDescriptor?>> current() async {
    final chosen = _chosen;

    if (chosen != null) {
      return Result<ServerDescriptor?>.ok(chosen);
    }

    try {
      final origin = await identity.originServer();

      return Result<ServerDescriptor?>.ok(
        origin == null
            ? null
            : ServerDescriptor(
                domain: origin.domain,
                baseUrl: origin.baseUrl,
                jwksUri: origin.jwksUri,
                certificateFingerprint: origin.certificateFingerprint,
                grpcAuthority: origin.grpcAuthority,
              ),
      );
    } on Exception catch (error) {
      return Result<ServerDescriptor?>.error(
        failureFrom(error, op: opChooseServer),
      );
    }
  }

  @override
  Future<Result<ServerDescriptor>> adoptOrigin(String domain) async {
    try {
      final wanted = canonicalServerDomain(domain);
      var row = await identity.server(wanted);

      if (row == null) {
        final chosen = _chosen;

        if (chosen == null) {
          throw AppException(
            kind: ErrorKind.failedPrecondition,
            message:
                'the reader is hosted at $wanted, which this device has '
                'not discovered and is not talking to',
            code: codeUnknownOrigin,
            op: opAdoptOrigin,
          );
        }

        // The same node under another name: it answered the calls this device
        // has been making, so what it publishes is what was already looked up.
        // Recording it is what gives the reader's row a node to reference.
        await identity.rememberDescriptor(
          ServerDescriptor(
            domain: wanted,
            baseUrl: chosen.baseUrl,
            grpcAuthority: chosen.grpcAuthority,
          ),
          at: _clock(),
        );

        row = await identity.server(wanted);
      }

      await identity.markOrigin(wanted);

      final descriptor = ServerDescriptor(
        domain: row!.domain,
        baseUrl: row.baseUrl,
        jwksUri: row.jwksUri,
        certificateFingerprint: row.certificateFingerprint,
        grpcAuthority: row.grpcAuthority,
      );

      _chosen = descriptor;
      _log.info('the reader is hosted at ${descriptor.domain}');

      return Result<ServerDescriptor>.ok(descriptor);
    } on Exception catch (error) {
      return Result<ServerDescriptor>.error(
        failureFrom(error, op: opAdoptOrigin),
      );
    }
  }

  @override
  Future<Result<ServerDescriptor>> choose(ServerChoice choice) async {
    try {
      final origin = choice.discovery;
      final descriptor = origin == null
          ? await discovery.discover(choice.domain)
          : await discovery.discoverAt(origin, domain: choice.domain);

      // The endpoint is resolved before anything is written, because a node
      // this build cannot dial is a choice worth refusing rather than
      // recording: the reader is in front of the screen and can pick another.
      final endpoint = endpointFor(descriptor);

      await identity.rememberDescriptor(descriptor, at: _clock());
      await connection.connectTo(endpoint);

      _chosen = descriptor;
      _log.info('this device now talks to ${descriptor.domain}');

      return Result<ServerDescriptor>.ok(descriptor);
    } on Exception catch (error) {
      return Result<ServerDescriptor>.error(
        failureFrom(error, op: opChooseServer),
      );
    }
  }
}

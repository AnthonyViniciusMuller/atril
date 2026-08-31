/// Which node this device talks to, and how the reader changes it.
///
/// This is the first repository in the app, and it is the one the guide's rule
/// about repositories reads oddly against: it does not answer from the local
/// replica, because *which node* is not a record that replicates. It is a
/// decision the reader takes once per install, recorded in the catalogue, and
/// it is what every other repository's answers are about.
///
/// It is UC13 with a screen on top. The domain a reader types is half of their
/// own identifier — `@local_name:server` — so this is not a preference and not
/// a setting: nothing else in onboarding can be asked until it is answered.
library;

import '../../../domain/models/server.dart';
import '../../../utils/result.dart';

/// A node the reader picked out.
final class ServerChoice {
  /// The node at [domain], whose document is at [discovery] when this build
  /// already knows where that is.
  const ServerChoice(this.domain, {this.discovery});

  /// The federation domain, as the reader typed it or as a build named it.
  final String domain;

  /// Where the `.well-known` document is served, for the local federation
  /// alone.
  ///
  /// `make dev-up` gives its nodes a `base_url` of `http://quire-a.example`,
  /// which resolves inside the compose network and nowhere a host running this
  /// app can reach, and serves the documents on `127.0.0.1:18080` instead. It
  /// is `null` for every node a reader ever types: RFC 8615 says where the
  /// document is, and a lookup that could be pointed elsewhere would be a
  /// lookup an attacker could point.
  final Uri? discovery;

  @override
  String toString() => 'ServerChoice($domain)';
}

/// The node this device talks to.
abstract interface class ServerRepository {
  /// The node this device is currently pointed at, or `null` on an install
  /// where nobody has chosen one yet.
  Future<Result<ServerDescriptor?>> current();

  /// Looks [choice] up, records what it published, and points this device at
  /// it.
  ///
  /// The three happen together on purpose. A node recorded and not dialled is a
  /// row nothing acts on, and a node dialled and not recorded is a choice the
  /// next launch has forgotten.
  Future<Result<ServerDescriptor>> choose(ServerChoice choice);

  /// Records that the reader who has just signed in is hosted at [domain], and
  /// makes that node the origin in this device's catalogue.
  ///
  /// It is a separate call from [choose] because the two answer different
  /// questions. A choice is where this device is *pointed*; an origin is where
  /// the reader is *named*, and only a login can establish that — which is also
  /// why the domain comes from the node's own reply rather than from what was
  /// typed. The two are the same domain in every ordinary case and are allowed
  /// to differ: a node identified by one host may be served from another, and
  /// an apex that redirects to a canonical name is the shape that produces it.
  Future<Result<ServerDescriptor>> adoptOrigin(String domain);
}

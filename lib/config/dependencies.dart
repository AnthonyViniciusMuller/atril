/// The provider graph, one function per environment.
///
/// This is the composition root and the only place in the app where a service
/// is constructed. Everything below reads what it needs out of the tree and
/// knows nothing about how it was built — which is what lets a test build the
/// same screen over an in-memory database and a fake node without a single
/// line of the screen changing.
///
/// **One function and not one per flavour.** The plan called for a `providers`
/// function per environment, and building it showed the split belongs one
/// layer up: the difference between a shipped build and one pointed at
/// `make dev-up` is entirely an [Environment], and two functions differing
/// only in which factory they call would be two things to keep in step for no
/// second behaviour. `Environment.production` and `Environment.development`
/// are the per-flavour functions; this is the graph they are both poured into.
/// A graph that branched on the flavour would be a second app that nobody runs
/// and nobody tests.
///
/// **Nearly everything is lazy, and one thing has to be.** `provider` builds a
/// provider on its first read, and the app depends on that in two places. A
/// device that has never been bound must reach onboarding without opening a
/// channel to a node it has not chosen; and the session holds the client that
/// refreshes it while that client makes its calls under the session, which is
/// a real cycle — closed here by resolving the refresher when it is first
/// needed rather than when the holder is built.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:grpc/service_api.dart' show ClientChannel;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/api/auth_api.dart';
import '../data/services/api/federation_api.dart';
import '../data/services/api/library_api.dart';
import '../data/services/api/reachability.dart';
import '../data/services/api/reading_api.dart';
import '../data/services/api/session.dart';
import '../data/services/api/sync_api.dart';
import '../data/services/channel/channel.dart';
import '../data/services/local/database.dart';
import '../data/services/storage/blob_storage.dart';
import '../data/services/storage/secure_session_store.dart';
import '../data/services/storage/session_store.dart';
import '../routing/router.dart';
import 'environment.dart';

/// The graph of [environment].
///
/// It is a `Future` because one thing in it cannot be opened synchronously:
/// the blob store asks the platform where the application's files go, and in a
/// browser it opens the origin-private file system. Doing it here rather than
/// behind a `FutureProvider` keeps every consumer from having to hold a
/// `Future<BlobStore>` for the sake of one await at start-up.
Future<List<SingleChildWidget>> providersFor(Environment environment) async {
  final blobs = await openBlobStore();

  return <SingleChildWidget>[
    Provider<Environment>.value(value: environment),
    Provider<BlobStore>.value(value: blobs),

    // The local replica. It is the app's own truth and outlives every screen,
    // so it is opened once and closed when the graph goes away.
    Provider<AtrilDatabase>(
      create: (_) => AtrilDatabase(),
      dispose: (_, AtrilDatabase database) => database.close(),
    ),

    Provider<SessionStore>(create: (_) => SecureSessionStore()),

    // One instance, shared by every client, because it is the sum of what
    // every call has learned and not a per-client opinion.
    Provider<NodeReachability>(
      create: (_) => NodeReachability.overPlatformRadio(),
      dispose: (_, NodeReachability reachability) => reachability.dispose(),
    ),

    // Where this build dials. Phase 6 is what replaces the environment's
    // answer with the node the reader chose, and it is a provider of its own
    // for exactly that reason: the clients below read an endpoint, not a
    // flavour.
    Provider<NodeEndpoint>.value(value: environment.initialEndpoint),

    // Lazy, and it matters. A device with no session never reads this, so a
    // fresh install reaches onboarding without dialling a node nobody has
    // chosen yet — which `NodeEndpoint` would refuse to do anyway, by name.
    Provider<ClientChannel>(
      create: (BuildContext context) =>
          openChannel(context.read<NodeEndpoint>()),
      dispose: (_, ClientChannel channel) => channel.shutdown(),
    ),

    // The cycle, closed. The holder is given a *function* that resolves the
    // client, and `provider` builds that client the first time the function is
    // called — which is the first refresh, long after both exist.
    Provider<SessionHolder>(
      create: (BuildContext context) => SessionHolder(
        store: context.read<SessionStore>(),
        refresher: () => context.read<AuthApi>(),
      ),
      dispose: (_, SessionHolder session) => session.dispose(),
    ),

    Provider<AuthApi>(
      create: (BuildContext context) => AuthApi(
        channel: context.read<ClientChannel>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<FederationApi>(
      create: (BuildContext context) => FederationApi(
        channel: context.read<ClientChannel>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<LibraryApi>(
      create: (BuildContext context) => LibraryApi(
        channel: context.read<ClientChannel>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<ReadingApi>(
      create: (BuildContext context) => ReadingApi(
        channel: context.read<ClientChannel>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<SyncApi>(
      create: (BuildContext context) => SyncApi(
        channel: context.read<ClientChannel>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),

    // The router is built once and not per frame: it holds the navigation
    // state of three branches, and rebuilding it would be the reader losing
    // where they were every time anything above it changed.
    Provider<GoRouter>(
      create: (BuildContext context) =>
          atrilRouter(session: context.read<SessionHolder>()),
      dispose: (_, GoRouter router) => router.dispose(),
    ),
  ];
}

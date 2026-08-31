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
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_impl.dart';
import '../data/repositories/server/server_repository.dart';
import '../data/repositories/server/server_repository_impl.dart';
import '../data/services/api/auth_api.dart';
import '../data/services/api/federation_api.dart';
import '../data/services/api/library_api.dart';
import '../data/services/api/reachability.dart';
import '../data/services/api/reading_api.dart';
import '../data/services/api/session.dart';
import '../data/services/api/sync_api.dart';
import '../data/services/channel/channel.dart';
import '../data/services/discovery/well_known.dart';
import '../data/services/local/database.dart';
import '../data/services/sync/seed.dart';
import '../domain/models/server.dart';
import '../data/services/storage/blob_storage.dart';
import '../data/services/storage/secure_session_store.dart';
import '../data/services/storage/session_store.dart';
import '../routing/router.dart';
import 'environment.dart';
import 'platform.dart';

/// The graph of [environment].
///
/// It is a `Future` because one thing in it cannot be opened synchronously:
/// the blob store asks the platform where the application's files go, and in a
/// browser it opens the origin-private file system. Doing it here rather than
/// behind a `FutureProvider` keeps every consumer from having to hold a
/// `Future<BlobStore>` for the sake of one await at start-up.
Future<List<SingleChildWidget>> providersFor(Environment environment) async {
  final blobs = await openBlobStore();

  // The replica is opened here rather than behind a lazy provider because one
  // question has to be answered before anything can dial: *which node is this
  // device signed in at*. A launch points the app at the reader's origin
  // server, and the only record of it is this database.
  final database = AtrilDatabase();
  final origin = await database.identityDao.originServer();

  return <SingleChildWidget>[
    Provider<Environment>.value(value: environment),
    Provider<BlobStore>.value(value: blobs),

    // The local replica. It is the app's own truth and outlives every screen,
    // so it is closed when the graph goes away.
    Provider<AtrilDatabase>.value(value: database),

    Provider<SessionStore>(create: (_) => SecureSessionStore()),

    // One instance, shared by every client, because it is the sum of what
    // every call has learned and not a per-client opinion.
    Provider<NodeReachability>(
      create: (_) => NodeReachability.overPlatformRadio(),
      dispose: (_, NodeReachability reachability) => reachability.dispose(),
    ),

    // Where this build talks, and the one thing that changes when the reader
    // picks a different node. It starts at the origin server the catalogue
    // records, or — on a device that has never signed in — at whatever the
    // flavour named, which for a shipped build is no node at all.
    //
    // Nothing is dialled by building it. A fresh install reaches onboarding
    // without opening a socket to a node nobody has chosen yet, because the
    // channel is opened by the first call and there is none until the reader
    // has chosen.
    Provider<NodeConnection>(
      create: (_) => NodeConnection(
        origin == null
            ? environment.initialEndpoint
            : environment.endpointFor(_descriptorOf(origin)),
      ),
      dispose: (_, NodeConnection connection) => connection.shutdown(),
    ),

    // The `.well-known` lookup, which is the one call a device makes before it
    // has a node — and therefore the one client here that does not read the
    // connection above.
    Provider<WellKnownDiscovery>(
      create: (_) => WellKnownDiscovery(),
      dispose: (_, WellKnownDiscovery discovery) => discovery.close(),
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
        connection: context.read<NodeConnection>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<FederationApi>(
      create: (BuildContext context) => FederationApi(
        connection: context.read<NodeConnection>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<LibraryApi>(
      create: (BuildContext context) => LibraryApi(
        connection: context.read<NodeConnection>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<ReadingApi>(
      create: (BuildContext context) => ReadingApi(
        connection: context.read<NodeConnection>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),
    Provider<SyncApi>(
      create: (BuildContext context) => SyncApi(
        connection: context.read<NodeConnection>(),
        session: context.read<SessionHolder>(),
        reachability: context.read<NodeReachability>(),
      ),
    ),

    // The repositories. They are what a view model is given, and the only
    // things above this file that a screen is allowed to reach for.
    Provider<ServerRepository>(
      create: (BuildContext context) => ServerRepositoryImpl(
        discovery: context.read<WellKnownDiscovery>(),
        identity: database.identityDao,
        connection: context.read<NodeConnection>(),
        // The one place the configuration reaches a repository, and it reaches
        // it as a function: the local federation is dialled at the address the
        // flavour names rather than the one it publishes, and nothing under
        // `data/` should have to import a flavour to know that.
        endpointFor: environment.endpointFor,
      ),
    ),

    Provider<AuthRepository>(
      create: (BuildContext context) => AuthRepositoryImpl(
        auth: context.read<AuthApi>(),
        identity: database.identityDao,
        servers: context.read<ServerRepository>(),
        session: context.read<SessionHolder>(),
        // Read at the edge, like every other thing this app learns from the
        // platform rather than from the reader.
        platform: devicePlatform,
        // The one place the read RPCs are called, and only for a device being
        // bound for the first time.
        seeder: ReplicaSeeder(
          database: database,
          library: context.read<LibraryApi>(),
          reading: context.read<ReadingApi>(),
        ),
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

/// The node a catalogue row describes, as discovery would have returned it.
///
/// It is private and it is used once, at the launch that has to know where to
/// dial. A row is what this device stored; a descriptor is what the rest of the
/// app speaks, and the four fields that differ between them are the four the
/// catalogue keeps and a lookup does not carry.
ServerDescriptor _descriptorOf(ServerRow row) => ServerDescriptor(
  domain: row.domain,
  baseUrl: row.baseUrl,
  jwksUri: row.jwksUri,
  certificateFingerprint: row.certificateFingerprint,
  grpcAuthority: row.grpcAuthority,
);

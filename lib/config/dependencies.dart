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
/// **Nearly everything is lazy, and one thing depends on it.** `provider`
/// builds a provider on its first read, and a device that has never been bound
/// is what needs that: onboarding must be reachable without opening a channel
/// to a node nobody has chosen.
///
/// **The session cycle is not closed by that laziness**, though it reads as if
/// it could be. The holder refreshes through the client whose own calls the
/// holder authorizes, so one of the two has to be reached later — but later is
/// only *when*, and `provider` resolves a type by walking *up* from the
/// provider asking. The client is declared under the holder, because it reads
/// the holder, so no context the holder can hold will ever find it. A variable
/// declared here closes the cycle instead, assigned where the client is built;
/// `test/architecture/provider_order_test.dart` is what keeps the next read
/// pointing upwards.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/account/account_repository.dart';
import '../data/repositories/account/account_repository_impl.dart';
import '../data/repositories/annotations/annotation_repository.dart';
import '../data/repositories/annotations/annotation_repository_impl.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_impl.dart';
import '../data/repositories/federation/federation_repository.dart';
import '../data/repositories/federation/federation_repository_impl.dart';
import '../data/repositories/library/library_repository.dart';
import '../data/repositories/library/library_repository_impl.dart';
import '../data/repositories/reading/reading_repository.dart';
import '../data/repositories/reading/reading_repository_impl.dart';
import '../data/repositories/server/server_repository.dart';
import '../data/repositories/server/server_repository_impl.dart';
import '../data/repositories/sync/sync_repository.dart';
import '../data/repositories/sync/sync_repository_impl.dart';
import '../data/services/api/auth_api.dart';
import '../data/services/api/federation_api.dart';
import '../data/services/api/library_api.dart';
import '../data/services/api/reachability.dart';
import '../data/services/api/reading_api.dart';
import '../data/services/api/session.dart';
import '../data/services/api/sync_api.dart';
import '../data/services/channel/channel.dart';
import '../data/services/content/content_downloader.dart';
import '../data/services/content/content_uploader.dart';
import '../data/services/content/upload_queue.dart';
import '../data/services/discovery/well_known.dart';
import '../data/services/epub/epub_host.dart';
import '../data/services/epub/host/host_factory.dart';
import '../data/services/files/file_source.dart';
import '../data/services/files/system_file_picker.dart';
import '../data/services/files/system_file_saver.dart';
import '../data/model/row_mappers.dart';
import '../data/services/local/database.dart';
import '../data/services/local/hybrid_clock_store.dart';
import '../data/services/sync/author.dart';
import '../data/services/sync/live_channel.dart';
import '../data/services/sync/pull.dart';
import '../data/services/sync/push.dart';
import '../data/services/sync/reconciler.dart';
import '../data/services/sync/scheduler.dart';
import '../data/services/sync/erase.dart';
import '../data/services/sync/seed.dart';
import '../data/services/sync/stream.dart';
import '../data/services/sync/watch.dart';
import '../domain/crdt/hybrid_clock.dart';
import '../data/services/appearance/system_seed.dart';
import '../data/services/storage/appearance_store.dart';
import '../data/services/storage/blob_storage.dart';
import '../data/services/storage/reader_settings_store.dart';
import '../data/services/storage/secure_session_store.dart';
import '../data/services/storage/session_store.dart';
import '../routing/router.dart';
import '../ui/core/themes/appearance_view_model.dart';
import '../utils/logging.dart';
import 'environment.dart';
import 'platform.dart';

final _log = loggerFor('config');

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

  // The device's hybrid clock, resumed from the floor it was left at. It is
  // read here for the same reason the origin server is — it is one row, and
  // the alternative is every stamp awaiting a future — and it is *one*
  // instance deliberately: the reconciler folds every instant this device
  // observes into it and the author stamps from it, and two clocks would be
  // two devices as far as C01's argument is concerned.
  final clock = await HybridClock.restore(
    store: LocalHybridClockStore(database.identityDao),
    onStoreError: (Object error, StackTrace stackTrace) =>
        _log.warning('the clock floor could not be written', error, stackTrace),
  );
  final reconciler = Reconciler(database, clock);

  // The client half of the session cycle, filled when the provider below
  // builds it. It is a variable and not a lookup because `provider` resolves
  // *upwards*: `AuthApi` is declared under `SessionHolder` — which is what
  // lets it read the holder — so the holder cannot reach it through a context
  // of its own, and the two comments at the providers say the rest.
  late final AuthApi authApi;

  return <SingleChildWidget>[
    Provider<Environment>.value(value: environment),
    Provider<BlobStore>.value(value: blobs),

    // The local replica. It is the app's own truth and outlives every screen,
    // so it is closed when the graph goes away.
    Provider<AtrilDatabase>.value(value: database),

    Provider<SessionStore>(create: (_) => SecureSessionStore()),

    // Where every change to a replicable record goes. Nothing above this line
    // calls the node's write RPCs — C21 is why, and a test walks `lib/` to keep
    // it that way — so a screen that saves anything reaches the author, the
    // author stamps it and the reconciler applies it, in that order and in no
    // other.
    Provider<HybridClock>.value(value: clock),
    Provider<Reconciler>.value(value: reconciler),
    Provider<OperationAuthor>(
      create: (_) => OperationAuthor(
        database: database,
        clock: clock,
        reconciler: reconciler,
      ),
    ),

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
            : environment.endpointFor(descriptorOfRow(origin)),
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
    // client, so that the client is reached when a refresh needs it rather
    // than when the holder is built.
    //
    // The function reads a variable and not the tree. `context.read` walks
    // *up* from the provider it is given, and `AuthApi` is below this one —
    // it has to be, because it reads the holder — so a lookup from here
    // searches the half of the graph the client is not in. It does not fail
    // where it is written: it fails at the first refresh, as an `UNAVAILABLE`
    // on whichever call met a stale token, which is every call the app makes.
    Provider<SessionHolder>(
      create: (BuildContext context) => SessionHolder(
        store: context.read<SessionStore>(),
        refresher: () => authApi,
      ),
      dispose: (_, SessionHolder session) => session.dispose(),
    ),

    // Eagerly, because this is the assignment the holder above is waiting on
    // and the call that needs it is not necessarily one of this client's: any
    // of the five meets the stale token first, and `SyncScheduler` — also
    // eager, and further down — starts making them before a screen is
    // touched. Building it dials nothing; the channel is opened by the first
    // call.
    Provider<AuthApi>(
      lazy: false,
      create: (BuildContext context) => authApi = AuthApi(
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

    // The reader's account and the devices that may write as them. It answers
    // from the node for the reason the federation does: none of it replicates,
    // and none of it can be changed while the node cannot be reached.
    Provider<AccountRepository>(
      create: (BuildContext context) => AccountRepositoryImpl(
        auth: context.read<AuthApi>(),
        identity: database.identityDao,
        // What a password change clears: the node ends every session of every
        // device, which its own use case says and the contract does not.
        session: context.read<SessionHolder>(),
      ),
    ),

    // The reader's federation, and the one repository here that answers from
    // the node rather than from the replica. What it holds is not a record
    // that replicates: it is what the node knows and enforces, and there is
    // nothing a reader can do about any of it while the node is unreachable.
    Provider<FederationRepository>(
      create: (BuildContext context) => FederationRepositoryImpl(
        federation: context.read<FederationApi>(),
        identity: database.identityDao,
        // The five below are what UC16 needs and the catalogue does not. A
        // migration points this device at another node, adopts an account
        // there and drops one cursor — and deliberately touches neither the
        // outbox nor the causal state, which are what the devices then push.
        auth: context.read<AuthApi>(),
        records: database.recordsDao,
        sync: database.syncDao,
        servers: context.read<ServerRepository>(),
        session: context.read<SessionHolder>(),
      ),
    ),

    // The reader's collection, read out of the replica and never off a node.
    // It is what makes UC01 answerable on a train: the seed of a freshly bound
    // device is the one place the read RPCs are called, and after it this is
    // the truth.
    // What the node is owed in bytes. It is separate from the operation log
    // and it has to be: the record travels when the log is pushed, and the
    // file waits for that push — C16 refuses an upload for a digest no work of
    // the reader's names, and this app never calls `CreateEbook`.
    Provider<ContentUploader>(
      create: (BuildContext context) =>
          ContentUploader(api: context.read<LibraryApi>(), blobs: blobs),
    ),
    Provider<ContentDownloader>(
      create: (BuildContext context) =>
          ContentDownloader(api: context.read<LibraryApi>(), blobs: blobs),
    ),
    Provider<UploadQueue>(
      create: (BuildContext context) => UploadQueue(
        database: database,
        uploader: context.read<ContentUploader>(),
      ),
    ),

    // How this device talks to its node, and when.
    //
    // The *what* is three services that know nothing about each other's
    // timing; the *when* is one loop above them. The push and the pull are
    // built here rather than inside the channels because the web's channel is
    // both of them plus a watch, and the native one is neither.
    Provider<OperationPusher>(
      create: (BuildContext context) =>
          OperationPusher(database: database, api: context.read<SyncApi>()),
    ),
    Provider<OperationPuller>(
      create: (BuildContext context) => OperationPuller(
        database: database,
        api: context.read<SyncApi>(),
        reconciler: reconciler,
      ),
    ),

    // The live channel, and the one place in this app where the platform
    // decides which of two implementations runs. It is `kIsWeb` and not a
    // conditional export because both sides compile everywhere: `Sync` is a
    // bidirectional call and gRPC-Web carries none, so what fails is the call
    // and not the build, and a question about the platform is answered where
    // the graph is composed — as the reader's host and the file saver are.
    Provider<SyncChannel>(
      create: (BuildContext context) => devicePlatform == 'web'
          ? WatchChannel(
              database: database,
              api: context.read<SyncApi>(),
              puller: context.read<OperationPuller>(),
              pusher: context.read<OperationPusher>(),
            )
          : SyncStream(
              database: database,
              api: context.read<SyncApi>(),
              reconciler: reconciler,
            ),
      dispose: (_, SyncChannel channel) => channel.close(),
    ),

    // The loop. It is built eagerly and not on its first read, because the
    // thing that would first read it is a screen — and a device that opened on
    // the reader's library and synchronized only once they wandered into the
    // settings would be a device whose guarantee depended on curiosity.
    Provider<SyncScheduler>(
      lazy: false,
      create: (BuildContext context) {
        final scheduler = SyncScheduler(
          database: database,
          channel: context.read<SyncChannel>(),
          session: context.read<SessionHolder>(),
          reachability: context.read<NodeReachability>(),
          uploads: context.read<UploadQueue>(),
        );

        unawaited(scheduler.start());

        return scheduler;
      },
      dispose: (_, SyncScheduler scheduler) => scheduler.dispose(),
    ),

    // What the shell's badge and the sync screen read. It joins the loop's own
    // state to the two durable facts a reader's question is actually about:
    // what this device owes, and when it last reached its node.
    Provider<SyncRepository>(
      create: (BuildContext context) => SyncRepositoryImpl(
        sync: database.syncDao,
        identity: database.identityDao,
        scheduler: context.read<SyncScheduler>(),
      ),
    ),

    Provider<LibraryRepository>(
      create: (BuildContext context) {
        final library = LibraryRepositoryImpl(
          library: database.libraryDao,
          author: context.read<OperationAuthor>(),
          blobs: blobs,
          uploads: context.read<UploadQueue>(),
          downloads: context.read<ContentDownloader>(),
          transfers: database.transfersDao,
          // Read at the edge, like every other thing this app learns from the
          // platform rather than from the reader — and it is a *default* and
          // not a rule: a native install keeps every book and offers to
          // release one, a browser keeps nothing until it is asked, and the
          // question the reader answers is the same on both.
          keepsByDefault: devicePlatform != 'web',
          budget: readStorageBudget,
        );

        // The second of the two moments the bytes of a deleted work are
        // reclaimed. The first is the deletion itself, which covers a work
        // this reader deleted here; this one covers the tombstone that
        // arrived from another device, which the sync loop applies and
        // deliberately does not act on — a reconciler that deleted a reader's
        // files would be the synchronization path removing something, and the
        // whole design keeps that one gesture in the repository.
        //
        // It is not awaited: the library screen must not wait on a directory
        // listing to render, and a pass that does not finish is one the next
        // launch or the next deletion repeats.
        unawaited(library.reclaimBytes());

        return library;
      },
    ),

    Provider<ReadingRepository>(
      create: (BuildContext context) => ReadingRepositoryImpl(
        library: database.libraryDao,
        places: database.readingDao,
        // Handed in rather than reached through the library DAO's own
        // database: which device this is is a question about identity, and a
        // repository that walked back through one accessor to borrow another
        // had a dependency nothing in its signature declared.
        identity: database.identityDao,
        blobs: blobs,
        author: context.read<OperationAuthor>(),
      ),
    ),

    // What the reader wrote down. It is a third repository beside the two
    // above and not a corner of either, because a mark outlives the session
    // that made it: it is read on a screen that is not the book's, exported on
    // its own, and — like every other replicable record — authored here and
    // pushed rather than sent through `CreateAnnotation`.
    Provider<AnnotationRepository>(
      create: (BuildContext context) => AnnotationRepositoryImpl(
        marks: database.annotationsDao,
        library: database.libraryDao,
        author: context.read<OperationAuthor>(),
      ),
    ),

    // What gives the engine a DOM on this platform. It is a *factory* and not a
    // host, because a host owns a webview and a book: one per reader screen,
    // disposed with it. Which factory is decided by `host/host_factory.dart`,
    // which is a conditional export on the web and a `defaultTargetPlatform`
    // question between the two native hosts.
    Provider<EpubHostFactory>(create: (_) => epubHostFactory()),

    // How the reader likes a page, kept beside the window's size and for the
    // same reason: it never replicates, it means nothing on another device, and
    // the contract has no field for it.
    Provider<ReaderSettingsStore>(
      create: (_) => PreferencesReaderSettingsStore(),
    ),

    // How the reader likes the application, and the colour the platform draws
    // itself with. The store is beside the reader's own for the same reason;
    // the seed is a platform question, which is why it is a port here and not
    // a plugin call in a widget — a widget test has no channel to answer it.
    Provider<AppearanceStore>(create: (_) => PreferencesAppearanceStore()),
    Provider<SystemSeed>(create: (_) => const PlatformSystemSeed()),

    // The one view model in the graph, and the one thing here a widget could
    // not build for itself: it is read above `MaterialApp`, to choose the
    // theme, and read again inside the settings screen, to change it. A screen
    // that built its own would be a switch that moves and changes nothing.
    ChangeNotifierProvider<AppearanceViewModel>(
      create: (BuildContext context) => AppearanceViewModel(
        store: context.read<AppearanceStore>(),
        system: context.read<SystemSeed>(),
      ),
    ),

    // The platform's own file dialog, behind a port. It is one implementation
    // and not six: `file_selector` is itself the split, and what this app adds
    // is the type group — which is spelled once, out of the formats UC02
    // admits, rather than in the screen that opens it.
    Provider<FilePicker>(create: (_) => const SystemFilePicker()),

    // Where a file this app produced goes. It is *two* implementations behind
    // one port and not one, because the platforms do not agree on what saving
    // a file is: the three desktops and the browser have a save dialog, and on
    // Android and iOS saving is the share sheet — which is where *Save to
    // Files* lives. The choice is made on `defaultTargetPlatform`, as the
    // reader's host split is, because both branches compile everywhere.
    Provider<FileSaver>(create: (_) => systemFileSaver()),

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
        // Its counterpart, for the case the replica surviving a logout does
        // not cover: a device somebody else signs in on holds a library that
        // is not theirs to be shown.
        eraser: ReplicaEraser(database: database, blobs: blobs),
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

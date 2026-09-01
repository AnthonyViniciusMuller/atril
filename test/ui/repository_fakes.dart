/// The repositories the screens read, faked, and the providers that hand them
/// over.
///
/// Every screen in this app reads its repositories out of the tree, so every
/// widget test that so much as *reaches* one needs them — the router's guard
/// and the adaptive scaffold's taps included, neither of which asserts anything
/// about a repository. One file, so that a repository gaining a method is one
/// place to add it rather than five.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:atril/config/environment.dart';
import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/sync/sync_repository.dart';
import 'package:atril/data/services/api/federation_api.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/cancellation.dart';
import 'package:atril/utils/result.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// A [ServerRepository] that answers from memory.
final class FakeServerRepository implements ServerRepository {
  /// The node this device is pointed at.
  ServerDescriptor? node;

  /// Every choice it was asked to make, in order.
  final List<ServerChoice> asked = <ServerChoice>[];

  /// What the next choice fails with, or `null` to let it succeed.
  Exception? refusal;

  @override
  Future<Result<ServerDescriptor?>> current() async =>
      Result<ServerDescriptor?>.ok(node);

  /// Every domain it was asked to adopt as the reader's origin.
  final List<String> adopted = <String>[];

  @override
  Future<Result<ServerDescriptor>> adoptOrigin(String domain) async {
    adopted.add(domain);

    final descriptor = ServerDescriptor(
      domain: domain,
      baseUrl: 'https://$domain',
    );

    node = descriptor;

    return Result<ServerDescriptor>.ok(descriptor);
  }

  @override
  Future<Result<ServerDescriptor>> choose(ServerChoice choice) async {
    asked.add(choice);

    final refused = refusal;

    if (refused != null) {
      return Result<ServerDescriptor>.error(refused);
    }

    final descriptor = ServerDescriptor(
      domain: choice.domain,
      baseUrl: 'https://${choice.domain}',
      grpcAuthority: '${choice.domain}:9090',
    );

    node = descriptor;

    return Result<ServerDescriptor>.ok(descriptor);
  }
}

/// An [AuthRepository] that answers from memory.
final class FakeAuthRepository implements AuthRepository {
  /// Every set of credentials it was handed, in order.
  final List<Credentials> attempts = <Credentials>[];

  /// What the next sign-in fails with, or `null` to let it succeed.
  Exception? refusal;

  /// Every registration it was handed, in order.
  final List<Registration> registrations = <Registration>[];

  @override
  Future<Result<User>> register(Registration registration) async {
    registrations.add(registration);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    return Result<User>.ok(_reader(registration.localName));
  }

  @override
  Future<Result<User>> signIn(Credentials credentials) async {
    attempts.add(credentials);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    return Result<User>.ok(_reader(credentials.identifier));
  }

  /// Every address a recovery was asked for, in order.
  final List<String> recoveries = <String>[];

  /// Every reset it was asked to make, as `(token, password)`.
  final List<(String, String)> resets = <(String, String)>[];

  @override
  Future<Result<void>> requestPasswordRecovery(String email) async {
    recoveries.add(email);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> resetPassword({
    required String recoveryToken,
    required String newPassword,
  }) async {
    resets.add((recoveryToken, newPassword));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// How many times it was asked to sign out.
  int signOuts = 0;

  /// The reader it reports as signed in, which nothing changes on its own.
  final StreamController<User?> readers = StreamController<User?>.broadcast();

  @override
  Stream<User?> reader() => readers.stream;

  @override
  Future<Result<void>> signOut() async {
    signOuts++;
    readers.add(null);

    return const Result<void>.ok(null);
  }

  User _reader(String localName) => User(
    id: '22222222-2222-4222-8222-222222222222',
    localName: localName,
    displayName: localName,
    originServerDomain: 'quire-a.example',
    federatedId: '@$localName:quire-a.example',
    createdAt: DateTime.utc(2026),
  );
}

/// A [FederationRepository] that answers from memory.
///
/// It answers with a `Result` and holds no stream, because the repository it
/// stands in for holds none either: the catalogue is what the node knows, so
/// every screen above it asks and is answered once.
final class FakeFederationRepository implements FederationRepository {
  /// The catalogue this node reports, which a test sets.
  List<KnownServer> catalogue = <KnownServer>[];

  /// What the next call fails with, or `null` to let it answer.
  Exception? refusal;

  /// How many times the catalogue was read.
  int reads = 0;

  /// Every domain an addition was asked for, in order.
  final List<String> added = <String>[];

  /// Every change to the switch, as `(serverId, active)`.
  final List<(String, bool)> switched = <(String, bool)>[];

  /// Every server a refresh was asked for, in order.
  final List<String> refreshed = <String>[];

  /// Every server a removal was asked for, in order.
  final List<String> forgotten = <String>[];

  /// Whether the next refresh reports a key that moved.
  bool fingerprintChanges = false;

  @override
  Future<Result<List<KnownServer>>> knownServers() async {
    reads++;

    final refused = refusal;

    return refused == null
        ? Result<List<KnownServer>>.ok(catalogue)
        : Result<List<KnownServer>>.error(refused);
  }

  @override
  Future<Result<KnownServer>> addServer(String domain) async {
    added.add(domain);

    final refused = refusal;

    if (refused != null) {
      return Result<KnownServer>.error(refused);
    }

    final server = KnownServer(
      id: 'added',
      descriptor: ServerDescriptor(
        domain: domain,
        baseUrl: 'https://$domain',
        grpcAuthority: '$domain:9090',
      ),
      isOrigin: false,
      active: true,
    );

    catalogue = <KnownServer>[...catalogue, server];

    return Result<KnownServer>.ok(server);
  }

  @override
  Future<Result<KnownServer>> setActive({
    required String serverId,
    required bool active,
  }) async {
    switched.add((serverId, active));

    final refused = refusal;

    if (refused != null) {
      return Result<KnownServer>.error(refused);
    }

    return Result<KnownServer>.ok(_byId(serverId));
  }

  @override
  Future<Result<ServerRefresh>> refreshServer(String serverId) async {
    refreshed.add(serverId);

    final refused = refusal;

    if (refused != null) {
      return Result<ServerRefresh>.error(refused);
    }

    return Result<ServerRefresh>.ok(
      ServerRefresh(
        server: _byId(serverId),
        fingerprintChanged: fingerprintChanges,
      ),
    );
  }

  @override
  Future<Result<void>> forgetServer(KnownServer server) async {
    forgotten.add(server.id);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    catalogue = <KnownServer>[
      for (final held in catalogue)
        if (held.id != server.id) held,
    ];

    return const Result<void>.ok(null);
  }

  /// The permissions this node reports, which a test sets.
  List<ReplicaAuthorization> grants = <ReplicaAuthorization>[];

  /// Every grant it was asked for, as `(serverId, replicatesFiles)`.
  final List<(String, bool)> authorized = <(String, bool)>[];

  /// Every permission a withdrawal was asked for, in order.
  final List<String> revoked = <String>[];

  @override
  Future<Result<List<ReplicaAuthorization>>> replicas() async {
    final refused = refusal;

    return refused == null
        ? Result<List<ReplicaAuthorization>>.ok(grants)
        : Result<List<ReplicaAuthorization>>.error(refused);
  }

  @override
  Future<Result<ReplicaAuthorization>> authorizeReplica({
    required String serverId,
    required bool replicatesFiles,
  }) async {
    authorized.add((serverId, replicatesFiles));

    final refused = refusal;

    if (refused != null) {
      return Result<ReplicaAuthorization>.error(refused);
    }

    final granted = ReplicaAuthorization(
      id: 'grant-${grants.length + 1}',
      serverId: serverId,
      serverDomain: _byId(serverId).descriptor.domain,
      authorizedAt: DateTime.utc(2026, 9),
      replicatesFiles: replicatesFiles,
      active: true,
    );

    grants = <ReplicaAuthorization>[...grants, granted];

    return Result<ReplicaAuthorization>.ok(granted);
  }

  @override
  Future<Result<void>> revokeReplica(String serverId) async {
    revoked.add(serverId);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    grants = <ReplicaAuthorization>[
      for (final grant in grants)
        if (grant.serverId == serverId)
          ReplicaAuthorization(
            id: grant.id,
            serverId: grant.serverId,
            serverDomain: grant.serverDomain,
            authorizedAt: grant.authorizedAt,
            replicatesFiles: grant.replicatesFiles,
            active: false,
          )
        else
          grant,
    ];

    return const Result<void>.ok(null);
  }

  /// The devices this migration would carry, which a test sets.
  CarriedDevices carried = const CarriedDevices(
    named: true,
    devices: <CarriedDevice>[
      CarriedDevice(
        id: '11111111-1111-4111-8111-111111111111',
        isThisDevice: true,
        name: 'Celular',
        platform: 'android',
      ),
    ],
  );

  /// Every migration it was handed, in order.
  final List<HomeServerMigration> migrations = <HomeServerMigration>[];

  @override
  Future<Result<CarriedDevices>> devicesToCarry() async {
    final refused = refusal;

    return refused == null
        ? Result<CarriedDevices>.ok(carried)
        : Result<CarriedDevices>.error(refused);
  }

  @override
  Future<Result<User>> migrate(HomeServerMigration migration) async {
    migrations.add(migration);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    return Result<User>.ok(
      User(
        id: '22222222-2222-4222-8222-222222222222',
        localName: migration.localName,
        displayName: migration.displayName,
        originServerDomain: migration.domain,
        federatedId: '@${migration.localName}:${migration.domain}',
        createdAt: DateTime.utc(2026, 9),
        email: migration.email,
      ),
    );
  }

  KnownServer _byId(String id) =>
      catalogue.firstWhere((KnownServer server) => server.id == id);
}

/// A [LibraryRepository] that answers from memory.
///
/// The works and the groupings are broadcast controllers rather than fields,
/// because what the screen is written against is a *stream*: a test that set a
/// list and pumped would be exercising a repository this app does not have.
/// Nothing is emitted until a test says so, which is also how the state before
/// the first answer — the one that is neither empty nor full — is reached.
final class FakeLibraryRepository implements LibraryRepository {
  /// The works, as the screen sees them arrive.
  final StreamController<Result<List<Ebook>>> works =
      StreamController<Result<List<Ebook>>>.broadcast();

  /// The groupings.
  final StreamController<Result<List<Collection>>> groupings =
      StreamController<Result<List<Collection>>>.broadcast();

  /// How many works are filed under each grouping.
  final StreamController<Result<Map<String, int>>> counts =
      StreamController<Result<Map<String, int>>>.broadcast();

  /// Every query the screen has asked, in order.
  final List<LibraryQuery> queries = <LibraryQuery>[];

  /// Every file it was asked to import, in order.
  final List<FileSource> imports = <FileSource>[];

  /// What the next import fails with, or `null` to let it succeed.
  Exception? refusal;

  @override
  Future<Result<Ebook>> importEbook(FileSource file) async {
    imports.add(file);

    final refused = refusal;

    if (refused != null) {
      return Result<Ebook>.error(refused);
    }

    return Result<Ebook>.ok(_imported(file));
  }

  Ebook _imported(FileSource file) => Ebook(
    id: 'imported',
    title: file.name,
    format: EbookFormat.epub,
    contentHash: '0' * 64,
    importedAt: DateTime.utc(2026, 8, 31),
    revision: Revision(
      vectorClock: VectorClock.empty.tick('device'),
      updatedAt: DateTime.utc(2026, 8, 31),
      deviceId: 'device',
    ),
  );

  @override
  Stream<Result<List<Ebook>>> watchEbooks([
    LibraryQuery query = const LibraryQuery(),
  ]) {
    queries.add(query);

    return works.stream;
  }

  @override
  Stream<Result<Ebook?>> watchEbook(String id) => works.stream.map(
    (result) => switch (result) {
      Ok<List<Ebook>>(:final value) => Result<Ebook?>.ok(
        value.where((work) => work.id == id).firstOrNull,
      ),
      Error<List<Ebook>>(:final error) => Result<Ebook?>.error(error),
    },
  );

  @override
  Future<Result<Ebook?>> ebook(String id) async =>
      const Result<Ebook?>.ok(null);

  @override
  Stream<Result<List<Collection>>> watchCollections() => groupings.stream;

  @override
  Stream<Result<Map<String, int>>> watchFilingCounts() => counts.stream;

  @override
  Stream<Result<List<Collection>>> watchCollectionsOf(String ebookId) =>
      groupings.stream;

  /// The works whose bytes this device holds.
  final Set<String> downloaded = <String>{};

  /// Every work a download was asked for, in order.
  final List<String> fetches = <String>[];

  @override
  Future<Result<EbookContent>> downloadEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    fetches.add(ebookId);

    final refused = refusal;

    if (refused != null) {
      return Result<EbookContent>.error(refused);
    }

    downloaded.add(ebookId);

    return Result<EbookContent>.ok(
      const EbookContent(
        contentHash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        sizeBytes: 3,
        mediaType: 'application/epub+zip',
      ),
    );
  }

  /// The works whose files the node has not received yet, and how big they are.
  final Map<String, int> owed = <String, int>{};

  @override
  Stream<Result<ContentState>> watchContent(String ebookId) => works.stream.map(
    (_) => Result<ContentState>.ok(
      ContentState(
        onThisDevice: downloaded.contains(ebookId),
        kept: kept.contains(ebookId),
        owedBytes: owed[ebookId],
      ),
    ),
  );

  /// Every edit it was handed, as `(ebookId, edits)`.
  final List<(String, EbookEdits)> edits = <(String, EbookEdits)>[];

  @override
  Future<Result<void>> editEbook(String ebookId, EbookEdits changes) async {
    edits.add((ebookId, changes));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// Every grouping it was asked to create, in order.
  final List<CollectionEdits> created = <CollectionEdits>[];

  /// Every change to a grouping, as `(collectionId, edits)`.
  final List<(String, CollectionEdits)> collectionEdits =
      <(String, CollectionEdits)>[];

  /// Every grouping it was asked to tombstone, and to bring back.
  final List<String> deletedCollections = <String>[];

  /// Every grouping it was asked to bring back, in order.
  final List<String> restoredCollections = <String>[];

  @override
  Future<Result<Collection>> createCollection(CollectionEdits edits) async {
    created.add(edits);

    final refused = refusal;

    if (refused != null) {
      return Result<Collection>.error(refused);
    }

    return Result<Collection>.ok(
      Collection(
        id: 'created',
        name: edits.name,
        kind: edits.kind,
        description: edits.description,
        createdAt: DateTime.utc(2026, 8, 31),
        revision: Revision(
          vectorClock: VectorClock.empty.tick('device'),
          updatedAt: DateTime.utc(2026, 8, 31),
          deviceId: 'device',
        ),
      ),
    );
  }

  @override
  Future<Result<void>> editCollection(
    String collectionId,
    CollectionEdits edits,
  ) async {
    collectionEdits.add((collectionId, edits));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    deletedCollections.add(collectionId);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreCollection(String collectionId) async {
    restoredCollections.add(collectionId);

    return const Result<void>.ok(null);
  }

  /// Every filing it was asked for, as `(ebookId, collectionId, filed)`.
  final List<(String, String, bool)> filings = <(String, String, bool)>[];

  @override
  Future<Result<void>> fileEbook({
    required String ebookId,
    required String collectionId,
    required bool filed,
  }) async {
    filings.add((ebookId, collectionId, filed));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  /// Every work it was asked to tombstone, in order.
  final List<String> deleted = <String>[];

  /// Every work it was asked to bring back, in order.
  final List<String> restored = <String>[];

  @override
  Future<Result<void>> deleteEbook(String ebookId) async {
    deleted.add(ebookId);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreEbook(String ebookId) async {
    restored.add(ebookId);

    return const Result<void>.ok(null);
  }

  /// The works this device keeps, which starts as every one it holds.
  final Set<String> kept = <String>{};

  /// Every work a release was asked for, in order.
  final List<String> released = <String>[];

  /// What the store reports.
  StorageBudget storageBudget = const StorageBudget(used: 0);

  @override
  Future<Result<void>> keepEbook(
    String ebookId, {
    Cancellation? cancel,
    Future<void> Function(DownloadProgress progress)? onProgress,
  }) async {
    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    kept.add(ebookId);
    downloaded.add(ebookId);

    return const Result<void>.ok(null);
  }

  @override
  Future<Result<void>> releaseEbook(String ebookId) async {
    released.add(ebookId);

    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    kept.remove(ebookId);
    downloaded.remove(ebookId);

    return const Result<void>.ok(null);
  }

  @override
  Future<Result<StorageBudget>> storage() async =>
      Result<StorageBudget>.ok(storageBudget);

  @override
  Stream<Result<List<Ebook>>> watchKeptEbooks() => works.stream.map(
    (result) => switch (result) {
      Ok<List<Ebook>>(:final value) => Result<List<Ebook>>.ok(<Ebook>[
        for (final work in value)
          if (kept.contains(work.id)) work,
      ]),
      Error<List<Ebook>>(:final error) => Result<List<Ebook>>.error(error),
    },
  );

  /// The covers this device has, by work.
  final Map<String, EpubCover> covers = <String, EpubCover>{};

  @override
  Future<Result<EpubCover?>> cover(String ebookId) async =>
      Result<EpubCover?>.ok(covers[ebookId]);
}

/// A [ReadingRepository] that answers from memory.
///
/// The places are a broadcast controller for the reason the works are: what
/// the library screen is written against is a *stream*, and a test that set a
/// list and pumped would be exercising a repository this app does not have.
final class FakeReadingRepository implements ReadingRepository {
  final StreamController<Result<List<ReadingPlace>>> _places =
      StreamController<Result<List<ReadingPlace>>>.broadcast();

  /// Every position the screen recorded.
  final List<({String ebookId, String locator, double? percent})> saved =
      <({String ebookId, String locator, double? percent})>[];

  /// What [openBook] answers with.
  Result<EpubBook>? book;

  /// Emits [places] to whoever is watching.
  void emitPlaces(List<ReadingPlace> places) =>
      _places.add(Result<List<ReadingPlace>>.ok(places));

  /// Emits a failure, which a screen should ride out rather than empty itself
  /// over.
  void failPlaces(Exception error) =>
      _places.add(Result<List<ReadingPlace>>.error(error));

  /// Closes the stream, as a disposed repository would.
  Future<void> close() => _places.close();

  @override
  Future<Result<EpubBook>> openBook(String ebookId) async =>
      book ??
      Result<EpubBook>.ok(
        EpubBook(ebookId: ebookId, bytes: Uint8List(0), title: 'Os Sertões'),
      );

  @override
  Future<Result<void>> saveProgress({
    required String ebookId,
    required String locator,
    double? percent,
  }) async {
    saved.add((ebookId: ebookId, locator: locator, percent: percent));

    return const Result<void>.ok(null);
  }

  @override
  Stream<Result<List<ReadingPlace>>> watchContinueReading({int limit = 20}) =>
      _places.stream;

  @override
  Stream<Result<List<ReadingPlace>>> watchPlacesIn(String ebookId) =>
      _places.stream;

  @override
  Future<Result<Ebook?>> ebook(String ebookId) async => Result<Ebook?>.ok(null);
}

/// An [AnnotationRepository] that answers from memory.
///
/// The marks are a broadcast controller for the reason the works are: what the
/// reader's screen is written against is a *stream*, and a repository that
/// answered a list once would be a repository this app does not have.
final class FakeAnnotationRepository implements AnnotationRepository {
  final StreamController<Result<List<Annotation>>> _marks =
      StreamController<Result<List<Annotation>>>.broadcast();

  /// Every mark it was asked to make, in order.
  final List<({String ebookId, String cfiRange, String? passage})> highlighted =
      <({String ebookId, String cfiRange, String? passage})>[];

  /// Every mark it was asked to remove, and to bring back.
  final List<String> removed = <String>[];

  /// As [removed], the other way.
  final List<String> restored = <String>[];

  /// What the next write fails with, or `null` to let it succeed.
  Exception? refusal;

  /// Emits [marks] to whoever is watching.
  void emitMarks(List<Annotation> marks) =>
      _marks.add(Result<List<Annotation>>.ok(marks));

  /// Emits a failure, which a screen should ride out rather than empty itself
  /// over.
  void failMarks(Exception error) =>
      _marks.add(Result<List<Annotation>>.error(error));

  /// Closes the streams, as a disposed repository would.
  Future<void> close() async {
    await _marks.close();
    await _passages.close();
  }

  final StreamController<Result<List<MarkedPassage>>> _passages =
      StreamController<Result<List<MarkedPassage>>>.broadcast();

  /// Every reworded mark, as `(id, text)`.
  final List<(String, String)> reworded = <(String, String)>[];

  List<MarkedPassage> _current = const <MarkedPassage>[];

  /// Emits [passages] to the annotations screen.
  void emitPassages(List<MarkedPassage> passages) {
    _current = passages;
    _passages.add(Result<List<MarkedPassage>>.ok(passages));
  }

  /// Emits a failure to the annotations screen.
  void failPassages(Exception error) =>
      _passages.add(Result<List<MarkedPassage>>.error(error));

  /// Every scope the screen asked for, as `(ebookId, kind)`.
  final List<(String?, AnnotationKind?)> scopes =
      <(String?, AnnotationKind?)>[];

  @override
  Stream<Result<List<Annotation>>> watchMarksIn(String ebookId) =>
      _marks.stream;

  /// The marks a screen is watching, starting from what is held now.
  ///
  /// It opens with the current list rather than waiting, because that is what
  /// the real repository does: drift answers a `watch` with the rows as they
  /// stand and then with every change. A fake that said nothing until a test
  /// pushed something would leave every screen on its spinner, which is a
  /// difference between the fake and the thing rather than a state of the app.
  @override
  Stream<Result<List<MarkedPassage>>> watchMarks({
    String? ebookId,
    AnnotationKind? kind,
  }) async* {
    scopes.add((ebookId, kind));

    yield Result<List<MarkedPassage>>.ok(_current);
    yield* _passages.stream;
  }

  /// What a one-off read answers with, which is what an export is built from.
  List<MarkedPassage> exportable = const <MarkedPassage>[];

  /// Every scope a one-off read was asked for, in order.
  final List<String?> exported = <String?>[];

  @override
  Future<Result<List<MarkedPassage>>> readMarks({
    String? ebookId,
    AnnotationKind? kind,
  }) async {
    exported.add(ebookId);

    return Result<List<MarkedPassage>>.ok(exportable);
  }

  @override
  Future<Result<void>> reword(String annotationId, String text) async {
    reworded.add((annotationId, text));

    final Exception? refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<Annotation>> highlight({
    required String ebookId,
    required String cfiRange,
    String? passage,
  }) async {
    highlighted.add((ebookId: ebookId, cfiRange: cfiRange, passage: passage));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length}',
        ebookId: ebookId,
        kind: AnnotationKind.highlight,
        locator: cfiRange,
        text: passage,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  /// Every note it was asked to make, in order.
  final List<({String ebookId, String cfiRange, String text})> noted =
      <({String ebookId, String cfiRange, String text})>[];

  @override
  Future<Result<Annotation>> note({
    required String ebookId,
    required String cfiRange,
    required String text,
  }) async {
    noted.add((ebookId: ebookId, cfiRange: cfiRange, text: text));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length + noted.length}',
        ebookId: ebookId,
        kind: AnnotationKind.note,
        locator: cfiRange,
        text: text,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  /// Every place it was asked to bookmark, in order.
  final List<({String ebookId, String locator})> bookmarked =
      <({String ebookId, String locator})>[];

  @override
  Future<Result<Annotation>> bookmark({
    required String ebookId,
    required String locator,
  }) async {
    bookmarked.add((ebookId: ebookId, locator: locator));

    final Exception? refused = refusal;

    if (refused != null) {
      return Result<Annotation>.error(refused);
    }

    return Result<Annotation>.ok(
      Annotation(
        id: 'mark-${highlighted.length + noted.length + bookmarked.length}',
        ebookId: ebookId,
        kind: AnnotationKind.bookmark,
        locator: locator,
        revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
      ),
    );
  }

  @override
  Future<Result<void>> removeMark(String annotationId) async {
    removed.add(annotationId);

    final Exception? refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<void>> restoreMark(String annotationId) async {
    restored.add(annotationId);

    return const Result<void>.ok(null);
  }
}

/// A [SyncRepository] that answers with whatever a test put in it.
///
/// The state is a broadcast controller for the reason the works are: what the
/// badge and the sync screen are written against is a *stream*, and a
/// repository that answered once would be a repository this app does not have.
/// The current value is replayed to each listener, as the real one's is —
/// the shell's badge subscribes long after the loop started.
final class FakeSyncRepository implements SyncRepository {
  final StreamController<SyncState> _states =
      StreamController<SyncState>.broadcast();

  SyncState _state = const SyncState();

  /// How many times a reader asked for a synchronization.
  int asked = 0;

  /// The refused changes a reader asked this device to forget.
  final List<String> discarded = <String>[];

  /// What [discard] answers with.
  Result<void> discards = const Result<void>.ok(null);

  /// What [syncNow] answers with.
  Result<void> answers = const Result<void>.ok(null);

  /// Announces [state].
  void emit(SyncState state) {
    _state = state;
    _states.add(state);
  }

  @override
  Stream<SyncState> watchState() =>
      Stream<SyncState>.multi((MultiStreamController<SyncState> listener) {
        listener.add(_state);

        final subscription = _states.stream.listen(
          listener.add,
          onDone: listener.close,
        );

        listener.onCancel = subscription.cancel;
      });

  @override
  Future<Result<void>> discard(String operationId) async {
    discarded.add(operationId);

    return discards;
  }

  @override
  Future<Result<void>> syncNow() async {
    asked++;

    return answers;
  }

  /// Closes the stream, as a test tearing down its tree would want.
  Future<void> dispose() => _states.close();
}

/// A [FilePicker] that answers with whatever a test put in it.
///
/// The default is `null`, which is a reader who opened the dialog and closed
/// it — the outcome that must not be reported as a failure, and the one a real
/// picker makes awkward to reach.
final class FakeFilePicker implements FilePicker {
  /// What the next pick answers with.
  FileSource? file;

  /// How many times the dialog was opened.
  int opened = 0;

  @override
  Future<FileSource?> pickEbook() async {
    opened++;

    return file;
  }
}

/// A [FileSaver] that keeps whatever it was handed.
///
/// The default is a reader who chose a place, because the interesting refusal
/// — backing out of the dialog — is the one a test has to ask for.
final class FakeFileSaver implements FileSaver {
  /// Every file it was asked to write, in order.
  final List<({String name, String mimeType, List<int> bytes})> saved =
      <({String name, String mimeType, List<int> bytes})>[];

  /// Whether the reader backs out of the dialog.
  bool cancels = false;

  /// What the next save throws, or `null` to let it succeed.
  Object? failure;

  /// What the last file written says.
  String get text => utf8.decode(saved.last.bytes);

  @override
  Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final Object? thrown = failure;

    if (thrown != null) {
      throw thrown;
    }

    if (cancels) {
      return null;
    }

    saved.add((name: suggestedName, mimeType: mimeType, bytes: bytes));

    return '/tmp/$suggestedName';
  }
}

/// A file with a name and no bytes worth speaking of.
final class NamedFile implements FileSource {
  /// The file called [name].
  const NamedFile(this.name);

  @override
  final String name;

  @override
  Future<int?> length() async => 3;

  @override
  Stream<List<int>> openRead() => Stream<List<int>>.value(<int>[1, 2, 3]);
}

/// What an onboarding screen reads out of the tree.
///
/// The environment defaults to a shipped one, so a test that says nothing gets
/// the build with no federation to tap: the development list is a case a test
/// has to ask for, which is the right way round for a list that must never
/// appear in production.
List<SingleChildWidget> repositoryProviders({
  ServerRepository? servers,
  AuthRepository? auth,
  FederationRepository? federation,
  LibraryRepository? library,
  ReadingRepository? reading,
  AnnotationRepository? annotations,
  SyncRepository? sync,
  FilePicker? picker,
  FileSaver? saver,
  Environment? environment,
}) => <SingleChildWidget>[
  Provider<Environment>.value(value: environment ?? Environment.production()),
  Provider<ServerRepository>.value(value: servers ?? FakeServerRepository()),
  Provider<AuthRepository>.value(value: auth ?? FakeAuthRepository()),
  Provider<FederationRepository>.value(
    value: federation ?? FakeFederationRepository(),
  ),
  Provider<LibraryRepository>.value(value: library ?? FakeLibraryRepository()),
  Provider<ReadingRepository>.value(value: reading ?? FakeReadingRepository()),
  Provider<AnnotationRepository>.value(
    value: annotations ?? FakeAnnotationRepository(),
  ),
  Provider<SyncRepository>.value(value: sync ?? FakeSyncRepository()),
  Provider<FilePicker>.value(value: picker ?? FakeFilePicker()),
  Provider<FileSaver>.value(value: saver ?? FakeFileSaver()),
];

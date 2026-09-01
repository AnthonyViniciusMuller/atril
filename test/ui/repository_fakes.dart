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
import 'dart:typed_data';

import 'package:atril/config/environment.dart';
import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/services/content/content_downloader.dart';
import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:atril/data/services/storage/blob_storage.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/collection.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/domain/models/library_query.dart';
import 'package:atril/domain/models/server.dart';
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
  LibraryRepository? library,
  ReadingRepository? reading,
  FilePicker? picker,
  Environment? environment,
}) => <SingleChildWidget>[
  Provider<Environment>.value(value: environment ?? Environment.production()),
  Provider<ServerRepository>.value(value: servers ?? FakeServerRepository()),
  Provider<AuthRepository>.value(value: auth ?? FakeAuthRepository()),
  Provider<LibraryRepository>.value(value: library ?? FakeLibraryRepository()),
  Provider<ReadingRepository>.value(value: reading ?? FakeReadingRepository()),
  Provider<FilePicker>.value(value: picker ?? FakeFilePicker()),
];

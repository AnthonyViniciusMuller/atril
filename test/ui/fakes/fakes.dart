/// The repositories the screens read, faked, and the providers that hand them
/// over.
///
/// Every screen in this app reads its repositories out of the tree, so every
/// widget test that so much as *reaches* one needs them — the router's guard
/// and the adaptive scaffold's taps included, neither of which asserts anything
/// about a repository. [fakeProviders] is that graph, and the fakes it composes
/// are one per file beside this one.
///
/// **A fake is only worth having if something says it agrees with the thing.**
/// `repository_contract_test.dart` is that something: the methods the screens
/// depend on are described once and run against both these and the drift-backed
/// repositories, so a fake that answered a query differently is a failing test
/// rather than a suite of screens passing against a repository this app does
/// not have.
library;

import 'package:atril/config/environment.dart';
import 'package:atril/data/repositories/account/account_repository.dart';
import 'package:atril/data/repositories/annotations/annotation_repository.dart';
import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/federation/federation_repository.dart';
import 'package:atril/data/repositories/library/library_repository.dart';
import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/data/repositories/sync/sync_repository.dart';
import 'package:atril/data/services/files/file_source.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'account_repository.dart';
import 'annotation_repository.dart';
import 'auth_repository.dart';
import 'federation_repository.dart';
import 'files.dart';
import 'library_repository.dart';
import 'reading_repository.dart';
import 'server_repository.dart';
import 'sync_repository.dart';

export 'account_repository.dart';
export 'annotation_repository.dart';
export 'auth_repository.dart';
export 'federation_repository.dart';
export 'files.dart';
export 'library_repository.dart';
export 'reading_repository.dart';
export 'server_repository.dart';
export 'sync_repository.dart';

/// What an onboarding screen reads out of the tree.
///
/// The environment defaults to a shipped one, so a test that says nothing gets
/// the build with no federation to tap: the development list is a case a test
/// has to ask for, which is the right way round for a list that must never
/// appear in production.
List<SingleChildWidget> fakeProviders({
  ServerRepository? servers,
  AuthRepository? auth,
  FederationRepository? federation,
  AccountRepository? accountRepository,
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
  Provider<AccountRepository>.value(
    value: accountRepository ?? FakeAccountRepository(),
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

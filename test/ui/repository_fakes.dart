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

import 'package:atril/config/environment.dart';
import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/domain/models/user.dart';
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

/// What an onboarding screen reads out of the tree.
///
/// The environment defaults to a shipped one, so a test that says nothing gets
/// the build with no federation to tap: the development list is a case a test
/// has to ask for, which is the right way round for a list that must never
/// appear in production.
List<SingleChildWidget> repositoryProviders({
  ServerRepository? servers,
  AuthRepository? auth,
  Environment? environment,
}) => <SingleChildWidget>[
  Provider<Environment>.value(value: environment ?? Environment.production()),
  Provider<ServerRepository>.value(value: servers ?? FakeServerRepository()),
  Provider<AuthRepository>.value(value: auth ?? FakeAuthRepository()),
];

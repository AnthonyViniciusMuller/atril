/// The onboarding screens' collaborators, faked.
///
/// It is shared by the widget tests of this directory and by the two tests
/// above it that merely have to *reach* an onboarding screen — the router's
/// guard and the root widget's — because a screen that reads a repository out
/// of the tree cannot be pumped without one.
library;

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

  @override
  Future<Result<User>> signIn(Credentials credentials) async {
    attempts.add(credentials);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    return Result<User>.ok(
      User(
        id: '22222222-2222-4222-8222-222222222222',
        localName: credentials.identifier,
        displayName: credentials.identifier,
        originServerDomain: 'quire-a.example',
        federatedId: '@${credentials.identifier}:quire-a.example',
        createdAt: DateTime.utc(2026),
      ),
    );
  }
}

/// What an onboarding screen reads out of the tree.
///
/// The environment defaults to a shipped one, so a test that says nothing gets
/// the build with no federation to tap: the development list is a case a test
/// has to ask for, which is the right way round for a list that must never
/// appear in production.
List<SingleChildWidget> onboardingProviders({
  ServerRepository? servers,
  AuthRepository? auth,
  Environment? environment,
}) => <SingleChildWidget>[
  Provider<Environment>.value(value: environment ?? Environment.production()),
  Provider<ServerRepository>.value(value: servers ?? FakeServerRepository()),
  Provider<AuthRepository>.value(value: auth ?? FakeAuthRepository()),
];

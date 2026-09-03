/// A [ServerRepository] that answers from memory.
///
/// It is the discovery half of onboarding without a network: what a screen is
/// written against is a `Result`, and this is one.
library;

import 'dart:async';

import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/utils/result.dart';

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

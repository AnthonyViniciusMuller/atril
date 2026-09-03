/// An [AuthRepository] that answers from memory.
library;

import 'dart:async';

import 'package:atril/data/repositories/auth/auth_repository.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/result.dart';

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
  final StreamController<Result<User?>> readers =
      StreamController<Result<User?>>.broadcast();

  @override
  Stream<Result<User?>> reader() => readers.stream;

  @override
  Future<Result<void>> signOut() async {
    signOuts++;
    readers.add(const Result<User?>.ok(null));

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

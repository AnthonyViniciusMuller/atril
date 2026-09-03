/// An [AccountRepository] that answers from memory.
library;

import 'dart:async';

import 'package:atril/data/repositories/account/account_repository.dart';
import 'package:atril/domain/models/device.dart';
import 'package:atril/domain/models/user.dart';
import 'package:atril/utils/result.dart';

/// An [AccountRepository] that answers from memory.
final class FakeAccountRepository implements AccountRepository {
  /// The devices this node reports, which a test sets.
  List<Device> bound = <Device>[];

  /// The identifier this device writes under.
  String? thisDevice = '11111111-1111-4111-8111-111111111111';

  /// What the next call fails with, or `null` to let it answer.
  Exception? refusal;

  /// Every rename, as `(deviceId, name)`.
  final List<(String, String)> renamed = <(String, String)>[];

  /// Every device an unbinding was asked for, in order.
  final List<String> unbound = <String>[];

  /// The reader this node reports, which a test sets.
  User reader = User(
    id: '22222222-2222-4222-8222-222222222222',
    localName: 'ana',
    displayName: 'Ana Maria',
    originServerDomain: 'quire-a.example',
    federatedId: '@ana:quire-a.example',
    email: 'ana@example.com',
    createdAt: DateTime.utc(2026),
  );

  /// How many times the record was read from the node.
  int reads = 0;

  /// Every display name it was asked to write, in order.
  final List<String> displayNames = <String>[];

  /// Every address change, as `(password, email)`.
  final List<(String, String)> emails = <(String, String)>[];

  /// Every password change, as `(current, next)`.
  final List<(String, String)> passwords = <(String, String)>[];

  @override
  Future<Result<User>> readAccount() async {
    reads++;

    final refused = refusal;

    return refused == null
        ? Result<User>.ok(reader)
        : Result<User>.error(refused);
  }

  @override
  Future<Result<User>> changeDisplayName(String displayName) async {
    displayNames.add(displayName);

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    reader = _reading(displayName: displayName);

    return Result<User>.ok(reader);
  }

  @override
  Future<Result<User>> changeEmail({
    required String password,
    required String email,
  }) async {
    emails.add((password, email));

    final refused = refusal;

    if (refused != null) {
      return Result<User>.error(refused);
    }

    reader = _reading(email: email);

    return Result<User>.ok(reader);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwords.add((currentPassword, newPassword));

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  User _reading({String? displayName, String? email}) => User(
    id: reader.id,
    localName: reader.localName,
    displayName: displayName ?? reader.displayName,
    originServerDomain: reader.originServerDomain,
    federatedId: reader.federatedId,
    email: email ?? reader.email,
    createdAt: reader.createdAt,
  );

  /// Every password a deletion was proved with, in order.
  final List<String> deletions = <String>[];

  @override
  Future<Result<void>> deleteAccount(String password) async {
    deletions.add(password);

    final refused = refusal;

    return refused == null
        ? const Result<void>.ok(null)
        : Result<void>.error(refused);
  }

  @override
  Future<Result<BoundDevices>> devices() async {
    final refused = refusal;

    return refused == null
        ? Result<BoundDevices>.ok(
            BoundDevices(devices: bound, thisDevice: thisDevice),
          )
        : Result<BoundDevices>.error(refused);
  }

  @override
  Future<Result<Device>> renameDevice({
    required String deviceId,
    required String name,
  }) async {
    renamed.add((deviceId, name));

    final refused = refusal;

    if (refused != null) {
      return Result<Device>.error(refused);
    }

    bound = <Device>[
      for (final device in bound)
        if (device.id == deviceId)
          Device(
            id: device.id,
            name: name,
            platform: device.platform,
            active: device.active,
            lastSyncedAt: device.lastSyncedAt,
          )
        else
          device,
    ];

    return Result<Device>.ok(
      bound.firstWhere((Device device) => device.id == deviceId),
    );
  }

  @override
  Future<Result<void>> revokeDevice(String deviceId) async {
    final refused = refusal;

    if (refused != null) {
      return Result<void>.error(refused);
    }

    unbound.add(deviceId);

    bound = <Device>[
      for (final device in bound)
        if (device.id == deviceId)
          Device(
            id: device.id,
            name: device.name,
            platform: device.platform,
            active: false,
            lastSyncedAt: device.lastSyncedAt,
          )
        else
          device,
    ];

    return const Result<void>.ok(null);
  }
}

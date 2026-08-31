import 'dart:convert';

import 'package:atril/data/services/storage/secure_session_store.dart';
import 'package:atril/data/services/storage/session_store.dart';
import 'package:atril/domain/models/session.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// The platform's store, as a map.
///
/// It replaces the three calls this app makes rather than the plugin's
/// platform interface, which keeps the test free of a package this project
/// does not otherwise depend on. What is being tested is what Atril writes and
/// reads back, not whether a keychain works.
final class _FakeStorage extends FlutterSecureStorage {
  _FakeStorage([Map<String, String>? held])
    : entries = held ?? <String, String>{};

  final Map<String, String> entries;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => entries[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      entries.remove(key);
    } else {
      entries[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    entries.remove(key);
  }
}

void main() {
  final expiry = DateTime.utc(2026, 9, 30, 12, 30);

  group('SecureSessionStore', () {
    test('holds nothing before anything has signed in', () async {
      final store = SecureSessionStore(storage: _FakeStorage());

      expect(await store.read(), isNull);
    });

    test('reads back what it wrote, to the microsecond', () async {
      final store = SecureSessionStore(storage: _FakeStorage());

      await store.write(
        SessionCredential(refreshToken: 'opaque', expiresAt: expiry),
      );

      final held = await store.read();

      expect(held?.refreshToken, 'opaque');
      expect(held?.expiresAt, expiry);
      expect(held?.expiresAt.isUtc, isTrue);
    });

    test('writes the credential as one value under one key', () async {
      final storage = _FakeStorage();
      final store = SecureSessionStore(storage: storage);

      await store.write(
        SessionCredential(refreshToken: 'opaque', expiresAt: expiry),
      );

      // Two keys would be a state where the token has been rotated and the
      // expiry has not, and every platform's store writes one key at a time.
      expect(storage.entries.keys, <String>[sessionStorageKey]);
    });

    test('replaces the credential on a rotation', () async {
      final store = SecureSessionStore(storage: _FakeStorage());

      await store.write(
        SessionCredential(refreshToken: 'spent', expiresAt: expiry),
      );
      await store.write(
        SessionCredential(refreshToken: 'issued', expiresAt: expiry),
      );

      expect((await store.read())?.refreshToken, 'issued');
    });

    test('forgets the credential', () async {
      final storage = _FakeStorage();
      final store = SecureSessionStore(storage: storage);

      await store.write(
        SessionCredential(refreshToken: 'opaque', expiresAt: expiry),
      );
      await store.clear();

      expect(await store.read(), isNull);
      expect(storage.entries, isEmpty);
    });

    test('discards a credential it cannot read', () async {
      final storage = _FakeStorage(<String, String>{
        sessionStorageKey: jsonEncode(<String, Object?>{'refresh_token': 42}),
      });
      final store = SecureSessionStore(storage: storage);

      await expectLater(
        store.read(),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', ErrorKind.unauthenticated)
              .having((e) => e.code, 'code', codeUnreadableCredential)
              .having((e) => e.op, 'op', opSessionStore),
        ),
      );

      // Keeping it would mean failing the same way on every start. A
      // credential that cannot be read is one this device does not have.
      expect(storage.entries, isEmpty);
    });

    test('discards a value that is not a credential at all', () async {
      final storage = _FakeStorage(<String, String>{
        sessionStorageKey: 'not json',
      });

      await expectLater(
        SecureSessionStore(storage: storage).read(),
        throwsA(isA<AppException>()),
      );
      expect(storage.entries, isEmpty);
    });

    test('says whether this platform can keep a secret', () {
      // The five native targets have somewhere to put one; a browser does not,
      // and the settings screen is where a reader is told which they are on.
      expect(SecureSessionStore.isSecure, isTrue);
    });
  });
}

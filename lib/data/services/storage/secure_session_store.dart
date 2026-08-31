/// The refresh credential, in the best place each platform has for it.
///
/// One implementation covers all six targets, and the reason it can is that
/// `flutter_secure_storage` is already the platform split: a keychain on iOS
/// and macOS, the `EncryptedSharedPreferences` of the Android keystore,
/// libsecret on Linux, the credential manager on Windows — and, on the web,
/// `localStorage` with an AES key that is itself in `localStorage`.
///
/// **That last one is not secure storage and this file does not pretend it
/// is.** A page cannot keep a secret from the page: anything the app can
/// decrypt, script running in the same origin can decrypt too, and there is no
/// browser API that changes that. What the web build gets is obfuscation and
/// the same lifetime — the credential survives a reload and does not survive
/// the reader clearing site data. [SecureSessionStore.isSecure] is what says
/// so in code, and phase 5's settings screen is where it is said to the
/// reader, because a sovereignty argument that quietly overstates what it
/// keeps is worse than one that does not.
///
/// The credential is written as one value under one key rather than as a token
/// and an expiry under two. Every platform's store writes one key at a time,
/// so two keys is a state where the token has been replaced and the expiry has
/// not — and a rotation writes both on every refresh.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/models/session.dart';
import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import 'session_store.dart';

final _log = loggerFor('data/storage');

/// The key the credential is written under.
///
/// It names the app as well as the value because two of the six stores are
/// shared with everything else the reader runs under the same account: a
/// libsecret collection and a browser origin are not this app's alone.
const String sessionStorageKey = 'atril.session';

/// The stable code of a stored credential this app cannot read back.
const String codeUnreadableCredential = 'unreadable_credential';

/// The refresh credential, kept by the platform.
final class SecureSessionStore implements SessionStore {
  /// The store over [storage], which defaults to the platform's own.
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Whether this platform's store keeps the credential from anything else
  /// running on the device.
  ///
  /// It is false in a browser and true on the five native targets. Nothing in
  /// `data` branches on it: it exists so that the settings screen can tell the
  /// reader what this device is actually promising.
  static bool get isSecure => !kIsWeb;

  @override
  Future<SessionCredential?> read() async {
    final stored = await _storage.read(key: sessionStorageKey);

    if (stored == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(stored);

      if (decoded is! Map<String, Object?>) {
        throw const FormatException('the stored credential is not an object');
      }

      final token = decoded[_tokenField];
      final expiry = decoded[_expiryField];

      if (token is! String || expiry is! int) {
        throw const FormatException('the stored credential is missing a field');
      }

      return SessionCredential(
        refreshToken: token,
        expiresAt: DateTime.fromMicrosecondsSinceEpoch(expiry, isUtc: true),
      );
    } on FormatException catch (error) {
      // A credential that cannot be read is a credential this device does not
      // have. Clearing it is what stops the app from failing the same way on
      // every start, and the reader signs in again — which is the same thing
      // that happens when the store is empty.
      _log.warning(
        'discarding a stored credential this app cannot read',
        error,
      );
      await clear();

      throw AppException(
        kind: ErrorKind.unauthenticated,
        message: 'the stored credential could not be read',
        code: codeUnreadableCredential,
        op: opSessionStore,
        cause: error,
      );
    }
  }

  @override
  Future<void> write(SessionCredential credential) => _storage.write(
    key: sessionStorageKey,
    value: jsonEncode(<String, Object?>{
      _tokenField: credential.refreshToken,
      _expiryField: credential.expiresAt.toUtc().microsecondsSinceEpoch,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: sessionStorageKey);

  static const String _tokenField = 'refresh_token';
  static const String _expiryField = 'expires_at_micros';
}

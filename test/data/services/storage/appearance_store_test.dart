/// How a reader likes the application drawn, across two runs of it.
///
/// The branches worth covering are the two that only show up on somebody
/// else's machine: a run that wrote half of it, and a preferences file written
/// by a build that knew a mode this one does not. Both are answered the same
/// way — fall back, keep what is readable — and the reason is the one
/// `reader_settings_store_test.dart` gives: this is a preference and not a
/// credential, and refusing to start over a word in it would be protecting a
/// value nothing depends on.
library;

import 'package:atril/data/services/storage/appearance_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The store over a preference backend that holds [initial].
PreferencesAppearanceStore _store([Map<String, Object>? initial]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(initial ?? <String, Object>{});

  return PreferencesAppearanceStore(preferences: SharedPreferencesAsync());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a first run', () {
    test('follows the device, in the colours the device offers', () async {
      final Appearance appearance = await _store().read();

      // Both defaults are decisions. The device has already been told once
      // whether its reader wants dark, and a platform that has a colour of its
      // own is a platform whose reader chose that colour too.
      expect(appearance.mode, ThemeMode.system);
      expect(appearance.systemColors, isTrue);
    });
  });

  group('a run after one that chose', () {
    test('reads back what was written', () async {
      final PreferencesAppearanceStore store = _store();

      await store.write(
        const Appearance(mode: ThemeMode.dark, systemColors: false),
      );

      expect(
        await store.read(),
        const Appearance(mode: ThemeMode.dark, systemColors: false),
      );
    });

    test('keeps the half that was written', () async {
      // A write interrupted between its two keys. The mode is a choice the
      // reader made and the colours are one they did not get to; answering
      // with neither would be the application forgetting something it was
      // told because of something it was not.
      final Appearance appearance = await _store(<String, Object>{
        appearanceModeKey: 'light',
      }).read();

      expect(appearance.mode, ThemeMode.light);
      expect(appearance.systemColors, isTrue);
    });

    test('falls back to a mode a later build knew and this one does not', () {
      // A downgrade should be harmless. The alternative is an application that
      // will not start because of a word in a preferences file.
      expect(
        _store(<String, Object>{
          appearanceModeKey: 'sepia',
          appearanceSystemColorsKey: false,
        }).read(),
        completion(
          const Appearance(mode: ThemeMode.system, systemColors: false),
        ),
      );
    });
  });

  group('the store that only remembers', () {
    test('answers with what it was last given', () async {
      final MemoryAppearanceStore store = MemoryAppearanceStore();

      expect(await store.read(), const Appearance());

      await store.write(const Appearance(mode: ThemeMode.light));

      expect(await store.read(), const Appearance(mode: ThemeMode.light));
    });
  });
}

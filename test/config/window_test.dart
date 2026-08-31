/// The window's floor, its memory, and the debounce that keeps it cheap.
///
/// None of it can be exercised against a real window in a unit test, and none
/// of it needs to be: what the platform does with a minimum size is the
/// platform's business, and what this code decides is which size to ask for
/// and how often to write one down.
library;

import 'dart:ui' show Size;

import 'package:atril/config/window.dart';
import 'package:atril/data/services/storage/window_store.dart';
import 'package:atril/ui/core/ui/adaptive_scaffold.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('the sizes', () {
    test('leave the compact layout reachable', () {
      // The floor is below the compact threshold deliberately: a desktop
      // window dragged narrow is supposed to become the phone layout, and a
      // minimum above 600 would be this app refusing the case the adaptive
      // scaffold was written for.
      expect(minimumWindowSize.width, lessThan(compactWidth));
    });

    test('open on a rail and fit a small laptop', () {
      expect(defaultWindowSize.width, greaterThanOrEqualTo(compactWidth));
      expect(defaultWindowSize.width, lessThanOrEqualTo(1366));
      expect(defaultWindowSize.height, lessThanOrEqualTo(768));
    });
  });

  group('whether there is a window', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('is true on the three desktop targets', () {
      for (final platform in <TargetPlatform>[
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(hasConfigurableWindow, isTrue, reason: '$platform');
      }
    });

    test('is false on the other three', () {
      for (final platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(hasConfigurableWindow, isFalse, reason: '$platform');
      }

      // The web build reports the platform it is *running on* — a browser on
      // a Linux desktop answers `linux` — so `kIsWeb` is the half of the guard
      // that keeps a page from reaching for a window manager.
      expect(kIsWeb, isFalse, reason: 'this suite runs on the VM');
    });

    test('lets both entry points call the configuration unconditionally', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(configureDesktopWindow(), completes);
    });
  });

  group('the recorder', () {
    test('writes once for a drag that delivered many resizes', () {
      fakeAsync((FakeAsync async) {
        final store = MemoryWindowStore();
        var asked = 0;
        final recorder = WindowSizeRecorder(
          store,
          delay: const Duration(milliseconds: 500),
          sizeOf: () async {
            asked++;

            return const Size(900, 700);
          },
        );

        // A resize per frame for a fifth of a second, as a dragged edge
        // delivers them.
        for (var frame = 0; frame < 12; frame++) {
          recorder.onWindowResized();
          async.elapse(const Duration(milliseconds: 16));
        }

        expect(asked, 0, reason: 'the window was asked while it was moving');

        async.elapse(const Duration(seconds: 1));

        expect(asked, 1);
        expect(store.size, const Size(900, 700));
      });
    });

    test('writes again once the window moves again', () {
      fakeAsync((FakeAsync async) {
        final store = MemoryWindowStore();
        var size = const Size(900, 700);
        final recorder = WindowSizeRecorder(
          store,
          delay: const Duration(milliseconds: 500),
          sizeOf: () async => size,
        );

        recorder.onWindowResized();
        async.elapse(const Duration(seconds: 1));
        expect(store.size, const Size(900, 700));

        size = const Size(1300, 800);
        recorder.onWindowMaximize();
        async.elapse(const Duration(seconds: 1));

        expect(store.size, const Size(1300, 800));
      });
    });

    test('drops a write that had not happened yet', () {
      fakeAsync((FakeAsync async) {
        final store = MemoryWindowStore();
        final recorder = WindowSizeRecorder(
          store,
          delay: const Duration(milliseconds: 500),
          sizeOf: () async => const Size(900, 700),
        );

        recorder.onWindowResized();
        recorder.cancel();
        async.elapse(const Duration(seconds: 1));

        expect(store.size, isNull);
      });
    });
  });

  group('the store', () {
    late SharedPreferencesAsync preferences;
    late PreferencesWindowStore store;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = SharedPreferencesAsync();
      store = PreferencesWindowStore(preferences: preferences);
    });

    test('answers nothing on a first run', () async {
      expect(await store.read(), isNull);
    });

    test('gives back what it was written', () async {
      await store.write(const Size(800, 600));

      expect(await store.read(), const Size(800, 600));
    });

    test('answers nothing where only one dimension is there', () async {
      // A run that wrote one key and not the other would otherwise reopen at
      // a width it was left at and a height it was not. The default size is a
      // better answer than half a window.
      await preferences.setDouble(windowWidthKey, 800);

      expect(await store.read(), isNull);
    });
  });
}

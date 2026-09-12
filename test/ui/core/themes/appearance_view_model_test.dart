/// What the application is drawn with, and what decides it.
///
/// Two things here are worth an assertion rather than a reading: that the
/// reader's preference and the platform's answer are kept apart — the switch
/// records what somebody *wants*, and a device with nothing to offer is a
/// separate fact — and that a colour nobody can follow is never offered as a
/// choice. Both are the kind of mistake that looks right in a screenshot taken
/// on the machine it was written on.
library;

import 'package:atril/data/services/appearance/system_seed.dart';
import 'package:atril/data/services/storage/appearance_store.dart';
import 'package:atril/ui/core/themes/appearance_view_model.dart';
import 'package:atril/ui/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _wallpaper = Color(0xFF8E4585);

/// A model over [store] and [system], loaded.
///
/// The load is asynchronous and the constructor is not, which is the shape the
/// application itself gets: a first frame drawn from the defaults, and the
/// reader's own answer over it.
Future<AppearanceViewModel> _loaded({
  AppearanceStore? store,
  SystemSeed? system,
}) async {
  final AppearanceViewModel model = AppearanceViewModel(
    store: store ?? MemoryAppearanceStore(),
    system: system ?? const NoSystemSeed(),
  );

  addTearDown(model.dispose);

  await pumpEventQueue();

  return model;
}

void main() {
  group('a device with no colour of its own', () {
    test('offers none, and draws in this application\'s', () async {
      final AppearanceViewModel model = await _loaded();

      // iOS and the browser, and every Android below 12. The preference is
      // still `true` — it says what the reader wants — and there is nothing
      // for it to be true *about*, which is why the settings screen asks the
      // second question and not the first.
      expect(model.systemColors, isTrue);
      expect(model.systemColorsOffered, isFalse);
      expect(model.lightScheme, isNull);
      expect(model.darkScheme, isNull);
    });
  });

  group('a device whose platform answers', () {
    test('grows both schemes from the one colour', () async {
      final AppearanceViewModel model = await _loaded(
        system: const MemorySystemSeed(_wallpaper),
      );

      expect(model.systemColorsOffered, isTrue);
      expect(
        model.lightScheme,
        atrilSchemeOf(brightness: Brightness.light, seed: _wallpaper),
      );
      expect(
        model.darkScheme,
        atrilSchemeOf(brightness: Brightness.dark, seed: _wallpaper),
      );
    });

    test('stops drawing with it the moment the reader says so', () async {
      final MemoryAppearanceStore store = MemoryAppearanceStore();
      final AppearanceViewModel model = await _loaded(
        store: store,
        system: const MemorySystemSeed(_wallpaper),
      );

      model.useSystemColors(use: false);

      // The schemes go and the offer does not: the platform still has a
      // colour, so the switch stays on the screen for the reader to change
      // their mind with.
      expect(model.lightScheme, isNull);
      expect(model.darkScheme, isNull);
      expect(model.systemColorsOffered, isTrue);

      await pumpEventQueue();

      expect(store.appearance.systemColors, isFalse);
    });
  });

  group('what the reader chose', () {
    test('is what a later run is drawn with', () async {
      final AppearanceViewModel model = await _loaded(
        store: MemoryAppearanceStore(
          const Appearance(mode: ThemeMode.dark, systemColors: false),
        ),
      );

      expect(model.mode, ThemeMode.dark);
      expect(model.systemColors, isFalse);
    });

    test('is written down as it is chosen, and said out loud', () async {
      final MemoryAppearanceStore store = MemoryAppearanceStore();
      final AppearanceViewModel model = await _loaded(store: store);

      int said = 0;

      model.addListener(() => said++);

      model.choose(ThemeMode.dark);

      expect(model.mode, ThemeMode.dark);
      expect(said, 1);

      await pumpEventQueue();

      expect(store.appearance.mode, ThemeMode.dark);
    });

    test('says nothing when it has not changed', () async {
      // The root of the application listens to this, so a rebuild of every
      // screen is what a redundant notification costs — and a segmented
      // button hands back the value that is already selected whenever it is
      // tapped twice.
      final AppearanceViewModel model = await _loaded();

      int said = 0;

      model.addListener(() => said++);

      model.choose(ThemeMode.system);
      model.useSystemColors(use: true);

      expect(said, 0);
    });
  });
}

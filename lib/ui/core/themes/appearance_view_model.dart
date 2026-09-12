/// What decides how the application is drawn.
///
/// It is a view model whose view is the whole app, which is why it sits in
/// `ui/core/themes` rather than under a feature: [AtrilApp] reads it to build
/// its two themes and the settings screen's appearance section reads the same
/// instance to change them. Two of them would be a settings screen that moves
/// a switch and nothing else.
///
/// **It is one object and not two preferences.** The mode and the system
/// colours are read from the same store, written to the same store, and both
/// end up in the same two `ThemeData`s; splitting them would be two listeners
/// on the root of the app for one decision.
///
/// **Nothing here fails.** The store swallows what a preference store does to
/// a write and the platform channel answers `null` where there is nothing to
/// answer, so there is no `Command` and no error to show: the worst outcome of
/// every call below is an application drawn the way it was drawn before.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/appearance/system_seed.dart';
import '../../../data/services/storage/appearance_store.dart';
import 'colors.dart';

/// The appearance of the application, and the way to change it.
final class AppearanceViewModel extends ChangeNotifier {
  /// The appearance kept in [store], over the colours [system] offers.
  ///
  /// It starts at the default and loads over it, which is deliberate: reading
  /// a preference is asynchronous on every platform and the first frame is
  /// not. A device that has chosen dark shows one frame of what it was
  /// configured to show before the answer arrives, which is a repaint, and the
  /// alternative is an application that does not start until a preference file
  /// has been opened.
  AppearanceViewModel({required this.store, required this.system}) {
    unawaited(_load());
  }

  /// Where the choice is kept.
  final AppearanceStore store;

  /// What the platform itself is drawn in.
  final SystemSeed system;

  Appearance _appearance = const Appearance();

  Color? _seed;

  ColorScheme? _light;

  ColorScheme? _dark;

  /// Light, dark, or whatever the device is set to.
  ThemeMode get mode => _appearance.mode;

  /// Whether the reader has asked for the platform's own colours.
  ///
  /// It is what the reader chose and not what this device can do — see
  /// [systemColorsOffered] for the second half of that sentence.
  bool get systemColors => _appearance.systemColors;

  /// Whether this platform has a colour to follow at all.
  ///
  /// It is the answer the platform actually gave rather than a list of the
  /// targets that should have one, because the list is longer than the truth:
  /// Android has no palette below 12, and a Linux session may set no accent.
  /// A switch shown where it changes nothing is a control that lies, so the
  /// settings screen asks this before drawing one.
  bool get systemColorsOffered => _seed != null;

  /// The scheme a light build draws with, or `null` for this app's own.
  ///
  /// `null` and not [atrilLightScheme] so that the themes have one place that
  /// knows what the default is. The pair is computed when the seed arrives and
  /// not per build: deriving forty roles from a colour is real work, and the
  /// root of the application is the one widget where doing it on every frame
  /// would be felt.
  ColorScheme? get lightScheme => systemColors ? _light : null;

  /// The scheme a dark build draws with, or `null` for this app's own.
  ColorScheme? get darkScheme => systemColors ? _dark : null;

  /// Draws the application in [mode] from now on.
  void choose(ThemeMode mode) => _adopt(_appearance.copyWith(mode: mode));

  /// Takes the palette from the platform, or stops taking it.
  void useSystemColors({required bool use}) =>
      _adopt(_appearance.copyWith(systemColors: use));

  Future<void> _load() async {
    _appearance = await store.read();
    notifyListeners();

    final Color? seed = await system.read();

    if (seed == null) {
      return;
    }

    _seed = seed;
    _light = atrilSchemeOf(brightness: Brightness.light, seed: seed);
    _dark = atrilSchemeOf(brightness: Brightness.dark, seed: seed);

    notifyListeners();
  }

  void _adopt(Appearance appearance) {
    if (appearance == _appearance) {
      return;
    }

    _appearance = appearance;
    notifyListeners();

    // Written unawaited on purpose: the application is already being drawn the
    // new way, and a reader who closed it in the half-second before the
    // preference landed would find the old one — which is the same outcome as
    // a store that refused the write, and is what the store's own logging is
    // for.
    unawaited(store.write(appearance));
  }
}

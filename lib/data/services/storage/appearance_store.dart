/// Where the reader's choice of light or dark is kept between two runs.
///
/// It is beside the window's size and the reading typography, in
/// `shared_preferences`, and the line `window_store.dart` draws is the same
/// one: the replica holds the records that replicate, the log this device owes
/// and the causal state that makes the next change correct, and whether
/// somebody likes their screen dark is none of those.
///
/// **It is deliberately not replicated, and the contract has no field for it.**
/// A phone read in bed and a desktop under an office light want different
/// answers, and the system colours behind half of this setting are a property
/// of *this* machine — a wallpaper on one device says nothing about the accent
/// colour on another. A setting that synced would make choosing one on either
/// device the wrong choice on the other, which is the argument
/// `reader_settings_store.dart` already makes about type size.
///
/// **A run that wrote half of it is not a state worth protecting.** Each field
/// is read on its own and falls back to the default, so a reader interrupted
/// mid-write comes back to the mode they chose and the colours they did not,
/// rather than to neither.
library;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/logging.dart';

final _log = loggerFor('data/storage');

/// The key the mode is written under.
const String appearanceModeKey = 'appearance.mode';

/// The key the system colours are written under.
const String appearanceSystemColorsKey = 'appearance.systemColors';

/// How a reader likes the application drawn.
///
/// It is [ThemeMode] and not an enum of this project's own. The framework's is
/// exactly this decision, `MaterialApp` takes it unchanged, and a parallel
/// three-valued enum would be a mapping written twice for no second meaning.
final class Appearance {
  /// An appearance, defaulting to whatever the device already says.
  const Appearance({this.mode = ThemeMode.system, this.systemColors = true});

  /// Light, dark, or whatever the device is set to.
  ///
  /// [ThemeMode.system] is the default because the reader has already told
  /// their device once, and an application that ignored it would be asking a
  /// question the platform has the answer to. What the setting adds is the
  /// reader who wants *this* application darker than the rest of their
  /// desktop, which is a real preference and not a second copy of the first.
  final ThemeMode mode;

  /// Whether the palette is taken from the platform.
  ///
  /// On by default, and true on the two targets that can never honour it: the
  /// preference says what the reader wants rather than what this device can
  /// do, so an iPhone and a browser hold the same `true` as everything else
  /// and simply have nothing to follow. A reader who turns it off on a laptop
  /// and later opens the same account on a phone has not thereby chosen
  /// anything about the phone — the setting does not replicate.
  final bool systemColors;

  /// This appearance with the named fields replaced.
  Appearance copyWith({ThemeMode? mode, bool? systemColors}) => Appearance(
    mode: mode ?? this.mode,
    systemColors: systemColors ?? this.systemColors,
  );

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.mode == mode &&
      other.systemColors == systemColors;

  @override
  int get hashCode => Object.hash(mode, systemColors);

  @override
  String toString() => 'Appearance($mode, systemColors: $systemColors)';
}

/// What remembers how a reader likes the application drawn.
abstract interface class AppearanceStore {
  /// The appearance this device was left at, or the default on a first run.
  Future<Appearance> read();

  /// Records [appearance].
  Future<void> write(Appearance appearance);
}

/// The store over the platform's own preferences.
final class PreferencesAppearanceStore implements AppearanceStore {
  /// A store over [preferences], or over the platform's own.
  PreferencesAppearanceStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Appearance> read() async {
    try {
      return Appearance(
        mode: _modeOf(await _preferences.getString(appearanceModeKey)),
        systemColors:
            await _preferences.getBool(appearanceSystemColorsKey) ??
            const Appearance().systemColors,
      );
    } on Exception catch (error) {
      // A preference store that cannot be read is an application that follows
      // the device, which is what it did before this setting existed. It is
      // not worth failing a start-up over, and it is worth one line in the log.
      _log.warning('the appearance could not be read', error);

      return const Appearance();
    }
  }

  @override
  Future<void> write(Appearance appearance) async {
    try {
      await _preferences.setString(appearanceModeKey, appearance.mode.name);
      await _preferences.setBool(
        appearanceSystemColorsKey,
        appearance.systemColors,
      );
    } on Exception catch (error) {
      _log.warning('the appearance could not be written', error);
    }
  }

  /// The mode [name] spells, or the default.
  ///
  /// An unknown name is a preference written by a later version of this
  /// application that has learned a mode this one has not. Falling back is
  /// what makes downgrading harmless; refusing would be a reader whose
  /// application will not start because of a word in a preferences file.
  static ThemeMode _modeOf(String? name) {
    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }

    return const Appearance().mode;
  }
}

/// A store that holds the appearance for as long as the process runs.
///
/// It is what a test uses and what a platform with no preference store would
/// fall back to: a reader whose choice lasts until they close the application
/// is worse than one whose choice lasts, and much better than one whose
/// application will not open.
final class MemoryAppearanceStore implements AppearanceStore {
  /// A store holding [appearance].
  MemoryAppearanceStore([this.appearance = const Appearance()]);

  /// What it holds.
  Appearance appearance;

  @override
  Future<Appearance> read() async => appearance;

  @override
  Future<void> write(Appearance value) async => appearance = value;
}

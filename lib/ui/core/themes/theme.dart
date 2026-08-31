/// The two themes this app is drawn in, and the only place a [ThemeData] is
/// built.
///
/// There are two and not one because a reading application is used in the dark
/// more than most, and there are only two because a third — a sepia, a
/// high-contrast — is a promise to keep every colour decision correct three
/// times. Phase 9's reading surface is where a page's own background belongs,
/// inside the engine that renders it, and not as a third app theme.
///
/// Both are derived from one seed in `colors.dart` and share the type scale in
/// `typography.dart`, so the difference between them is the brightness and
/// nothing else. That is the property worth protecting: a widget that looks
/// right in one and wrong in the other is almost always a colour written where
/// `colors.dart` could not see it.
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// The light and the dark theme.
///
/// It is an abstract final class rather than a pair of top-level getters
/// because the pair is the point: a screen is never given one of them, it is
/// given both and the platform chooses. `MaterialApp.themeMode` is
/// [ThemeMode.system] for that reason — the reader already told their device
/// which they want, and asking a second time in a settings screen would be
/// this app disagreeing with the device about a decision the device owns.
abstract final class AtrilTheme {
  /// The theme of a light build.
  static ThemeData get light => _from(atrilLightScheme);

  /// The theme of a dark build.
  static ThemeData get dark => _from(atrilDarkScheme);

  /// The theme of [scheme], with everything both themes agree on.
  static ThemeData _from(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme);

    return base.copyWith(
      textTheme: atrilTextTheme(base.textTheme),

      // Six targets, one density. The default is per-platform and it is the
      // right default for an app whose desktop build is a port of its phone
      // build; this one is a desktop application that also runs on a phone,
      // and a rail whose rows are touch-sized on a mouse-driven window wastes
      // the height a catalogue is read in. `adaptivePlatformDensity` is still
      // what decides, so a touch device keeps its touch targets.
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // The title sits where the text does. Left, on all six: centring is the
      // Cupertino default and staying with it would mean the same screen has
      // its title in a different place depending on which of the six builds
      // the reader opened — which is not a platform convention worth keeping
      // when the layout beside it is the adaptive one either way.
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}

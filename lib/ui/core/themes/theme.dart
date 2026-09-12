/// The two themes this app is drawn in, and the only place a [ThemeData] is
/// built.
///
/// There are two and not one because a reading application is used in the dark
/// more than most, and there are only two because a third — a sepia, a
/// high-contrast — is a promise to keep every colour decision correct three
/// times. Phase 9's reading surface is where a page's own background belongs,
/// inside the engine that renders it, and not as a third app theme.
///
/// Both are derived from one seed and share the type scale in
/// `typography.dart`, so the difference between them is the brightness and
/// nothing else. That is the property worth protecting: a widget that looks
/// right in one and wrong in the other is almost always a colour written where
/// `colors.dart` could not see it.
///
/// **Which of the two is shown is the reader's, and the seed may be the
/// platform's.** Both were once fixed here — `themeMode` was
/// [ThemeMode.system] and the seed was `atrilSeed` — on the argument that the
/// device already knows what the reader wants. Half of that argument holds and
/// is still the default; the other half was wrong. A reading application is
/// the one window somebody keeps open at night beside a desktop they leave
/// light, and *this* application darker than the rest of the desktop is a
/// preference the platform has no way to express.
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// The light and the dark theme.
///
/// It is an abstract final class rather than a pair of top-level getters
/// because the pair is the point: a screen is never given one of them, it is
/// given both, and `MaterialApp.themeMode` chooses between them — from the
/// device, or from what the reader said instead.
abstract final class AtrilTheme {
  /// The theme of a light build, over [scheme].
  ///
  /// [scheme] is what the platform's own colour grew — `atrilSchemeOf` is
  /// where it grew, from one seed and nothing else — and `null` is this
  /// application's own colours. A scheme and not a seed, because deriving the
  /// forty roles is real work and the caller is the root of the app: it is
  /// done once, where the platform answered, rather than on every build.
  static ThemeData light({ColorScheme? scheme}) =>
      _from(scheme ?? atrilLightScheme);

  /// The theme of a dark build, over [scheme].
  static ThemeData dark({ColorScheme? scheme}) =>
      _from(scheme ?? atrilDarkScheme);

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

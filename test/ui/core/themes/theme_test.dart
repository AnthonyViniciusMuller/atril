/// What the theme promises, as three assertions.
///
/// A theme is mostly taste and taste is not testable, so what is pinned here
/// is only what a later change could break silently: that the two schemes are
/// one seed seen twice, that the type scale is actually applied rather than
/// declared, and that the text a reader spends hours in stays legible against
/// what is behind it.
library;

import 'package:atril/ui/core/themes/colors.dart';
import 'package:atril/ui/core/themes/theme.dart';
import 'package:atril/ui/core/themes/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The WCAG contrast ratio between [a] and [b], both assumed opaque.
double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('the schemes', () {
    test('are the one seed, at both brightnesses', () {
      expect(atrilLightScheme.brightness, Brightness.light);
      expect(atrilDarkScheme.brightness, Brightness.dark);

      expect(AtrilTheme.light().colorScheme, atrilLightScheme);
      expect(AtrilTheme.dark().colorScheme, atrilDarkScheme);

      // Two schemes from one seed cannot drift apart in hue. If somebody
      // hand-tunes one of them, this is what says so.
      expect(
        ColorScheme.fromSeed(seedColor: atrilSeed, brightness: Brightness.dark),
        atrilDarkScheme,
      );
    });

    test('grow from whatever seed they are given', () {
      // The system's colour arrives as a seed and leaves as a whole scheme,
      // derived by the same algorithm with the same contrast guarantees. What
      // this pins is that it is a *seed* and not a palette: a wallpaper can
      // change the hue of every role and cannot change the shape of the
      // scheme, which is what keeps a system palette from producing something
      // no screen here has been looked at against.
      const Color wallpaper = Color(0xFF8E4585);

      final ColorScheme light = atrilSchemeOf(
        brightness: Brightness.light,
        seed: wallpaper,
      );

      expect(light, isNot(atrilLightScheme));
      expect(
        light,
        ColorScheme.fromSeed(
          seedColor: wallpaper,
          brightness: Brightness.light,
        ),
      );
      expect(AtrilTheme.light(scheme: light).colorScheme, light);

      // And a seed nobody gave is this application's own.
      expect(
        atrilSchemeOf(brightness: Brightness.dark, seed: null),
        atrilDarkScheme,
      );
      expect(AtrilTheme.dark(scheme: null).colorScheme, atrilDarkScheme);
    });

    test('keep body text legible on the surface it is read on', () {
      // The third and fourth are a system palette: the roles come out of the
      // same algorithm, so the floor has to hold for a seed this project did
      // not choose — which is the whole argument for taking one colour off the
      // platform rather than forty.
      const Color wallpaper = Color(0xFF8E4585);

      for (final scheme in <ColorScheme>[
        atrilLightScheme,
        atrilDarkScheme,
        atrilSchemeOf(brightness: Brightness.light, seed: wallpaper),
        atrilSchemeOf(brightness: Brightness.dark, seed: wallpaper),
      ]) {
        // 4.5:1 is the WCAG AA floor for body text. It is asserted on the
        // pair every screen in this app uses most, because a seed changed for
        // how it looks in a header is a seed changed for the wrong screen.
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'onSurface on surface, ${scheme.brightness}',
        );
        expect(
          _contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'onSurfaceVariant on surface, ${scheme.brightness}',
        );
      }
    });
  });

  group('the type scale', () {
    test('gives paragraphs their leading and leaves labels alone', () {
      final scale = atrilTextTheme(Typography.material2021().black);

      expect(scale.bodyLarge?.height, atrilParagraphHeight);
      expect(scale.bodyMedium?.height, atrilParagraphHeight);
      expect(scale.bodySmall?.height, atrilParagraphHeight);

      final baseline = Typography.material2021().black;

      expect(scale.labelLarge, baseline.labelLarge);
      expect(scale.labelMedium, baseline.labelMedium);
    });

    test('is what the themes hand to a screen', () {
      for (final theme in <ThemeData>[AtrilTheme.light(), AtrilTheme.dark()]) {
        expect(theme.textTheme.bodyLarge?.height, atrilParagraphHeight);
        expect(theme.textTheme.titleMedium?.letterSpacing, 0);
      }
    });
  });
}

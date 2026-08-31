/// Every colour this app draws with, named once.
///
/// The rule is one line long and it is the reason this file exists: **a hex
/// literal outside this file is a theme that will disagree with itself.** A
/// colour written into a widget is invisible to the dark scheme, invisible to
/// the contrast check, and impossible to change without finding every copy of
/// it — and there is always one more copy.
///
/// What is spelled out here is a *seed*, not a palette. Material 3 derives the
/// forty-odd roles of a scheme — the surfaces, the containers, the `on-`
/// colours and their contrast guarantees — from a single source colour, so
/// naming one colour and letting the algorithm name the rest is both less to
/// maintain and more likely to be legible. A role Material has no name for is
/// added here, next to the seed, and not where it is used.
library;

import 'package:flutter/material.dart';

/// The colour both schemes are derived from.
///
/// A muted blue-green, chosen for what it is *not*: it is not a brand, and it
/// is not saturated. Every screen in this app is a page of text — a catalogue,
/// a book, a note the reader wrote — and the chrome around text earns its
/// place by staying behind it.
const Color atrilSeed = Color(0xFF3F6B6B);

/// The scheme a light build draws with.
final ColorScheme atrilLightScheme = ColorScheme.fromSeed(
  seedColor: atrilSeed,
  brightness: Brightness.light,
);

/// The scheme a dark build draws with.
///
/// It is derived from the same seed rather than hand-tuned, so the two schemes
/// cannot drift apart: a role that changes hue in one changes in both.
final ColorScheme atrilDarkScheme = ColorScheme.fromSeed(
  seedColor: atrilSeed,
  brightness: Brightness.dark,
);

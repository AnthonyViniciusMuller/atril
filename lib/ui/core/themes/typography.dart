/// The type scale every screen inherits, the reader among them.
///
/// It is a *modification* of the Material 3 baseline rather than fifteen
/// styles written out, and that is deliberate. The baseline already carries
/// the platform's font, the optical sizes and the weights the components are
/// designed against; restating it here would freeze a copy that stops
/// tracking the framework and says nothing about what this app decided. What
/// this app decided is below, and it is short enough to argue with.
///
/// **Long text gets a line height, and short text does not.** A catalogue
/// entry, a note the reader wrote, the description of a work: these are
/// paragraphs, and 1.5 is the line height below which a paragraph stops being
/// comfortable at a body size. A label on a button is one line and gains
/// nothing from the leading, so the label styles are left alone.
///
/// **Titles are not tracked out.** The baseline widens `titleMedium` and
/// `titleSmall` slightly, which reads as emphasis in a header bar and as noise
/// above a list of book titles — which is what most titles in this app sit
/// above.
///
/// The book itself is not typeset here. Phase 9 renders an EPUB through
/// epub.js, inside a DOM this scale does not reach, and the reader's own font
/// and size controls live there: what a reading screen inherits from this file
/// is its chrome — the title, the progress, the note the reader is writing —
/// so that a book's page is the only thing on screen that looks different.
library;

import 'package:flutter/material.dart';

/// The leading of a paragraph, as a multiple of the font size.
///
/// It is named rather than repeated because phase 9's reading preferences are
/// spelled in the same unit, and a default that disagreed with the app around
/// it would be visible on the first screen that shows both.
const double atrilParagraphHeight = 1.5;

/// The type scale of the app, over [baseline].
///
/// [baseline] is the platform's own Material 3 scale, which is what
/// [ThemeData] would have used. It is a parameter and not a lookup so that
/// this function is pure and a test can hand it a known scale rather than
/// whichever one the host running the test happens to have.
TextTheme atrilTextTheme(TextTheme baseline) => baseline.copyWith(
  bodyLarge: _paragraph(baseline.bodyLarge),
  bodyMedium: _paragraph(baseline.bodyMedium),
  bodySmall: _paragraph(baseline.bodySmall),
  titleLarge: _untracked(baseline.titleLarge),
  titleMedium: _untracked(baseline.titleMedium),
  titleSmall: _untracked(baseline.titleSmall),
);

/// [style] as a paragraph: the same face, given room to breathe.
TextStyle? _paragraph(TextStyle? style) =>
    style?.copyWith(height: atrilParagraphHeight);

/// [style] with the baseline's extra tracking removed.
TextStyle? _untracked(TextStyle? style) => style?.copyWith(letterSpacing: 0);

/// What is drawn over the page, kept in step with what the replica holds.
///
/// **The list is the truth and the gesture is not.** What is painted is decided
/// by the annotations the repository answers with, never by the action that
/// made one — so a highlight made on a phone appears here when it synchronizes,
/// one removed anywhere leaves the page, and a mark given words is redrawn in
/// the colour a note is drawn in. Nothing here remembers who made what.
///
/// It is an object rather than a method on the view model because it owns one
/// piece of state — what is currently on the page — and that state is the whole
/// of the algorithm: the diff against it is what keeps a redraw after a
/// re-open costing the same as the first draw, and it is what makes
/// `EpubHost.draw` being idempotent per range something this class relies on
/// rather than something the caller has to know.
library;

import 'package:flutter/foundation.dart';

import '../../../data/services/epub/epub_host.dart';
import '../../../domain/models/annotation.dart';
import '../../core/themes/colors.dart';

/// How solid a mark is painted over the page.
///
/// A highlight a reader cannot read through is a highlight that hid the
/// sentence it was about, which is the one thing it was for.
const double readerMarkOpacity = 0.35;

/// The paint over one book's page.
final class MarkPainter {
  /// A painter that draws into [host].
  MarkPainter(this.host);

  /// Where the marks are drawn.
  final EpubHost host;

  final Map<String, AnnotationKind?> _painted = <String, AnnotationKind?>{};

  /// What is on the page now, as this object believes it.
  @visibleForTesting
  Map<String, AnnotationKind?> get painted =>
      Map<String, AnnotationKind?>.unmodifiable(_painted);

  /// Forgets what is on the page, without erasing anything.
  ///
  /// It is what a freshly opened book calls: the engine has drawn nothing, so
  /// believing otherwise would be a diff against a page that no longer exists.
  void forget() => _painted.clear();

  /// Draws what is missing, erases what has gone, and redraws what changed.
  ///
  /// A failure leaves this object believing **nothing** is painted rather than
  /// believing what it had drawn so far, so the next reconciliation is a full
  /// redraw and not a diff against a lie. The failure is rethrown: what to say
  /// about it is the caller's to decide, and for the reader the answer is a log
  /// line, because the book is on screen and readable.
  Future<void> reconcile(List<Annotation> marks) async {
    final Map<String, AnnotationKind?> wanted = <String, AnnotationKind?>{
      for (final Annotation mark in marks)
        // A bookmark is a position and covers no range, so there is nothing to
        // paint over. It is shown in the chrome instead.
        if (mark.kind != AnnotationKind.bookmark) mark.locator: mark.kind,
    };

    try {
      for (final String range in _painted.keys.toList()) {
        if (wanted[range] != _painted[range]) {
          await host.erase(range);
        }
      }

      for (final MapEntry<String, AnnotationKind?> mark in wanted.entries) {
        if (_painted[mark.key] != mark.value) {
          await host.draw(
            EpubMark(
              cfiRange: mark.key,
              color: mark.value == AnnotationKind.note
                  ? atrilNote
                  : atrilHighlight,
              opacity: readerMarkOpacity,
            ),
          );
        }
      }

      _painted
        ..clear()
        ..addAll(wanted);
    } on Object {
      _painted.clear();
      rethrow;
    }
  }
}

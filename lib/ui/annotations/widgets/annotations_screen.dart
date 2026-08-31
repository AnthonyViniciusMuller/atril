/// Everything the reader has marked, across every book.
///
/// Phase 10 is what fills it, and the reason it is a destination of its own
/// rather than a tab inside a book: a highlight is worth as much away from the
/// page it was taken on as on it, and the roadmap's screen lists both — one
/// book's marks, and the whole library's.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';

/// The annotations screen.
class AnnotationsScreen extends StatelessWidget {
  /// Creates the annotations screen.
  const AnnotationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).navigationAnnotations),
    ),
  );
}

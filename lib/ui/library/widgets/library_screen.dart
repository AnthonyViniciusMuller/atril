/// The reader's collection.
///
/// Phase 8 is what fills it: a grid on a wide window, a list on a narrow one,
/// the empty state that tells a new reader what to do next, and the repository
/// underneath that reads the local replica and is therefore correct offline.
/// What is here now is the destination the shell's first branch points at, so
/// that the route table and the navigation surface are testable before there
/// is anything to navigate to.
library;

import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';

/// The library screen.
class LibraryScreen extends StatelessWidget {
  /// Creates the library screen.
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).navigationLibrary)),
  );
}

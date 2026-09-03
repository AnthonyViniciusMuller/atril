/// The two file ports, faked: the one a reader picks with and the one they
/// save with.
library;

import 'dart:convert';

import 'package:atril/data/services/files/file_source.dart';

/// A [FilePicker] that answers with whatever a test put in it.
///
/// The default is `null`, which is a reader who opened the dialog and closed
/// it — the outcome that must not be reported as a failure, and the one a real
/// picker makes awkward to reach.
final class FakeFilePicker implements FilePicker {
  /// What the next pick answers with.
  FileSource? file;

  /// How many times the dialog was opened.
  int opened = 0;

  @override
  Future<FileSource?> pickEbook() async {
    opened++;

    return file;
  }
}

/// A [FileSaver] that keeps whatever it was handed.
///
/// The default is a reader who chose a place, because the interesting refusal
/// — backing out of the dialog — is the one a test has to ask for.
final class FakeFileSaver implements FileSaver {
  /// Every file it was asked to write, in order.
  final List<({String name, String mimeType, List<int> bytes})> saved =
      <({String name, String mimeType, List<int> bytes})>[];

  /// Whether the reader backs out of the dialog.
  bool cancels = false;

  /// What the next save throws, or `null` to let it succeed.
  Object? failure;

  /// What the last file written says.
  String get text => utf8.decode(saved.last.bytes);

  @override
  Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final Object? thrown = failure;

    if (thrown != null) {
      throw thrown;
    }

    if (cancels) {
      return null;
    }

    saved.add((name: suggestedName, mimeType: mimeType, bytes: bytes));

    return '/tmp/$suggestedName';
  }
}

/// A file with a name and no bytes worth speaking of.
final class NamedFile implements FileSource {
  /// The file called [name].
  const NamedFile(this.name);

  @override
  final String name;

  @override
  Future<int?> length() async => 3;

  @override
  Stream<List<int>> openRead() => Stream<List<int>>.value(<int>[1, 2, 3]);
}

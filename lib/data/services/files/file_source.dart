/// A file the reader named, and the one thing this app does with it.
///
/// It is a port and not a call to `file_selector` at the call site, for the
/// reason every other platform edge here is one: a repository that opened a
/// picker could not be tested without a picker, and the interesting half of
/// the import — hashing a stream while copying it — has nothing to do with
/// where the bytes came from.
///
/// **It is a stream and never a path, and never the bytes.** A path is a
/// concept the web target does not have; a `Uint8List` is a book held twice,
/// once by the caller and once by the store it is being written into. What
/// every target does have is a file that can be read a chunk at a time, which
/// is also exactly what a digest computed as the bytes go past needs.
library;

/// A file the reader chose.
abstract interface class FileSource {
  /// What it is called, with its extension.
  ///
  /// The extension is the only thing that says what format a file is. The node
  /// records what it was told the bytes are and never opens them, so naming
  /// the format is the client's guess to make — and one it makes from the
  /// name, exactly as `internal/client`'s own `describe` does.
  String get name;

  /// How long it is, if the platform said.
  ///
  /// It is a hint and not the answer: what the import declares to the node is
  /// what it actually read, because a length taken from a directory entry and
  /// a length counted while copying can differ on a file somebody is writing.
  Future<int?> length();

  /// The bytes, in whatever chunks the platform hands them over in.
  Stream<List<int>> openRead();
}

/// Where a reader names one.
abstract interface class FilePicker {
  /// Asks the reader for a file to import, or answers `null` if they did not
  /// choose one.
  ///
  /// Cancelling is not a failure and is not reported as one. A reader who
  /// opened the dialog and changed their mind has done nothing wrong, and a
  /// screen that showed them an error would be a screen apologizing for their
  /// decision.
  Future<FileSource?> pickEbook();
}

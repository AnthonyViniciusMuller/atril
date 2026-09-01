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

/// Where a reader puts a file this app produced.
///
/// It is the other half of [FilePicker] and it is a port for the same reason,
/// with one of its own on top: **the platforms do not agree on what saving a
/// file is.** The three desktops and the browser have a save dialog; Android
/// and iOS have a share sheet, which is where *save to Files* and *save to
/// Drive* live on those systems. Two implementations behind one interface is
/// what keeps that a fact about `data/services/files` instead of a condition
/// inside the screen that exports something.
///
/// It takes the bytes whole, unlike [FileSource], and the asymmetry is real
/// rather than an oversight: what this app hands out is a document it has just
/// composed in memory — a few kilobytes of Markdown or JSON — and not a book.
/// The day something large is exported, this grows a streaming shape and the
/// import's argument applies to it too.
abstract interface class FileSaver {
  /// Asks the reader where [bytes] should go, and puts them there.
  ///
  /// [suggestedName] carries the extension, which is the only thing that tells
  /// a system what the file is; [mimeType] is what a share sheet routes on.
  ///
  /// It answers with what the file was saved as, or `null` where the reader
  /// backed out. Backing out is not a failure and is not reported as one — the
  /// same rule [FilePicker.pickEbook] follows, for the same reason.
  Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
  });
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

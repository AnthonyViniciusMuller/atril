/// The files this device still owes the node.
///
/// It is an outbox for bytes, beside the one `sync.dart` holds for operations,
/// and it exists for the same reason: an import is finished the moment the
/// bytes are on this device and the change is in the log, and everything after
/// that is a delivery somebody has to remember. A device that kept the queue in
/// memory would forget a two-hundred-megabyte transfer every time the reader
/// closed the app, which on a mobile network is the difference between an
/// upload that finishes over a week of commutes and one that never finishes at
/// all.
///
/// It replicates to nobody. What travels is the file; what is recorded here is
/// this device's own progress at sending it, which means nothing anywhere else.
///
/// **The node's `received_bytes` is the authority and this row is a hint.** D11
/// stages an upload in a temporary file held in the node's process, so a
/// restart or an expiry invalidates a session this device is still holding —
/// and the identifier below is therefore something to *try*, never something to
/// assume. Every call is written to fall back to `BeginEbookUpload`, and a
/// refused chunk is a beginning rather than a failure.
library;

import 'package:drift/drift.dart';

import '../converters.dart';

/// One file waiting to reach the node.
///
/// The digest is the key, and that is the same decision the blob store and the
/// node's own content table make: the object is shared between every work that
/// names it, so two works imported from one file are one transfer and not two.
@DataClassName('ContentUploadRow')
class ContentUploads extends Table {
  /// The file, lowercase hex sha-256.
  TextColumn get contentHash => text().withLength(min: 64, max: 64)();

  /// What it is, as it was declared to the node.
  ///
  /// It is stored rather than derived on each attempt because it is part of
  /// the declaration the node checked: a build that changed its mind about
  /// what a `.mobi` is called would otherwise resume a transfer under a
  /// description the node did not agree to.
  TextColumn get mediaType => text().withLength(min: 1, max: 100)();

  /// How many bytes there are, by this device's own count.
  IntColumn get sizeBytes => integer()();

  /// The session the node opened, or `null` for a transfer that has not
  /// started or whose session is known to be gone.
  TextColumn get uploadId => text().nullable()();

  /// How many bytes the node last said it holds.
  ///
  /// It is what the node reported and never what this device sent. A device
  /// that recorded what it *sent* would resume past bytes that never landed,
  /// and the digest at the end is what would notice — after the whole file had
  /// travelled.
  IntColumn get sentBytes => integer().withDefault(const Constant(0))();

  /// When the transfer entered the queue.
  IntColumn get queuedAt => integer().map(const InstantConverter())();

  /// When it was last attempted, or `null` for one nothing has tried.
  IntColumn get attemptedAt =>
      integer().map(const InstantConverter()).nullable()();

  /// Why the last attempt did not finish, as the node's stable reason or this
  /// app's own code, or `null` for one that has not failed.
  ///
  /// `unclaimed_content` is the one worth naming here, because it is not a
  /// failure at all: C16 refuses an upload for a digest no work of the reader's
  /// names, and this app never calls `CreateEbook`, so every freshly imported
  /// book answers that until the operation creating it has been pushed. The
  /// row stays queued and the next attempt after a push succeeds.
  TextColumn get refusedCode => text().nullable()();

  /// How many attempts have been made, so that a screen can say *this one is
  /// not working* rather than showing a queue that silently never drains.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{contentHash};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (content_hash GLOB '[0-9a-f]*' AND length(content_hash) = 64)",
    'CHECK (size_bytes > 0)',
    'CHECK (sent_bytes >= 0 AND sent_bytes <= size_bytes)',
  ];
}

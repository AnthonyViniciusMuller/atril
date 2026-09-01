/// What this device still owes the node in bytes, and how it pays it.
///
/// An import is finished the moment the file is on this device and the change
/// is in the log. Everything after that is a delivery, and a delivery is
/// something to *remember* rather than something to wait for — which is why
/// the queue is a table and not a list in memory. A device that held it in
/// memory would forget a two-hundred-megabyte transfer every time the reader
/// closed the app, which on the network RNF01 is written about is the
/// difference between an upload that finishes over a week of commutes and one
/// that never finishes at all.
///
/// **This is where C16 stops being a failure.** An upload is refused with
/// `unclaimed_content` until the operation that created the work has been
/// pushed, and this app never calls `CreateEbook`, so *every* freshly imported
/// book answers that on its first attempt. The row stays queued, the reason is
/// recorded, and the attempt after the next push succeeds. Anything else would
/// be an import that lost its file because it happened while the reader was on
/// a train.
///
/// **Nothing here decides when to run.** Phase 11's loop is what drives a queue
/// on launch, on resume and while the app is open; until then the callers are
/// the import that has just filled it and the detail screen's retry. The queue
/// is written so that running it twice at once is not a hazard — a second call
/// while one is in flight is refused rather than queued — and so that running
/// it when there is nothing to do costs one query.
library;

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';
import '../local/dao/transfers_dao.dart';
import '../local/database.dart';
import '../storage/blob_storage.dart';
import 'content_uploader.dart';

final _log = loggerFor('data/content');

/// What one pass over the queue did.
final class UploadRun {
  /// A pass that delivered [sent] files and left [waiting] and [failed].
  const UploadRun({this.sent = 0, this.waiting = 0, this.failed = 0});

  /// How many files the node now holds because of this pass.
  final int sent;

  /// How many are waiting for something that has not happened yet — a work to
  /// be pushed (C16), a network to come back.
  final int waiting;

  /// How many were refused something no retry will change.
  final int failed;

  /// Whether the pass did anything at all.
  bool get isEmpty => sent == 0 && waiting == 0 && failed == 0;

  @override
  String toString() =>
      'UploadRun(sent $sent, waiting $waiting, failed $failed)';
}

/// The files owed, and the pass that delivers them.
final class UploadQueue {
  /// The queue over [database], sending through [uploader].
  UploadQueue({
    required this.database,
    required this.uploader,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Where the queue lives.
  final AtrilDatabase database;

  /// What sends a file.
  final ContentUploader uploader;

  final DateTime Function() _now;

  bool _running = false;

  /// Whether a pass is in flight.
  bool get isRunning => _running;

  TransfersDao get _transfers => database.transfersDao;

  /// Records that the node is owed the bytes [contentHash] names.
  ///
  /// Two works imported from one file are one transfer: the object is shared
  /// between every work that names it, so a second import of the same book
  /// does not queue a second upload — and does not reset the offset of a
  /// session the node may already be part way through.
  Future<void> owe({
    required String contentHash,
    required String mediaType,
    required int sizeBytes,
  }) => _transfers.enqueue(
    contentHash: contentHash,
    mediaType: mediaType,
    sizeBytes: sizeBytes,
    at: _now(),
  );

  /// Sends what is owed, oldest first.
  ///
  /// A pass while one is already running does nothing and says so, rather than
  /// being queued behind it: the caller that would have been queued is a
  /// launch, a resume or a reader tapping *try again*, and by the time the
  /// first pass ends it will have covered what the second was going to send.
  ///
  /// It never throws. Every transfer is answered for on its own row, and a
  /// pass that gave up at the first failure would leave every file behind one
  /// unsendable book waiting on it.
  Future<UploadRun> run({int? limit}) async {
    if (_running) {
      _log.fine('a pass over the upload queue is already running');

      return const UploadRun();
    }

    _running = true;

    try {
      var sent = 0;
      var waiting = 0;
      var failed = 0;

      for (final owed in await _transfers.pending(limit: limit)) {
        switch (await _sendOne(owed)) {
          case _Answer.sent:
            sent++;
          case _Answer.waiting:
            waiting++;
          case _Answer.failed:
            failed++;
        }
      }

      final run = UploadRun(sent: sent, waiting: waiting, failed: failed);

      if (!run.isEmpty) {
        _log.info('$run');
      }

      return run;
    } finally {
      _running = false;
    }
  }

  Future<_Answer> _sendOne(ContentUploadRow owed) async {
    try {
      final outcome = await uploader.upload(
        owed.contentHash,
        mediaType: owed.mediaType,
        // A hint and never an assumption. D11 stages an upload in a file held
        // in the node's process, so a restart or an expiry invalidates a
        // session this device is still holding — and the uploader falls back
        // to `BeginEbookUpload` when the node says it has none.
        resuming: owed.uploadId,
        onProgress: (UploadProgress progress) => _transfers.recordProgress(
          contentHash: owed.contentHash,
          uploadId: progress.uploadId,
          sentBytes: progress.sentBytes,
        ),
      );

      // Sent or already held: either way the node has the file and it is not
      // owed any more. `alreadyHeld` is not a lesser outcome — it is the
      // answer this device wanted, reached by another device of the reader's
      // or by another reader who had imported the same book.
      await _transfers.retire(owed.contentHash);

      _log.fine('${owed.contentHash} is on the node ($outcome)');

      return _Answer.sent;
    } on Object catch (error, stackTrace) {
      return _record(owed, error, stackTrace);
    }
  }

  /// Whether nothing that could happen later would make [failure] go away.
  ///
  /// One does: a digest this device no longer holds. The file was removed —
  /// the reader released it to make room, or a store was cleared — and there
  /// is nothing left to send, so the row is retired rather than retried until
  /// the end of time.
  bool _isHopeless(AppException failure) => failure.code == codeBlobMissing;

  Future<_Answer> _record(
    ContentUploadRow owed,
    Object error,
    StackTrace stackTrace,
  ) async {
    final failure = error is AppException
        ? error
        : AppException(kind: ErrorKind.unknown, message: '$error');

    if (_isHopeless(failure)) {
      _log.warning(
        'this device no longer holds ${owed.contentHash}; it is not owed',
        error,
      );

      await _transfers.retire(owed.contentHash);

      return _Answer.failed;
    }

    final waiting = _isWaiting(failure);

    await _transfers.recordAttempt(
      contentHash: owed.contentHash,
      at: _now(),
      refusedCode: failure.code.isEmpty ? null : failure.code,
      // The session survives what the node is still holding it through, and is
      // forgotten where the uploader will have released it — the two have to
      // agree, or a later launch resumes an identifier nothing is behind.
      keepSession: waiting || failure.kind == ErrorKind.unavailable,
    );

    if (waiting) {
      _log.fine('${owed.contentHash} is waiting: $failure');

      return _Answer.waiting;
    }

    _log.warning('${owed.contentHash} could not be sent', error, stackTrace);

    return _Answer.failed;
  }

  /// Whether [failure] is a *not yet* rather than a *no*.
  ///
  /// A failed precondition is exactly that by definition — the vocabulary
  /// calls it a state the operation cannot run in *until that changes* — and
  /// on this path the state is almost always C16's: a work whose creating
  /// operation has not been pushed. `unclaimed_content` is what names it, and
  /// the kind is what still gets it right where the reason did not survive the
  /// trip. An unreachable node and a deadline are the network, which comes
  /// back. Everything else — a file the node will not accept at any size, a
  /// declaration it refused — is a refusal a retry would only repeat.
  bool _isWaiting(AppException failure) =>
      failure.code == codeUnclaimedContent ||
      failure.kind == ErrorKind.failedPrecondition ||
      failure.kind == ErrorKind.unavailable ||
      failure.kind == ErrorKind.deadlineExceeded;
}

enum _Answer { sent, waiting, failed }

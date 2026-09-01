/// A work in the reader's collection, and the bytes behind it.
///
/// The record and the file are deliberately two things. A device that holds
/// the row and not the bytes is the ordinary state of a book that has not been
/// downloaded, and on the web it is the ordinary state of every book the
/// reader has not asked to keep — so [Ebook] references no file, and
/// [EbookContent] names a digest and not a work.
library;

import 'dart:typed_data';

import '../crdt/revision.dart';

/// The formats UC02 admits, as subsection 4.2.2 lists them.
///
/// The names are the ones the delta, the local schema and the node's own
/// column all use. An unknown one is an answer and not a failure: it is what a
/// node running a later version legitimately sends, and a work whose format
/// this build cannot name can still be listed, synchronized and kept.
enum EbookFormat {
  /// The one format the reader of phase 9 can open.
  epub('epub'),

  /// Imported, listed, synchronized, and not opened here.
  pdf('pdf'),

  /// As [pdf].
  mobi('mobi'),

  /// As [pdf].
  djvu('djvu'),

  /// As [pdf].
  cbz('cbz');

  const EbookFormat(this.wireName);

  /// The name the contract and both schemas use.
  final String wireName;

  /// The format [name] spells, or `null` for one this build cannot name.
  static EbookFormat? parse(String name) {
    for (final format in EbookFormat.values) {
      if (format.wireName == name) {
        return format;
      }
    }

    return null;
  }

  @override
  String toString() => wireName;
}

/// A work.
final class Ebook {
  /// The work, as a replica holds it.
  const Ebook({
    required this.id,
    required this.title,
    required this.format,
    required this.contentHash,
    required this.importedAt,
    required this.revision,
    this.author,
    this.publisher,
    this.language,
    this.sizeBytes,
    this.extraMetadata = const <String, Object?>{},
  });

  /// The identifier the importing device minted, and the one every annotation
  /// and every reading position references.
  final String id;

  /// What the work is called.
  final String title;

  /// Absent rather than empty when the file did not say. A work whose author
  /// is unknown and one whose author is the empty string are different claims.
  final String? author;

  /// Absent rather than empty, as [author] is.
  final String? publisher;

  /// Absent rather than empty, as [author] is.
  final String? language;

  /// The format, or `null` for one this build cannot name.
  final EbookFormat? format;

  /// The digest of the file, lowercase hex sha-256.
  ///
  /// It identifies the bytes across the whole federation, so the same work
  /// imported by two readers converges on one stored object.
  final String contentHash;

  /// The length of the file, absent until something has seen it.
  final int? sizeBytes;

  /// The metadata the format carried and the contract does not name — series,
  /// ISBN, subjects (RF05). An object, never a scalar.
  final Map<String, Object?> extraMetadata;

  /// When the work entered the collection, on a wall clock.
  final DateTime importedAt;

  /// The replication metadata, which is what a merge reads.
  final Revision revision;

  @override
  String toString() => 'Ebook($id, $title)';
}

/// The bytes of a work, as a node holds them.
final class EbookContent {
  /// The description of one stored object.
  const EbookContent({
    required this.contentHash,
    required this.sizeBytes,
    required this.mediaType,
  });

  /// The digest the bytes are addressed by.
  final String contentHash;

  /// How many bytes there are.
  final int sizeBytes;

  /// What they are, as a media type.
  final String mediaType;

  @override
  String toString() => 'EbookContent($contentHash, $sizeBytes bytes)';
}

/// Where a work's bytes are, from this device's point of view.
///
/// It is one value and not three booleans scattered over a screen, because the
/// states a reader can be in are not independent and the sentence to show them
/// depends on the combination. A book can be here and still owed to the node —
/// that is every freshly imported book — and one that is neither here nor owed
/// is one whose file lives on the node and has not been fetched.
///
/// The reason it has to be said at all is D02: a device holding the row and not
/// the bytes is the ordinary state of a book that has not been downloaded, and
/// in a browser it is the ordinary state of every book the reader has not asked
/// to keep. A screen that assumed the file was there would be a screen that
/// opens a book which is not on this device.
final class ContentState {
  /// The bytes are [onThisDevice], [kept] by the reader's decision or the
  /// platform's default, and — where the node has not received them —
  /// [sentBytes] of [owedBytes] delivered.
  const ContentState({
    required this.onThisDevice,
    required this.kept,
    this.owedBytes,
    this.sentBytes = 0,
  });

  /// Whether this device holds the file.
  final bool onThisDevice;

  /// Whether this device is keeping it when the network is not there.
  final bool kept;

  /// How many bytes the node has still to receive, or `null` when it has them.
  final int? owedBytes;

  /// How many of those the node has acknowledged.
  final int sentBytes;

  /// Whether the node has not received the file yet.
  ///
  /// While this holds, the file is on this device and nowhere else, which is
  /// why releasing it is refused: it is the only copy there is.
  bool get isOwed => owedBytes != null;

  /// How far the transfer has got, between zero and one.
  double get sentFraction {
    final total = owedBytes;

    return total == null || total == 0
        ? 0
        : (sentBytes / total).clamp(0, 1).toDouble();
  }

  @override
  String toString() =>
      'ContentState(here: $onThisDevice, kept: $kept, owed: $owedBytes)';
}

/// One message of a download.
///
/// It is a sealed pair rather than a stream of bytes with the description
/// handed over some other way, because that is exactly the shape the contract
/// sends: a `DownloadEbookContentResponse` is a `oneof`, the description
/// arrives first, and the bytes follow it.
sealed class EbookDownload {
  const EbookDownload();
}

/// The description of what is about to arrive.
final class EbookDownloadStart extends EbookDownload {
  /// The download of [content].
  const EbookDownloadStart(this.content);

  /// What the node holds.
  final EbookContent content;
}

/// Some of the bytes.
final class EbookDownloadChunk extends EbookDownload {
  /// The chunk carrying [bytes].
  const EbookDownloadChunk(this.bytes);

  /// The bytes, in the order they were sent.
  final Uint8List bytes;
}

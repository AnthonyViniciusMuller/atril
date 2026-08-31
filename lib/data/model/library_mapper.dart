/// The library half of the contract, as domain values: the works, the
/// groupings, and the bytes behind a work.
///
/// It maps in one direction only, and that is the rule and not an omission:
/// every change to an e-book or a collection is authored as an operation in
/// the local database and pushed (C21), so nothing in this app ever serializes
/// one. What is sent about a work is its digest, to the upload calls, and a
/// digest is a string.
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart';

import '../../domain/models/collection.dart';
import '../../domain/models/ebook.dart';
import '../services/api/generated/quire/v1/library.pb.dart' as pb;
import 'mapping.dart';

/// The formats, by the name the contract's enum spells them with.
///
/// A value this build cannot name is not an error: a node running a later
/// version of the contract legitimately sends one, and a work whose format
/// this device cannot name can still be listed, synchronized and kept — it
/// simply cannot be opened. That is why [Ebook.format] is nullable.
const Map<String, EbookFormat> ebookFormatsByWireName = <String, EbookFormat>{
  'EBOOK_FORMAT_EPUB': EbookFormat.epub,
  'EBOOK_FORMAT_PDF': EbookFormat.pdf,
  'EBOOK_FORMAT_MOBI': EbookFormat.mobi,
  'EBOOK_FORMAT_DJVU': EbookFormat.djvu,
  'EBOOK_FORMAT_CBZ': EbookFormat.cbz,
};

/// The two kinds of grouping, by the name the contract's enum spells them
/// with.
const Map<String, CollectionKind> collectionKindsByWireName =
    <String, CollectionKind>{
      'COLLECTION_KIND_COLLECTION': CollectionKind.collection,
      'COLLECTION_KIND_CATEGORY': CollectionKind.category,
    };

/// A work in the reader's collection.
Ebook ebookOf(pb.Ebook ebook) => Ebook(
  id: ebook.id.toLowerCase(),
  title: ebook.title,
  author: ebook.hasAuthor() ? ebook.author : null,
  publisher: ebook.hasPublisher() ? ebook.publisher : null,
  language: ebook.hasLanguage() ? ebook.language : null,
  format: ebookFormatsByWireName[ebook.format.name],
  contentHash: ebook.contentHash.toLowerCase(),
  sizeBytes: ebook.hasSizeBytes() ? ebook.sizeBytes.toInt() : null,
  extraMetadata: extraMetadataOf(ebook.extraMetadata),
  importedAt: wallClockOf(ebook.importedAt),
  revision: revisionOf(ebook.revision),
);

/// A grouping the reader defined.
Collection collectionOf(pb.Collection collection) => Collection(
  id: collection.id.toLowerCase(),
  name: collection.name,
  kind: collectionKindsByWireName[collection.kind.name],
  description: collection.hasDescription() ? collection.description : null,
  createdAt: wallClockOf(collection.createdAt),
  revision: revisionOf(collection.revision),
);

/// The metadata the format carried and the contract does not name.
///
/// A `Struct` is proto3's JSON object, so its proto3 encoding *is* the map —
/// there is nothing to walk here, and walking it would be a second decoder to
/// keep in step with the one the delta is read through. A value that is not an
/// object is refused rather than coerced: the column it lands in is `jsonb`
/// constrained to one, on the node and on this device.
Map<String, Object?> extraMetadataOf(Struct metadata) {
  if (metadata.fields.isEmpty) {
    return const <String, Object?>{};
  }

  final decoded = metadata.toProto3Json();

  if (decoded is! Map<String, Object?>) {
    throw malformed('extra_metadata', 'is not an object');
  }

  return decoded;
}

/// The bytes of a work, as a node holds them.
EbookContent contentOf(pb.EbookContent content) => EbookContent(
  contentHash: content.contentHash.toLowerCase(),
  sizeBytes: content.sizeBytes.toInt(),
  mediaType: content.mediaType,
);

/// What is about to be sent, declared to `BeginEbookUpload`.
///
/// It is the one library message this app writes, and it carries a digest
/// rather than a work: an upload names bytes, so an import can queue its
/// operation and send its file without either waiting for the other.
pb.EbookContent wireContent(EbookContent content) => pb.EbookContent(
  contentHash: content.contentHash,
  sizeBytes: Int64(content.sizeBytes),
  mediaType: content.mediaType,
);

/// One message of a download, as the `oneof` sends it.
///
/// A response carrying neither half is refused rather than skipped: the
/// contract has no third case, so one arriving means this device and the node
/// disagree about the shape of the stream, and continuing would be reading
/// bytes of unknown provenance into a file addressed by a digest.
EbookDownload downloadOf(pb.DownloadEbookContentResponse response) {
  if (response.hasContent()) {
    return EbookDownloadStart(contentOf(response.content));
  }

  if (response.hasChunk()) {
    return EbookDownloadChunk(Uint8List.fromList(response.chunk));
  }

  throw malformed('payload', 'is neither a description nor a chunk');
}

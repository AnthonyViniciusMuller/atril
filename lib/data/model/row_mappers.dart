/// The replica's rows, as domain values.
///
/// It is the mirror of the other mappers in this directory and the direction
/// is the difference: they map the *wire* onto the domain, and this maps what
/// drift hands back. A row and a message describe the same record and are not
/// the same type, so the two conversions are two functions — and both belong
/// here, because `data/model` is where this app says what a record *is* once
/// it has stopped being somebody else's representation.
///
/// It exists as a file because three repositories were reaching into a fourth
/// for these: the annotation and reading repositories imported
/// `ebookOfRow` out of `library_repository_impl.dart`, which made a repository
/// a library for its neighbours. Nothing here knows about a repository.
library;

import 'dart:convert';

import '../../domain/crdt/revision.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/collection.dart';
import '../../domain/models/ebook.dart';
import '../../domain/models/server.dart';
import '../../utils/logging.dart';
import '../services/local/database.dart';

final _log = loggerFor('data/model');

/// A work, as the replica holds it.
///
/// The format is read through [EbookFormat.parse], so a value a later build of
/// the node knows and this one does not comes back as `null` rather than as a
/// failure: a work whose format this build cannot name is still listed,
/// synchronized and kept.
Ebook ebookOfRow(EbookRow row) => Ebook(
  id: row.id,
  title: row.title,
  author: row.author,
  publisher: row.publisher,
  language: row.language,
  format: EbookFormat.parse(row.format),
  contentHash: row.contentHash,
  sizeBytes: row.sizeBytes,
  extraMetadata: metadataOf(row.extraMetadata),
  importedAt: row.importedAt,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// A grouping, as the replica holds it.
Collection collectionOfRow(CollectionRow row) => Collection(
  id: row.id,
  name: row.name,
  kind: CollectionKind.parse(row.kind),
  description: row.description,
  createdAt: row.createdAt,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// A mark, as the replica holds it.
Annotation annotationOfRow(AnnotationRow row) => Annotation(
  id: row.id,
  ebookId: row.ebookId,
  kind: AnnotationKind.parse(row.kind),
  text: row.content,
  locator: row.locator,
  revision: Revision(
    vectorClock: row.vectorClock,
    updatedAt: row.updatedAt,
    deviceId: row.deviceId,
    deleted: row.deleted,
  ),
);

/// The node a catalogue row describes, as discovery would have returned it.
///
/// A row is what this device stored and a descriptor is what the rest of the
/// app speaks, and the difference between them is the two fields the catalogue
/// keeps and a client lookup never carries: `jwks_uri` and the certificate
/// fingerprint live in the *server* document, which a peer reads and this
/// device does not.
///
/// It was written three times in the server repository and a fourth at the
/// composition root, which is what put it here.
ServerDescriptor descriptorOfRow(ServerRow row) => ServerDescriptor(
  domain: row.domain,
  baseUrl: row.baseUrl,
  jwksUri: row.jwksUri,
  certificateFingerprint: row.certificateFingerprint,
  grpcAuthority: row.grpcAuthority,
);

/// The extra metadata a row carries, decoded.
///
/// The column is constrained to a JSON object by the schema and by the node's
/// own, so anything else in it is a database this app did not write. It is
/// reported as empty rather than thrown, because the alternative is one
/// malformed row making the whole collection unreadable.
Map<String, Object?> metadataOf(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return const <String, Object?>{};
  }

  final decoded = json.decode(encoded);

  if (decoded is! Map<String, Object?>) {
    _log.warning('the extra metadata of a work is not an object');

    return const <String, Object?>{};
  }

  return decoded;
}

/// `?.let`, which Dart has no operator for.
///
/// It is here so that a nullable row maps to a nullable model without the call
/// site restating the null check.
extension RowMapping<T extends Object> on T {
  /// [transform] applied to this row.
  R let<R>(R Function(T row) transform) => transform(this);
}

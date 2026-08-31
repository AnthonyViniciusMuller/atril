/// The changed fields an operation carries, and how they are read.
///
/// A delta names a record's fields as the schema and the contract both name
/// them — `title`, `locator`, `ebook_id` — and carries their values in the form
/// the column holds: a kind is `note` and not the contract's enumerator, an
/// instant is microseconds, extra metadata is an object. That is the same
/// principle `TargetEntity` follows and for the same reason: one vocabulary
/// travels through the contract, the node's schema and this device's, and a
/// second one would have to be translated at every hop. The specification says
/// nothing about the shape of `carga_delta` at all, which is C19.
///
/// The names below are `internal/sync/infra/service/records`' own, spelled once
/// here so that the reconciler and the operation author of phase 7 cannot spell
/// them two ways. A field spelled differently is a field claimed on nobody's
/// record: it would be stored, replicated, and applied by nothing.
library;

/// The title of a work.
const String fieldTitle = 'title';

/// Its author, absent rather than empty when the file did not say.
const String fieldAuthor = 'author';

/// Its publisher.
const String fieldPublisher = 'publisher';

/// Its language.
const String fieldLanguage = 'language';

/// The metadata the format carried and the contract does not name. An object,
/// never a scalar.
const String fieldExtraMetadata = 'extra_metadata';

/// The format of the file, fixed at import.
const String fieldFormat = 'format';

/// The digest of the file, fixed at import.
const String fieldContentHash = 'content_hash';

/// The length of the file, fixed at import.
const String fieldSizeBytes = 'size_bytes';

/// When a work entered the collection.
const String fieldImportedAt = 'imported_at';

/// The name of a grouping.
const String fieldName = 'name';

/// The kind of a grouping, or of a mark.
const String fieldKind = 'kind';

/// What a grouping is for.
const String fieldDescription = 'description';

/// When a grouping was created.
const String fieldCreatedAt = 'created_at';

/// The work half of a filing's pair, and the work a mark or a position is in.
const String fieldEbookId = 'ebook_id';

/// The grouping half of a filing's pair.
const String fieldCollectionId = 'collection_id';

/// What the reader wrote in a mark.
const String fieldText = 'text';

/// The passage a mark is attached to, or the position a reader reached.
const String fieldLocator = 'locator';

/// How far through a work the reader is.
const String fieldPercent = 'percent';

/// A field the change claims with a value the record cannot hold.
///
/// It is a rejection and not a failure of this device: the operation came from
/// somewhere else, no retry will change it, and what the reconciler does with
/// it is answer for that one operation and go on with the batch.
final class DeltaException implements Exception {
  /// The failure on [field], because [reason].
  const DeltaException(this.field, this.reason);

  /// The field that carried it.
  final String field;

  /// What is wrong with it, for an operator rather than for a reader.
  final String reason;

  @override
  String toString() => 'the change claims $field, which $reason';
}

/// The changed fields of one record, read by name.
///
/// Every reader here distinguishes three states, and the distinction is the
/// whole of what per-field reconciliation rests on. A field the delta does not
/// name is one the change did not write, and it keeps whatever device wrote it
/// last. A field named as JSON null is a field the change *cleared*. A field
/// named with a value is a field the change wrote.
extension type const Delta(Map<String, Object?> fields) {
  /// Whether the change claims [field] at all.
  bool claims(String field) => fields.containsKey(field);

  /// The text [field] claims: `null` where it is cleared, and absent where it
  /// is not claimed.
  ///
  /// The two are told apart by [claims], which every caller checks first.
  String? text(String field) {
    final value = fields[field];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw DeltaException(field, 'is not text');
    }

    return value;
  }

  /// The text [field] claims, refusing an absent or empty one.
  ///
  /// It is what an insert reads for a column the row cannot be created without:
  /// a record built out of a delta that named none of them would be refused by
  /// a constraint rather than by the reconciler, and the caller would be told
  /// about a table.
  String requiredText(String field) {
    if (!claims(field)) {
      throw DeltaException(field, 'a record cannot be created without it');
    }

    final value = text(field);

    if (value == null || value.trim().isEmpty) {
      throw DeltaException(field, 'is a field the record cannot be without');
    }

    return value;
  }

  /// The whole number [field] claims, or `null` where it is cleared.
  int? integer(String field) {
    final value = fields[field];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    // JSON has one number type, so a value that travelled as 1.0 is the same
    // claim as one that travelled as 1 — but 1.5 is not a whole number by any
    // reading, and rounding it would store something nobody wrote.
    if (value is double && value == value.roundToDouble()) {
      return value.toInt();
    }

    throw DeltaException(field, 'is not a whole number');
  }

  /// The number [field] claims, or `null` where it is cleared.
  double? number(String field) {
    final value = fields[field];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    throw DeltaException(field, 'is not a number');
  }

  /// The instant [field] claims, as the microseconds the wire carries.
  DateTime? instant(String field) {
    final micros = integer(field);

    return micros == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  /// The object [field] claims, still encoded, or `null` where it is cleared.
  ///
  /// It is returned as the text it will be stored as rather than decoded,
  /// because nothing between here and the column reads inside it — and the
  /// column is constrained to an object, which is checked here so that the
  /// refusal names the field rather than the table.
  Object? object(String field) {
    final value = fields[field];

    if (value == null) {
      return null;
    }

    if (value is! Map<String, Object?>) {
      throw DeltaException(field, 'is not an object');
    }

    return value;
  }

  /// The identifier [field] claims, refusing one that names nothing.
  String requiredId(String field) => requiredText(field).toLowerCase();
}

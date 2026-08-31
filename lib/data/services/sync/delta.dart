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
/// here so that the reconciler and the operation author cannot spell them two
/// ways. A field spelled differently is a field claimed on nobody's record: it
/// would be stored, replicated, and applied by nothing.
///
/// The file has two halves and they are the two directions a delta travels.
/// [Delta] reads one that arrived; [DeltaWriter] writes one this device is
/// authoring. They agree on the encoding — an instant is microseconds either
/// way — because a value written in one shape and read in another is a field
/// that survives the wire and not the round trip.
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

/// A delta under construction: the fields a change claims, and nothing else.
///
/// It is the authoring half of this file, and the whole of what it is for is
/// the three states [Delta] distinguishes on the way back. A field this writer
/// was never given stays unnamed, and keeps whatever device wrote it last. A
/// field given a value is a field the change wrote. A field given `null` — or
/// [clear] — is a field the change *cleared*, which is a claim and not a
/// silence.
///
/// Every claim optionally takes the value the record already holds, and a claim
/// that matches it is not made at all:
///
/// ```dart
/// final changes = DeltaWriter()
///   ..text(fieldTitle, form.title, current: row.title)
///   ..text(fieldAuthor, form.author, current: row.author);
///
/// if (changes.isNotEmpty) {
///   await author.write(Change.update(TargetEntity.ebook, row.id, changes.fields));
/// }
/// ```
///
/// That is the rule the phase this landed in is named for, and it is worth more
/// than the bytes it saves. Reconciliation is per record and not per field
/// (C17): a delta that restated a title the reader never touched would carry
/// this device's claim to it, and the next merge against a device that *did*
/// change it would be decided by a tie-break rather than by what anybody meant.
/// A change that claims only what changed cannot lose an edit it did not make.
///
/// The writer knows nothing about which fields a record requires, because it
/// does not know which record it is building one for. A delta missing a field
/// the row cannot exist without is refused by the reconciler, which does.
final class DeltaWriter {
  /// An empty delta.
  DeltaWriter();

  final Map<String, Object?> _fields = <String, Object?>{};

  /// The fields claimed so far, in the order they were claimed.
  ///
  /// It is a copy: a writer handed to something that could keep writing to the
  /// map behind an operation would be a change that grew after it was logged.
  Map<String, Object?> get fields => Map<String, Object?>.of(_fields);

  /// The delta as it stands, read through the same vocabulary that reads one
  /// off the wire.
  Delta get delta => Delta(fields);

  /// Whether the change claims nothing at all.
  ///
  /// An update that claims nothing is not a change, and the operation author
  /// refuses one: it would tick a clock and stamp an instant to tell every
  /// replica that nothing happened, and leave the record reflecting this device
  /// for a write it did not make.
  bool get isEmpty => _fields.isEmpty;

  /// Whether the change claims anything.
  bool get isNotEmpty => _fields.isNotEmpty;

  /// Whether [field] has been claimed, however it was claimed.
  bool claims(String field) => _fields.containsKey(field);

  /// Claims [field] as cleared.
  ///
  /// It is [text] with `null` said out loud, and it is worth a method because
  /// the difference between clearing a field and leaving it alone is invisible
  /// at a call site that passes a variable which happens to be null.
  void clear(String field) => _fields[field] = null;

  /// Claims [field] as [value], or as cleared where it is `null`.
  void text(String field, String? value, {Object? current = _unstated}) =>
      _claim(field, value, current);

  /// Claims [field] as an identifier, in the canonical lowercase text every
  /// replica compares them as.
  ///
  /// It refuses one that names nothing, because a delta that carried an empty
  /// identifier would be an operation the node resolves to no record and this
  /// device could not tell apart from one it never wrote.
  void id(String field, String value, {Object? current = _unstated}) {
    if (value.trim().isEmpty) {
      throw DeltaException(field, 'is an identifier that names nothing');
    }

    _claim(
      field,
      value.toLowerCase(),
      current is String ? current.toLowerCase() : current,
    );
  }

  /// Claims [field] as a whole number, or as cleared where it is `null`.
  void integer(String field, int? value, {Object? current = _unstated}) =>
      _claim(field, value, current);

  /// Claims [field] as a number, or as cleared where it is `null`.
  void number(String field, double? value, {Object? current = _unstated}) =>
      _claim(field, value, current);

  /// Claims [field] as an instant, or as cleared where it is `null`.
  ///
  /// It travels as the microseconds [Delta.instant] reads back, and in UTC,
  /// because the value is compared against instants stamped on other devices in
  /// other zones.
  void instant(String field, DateTime? value, {Object? current = _unstated}) =>
      _claim(
        field,
        value?.toUtc().microsecondsSinceEpoch,
        current is DateTime ? current.toUtc().microsecondsSinceEpoch : current,
      );

  /// Claims [field] as an object, or as cleared where it is `null`.
  ///
  /// An object and never a scalar, which the column it lands in constrains and
  /// [Delta.object] checks on the way back. [current] is the decoded object and
  /// not the text a row stores it as, and the two are compared structurally: a
  /// map that differs only in the order its keys were built in is the same
  /// metadata and is not a change the reader made.
  void object(
    String field,
    Map<String, Object?>? value, {
    Object? current = _unstated,
  }) => _claim(field, value, current);

  void _claim(String field, Object? value, Object? current) {
    if (!identical(current, _unstated) && _same(value, current)) {
      return;
    }

    _fields[field] = value;
  }

  @override
  String toString() => 'DeltaWriter(${_fields.keys.join(', ')})';
}

/// The stand-in for a current value nobody passed.
///
/// A sentinel and not `null`, because `null` is a value a record legitimately
/// holds: a claim of `null` against a field that is already `null` is a claim
/// worth dropping, and one against a field that is not is a field the reader
/// cleared.
const Object _unstated = Object();

/// Whether two decoded JSON values are the same claim.
///
/// Structural, because the values here are the ones the wire carries: a map and
/// a list compare by what they hold, and two instants compare as instants
/// rather than as the zones they were written in.
bool _same(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }

  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) {
      return false;
    }

    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || !_same(entry.value, b[entry.key])) {
        return false;
      }
    }

    return true;
  }

  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      if (!_same(a[index], b[index])) {
        return false;
      }
    }

    return true;
  }

  if (a is DateTime && b is DateTime) {
    return a.isAtSameMomentAs(b);
  }

  return a == b;
}

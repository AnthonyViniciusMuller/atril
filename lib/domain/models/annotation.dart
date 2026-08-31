/// What the reader wrote in a work, and where they stopped in it.
///
/// The two reconcile differently and C05 is the difference. An annotation can
/// be edited from any of the reader's devices, so two versions of it can be
/// concurrent and the full [Revision] is needed to settle them. A reading
/// position belongs to one device and is written by that device alone, so its
/// versions are totally ordered by that device's own counter and can never
/// conflict — it carries a [Version], which is the same metadata without the
/// two fields that break a tie.
library;

import '../crdt/revision.dart';

/// What kind of mark the reader left.
enum AnnotationKind {
  /// Text the reader wrote, which the contract requires to be present.
  note('note'),

  /// A passage, with text only if it was given one.
  highlight('highlight'),

  /// A position, with no selection.
  bookmark('bookmark');

  const AnnotationKind(this.wireName);

  /// The name the contract and both schemas use.
  final String wireName;

  /// The kind [name] spells, or `null` for one this build cannot name.
  static AnnotationKind? parse(String name) {
    for (final kind in AnnotationKind.values) {
      if (kind.wireName == name) {
        return kind;
      }
    }

    return null;
  }

  @override
  String toString() => wireName;
}

/// Something the reader wrote, and the passage it is attached to.
final class Annotation {
  /// The mark, as a replica holds it.
  const Annotation({
    required this.id,
    required this.ebookId,
    required this.kind,
    required this.locator,
    required this.revision,
    this.text,
  });

  /// The identifier the device that made the mark minted.
  final String id;

  /// The work it is in. A mark is made in a work and stays in it.
  final String ebookId;

  /// Which kind of mark, or `null` for one this build cannot name.
  final AnnotationKind? kind;

  /// Required for a note, which is otherwise an empty note; optional on the
  /// other two.
  final String? text;

  /// The passage, expressed so that it survives the format: a CFI in an EPUB,
  /// a page in a PDF.
  ///
  /// It is replicated to the reader's other devices, which is the whole reason
  /// there is one EPUB engine across the six targets: two CFI implementations
  /// would disagree here, and the disagreement would arrive as a highlight on
  /// the wrong paragraph.
  final String locator;

  /// The replication metadata.
  final Revision revision;

  @override
  String toString() => 'Annotation($id, $kind in $ebookId)';
}

/// Where one device stopped in one work.
final class ReadingProgress {
  /// The position, as a replica holds it.
  const ReadingProgress({
    required this.ebookId,
    required this.deviceId,
    required this.locator,
    required this.version,
    this.percent,
  });

  /// The work.
  final String ebookId;

  /// The device the position belongs to, and half of the row's natural key
  /// (C18). It is not a tie-break: nothing ever ties.
  final String deviceId;

  /// Where the reader stopped, in the same form an annotation is anchored by.
  final String locator;

  /// How far through, 0 to 100.
  ///
  /// Derived from [locator] and carried anyway, so that a client can show
  /// progress without resolving a position it may not be able to interpret: a
  /// device that cannot open a DjVu can still report that the reader is 40%
  /// through it.
  final double? percent;

  /// The clock and the instant, without the two tie-break fields a record with
  /// one writer can never need.
  final Version version;

  @override
  String toString() => 'ReadingProgress($ebookId on $deviceId)';
}

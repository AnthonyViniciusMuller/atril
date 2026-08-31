/// The reading half of the contract, as domain values: what the reader wrote
/// in a work, and where they stopped in it.
///
/// It maps in one direction, as the library mapper does and for the same
/// reason: both entities replicate, so every change to one is authored as an
/// operation and pushed rather than sent as a record.
library;

import '../../domain/models/annotation.dart';
import '../services/api/generated/quire/v1/reading.pb.dart' as pb;
import 'mapping.dart';

/// The kinds of mark, by the name the contract's enum spells them with.
const Map<String, AnnotationKind> annotationKindsByWireName =
    <String, AnnotationKind>{
      'ANNOTATION_KIND_NOTE': AnnotationKind.note,
      'ANNOTATION_KIND_HIGHLIGHT': AnnotationKind.highlight,
      'ANNOTATION_KIND_BOOKMARK': AnnotationKind.bookmark,
    };

/// Something the reader wrote.
Annotation annotationOf(pb.Annotation annotation) => Annotation(
  id: annotation.id.toLowerCase(),
  ebookId: annotation.ebookId.toLowerCase(),
  kind: annotationKindsByWireName[annotation.kind.name],
  text: annotation.hasText() ? annotation.text : null,
  locator: annotation.locator,
  revision: revisionOf(annotation.revision),
);

/// Where one device stopped in one work.
///
/// It carries a [Version] and not a [Revision], and the two dropped fields are
/// the two that break a tie: a row whose only writer is the device it names
/// can never have one (C05). A mapper that filled them in with something
/// plausible would be inviting the reconciler to apply a rule where nothing
/// ties.
ReadingProgress progressOf(pb.ReadingProgress progress) => ReadingProgress(
  ebookId: progress.ebookId.toLowerCase(),
  deviceId: progress.deviceId.toLowerCase(),
  locator: progress.locator,
  percent: progress.hasPercent() ? progress.percent : null,
  version: versionOf(progress.vectorClock, progress.updatedAt),
);

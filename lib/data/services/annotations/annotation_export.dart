/// What the reader has marked, as a file they can take away.
///
/// **It is here because a sovereignty argument that cannot get the data out of
/// the app is an argument with a hole in it.** The whole of Quire's case is
/// that the reader's library is theirs and lives on a node they chose; a client
/// whose only way out is that node's API would have moved the lock rather than
/// removed it. So this writes two files, and the choice between them is the
/// choice between a reader and a program.
///
/// **Markdown is for a person and JSON is for a program, and they are spelled
/// accordingly.** The Markdown carries the words in the order a reader would
/// read them and says nothing about identifiers. The JSON carries the record —
/// with the contract's own field names, `ebook_id` and `locator` and `kind`,
/// spelled exactly as `delta.dart`, the node's schema and this device's all
/// spell them. That is the same argument the delta vocabulary makes: one set of
/// names travels everywhere, and a second one would have to be translated at
/// every hop. An export that invented `bookId` would be an export nothing this
/// project ships could read back.
///
/// **The Markdown's own words are given to it and not written here.** A file a
/// reader opens is user-visible text, so *Highlight* and *Note* and the date
/// come from the ARB through [ExportWords]; what stays in this file is the
/// structure. The JSON's keys are the opposite case and are deliberately never
/// translated: they are a wire vocabulary, and a program reading a file whose
/// keys depend on the exporter's locale could not read it at all.
library;

import 'dart:convert';

import '../../../domain/models/annotation.dart';
import '../sync/delta.dart';

/// The two shapes an export takes.
enum ExportFormat {
  /// For a person: headings, quotes and the words in reading order.
  markdown('md', 'text/markdown'),

  /// For a program: the record, under the contract's own field names.
  json('json', 'application/json');

  const ExportFormat(this.extension, this.mediaType);

  /// The extension the file is named with, which is the only thing that tells
  /// a system what it holds.
  final String extension;

  /// What a share sheet routes on.
  final String mediaType;
}

/// The words the Markdown export needs, which come from the ARB.
///
/// It is a parameter and not a set of literals in this file because an export
/// is something a reader opens: *Grifo* is as user-visible as a button. The
/// call site is a view model, which is where a localization lives in this app.
final class ExportWords {
  /// The words, and how a date is written.
  const ExportWords({
    required this.title,
    required this.exportedAt,
    required this.highlight,
    required this.note,
    required this.bookmark,
    required this.unknownKind,
    required this.dateOf,
  });

  /// The heading the file opens with.
  final String title;

  /// The line under it, already carrying the date.
  final String exportedAt;

  /// What each kind of mark is called.
  final String highlight;
  final String note;
  final String bookmark;

  /// What a kind this build cannot name is called.
  final String unknownKind;

  /// How an instant is written for a reader.
  final String Function(DateTime at) dateOf;

  /// What [kind] is called.
  String nameOf(AnnotationKind? kind) => switch (kind) {
    AnnotationKind.highlight => highlight,
    AnnotationKind.note => note,
    AnnotationKind.bookmark => bookmark,
    null => unknownKind,
  };
}

/// The name a file of [format] is suggested under.
///
/// It is a fixed stem and not the date or the book's title, and both are
/// deliberate: a title becomes a filename with a colon in it on the one system
/// that refuses those, and a reader saving twice is better served by their own
/// file manager asking than by two files they have to tell apart later.
String exportFileName(ExportFormat format) => 'atril-marks.${format.extension}';

/// [marks] as the bytes of a file in [format].
List<int> exportBytes(
  List<MarkedPassage> marks, {
  required ExportFormat format,
  required ExportWords words,
  required DateTime at,
}) => utf8.encode(switch (format) {
  ExportFormat.markdown => markdownOf(marks, words),
  ExportFormat.json => jsonOf(marks, at: at),
});

/// [marks] as Markdown, grouped by the work each is in.
///
/// The grouping preserves the order the marks arrived in, which is the order
/// the repository answers with — most recent first — and it does not reorder
/// within a book. Reading order would be the reader's expectation and it is
/// unreachable without comparing two CFIs, which is the one thing
/// `architecture.md` forbids outright.
String markdownOf(List<MarkedPassage> marks, ExportWords words) {
  final StringBuffer out = StringBuffer()
    ..writeln('# ${words.title}')
    ..writeln()
    ..writeln('_${words.exportedAt}_');

  String? current;

  for (final MarkedPassage passage in marks) {
    if (passage.work.id != current) {
      current = passage.work.id;
      out
        ..writeln()
        ..writeln('## ${passage.work.title}');
    }

    final Annotation mark = passage.mark;

    out
      ..writeln()
      ..writeln(
        '### ${words.nameOf(mark.kind)} — '
        '${words.dateOf(mark.revision.updatedAt.toLocal())}',
      )
      ..writeln();

    if (mark.text case final String said) {
      // A highlight's text is the book's words and a note's are the reader's,
      // and the file says which by how it sets them: a quotation for the
      // passage, plain prose for what somebody wrote about it.
      final String prefix = mark.kind == AnnotationKind.highlight ? '> ' : '';

      for (final String line in said.split('\n')) {
        out.writeln('$prefix$line');
      }

      out.writeln();
    }

    // The locator, so that the file is not only readable but *resolvable*: it
    // is what any client of this contract — this one included — opens the book
    // at, and an export that dropped it would be a quotation with no citation.
    out.writeln('`${mark.locator}`');
  }

  return out.toString();
}

/// [marks] as JSON, under the contract's own field names.
String jsonOf(
  List<MarkedPassage> marks, {
  required DateTime at,
}) => const JsonEncoder.withIndent('  ').convert(<String, Object?>{
  'exported_at': at.toUtc().toIso8601String(),
  'annotations': <Map<String, Object?>>[
    for (final MarkedPassage passage in marks)
      <String, Object?>{
        'id': passage.mark.id,
        fieldEbookId: passage.mark.ebookId,
        // Not a field of the record and named apart from those that are:
        // it is the one thing a reader opening this file needs and cannot
        // resolve from an identifier alone.
        'ebook_title': passage.work.title,
        fieldKind: passage.mark.kind?.wireName,
        fieldLocator: passage.mark.locator,
        fieldText: passage.mark.text,
        'updated_at': passage.mark.revision.updatedAt.toUtc().toIso8601String(),
      },
  ],
});

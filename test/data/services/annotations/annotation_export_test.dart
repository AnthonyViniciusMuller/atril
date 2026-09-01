/// The two files a reader can take their marks away in.
///
/// The argument this pins is the one the phase's last commit exists for: a
/// sovereignty claim that cannot get the data out of the app is a claim with a
/// hole in it. So there are two assertions that matter more than the layout —
/// **the JSON carries the contract's own field names**, so that what comes out
/// of this app is readable by anything that speaks the same contract, and
/// **every mark carries its locator**, so that the file is resolvable and not
/// merely readable.
library;

import 'dart:convert';

import 'package:atril/data/services/annotations/annotation_export.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime.utc(2026, 9, 1, 12);

const String _range = 'epubcfi(/6/14[chap05ref]!/4[body01]/10,/2/1:1,/3:4)';

/// The words, in the shape a view model reads them out of the ARB.
final ExportWords _words = ExportWords(
  title: 'Marcações',
  exportedAt: 'Exportado do Atril em 1 de setembro de 2026',
  highlight: 'Grifo',
  note: 'Nota',
  bookmark: 'Marcador de página',
  unknownKind: 'Marcação',
  dateOf: (DateTime at) => '1 de setembro de 2026',
);

Ebook _work({required String id, required String title}) => Ebook(
  id: id,
  title: title,
  format: EbookFormat.epub,
  contentHash: '0' * 64,
  importedAt: _at,
  revision: Revision.first('device', _at),
);

MarkedPassage _passage({
  required String id,
  required Ebook work,
  AnnotationKind kind = AnnotationKind.highlight,
  String? text,
  String locator = _range,
}) => MarkedPassage(
  mark: Annotation(
    id: id,
    ebookId: work.id,
    kind: kind,
    text: text,
    locator: locator,
    revision: Revision.first('device', _at),
  ),
  work: work,
);

void main() {
  final Ebook sertoes = _work(id: 'a', title: 'Os Sertões');
  final Ebook veredas = _work(id: 'b', title: 'Grande Sertão: Veredas');

  group('the file for a person', () {
    test('groups the marks under the book each is in', () {
      final String out = markdownOf(<MarkedPassage>[
        _passage(id: '1', work: sertoes, text: 'A terra é ingrata.'),
        _passage(id: '2', work: sertoes, text: 'O sertão é sem fim.'),
        _passage(id: '3', work: veredas, text: 'Nonada.'),
      ], _words);

      expect(out, contains('# Marcações'));
      expect('## Os Sertões'.allMatches(out), hasLength(1));
      expect('## Grande Sertão: Veredas'.allMatches(out), hasLength(1));
      // The second mark in the first book does not start a second heading.
      expect(
        out.indexOf('O sertão é sem fim.'),
        lessThan(out.indexOf('## Grande Sertão: Veredas')),
      );
    });

    test('quotes a passage and does not quote what a reader wrote', () {
      // A highlight's text is the book's words and a note's are the reader's,
      // and the file says which by how it sets them.
      final String out = markdownOf(<MarkedPassage>[
        _passage(id: '1', work: sertoes, text: 'A terra é ingrata.'),
        _passage(
          id: '2',
          work: sertoes,
          kind: AnnotationKind.note,
          text: 'A seca é personagem.',
        ),
      ], _words);

      expect(out, contains('> A terra é ingrata.'));
      expect(out, contains('\nA seca é personagem.'));
      expect(out, isNot(contains('> A seca é personagem.')));
    });

    test('carries the locator of every mark', () {
      // What makes the file resolvable and not merely readable: it is what any
      // client of this contract opens the book at, and an export that dropped
      // it would be a quotation with no citation.
      final String out = markdownOf(<MarkedPassage>[
        _passage(id: '1', work: sertoes, kind: AnnotationKind.bookmark),
      ], _words);

      expect(out, contains('`$_range`'));
      expect(out, contains('Marcador de página'));
    });

    test('takes its words from the caller and not from this file', () {
      // An export is something a reader opens, so its words are as
      // user-visible as a button and belong in the ARB.
      final String out = markdownOf(<MarkedPassage>[
        _passage(id: '1', work: sertoes, kind: AnnotationKind.note, text: 'x'),
      ], _words);

      expect(out, contains('Nota'));
      expect(out, isNot(contains('Note')));
    });
  });

  group('the file for a program', () {
    test('spells its fields the way the contract does', () {
      // The delta vocabulary's argument, applied one hop further out: one set
      // of names travels through the contract, the node's schema and this
      // device's, and an export that invented `bookId` would be one nothing
      // this project ships could read back.
      final Map<String, Object?> out = jsonDecode(
        jsonOf(<MarkedPassage>[
          _passage(id: '1', work: sertoes, text: 'A terra é ingrata.'),
        ], at: _at),
      ) as Map<String, Object?>;

      final Map<String, Object?> mark =
          (out['annotations']! as List<Object?>).single as Map<String, Object?>;

      expect(mark.keys, containsAll(<String>['ebook_id', 'kind', 'locator']));
      expect(mark['ebook_id'], 'a');
      expect(mark['kind'], 'highlight');
      expect(mark['locator'], _range);
      expect(mark['text'], 'A terra é ingrata.');
      expect(mark['ebook_title'], 'Os Sertões');
    });

    test('says when it was written, in UTC', () {
      final Map<String, Object?> out = jsonDecode(
        jsonOf(const <MarkedPassage>[], at: _at),
      ) as Map<String, Object?>;

      expect(out['exported_at'], '2026-09-01T12:00:00.000Z');
      expect(out['annotations'], isEmpty);
    });

    test('leaves a mark with nothing to say saying nothing', () {
      final Map<String, Object?> out = jsonDecode(
        jsonOf(<MarkedPassage>[
          _passage(id: '1', work: sertoes, kind: AnnotationKind.bookmark),
        ], at: _at),
      ) as Map<String, Object?>;

      final Map<String, Object?> mark =
          (out['annotations']! as List<Object?>).single as Map<String, Object?>;

      expect(mark['text'], isNull);
      expect(mark['kind'], 'bookmark');
    });
  });

  test('the file is named by its format and by nothing else', () {
    // Not the date and not the book's title: a title becomes a filename with a
    // colon in it on the one system that refuses those, and a reader saving
    // twice is better served by their own file manager asking.
    expect(exportFileName(ExportFormat.markdown), 'atril-marks.md');
    expect(exportFileName(ExportFormat.json), 'atril-marks.json');
    expect(ExportFormat.json.mediaType, 'application/json');
  });

  test('the bytes are utf-8, whichever format they are', () {
    // The one thing both files must agree on: a reader whose marks are in
    // Portuguese has a file full of characters above the ASCII range.
    for (final ExportFormat format in ExportFormat.values) {
      final List<int> bytes = exportBytes(
        <MarkedPassage>[
          _passage(id: '1', work: sertoes, text: 'A terra é ingrata.'),
        ],
        format: format,
        words: _words,
        at: _at,
      );

      expect(utf8.decode(bytes), contains('A terra é ingrata.'));
    }
  });
}

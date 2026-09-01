/// What an EPUB says about itself, read out of a file built here.
///
/// The archives are assembled in the test rather than committed as fixtures,
/// because what is being checked is a *shape* — an OPF somewhere other than
/// the root, a cover declared the way EPUB 2 declared them, a `dc:creator`
/// bound to an unconventional prefix — and a shape is clearer as three lines
/// of XML above the assertion than as a binary nobody can read in a diff.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:atril/data/services/epub/epub_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bytes of a one-pixel image, which is a cover as far as this app cares.
final Uint8List _image = Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10]);

/// An EPUB holding [files], zipped.
Uint8List epubOf(Map<String, Object> files) {
  final archive = Archive();

  for (final entry in files.entries) {
    final bytes = entry.value is String
        ? utf8.encode(entry.value as String)
        : entry.value as Uint8List;

    archive.add(ArchiveFile.bytes(entry.key, bytes));
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// The container document, pointing at [opfPath].
String containerFor(String opfPath) =>
    '<?xml version="1.0"?>'
    '<container version="1.0" '
    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
    '<rootfiles><rootfile full-path="$opfPath" '
    'media-type="application/oebps-package+xml"/></rootfiles></container>';

/// A package document carrying [metadata], and [manifest] if there is any.
String opfWith(String metadata, {String manifest = ''}) =>
    '<?xml version="1.0"?>'
    '<package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
    '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
    '$metadata'
    '</metadata>'
    '<manifest>$manifest</manifest>'
    '</package>';

void main() {
  group('the package document', () {
    test('is found wherever the container says it is', () {
      // An OPF under a directory of the publisher's choosing is an ordinary
      // EPUB. Guessing `content.opf` at the root reads most files and none of
      // the ones that matter.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('OEBPS/Um Livro/pacote.opf'),
        'OEBPS/Um Livro/pacote.opf': opfWith(
          '<dc:title>Vidas Secas</dc:title>',
        ),
      });

      expect(readEpubMetadata(epub)?.title, 'Vidas Secas');
    });

    test('is read whatever prefix Dublin Core was bound to', () {
      // The namespace is what identifies the element; `dc:` is a convention.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf':
            '<?xml version="1.0"?>'
            '<package xmlns="http://www.idpf.org/2007/opf" version="2.0">'
            '<metadata xmlns:x="http://purl.org/dc/elements/1.1/">'
            '<x:title>Os Sertões</x:title>'
            '</metadata></package>',
      });

      expect(readEpubMetadata(epub)?.title, 'Os Sertões');
    });

    test('reads the fields the contract names', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Grande Sertão: Veredas</dc:title>'
          '<dc:creator>João Guimarães Rosa</dc:creator>'
          '<dc:publisher>José Olympio</dc:publisher>'
          '<dc:language>pt-BR</dc:language>',
        ),
      });

      final metadata = readEpubMetadata(epub)!;

      expect(metadata.title, 'Grande Sertão: Veredas');
      expect(metadata.author, 'João Guimarães Rosa');
      expect(metadata.publisher, 'José Olympio');
      expect(metadata.language, 'pt-BR');
    });
  });

  group('what the file did not say', () {
    test('is absent and never empty', () {
      // A work whose author is unknown and one whose author is the empty
      // string are different claims, and only the first one is true here.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith('<dc:title>Anônimo</dc:title>'),
      });

      final metadata = readEpubMetadata(epub)!;

      expect(metadata.author, isNull);
      expect(metadata.publisher, isNull);
      expect(metadata.language, isNull);
    });

    test('is absent when the element is there and holds nothing', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Anônimo</dc:title><dc:creator>   </dc:creator>',
        ),
      });

      expect(readEpubMetadata(epub)?.author, isNull);
    });
  });

  group('the extra metadata', () {
    test('carries the subjects, the series and the other authors', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Os Sertões</dc:title>'
          '<dc:creator>Euclides da Cunha</dc:creator>'
          '<dc:creator>Walnice Nogueira Galvão</dc:creator>'
          '<dc:subject>Canudos</dc:subject>'
          '<dc:subject>Sertão</dc:subject>'
          '<meta name="calibre:series" content="Clássicos"/>'
          '<meta name="calibre:series_index" content="3"/>',
        ),
      });

      final metadata = readEpubMetadata(epub)!;

      // The column holds one author, so the rest are kept rather than joined
      // into a name nobody has.
      expect(metadata.author, 'Euclides da Cunha');
      expect(metadata.extra['contributors'], <String>[
        'Walnice Nogueira Galvão',
      ]);
      expect(metadata.extra['subjects'], <String>['Canudos', 'Sertão']);
      expect(metadata.extra['series'], 'Clássicos');
      expect(metadata.extra['series_index'], 3.0);
    });

    test('takes an identifier that is an ISBN and leaves the rest', () {
      // A dc:identifier is whatever scheme the publisher chose, and filing a
      // UUID under `isbn` would be recording something the file did not say.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Um</dc:title>'
          '<dc:identifier>urn:uuid:0d9a6f4c-3f6a-4a1e-9a56-1f2e3d4c5b6a</dc:identifier>'
          '<dc:identifier>urn:isbn:9788535902778</dc:identifier>',
        ),
      });

      expect(readEpubMetadata(epub)?.extra['isbn'], '9788535902778');
    });

    test('is empty when the file carried nothing beyond the contract', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith('<dc:title>Um</dc:title>'),
      });

      expect(readEpubMetadata(epub)?.extra, isEmpty);
    });
  });

  group('the cover', () {
    test('is found the way EPUB 3 declares one', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('OEBPS/content.opf'),
        'OEBPS/content.opf': opfWith(
          '<dc:title>Um</dc:title>',
          manifest:
              '<item id="capa" href="images/capa.png" '
              'media-type="image/png" properties="cover-image"/>',
        ),
        'OEBPS/images/capa.png': _image,
      });

      final cover = readEpubMetadata(epub)?.cover;

      expect(cover?.mediaType, 'image/png');
      expect(cover?.bytes, _image);
    });

    test('is found the way EPUB 2 declared one', () {
      // There is no `cover-image` property before EPUB 3, and the convention
      // that won was a meta element naming the manifest item by its id. Both
      // versions are in every reader's library.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Um</dc:title><meta name="cover" content="capa"/>',
          manifest:
              '<item id="capa" href="capa.jpg" media-type="image/jpeg"/>',
        ),
        'capa.jpg': _image,
      });

      expect(readEpubMetadata(epub)?.cover?.mediaType, 'image/jpeg');
    });

    test('resolves its path against the package document', () {
      // The mistake this is about produces a cover for the files whose OPF
      // happens to sit at the top level, and none for anybody else's.
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('OEBPS/content.opf'),
        'OEBPS/content.opf': opfWith(
          '<dc:title>Um</dc:title>',
          manifest:
              '<item id="c" href="../images/capa.png" '
              'media-type="image/png" properties="cover-image"/>',
        ),
        'images/capa.png': _image,
      });

      expect(readEpubMetadata(epub)?.cover?.bytes, _image);
    });

    test('is absent when the manifest points at nothing', () {
      final epub = epubOf(<String, Object>{
        containerPath: containerFor('content.opf'),
        'content.opf': opfWith(
          '<dc:title>Um</dc:title>',
          manifest:
              '<item id="c" href="capa.png" media-type="image/png" '
              'properties="cover-image"/>',
        ),
      });

      expect(readEpubMetadata(epub)?.cover, isNull);
      expect(readEpubMetadata(epub)?.title, 'Um');
    });
  });

  group('a file this app cannot read', () {
    test('is described as nothing rather than refused', () {
      // Every one of these is the same answer: the work is imported under its
      // file name and the reader renames it. Refusing to take a book into the
      // library because a publisher wrote bad XML is the library's problem.
      expect(readEpubMetadata(Uint8List.fromList(<int>[1, 2, 3])), isNull);
      expect(
        readEpubMetadata(epubOf(<String, Object>{'mimetype': 'x'})),
        isNull,
      );
      expect(
        readEpubMetadata(
          epubOf(<String, Object>{containerPath: '<not xml'}),
        ),
        isNull,
      );
      expect(
        readEpubMetadata(
          epubOf(<String, Object>{
            containerPath: containerFor('content.opf'),
            'content.opf': '<package>',
          }),
        ),
        isNull,
      );
    });
  });
}

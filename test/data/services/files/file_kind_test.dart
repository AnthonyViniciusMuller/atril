/// What a file's name says it is, and what it agrees with.
library;

import 'package:atril/data/services/files/file_kind.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the guess', () {
    test('names every format UC02 admits', () {
      // A format the contract has and this table has not is a file the reader
      // is told cannot be imported, with no message anywhere saying why.
      for (final format in EbookFormat.values) {
        expect(
          describeFile('book.${format.wireName}')?.format,
          format,
          reason: 'the table does not know ${format.wireName}',
        );
      }
    });

    test('agrees with the reference client on every media type', () {
      // `internal/client`'s own `describe` is this table. The two have to
      // match: a work imported through that client and the same file imported
      // here must reach the node describing themselves the same way, or one of
      // them is a second stored object under a second media type.
      expect(mediaTypes, <EbookFormat, String>{
        EbookFormat.epub: 'application/epub+zip',
        EbookFormat.pdf: 'application/pdf',
        EbookFormat.mobi: 'application/x-mobipocket-ebook',
        EbookFormat.djvu: 'image/vnd.djvu',
        EbookFormat.cbz: 'application/vnd.comicbook+zip',
      });
    });

    test('does not care how the extension was capitalized', () {
      expect(describeFile('Os Sertões.EPUB')?.format, EbookFormat.epub);
    });

    test('reads the last extension and not the first', () {
      // A half-downloaded file is exactly the case where trusting the wrong
      // dot stores something under a name that lies about it.
      expect(describeFile('livro.epub.part'), isNull);
    });

    test('places nothing when there is no extension at all', () {
      expect(describeFile('livro'), isNull);
      expect(describeFile('livro.'), isNull);
    });
  });

  group('the title of last resort', () {
    test('is the name without its extension', () {
      expect(
        titleFromFileName('Grande Sertão: Veredas.epub'),
        'Grande Sertão: Veredas',
      );
    });

    test('keeps a name that is nothing but an extension', () {
      // A work always has a title — the column and the contract both refuse
      // one without — so a stem that came out empty falls back to the whole
      // name rather than to nothing.
      expect(titleFromFileName('.epub'), '.epub');
    });
  });
}

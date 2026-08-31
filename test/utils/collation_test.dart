import 'package:atril/utils/collation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the fold', () {
    test('knows every letter it claims to', () {
      // The table is two literals — the accented letters and what each folds
      // onto — and the one mistake that shape invites is a line that got one
      // letter out of step. A map built from mismatched halves would silently
      // fold half the alphabet onto the wrong letter, and every test below
      // would still pass on the half it covered.
      expect(foldedLetterCount, 89);
    });

    test('puts a Portuguese title where a reader would look for it', () {
      final shelf = <String>['Serviço', 'Sertão', 'Sermão'];

      shelf.sort(compareFolded);

      expect(shelf, <String>['Sermão', 'Sertão', 'Serviço']);
    });

    test('does not sort the accented letters after the alphabet', () {
      // The failure this is about: under a comparison of code units `Á` is
      // U+00C1 and sorts after `z`, so every author whose name carries an
      // accent lands in a clump at the end of the list.
      final authors = <String>['Zweig', 'Álvares de Azevedo', 'Machado'];

      authors.sort(compareFolded);

      expect(authors.first, 'Álvares de Azevedo');
      expect(authors.last, 'Zweig');
    });

    test('orders two spellings of one word rather than calling them equal', () {
      // They fold onto the same key, and a comparison that answered zero would
      // leave their order to whichever row the database returned first — which
      // is a list that changes under the reader between two identical queries.
      expect(compareFolded('Sertao', 'Sertão'), isNot(0));
      expect(
        compareFolded('Sertao', 'Sertão'),
        -compareFolded('Sertão', 'Sertao'),
      );
    });

    test('collapses the whitespace a title was typed with', () {
      expect(foldForComparison('  Grande   Sertão  '), 'grande sertao');
    });

    test('spells out the three letters that are two', () {
      expect(foldForComparison('Æsop'), 'aesop');
      expect(foldForComparison('Œuvres'), 'oeuvres');
      expect(foldForComparison('Straße'), 'strasse');
    });

    test('leaves a character it does not know alone', () {
      // A worse answer than a real collator would give, and not a wrong one:
      // the character still sorts consistently and still matches itself.
      expect(foldForComparison('東京'), '東京');
    });
  });

  group('a search', () {
    test('finds a word the reader typed without its accents', () {
      expect(containsFolded('Grande Sertão: Veredas', 'sertao'), isTrue);
    });

    test('finds a word the reader typed with them', () {
      expect(containsFolded('Grande Sertao: Veredas', 'sertão'), isTrue);
    });

    test('does not find what is not there', () {
      expect(containsFolded('Grande Sertão: Veredas', 'capitu'), isFalse);
    });
  });
}

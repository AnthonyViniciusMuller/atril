/// Comparing text the way a reader of this app's language would.
///
/// Sorting a shelf and searching it are the same question asked twice, and
/// both are asked about Portuguese. *Sertão* has to sit between *Sermão* and
/// *Serviço*, and a reader who types `sertao` has to find it — neither of
/// which happens under a comparison of code units, where `ã` (U+00E3) sorts
/// after every unaccented letter and matches nothing but itself.
///
/// **It is done here and not in SQL.** sqlite ships three collations and all
/// three are ASCII: `NOCASE` folds `A` onto `a` and leaves `Á` alone, so an
/// index built on it would order this app's own language wrongly and there
/// would be nothing on the screen to say why. A custom collation registered
/// into the connection would fix the five native targets and not the sixth,
/// where the database is a WebAssembly build — and a library that sorted
/// differently in a browser is exactly the kind of per-platform difference
/// `architecture.md` spends its conditional exports avoiding. The collection
/// is one reader's and is read into memory to be shown anyway, so the
/// comparison costs a fold per row and buys one behaviour on six targets.
///
/// The fold is deliberately not a full Unicode collation. It is the subset
/// that Portuguese, Spanish, French, German and the other Latin-script
/// languages a reader's library is likely to mix actually use, and a character
/// it does not know is left as it is rather than dropped: an unfolded
/// character still sorts consistently and still matches itself, which is a
/// worse answer than a collator would give and not a wrong one.
library;

/// The letters this fold knows, and what each one folds onto.
///
/// Written as two strings rather than a map so that a reader can see the
/// correspondence, and checked in a test that they are the same length —
/// which is the one mistake this shape invites.
const String _accented =
    'àáâãäåāăąçćĉċčďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıĵķĺļľłñńņňòóôõöøōŏőŕŗř'
    'śŝşšţťŧùúûüũūŭůűųŵýÿŷźżžæœß';

/// What each character of [_accented] folds onto, in the same order.
///
/// `æ`, `œ` and `ß` are the three that are not one character: they fold onto
/// the pairs a reader spells them out as, which is why the table below is
/// applied per character rather than as a translation of equal length.
const List<String> _folded = <String>[
  'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', //
  'c', 'c', 'c', 'c', 'c', //
  'd', 'd', //
  'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', //
  'g', 'g', 'g', 'g', //
  'h', 'h', //
  'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', //
  'j', //
  'k', //
  'l', 'l', 'l', 'l', //
  'n', 'n', 'n', 'n', //
  'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', //
  'r', 'r', 'r', //
  's', 's', 's', 's', //
  't', 't', 't', //
  'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', //
  'w', //
  'y', 'y', 'y', //
  'z', 'z', 'z', //
  'ae', 'oe', 'ss', //
];

/// [_accented] and [_folded], as the map the fold actually reads.
final Map<String, String> _foldings = <String, String>{
  for (var index = 0; index < _accented.length; index++)
    _accented[index]: _folded[index],
};

/// How many letters the fold knows, for the test that checks the two halves of
/// the table line up.
int get foldedLetterCount => _foldings.length;

/// [text] as the key it sorts and matches under.
///
/// Lower case, without the marks above the letters, and with runs of
/// whitespace collapsed so that a title typed with two spaces sorts where the
/// reader expects. Everything else is left alone: punctuation is part of a
/// title and a subtitle after a colon is still the same work.
String foldForComparison(String text) {
  final folded = StringBuffer();

  for (final character in text.toLowerCase().split('')) {
    folded.write(_foldings[character] ?? character);
  }

  return folded.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Compares [a] and [b] as a reader would expect to find them on a shelf.
///
/// Ties on the folded key fall back to the text itself, so that two titles
/// differing only in their accents have an order at all rather than one
/// decided by which row the database happened to return first — a list whose
/// order changes between two builds of the same query is a list that jumps
/// under the reader's finger.
int compareFolded(String a, String b) {
  final folded = foldForComparison(a).compareTo(foldForComparison(b));

  return folded != 0 ? folded : a.compareTo(b);
}

/// Whether [text] contains [term], both folded.
///
/// It is the search of the last commit of this phase, and it is here rather
/// than beside it because a search that matched differently from the way the
/// results are sorted would be two answers to one question.
bool containsFolded(String text, String term) =>
    foldForComparison(text).contains(foldForComparison(term));

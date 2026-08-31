/// The four constraints the contract publishes, checked on this side.
///
/// They are checked here as well as on the node, and the reason is not
/// distrust: a reader who typed a capital letter into a local name should be
/// told so by the field they typed it into, and not by a round trip. The node
/// stays the only authority on a name being *taken*, which is a fact about
/// other readers that this device cannot know.
library;

import 'package:atril/domain/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the local name', () {
    test('is folded to the form uniqueness is decided on', () {
      // `@Ana` and `@ana` differ only in how they were typed, while RN09 is
      // over the stored value: accepting both would hand the second reader the
      // account the first believes is theirs.
      expect(canonicalLocalName('  Ana  '), 'ana');
    });

    test('admits letters, digits and the three separators between them', () {
      expect(localNameViolation('ana'), isNull);
      expect(localNameViolation('a'), isNull);
      expect(localNameViolation('ana.maria_2-b'), isNull);
      expect(localNameViolation('a' * maxLocalNameLength), isNull);
    });

    test('refuses what a url, a jwt or a lookup would have to escape', () {
      expect(localNameViolation(''), isNotNull);
      expect(localNameViolation('Ana'), isNotNull);
      expect(localNameViolation('ana maria'), isNotNull);
      expect(localNameViolation('ana@quire.example'), isNotNull);
      expect(localNameViolation('.ana'), isNotNull);
      expect(localNameViolation('ana.'), isNotNull);
      expect(localNameViolation('a' * (maxLocalNameLength + 1)), isNotNull);
    });
  });

  group('the display name', () {
    test('is anything that is not blank and fits the column', () {
      expect(displayNameViolation('Ana Maria'), isNull);
      expect(displayNameViolation('田中'), isNull);
      expect(displayNameViolation(''), isNotNull);
      expect(displayNameViolation('a' * (maxDisplayNameLength + 1)), isNotNull);
    });
  });

  group('the address', () {
    test('is something, an at sign, something', () {
      // Deliberately not RFC 5322: an address is proved to exist by sending to
      // it, which UC08 already does, and a stricter pattern would only reject
      // addresses that work.
      expect(emailViolation('ana@quire.example'), isNull);
      expect(emailViolation('ana+livros@quire.example'), isNull);
      expect(emailViolation('ana'), isNotNull);
      expect(emailViolation('@quire.example'), isNotNull);
      expect(emailViolation('ana@'), isNotNull);
      expect(emailViolation('a@b@c'), isNotNull);
    });
  });

  group('the password', () {
    test('has a floor and a ceiling and no composition rule', () {
      expect(passwordViolation('a' * minPasswordLength), isNull);
      expect(passwordViolation('a' * (minPasswordLength - 1)), isNotNull);
      expect(passwordViolation('a' * maxPasswordBytes), isNull);
      expect(passwordViolation('a' * (maxPasswordBytes + 1)), isNotNull);
    });

    test('measures the ceiling in bytes, which is what bcrypt measures', () {
      // Twenty-five accented characters are fifty bytes and fit; forty are
      // eighty and do not.
      expect(passwordViolation('á' * 25), isNull);
      expect(passwordViolation('á' * 40), isNotNull);
    });
  });
}

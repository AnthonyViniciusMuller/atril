/// The identifiers this device mints.
library;

import 'package:atril/utils/identifiers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is a lower-case version-4 uuid in thirty-six characters', () {
    // Thirty-six is what the schema's columns declare and what the node's own
    // identifiers are, so anything else is a row sqlite refuses.
    final id = mintIdentifier();

    expect(id, hasLength(36));
    expect(id, id.toLowerCase());
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
      reason: '$id is not a version-4 uuid',
    );
  });

  test('does not repeat itself', () {
    final minted = <String>{for (var i = 0; i < 2000; i++) mintIdentifier()};

    expect(minted, hasLength(2000));
  });
}

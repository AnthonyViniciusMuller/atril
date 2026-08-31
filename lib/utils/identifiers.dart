/// The identifiers this device mints for records it creates.
///
/// Three of the five replicable entities are addressed across the federation by
/// an identifier one device invented — a work, a grouping and a mark — and two
/// are addressed by a natural key while still carrying a surrogate one that
/// *each replica mints for itself* (C18). Either way something on this side has
/// to produce a name no other device will produce, without asking anybody.
///
/// It is a version-4 UUID over [Random.secure] and not a package, and the
/// reason is proportion rather than principle: what is needed is 122 random
/// bits in the textual shape the schema's `CHECK` and the node's columns both
/// expect, which is this file, and a dependency for it would be a dependency to
/// keep current for sixteen lines. `Random.secure` is the platform's own
/// generator on all six targets — `getrandom` and the like natively, and
/// `crypto.getRandomValues` in a browser — so the entropy is not this file's
/// invention either.
///
/// Collision is not a risk anybody manages here: 122 bits is the same guarantee
/// the node relies on for the identifiers *it* mints, and the schema would
/// refuse a duplicate anyway.
library;

import 'dart:math';

final Random _entropy = Random.secure();

/// A new version-4 UUID, lower case, in the canonical thirty-six characters.
String mintIdentifier() {
  final bytes = List<int>.generate(16, (_) => _entropy.nextInt(256));

  // The version and the variant, which are what make it a v4 rather than
  // sixteen random bytes that happen to be written with hyphens.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = <String>[
    for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

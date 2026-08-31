/// A reader, as their origin server knows them.
///
/// Every field here is answered by exactly one node — the reader's origin
/// server (RN08) — and a node that merely replicates the reader holds the row
/// without an address and without a password (C03). The address is the one
/// field that is personal data rather than identity, which is why it is
/// absent from every reply but the reader's own (RN09).
library;

/// The greatest length `identity.users.local_name` holds.
const int maxLocalNameLength = 64;

/// The greatest length `identity.users.display_name` holds, in characters as
/// PostgreSQL counts a `varchar`.
const int maxDisplayNameLength = 120;

/// The greatest length `identity.users.email` holds.
const int maxEmailLength = 255;

/// The shortest password the node accepts.
///
/// Eight characters, which is what NIST SP 800-63B asks of a memorized secret.
/// It is a floor and not a composition rule: the same document withdrew the
/// requirement for mixed character classes, on the evidence that it pushes
/// people towards predictable substitutions and towards writing the result
/// down.
const int minPasswordLength = 8;

/// The longest password the node accepts, in bytes.
///
/// Seventy-two is where the hashing algorithm shows through: bcrypt takes at
/// most that many bytes and refuses anything longer. It is a byte count and not
/// a character count, because that is what bcrypt measures.
const int maxPasswordBytes = 72;

/// The stable code of a local name that is not one.
const String codeInvalidLocalName = 'invalid_local_name';

/// The stable code of a shown name that is blank or too long.
const String codeInvalidDisplayName = 'invalid_display_name';

/// The stable code of an address the node cannot store or deliver to.
const String codeInvalidEmail = 'invalid_email';

/// The stable code of a password outside the bounds the node accepts.
const String codeInvalidPassword = 'invalid_password';

/// The stable code of a local name that belongs to somebody else here.
const String codeLocalNameTaken = 'local_name_taken';

/// The stable code of an address already registered on this node.
const String codeEmailRegistered = 'email_registered';

/// The local name [typed] means, in the form the node stores.
///
/// Folding is what makes the identifier one identifier. `@Ana` and `@ana`
/// differ only in how they were typed while the uniqueness of RN09 is over the
/// stored value, so accepting both would hand the second reader the account the
/// first believes is theirs. The node folds too; doing it here as well is what
/// registers a reader who capitalizes their own name instead of rejecting them.
String canonicalLocalName(String typed) => typed.trim().toLowerCase();

/// Why [name] is not a local name, or `null` when it is one.
///
/// It is the rule `identity.users_local_name_format` checks, applied on this
/// side so that a reader is told before a request travels. The reason is
/// diagnostic and is never shown: what a form says is chosen from the ARB by
/// the screen, out of the field the violation names.
String? localNameViolation(String name) {
  if (name.isEmpty) {
    return 'it must not be empty';
  }

  if (name.length > maxLocalNameLength) {
    return 'it must be at most $maxLocalNameLength characters long';
  }

  for (var index = 0; index < name.length; index++) {
    final character = name.codeUnitAt(index);

    if (_isAlphanumeric(character)) {
      continue;
    }

    if (!_isLocalNameSeparator(character)) {
      return 'it may contain only lower-case letters, digits, '
          'and the separators . - _';
    }

    // A separator is allowed only between two other characters.
    if (index == 0 || index == name.length - 1) {
      return 'it must start and end with a letter or a digit';
    }
  }

  return null;
}

/// Why [name] is not a usable display name, or `null`.
///
/// The two rules are that it is not blank — which the schema does not check,
/// and which would leave a reader rendered as nothing — and that it fits the
/// column.
String? displayNameViolation(String name) {
  if (name.isEmpty) {
    return 'it must not be empty';
  }

  if (name.runes.length > maxDisplayNameLength) {
    return 'it must be at most $maxDisplayNameLength characters long';
  }

  return null;
}

/// Why [address] is not usable, or `null`.
///
/// Something, an at sign, something, none of it blank — and deliberately not an
/// attempt at RFC 5322. An address is proved to exist by sending to it, which
/// UC08 already does, and a stricter pattern would only reject addresses that
/// work.
String? emailViolation(String address) {
  if (address.runes.length > maxEmailLength) {
    return 'it must be at most $maxEmailLength characters long';
  }

  final at = address.indexOf('@');

  if (at < 0) {
    return 'it must contain an at sign';
  }

  if (at == 0 || at == address.length - 1) {
    return 'it must have something on both sides of the at sign';
  }

  if (address.indexOf('@', at + 1) >= 0) {
    return 'it must contain exactly one at sign';
  }

  return null;
}

/// Why [password] is outside the bounds the node accepts, or `null`.
String? passwordViolation(String password) {
  if (password.length < minPasswordLength) {
    return 'it must be at least $minPasswordLength characters long';
  }

  // The bound bcrypt imposes is over bytes, and a password of accented
  // characters reaches it in fewer of them than one of ASCII.
  if (password.codeUnits.fold<int>(
        0,
        (int sum, int unit) => sum + _bytesOf(unit),
      ) >
      maxPasswordBytes) {
    return 'it must be at most $maxPasswordBytes bytes long';
  }

  return null;
}

bool _isAlphanumeric(int character) =>
    (character >= 0x30 && character <= 0x39) ||
    (character >= 0x61 && character <= 0x7a);

bool _isLocalNameSeparator(int character) =>
    character == 0x2e || character == 0x2d || character == 0x5f;

/// How many bytes [unit] takes in UTF-8, counting a surrogate as two of the
/// four its pair costs.
int _bytesOf(int unit) => switch (unit) {
  < 0x80 => 1,
  < 0x800 => 2,
  _ => 3,
};

/// The reader.
final class User {
  /// The reader, as a node reports them.
  const User({
    required this.id,
    required this.localName,
    required this.displayName,
    required this.originServerDomain,
    required this.federatedId,
    required this.createdAt,
    this.email,
  });

  /// The identifier at the origin node.
  final String id;

  /// The first half of the federated identifier, constrained by the node to
  /// `^[a-z0-9]([a-z0-9._-]{0,62}[a-z0-9])?$`.
  final String localName;

  /// What the reader calls themselves, and the only name meant to be shown.
  final String displayName;

  /// The domain of the node that authenticates this reader.
  final String originServerDomain;

  /// `@local_name:domain`, assembled by the node so that every client renders
  /// the identifier the same way.
  final String federatedId;

  /// When the account was created, on a wall clock.
  final DateTime createdAt;

  /// The address recovery is sent to. Absent unless this reader is the caller.
  final String? email;

  @override
  String toString() => 'User($federatedId)';
}

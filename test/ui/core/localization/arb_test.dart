/// The ARB files, held to each other.
///
/// `flutter gen-l10n` does notice a message that only one language has, and it
/// reports it into `build/l10n-untranslated.json` — which is where it has to
/// go, because the deliberately empty `app_pt.arb` would otherwise print a
/// backlog on every build. That makes the tool's own report the wrong place to
/// enforce this from, so the enforcement is here: a message the English file
/// is missing is a failing test rather than a line in a file nobody opens.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where the ARB files are, as `l10n.yaml` names them.
const String arbDirectory = 'lib/ui/core/localization';

/// The decoded contents of `$arbDirectory/$name`.
Map<String, Object?> arb(String name) =>
    jsonDecode(File('$arbDirectory/$name').readAsStringSync())
        as Map<String, Object?>;

/// The message keys of [resources] — everything that is not an `@`-attribute.
Set<String> messagesOf(Map<String, Object?> resources) =>
    resources.keys.where((String key) => !key.startsWith('@')).toSet();

void main() {
  final template = arb('app_pt_BR.arb');
  final english = arb('app_en.arb');

  test('the template is Brazilian Portuguese', () {
    expect(template['@@locale'], 'pt_BR');
    expect(english['@@locale'], 'en');
    expect(arb('app_pt.arb')['@@locale'], 'pt');
  });

  test('the base Portuguese file is empty on purpose', () {
    // The tool refuses `pt_BR` unless the bare language exists as its
    // fallback, and this app has one Portuguese: what a generic `pt` file
    // would hold is the Brazilian text, which is what an untranslated message
    // already falls back to. Filling it would be maintaining every string
    // twice; this asserts nobody started to.
    expect(messagesOf(arb('app_pt.arb')), isEmpty);
  });

  test('every message is in English too', () {
    expect(
      messagesOf(english),
      messagesOf(template),
      reason: 'app_en.arb and app_pt_BR.arb name different messages',
    );
  });

  test('every message in the template is described', () {
    // `required-resource-attributes` enforces the attribute exists; what it
    // cannot enforce is that the description says anything. The ARB is the
    // only place the *meaning* of a string is written down — a call site shows
    // a getter name and nothing else — so an empty one is worse than none.
    for (final message in messagesOf(template)) {
      final attributes = template['@$message'];

      expect(
        attributes,
        isA<Map<String, Object?>>(),
        reason: '$message carries no @$message',
      );

      final description = (attributes! as Map<String, Object?>)['description'];

      expect(
        description,
        isA<String>().having(
          (String it) => it.trim().length,
          'length',
          greaterThan(20),
        ),
        reason: '$message is not described in a way a translator can use',
      );
    }
  });

  test('the translations are not left as the template', () {
    // A copied ARB whose values were never translated passes every other check
    // here. What is exempt is what is genuinely the same in both languages: a
    // proper noun, and the handful of words Portuguese borrowed unchanged. The
    // set is written out rather than inferred, so that adding to it is a
    // decision somebody made about one message.
    const Set<String> sameInBoth = <String>{
      // The name of the app.
      'appTitle',
      // Portuguese writes it exactly as English does, hyphen included.
      'registerEmailLabel',
    };

    for (final message in messagesOf(template).difference(sameInBoth)) {
      expect(
        english[message],
        isNot(template[message]),
        reason: '$message is the Portuguese string in app_en.arb',
      );
    }
  });
}

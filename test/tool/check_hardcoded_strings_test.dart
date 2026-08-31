/// The checker, checked.
///
/// A rule enforced by a script nobody tested is a rule that is one refactor
/// away from passing everything, and this one would pass silently: a visitor
/// that stopped matching would report nothing, which is what a clean tree
/// looks like. So the fixtures below are written from both sides — what has to
/// be caught, and what has to be left alone.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_hardcoded_strings.dart';

late Directory _directory;

/// The findings of [source], written to a file the checker then reads.
List<Finding> findingsIn(String source) {
  final file = File('${_directory.path}/fixture.dart')
    ..writeAsStringSync(source);

  return checkFile(file);
}

void main() {
  setUp(() => _directory = Directory.systemTemp.createTempSync('atril-l10n'));
  tearDown(() => _directory.deleteSync(recursive: true));

  group('is caught', () {
    test('a widget whose first argument is text', () {
      expect(findingsIn("Widget b() => Text('Biblioteca');"), hasLength(1));
      expect(
        findingsIn("Widget b() => const SelectableText('Anotações');"),
        hasLength(1),
      );
    });

    test('a first argument written after a named one', () {
      // `Text(key: k, 'x')` is legal Dart, and counting positions is what
      // catches it where comparing against the first argument would not.
      expect(
        findingsIn("Widget b() => Text(key: k, 'Configurações');"),
        hasLength(1),
      );
    });

    test('a named argument the framework renders', () {
      expect(
        findingsIn("Widget b() => IconButton(tooltip: 'Importar');"),
        hasLength(1),
      );
      expect(
        findingsIn(
          "Widget b() => TextField(decoration: "
          "InputDecoration(labelText: 'Domínio'));",
        ),
        hasLength(1),
      );
      expect(
        findingsIn("Widget b() => MaterialApp(title: 'Atril');"),
        hasLength(1),
      );
    });

    test('a message split across lines', () {
      expect(
        findingsIn("Widget b() => Text('uma frase '\n    'em duas metades');"),
        hasLength(1),
      );
    });

    test('an interpolation that also carries words', () {
      expect(findingsIn(r"Widget b() => Text('página $n');"), hasLength(1));
    });
  });

  group('is left alone', () {
    test('a literal that is not read by anybody', () {
      expect(findingsIn("final k = Key('library');"), isEmpty);
      expect(findingsIn("final d = Directory('lib/ui');"), isEmpty);
      expect(
        findingsIn("Widget b() => Image.asset('assets/cover.png');"),
        isEmpty,
      );
    });

    test('every positional argument but the first', () {
      expect(findingsIn("void f() => Text('a', 'b');").length, 1);
    });

    test('an empty string and a format', () {
      expect(findingsIn("Widget b() => const Text('');"), isEmpty);
      expect(findingsIn(r"Widget b() => Text('$page/$total');"), isEmpty);
      expect(findingsIn(r"Widget b() => Text('$percent%');"), isEmpty);
    });

    test('a value that is not a literal', () {
      expect(
        findingsIn('Widget b() => Text(l10n.navigationLibrary);'),
        isEmpty,
      );
    });

    test('a literal exempted on its own line or the one above', () {
      expect(
        findingsIn("Widget b() => Text('Atril'); // l10n-ignore a proper noun"),
        isEmpty,
      );
      expect(
        findingsIn(
          '// l10n-ignore a proper noun\n'
          "Widget b() => Text('Atril');",
        ),
        isEmpty,
      );
    });
  });

  test('reports where the literal is', () {
    final findings = findingsIn("Widget b() => Text('oi');");

    expect(findings.single.line, 1);
    expect(findings.single.column, 20);
    expect(findings.single.literal, "'oi'");
  });
}

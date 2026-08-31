/// Fails when a user-visible string is written into a widget instead of into
/// the ARB.
///
/// Dart ships no lint for this, and the rule is one of the few in
/// [`CLAUDE.md`](../CLAUDE.md) that a session can break without noticing: a
/// screen written in an afternoon is in Portuguese either way, and the English
/// build is what discovers the literal — usually after the screen has been
/// copied twice.
///
/// A grep cannot enforce it. `Text('Biblioteca')` and `Key('library')` are the
/// same six characters of context, `Text(\n  'Biblioteca',\n)` matches
/// neither, and `Icon` constants and asset paths are literals that belong
/// where they are. So this parses the file and looks at *where the literal
/// lands*: the first argument of a widget whose first argument is text, or a
/// named argument the framework renders — `tooltip`, `labelText`,
/// `semanticsLabel` and the rest of [_renderedParameters].
///
/// It is deliberately syntactic and unresolved. Resolution would need the
/// whole package analysed for every run, which is seconds rather than
/// milliseconds, and it would buy the one case this cannot see anyway: a
/// literal assigned to a variable first. What it does see is what a screen is
/// actually written with.
///
/// ```
/// dart run tool/check_hardcoded_strings.dart [<directory>...]
/// ```
///
/// An intentional literal is exempted with `// l10n-ignore`, on the line or
/// on the one above it. It should carry a reason.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// The directories checked when none is named on the command line.
///
/// Everything a reader can read is under one of the two. `lib/data` and
/// `lib/domain` are not here and are not an omission: a message in a log
/// record or in an `AppException` is read by whoever is debugging this app,
/// and translating those would make a bug report untranslatable back.
const List<String> defaultRoots = <String>['lib/ui', 'lib/routing'];

/// Paths that are skipped wherever they appear.
const List<String> skippedPaths = <String>['lib/ui/core/localization'];

/// The comment that exempts a literal.
const String ignoreMarker = 'l10n-ignore';

/// Widgets whose first positional argument is the text they display.
const Set<String> _textWidgets = <String>{'Text', 'SelectableText'};

/// Named arguments the framework renders to a reader, or reads aloud.
const Set<String> _renderedParameters = <String>{
  'applicationLegalese',
  'applicationName',
  'barrierLabel',
  'cancelText',
  'confirmText',
  'counterText',
  'errorText',
  'helperText',
  'helpText',
  'hintText',
  'label',
  'labelText',
  'message',
  'prefixText',
  'semanticLabel',
  'semanticsLabel',
  'subtitle',
  'suffixText',
  'title',
  'tooltip',
};

Future<int> main(List<String> arguments) async {
  final named = arguments.isNotEmpty;
  final roots = named ? arguments : defaultRoots;
  final findings = <Finding>[];

  for (final root in roots) {
    final directory = Directory(root);

    if (!directory.existsSync()) {
      // A default root that does not exist yet is a layer this app has not
      // grown, not a mistake: `lib/routing` arrives one commit after this
      // check does. A root somebody named on the command line is different —
      // they meant that one, and checking nothing would look like passing.
      if (named) {
        stderr.writeln('no such directory: $root');

        return exitCode = 2;
      }

      continue;
    }

    for (final file in _dartFilesIn(directory)) {
      findings.addAll(checkFile(file));
    }
  }

  for (final finding in findings) {
    stdout.writeln('${finding.path}:${finding.line}:${finding.column}');
    stdout.writeln('  a user-visible string is hardcoded: ${finding.literal}');
    stdout.writeln('  use AppLocalizations.of(context) — or // $ignoreMarker');
    stdout.writeln();
  }

  if (findings.isEmpty) {
    stdout.writeln('no hardcoded strings under ${roots.join(', ')}');

    return 0;
  }

  final count = findings.length;
  stdout.writeln('$count hardcoded string${count == 1 ? '' : 's'}');

  return exitCode = 1;
}

/// Every `.dart` file under [directory], in a stable order, skipping the
/// generated localizations and anything else in [skippedPaths].
List<File> _dartFilesIn(Directory directory) {
  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .where(
        (File file) => !skippedPaths.any(
          (String skipped) => file.path.replaceAll(r'\', '/').contains(skipped),
        ),
      )
      .toList();

  files.sort((File a, File b) => a.path.compareTo(b.path));

  return files;
}

/// What [file] is hiding, if anything.
///
/// It is public so that `test/tool/check_hardcoded_strings_test.dart` can
/// check the checker: a rule enforced by a script nobody tested is a rule that
/// is one refactor away from passing everything.
List<Finding> checkFile(File file) {
  final unit = parseFile(
    path: file.absolute.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  );

  final visitor = _LiteralVisitor(
    path: file.path,
    lines: unit.content.split('\n'),
    lineInfo: unit.lineInfo,
  );

  unit.unit.accept(visitor);

  return visitor.findings;
}

/// One literal that should have been a message.
final class Finding {
  /// A literal at [line]:[column] of [path], whose source is [literal].
  const Finding({
    required this.path,
    required this.line,
    required this.column,
    required this.literal,
  });

  /// The file the literal is in, as it was walked.
  final String path;

  /// The one-based line it starts on.
  final int line;

  /// The one-based column it starts at.
  final int column;

  /// Its source, quotes included.
  final String literal;
}

/// Walks a compilation unit looking at where each string literal lands.
final class _LiteralVisitor extends RecursiveAstVisitor<void> {
  _LiteralVisitor({
    required this.path,
    required this.lines,
    required this.lineInfo,
  });

  final String path;
  final List<String> lines;
  final LineInfo lineInfo;

  final List<Finding> findings = <Finding>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _inspect(node.constructorName.type.name.lexeme, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _inspect(node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  /// The arguments of a call to [name], and which of them are read.
  void _inspect(String name, ArgumentList arguments) {
    var positional = 0;

    for (final argument in arguments.arguments) {
      if (argument is NamedArgument) {
        if (_renderedParameters.contains(argument.name.lexeme)) {
          _report(argument.argumentExpression);
        }

        continue;
      }

      // A positional argument is only text where the widget's first one is,
      // and only when it is the first: `Text('a', key: k)` is one case and
      // `Directory('lib/ui')` is not. It is counted rather than compared
      // against `arguments.first`, because a named argument may be written
      // ahead of a positional one.
      if (positional++ == 0 && _textWidgets.contains(name)) {
        _report(argument.argumentExpression);
      }
    }
  }

  /// Records [expression] if it is a literal carrying words.
  void _report(Expression expression) {
    if (expression is! StringLiteral) {
      return;
    }

    if (!_carriesWords(expression)) {
      return;
    }

    final location = lineInfo.getLocation(expression.offset);

    if (_isExempt(location.lineNumber)) {
      return;
    }

    findings.add(
      Finding(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        literal: expression.toSource(),
      ),
    );
  }

  /// Whether [literal] contains anything a reader would read as language.
  ///
  /// An empty string is a placeholder, and an interpolation whose own text is
  /// only punctuation — `'$page/$total'`, `'$percent%'` — is a format and not
  /// a sentence. Both are left alone, because flagging them would mean the
  /// escape hatch is the common case and an escape hatch nobody reads is an
  /// escape hatch that hides the real ones.
  bool _carriesWords(StringLiteral literal) {
    final letters = RegExp(r'\p{L}', unicode: true);

    if (literal is SimpleStringLiteral) {
      return letters.hasMatch(literal.value);
    }

    if (literal is StringInterpolation) {
      return literal.elements.whereType<InterpolationString>().any(
        (InterpolationString part) => letters.hasMatch(part.value),
      );
    }

    // An adjacent-strings literal, which is how a long message is wrapped.
    return literal.toSource().split(RegExp('[\'"]')).any(letters.hasMatch);
  }

  /// Whether the literal on [line] was exempted, there or on the line above.
  bool _isExempt(int line) {
    for (final candidate in <int>[line, line - 1]) {
      if (candidate >= 1 &&
          candidate <= lines.length &&
          lines[candidate - 1].contains(ignoreMarker)) {
        return true;
      }
    }

    return false;
  }
}

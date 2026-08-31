@TestOn('vm')
/// The rule that decides this app's shape, made executable.
///
/// Atril never calls a write RPC on a replicable record. Every change is
/// authored as an operation in the local database and reaches the node through
/// `SyncService`, and C21 in
/// [`quire/docs/tcc-corrections.md`](../../../quire/docs/tcc-corrections.md) is
/// why: `UpdateEbook` writes `library.ebooks` and appends nothing to
/// `sync.operations`, so the change reaches the reader's other devices and
/// every authorized replica — never. The same change authored offline and
/// pushed reaches all of them.
///
/// The stubs keep the calls, because the contract has them and a fork of the
/// contract is not a client. What keeps `lib/` from using them is this file.
/// [`docs/architecture.md`](../../docs/architecture.md) states the rule in
/// prose; a rule stated only in prose is a rule the next session breaks in an
/// afternoon, honestly and for a good local reason.
///
/// There are three checks and the second is the one worth explaining. A pinned
/// list of names silently stops matching the day the contract renames one, and
/// a check that matches nothing passes forever — so the names are also asserted
/// against the vendored `.proto` files, which is where a rename would show up.
/// The third is the same argument the hardcoded-string checker makes about
/// itself: a visitor that stopped matching would report nothing, and nothing is
/// what a clean tree looks like.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// The twelve calls that write a record the federation replicates.
///
/// They are the eight of `LibraryService` and the four of `ReadingService`, as
/// the contract spells them. The content calls are not among them and are not
/// an omission: `BeginEbookUpload` and the three beside it move bytes, which
/// are addressed by their digest and replicate through nothing — an upload
/// names a file and never a work.
const List<String> writeRpcs = <String>[
  'CreateEbook',
  'UpdateEbook',
  'DeleteEbook',
  'CreateCollection',
  'UpdateCollection',
  'DeleteCollection',
  'AddEbookToCollection',
  'RemoveEbookFromCollection',
  'CreateAnnotation',
  'UpdateAnnotation',
  'DeleteAnnotation',
  'UpdateReadingProgress',
];

/// Where the generated contract lives, which is the one place the names are
/// allowed to appear: it is the contract, not a call to it.
const String generated = 'lib/data/services/api/generated';

/// The vendored contract the names are checked against.
const List<String> contracts = <String>[
  'proto/quire/v1/library.proto',
  'proto/quire/v1/reading.proto',
];

/// The name a Dart stub gives [rpc], which is what a call site would read.
String _asDart(String rpc) => rpc[0].toLowerCase() + rpc.substring(1);

/// Every use of a write RPC in [source], as `line: name`.
///
/// It is syntactic and unresolved, which is enough here and is not enough for
/// every rule: these twelve names are the contract's own and nothing else in
/// this app has any business spelling one. A wrapper method *named*
/// `updateEbook` is reported exactly as a call to one would be, which is the
/// answer this check should give — a call by a different name is still a call.
List<String> usesIn(String source, {required String path}) {
  final unit = parseString(
    content: source,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );
  final visitor = _WriteCallVisitor(unit.lineInfo);

  unit.unit.accept(visitor);

  return visitor.uses;
}

void main() {
  test('nothing in lib calls a write rpc on a replicable record', () {
    final offenders = <String, List<String>>{};

    for (final file in _dartFilesUnder('lib')) {
      final path = file.path.replaceAll(r'\', '/');

      if (path.contains(generated)) {
        continue;
      }

      final uses = usesIn(file.readAsStringSync(), path: path);

      if (uses.isNotEmpty) {
        offenders[path] = uses;
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'every change to a replicable record is authored through '
          'OperationAuthor and pushed by SyncService. C21 is why: a change '
          'made through these calls replicates to nobody. See '
          'docs/architecture.md.',
    );
  });

  test('the pinned names are the contract\'s own', () {
    final declared = <String>{};

    for (final path in contracts) {
      final file = File(path);

      expect(file.existsSync(), isTrue, reason: 'the contract is vendored');

      for (final match in RegExp(
        r'^\s*rpc\s+(\w+)\s*\(',
        multiLine: true,
      ).allMatches(file.readAsStringSync())) {
        declared.add(match.group(1)!);
      }
    }

    // A name this check pins that the contract no longer declares is a check
    // that has quietly stopped guarding anything: it would match nothing in
    // `lib/` and pass for as long as nobody looked.
    expect(declared, containsAll(writeRpcs));
  });

  test('the check sees a call it should refuse', () {
    final uses = usesIn('''
void save(LibraryServiceClient client, UpdateEbookRequest request) {
  client.updateEbook(request);
}
''', path: 'lib/pretend.dart');

    expect(uses, hasLength(1));
    expect(uses.single, contains('updateEbook'));
  });

  test('the check leaves the words the rule is written in alone', () {
    // The prose says these names constantly, and a check that flagged a comment
    // would be a check somebody disables.
    final uses = usesIn('''
/// Never calls UpdateEbook, per C21.
// UpdateEbook writes the row and appends nothing to the log.
const String reason = 'documented in architecture.md';
''', path: 'lib/pretend.dart');

    expect(uses, isEmpty);
  });
}

/// Every `.dart` file under [root], in a stable order.
List<File> _dartFilesUnder(String root) {
  final files = Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList();

  files.sort((File a, File b) => a.path.compareTo(b.path));

  return files;
}

/// Reports every identifier and every string that names a write RPC.
final class _WriteCallVisitor extends RecursiveAstVisitor<void> {
  _WriteCallVisitor(this._lines);

  static final Set<String> _dartNames = <String>{
    for (final rpc in writeRpcs) _asDart(rpc),
  };

  final LineInfo _lines;

  final List<String> uses = <String>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_dartNames.contains(node.name)) {
      _report(node.offset, node.name);
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // The stubs address a method by its path, so a hand-written call would be
    // a string and not an identifier. A comment is neither, which is what keeps
    // the rule's own prose off this list.
    for (final rpc in writeRpcs) {
      if (node.value.contains(rpc)) {
        _report(node.offset, rpc);
      }
    }

    super.visitSimpleStringLiteral(node);
  }

  void _report(int offset, String name) =>
      uses.add('${_lines.getLocation(offset).lineNumber}: $name');
}

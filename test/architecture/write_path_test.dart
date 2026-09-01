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
/// **The check is narrowed to the files that could make a call.** Phase 7 walked
/// the whole of `lib/` and reported the twelve names wherever they were spelled,
/// on the argument that a wrapper *named* `updateEbook` is a call by another
/// name. That argument was cheap while nothing else in the app spelled one, and
/// phase 8 is where it stopped being: the reader's own vocabulary for UC01 and
/// UC03 is *delete this book*, *create a collection*, *add a book to a shelf* —
/// the same words, because they name the same operations. A repository method
/// called `deleteEbook` does not call `DeleteEbook`; it authors an operation.
///
/// So a file is walked when it could be holding a client: it lives under
/// `data/services/api`, or it imports a client from there, the generated stubs,
/// or `package:grpc`. Nothing else can reach a node, and a name spelled in a
/// file that cannot is a name. The rule is not weakened where it bites — every
/// file that holds a stub is still walked, and a wrapper *there* is still
/// reported.
///
/// There are five checks and the second is the one worth explaining. A pinned
/// list of names silently stops matching the day the contract renames one, and
/// a check that matches nothing passes forever — so the names are also asserted
/// against the vendored `.proto` files, which is where a rename would show up.
/// The narrowing is pinned the same way: every `*_api.dart` under
/// `data/services/api` is asserted to count as a client, so a sixth client
/// added later is covered by the naming this project already follows rather
/// than by somebody remembering this file. The last two are the argument the
/// hardcoded-string checker makes about itself: a visitor that stopped matching
/// would report nothing, and nothing is what a clean tree looks like.
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

/// Where a client to the node can live at all.
const String apiDirectory = 'lib/data/services/api/';

/// Whether a file at [path] holding [source] could be calling the node.
///
/// It can if it *is* one of the clients — everything under `data/services/api`
/// — or if it imports one: a `*_api.dart` from there, the generated stubs, or
/// `package:grpc` itself. A stub cannot be reached any other way, so a file
/// that imports none of them cannot be making a call however it spells its own
/// methods.
///
/// It is deliberately about the import graph as *written*, one file at a time,
/// and not about what a file transitively depends on. A repository that reaches
/// a node does so through a client it names, and a check that followed the
/// graph would eventually walk everything and be the whole-tree check again.
bool canReachNode({required String path, required String source}) {
  if (path.contains(apiDirectory)) {
    return true;
  }

  final unit = parseString(
    content: source,
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );

  for (final directive in unit.unit.directives.whereType<UriBasedDirective>()) {
    final uri = directive.uri.stringValue ?? '';

    if (uri.startsWith('package:grpc') ||
        uri.contains('/generated/') ||
        (uri.contains('services/api/') && uri.endsWith('_api.dart'))) {
      return true;
    }
  }

  return false;
}

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

      final source = file.readAsStringSync();

      if (!canReachNode(path: path, source: source)) {
        continue;
      }

      final uses = usesIn(source, path: path);

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

  test('every client this project has counts as one', () {
    // The narrowing rests on a naming convention, so the convention is asserted
    // rather than assumed: a sixth client added under `data/services/api` is
    // covered by being called `*_api.dart`, and one that is not would otherwise
    // narrow this check out of existence quietly.
    final clients = _dartFilesUnder(
      apiDirectory,
    ).where((File file) => file.path.endsWith('_api.dart'));

    expect(clients, isNotEmpty, reason: 'the clients are where they were');

    for (final client in clients) {
      final imported = "import '../../${client.path.substring('lib/'.length)}';";

      expect(
        canReachNode(path: 'lib/pretend.dart', source: imported),
        isTrue,
        reason: '${client.path} does not count as a client',
      );
    }
  });

  test('a file that cannot reach a node is not walked', () {
    // The reader's vocabulary for UC01 and UC03 is the contract's: *delete this
    // book*, *create a collection*, *add a book to a shelf*. A repository
    // method spelling one of them is not a call to one.
    const String repository = '''
import '../../services/local/database.dart';

Future<void> remove(LibraryRepository library, String id) =>
    library.deleteEbook(id);
''';

    expect(
      canReachNode(
        path: 'lib/data/repositories/library/library_repository.dart',
        source: repository,
      ),
      isFalse,
    );
    // And it would have been reported, which is what makes the narrowing the
    // thing doing the work here rather than the visitor having gone blind.
    expect(usesIn(repository, path: 'lib/pretend.dart'), hasLength(1));
  });

  test('a file that holds a client is walked, wrapper or not', () {
    const String client = '''
import 'generated/quire/v1/library.pbgrpc.dart';

Future<void> remove(LibraryServiceClient client, String id) =>
    client.deleteEbook(DeleteEbookRequest(ebookId: id));
''';

    expect(
      canReachNode(
        path: 'lib/data/services/api/library_api.dart',
        source: client,
      ),
      isTrue,
    );
    expect(usesIn(client, path: 'lib/pretend.dart'), isNotEmpty);
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

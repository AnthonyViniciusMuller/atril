@TestOn('vm')
/// The direction a provider may look in, made executable.
///
/// `provider` resolves a type by walking *up* from the context it is given, and
/// `MultiProvider` nests its list in order: the first entry is the outermost
/// widget and the last is the innermost. So a provider may read anything
/// declared above it and nothing declared below it, and the composition root is
/// the one file in the app where that ordering is expressed at all.
///
/// The rule is worth a test because breaking it is silent. A `context.read<T>()`
/// aimed downwards analyses, compiles, and runs — it throws only when the
/// closure holding it is *called*, which for a lazily resolved dependency is
/// long after start-up and somewhere else entirely. The session holder read the
/// auth client that way, so every call in the app met a `ProviderNotFoundError`
/// at its first token refresh, wrapped as an `UNAVAILABLE` and reported as a
/// node that could not be reached. Nothing in `lib/` said anything was wrong,
/// and no test built the graph.
///
/// Deferring the read does not change the direction. The comment that
/// introduced the bug was right that a cycle has to be closed by resolving one
/// half later; it was wrong that resolving it later lets it be resolved through
/// the tree. What closes such a cycle is a variable at the composition root,
/// assigned where the provider below is built.
///
/// The last two tests are the argument `write_path_test.dart` makes about
/// itself: a visitor that stopped matching would report nothing, and nothing is
/// what a clean tree looks like.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The composition root, which is the only file this rule is about.
const String compositionRoot = 'lib/config/dependencies.dart';

/// One entry of the list `providersFor` returns.
final class _Provided {
  const _Provided({
    required this.type,
    required this.index,
    required this.reads,
  });

  /// The type it provides, as it is spelled.
  final String type;

  /// Where it sits in the list, which is how deep in the tree it is.
  final int index;

  /// Every `context.read<T>()` written anywhere inside it, however deeply the
  /// closure holding it is nested.
  final List<String> reads;
}

/// A read that looks for something declared below the provider making it.
final class _Downward {
  const _Downward({required this.from, required this.to});

  final String from;
  final String to;

  @override
  String toString() => '$from reads $to, which is declared below it';
}

void main() {
  group('the composition root', () {
    late List<_Provided> providers;

    setUpAll(() {
      providers = _providersOf(File(compositionRoot).readAsStringSync());
    });

    test('reads nothing that is declared below it', () {
      expect(
        _downwardReads(providers),
        isEmpty,
        reason:
            '`provider` resolves upwards and `MultiProvider` nests its list in '
            'order, so a provider can only read what is declared before it. '
            'Close a cycle with a variable at the composition root, assigned '
            'where the provider below it is built.',
      );
    });

    // The narrowing this file relies on: every entry of the list is a provider
    // whose type is spelled as a type argument. An entry built some other way
    // would be a provider this visitor cannot see, and it would pass by not
    // being looked at.
    test('is a list of providers this visitor can read', () {
      expect(providers, hasLength(greaterThan(30)));
      expect(providers.map((_Provided p) => p.type), contains('SessionHolder'));
      expect(providers.map((_Provided p) => p.type), contains('AuthApi'));
    });

    test('is read by a visitor that still finds the reads', () {
      expect(
        providers.expand((_Provided p) => p.reads),
        hasLength(greaterThan(20)),
      );
    });

    // The check itself, over the shape the bug had. Without this a visitor that
    // matched nothing would pass the three tests above by finding a graph it
    // could not see into.
    test('would have caught the cycle it was written for', () {
      final broken = _providersOf('''
        Future<List<SingleChildWidget>> providersFor(Environment e) async {
          return <SingleChildWidget>[
            Provider<SessionHolder>(
              create: (BuildContext context) => SessionHolder(
                refresher: () => context.read<AuthApi>(),
              ),
            ),
            Provider<AuthApi>(
              create: (BuildContext context) => AuthApi(
                session: context.read<SessionHolder>(),
              ),
            ),
          ];
        }
      ''');

      expect(
        _downwardReads(broken).map((_Downward d) => d.toString()),
        <String>['SessionHolder reads AuthApi, which is declared below it'],
      );
    });
  });
}

/// The reads that point at something declared below the provider making them.
///
/// A read of something the list does not provide is not reported: the graph is
/// mounted under a tree that may provide it, and this file is about the order
/// of the list and not about where else a type could come from.
List<_Downward> _downwardReads(List<_Provided> providers) {
  final declaredAt = <String, int>{};

  for (final _Provided provider in providers) {
    declaredAt.putIfAbsent(provider.type, () => provider.index);
  }

  return <_Downward>[
    for (final _Provided provider in providers)
      for (final String read in provider.reads)
        if ((declaredAt[read] ?? -1) >= provider.index)
          _Downward(from: provider.type, to: read),
  ];
}

/// The entries of the list `providersFor` returns, in the order it returns
/// them.
List<_Provided> _providersOf(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final list = _ReturnedList().find(unit);

  if (list == null) {
    fail('$compositionRoot returns no list of providers');
  }

  final found = <_Provided>[];

  for (final CollectionElement element in list.elements) {
    final type = _providedBy(element);

    if (type == null) {
      continue;
    }

    final reads = _Reads();
    element.visitChildren(reads);

    found.add(_Provided(type: type, index: found.length, reads: reads.types));
  }

  return found;
}

/// The type [element] provides, or `null` where it is not a provider written
/// as one.
///
/// It reads two node shapes because the source is parsed and not resolved, and
/// the parser cannot tell a constructor from a function without knowing what
/// the name means: `Provider<T>(...)` arrives as a method invocation carrying
/// the type argument, and `Provider<T>.value(...)` as an instance creation
/// carrying it on the named type. Resolving the unit instead would be a second
/// analysis of the whole package to learn something the syntax already says.
String? _providedBy(CollectionElement element) {
  final arguments = switch (element) {
    InstanceCreationExpression(:final ConstructorName constructorName) =>
      constructorName.type.typeArguments?.arguments,
    MethodInvocation(:final TypeArgumentList? typeArguments) =>
      typeArguments?.arguments,
    _ => null,
  };

  if (arguments == null || arguments.length != 1) {
    return null;
  }

  return arguments.single.toSource();
}

/// The list literal returned by `providersFor`.
final class _ReturnedList extends RecursiveAstVisitor<void> {
  ListLiteral? _list;

  ListLiteral? find(CompilationUnit unit) {
    unit.visitChildren(this);

    return _list;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme != 'providersFor') {
      return;
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final returned = node.expression;

    if (returned is ListLiteral) {
      _list ??= returned;
    }
  }
}

/// Every `context.read<T>()` under the node it is walked over.
final class _Reads extends RecursiveAstVisitor<void> {
  final List<String> types = <String>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final arguments = node.typeArguments?.arguments;

    if (node.methodName.name == 'read' &&
        arguments != null &&
        arguments.length == 1) {
      types.add(arguments.single.toSource());
    }

    super.visitMethodInvocation(node);
  }
}

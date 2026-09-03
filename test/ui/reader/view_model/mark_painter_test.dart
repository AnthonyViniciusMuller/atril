/// The paint over the page, against the list the replica holds.
///
/// It is the one part of the reader that is an algorithm rather than a screen,
/// and it was inside a view model that needs a host, a repository and a
/// settings store to exist. Here it needs a recorder.
library;

import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/domain/crdt/revision.dart';
import 'package:atril/domain/models/annotation.dart';
import 'package:atril/ui/core/themes/colors.dart';
import 'package:atril/ui/reader/view_model/mark_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String _book = 'aaaaaaaa-1111-4111-8111-111111111111';

/// A host that writes down what it was asked to draw.
final class _Recorder implements EpubHost {
  final List<EpubMark> drawn = <EpubMark>[];
  final List<String> erased = <String>[];

  /// What the next call fails with, or `null` to let it through.
  Object? refusal;

  @override
  Future<void> draw(EpubMark mark) async {
    final Object? refused = refusal;

    if (refused != null) {
      throw refused;
    }

    drawn.add(mark);
  }

  @override
  Future<void> erase(String cfiRange, {bool underline = false}) async {
    final Object? refused = refusal;

    if (refused != null) {
      throw refused;
    }

    erased.add(cfiRange);
  }

  @override
  Future<void> apply(EpubStyle style) async {}

  @override
  Future<List<EpubChapter>> chapters() async => const <EpubChapter>[];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> goTo(String locator) async {}

  @override
  Future<void> nextPage() async {}

  @override
  Future<void> open(EpubBook book, {String? at}) async {}

  @override
  Stream<EpubPosition> get positions => const Stream<EpubPosition>.empty();

  @override
  Future<void> previousPage() async {}

  @override
  Stream<EpubSelection> get selections => const Stream<EpubSelection>.empty();

  @override
  Future<String> textOf(String cfiRange) async => '';

  @override
  Widget view() => const SizedBox.shrink();
}

Annotation _mark(
  String range, {
  AnnotationKind kind = AnnotationKind.highlight,
}) => Annotation(
  id: range,
  ebookId: _book,
  kind: kind,
  locator: range,
  revision: Revision.first('device', DateTime.utc(2026, 9, 1)),
);

void main() {
  late _Recorder host;
  late MarkPainter painter;

  setUp(() {
    host = _Recorder();
    painter = MarkPainter(host);
  });

  test('draws what is in the list and nothing else', () async {
    await painter.reconcile(<Annotation>[_mark('one'), _mark('two')]);

    expect(host.drawn.map((EpubMark it) => it.cfiRange), <String>[
      'one',
      'two',
    ]);
    expect(host.erased, isEmpty);
  });

  test('draws nothing twice', () async {
    // The reconciliation runs on every emission of the list, which on a
    // synchronizing device is often. A redraw per emission would be the engine
    // asked to paint a page it has already painted, once per mark, forever.
    await painter.reconcile(<Annotation>[_mark('one')]);
    await painter.reconcile(<Annotation>[_mark('one')]);

    expect(host.drawn, hasLength(1));
  });

  test('erases what has left the list', () async {
    await painter.reconcile(<Annotation>[_mark('one'), _mark('two')]);
    await painter.reconcile(<Annotation>[_mark('two')]);

    expect(host.erased, <String>['one']);
    expect(host.drawn, hasLength(2));
  });

  test('redraws a mark whose kind changed', () async {
    // What happens when a highlight is given words: it is the same range and a
    // different colour, so it is erased and drawn again rather than left as it
    // was.
    await painter.reconcile(<Annotation>[_mark('one')]);
    await painter.reconcile(<Annotation>[
      _mark('one', kind: AnnotationKind.note),
    ]);

    expect(host.erased, <String>['one']);
    expect(host.drawn.map((EpubMark it) => it.color), <Color>[
      atrilHighlight,
      atrilNote,
    ]);
  });

  test('paints nothing over a bookmark', () async {
    // A bookmark is a position and covers no range. It is shown in the chrome.
    await painter.reconcile(<Annotation>[
      _mark('one', kind: AnnotationKind.bookmark),
    ]);

    expect(host.drawn, isEmpty);
    expect(painter.painted, isEmpty);
  });

  test('forgets everything when a draw fails', () async {
    // The page and this object have disagreed, and the next emission has to be
    // a full redraw rather than a diff against a lie.
    await painter.reconcile(<Annotation>[_mark('one')]);
    host.refusal = Exception('the engine has no page');

    await expectLater(
      painter.reconcile(<Annotation>[_mark('one'), _mark('two')]),
      throwsA(isA<Exception>()),
    );

    expect(painter.painted, isEmpty);

    host.refusal = null;
    await painter.reconcile(<Annotation>[_mark('one'), _mark('two')]);

    expect(host.drawn.map((EpubMark it) => it.cfiRange), <String>[
      'one',
      'one',
      'two',
    ]);
  });

  test('forget leaves the page alone', () async {
    // A book that has just been opened has an engine with nothing on it, and
    // erasing what it never drew would be a call that fails for a reason
    // nobody could act on.
    await painter.reconcile(<Annotation>[_mark('one')]);
    painter.forget();

    expect(host.erased, isEmpty);
    expect(painter.painted, isEmpty);

    await painter.reconcile(<Annotation>[_mark('one')]);

    expect(host.drawn, hasLength(2));
  });
}

/// A [ReadingRepository] that answers from memory.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:atril/data/repositories/reading/reading_repository.dart';
import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/domain/models/ebook.dart';
import 'package:atril/utils/result.dart';

/// A [ReadingRepository] that answers from memory.
///
/// The places are a broadcast controller for the reason the works are: what
/// the library screen is written against is a *stream*, and a test that set a
/// list and pumped would be exercising a repository this app does not have.
final class FakeReadingRepository implements ReadingRepository {
  final StreamController<Result<List<ReadingPlace>>> _places =
      StreamController<Result<List<ReadingPlace>>>.broadcast();

  /// Every position the screen recorded.
  final List<({String ebookId, String locator, double? percent})> saved =
      <({String ebookId, String locator, double? percent})>[];

  /// What [openBook] answers with.
  Result<EpubBook>? book;

  /// Emits [places] to whoever is watching.
  void emitPlaces(List<ReadingPlace> places) =>
      _places.add(Result<List<ReadingPlace>>.ok(places));

  /// Emits a failure, which a screen should ride out rather than empty itself
  /// over.
  void failPlaces(Exception error) =>
      _places.add(Result<List<ReadingPlace>>.error(error));

  /// Closes the stream, as a disposed repository would.
  Future<void> close() => _places.close();

  @override
  Future<Result<EpubBook>> openBook(String ebookId) async =>
      book ??
      Result<EpubBook>.ok(
        EpubBook(ebookId: ebookId, bytes: Uint8List(0), title: 'Os Sertões'),
      );

  @override
  Future<Result<void>> saveProgress({
    required String ebookId,
    required String locator,
    double? percent,
  }) async {
    saved.add((ebookId: ebookId, locator: locator, percent: percent));

    return const Result<void>.ok(null);
  }

  @override
  Stream<Result<List<ReadingPlace>>> watchContinueReading({int limit = 20}) =>
      _places.stream;

  @override
  Stream<Result<List<ReadingPlace>>> watchPlacesIn(String ebookId) =>
      _places.stream;

  @override
  Future<Result<Ebook?>> ebook(String ebookId) async => Result<Ebook?>.ok(null);
}

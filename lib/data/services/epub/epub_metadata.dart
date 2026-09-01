/// What an EPUB says about itself.
///
/// An EPUB is a zip holding one XML document that describes the work — the
/// *package document*, or OPF — and the path to it is in a second XML document
/// at a fixed place, `META-INF/container.xml`. Both steps are in the OCF
/// specification, and both are done here rather than guessed: an EPUB whose OPF
/// is not at the conventional path is an ordinary EPUB and not a broken one.
///
/// **Absent is not empty.** A work whose author the file did not name and one
/// whose `dc:creator` is an empty element are different claims, and the whole
/// of what this file returns is written to keep them apart: a field the OPF did
/// not carry comes back `null`, and a delta built from it does not claim the
/// field at all — so it keeps whatever another device wrote there. The contract
/// spells the same difference with `optional`, and the column with `NULL`.
///
/// **Nothing here fails an import.** A file that is not a zip, a container that
/// names no root, an OPF that is not XML: all of them answer `null`, the work
/// is imported under its file name, and the reader edits it if they care. The
/// alternative is refusing to take a book into the library because a publisher
/// wrote bad XML, which is the library's problem and never the reader's.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../../utils/logging.dart';

final _log = loggerFor('data/epub');

/// Where the path to the package document is, by the OCF specification.
const String containerPath = 'META-INF/container.xml';

/// The namespace the package document's metadata elements are in.
const String dublinCore = 'http://purl.org/dc/elements/1.1/';

/// The largest file this app will read a package document out of.
///
/// [readEpubMetadata] holds the whole archive in memory, so the bound is not
/// an optimization: it is what keeps a reader importing an illustrated atlas
/// on a phone from being shown a crash instead of a book. Past it the work is
/// imported under its file name, which is exactly what an EPUB with no usable
/// OPF produces anyway, and the reader renames it.
const int metadataSizeLimit = 64 * 1024 * 1024;

/// The cover of a work, as the file carried it.
final class EpubCover {
  /// The image, of [mediaType].
  const EpubCover({required this.mediaType, required this.bytes});

  /// What the manifest said the image is.
  final String mediaType;

  /// The image itself.
  final Uint8List bytes;

  @override
  String toString() => 'EpubCover($mediaType, ${bytes.length} bytes)';
}

/// What a package document said.
final class EpubMetadata {
  /// The metadata read out of one file.
  const EpubMetadata({
    this.title,
    this.author,
    this.publisher,
    this.language,
    this.extra = const <String, Object?>{},
    this.cover,
  });

  /// What the work is called, or `null` where the file did not say.
  final String? title;

  /// Its author. The first `dc:creator`, and not all of them joined: the
  /// column is one author and a list rendered into it would be a name nobody
  /// has. The rest travel in [extra] as `contributors`.
  final String? author;

  /// Its publisher.
  final String? publisher;

  /// Its language, as the file spelled the tag.
  final String? language;

  /// The metadata the format carried and the contract does not name (RF05).
  ///
  /// An object, never a scalar, because the column it lands in is `jsonb` and
  /// constrained to one — on the node and on this device.
  final Map<String, Object?> extra;

  /// The cover, if the manifest pointed at one this app could read.
  final EpubCover? cover;

  /// Whether the file said anything at all.
  bool get isEmpty =>
      title == null &&
      author == null &&
      publisher == null &&
      language == null &&
      extra.isEmpty &&
      cover == null;

  @override
  String toString() => 'EpubMetadata($title, $author)';
}

/// What the EPUB in [bytes] says about itself, or `null` if it says nothing
/// this app can read.
///
/// The whole file is in memory, and that is the one thing about this function
/// worth arguing with. A zip is read from its end — the central directory is
/// the last thing in it — so extracting two small entries out of a large
/// archive wants random access, which the blob store deliberately does not
/// offer: it answers a stream, on all six targets, and the browser's
/// origin-private file system is where a seekable handle would have to be
/// invented. The caller is what bounds the cost, by declining to read a file
/// larger than [metadataSizeLimit]; a book past that is imported under its
/// file name, which is what an unreadable OPF would have produced anyway.
EpubMetadata? readEpubMetadata(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final opfPath = _packagePath(archive);

    if (opfPath == null) {
      return null;
    }

    final opf = _textOf(archive, opfPath);

    if (opf == null) {
      return null;
    }

    return _metadataOf(XmlDocument.parse(opf), archive, opfPath);
  } on Object catch (error) {
    // Every failure here is the same failure: this file does not describe
    // itself in a way this app can read. It is not an import that failed.
    _log.fine('an EPUB could not be described', error);

    return null;
  }
}

/// The path of the package document, out of `META-INF/container.xml`.
///
/// The first `rootfile`, which is what the specification says to take: a
/// container may declare more than one rendition of the same work, and the
/// first is the one a reading system defaults to.
String? _packagePath(Archive archive) {
  final container = _textOf(archive, containerPath);

  if (container == null) {
    return null;
  }

  final root = XmlDocument.parse(
    container,
  ).findAllElements('rootfile').firstOrNull;
  final path = root?.getAttribute('full-path');

  return path == null || path.isEmpty ? null : path;
}

EpubMetadata _metadataOf(XmlDocument opf, Archive archive, String opfPath) {
  final extra = <String, Object?>{};
  final creators = _all(opf, 'creator');
  final subjects = _all(opf, 'subject');
  final identifiers = _all(opf, 'identifier');
  final isbn = identifiers
      .map(_isbnOf)
      .whereType<String>()
      .firstOrNull;

  if (subjects.isNotEmpty) {
    extra['subjects'] = subjects;
  }

  // Every author after the first. The column holds one, and a list rendered
  // into it would be a name nobody has; dropping the rest would lose what the
  // file actually said, which is what the extra metadata is for.
  if (creators.length > 1) {
    extra['contributors'] = creators.sublist(1);
  }

  if (isbn != null) {
    extra['isbn'] = isbn;
  }

  // Calibre's, and by now every reader's: the series is not in Dublin Core and
  // there is no other spelling of it in the wild.
  final series = _meta(opf, 'calibre:series');
  final index = _meta(opf, 'calibre:series_index');

  if (series != null) {
    extra['series'] = series;
  }

  if (index != null) {
    final position = double.tryParse(index);

    if (position != null) {
      extra['series_index'] = position;
    }
  }

  return EpubMetadata(
    title: _first(opf, 'title'),
    author: creators.firstOrNull,
    publisher: _first(opf, 'publisher'),
    language: _first(opf, 'language'),
    extra: extra,
    cover: _cover(opf, archive, opfPath),
  );
}

/// The cover the manifest points at, read out of the archive.
///
/// Two spellings, because there are two versions of the format in every
/// reader's library. EPUB 3 marks the manifest item `properties="cover-image"`;
/// EPUB 2 had no such property and the convention that won was a
/// `<meta name="cover" content="the item's id">`. Both are looked for, the
/// modern one first.
EpubCover? _cover(XmlDocument opf, Archive archive, String opfPath) {
  final items = opf.findAllElements('item').toList();

  var item = items.firstWhereOrNull(
    (element) =>
        (element.getAttribute('properties') ?? '')
            .split(RegExp(r'\s+'))
            .contains('cover-image'),
  );

  if (item == null) {
    final named = _meta(opf, 'cover');

    item = named == null
        ? null
        : items.firstWhereOrNull(
            (element) => element.getAttribute('id') == named,
          );
  }

  final href = item?.getAttribute('href');

  if (item == null || href == null || href.isEmpty) {
    return null;
  }

  // The href is relative to the package document and not to the root of the
  // archive, which is the mistake that produces a cover for the files whose
  // OPF happens to be at the top level and none for anybody else's.
  final path = p.posix.normalize(
    p.posix.join(p.posix.dirname(opfPath), Uri.decodeFull(href)),
  );
  final bytes = _bytesOf(archive, path);

  return bytes == null
      ? null
      : EpubCover(
          mediaType: item.getAttribute('media-type') ?? 'application/octet-stream',
          bytes: bytes,
        );
}

/// The text of the first `dc:`[name] element, trimmed, or `null`.
String? _first(XmlDocument opf, String name) => _all(opf, name).firstOrNull;

/// The text of every `dc:`[name] element, in order, without the empty ones.
///
/// The namespace is matched and the prefix is not: a package document may
/// bind Dublin Core to any prefix it likes, and the one that is conventional
/// is not the one that is required.
List<String> _all(XmlDocument opf, String name) => <String>[
  for (final element in opf.findAllElements(name, namespaceUri: dublinCore))
    if (element.innerText.trim().isNotEmpty) element.innerText.trim(),
];

/// The content of the `<meta name="...">` called [name], or `null`.
String? _meta(XmlDocument opf, String name) {
  for (final element in opf.findAllElements('meta')) {
    if (element.getAttribute('name') == name) {
      final content = element.getAttribute('content')?.trim();

      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
  }

  return null;
}

/// The ISBN [identifier] carries, or `null` if it carries something else.
///
/// A `dc:identifier` is whatever scheme the publisher chose — a UUID, a DOI,
/// a URL — so the two forms that actually say *ISBN* are the ones taken: the
/// `urn:isbn:` URN, and a bare run of digits of the right length. Anything
/// else is left alone rather than filed under a name it does not have.
String? _isbnOf(String identifier) {
  final value = identifier.trim();
  final urn = RegExp(r'^urn:isbn:(.+)$', caseSensitive: false).firstMatch(value);

  if (urn != null) {
    return urn.group(1)!.trim();
  }

  final digits = value.replaceAll(RegExp(r'[\s-]'), '');

  return RegExp(r'^\d{9}[\dXx]$|^\d{13}$').hasMatch(digits) ? digits : null;
}

/// The bytes of [path] in [archive], or `null` if it is not there.
Uint8List? _bytesOf(Archive archive, String path) {
  final file = archive.findFile(path);

  return file == null || !file.isFile ? null : file.readBytes();
}

/// The text of [path] in [archive], decoded as UTF-8.
String? _textOf(Archive archive, String path) {
  final bytes = _bytesOf(archive, path);

  return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
}

extension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }

    return null;
  }
}

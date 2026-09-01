/// What a file's name says it is.
///
/// It is a guess, and it is the client's guess to make. The node records what
/// it was told the bytes are and never opens them, so nothing downstream can
/// correct a wrong answer here — which is exactly why the answer is an
/// extension and never a sniffed header: a reader who renamed a file has told
/// this app something, and a client that overrode them would be a client that
/// disagrees with the reader about their own library.
///
/// `internal/client`'s own `describe` is the same table, and the two are
/// deliberately identical: a work imported through the reference client and
/// the same file imported here have to reach the node describing themselves
/// the same way, or one of them is a second stored object under a second media
/// type.
///
/// An extension this app does not know is not named at all. That is a refusal
/// the import turns into a message rather than a format invented for the
/// reader, and it is what keeps the closed set in the schema, in the delta and
/// in the contract from having to admit a sixth value nobody can render.
library;

import '../../../domain/models/ebook.dart';

/// A format, and what the bytes are called on the wire.
typedef FileKind = ({EbookFormat format, String mediaType});

/// The media type of each format UC02 admits.
///
/// They are the registered ones where a registration exists. `mobi` has none —
/// `application/x-mobipocket-ebook` is the de facto name and is what the
/// reference client sends — and a media type the node has not seen before is
/// stored rather than refused, so agreeing with the reference client is what
/// matters and being registered is not.
const Map<EbookFormat, String> mediaTypes = <EbookFormat, String>{
  EbookFormat.epub: 'application/epub+zip',
  EbookFormat.pdf: 'application/pdf',
  EbookFormat.mobi: 'application/x-mobipocket-ebook',
  EbookFormat.djvu: 'image/vnd.djvu',
  EbookFormat.cbz: 'application/vnd.comicbook+zip',
};

/// What [fileName] says it is, or `null` for a name this app cannot place.
///
/// The comparison is on the last extension and is case-insensitive: a file
/// named `Livro.EPUB` is an EPUB, and one named `livro.epub.part` is not — a
/// half-downloaded file is exactly the case where trusting the wrong dot
/// stores something under a name that lies about it.
FileKind? describeFile(String fileName) {
  final dot = fileName.lastIndexOf('.');

  if (dot < 0 || dot == fileName.length - 1) {
    return null;
  }

  final format = EbookFormat.parse(fileName.substring(dot + 1).toLowerCase());

  return format == null
      ? null
      : (format: format, mediaType: mediaTypes[format]!);
}

/// [fileName] without its extension, trimmed.
///
/// It is the title of last resort. A work always has one — the column and the
/// contract both refuse a work without a title — and a file whose format
/// carries no metadata this app can read, or carries none at all, has nothing
/// else to be called. A reader who wants better renames it on the detail
/// screen, which is RF05 and lands later in this phase.
String titleFromFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final stem = (dot <= 0 ? fileName : fileName.substring(0, dot)).trim();

  return stem.isEmpty ? fileName : stem;
}

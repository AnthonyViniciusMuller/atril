/// [FilePicker] over the platform's own dialog.
///
/// One implementation and not six. `file_selector` is itself the platform
/// split — a document picker on Android, a `UIDocumentPickerViewController` on
/// iOS, GTK, AppKit and the Win32 common dialog on the three desktops, and an
/// `<input type="file">` in a browser — so there is nothing here for a
/// conditional export to choose between. What this file adds is the type
/// group, which is the one thing that has to be spelled differently per
/// platform and is spelled once here rather than in the screen.
library;

import 'package:file_selector/file_selector.dart';

import '../../../domain/models/ebook.dart';
import 'file_source.dart';

/// The extensions the picker offers, which are the formats UC02 admits.
///
/// They are `EbookFormat`'s own names, so a format added to the contract is
/// added to the dialog by the same edit. The dialog is a filter and not a
/// guarantee: every platform lets a determined reader choose something else,
/// which is why the import checks the extension again rather than trusting
/// that it was offered.
final List<String> ebookExtensions = <String>[
  for (final format in EbookFormat.values) format.wireName,
];

/// The type group the dialog is opened with.
///
/// Extensions and not UTIs or MIME types, because `file_selector` derives the
/// platform-specific form from them and the three it cannot derive are the
/// three this app does not use. A group naming a UTI would be a group that
/// filters on Apple's platforms and nothing else.
final XTypeGroup ebookTypeGroup = XTypeGroup(extensions: ebookExtensions);

/// The reader's own file dialog.
final class SystemFilePicker implements FilePicker {
  /// The picker over the platform's dialog.
  const SystemFilePicker();

  @override
  Future<FileSource?> pickEbook() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[ebookTypeGroup],
    );

    return file == null ? null : XFileSource(file);
  }
}

/// An [XFile], as this app reads one.
final class XFileSource implements FileSource {
  /// The file [file] names.
  const XFileSource(this.file);

  /// What the picker handed back.
  final XFile file;

  @override
  String get name => file.name;

  @override
  Future<int?> length() => file.length();

  @override
  Stream<List<int>> openRead() => file.openRead();
}

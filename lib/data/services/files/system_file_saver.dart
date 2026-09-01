/// [FileSaver] over what each platform means by *save this file*.
///
/// **Two implementations and not one, because the platforms genuinely differ.**
/// Linux, macOS, Windows and the browser have a save dialog, and
/// `file_selector` — which is already this app's picker — is the split across
/// those four. Android and iOS have no save dialog at all: `file_selector` does
/// not implement `getSaveLocation` there, and the reason is not an omission in
/// the package. Saving a file on those systems *is* the share sheet, which is
/// where **Save to Files** and **Save to Drive** live beside sending the thing
/// to somebody.
///
/// So the choice is made at run time on `defaultTargetPlatform`, exactly as the
/// EPUB host's native split is and for the same reason: both branches compile
/// on every target, so this is a question about the machine rather than about
/// the language, and `architecture.md` reserves a conditional export for the
/// cases where the losing branch cannot be compiled at all.
///
/// The browser is the interesting corner of the first branch. `file_selector`'s
/// web implementation answers `getSaveLocation` with an empty path — a stand-in
/// for a dialog a browser does not have — and `XFile.saveTo` then hands the
/// bytes to the browser as a download. That is the whole of *saving a file* on
/// that target, and it is why the empty path is passed on rather than treated
/// as a refusal.
library;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'file_source.dart';

/// The saver this build's platform needs.
FileSaver systemFileSaver() =>
    defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS
    ? const SharedFileSaver()
    : const DialogFileSaver();

/// The save dialog of the three desktops, and the browser's download.
final class DialogFileSaver implements FileSaver {
  /// The saver over the platform's dialog.
  const DialogFileSaver();

  @override
  Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(extensions: <String>[_extensionOf(suggestedName)]),
      ],
    );

    if (location == null) {
      // The reader opened the dialog and changed their mind, which is a
      // decision and not an error.
      return null;
    }

    // The name is carried on the file and not only in the path, because it is
    // the name a browser downloads under — a web location has no path to take
    // one from.
    await XFile.fromData(
      Uint8List.fromList(bytes),
      name: suggestedName,
      mimeType: mimeType,
    ).saveTo(location.path);

    return location.path.isEmpty ? suggestedName : location.path;
  }
}

/// The share sheet of Android and iOS, which is where saving a file lives.
final class SharedFileSaver implements FileSaver {
  /// The saver over the platform's share sheet.
  const SharedFileSaver();

  @override
  Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(Uint8List.fromList(bytes), mimeType: mimeType),
        ],
        // `cross_file` drops the name of a file built from bytes on every
        // target but the web, so the sheet is told it separately. Without it
        // the reader is offered something called `image.jpg`.
        fileNameOverrides: <String>[suggestedName],
        subject: suggestedName,
      ),
    );

    // *Unavailable* is a sheet that ran and would not say what the reader
    // chose, which is the ordinary answer on Android: it is reported as a save
    // rather than as a refusal, because the alternative is telling somebody who
    // has just saved their annotations that nothing happened.
    return result.status == ShareResultStatus.dismissed ? null : suggestedName;
  }
}

/// The extension [name] ends with, without the dot.
String _extensionOf(String name) {
  final int dot = name.lastIndexOf('.');

  return dot == -1 ? '' : name.substring(dot + 1);
}

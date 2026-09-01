/// The host on the five native targets.
///
/// Two of them are reachable here and the choice between them is made at run
/// time, because both compile: Linux runs CEF and Android, iOS, macOS and
/// Windows run the platform's own webview. `defaultTargetPlatform` is what
/// asks, and it is asked here — at the edge — rather than inside a repository,
/// for the reason `config/platform.dart` gives about `Device.platform`.
library;

import 'package:flutter/foundation.dart';

import '../desktop_epub_host.dart';
import '../epub_host.dart';
import '../webview_epub_host.dart';

/// The factory this build's platform needs.
EpubHostFactory epubHostFactory() =>
    defaultTargetPlatform == TargetPlatform.linux
    ? const DesktopEpubHostFactory()
    : const WebviewEpubHostFactory();

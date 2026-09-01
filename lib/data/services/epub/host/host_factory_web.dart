/// The host in a browser.
///
/// One answer, and the file exists so that `desktop_epub_host.dart` is never
/// reached from a web build: it serves the engine over an `HttpServer`, and a
/// `dart:io` import does not parse for this target.
library;

import '../epub_host.dart';
import '../webview_epub_host.dart';

/// The factory this build's platform needs.
EpubHostFactory epubHostFactory() => const WebviewEpubHostFactory();

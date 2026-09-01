/// Which host this build gives the engine, chosen at compile time.
///
/// It is the **fifth** conditional export in this application and the first
/// whose two sides are both this project's own code. `architecture.md` lists
/// the other four and states the rule they meet: a conditional export is for
/// the case where the losing branch *cannot be compiled at all*, so an
/// interface picked at run time would not help because both implementations
/// would still have to compile.
///
/// This meets it. `desktop_epub_host.dart` serves the engine over an
/// `HttpServer`, which is `dart:io`, and a `dart:io` import does not parse for
/// the web target. There is no version of this file that reaches both hosts at
/// run time.
///
/// The split inside the native branch is a different kind and is deliberately
/// *not* a conditional export: Linux and the four other native targets can both
/// be compiled, so which of the two hosts to build is a question about the
/// machine and is answered with `defaultTargetPlatform` where the graph is
/// composed.
library;

export 'host_factory_io.dart'
    if (dart.library.js_interop) 'host_factory_web.dart';

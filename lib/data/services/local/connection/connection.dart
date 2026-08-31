/// Where the database file lives, which is the one thing about it that differs
/// per platform.
///
/// This is a conditional export, and it is the second one in the app rather
/// than an exception to the rule
/// [`architecture.md`](../../../../../docs/architecture.md) states: a
/// `dart:io` import does not compile in a browser and a `package:web` one does
/// not compile anywhere else, so a database opened over a file and a database
/// opened over the origin-private file system cannot be two implementations of
/// an interface selected at run time — the losing branch would still have to be
/// compiled. Everything the platforms merely *do* differently stays behind an
/// interface; what a platform cannot even parse is what a conditional export is
/// for.
///
/// Both files expose one function, and nothing above this directory knows which
/// of them answered.
library;

export 'connection_io.dart' if (dart.library.js_interop) 'connection_web.dart';

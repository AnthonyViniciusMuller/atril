// Fills in the file list and the version of `build/web/atril_service_worker.js`.
//
// The worker itself is committed under `web/` and is reviewed there. Only two
// of its lines cannot be written by hand — which files this build produced, and
// a version that changes when any of them does — and this program replaces
// exactly those two, in the copy `flutter build web` placed in the output.
//
// It is a step after the build rather than a step inside it because Flutter has
// no hook that runs at that point, and because the alternative — a worker that
// discovers what to cache at run time — caches whatever the first visit
// happened to touch. A reader who opened the library and not the reader would
// get an app that works offline until they open a book.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Files that exist in the output and are not part of the shell.
///
/// The source maps are a debugging aid measured in megabytes, and the worker
/// cannot cache itself. The Markdown is `web/README.md`: everything under
/// `web/` is copied into the output, so this project's note about the two drift
/// assets is deployed with the app, and there is no reason to also hold it
/// offline.
///
/// The renderer directory is the other exclusion, and it is a whitelist rather
/// than a blacklist. `--no-web-resources-cdn` copies the whole of the web SDK's
/// `canvaskit/` into the output — 36 MB of a 46 MB build — and most of it is
/// files this build cannot load: `skwasm`, `skwasm_heavy` and `wimp` are the
/// renderers of a `--wasm` build, which the loader selects only from a
/// `dart2wasm` entry in the build configuration and this build has none;
/// `webparagraph/` is a CanvasKit that is loaded only when `preferWebParagraph`
/// is configured, and `flutter_bootstrap.js` configures nothing; and the
/// `.symbols` files are the profiler's symbol maps. What the loader *can* ask
/// for is two pairs — `chromium/canvaskit.{js,wasm}` on a Chromium browser,
/// `canvaskit.{js,wasm}` on every other — and the pair is chosen at run time
/// from the browser, so both are held. Precaching the rest was 25 MB a reader
/// never fetched, and `cache.addAll` is atomic: one of those fetches failing
/// left the shell not cached at all.
///
/// Whitelist, because the failure modes differ. A renderer the engine grows and
/// this list does not name is served from the network rather than the cache,
/// which is the app online and not offline for that one file; a renderer this
/// list kept and the engine dropped is bytes nobody fetches. The build itself is
/// untouched either way — every variant is still deployed, and the worker
/// passes any request outside the shell straight through — so a wrong guess
/// here is never a blank page.
bool _isExcluded(String path) {
  if (path.endsWith('.map') ||
      path.endsWith('.md') ||
      path.endsWith('.symbols') ||
      path == 'atril_service_worker.js' ||
      path == 'flutter_service_worker.js' ||
      path.startsWith('.')) {
    return true;
  }
  if (path.startsWith('canvaskit/')) {
    return !_rendererFiles.contains(path);
  }
  return false;
}

/// The renderer files a JavaScript CanvasKit build can load, and no others.
const Set<String> _rendererFiles = <String>{
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
};

void main(List<String> arguments) {
  final output = Directory(arguments.isEmpty ? 'build/web' : arguments.first);
  if (!output.existsSync()) {
    stderr.writeln(
      "no web build at ${output.path} — run 'flutter build web' first",
    );
    exit(1);
  }

  final worker = File('${output.path}/atril_service_worker.js');
  if (!worker.existsSync()) {
    stderr.writeln(
      'no ${worker.path}: web/atril_service_worker.js is missing from this '
      'build, which means the shell would never be cached',
    );
    exit(1);
  }

  // `--pwa-strategy=none` does not omit Flutter's worker; it writes an empty
  // one. Nothing registers it, so it is inert — and a zero-byte file named
  // `flutter_service_worker.js` sitting beside Atril's is an invitation to
  // register the wrong one, which would replace Atril's registration because
  // both claim the same scope. So it is deleted rather than deployed.
  final tombstone = File('${output.path}/flutter_service_worker.js');
  if (tombstone.existsSync()) {
    tombstone.deleteSync();
  }

  final resources = <String>[];
  final entries = <String, List<int>>{};
  // The version is a digest over every file's path *and* its own digest, so an
  // asset whose bytes changed under an unchanged name produces a new cache, and
  // one that merely moved does too. A build number would do neither.
  //
  // Hashing each file and then hashing the hashes keeps one file in memory at a
  // time rather than the whole output, and it is why the summary is built from
  // the sorted list: a digest over a directory listing must not depend on the
  // order the filesystem happened to return it in.
  final summary = <int>[];
  for (final entity in output.listSync(recursive: true).whereType<File>()) {
    final path = entity.path
        .substring(output.path.length)
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp('^/'), '');
    if (_isExcluded(path)) {
      continue;
    }
    resources.add(path);
    entries[path] = sha256.convert(entity.readAsBytesSync()).bytes;
  }
  resources.sort();
  for (final path in resources) {
    summary
      ..addAll(utf8.encode(path))
      ..addAll(entries[path]!);
  }

  final stamp = sha256.convert(summary).toString().substring(0, 16);
  var source = worker.readAsStringSync();
  source = _replaceLine(
    source,
    worker.path,
    "const VERSION = 'development';",
    "const VERSION = '$stamp';",
  );
  source = _replaceLine(
    source,
    worker.path,
    'const RESOURCES = [];',
    'const RESOURCES = [\n${resources.map((r) => "  '$r',").join('\n')}\n];',
  );
  worker.writeAsStringSync(source);

  stdout.writeln(
    'atril_service_worker.js caches ${resources.length} files at $stamp',
  );
}

String _replaceLine(String source, String path, String from, String to) {
  if (!source.contains(from)) {
    // The worker and this program are two halves of one thing, so a rename in
    // either is a build that fails here rather than a service worker that
    // silently caches nothing.
    stderr.writeln('$path does not contain "$from"');
    exit(1);
  }
  return source.replaceFirst(from, to);
}

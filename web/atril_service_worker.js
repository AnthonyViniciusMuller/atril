'use strict';

// Atril's offline shell.
//
// This file exists because Flutter's no longer does. `flutter_service_worker.js`
// is deprecated (flutter/flutter#156910) and in 3.47.1 the tool generates a
// thirty-one-line tombstone that unregisters itself and reloads every client —
// so the target whose whole promise is that the network is an optimization had
// nothing left caching its own application.
//
// What it caches is the *shell*: the document, the compiled app, the renderer,
// the fonts and icons, sqlite's WebAssembly build and drift's worker. It does
// not cache a reader's books. Those are the per-book opt-in of phase 8, held in
// the origin-private file system against a budget the reader can see, and a
// worker that quietly cached them as they streamed would be the one thing that
// decision forbids: storage spent without being shown.
//
// The two lines below are rewritten by `tool/make_service_worker.dart` after
// `flutter build web`, because the file list and its version are only knowable
// once the build has produced them. What is here is what a development build
// gets: no precache, and every fetch straight to the network.
const VERSION = 'development';
const RESOURCES = [];

const CACHE = 'atril-shell-' + VERSION;

self.addEventListener('install', (event) => {
  // `skipWaiting` is deliberately not called. A worker that took over a page
  // already running would serve it a mixture of two builds — the JavaScript of
  // one and the assets of the other — for the rest of the session. Waiting
  // costs a reader nothing they can see: the new shell is what the next full
  // load gets.
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(RESOURCES)),
  );
});

self.addEventListener('activate', (event) => {
  // Activation only happens once every client of the previous worker is gone,
  // so this is the first moment the old shell is provably unreferenced.
  //
  // `clients.claim` is not called either, and the consequence is worth stating:
  // the very first visit to this app is served entirely from the network and is
  // not offline-capable. From the second load onwards it is. The alternative is
  // claiming a page that was loaded without a controller, which is the same
  // mixed-build hazard as `skipWaiting` by another route.
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) => name.startsWith('atril-shell-') && name !== CACHE)
          .map((name) => caches.delete(name)),
      ),
    ),
  );
});

// The precached paths are relative to the scope this worker was registered
// under, which is not necessarily the origin's root — `--base-href` is a
// documented option and a node may well serve this app under a path. Resolving
// them once here is what lets every comparison below be an exact URL match.
const shell = new Set(
  RESOURCES.map((path) => new URL(path, self.registration.scope).href),
);
const document_ = new URL('index.html', self.registration.scope).href;

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Everything this app says to a node goes past untouched, and the two
  // conditions below are each load-bearing rather than defensive.
  //
  // A node is normally a different origin, so the origin check alone would
  // already exclude every gRPC-Web call and the `.well-known` lookup. The
  // method check covers the case where it is not — a build served from the same
  // origin as its node — because a cached POST response would be one device
  // replaying another's answer to a synchronization request.
  if (request.method !== 'GET') {
    return;
  }
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) {
    return;
  }

  // A navigation to any location this app routes — go_router gives the web
  // target real URLs — is the one document there is.
  if (request.mode === 'navigate') {
    event.respondWith(
      caches.match(document_).then((cached) => cached || fetch(request)),
    );
    return;
  }

  // Only the files this build actually produced are answered from the cache.
  // Anything else is somebody else's request travelling through this scope, and
  // a worker that cached whatever it saw would be one that never forgets a
  // mistake.
  //
  // The cache is looked up by the resolved URL rather than by the request, so
  // that a query string appended to an asset still finds the entry the install
  // step stored. A miss falls through to the network and is not written back:
  // this cache holds one build, and the manifest is what says which.
  if (!shell.has(url.origin + url.pathname)) {
    return;
  }
  event.respondWith(
    caches
      .match(url.origin + url.pathname)
      .then((cached) => cached || fetch(request)),
  );
});

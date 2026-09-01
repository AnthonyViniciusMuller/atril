// The web entry point, written out rather than left to the tool's default,
// because the default registers a service worker this app must not have.
//
// Flutter's own worker is gone. In 3.47.1 the file the tool generates —
// `flutter_service_worker.js` — is thirty-one lines that call
// `registration.unregister()` and reload every client: a tombstone for a
// feature deprecated in flutter/flutter#156910. The default bootstrap still
// registers it, so an app that took the default would install a worker whose
// only behaviour is to remove itself, and would remove Atril's along with it.
//
// So the loader is called with no `serviceWorkerSettings`, and
// `atril_service_worker.js` is registered here instead. `make build-web` also
// passes `--pwa-strategy=none`, which stops the tombstone being written at all.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();

// Registered after the loader rather than before it, and deliberately not
// awaited: the first visit is served from the network either way, and a reader
// should not wait on a cache being filled for a page that is already loading.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('atril_service_worker.js').catch(function (error) {
      // A browser in a private window, or one with storage disabled, refuses
      // the registration. That costs the offline shell and nothing else, so it
      // is reported and not raised.
      console.warn('Atril: the offline service worker was refused:', error);
    });
  });
}

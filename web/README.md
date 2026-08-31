# The two files served beside the app

A browser has no filesystem to open a database on, so the web build runs sqlite
compiled to WebAssembly inside a worker, over the origin-private file system
where the browser has one and over IndexedDB where it does not. Neither file
can be built from source at `flutter build` time, and neither is on pub, so
both are committed here — the alternative being a build that fetches its own
database engine from a CDN, which is a reader who cannot open a book on a
train.

| File | What it is |
|---|---|
| `sqlite3.wasm` | sqlite, compiled for the web with the virtual-file-system hooks `package:sqlite3` needs. A build from anywhere else — sql.js, say — will not work |
| `drift_worker.js` | drift's own worker, compiled from the drift release below. It is what holds the database, so that a query does not block the frame the reader is looking at |

Both come from the same drift release, and the pair has to stay together: the
worker and the package talk a protocol that is versioned with drift, and a
worker from another release fails at the first statement rather than at build
time.

```
drift 2.34.3
https://github.com/simolus3/drift/releases/tag/drift-2.34.3

sha256(sqlite3.wasm)     41cf968998241465d8b1dfffb1eb60dd10c35de5022a3647e14174ea3af84143
sha256(drift_worker.js)  4db0469de8ceabad8d5cd3d920614486ba587e100e39523f36f704a3aec5f26c
```

`make web-assets` refreshes them for the version the Makefile pins, and
`make web-assets-check` — which CI runs — fails when that pin and the drift
resolved in `pubspec.lock` have come apart.

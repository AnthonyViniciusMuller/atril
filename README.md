# Atril

Flutter client for [Quire](../quire) — mobile, web and desktop.

An *atril* is the lectern a book rests on while it is being read. Quire gathers the folded
sheets; Atril is what holds them open in front of the reader, on whichever device is at hand.

## Status

Complete through phase 13 of [`docs/ROADMAP.md`](docs/ROADMAP.md), on all six targets: Android,
iOS, web, Linux, macOS and Windows. What that means in practice:

- **The library.** Import an e-book, file it under collections, edit what a work says about
  itself, delete one. Every change is authored locally and replicated.
- **The reader.** EPUB, through one engine on all six targets — epub.js, hosted by the platform's
  webview on five and by a CEF texture on Linux. The other formats import, list, synchronize and
  show a reading percentage; they cannot be opened yet.
- **Annotations.** Highlights, notes and bookmarks, a screen that lists them across the library,
  and an export the reader saves wherever they choose.
- **Synchronization.** A full replica in SQLite with a Dart reconciler — vector clocks, and a
  per-field `(updated_at, device_id)` tie-break — reconciling against the same rules the node
  uses. Push, pull, a live channel, a bounded backoff, and a screen that says when this device
  last reached its node.
- **Federation and sovereignty.** The catalogue of known nodes, granting and revoking a peer's
  right to hold a copy, moving an account to a different node with its devices and its history,
  device management, and account settings and deletion.

Two things the status does not claim, and both are still true after the phase 14 review. The
**release workflow has never run** — it wants a tag, three runners and signing secrets this
repository does not have — and the **Flatpak, the signed `.app` and the MSIX have not been
built**, for the same reason. So every fix that phase made to `release.yml` is a fix nothing has
executed. What has been built on this machine is the Linux bundle and the web output; the other
four are built by [`ci.yml`](.github/workflows/ci.yml) on every push, which now builds **Android
in release** — the one target where the release configuration is this repository's own work
rather than the toolchain's, and it was running nowhere.

## Getting started

```bash
flutter pub get
make help          # the annotated list of targets
make analyze       # the formatter, the analyzer and the no-hardcoded-strings check
make test
```

`make build-all` builds every target this machine can; CI builds all six.

### Pointing a build at the local federation

The client needs a node. From the Quire checkout next door:

```bash
cd ../quire && make dev-up
```

That brings up two federated nodes. Three ports matter, and they are three because the discovery
document, the native gRPC lane and the browser's gRPC-Web lane are three different services:

| | Node A | Node B |
|---|---|---|
| Discovery (`/.well-known/quire/client`) | `127.0.0.1:18080` | `127.0.0.1:28080` |
| gRPC, native, TLS | `127.0.0.1:19090` | `127.0.0.1:29090` |
| gRPC-Web, plain HTTP | `127.0.0.1:18090` | `127.0.0.1:28090` |

`lib/main_development.dart` is the entry point that knows those addresses, and a build started
from it offers both nodes in one tap on the server-selection screen. A shipped build knows no
node at all and waits for the reader to type a domain. **How you reach them differs per
target, and the difference is not discoverable from a failure message.**

**Linux, macOS and Windows** — nothing to do. The app runs on the same host as the federation, so
`127.0.0.1` is the federation.

```bash
make run-linux
```

The native lane is TLS against certificates `make dev-certs` generated, so the Makefile passes
the authority in as a base64 `--dart-define`. Those certificates are not committed on either
side — a vendored copy would be stale the next time anybody started the federation — which is why
it is a flag and not a file.

**Web** — nothing to do either, and for a different reason.

```bash
make run-web
```

A page cannot add to the browser's trust store, so the certificate flag is ignored here and is
not needed: the gRPC-Web lane is plain HTTP, and a loopback origin is a secure context as far as
a browser is concerned. This is the target where the transport differs rather than the address.

**iOS Simulator** — nothing to do. The simulator shares the host's network stack, so `127.0.0.1`
is still the federation.

```bash
flutter run -d <simulator> -t lib/main_development.dart
```

**Android emulator, and an Android device over USB** — `127.0.0.1` is *the device*, so the
addresses above resolve to nothing. Forward them first:

```bash
for port in 18080 19090 28080 29090; do adb reverse tcp:$port tcp:$port; done
flutter run -d <device> -t lib/main_development.dart
```

`adb reverse` makes the device's own loopback reach the host's, which is what lets one set of
hardcoded addresses serve every target. The forwards are lost when the device disconnects.

**An iOS device over a cable** has no equivalent of `adb reverse`. Reaching the federation from
one means giving it an address on the network you are both on, which is an edit to
`Environment.development` in `lib/config/environment.dart` rather than a command.

### Packaging

```bash
make package-linux      # a Flatpak, on a host with flatpak-builder
make package-macos      # a signed .app, on macOS
make package-windows    # an MSIX, on Windows
```

Each one signs with whatever the environment gives it and names the artifact `-unsigned` when it
was given nothing; [`docs/ROADMAP.md`](docs/ROADMAP.md) phase 13 has the arguments, and
`.github/workflows/release.yml` is where a tag runs all three.

## Where things are

- [`docs/architecture.md`](docs/architecture.md) — the layout, and the places this project
  departs from the [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)
  on purpose. **Read it before changing anything.**
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — one checkbox per commit, and what each one decided.
- [`CLAUDE.md`](CLAUDE.md) — the rules a contributor is most likely to break without noticing.

Three of those rules are worth repeating here, because each is a place the obvious thing is the
wrong thing. **Atril never calls the node's write RPCs** — every change to a replicable record is
authored in the local database and pushed through `SyncService`, because a change made through
the API replicates to nobody. **There is one EPUB engine and several hosts**, since a locator
written on one device has to resolve on another. And **no user-visible string is hardcoded**;
`pt_BR` is the default locale and `en` the second.

## License

[MIT](LICENSE).

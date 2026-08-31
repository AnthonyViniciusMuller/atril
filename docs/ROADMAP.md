# Implementation roadmap

One checkbox per commit. Tick a box only after the commit lands, so that any future session can
resume the work by reading this file and `git log`.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
and are written in English, as they are in [Quire](../../quire). Commits stay small and are
reviewed before landing. The scope is omitted unless it disambiguates.

The layout every layer follows — and the four places this project departs from the
[Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide) — is in
[`architecture.md`](architecture.md). Read it before starting a phase; in particular the reason
Atril writes to its own database and pushes, and never calls the node's write RPCs.

Thesis traceability: requirement identifiers (RF, RNF, RN, UC) refer to the TCC specification.
The contract is [`quire/proto/quire/v1`](../../quire/proto/quire/v1); the corrections and
divergences those files are written against are in
[`quire/docs/tcc-corrections.md`](../../quire/docs/tcc-corrections.md).

Six targets: Android, iOS, web, Linux, macOS, Windows. A commit that builds on five of them is
not done.

## Decisions taken before phase 0

| | |
|---|---|
| Web transport | gRPC-Web, translated by the node's own Istio gateway. Landed upstream: `EnvoyFilter`, CORS on the `/quire.v1.` route, and `test/e2e/grpcweb_kind_test.go`. The channel is the only thing that differs per platform |
| The two missing streams | `WatchOperations` replaces bidirectional `Sync` for a browser — a notification carrying a position, never an operation. `BeginEbookUpload`/`PutEbookChunk`/`FinishEbookUpload`/`DiscardEbookUpload` replace the client-streaming upload, and Atril uses them on **all six** targets because an offset-addressed upload resumes and a stream does not |
| Local store | A full replica in SQLite with a Dart reconciler — the vector-clock merge and the `(updated_at, device_id)` tie-break, ported from `internal/shared/crdt` and property-tested against the same laws |
| Reader | EPUB only. The other four formats import, list, sync and show percent progress, and cannot be opened yet |
| State management | The guide's own: `ChangeNotifier` view models, `Command`, `Result`, `provider` for injection, `go_router` for navigation |
| Localization | `flutter_localizations` and ARB from the first screen. `pt_BR` is the default locale, `en` the second. No hardcoded user-visible string, ever |
| Rejected operations | Quarantined, minimally: the local write stays, the record carries a refused flag, and the sync screen shows the node's reason with a discard action. No rollback — it destroys work the reader built on top — and no silent keep, which would leave the device disagreeing with every replica and saying nothing |
| Offline on the web | Per-book opt-in against a visible budget. Books stream on open; a reader marks the ones to keep, and usage is shown against `navigator.storage.estimate()`. Nothing is ever evicted silently, so the web target promises exactly what it can keep |
| Background sync | Foreground only, uniformly on all six: on launch, on resume, and while the app is open. It is what RNF09's periodic reconstruction asks for, it is one behaviour to document rather than four, and per-platform work stays a later phase rather than a design constraint |
| Interrupted uploads | Resumed across app restarts: `upload_id` and offset live in the local database, the node's `received_bytes` is authoritative, and any refusal falls back to `BeginEbookUpload`. It is the property D11 added over the streaming shape and the one that matters on a mobile network |

## Phase 0 — Bootstrap

The prelude in [Quire](../../quire) has landed in full. `ce0c2ed` routed gRPC-Web through the
gateway and `c2b8139`/`6b8eacb` added the two shapes a browser needs where a stream is
unreachable; `ccc8ae8`, `7120164` and `901792d` closed the three questions this roadmap opened
against them — the discovery document is covered by a test, the browser's server stream is
covered by one that was checked against its own regression, and the compose federation now
serves the browser lane on `127.0.0.1:18090` and `127.0.0.1:28090`.

Nothing on the Quire side blocks this repository any more.

Then, here:

- [x] `chore: add flutter scaffold` — what `flutter create` produced, unchanged, so that every
      later diff is this project and not the template. All six platform directories
- [x] `docs: add architecture and implementation roadmap` — this file and
      [`architecture.md`](architecture.md)
- [x] `build: tighten the analyzer` — `flutter_lints` plus the rules this project wants argued
      for rather than inherited: `always_declare_return_types`, `prefer_final_locals`,
      `require_trailing_commas`, and `avoid_print` promoted to an error, with the three strict
      language modes, in `analysis_options.yaml`. ~~`errors: missing_return: error`~~ is not
      part of it: `missing_return` was replaced by `body_might_complete_normally` when Dart
      became null-safe, and that diagnostic is already an error by default, so the line would
      configure a code the analyzer no longer has. Checked against Dart 3.13.1 rather than
      assumed
- [x] `ci: add analyze, test and build workflow` — `dart format --set-exit-if-changed`,
      `flutter analyze`, `flutter test`, and a build of each of the six targets. The Apple
      targets need a macOS runner; if none is available the workflow says so in a comment rather
      than pretending to cover them
- [x] `build: add a makefile` — the targets this project is driven by, mirroring Quire's:
      `proto`, `gen`, `test`, `analyze`, `run-linux`, `run-web`, `build-all`

## Phase 1 — The contract

- [x] `build: vendor the quire protobuf contracts` — the six `.proto` files copied into
      `proto/quire/v1`, with a `make proto-sync` that refreshes them from a Quire checkout and a
      CI check that fails when the copy has drifted. They are copied and not submoduled for the
      reason `buf.gen.yaml` gives on the other side: what is public is the contract, and a peer
      implements it from the files rather than by importing anyone's types
- [x] `build: generate dart stubs with protoc-gen-dart` — `dart pub global activate
      protoc_plugin`, pinned; the generation wired into `make gen`; the output under
      `lib/data/services/api/generated` and committed, with a CI drift check that regenerates and
      diffs. Generated code is excluded from the analyzer and from coverage
- [x] `build: add the generated quire contract` — the stubs themselves, in their own commit so
      that the diff of the commit before it is readable

## Phase 2 — The shared core

The part of `internal/shared` a device cannot be correct without. Pure Dart, no Flutter import,
and the most heavily tested code in the app. `Command` is the one exception, and it is unavoidable:
it extends `ChangeNotifier`, which lives in `package:flutter/foundation.dart`, and a hand-written
listenable would be a type no widget and no `provider` could observe.

- [x] `feat: add the result type` — the guide's sealed `Result<T>`, its `Ok`/`Error` cases, and
      the extensions the view models use
- [x] `feat: add the error vocabulary` — one `AppException` with the `Kind` values
      `internal/shared/errs` uses, the machine-readable code, and the per-field validation
      failures. This is the type every layer boundary carries; the gRPC mapping arrives in
      phase 4
- [x] `feat: add the command type` — `Command0` and `Command1`, with `running`, `error` and
      `completed`, so a view model exposes actions and not methods
- [x] `feat: add the vector clock` — a `Map<String, int>` wrapper, its pointwise-maximum merge,
      and a comparison returning *before*, *after*, *equal* or *concurrent*. A device absent and
      a device at zero are the same thing, on both sides of every operation
- [x] `test: prove the vector clock is a join semilattice` — merge is idempotent, commutative and
      associative, and the partial order agrees with it. The property tests
      `internal/shared/crdt` carries, written again against the same laws, because a client that
      merges differently converges differently
- [x] `feat: add the hybrid logical clock` — `t = max(wall clock, greatest observed + 1µs)`, per
      C01. It persists its floor, so a fresh launch does not begin having observed nothing, and
      it is monotone on a browser whose wall clock has millisecond resolution. The floor leaves
      through a `HybridClockStore` port, because a stamp is synchronous and a database is not;
      the row it is written to arrives with the identity tables in phase 3
- [x] `feat: add the revision and the last writer wins rule` — the four fields every replicable
      record carries, and the decision procedure: consult the clock, and only where it reports
      the two versions concurrent, break the tie on `(updated_at, device_id)`
- [ ] `feat: add logging` — one logger, levels from the environment, and nothing written to
      stdout anywhere else

## Phase 3 — The local replica

`drift` over SQLite, and the one place in the app that holds the reader's collection.

- [ ] `feat: add the drift database` — the connection, the schema version, and the migration
      strategy. Native through `sqlite3_flutter_libs`
- [ ] `build: add the drift web worker assets` — `sqlite3.wasm` and `drift_worker.js` under
      `web/`, and the web connection that picks OPFS where it is available and IndexedDB where it
      is not. Committed with the version they were built from
- [ ] `feat: add the identity tables` — the bound device, the reader, the origin server, the
      known-server catalogue, and the hybrid clock's floor, which phase 2 left behind a port. The
      device id lives here and not in the session store, because it survives logout
- [ ] `feat: add the library tables` — `ebooks`, `collections` and `ebook_collections`, each with
      the revision columns spelled out: `vector_clock`, `updated_at`, `device_id`, `deleted`. The
      membership table carries the unique `(ebook_id, collection_id)` C06 requires, because the
      pair and not the row is the record
- [ ] `feat: add the reading tables` — `annotations` with a full revision, and `progress` with a
      clock and a timestamp and neither tie-break field, per C05, unique on
      `(ebook_id, device_id)`
- [ ] `feat: add the operation log and the node cursors` — what this device authored and has not
      handed over, in the order it authored it, and the last position pulled from each node. The
      cursor is keyed by the node dialed: a position is that node's own order and two of them
      have nothing to do with each other
- [ ] `feat: add the record versions table` — the causal version last seen of each record this
      device has touched, and for the two associative entities the surrogate id this device
      minted. C18 is why the second half exists: a device that forgets the id it minted mints
      another on every write
- [ ] `feat: add the reconciler` — applies one operation to the local replica, per field, by the
      rule phase 2 established. Idempotent by operation id, because a node may deliver the same
      operation twice and receiving is what makes retries safe
- [ ] `test: prove the reconciler converges` — a generated operation log, applied in every
      shuffled order, reaching one state. The tombstone case is separate and explicit: a deletion
      is a write like any other, and a record removed outright is resurrected by the next replica
      that had not yet heard
- [ ] `feat: add the blob store` — the e-book bytes, keyed by content hash, behind an interface
      with a filesystem implementation and a browser one
- [ ] `feat: report the storage budget` — what the store holds and what it may hold, as a number
      the interface answers. On the web that is `navigator.storage.estimate()`; on the five
      native targets it is the free space on the volume. It exists because the web build spends
      it deliberately rather than discovering it: a reader whose next download fails deserves a
      sentence and not a crash, and one whose book was evicted deserves never to find out that
      way

## Phase 4 — Reaching a node

- [ ] `feat: add the platform channel` — `channel_io.dart` and `channel_web.dart` behind one
      conditional export. The native side takes an optional CA so that `make dev-up` can be
      dialled; the web side takes the proxy's URL
- [ ] `feat: add the session interceptor` — the bearer token on every call, a single-flight
      refresh on `UNAUTHENTICATED` that retries the call once, and the rotation the contract
      requires: the refresh credential presented is consumed and the reply carries its
      replacement
- [ ] `feat: map grpc status onto the error vocabulary` — `GrpcError` to `AppException`, keeping
      the code and the field failures the node sends, so a rejected registration reaches a form
      as something it can point at
- [ ] `feat: add the session store` — the refresh credential in `flutter_secure_storage` on the
      five native targets. On the web there is no secure storage, only `localStorage`; the store
      says so in one comment and the settings screen says so to the reader
- [ ] `feat: add the api clients` — one thin client per gRPC service over the generated stubs,
      and the mappers between the wire types and the domain models
- [ ] `feat: add connectivity awareness` — whether a node is reachable, as a stream. Not
      `connectivity_plus` alone, which reports a radio and not a route: a failed call is the
      signal, and the radio is the hint that it is worth trying again

## Phase 5 — The shell

- [ ] `feat: add the theme` — Material 3, a light and a dark scheme, and the type scale the
      reader inherits. Named colours only; a hex literal in a widget is a theme that will
      disagree with itself
- [ ] `feat: add localization` — `flutter_localizations`, `app_pt_BR.arb` and `app_en.arb`, and
      the lint that fails the build on a hardcoded string
- [ ] `feat: add routing` — `go_router`, the route table, and the redirect that sends a device
      with no session to onboarding and one with a session away from it
- [ ] `feat: add the adaptive scaffold` — one navigation surface expressed three ways:
      `NavigationBar` on a phone, `NavigationRail` on a tablet or a small window, and an extended
      rail on a desktop. Chosen by width and not by platform, because a resized desktop window is
      a phone and a tablet in landscape is not
- [ ] `feat: add the entry points and the dependency graph` — `main.dart`,
      `main_development.dart`, and one `providers` function per environment. Nothing below
      `main` reads a compile-time constant, for the reason Quire gives about `os.Getenv`: the
      configuration surface is one struct, and a widget that reads the environment is a widget
      that cannot be tested
- [ ] `feat: add the desktop window configuration` — a minimum size and a remembered one on
      Linux, macOS and Windows, so the adaptive layout has a floor to be correct at

## Phase 6 — Onboarding (UC13, UC14, UC07, UC08)

- [ ] `feat: add server discovery` — `FederationService.DiscoverServer`, and the direct
      `.well-known/quire/client` fetch for a device that has no node to ask yet — the *client*
      document and not the server one, which is what a peer reads to learn the key to pin. The
      fetch sends no custom header of any kind: the node answers the document with
      `Access-Control-Allow-Origin` itself, but the gateway admits `GET` on `/.well-known/*` and
      not `OPTIONS`, so anything that provokes a preflight is refused `403`. A reader types a
      domain; the app learns the base URL, the JWKS URI and the gRPC authority from the document
      the node publishes
- [ ] `feat: add the server selection screen` — the first screen a new install shows, with the
      development federation reachable in one tap in a debug build. The identifier is
      `@local_name:server` and the server half is which node the call was addressed to, so this
      screen is not a preference — it is half of the reader's name
- [ ] `feat: add registration` — UC14. `RegisterUser` against the discovered node, the local-name
      constraint validated client-side against the same regex the contract publishes, and the
      server's field-level rejections rendered on the fields that caused them
- [ ] `feat: add login and device binding` — UC07. The `DeviceBinding` carries this device's id
      when it has one and its name and platform when it does not, and the reply is where a new
      device learns the id its vector-clock entries will be counted under. The platform string is
      free-form by design, so it says `android`, `ios`, `web`, `linux`, `macos` or `windows` and
      the node is not redeployed to add a seventh
- [ ] `feat: add logout` — clears the session and nothing else. The device id, the local replica
      and the pending log stay, because logging out is not unbinding
- [ ] `feat: add password recovery` — UC08. Two screens: request, and reset from a token. The
      request reports the same outcome whether or not the address is registered, and the screen
      does not helpfully say otherwise
- [ ] `feat: seed a newly bound device` — the one place the read RPCs are called: `ListEbooks`,
      `ListCollections`, `ListAnnotations` and `ListReadingProgress`, straight into the local
      replica, before the first pull. A device bound to a reader with a history has to start
      somewhere, and pulling from position zero would only replay what the log has — which, until
      C21 closes, is not everything

## Phase 7 — Authoring a change (UC09, UC10)

This phase writes no screen. It is the path every screen after it uses, and it comes first for
that reason.

- [ ] `feat: add the operation author` — one entry point for a change to a replicable record: it
      resolves the target, stamps the delta on the version this device last saw, ticks its clock
      entry, appends to the local log and applies to the local replica in one transaction. The
      caller does not branch on connectivity, because there is nothing to branch on
- [ ] `feat: add the delta vocabulary` — the field names the node reads in
      `internal/sync/infra/service/records`, spelled once. A field the delta does not name keeps
      whatever device wrote it last, and a field named as JSON null is a field the reader
      cleared: the difference is the whole of what per-field reconciliation rests on
- [ ] `feat: resolve the associative entities by natural key` — C18. An operation on a filing
      carries `(ebook_id, collection_id)` in its delta and an operation on a position carries
      `ebook_id`, the device half being the authoring device by C05. The surrogate id is
      provenance
- [ ] `test: pin the write path against the contract` — a test that walks `lib/` and fails if
      anything calls one of the eleven write RPCs. It is the executable form of the rule in
      [`architecture.md`](architecture.md), and it is what makes the rule survive a future session

## Phase 8 — The library (UC01, UC02, UC03)

- [ ] `feat: add the library repository` — a stream of the reader's collection out of the local
      replica, sorted, filtered, and correct while offline because there is nothing else it could
      be
- [ ] `feat: add the library screen` — a grid on a wide window and a list on a narrow one, with
      the empty state that tells a new reader what to do next
- [ ] `feat: add e-book import` — a file picked, hashed with SHA-256 as it is read so the bytes
      are never held twice, written to the blob store under that digest, and registered as an
      operation. The digest is what identifies the bytes across the federation, so importing the
      same file twice on two devices converges on one object
- [ ] `feat: extract epub metadata on import` — title, author, publisher, language and the cover,
      out of the OPF. What the file did not say is absent and not empty: a work whose author is
      unknown and one whose author is the empty string are different claims, and the contract
      spells the difference with `optional`
- [ ] `feat: add content upload` — the chunked shape D11 added, on all six targets:
      `BeginEbookUpload` declares the size and the digest and is refused there if the node will
      not take it, `PutEbookChunk` carries each chunk at the offset it continues from, and
      `FinishEbookUpload` is where the node's hash is checked against what was declared. It is
      independent of the record: the call names a digest and not an e-book, so an import queues
      its operation and uploads its bytes without either waiting for the other
- [ ] `feat: resume an interrupted upload` — the property the client stream did not have. A
      `PutEbookChunk` reply carries `received_bytes`, which is the offset the next chunk must
      carry, so a caller whose connection died continues from what arrived and one that lost a
      reply and repeated a chunk is told so rather than corrupting the file. `already_held` is
      handled at both ends: another device of the same reader may have sent the file in between,
      and then there is nothing to send. `DiscardEbookUpload` on abandonment, because a client
      that has given up should say so
- [ ] `feat: carry an upload across a restart` — the `upload_id` and the offset in the local
      database, so closing the app does not start a large book over. The node's `received_bytes`
      is the authority and this device's opinion is a hint: D11 stages the bytes in a temporary
      file held in the process, so a node restart or an expiry invalidates a session this device
      is still holding. Every call is therefore written to fall back to `BeginEbookUpload`, and a
      refused chunk is a beginning rather than a failure
- [ ] `feat: add content download` — `DownloadEbookContent` into the blob store, resumable,
      cancellable, and reported per book. A node that replicates this reader without their files
      answers that it does not hold them, and that is a legitimate state and not an error
- [ ] `feat: add offline pinning` — which books this device keeps. On the five native targets
      every book is kept and the control is there to release one; on the web nothing is kept
      until the reader says so, and the screen shows what is held against the budget phase 3
      reports. It is one mechanism with two defaults rather than two features, because the
      question a reader is answering is the same one — *is this book here when the network is
      not* — and only the honest answer differs by platform
- [ ] `feat: add the e-book detail screen` — the metadata, the cover, where the bytes are, and
      the actions
- [ ] `feat: add metadata editing` — RF05, including the extra metadata the format carried and
      the contract does not name. It is an object and never a scalar, because the column it lands
      in is `jsonb` and constrained to one
- [ ] `feat: add deletion` — a tombstone, never a removal, with the undo that a tombstone makes
      cheap
- [ ] `feat: add collections` — UC03. Create, rename, describe, delete, and the two kinds the
      contract admits. A collection is a grouping the reader defined and a category is not, and
      the screen does not blur them
- [ ] `feat: add filing a work under a collection` — UC02, and the reason C06 exists: two devices
      that add and remove the same book from the same shelf while offline reach the same answer,
      because membership is a register per pair and not a row
- [ ] `feat: add search and filtering` — over the local replica, by title, author, collection and
      format. No RPC: the collection is here

## Phase 9 — The reader (UC04)

One EPUB CFI implementation — epub.js — hosted six different ways. The locator is the thing
that has to be right: the node stores it, replicates it, and hands it to the reader's other
devices, so a CFI authored on a phone must resolve on the desktop or an annotation lands on the
wrong paragraph after a sync. That is what decides the shape of this phase.

**The split is one engine and several hosts, never several engines.** A Dart CFI implementation
beside a JavaScript one would be two answers to "where is this passage", agreeing almost always,
and the disagreements would arrive as corrupted annotations a long way from their cause. So
epub.js is bundled once and every platform runs the same file; what differs is only what gives
it a DOM.

| Target | Host |
|---|---|
| Android, iOS, macOS | `flutter_epub_viewer`, over `flutter_inappwebview` |
| Web | `flutter_epub_viewer`, epub.js in an `<iframe>` through `dart:js_interop` |
| Linux, Windows | `webview_cef`, CEF rendered to a Flutter texture |

- [ ] `feat: bundle epub.js` — the engine as an asset, pinned to a version and committed, with
      the licence beside it. It is loaded from the bundle and never from a CDN: an offline-first
      reader that cannot open a book on a train has missed the point, and a renderer fetched at
      runtime is a renderer that changes under a locator
- [ ] `feat: add the epub host interface` — the port every platform implements: open a book from
      the blob store, render it, navigate, report the current CFI, resolve one, and apply a
      highlight over a CFI range. It is the whole surface the reader feature knows, and it names
      no webview
- [ ] `feat: add the webview epub host` — `flutter_epub_viewer` on Android, iOS and macOS. It
      already exposes CFI for the position, for navigation and for extracting a text range, so
      what this commit writes is the mapping onto the port and not a renderer
- [ ] `feat: add the web epub host` — the same package's web path, which puts epub.js in an
      `<iframe>` and talks to it over `dart:js_interop` rather than through a webview plugin
- [ ] `feat: add the desktop epub host` — `webview_cef` for Linux and Windows, loading the same
      bundled epub.js and the same bridge the other two hosts use. This is the risk in the phase
      and it is named in the open questions: CEF is a heavy dependency, Linux is its
      software-rendered path, and the package is a community one
- [ ] `test: prove a locator round-trips between hosts` — the correctness claim the whole split
      rests on. A CFI produced by one host resolves to the same passage under another, checked
      against a corpus rather than asserted, because the failure it guards against is an
      annotation that syncs to a reader's other device and lands somewhere else
- [ ] `feat: add the reader chrome` — the page, the progress, the table of contents, and the
      controls that get out of the way. Flutter widgets over the host, not inside it
- [ ] `feat: add reader settings` — font, size, line height, margins and the reading theme,
      applied through the host's own styling. Local and deliberately unsynchronized: they are
      about this screen on this device and the contract has no field for them
- [ ] `feat: track reading position` — UC04. The CFI the host reports, and the percentage derived
      from it and stored anyway, so a device that cannot open a DjVu can still report that the
      reader is forty percent through it. Written through the operation author like every other
      change, debounced, because a position that wrote an operation per page turn would be a log
      nobody wants
- [ ] `feat: add continue reading` — the shelf that reads the position rows back, including the
      ones this reader's other devices wrote. Where each device stopped in each book is a
      question with one answer per device, and showing all of them is the point

## Phase 10 — Annotations (UC05)

- [ ] `feat: add highlights` — a selection in the reader, anchored to a CFI range
- [ ] `feat: add notes` — a highlight with text, which the contract requires to be present
      because a note without it is an empty note
- [ ] `feat: add bookmarks` — a position, no text, no selection
- [ ] `feat: add the annotations screen` — everything marked in one book and everything marked
      across the library, each navigating back to its passage
- [ ] `feat: add annotation export` — Markdown and JSON, to a file the reader chooses. It is
      their data, and a sovereignty argument that cannot get it out of the app is an argument
      with a hole in it

## Phase 11 — Synchronization (UC09, UC10, UC11)

- [ ] `feat: add push` — `PushOperations`, draining the local log in order, and the four outcomes
      handled distinctly: applied and duplicate both retire the operation, superseded retires it
      and leaves the replica alone, and rejected is the only one that surfaces to a reader
- [ ] `feat: add pull` — `PullOperations` from this node's cursor, through the reconciler, with
      the cursor advanced only after the batch is committed. `has_more` is a loop and not a
      recursion
- [ ] `feat: add the sync stream` — `Sync`, the bidirectional one, on the five native targets:
      `SyncStart` with the cursor, then pushes and acks in one direction and operations in the
      other. The ack is sent after the write commits and not after the read returns, because an
      operation written to a socket is not an operation written to disk and a device that dies in
      between must come back to the same place
- [ ] `feat: add the watch stream` — `WatchOperations` for the web, where gRPC-Web carries no
      bidirectional call. It is a notification and not a delivery: the response carries
      `last_position` and never an operation, so the handler does one thing — compare it against
      this node's cursor and pull if it is behind. There is no ack, because the node holds
      nothing in flight for this caller, and a missed notification costs a poll rather than an
      operation
- [ ] `feat: add the sync scheduler` — the stream while the app is in the foreground and
      reachable, a push on reconnect, a bounded backoff on failure, and a policy for the
      background on each platform that has one
- [ ] `feat: add the sync status surface` — what is pending and when the last sync completed.
      One line in the shell, one screen behind it. A reader who cannot tell whether their notes
      are only on this phone has not been given the guarantee the app claims
- [ ] `feat: quarantine a refused change` — the case the local-first write path makes possible:
      the reader has seen the change land and the node will not take it, so the device is showing
      something that will reach nobody. The record carries a refused flag and the node's reason,
      the sync screen lists it, and the reader can discard it. It is deliberately not a rollback
      — the write may have others built on top of it, and destroying those to satisfy a refusal
      is the one outcome worse than the refusal — and deliberately not silence, which would leave
      this device disagreeing with every replica and saying nothing. A correct client should
      rarely produce one, so this is a flag and a list and not a merge interface
- [ ] `test: prove two devices converge` — two databases, one operation log, the later write
      pushed first, both landing on the write that wins on `(updated_at, device_id)`. It is
      Quire's own end-to-end reconciliation test, written from this side

## Phase 12 — Federation and sovereignty (UC06, UC12, UC15, UC16)

The phase the thesis is actually about, and the one a demonstration ends on.

- [ ] `feat: add the known servers screen` — UC12. The catalogue, adding a node by domain, what
      discovery learned about it, and refreshing a node whose key was rotated
- [ ] `feat: add replica authorization` — UC15. Granting a node the right to hold a copy, with
      and without the files, and revoking it. Metadata without the files is the cheap replica a
      reader is most likely to want on a node they do not own, and the screen makes the choice
      legible rather than a checkbox. C22 is stated where it lands: nothing in the contract can
      tell a node that it is a replica, so the grant is recorded and the federation is completed
      out of band, and the screen says so instead of appearing to have worked
- [ ] `feat: add home server migration` — UC16, and the demonstration this project exists for. A
      reader moves to a node they had no account on, carrying their devices, and everything each
      one was holding and had not handed over is pushed to the new node under the identifiers it
      was authored with. The previous node is not asked anything. The screen is a wizard because
      the operation is not reversible, and the causal state is not cleared on the way through —
      clearing it would complete the migration by discarding what was being migrated
- [ ] `feat: add device management` — the reader's devices, renaming one, and revoking one. A
      revoked device's row stays and so does its clock entry, or the history that names it stops
      being readable, and the screen says *unbound* and not *deleted*
- [ ] `feat: add account settings` — UC06. Display name, address, password. Only the display name
      is writable directly; the address and the password are credentials in their own right and
      go through their own calls, which is C14
- [ ] `feat: add account deletion` — with what it does and does not reach spelled out: this node,
      and not the replicas that already hold a copy

## Phase 13 — Delivery

- [ ] `build: add the android release configuration` — signing, the application id, and the
      minimum SDK
- [ ] `build: add the ios release configuration` — the bundle identifier, the capabilities, and
      the deployment target
- [ ] `build: add desktop packaging` — an AppImage or a Flatpak on Linux, a signed `.app` on
      macOS, an MSIX on Windows
- [ ] `build: add the web build` — the manifest, the icons, the offline service worker, and the
      renderer choice argued for in a comment
- [ ] `ci: add the release workflow` — tagged builds for all six, with the artifacts attached
- [ ] `docs: update the readme` — the status section stops saying *not started*, and the
      getting-started section says how to reach `make dev-up` from each target, which differs on
      the web and should not be discovered

## Open questions

Recorded rather than answered, and each one should be settled before the phase that needs it.
The web-transport questions the first draft carried were closed upstream by `ce0c2ed`, `c2b8139`
and `6b8eacb`; what follows is what those commits did not reach.

### Blocking a phase

None. The three that were here were settled in Quire, and two of them were settled by being
disproved rather than fixed — which is why they are recorded instead of deleted.

- ~~**Discovery from a browser has no CORS policy.**~~ It has one, and not where this roadmap
  looked: `wellknown.go` sets `Access-Control-Allow-Origin` on the documents themselves, saying
  a reader's application may well be a page on another origin. The absence of a `corsPolicy` in
  the `VirtualService` was read as the absence of the header, and it was neither. Two
  constraints came out of checking it, and both are Atril's to honour — they are in
  [`architecture.md`](architecture.md).
- ~~**`WatchOperations` has never been exercised through the gateway.**~~ It had not been, and
  it works: Istio disables both the route timeout and the stream idle timeout on a gateway, so
  an idle stream is not cut. `7120164` pins it with a twenty-second idle window, verified by
  putting Envoy's fifteen-second default back and watching the test fail. One finding came out
  of it that changes client code — see the header-flush note in
  [`architecture.md`](architecture.md).
- ~~**The compose federation has no proxy.**~~ `901792d` adds one. `flutter run -d chrome`
  against `make dev-up` now reaches a node.

### Shaping a design

- **A webview on Linux and Windows.** The reader is epub.js on every target, and five of the six
  have a maintained host for it. Linux and Windows rest on `webview_cef` — a community package
  over CEF, whose Linux path is software-rendered, and which is a large native dependency to
  bind into a build for six platforms. If it does not hold, the fallback is not a Dart renderer
  — that would be a second CFI implementation and phase 9 says why it must not exist — but
  shipping those two targets without the reader while the library, the sync and the annotations
  still work. It is an empirical question and not a judgement: spike it before phase 9 rather
  than deciding it. *Phase 9.*
- **`flutter_inappwebview` was last published 23 months ago.** It is what carries the reader on
  Android, iOS and macOS, through `flutter_epub_viewer`. The package above it is current, and
  whether this one still builds clean against Flutter 3.47 is a thing to check rather than a
  risk to accept. *Phase 9.*

### Watching upstream

- **C21 is still open.** `internal/` has no outbox: a change made through the node's API writes
  the table and appends nothing to `sync.operations`. It is the reason Atril writes locally and
  pushes, the reason the eleven write RPCs are forbidden, and the reason phase 6 seeds a new
  device through the read calls. The day it closes, all three are revisited deliberately — the
  rule becomes a preference and the seeding step becomes unnecessary.
- **C22 is still open.** Nothing in the contract can tell a node that it is a replica, so the
  authorization screen of phase 12 grants a permission it cannot act on. What the screen says
  about that is a wording question, not a technical one, and it should be answered by whoever
  writes the defence rather than by the app.

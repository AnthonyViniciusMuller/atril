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
- [x] `feat: add logging` — one logger, levels from the environment, and nothing written to
      stdout anywhere else

## Phase 3 — The local replica

`drift` over SQLite, and the one place in the app that holds the reader's collection.

- [x] `feat: add the drift database` — the connection, the schema version, and the migration
      strategy. ~~Native through `sqlite3_flutter_libs`~~: that package reached its end of life
      when `sqlite3` 3.x began building and bundling SQLite itself through Dart's build hooks,
      and its last release contains no code at all — drift 2.32 moved to it and says so in its
      changelog. Native is `sqlite3` directly, opened on a background isolate. The connection is
      a conditional export for the reason `architecture.md` now gives at its own heading: a
      `dart:io` import does not parse for the web target, so the two cannot be implementations
      of an interface picked at run time
- [x] `build: add the drift web worker assets` — `sqlite3.wasm` and `drift_worker.js` under
      `web/`, and the web connection that picks OPFS where it is available and IndexedDB where it
      is not. Committed with the version they were built from, and with the check that fails when
      a drift upgrade leaves them behind — the worker and the package talk a protocol versioned
      with drift, so a stale pair compiles and then fails at the first statement. Both files come
      from the one drift release for that reason. The connection reports what the browser gave it
      and whether that survives a reload, because two of drift's four backings do not
- [x] `feat: add the identity tables` — the bound device, the reader, the origin server, the
      known-server catalogue, and the hybrid clock's floor, which phase 2 left behind a port. The
      device id lives here and not in the session store, because it survives logout. The origin
      server is a flag on the catalogue and not a table of its own — it is the node the reader is
      signed in at, and a partial unique index is what keeps a device from having two
- [x] `feat: add the library tables` — `ebooks`, `collections` and `ebook_collections`, each with
      the revision columns spelled out: `vector_clock`, `updated_at`, `device_id`, `deleted`. The
      membership table carries the unique `(ebook_id, collection_id)` C06 requires, because the
      pair and not the row is the record. The four columns are a mixin and not four copies: the
      reconciler reads them generically, so one spelled differently on one table would be a
      record the merge quietly skipped
- [x] `feat: add the reading tables` — `annotations` with a full revision, and `progress` with a
      clock and a timestamp and neither tie-break field, per C05, unique on
      `(ebook_id, device_id)`. `progress` deliberately does not reuse the revision mixin: its
      `device_id` is the row's own key and not a record of who wrote last, and a table offering a
      tie-break would invite the reconciler to apply one where nothing ties
- [x] `feat: add the operation log and the node cursors` — what this device authored and has not
      handed over, in the order it authored it, and the last position pulled from each node. The
      cursor is keyed by the node dialed: a position is that node's own order and two of them
      have nothing to do with each other. The order is sqlite's rowid and the identity is the
      uuid this device minted, because the identifier travels and a position does not; and the
      cursor never moves backwards, since a retry that answered with an older page must not undo
      a position whose operations are already applied. The `Operation` value the log stores and
      returns lands with it, in `domain/models`
- [x] `feat: add the record versions table` — the causal version last seen of each record this
      device has touched, and for the two associative entities the surrogate id this device
      minted. C18 is why the second half exists: a device that forgets the id it minted mints
      another on every write. The clock is merged and never replaced, because a device holding an
      unpushed change knows a version the node does not; and `RecordKey` is what makes a filing
      addressable by its pair and by nothing else
- [x] `feat: add the reconciler` — applies one operation to the local replica, per field, by the
      rule phase 2 established. Idempotent by operation id, because a node may deliver the same
      operation twice and receiving is what makes retries safe: an `applied_operations` table is
      what makes redelivery free rather than merely harmless, and what tells *duplicate* apart
      from *superseded*. The delta vocabulary lands here rather than in phase 7 — the reconciler
      cannot decode a change without it — so what is left for that phase is the authoring side
- [x] `test: prove the reconciler converges` — a generated operation log, applied in every
      shuffled order ~~reaching one state~~ **that a replica could legitimately receive**,
      reaching one state. Two corrections came out of writing it. An order inconsistent with
      causality is not one any replica receives — a node allocates its positions inside the
      writing transaction and a device pushes its own log in order — so those are what the
      generator produces. And a log whose concurrent writes claim *different* fields of one
      record does not converge at all: that is C17, open upstream, and Atril reproduces it
      because a client that settled it differently would disagree with the node. The last group
      of the test pins that as behaviour rather than folklore, and `architecture.md` records it
      beside the other findings the node will not tell us. The tombstone case is separate and
      explicit, as planned
- [x] `feat: add the blob store` — the e-book bytes, keyed by content hash, behind an interface
      with a filesystem implementation and a browser one. A write is staged and published under
      the digest the caller computed while streaming, because an import hashes the file as it
      reads it and cannot address the bytes until the last of them has been read — which is also
      what makes a write atomic. A browser with no origin-private file system is reported rather
      than worked around: it can still list, sync and stream, and phase 8 asks before offering to
      keep a book
- [x] `feat: report the storage budget` — what the store holds and what it may hold, as a number
      the interface answers. On the web that is `navigator.storage.estimate()`; ~~on the five
      native targets it is the free space on the volume~~ — there is no portable way to ask a
      volume how much room is left, and no package on pub covers all five (the maintained one has
      no macOS), so the choice was between a number absent on one target, a number that could not
      be verified on four, and none. Natively the budget reports what the store holds and says it
      is unmeasured, which refuses no download the platform has not refused. It costs least where
      it is missing: a native install keeps every book by default and has no budget to spend,
      while the web build, which does, has the browser's own answer. Phase 8 shows the number and
      is where this is worth revisiting. It exists because the web build spends it deliberately
      rather than discovering it: a reader whose next download fails deserves a sentence and not
      a crash, and one whose book was evicted deserves never to find out that way

## Phase 4 — Reaching a node

- [x] `feat: add the platform channel` — `channel_io.dart` and `channel_web.dart` behind one
      conditional export. The native side takes an optional CA so that `make dev-up` can be
      dialled; the web side takes the proxy's URL. Both addresses are one value, because the
      configuration is one struct compiled for six targets and a field only some of them read
      costs less than a configuration that knows which target it is. It is parsed where the
      configuration is read rather than at the first call, and a `grpc` authority that names no
      port is refused rather than defaulted to 443: the contract publishes `host:port`, so a bare
      host is a node saying something this client cannot act on, and a guess would be dialling
      somewhere nobody named
- [x] `build: let a shipped build reach the network` — not in the plan, and found by reading what
      the scaffold actually grants once there was something to dial. `flutter create` puts
      `android.permission.INTERNET` in the debug and profile manifests and not in the one merged
      into a release, because what needs it there is the tooling's own socket; and the macOS
      entitlements grant `com.apple.security.network.server` and not
      `com.apple.security.network.client`, which is the one the sandbox checks an outgoing
      connection against. Either way the app compiles, launches, and cannot reach a node — on two
      of the six targets, in the build that ships

- [x] `feat: add the session interceptor` — the bearer token on every call, a single-flight
      refresh on `UNAUTHENTICATED` that retries the call once, and the rotation the contract
      requires: the refresh credential presented is consumed and the reply carries its
      replacement, which is why the store is written before the session is adopted. The token is
      attached through a metadata provider rather than as static metadata, so a token that went
      stale between the client being built and the call being sent is refreshed before the
      request leaves. ~~All of it in the interceptor~~: `interceptUnary` has to return a
      `ResponseFuture`, which can only be built around a `ClientCall`, so an interceptor cannot
      answer with the result of a *second* call — the retry lives beside the call instead, in
      `SessionHolder.retrying`, and the clients wrap the two together. The skip list is the
      node's own `authn.PublicMethods()`, and it is not a convenience: `RefreshSession` asking
      for a token would refresh in order to refresh. Only the refresh credential is persisted —
      an access token written to disk outlives nothing useful — so a cold start exchanges before
      its first call, and `isSignedIn` is answered without a round trip
- [x] `feat: map grpc status onto the error vocabulary` — `GrpcError` to `AppException`, keeping
      the code and the field failures the node sends, so a rejected registration reaches a form
      as something it can point at. The table is `grpcx.Code` read backwards and is kept equal to
      it deliberately: `ABORTED` is a *conflict* and not a failed precondition, which is the
      difference between a device retrying an operation after reconciling and abandoning it. The
      two details travel in `grpc-status-details-bin` as `google.rpc.ErrorInfo` and
      `google.rpc.BadRequest`, and `package:grpc` parses them into types it keeps under `src/`
      and does not export — so `proto/google/rpc` vendors the two canonical files and `make gen`
      generates our own, which is also what lets a test build the trailer a node sends and read
      it back over a socket. A reason scoped to another domain is ignored rather than branched
      on: a detail attached by a gateway means what that gateway meant by it
- [x] `feat: add the session store` — the refresh credential in `flutter_secure_storage` on the
      five native targets. On the web there is no secure storage, only `localStorage`; the store
      says so in one comment and the settings screen says so to the reader. ~~Two
      implementations~~: the package's own web backing *is* `localStorage`, with an AES key that
      is itself in `localStorage`, so one implementation is already the split — what the web
      target lacks is secrecy and not a store, and `isSecure` is the flag phase 5's settings
      screen reads. The interface and the in-memory one landed with the interceptor, which
      needed something to hold. The credential is one JSON value under one key, because every
      platform's store writes one key at a time and two keys is a state where the token has
      rotated and the expiry has not. Three things the package costs elsewhere: the Linux build
      links libsecret, so CI installs its headers beside GTK's; the sandboxed macOS build needs a
      keychain access group or the store raises at the first write; and it is held at 10, because
      11's Android archive demands compile SDK 37 and the Gradle plugin this Flutter release
      ships supports 36 — found by building the target rather than by reading the changelog
- [x] `feat: add the api clients` — one thin client per gRPC service over the generated stubs,
      and the mappers between the wire types and the domain models, which is where the rest of
      `domain/models` lands: the reader, the device, the node, the work, the grouping, the mark
      and the position. Three of the five clients are smaller than the service they cover, and
      the missing methods are the point. `LibraryApi` and `ReadingApi` expose no write RPC at
      all — C21 — so what is left of them is the reads that seed a freshly bound device and the
      content calls, which carry bytes and not records. `SyncApi` leaves out the two calls a
      device is not the caller of: `ReplicateOperations`, whose caller is a peer proving itself
      with a certificate, and bidirectional `Sync`, whose acknowledgement means *durably
      written* and therefore belongs with the loop phase 11 builds around it. A wire enum this
      build cannot name is `null` on a record and a refusal on an operation, which is the
      difference between a work it cannot open and a change it must not apply somewhere nobody
      named. And the session and the client that refreshes it are a real cycle, closed with a
      `late final` at the composition root rather than pretended away
- [x] `feat: add connectivity awareness` — whether a node is reachable, as a stream. Not
      `connectivity_plus` alone, which reports a radio and not a route: a failed call is the
      signal, and the radio is the hint that it is worth trying again. The evidence is wired into
      `ApiClient` rather than into each caller, because that is the one place every call passes
      through and a client that had to remember to report would eventually not. A *refusal* is an
      answer and counts as reached — a `NOT_FOUND` is a node that received the request and
      decided — so only the two failures that mean nothing arrived mark it otherwise. The radio
      is used in the one direction it is honest: no interface at all is proof, and an interface
      appearing is a prompt to retry rather than a claim that a retry will work. The state starts
      optimistic, since a device that has tried nothing has no evidence

- [x] `docs: record the fourth conditional export` — `architecture.md` counted three and named
      the shape as being used "twice more"; `GrpcError` and `StatusCode` make a fourth, and it is
      of a different kind — the two types are one class each and `package:grpc` publishes them
      only through two libraries, one of which imports `dart:io` and the other `dart:js_interop`,
      so the split has nothing of this project's own on either side. It is written down so that a
      future session counts four rather than finding a rule that appears to have been broken. The
      same paragraph now records what the session store turned out to be: one implementation,
      because the package is already the split

## Phase 5 — The shell

- [x] `feat: add the theme` — Material 3, a light and a dark scheme, and the type scale the
      reader inherits. Named colours only; a hex literal in a widget is a theme that will
      disagree with itself. One seed and not a palette: Material derives the forty-odd roles
      from a source colour, so two schemes from one seed cannot drift apart in hue and a test
      says so. The scale is a modification of the baseline rather than fifteen styles written
      out — a copy of the baseline stops tracking the framework and records nothing this app
      decided; what it decided is a line height on the three body styles and no extra tracking
      on the titles. There is no third theme and no theme *setting*: the device already knows
      whether the reader wants dark, and a page's own background belongs to the engine phase 9
      renders it in
- [x] `feat: add localization` — `flutter_localizations`, `app_pt_BR.arb` and `app_en.arb`, and
      ~~the lint~~ that fails the build on a hardcoded string: Dart ships no such lint and none
      of the three ways to add one is a lint. A grep cannot tell `Text('Biblioteca')` from
      `Key('library')` and does not see a message wrapped over two lines; `custom_lint` is a
      plugin package inside the repository for one rule. So it is
      `tool/check_hardcoded_strings.dart`, which parses `lib/ui` and `lib/routing` and looks at
      *where a literal lands* — the first argument of a widget whose first argument is text, or a
      named argument the framework renders — with `// l10n-ignore` as the escape hatch and its own
      test, because a visitor that stopped matching would report nothing and nothing is what a
      clean tree looks like. It is `make l10n-check`, and `make analyze` depends on it. There is a
      third ARB, `app_pt.arb`, and it is empty: gen-l10n refuses a locale with a country code
      unless the bare language exists as its fallback, and what a generic Portuguese file would
      hold is the Brazilian text. Its four "untranslated" messages are written to a file under
      `build/` rather than onto the terminal, which is why holding `app_en.arb` to the template is
      a test and not the tool's own report
- [x] `feat: add routing` — `go_router`, the route table, and the redirect that sends a device
      with no session to onboarding and one with a session away from it. The guard tests
      `/onboarding` as a *prefix*, because phase 6 hangs registration, login and recovery below it
      and an equality would bounce a signed-out device off the screens it is being sent to use.
      The three shell destinations are branches of one `StatefulShellRoute`, so each keeps its own
      navigator and a reader comes back to the library rather than starting it over; the shell
      itself is a parameter, so this file holds the table and the guard and phase 5's next commit
      supplies the surface. Not in the plan: `SessionHolder` gained a `signedIn` stream and a
      `dispose`. A redirect that only ran on navigation would leave a device signed out by a
      refused refresh credential sitting on the library until the reader touched something, and
      what `GoRouter` wants for that is a `Listenable` — which `SessionHolder` cannot be, since it
      imports nothing from Flutter. The adapter is in `routing/`. There is also a not-found
      screen, for the one target with an address bar: `go_router`'s own error page is a stack
      trace on a red background, and a pasted link has no history to offer a back button
- [x] `feat: add the adaptive scaffold` — one navigation surface expressed three ways:
      `NavigationBar` on a phone, `NavigationRail` on a tablet or a small window, and an extended
      rail on a desktop. Chosen by width and not by platform, because a resized desktop window is
      a phone and a tablet in landscape is not. The thresholds are Material 3's, at 600 and at
      1200 rather than at 840: an extended rail is 256 pixels, and spending that out of 840 leaves
      a catalogue less room than the rail saved. It measures the space it was *given* and not the
      window, which is the number that decides whether a rail fits when something else is beside
      it. The destinations are one list in the order the router declares its branches, because a
      surface reports the index it was tapped at and two orderings written separately disagree
      silently — as a tap on *Settings* opening the annotations. Three destinations and not four:
      collections live inside the library (phase 8) and the sync status is a line in the shell
      with a screen behind it (phase 11)
- [x] `feat: add the entry points and the dependency graph` — `main.dart`,
      `main_development.dart`, and ~~one `providers` function per environment~~: the split
      belongs one layer up. The difference between the two builds is entirely an `Environment`,
      and two graph functions differing only in which factory they called would be two things to
      keep in step for no second behaviour — so it is `Environment.production` /
      `Environment.development` and one `providersFor(environment)`. Nothing below `main` reads a
      compile-time constant, for the reason Quire gives about `os.Getenv`: the configuration
      surface is one struct, and a widget that reads the environment is a widget that cannot be
      tested. There are two such constants and they are both read at the edge — `ATRIL_LOG_LEVEL`
      in `config/environment.dart`, and the local federation's certificate authority in
      `main_development.dart`. The second is a **flag and not a vendored file**: Quire generates
      those certificates before every `make dev-up` and does not commit them, so a copy here would
      be stale by the next run; the PEM is base64 in one `--dart-define`, which `make run-linux`
      and `make run-web` fill from the Quire checkout. A production build knows no node, and
      `initialEndpoint` carries no address rather than `null` — an absent endpoint and an endpoint
      with no address are the same state, and `NodeEndpoint` already names the second. Two things
      in the graph are lazy on purpose: a device with no session reaches onboarding without
      dialling a node nobody has chosen, and the session/auth-client cycle is closed by
      ~~resolving the refresher on first use rather than by a `late final`~~ — which was wrong,
      and is corrected in the fix below. Deferring the lookup defers *when* it runs and not
      *where* it looks: `provider` resolves upwards, and the client is declared under the holder
      because it reads the holder, so no context the holder can hold will ever find it. It is a
      `late final` at the composition root after all
- [x] `feat: add the desktop window configuration` — a minimum size and a remembered one on
      Linux, macOS and Windows, so the adaptive layout has a floor to be correct at. The floor is
      400×600 and is deliberately *below* the compact threshold: a narrow desktop window is meant
      to become the phone layout, and a minimum above 600 would be the app refusing the case the
      scaffold was written for. The three embedders set an initial size in C++, Swift and C++
      before any Dart runs and impose no minimum at all, so without `window_manager` this would be
      three native edits nobody reading `lib/` would find. The size is remembered and the
      **position is not** — a window restored to coordinates that were on a second monitor is a
      window the reader cannot find, and the failure is silent and needs a settings reset to
      escape. It goes to `shared_preferences` and not to a drift table: the local database is the
      replica, a window's width replicates to nobody, and it has to be readable before `runApp`.
      Writing is debounced, because a dragged edge delivers a resize per frame

- [x] `docs: record what the shell settled` — `architecture.md` still described
      `config/dependencies.dart` as "one function per environment", which this phase found to be
      one layer too low, and it named none of what the shell added: the two providers that are
      lazy on purpose, the third ARB file that exists because gen-l10n demands it, the window
      store's place outside the replica, and the fact that the no-hardcoded-strings rule is
      enforced by a program in `tool/` because Dart ships no lint for it

## Phase 6 — Onboarding (UC13, UC14, UC07, UC08)

- [x] `feat: add server discovery` — ~~`FederationService.DiscoverServer`~~ landed in phase 4
      with the rest of the federation client; what this commit adds is the direct
      `.well-known/quire/client` fetch for a device that has no node to ask yet — the *client*
      document and not the server one, which is what a peer reads to learn the key to pin. The
      fetch sends no header of any kind, not even `Accept`: the node answers the document with
      `Access-Control-Allow-Origin` itself, but the gateway admits `GET` on `/.well-known/*` and
      not `OPTIONS`, so anything that provokes a preflight is refused `403`. A reader types a
      domain; the app learns the base URL and the gRPC authority — **and not the JWKS URI**,
      which this entry claimed and `internal/shared/wellknown/wellknown.go` disproves:
      `jwks_uri` and `cert_fingerprint` are in the *server* document alone, because neither is
      a value a reader's application checks anything against. A descriptor read here carries
      three of five fields absent and that is the document, not a lookup that half-failed. The
      lookup is HTTPS for a typed domain and is never downgraded by a redirect, since the
      document is exactly as trustworthy as the channel it arrived on; `discoverAt` is the
      second entry point, for the local federation, whose nodes publish a `base_url` that
      resolves inside the compose network and nowhere else. `package:http` is promoted from
      transitive rather than added: its `Client()` is itself the platform split, which is what
      keeps this one file instead of a fifth conditional export
- [x] `feat: address a node by its domain` — not in the plan, and found by trying to write the
      row the screen below records: `known_servers` was keyed by the node's own identifier, and a
      node discovered directly has none. The client document publishes `base_url` and `grpc`, and
      the id in `federation.servers` is a value only `ListKnownServers` reports — which is a call
      a device cannot make before it has signed in at the node it is trying to reach. So the
      **domain** is the key: it is what the reader typed, what the lookup was addressed to, what
      every federated identifier carries, and what `LoginResponse.User.origin_server_domain`
      answers with, so it is the one name for a node that exists at every point in this app's
      life. The node's own identifier stays as a nullable `remote_id`, filled in by phase 12 and
      used to address nothing. `signed_in_reader` and `node_cursors` follow the key, and
      `rememberDescriptor` is deliberately not an upsert of the whole row: a lookup that wiped
      the pin and the id would be this device forgetting what it was told by reading a document
      that was never going to mention it. The schema version stays at one, because there is no
      installed database anywhere for it to promise anything to
- [x] `feat: point the channel at the chosen node` — also not in the plan, and the other half of
      what the screen below needs: the channel was opened once from the flavour's endpoint, and
      phase 6 is where the endpoint stops being a property of the build. `NodeConnection` holds
      it, opens a channel on the first call and closes it when the reader points somewhere else,
      and `providersFor` resolves the launch endpoint from the origin server in the catalogue —
      which is why the database is opened at the composition root rather than behind a lazy
      provider. It is a *supplier* and not a `ClientChannel`, which was the obvious shape and is
      not available: `createCall` returns a `ClientCall` and `onConnectionStateChanged` a
      `ConnectionState`, and `package:grpc` publishes both only through `grpc.dart` — the library
      that also exports the HTTP/2 channel and so `dart:io`, which does not parse for the web
      target. An implementation of that interface could not name its own signatures on six
      targets. So the five clients build their stub per call instead of holding one: a generated
      client is a channel, some options and `static final` methods, and a `late final` stub would
      be a stub bound to whichever node this app was pointed at when it was first read.
      `NodeEndpoint.of` fills both lanes from one document — `grpc` for the native lane, the base
      URL for the browser, since the authority a node publishes is what a *peer* dials — and
      `Environment.endpointFor` overrides it for the local federation, whose published addresses
      resolve inside the compose network and nowhere a host can reach
- [x] `feat: add the server selection screen` — the first screen a new install shows, with the
      development federation reachable in one tap in a debug build. The identifier is
      `@local_name:server` and the server half is which node the call was addressed to, so this
      screen is not a preference — it is half of the reader's name. It is also the app's first
      repository and its first view model, and both are the shape everything after them follows:
      `ServerRepository` looks a node up, records it and points the connection at it in one call,
      because a node recorded and not dialled is a row nothing acts on and a node dialled and not
      recorded is a choice the next launch has forgotten. The choice is held in memory and not in
      the catalogue: what the catalogue records is that a node was *discovered*, and what makes
      one of its rows the reader's own is a login. The screen ends here rather than moving on,
      because there is nowhere to move on to until the two commits below exist — a selection
      screen showing what is selected is the whole of its job, and the two ways onward are added
      by the commits that create somewhere for them to go
**The next two are in the other order.** Registration was written down first and login has to
land first: `RegisterUser` returns no session, so a reader who has just created an account goes
to the sign-in screen — which means registration is reached *from* login and returns to it, and
a registration commit landing first would end at a route that matches nothing.

- [x] `feat: add login and device binding` — UC07. The `DeviceBinding` carries this device's id
      when it has one and its name and platform when it does not, and the reply is where a new
      device learns the id its vector-clock entries will be counted under. The platform string is
      free-form by design, so it says `android`, `ios`, `web`, `linux`, `macos` or `windows` and
      the node is not redeployed to add a seventh; it is read at the edge, in `config/platform.dart`,
      because a repository that asked the framework what platform it was on could not be tested as
      any other. Everything is written before the session is adopted — the device identity, the
      origin node, the reader's row — since a device the shell believes is signed in and that
      cannot say who as is a library it cannot fill. The screen navigates nowhere on success:
      adopting the session is what the guard watches, and a screen that also pushed a route would
      be a second answer to where a signed-in device belongs. `ServerRepository.adoptOrigin` is
      the piece that was not obvious — the node answers with the domain the reader is *named* at,
      which is allowed to differ from the one that was typed (an apex redirecting to a canonical
      host), and a reader's row needs a catalogue entry to reference either way
- [x] `feat: add registration` — UC14. `RegisterUser` against the discovered node, the four
      constraints validated client-side against the same rules the contract publishes — written
      out rather than compiled as a pattern, as `internal/identity/domain/user` writes them, so
      that a violation can say which part was broken — and the server's field-level rejections
      rendered on the fields that caused them. One mapping serves both, because the field names
      are the contract's own: a `BadRequest` names `local_name`, and so does the check that ran
      before anything travelled. Every violation is reported and not the first, since a form
      answering one field at a time makes the reader submit four times to learn four things the
      client already knew. Nothing is written locally: a registration is an account on a node and
      not a reader on this device, and what makes this device that reader's is the login that
      follows — which is where the screen hands them, with the name they chose carried in the
      location so that the hand-off survives a reload in a browser
- [x] `feat: add logout` — clears the session and nothing else. The device id, the local replica
      and the pending log stay, because logging out is not unbinding, and the settings screen says
      so where the reader can read it: what signing out does *not* do is the part they have no
      way of knowing. The credential is presented to `Logout` rather than inferred from the
      session, which is what lets a device whose access token has already expired end its session
      without refreshing first — and the local half happens whether or not the node could be
      told, because a reader who asks to sign out on a train is signed out and what survives a
      failed call is a credential nobody holds. It is also the settings screen's first section
      and the app's first view model over a stream: the reader is read from the local database,
      so it is right offline, and it stops naming them the moment a refused credential ends the
      session under them
- [x] `feat: add password recovery` — UC08. Two screens: request, and reset from a token. The
      request reports the same outcome whether or not the address is registered, and the screen
      does not helpfully say otherwise — the confirmation is worded to be true either way, the
      only failure it can show is one about reaching the node, and the address is not logged,
      since whether an address is registered somewhere is the fact the whole call is built not to
      reveal. What *is* checked is the shape of what was typed, which is a different question and
      is safe to answer. The reset is a location of its own rather than a step inside the
      request, because the code arrives in a mail client — as often as not on another device —
      and a link can carry the credential in the location. The node answers one refusal for four
      states (never issued, spent, expired, somebody else's), and the screen repeats that
      indistinction rather than inventing an explanation. A successful reset clears this device's
      session as well: the node has ended every session of every device, and keeping this one
      would be presenting a credential it has already thrown away, on every call
- [x] `feat: seed a newly bound device` — the one place the read RPCs are called: `ListEbooks`,
      `ListCollections`, `ListAnnotations` and `ListReadingProgress`, straight into the local
      replica, before the first pull. A device bound to a reader with a history has to start
      somewhere, and pulling from position zero would only replay what the log has — which, until
      C21 closes, is not everything. What is written is what the node said: a work, a grouping and
      a mark carry their `Revision` on the wire and a position its `Version`, so those four
      reconcile from the seeded row exactly as if they had been pulled. **The filing is the
      exception, and the contract is why**: there is no `ListEbookCollections` and no
      `EbookCollection` message, so a membership is visible only through the filters on the two
      list calls and neither carries a revision for it. A filing is therefore seeded with no
      causal history at all — the empty clock and the epoch — which makes the first operation
      about it supersede the seeded row: it is there so a reader's shelves are not empty on a new
      device, and it yields to the first thing the log says. Its surrogate identifier is minted
      here, which is what C18 says a replica must do, and `utils/identifiers.dart` is that minter
      — sixteen lines over `Random.secure` rather than a package, and what phase 7 will author
      records with. A record in a format or of a kind this build cannot name is skipped loudly
      rather than written as something it is not, which is the same answer the reconciler gives
      the operation that would have created it. The seed is not one transaction — every write is
      an upsert keyed by an identifier the node chose, so an interrupted run is finished by the
      next — and its failure does not fail the sign-in: a failed seed costs a library that fills
      in later, and refusing the login would cost a reader who cannot get in because one page of
      their annotations timed out

## Phase 7 — Authoring a change (UC09, UC10)

This phase writes no screen. It is the path every screen after it uses, and it comes first for
that reason.

- [x] `feat: add the operation author` — one entry point for a change to a replicable record: it
      resolves the target, stamps the delta on the version this device last saw, ticks its clock
      entry, appends to the local log and ~~applies to the local replica~~ **applies it through
      the reconciler** in one transaction. The caller does not branch on connectivity, because
      there is nothing to branch on. Two things came out of building it. The local write is the
      reconciler's, not the author's: an author that wrote the row itself would be a second
      implementation of the merge, and the first divergence between the two would be a change
      that looks applied here and reconciles differently everywhere else — so what the author
      contributes is the version, the name and the log entry, and applying it is the ordinary
      path run against an operation this device happens to have written. And the instant is
      stamped on the record's own floor as well as on the device clock, which is not redundant:
      phase 6's seed writes the node's timestamps into the replica without folding them into this
      device's clock, so a record seeded and then edited here would otherwise carry a causally
      later version with an earlier instant — the one edge C01's acyclicity argument depends on
      not existing. This commit authors the three records addressed by their own identifier; the
      two C18 is about land two commits below
- [x] `feat: add the delta vocabulary` — ~~the field names~~ landed in phase 3 with the
      reconciler, in `data/services/sync/delta.dart`, because a reconciler cannot decode a change
      without them. What is left here is the authoring side: writing a delta that claims exactly
      the fields the reader changed, where a field left unnamed keeps whatever device wrote it
      last and a field named as JSON null is a field the reader cleared. `DeltaWriter` is the
      mirror of `Delta`, in the same file and on the same encoding, and every claim optionally
      takes the value the record already holds so that one that changed nothing is not made. That
      is worth more than the bytes: reconciliation is per record and not per field (C17), so a
      delta restating a title the reader never touched carries this device's claim to it, and the
      next merge against a device that *did* change it is settled by a tie-break rather than by
      what anybody meant
- [x] `feat: resolve the associative entities by natural key` — C18. An operation on a filing
      carries `(ebook_id, collection_id)` in its delta and an operation on a position carries
      `ebook_id`, the device half being the authoring device by C05. The surrogate id is
      provenance, and it is read back out of `record_versions` rather than minted per write —
      checked against `internal/sync/infra/service/records/{membership,progress}.go` rather than
      assumed, which is also where the third finding came from: **the node ignores the kind of
      change on both of them.** A filing is a register, so filing and unfiling are the two
      directions and there is no update between them; a position is refused only a deletion, and
      insert against update is not distinguished at all. So the author derives the position's
      kind instead of asking for it — a position has exactly one writer (C05), so whether there
      is one to update is exactly whether this device has written one before, which is a question
      no caller should have to answer
- [x] `test: pin the write path against the contract` — a test that walks `lib/` and fails if
      anything calls one of the ~~eleven~~ **twelve** write RPCs. It is the executable form of
      the rule in [`architecture.md`](architecture.md), and it is what makes the rule survive a
      future session. There are twelve and not eleven: `LibraryService` declares eight calls that
      write a replicable record and `ReadingService` four, which is what `architecture.md`'s own
      blockquote has always listed — the count was wrong here and in `library_api.dart` and both
      are corrected. The check is three tests rather than one, because a pinned list of names is
      a check that stops guarding anything the day the contract renames one of them and passes
      forever afterwards: the names are asserted against the vendored `.proto` files, and the
      visitor is run over a call it must refuse and over the prose that names the same RPCs and
      must not be flagged

## Phase 8 — The library (UC01, UC02, UC03)

- [x] `feat: add the library repository` — a stream of the reader's collection out of the local
      replica, sorted, filtered, and correct while offline because there is nothing else it could
      be. The sort is not in SQL, and that is the finding: sqlite ships three collations and all
      three are ASCII, so `NOCASE` folds `A` onto `a` and leaves `Á` alone — a shelf ordered by
      the database would put *Sertão* after *Zweig* in the app's own language. A custom collation
      registered into the connection would mend the five native targets and not the sixth, where
      the database is a WebAssembly build, so the fold is Dart's in `utils/collation.dart` and
      one behaviour serves six targets. It is the same fold the search of the last commit
      matches through, because a search that matched differently from the way the results are
      ordered would be two answers to one question. The join that narrows the collection to one
      grouping stays in SQL, and the answers are `Stream<Result<…>>`: a stream that failed by
      ending would be an exception crossing a layer boundary, and a list that stopped arriving
      looks exactly like an empty collection
- [x] `feat: add the library screen` — a grid on a wide window and a list on a narrow one, with
      the empty state that tells a new reader what to do next. There are **two** empty states and
      not one, which is what the query object landed for: a reader with no books is told how to
      start, and a reader whose shelf is empty is told which shelf and offered the way back to
      the whole collection. A third state has no words at all — before the first answer the body
      is blank rather than a spinner, because this is a query over rows the device already holds
      and a progress indicator on screen for two frames is a flash a reader reads as a failure;
      it is also what keeps `pumpAndSettle` from waiting forever on an animation nothing ends.
      The grid threshold is the navigation surface's own `compactWidth`, so that the two layouts
      change together rather than at two widths a dragged window crosses separately
- [x] `feat: add e-book import` — a file picked, hashed with SHA-256 as it is read so the bytes
      are never held twice, written to the blob store under that digest, and registered as an
      operation. The digest is what identifies the bytes across the federation, so importing the
      same file twice on two devices converges on one object. The picker is `file_selector`,
      flutter.dev's own, behind a port whose whole surface is a name and a *stream*: a path is a
      concept the web target does not have and a `Uint8List` is a book held twice, and the one
      shape all six targets share is also exactly what a digest computed as the bytes go past
      needs. The bytes are written before the record, deliberately — a device interrupted between
      the two has a file nothing names, which the next import of the same book adopts for free
      because the store is keyed by the digest, while the other order leaves a work whose file
      this device never had. The format is guessed from the extension and never from the bytes,
      which is `internal/client`'s own `describe` and is checked against it: the node stores what
      it was told and never opens the file, so a guess made here is one nothing downstream can
      correct
- [x] `feat: extract epub metadata on import` — title, author, publisher, language and the cover,
      out of the OPF. What the file did not say is absent and not empty: a work whose author is
      unknown and one whose author is the empty string are different claims, and the contract
      spells the difference with `optional` — so a field the package document did not carry is
      not *claimed* either, which matters more than the column: a delta naming `author` as null
      is this device telling every replica the work has none. Three things came out of building
      it. The OPF is found through `META-INF/container.xml` and its cover href is resolved
      against the package document's own directory, which is the difference between reading most
      files and reading the ones whose publisher used a subdirectory. There are two ways to
      declare a cover — EPUB 3's `properties="cover-image"` and EPUB 2's `<meta name="cover">` —
      and both are in every reader's library. And the cover is **not** in the blob store and does
      not replicate: it is derived from a file this device holds, the store's digests are what
      the reader is shown in a storage budget, and a device that downloads the book later
      extracts its own. That is the first table this phase adds and therefore the app's first
      migration — every version so far only adds, so the whole of it is drift's `createAll`,
      whose statements are `CREATE TABLE IF NOT EXISTS`
- [x] `feat: add content upload` — the chunked shape D11 added, on all six targets:
      `BeginEbookUpload` declares the size and the digest and is refused there if the node will
      not take it, `PutEbookChunk` carries each chunk at the offset it continues from, and
      `FinishEbookUpload` is where the node's hash is checked against what was declared. It is
      independent of the record: the call names a digest and not an e-book, so ~~an import queues
      its operation and uploads its bytes without either waiting for the other~~ **the record
      does not wait for the bytes — and the bytes do wait for the record.** That is C16, checked
      against `internal/library/application/upload/rules.go` rather than assumed, and it is the
      one assumption of this phase that turned out false. Because the call carries no work
      identifier the node has nothing to check it against but one thing: whether the calling
      reader already holds a work naming the digest. The flow the contract describes is
      `CreateEbook`, read `content_missing`, then upload — and Atril never calls `CreateEbook`,
      so the work reaches the node only when the log is pushed. Until then the upload is refused
      `unclaimed_content`, which is a *not yet* and not a failure: nothing about the file is
      wrong and the same call succeeds after the next push. The uploader therefore does not give
      up on such a transfer, the queue two commits below is where one waits, and phase 11's loop
      is what will drive it. Recorded in `architecture.md` beside C18 and C21. The chunk is 256
      KiB, which is `internal/client`'s own number rather than a coincidence — gRPC refuses a
      message over four megabytes and a client that sized its chunks by the file would work on
      every book it was tested with and fail on the atlas
- [x] `feat: resume an interrupted upload` — the property the client stream did not have. A
      `PutEbookChunk` reply carries `received_bytes`, which is the offset the next chunk must
      carry, so a caller whose connection died continues from what arrived and one that lost a
      reply and repeated a chunk is told so rather than corrupting the file. `already_held` is
      handled at both ends: another device of the same reader may have sent the file in between,
      and then there is nothing to send. `DiscardEbookUpload` on abandonment, because a client
      that has given up should say so. Two things came out of building it. A resumed session is
      asked where it is with **a chunk of no bytes** — the node does not write a chunk at an
      offset it is not expecting and answers with the offset it *is*, so the question costs one
      call and no transfer, where sending the first real chunk to be told it landed nowhere would
      cost a quarter of a megabyte on exactly the network this shape exists for. And a discard is
      not what every failure deserves: a connection that dropped leaves the session **standing**,
      because the node is holding what arrived and that is the whole point, while a refusal
      nothing can improve — the node's ceiling, a store contradicting itself — releases it. A
      failure to discard is never reported, because it would replace the reason the transfer
      stopped with the reason the courtesy did
- [x] `feat: carry an upload across a restart` — the `upload_id` and the offset in the local
      database, so closing the app does not start a large book over. The node's `received_bytes`
      is the authority and this device's opinion is a hint: D11 stages the bytes in a temporary
      file held in the process, so a node restart or an expiry invalidates a session this device
      is still holding. Every call is therefore written to fall back to `BeginEbookUpload`, and a
      refused chunk is a beginning rather than a failure. The queue is a table beside the
      operation log and not part of it, because the two are owed separately and C16 is why they
      have to be: the record travels when the log is pushed and the file waits for that push, so
      every freshly imported book's *first* attempt is refused `unclaimed_content` and stays
      queued. Two things fell out of writing it. The session is recorded **before a byte
      travels** — a device told about the identifier only once a chunk had landed would forget
      every session that opened and then lost its connection, which is the case the whole shape
      exists for. And the offset written down is what the node *reported*, never what this device
      sent, which is visible in the test: a connection that drops with the reply in flight leaves
      the row saying nought while the node holds sixty-four bytes, and the resume asks the node
      rather than believing the row. A device that wrote down what it sent would resume past
      bytes that never landed and find out at the digest, after the whole file had travelled
- [x] `feat: add content download` — `DownloadEbookContent` into the blob store, ~~resumable~~
      **not resumable, and it cannot be**, cancellable, and reported per book. A node that
      replicates this reader without their files answers that it does not hold them, and that is
      a legitimate state and not an error (D02). The correction is the contract's shape rather
      than a shortcut: `DownloadEbookContentRequest` carries an e-book identifier and *no offset
      and no range*, so there is no way to ask a node for the second half of a file, and an
      interrupted transfer starts again. What the contract does give is the description **first**,
      before any bytes — so the digest and the length are known in advance, and that is what this
      commit spends. The bytes are hashed as they arrive and checked against the digest the
      *work* names before anything is committed, because `BlobWrite.commit` names an object
      rather than checking one: a truncated or altered transfer stored under a name that promises
      otherwise is exactly what the digest exists to prevent, and the only place to notice is
      here. Nothing partial is ever kept, which is also what makes starting again all an
      interruption costs, and cancelling discards for the same reason — a reader who stopped a
      download has stopped wanting the book on this device. Cancelling **breaks out of** the
      stream rather than throwing out of it, which is what ends the call rather than abandoning a
      stream the transport is still holding open
- [x] `feat: add offline pinning` — which books this device keeps. On the five native targets
      every book is kept and the control is there to release one; on the web nothing is kept
      until the reader says so, and the screen shows what is held against the budget phase 3
      reports. It is one mechanism with two defaults rather than two features, because the
      question a reader is answering is the same one — *is this book here when the network is
      not* — and only the honest answer differs by platform. The shape that carries both is a
      table of **decisions** and not a list of kept books: a row says what the reader chose and
      its absence is what the platform answers, which a membership list could express in one
      direction only. Two things came out of it. The key is the digest, as it is in the store and
      in the queue, so two works naming one file are one decision — they *are* the same bytes.
      And a release is **refused while the file is still owed**: a work whose transfer has not
      finished exists on this device and nowhere else, so *free the space* would be the one
      gesture in this app that destroys something a reader cannot get back. The per-book control
      lands in the settings screen's storage section, which is where a reader looks for what is
      taking up room; the detail screen of the next commit offers the same decision about the
      book they are looking at
- [x] `feat: add the e-book detail screen` — the metadata, the cover, where the bytes are, and
      the actions. *Where the bytes are* is not a nicety on this screen; it is D02 reaching a
      reader, and it is one value rather than three booleans because the states are not
      independent and the sentence depends on the combination — a book can be here and still owed
      to the node, which every freshly imported one is, and a book that is neither here nor owed
      is one whose file is on the node. `ContentState` is what carries that, and the four
      sentences it selects are what makes the refusal to release the only copy make sense rather
      than look arbitrary. Two other things are worth recording. A work another device deleted is
      a **state** and not a failure — the tombstone arrived, the reconciler applied it, and the
      screen says so with the reason instead of apologizing for working — and it is told apart
      from *the first answer has not come back* by a flag, because saying a book was deleted
      before the query has run is a lie one frame long. And the location carries the identifier
      rather than the work: it is nested under the shelf, so the way back is where the reader
      came from, and it survives a reload in a browser and a link somebody pasted
- [x] `feat: add metadata editing` — RF05, including the extra metadata the format carried and
      the contract does not name. It is an object and never a scalar, because the column it lands
      in is `jsonb` and constrained to one. The form hands over **every** field and the
      repository works out what changed, which is C17 deciding a layering question: a screen with
      its own dirty flags would be a second answer to *what did the reader touch*, and the two
      would disagree the first time a field was edited back to what it was — while a delta
      restating a title nobody touched carries this device's claim to it and loses the next merge
      by a tie-break rather than by intent. An edit that claims nothing is not an operation at
      all. Two smaller things fell out. An empty field is a field the reader **cleared**, because
      a form has no other way to say *there is no author*, and clearing is a claim rather than a
      silence. And the extra-metadata editor edits text and hands everything else back untouched:
      `subjects` is a list and `series_index` is a number, so a form that rendered them into text
      boxes would turn a list into a string the moment the reader saved anything
- [x] `feat: add deletion` — a tombstone, never a removal, with the undo that a tombstone makes
      cheap. The undo is **one operation carrying nothing**: a record's `deleted` flag travels on
      the revision and the revision is derived from the kind, so an update on a tombstoned record
      lifts it — here and, by the same rule in `internal/sync/infra/service/records`, everywhere.
      That needed a correction to phase 7's author, which refuses an update claiming no field: a
      restore claims none and is still a change, so `Change.restore` says so and is exempt for the
      reason `Change.delete` is — the kind *is* the claim. The file is left alone and its transfer
      left queued, because a tombstoned work still counts for C16's check on the node, so a book
      deleted mid-upload finishes uploading and an undo finds the file where it should be.
      **And this is where phase 7's write-path check had to be narrowed.** It walked all of `lib/`
      and reported the twelve RPC names wherever they were spelled, which was cheap while nothing
      else spelled one; the reader's vocabulary for UC01 and UC03 is the contract's own — *delete
      this book*, *create a collection*, *add a book to a shelf* — because they name the same
      operations, so `LibraryRepository.deleteEbook` collided with `DeleteEbook`. It now walks the
      files that could be *making* a call: the ones under `data/services/api` and the ones that
      import a client, the stubs or `package:grpc`. The narrowing is itself pinned, by asserting
      that every `*_api.dart` there counts as a client
- [x] `feat: add collections` — UC03. Create, rename, describe, delete, and the two kinds the
      contract admits. A collection is a grouping the reader defined and a category is not, and
      the screen does not blur them: two headings, two lists, and one choice in the form that
      makes either. A single list with a badge would be this app deciding the distinction does
      not matter, which is a decision about the reader's library and not this app's to take —
      and the split lives in the view model, where it can be tested, rather than in a widget
      filtering as it builds. Deleting a shelf is not deleting what was on it, and the message
      says so **in the same sentence** rather than in two joined with a space: the fear that
      stops somebody tidying their library is exactly that, and where that clause goes is a
      translator's decision. The route is `/library/shelves`, declared *before* `/library/:ebookId`
      because `go_router` matches in declaration order and a parameter would otherwise swallow a
      literal and try to show a book called *shelves*
- [x] `feat: add filing a work under a collection` — ~~UC02~~ **UC03**, and the reason C06 exists:
      two devices that add and remove the same book from the same shelf while offline reach the
      same answer, because membership is a register per pair and not a row. The use case was
      misnumbered here: `AddEbookToCollection` is declared under UC03 in the contract, which is
      where organizing the collection lives; UC02 is the import. What the commit shows is the
      register: filing and unfiling are the two directions, the row is reused and its tombstone
      flipped rather than a second one appended, and the surrogate identifier this device minted
      is reused so the log does not fill with new names for one record. Both are pinned as tests.
      The chooser applies each mark as it is made rather than collecting them until a dialog
      closes, which is what a register makes natural — filing a work and filing it again are one
      request, so there is nothing to batch and nothing to undo if the reader walks away half way
      through
- [x] `feat: add search and filtering` — over the local replica, by title, author, collection and
      format. No RPC: the collection is here. The format is an equality on a column and stays in
      SQL; the search is matched in Dart on the **same folded key the shelf is ordered by**, which
      is the first commit of this phase paying for itself — `LIKE` in sqlite is ASCII-insensitive
      and nothing else, so a reader who typed `sertao` would find nothing, and one who typed
      `Sertão` would find it under a rule that disagreed with the order the results came back in.
      Every word has to match something and not the phrase in order, because a reader who types
      an author and a title is naming two things. It matches what it was given and does not guess
      a plural: `sertao` does not find *Os Sertões*, and a stemmer would decide on the reader's
      behalf which words are the same word — in a library that holds more than one language.
      There are now **three** empty states rather than two: *you have no books* is where to
      start, *nothing on this shelf* names a place, *nothing found* names what was asked for —
      and the last two share one way out, which undoes the search, the format and the shelf at
      once, because a reader looking at nothing should not have to undo three filters one at a
      time to find out which was the problem. Nothing is debounced: the answer is a query over
      rows this device already holds, and a delay would be this app pretending to wait for a
      network it is not talking to

## Phase 9 — The reader (UC04)

One EPUB CFI implementation — epub.js — hosted six different ways. The locator is the thing
that has to be right: the node stores it, replicates it, and hands it to the reader's other
devices, so a CFI authored on a phone must resolve on the desktop or an annotation lands on the
wrong paragraph after a sync. That is what decides the shape of this phase.

**The split is one engine and several hosts, never several engines.** A Dart CFI implementation
beside a JavaScript one would be two answers to "where is this passage", agreeing almost always,
and the disagreements would arrive as corrupted annotations a long way from their cause. So
epub.js is loaded from one file and every platform runs it; what differs is only what gives it a
DOM.

The two open questions this phase was told to settle first were spiked before it started, and
both answers changed the table below.

**The engine is already bundled, by the package.** `flutter_epub_viewer` 2.0.0 ships epub.js,
JSZip and the page and glue that drive them as assets of its own, published under
`packages/flutter_epub_viewer/lib/assets/webpage/…`. Bundling a second copy — which is what the
first commit here used to say — would have put *two* engines in the app and left the desktop host
running the one the other five do not. So the engine is pinned rather than vendored: the package
is constrained to an exact version, `data/services/epub/engine.dart` records the digest of every
asset the host page reaches, and the desktop host loads those same bytes. What the roadmap wanted
from "bundle it" — a renderer that cannot change under a locator that has already been replicated
— is what the digest delivers, and the version string never could.

**Windows has a maintained webview and does not need CEF.** `flutter_inappwebview` supports it
through `flutter_inappwebview_windows`, and `flutter_epub_viewer` chooses its native path on
`dart.library.io` rather than on a platform list — so Windows runs the same host as Android, iOS
and macOS with nothing written for it. That leaves `webview_cef` carrying **Linux alone**, which
halves the surface the round-trip test has to cover and takes a 660 MB native dependency off a
target whose operating system already ships a browser engine.

| Target | Host |
|---|---|
| Android, iOS, macOS, Windows | `flutter_epub_viewer`, over `flutter_inappwebview` |
| Web | `flutter_epub_viewer`, epub.js in an `<iframe>` through `dart:js_interop` |
| Linux | `webview_cef`, CEF rendered to a Flutter texture |

**The Linux spike was run and it holds.** `flutter build linux --debug` against `webview_cef`
0.6.2 and Flutter 3.47.1 succeeds. Three things came out of it that are this phase's to carry,
and they are recorded here because none of them is visible from the package's README:

- CEF is downloaded at build time — 658 MB, into the pub cache, once per machine — and the
  shipped `libcef.so` is 244 MB stripped. A Linux bundle goes from a few megabytes to about 300,
  which is the size an Electron application ships and is the price of the sixth target having a
  reader at all.
- The plugin's CMake step **patches `linux/runner/main.cc` and `my_application.cc` in place**: a
  CEF process bootstrap before `g_application_run`, and two key handlers on the view. The scripts
  are idempotent and guarded by greps, so the patch is committed here and the build is a no-op
  over it — which turns a silent mutation of tracked files into a reviewed diff.
- `xclip` is wanted at run time for pasting into a CEF area, and its absence is a warning rather
  than a failure.

- [x] `feat: pin the epub.js engine` — the engine named, pinned and credited. `pubspec.yaml`
      constrains `flutter_epub_viewer` to an exact version rather than a range, because a caret
      would let `pub upgrade` move the renderer under a locator that has already been written
      down and replicated. `engine.dart` names the asset keys every host loads and the sha-256 of
      each, and the test hashes what the bundle actually holds — so the engine changing is a red
      build rather than a highlight landing on the wrong paragraph six weeks later. The digests
      cover the closure and not just `epub.js`: `epubView.js` is what asks the renderer where the
      page starts and hands the answer across the bridge, so a change there moves the locator
      exactly as a change to the renderer would. The licences of epub.js and JSZip are committed
      and registered, because Flutter registers a resolved package's own `LICENSE` and knows
      nothing about the two libraries vendored inside it — the package's BSD-3 covers its author's
      work and says nothing about theirs. One check in it was written twice: the host page carries
      two commented-out CDN tags, and a *nothing is fetched at run time* assertion that read
      commented-out markup would be red on a page that fetches nothing, which is an assertion
      somebody deletes
- [x] `feat: add the epub host interface` — the port every platform implements: open a book from
      the blob store, render it, navigate, report the current CFI, resolve one, and apply a
      highlight over a CFI range. It is the whole surface the reader feature knows, and it names
      no webview. One invariant is stated as a rule rather than left to each implementation to
      observe: **a locator crosses the port unchanged, in both directions** — no normalizing, no
      trimming, no re-encoding — because two hosts that each tidied a CFI slightly differently
      would be two CFI implementations wearing one interface, which is this phase's failure
      arriving by the back door. The book crosses as bytes and not as a stream or a path: epub.js
      reads a zip by seeking in it, the web target has no path, and on the native targets the file
      lives in a blob store addressed by digest. Styling is in the port from the start even though
      the settings screen is four commits away, because the port is meant to be the whole surface
      and a port that grows a method per screen is a port nobody can implement against
- [x] `feat: add the webview epub host` — `flutter_epub_viewer` on the five targets it reaches:
      Android, iOS, macOS and Windows through `flutter_inappwebview`, and a browser through the
      same package's `<iframe>` and `dart:js_interop` path. It is **one** implementation of the
      port and not two, and that is the finding rather than a shortcut — the package's own
      conditional export on `dart.library.io` is the split, so a second class over it would have
      the same body. The roadmap carried these as two commits on the assumption that the web path
      needed writing; it needed checking, and it holds. What this commit writes is the mapping
      onto the port: the package already exposes CFI for the position, for navigation and for
      extracting a text range. Two places are not mechanical and both are commented where they
      happen — the whole `body` rule is built in one place, because the glue assigns custom CSS
      *over* the colours it set separately and a rule split between the two loses whichever was
      written first; and the passage behind a CFI range is fetched through the glue function that
      takes a range, because the package's Dart API takes two end CFIs and splitting a range back
      into its ends would be parsing a CFI in Dart. `allowScriptedContent` stays false, which is
      a security decision rather than an untouched default: a reader's library holds files they
      were given, and on the web the rendering context is a same-origin iframe.

      **It cost a dependency knot the roadmap did not see coming, and the resolution is three
      lines in the pubspec.** `flutter_inappwebview` 6.1.5 — the stable release — cannot build
      for Android at all under this Flutter's Gradle plugin, and it fails while Gradle is still
      evaluating that package's own build file, so there is no fix on this side. `6.2.0-beta.3`
      fixes it and brings an endorsed Linux implementation over WPE WebKit, which Flutter then
      adds to every Linux build and which fails at CMake because WPE is packaged by neither
      Ubuntu nor Debian. So the pubspec asks for the beta by exact version and *declines* the
      Linux implementation, replacing it with `tool/no_wpe_webview` — a package of the same name
      that declares no platform. Android, web and Linux were each built to prove it. The three
      warnings Flutter prints about the missing default plugin are left visible, because they
      are an accurate description of what is being done
- [x] `feat: add the desktop epub host` — `webview_cef` for Linux, loading the same pinned assets
      over a loopback server, because a CEF webview has no asset protocol to be handed and the
      host page resolves its scripts by relative path. The bridge is the same one: the package's
      glue talks to `window.flutter_inappwebview.callHandler`, and both the browser host and this
      one shim exactly that — so the three hosts differ in what gives epub.js a DOM and in
      nothing above it. The runner patch lands here, committed and annotated rather than applied
      at build time.

      The server is the part worth reading. It binds the loopback address only, serves **exactly**
      the closure `engine.dart` pins and answers 404 to everything else — which is not tidiness:
      the page rendering in that webview is a file somebody else wrote, and a server that would
      hand it the rest of the bundle if asked is a server handing a book the application's
      insides. It is one server for the process rather than one per book, and nothing is copied
      to disk, so what is served is what `engine_test.dart` hashes rather than a second copy that
      outlives the run. That is also the one place in the whole chain where a byte of the engine
      passes through this project's own code, so its test hashes every asset off the socket.

      The port picking is the **fifth** conditional export and the first whose two sides are both
      this project's code: the server is `dart:io`, which does not parse for the web target.
      Choosing between the two *native* hosts is deliberately not one — both compile, so it is a
      question about the machine and `defaultTargetPlatform` answers it where the graph is
      composed
- [x] `test: prove a locator round-trips between hosts` — the correctness claim the whole split
      rests on, and the commit where what *can* be proved had to be worked out rather than
      assumed. A literal round trip opens a book under two hosts and compares what each resolves;
      a host is a webview, and no webview exists in `flutter test` on any platform. So the claim
      is decomposed into the three things it is actually made of, each checkable, and together
      leaving nowhere for two hosts to disagree: **there is one implementation** of where a
      passage is — no Dart in `lib/` takes a locator apart, and every host loads the same pinned
      keys; **a locator crosses each port unchanged** — checked against a corpus of the shapes
      epub.js really emits, ranges and assertions and offsets included, through the mapping and
      through the JSON both bridges carry it in; and **both hosts drive that one implementation
      through the same names** — every function the Linux host spells is checked against the glue
      the bundle holds, which is the single asymmetry this phase introduced, since the other five
      targets get their names from a compiled API and Linux writes them out.

      Two of the checks are the kind that fail by matching nothing and passing forever, which
      `architecture.md` warns about in the write-path test, and both are answered rather than
      noted. The detector for Dart that dissects a locator is a named function shown four shapes
      of violation and four things that are not violations, so a clean tree and a broken detector
      stop looking alike. The glue is asserted to have been read at all before it is asserted to
      define anything. And `previous` versus `prev`, and the capital L in `addUnderLine`, are
      pinned by name: they are what a careful person gets wrong once, and getting them wrong is a
      target that quietly stops turning pages
- [x] `feat: add the reader chrome` — the page, the progress, the table of contents, and the
      controls that get out of the way. Flutter widgets over the host, not inside it: markup
      inside the webview would be a second design system, outside the theme, outside the ARB and
      unreachable by a widget test, drawn by the engine whose one job is somebody else's book.

      A `ReadingRepository` lands with it, beside `LibraryRepository` rather than as four more
      methods on it, because what each is *about* differs — the library is the collection, this
      is one book, open, with one screen's lifetime. It reaches no node: the bytes come from the
      blob store, and bringing them onto the device is the library's job and happens first.

      **The three ways a book does not open are three sentences and not one.** The file is not on
      this device — an offer, and the way out is the book's own screen, which already owns
      downloading rather than a second progress bar here. The format is one this build does not
      render — a fact that leaves the rest of the book's life intact, and no *try again*, since
      trying cannot change what a file is. And anything else, which is the only one that
      apologizes. A screen with one message for all three would say *something went wrong* about
      a book that is merely not downloaded. The codes are pinned in a test, because a screen that
      switched on a message string would break when somebody edited the ARB.

      The chrome starts visible and clears on a tap, which is the opposite of what a reading app
      usually does: a reader who has just opened a book needs the way back more than the four
      lines the bar covers. The contents is flat with an indent rather than a tree of
      disclosures, because a contents is read by looking down it. Keys turn pages on the desktop
      and in a browser, handled in Flutter rather than in the page, since on Linux the page is a
      texture and the events reach the Flutter view first
- [x] `feat: add reader settings` — font, size, line height, margins and the reading theme,
      applied through the host's own styling. Local and deliberately unsynchronized: they are
      about this screen on this device and the contract has no field for them — and that absence
      upstream is right rather than a gap, because a phone read on a train and a desktop at arm's
      length want different answers, so a setting that synced would make choosing one on either
      device the wrong choice on the other. The sheet says so once, since a reader who set up a
      phone and then opened the desktop should learn that it is a decision and not a missing
      feature.

      They live in `shared_preferences` beside the window's size, and the half-written case is
      answered the opposite way from the session credential's: each field falls back on its own,
      so an interrupted write leaves a page mostly the way somebody chose it rather than nothing
      they chose. A theme name a later build knows and this one does not falls back too — a
      downgrade should be harmless, and refusing would be a reader who cannot open a book because
      of a word in a preferences file.

      The sizes are steps and not a slider, because a slider over type size invites a reader to
      hunt for a value they cannot name and cannot get back to; the control snaps to the nearest
      step, so a preference from another build is still a size this reader chose. Everything
      applies as it is changed and there is no *apply*: the page is visible behind the sheet, and
      a dialog that applied on dismissal would ask somebody to imagine a result they can look at.
      Restyling is a method rather than a `Command` — a control that greyed out while the size
      was applying would flicker under a reader stepping through sizes, which is how it is used
- [x] `feat: track reading position` — UC04. The CFI the host reports, and the percentage derived
      from it and stored anyway, so a device that cannot open a DjVu can still report that the
      reader is forty percent through it. Written through the operation author like every other
      change — never `UpdateReadingProgress`, which C21 makes useless — and the author decides
      whether it is an insert, because C05 makes that answerable: a position has one writer, so a
      record this device never stamped is a record that does not exist.

      Debounced at three seconds, and each turn replaces the last rather than queueing behind it,
      so flicking through a chapter writes one operation and not thirty. **It is written again on
      the way out, and that is not redundant**: a reader who opens a book, reads a page and
      closes it inside the debounce would otherwise lose the only thing the screen was for. A
      page already written is not written twice, and a book nobody turned a page in writes
      nothing at all — recording a position on *open* would move a bookmark set on another device
      because somebody glanced at the first page here.

      The percentage is claimed even when it is absent. A field the delta does not name keeps
      whatever wrote it last, so a locator that moved beside a percentage that did not would be a
      row disagreeing with itself. The debounce lives in the view model rather than the
      repository, because what it is about is the rate of page turns and the view model is what
      sees them; a failure to write is logged and never shown, since a banner over a book because
      a bookmark did not save is worse than the thing it reports
- [x] `feat: add continue reading` — the strip that reads the position rows back, including the
      ones this reader's other devices wrote. Where each device stopped in each book is a
      question with one answer per device, and showing all of them is the point: RN01 asks for it
      and C05 is what makes it correct, because a phone and a desktop disagreeing about where the
      reader is are not in conflict — they are two true statements about two devices. Collapsing
      them would be this application deciding which of a reader's devices counts.

      **Half of this was later reversed** — see `fix: show one card per book in the strip, and the
      devices on the book's own screen` at the end of this file. The two statements are still two
      statements and nothing merges them, but the strip is not where they belong: it answers a
      question about *books*, and the book's own screen is where every device's place is listed.

      **It says *another device* and never which one, and that is a finding rather than a
      shortcut.** Nothing in this application stores the reader's other devices: `ListDevices` is
      in the contract and phase 12 is what calls it. Until then the honest answer is that some
      other device of theirs got here, and inventing a name would be worse than the shorter
      sentence. A test pins the wording so that a later phase adding device names is a decision
      rather than a drift.

      A `ReadingDao` lands with it, its own accessor rather than a method on the library's, for
      the reason the repositories above them are two. It orders in SQL — unlike the shelf, which
      cannot, because sqlite's collations are ASCII and a title is not an integer. The strip is
      not narrowed by the search or the shelf filter: what it answers is *where was I*, and a
      strip that emptied as somebody typed would be a second set of results competing with the
      one they asked for. A tombstoned work is left out, since a reader who deleted a book has
      said they are not reading it, and a failure leaves the strip as it was rather than emptying
      it — a band that vanished because one query failed would look like a reader who had never
      opened a book


## Phase 10 — Annotations (UC05)

- [x] `feat: add highlights` — a selection in the reader, anchored to a CFI range. Three
      decisions came out of building it. **The single `text` field carries the passage for a
      highlight**, captured from the selection that made it: the contract gives an annotation one
      nullable text, the screen that lists marks across the library has no engine and no open
      book to ask, and a highlight that stored nothing could only ever be shown as a CFI. **The
      paint is reconciled against the list and never against the gesture** — the reader's view
      model draws what `watchMarksIn` says and erases what leaves it, so a mark that arrived by
      synchronization is painted by the same code as one made a second ago, and a re-open costs
      the same as the first draw. And **the marks come back most recent first, never in reading
      order**: two CFIs are compared by parsing them, and a CFI parser in Dart is the second
      implementation `architecture.md` forbids outright
- [x] `feat: add notes` — a highlight with text, which the contract requires to be present
      because a note without it is an empty note. The requirement is enforced twice over and in
      neither place as a surprise: the dialog's save button is disabled while the field is blank,
      and the repository refuses a blank note with a code of its own — because the `CHECK`
      constraint below would refuse the same thing while naming a table. The note is where the
      single text field diverges from a highlight's: a highlight spends it on the passage and a
      note on the reader's own words, since those are what the contract says a note cannot be
      without. It is a dialog and not a location, which is the one place this app departs from
      *every form is a screen*: a reader who switched away would come back to a **selection** the
      engine has not kept, so a route promising otherwise would be lying
- [x] `feat: add bookmarks` — a position, no text, no selection. It is deliberately not the
      same record as a reading position, and the two look alike enough to be worth separating in
      writing: a position is where a *device* stopped, has exactly one writer (C05) and is
      overwritten on the next page; a bookmark is a place the *reader* chose, and nothing
      overwrites it. The page is recognized by comparing its locator as text, never by parsing
      one — a CFI comparator in Dart is the forbidden second implementation, and what the
      cheaper rule costs is small and stated where it is made: a bookmark taken at one type size
      is not recognized as *this page* at another, so the control offers to make a new one, and
      the old mark is still in the list and still navigates to the right passage
- [x] `feat: add the annotations screen` — everything marked in one book and everything marked
      across the library, each navigating back to its passage. The two are **one screen with a
      narrowing**, not two screens sharing a list: the same question at two widths, reached from
      the shell for the whole library and from a book — or from the reader, pushed, so the way
      back is the page — for one. Navigating back to a passage is what put a locator in the
      reader's location: `?at=` is a query parameter and not a path segment, because it is not
      part of the identity of the screen, and it is escaped because a CFI is full of slashes,
      brackets and commas. Giving a highlight words promotes it to a note and the passage it had
      stored gives way to them — one text field, and the contract says a note's belongs to the
      reader — so the dialog opens with the passage already in it and what the reader is looking
      at when they save is what is stored. One translation was corrected here rather than
      shipped: the filter for notes reads *Notas*, since *Anotações* is the name of the whole
      screen and a chip repeating it names two different things at once
- [x] `feat: add annotation export` — Markdown and JSON, to a file the reader chooses. It is
      their data, and a sovereignty argument that cannot get it out of the app is an argument
      with a hole in it. The two formats are spelled for their two readers: the Markdown carries
      the words in the order they were marked, quoting a passage and not quoting what somebody
      wrote about it, with its own words taken from the ARB because a file a reader opens is
      user-visible text; the JSON carries the record under the **contract's own field names** —
      `ebook_id`, `kind`, `locator`, spelled exactly as `delta.dart` and both schemas spell them
      — because that is the delta vocabulary's argument one hop further out, and an export that
      invented `bookId` would be one nothing in this project could read back. Every mark carries
      its locator, which is what makes the file resolvable and not merely readable. **`share_plus`
      was added, and the roadmap did not foresee it**: `file_selector` has no save dialog on
      Android or iOS, and that is not a gap in the package — those systems have no save dialog,
      and saving a file there *is* the share sheet, which is where *Save to Files* lives. So
      `FileSaver` is a port with two implementations picked on `defaultTargetPlatform`, exactly as
      the reader's host is. The alternative was an export on four targets of six

## Phase 11 — Synchronization (UC09, UC10, UC11)

- [x] `feat: add push` — `PushOperations`, draining the local log in order, and the four outcomes
      handled distinctly: applied and duplicate both retire the operation, superseded retires it
      and leaves the replica alone, and rejected is the only one that surfaces to a reader. A
      fifth is handled too and the roadmap did not name it: a node running a later contract can
      answer with an outcome this build cannot spell, and the operation stays owed rather than
      being guessed at — the worst that follows is a `duplicate` on the next pass. The pass ends
      when a batch retires nothing, which is what keeps a head batch of refusals from being
      offered for ever before the quarantine lands
- [x] `feat: add pull` — `PullOperations` from this node's cursor, through the reconciler, with
      the cursor advanced only after the batch is committed. `has_more` is a loop and not a
      recursion. What makes that ordering safe rather than merely careful is `applied_operations`:
      a page re-read after an interruption comes back `duplicate` by the identifier its author
      minted and the replica is untouched, so the cost of dying between the commit and the cursor
      is one decode. The loop also ends on a page that carried operations and did not move the
      cursor past them — a node this build cannot follow, rather than a log it has caught up with
- [x] `feat: add the sync stream` — `Sync`, the bidirectional one, on the five native targets:
      `SyncStart` with the cursor, then pushes and acks in one direction and operations in the
      other. The ack is sent after the write commits and not after the read returns, because an
      operation written to a socket is not an operation written to disk and a device that dies in
      between must come back to the same place. Two things the plan did not foresee. The stream
      is the first call whose two directions cannot be mapped in `data/model` — a `oneof` is a
      shape and not a record — so `SyncApi` grew a vocabulary of its own, `SyncCommand` and
      `SyncEvent`, rather than letting a generated message reach the caller. And **closing is
      ordered**: half-closing and hanging up in one breath discards the frames still in the air,
      including an acknowledgement already earned, so the outbound half is closed, the node is
      given a moment to end the stream itself, and the hang-up is what happens when it does not
- [x] `feat: add the watch stream` — `WatchOperations` for the web, where gRPC-Web carries no
      bidirectional call. It is a notification and not a delivery: the response carries
      `last_position` and never an operation, so the handler does one thing — compare it against
      this node's cursor and pull if it is behind. There is no ack, because the node holds
      nothing in flight for this caller, and a missed notification costs a poll rather than an
      operation. What the roadmap left implicit is that the web's *push* is a call of its own,
      so the watch is not one call but three, and it is the second implementation of a port the
      scheduler talks to: `SyncChannel` — open, offer, close. That is where the platform question
      is answered, once, where the graph is composed
- [x] `feat: add the sync scheduler` — the channel while the app is in the foreground, a push on
      reconnect, and a bounded backoff on failure. **Two lines of this checkbox were wrong and are
      corrected here rather than implemented.** *A policy for the background on each platform that
      has one* contradicts the decision table above, which says foreground only, uniformly on all
      six — and the table is right: a background policy is four mechanisms and no fifth for the
      three desktops, which is a phase and not a line. And *reachable* cannot be a condition for
      connecting: `NodeReachability` concludes that a node answers only from a call that answered,
      so a loop that refused to try while it believed otherwise could never learn it was wrong,
      and every device whose network did not physically change would be stuck. Reachability
      contributes the one thing it can honestly contribute — a hint that clears the wait — and an
      unreachable node is what the backoff is *for*. The loop also drives the upload queue, which
      `upload_queue.dart` had already said was its job, and it learns about a locally authored
      change by watching `pending_operations` grow rather than by being called: a caller that had
      to remember to announce a write is a caller that eventually does not
- [x] `feat: add the sync status surface` — what is pending and when the last sync completed.
      One line in the shell, one screen behind it. A reader who cannot tell whether their notes
      are only on this phone has not been given the guarantee the app claims. The line is a
      **badge on the settings destination** and the screen is `/settings/sync` below it, which is
      a claim about what synchronization is: a property of the app rather than a fourth place to
      visit. The badge is absent at zero — a nought is a permanent mark saying everything is fine,
      which is the state a reader already assumes. Two things the plan did not name. *When the
      last sync completed* could not be `node_cursors.pulled_at` as it stood, because a device
      that is up to date pulls nothing and the column would have reported whenever somebody last
      wrote something; it now also moves when a channel opens, and the column's comment says so.
      And **waiting is not failing**: the screen distinguishes a node that did not answer, which
      it calls a wait, from a refusal no retry fixes, which it names — an offline-first app whose
      ordinary state looks like a fault has taught its reader to ignore the one time it is not
- [x] `feat: quarantine a refused change` — the case the local-first write path makes possible:
      the reader has seen the change land and the node will not take it, so the device is showing
      something that will reach nobody. The record carries a refused flag and the node's reason,
      the sync screen lists it, and the reader can discard it. It is deliberately not a rollback
      — the write may have others built on top of it, and destroying those to satisfy a refusal
      is the one outcome worse than the refusal — and deliberately not silence, which would leave
      this device disagreeing with every replica and saying nothing. A correct client should
      rarely produce one, so this is a flag and a list and not a merge interface. Two details the
      plan left open. It is a **side table** and not a column on `pending_operations`, which keeps
      the upgrade `createAll` — every version of this schema still only adds — and keeps the
      outbox as dumb as its own comment asks for. And a quarantined change **stops being offered**,
      which is the half that makes the drain work at all: the head of the outbox moves without
      retiring, so one refusal no longer stops every change behind it from ever being pushed
- [x] `test: prove two devices converge` — two databases, one operation log, the later write
      pushed first, both landing on the write that wins on `(updated_at, device_id)`. It is
      Quire's own end-to-end reconciliation test, written from this side. It is not a second
      `reconciler_convergence_test.dart`: that one shuffles a synthetic log into a reconciler and
      proves the merge, and this drives two whole replicas through everything *around* it — the
      author stamping a version on the right predecessor, the outbox, the two calls, the cursor.
      Those are the divergences no amount of correctness in the merge repairs. Two assertions
      beyond the plan's earned their place: both devices end holding the same *causal state* and
      not only the same row, since the next write either one authors is stamped on top of what it
      thinks the current version is; and neither device is left owing anything, because the write
      that lost was stored by the node and retired here rather than retried for ever

## Phase 12 — Federation and sovereignty (UC06, UC12, UC15, UC16)

The phase the thesis is actually about, and the one a demonstration ends on.

- [x] `feat: add the known servers screen` — UC12. The catalogue, adding a node by domain, what
      discovery learned about it, and refreshing a node whose key was rotated. **It is the first
      repository in this app that does not answer from the local replica, and that is the phase's
      own shape rather than an oversight.** Every other one holds records that replicate, so the
      truth is here and the node hears later; a catalogue entry is what the *node* knows and
      enforces, it changes on the reader's other devices, and none of the four things this screen
      offers can be done while the node is unreachable — so a cached list would be a screen
      showing a peer that may already be gone, under controls that would all fail. A failed read
      says the node did not answer and offers to ask again. The catalogue is still *mirrored* into
      `known_servers` as each answer arrives, which is a different job and the reason the table
      has a nullable `remote_id`: `ListKnownServers` is the only call that reports a node's own
      identifier, and that identifier is what a replica grant is addressed by. Three details the
      plan did not name. The screen asks for the **deactivated** nodes, which the contract hides
      by default — this is where the switch that deactivated one lives, and a list that hid them
      would have no way back from the state its own control produces. Forgetting a node
      **deactivates the local row rather than deleting it**, which is what the column's comment
      has asked for since the table was written: the reader's own row references a domain, and a
      revoked peer that still holds a copy is something they should keep being able to see. And
      the reader's own node carries neither the switch nor the removal, because it is not a peer
      they chose and neither control has anything coherent to do to it
- [x] `feat: add replica authorization` — UC15. Granting a node the right to hold a copy, with
      and without the files, and revoking it. Metadata without the files is the cheap replica a
      reader is most likely to want on a node they do not own, and the screen makes the choice
      legible rather than a checkbox. C22 is stated where it lands: nothing in the contract can
      tell a node that it is a replica, so the grant is recorded and the federation is completed
      out of band, and the screen says so instead of appearing to have worked. What that came to
      in practice is a **permanent note beside the grants rather than a message after one**: a
      snackbar saying the other node has not been told is a sentence that scrolls away, and the
      claim it corrects — that the copy is now flowing — is on the screen for as long as the
      permission is. The choice of what travels is two options with a sentence each, in a dialog
      of its own, because *whom do you trust with this* and *how much* are different questions;
      the cheap replica is the one selected when the dialog opens, so a reader who reads neither
      sentence gets the answer that costs the other operator least. Three things the plan did not
      name. The revoked permissions are **asked for** — `ListReplicaAuthorizations` hides them by
      default, and they are the only thing that explains a peer that still holds data, so a
      sovereignty screen without them answers *nobody* to the question it exists for. The
      candidates offered exclude the reader's own node and every node a live permission already
      names, which is the screen's arithmetic and not the node's. And a candidate publishing no
      gRPC authority is **listed and flagged** rather than hidden: the node accepts the grant,
      nothing will ever replicate there, and saying so costs less than a reader wondering why
- [x] `feat: add home server migration` — UC16, and the demonstration this project exists for. A
      reader moves to a node they had no account on, carrying their devices, and everything each
      one was holding and had not handed over is pushed to the new node under the identifiers it
      was authored with. The screen is a wizard because the operation is not reversible, and the
      causal state is not cleared on the way through — clearing it would complete the migration
      by discarding what was being migrated. **One line of this checkbox needed splitting rather
      than implementing.** *The previous node is not asked anything* is true of the migration and
      false of the wizard, and the difference is the point: the identifiers the devices travel
      under are the half that cannot be recreated, and the names are the half only the node being
      left knows. So it is asked for the names, once, when the wizard opens — and a node that
      does not answer costs exactly the names: the identifiers come out of `record_versions`,
      whose vector clocks are keyed by every device that has ever authored anything this replica
      has seen. UC16 stays independent of that node's availability, which is what it exists for,
      and the step says which of the two happened instead of inventing a fact. A device the node
      could not name travels under one the ARB supplies, carrying the first eight characters of
      its identifier so that two of them can be told apart in the list the reader renames from
      afterwards. **C20 was found by reading `../quire` rather than the contract, and it changes
      client code**: the session comes back for the *first device in the list*, the vendored
      `.proto` does not say so, and `tcc-corrections.md` records the sentence as still to be
      added — so this device is put first and deduplicated in the repository, where the rule is
      named. Three more decisions. This device is **pointed at the new node at the last step and
      not before**: discovering the domain early would validate it and would also leave the app
      talking to a node the reader has no account on while they fill in a form, so the domain is
      checked for shape where it is typed and committing and connecting are one act — and a
      migration that fails points the device back, since a device holding a session for one node
      while dialling another fails every call for a reason nothing on screen explains. The
      **cursor for the new node is dropped**, which the reference client does and the plan did
      not mention: a position is a number in that node's log, the log it is about to write for
      this reader is empty, and a number left over from an earlier conversation with the same
      address would skip everything the migration is about to put there. And the repository
      grew `AuthApi` for the one call UC16 needs from the identity slice, which is the same
      seam Quire names on its own side — the one place a controller of one slice translates for
      a use case of another
- [x] `feat: add device management` — the reader's devices, renaming one, and revoking one. A
      revoked device's row stays and so does its clock entry, or the history that names it stops
      being readable, and the screen says *unbound* and not *deleted*. The unbound ones are
      **asked for**, which the contract hides by default and which is the same argument one step
      further out: the row is the only place an identifier a vector clock carries gets a name, so
      a list that hid it would make the history it explains unreadable. Two things the plan did
      not name. **A device cannot unbind itself, and this app is what refuses it**: the node
      cannot tell that request apart from any other and would carry it out, ending this session
      and every future one with nothing left on screen to undo the act — so the row says *this
      device* and offers no control, which is quieter than an error the reader had to provoke.
      And renaming this device **writes the local `bound_devices` row too**, because that name is
      what the next binding sends: a name changed at the node alone would be two names for one
      device, and the one this device kept would win the next time it signed in. The repository
      is `AccountRepository` and it arrived one commit early — the migration needed `ListDevices`
      before this screen did — which is also why UC06 and RF11 share one: both are `AuthService`,
      both are served by the one node that authenticates the reader (RN08), and neither
      replicates
- [x] `feat: add account settings` — UC06. Display name, address, password. Only the display name
      is writable directly; the address and the password are credentials in their own right and
      go through their own calls, which is C14. The screen keeps that shape rather than hiding
      it: three dialogs and not one form, because a single *save* button would have to demand a
      password for the name as well or accept one for none of it — which is the same thing a
      field mask cannot express, one layer up. **One finding changes client code and is not in
      the contract**: `ChangePassword` ends every session of every device.
      `internal/identity/application/usecase/changepassword` says so and says why — a reader
      changing their password is responding to a suspicion, and a session that survived would be
      the one they suspect — while `auth.proto` says it only of the reset. So this device clears
      its own session after the call, exactly as the password reset of phase 6 does, and the
      dialog warns *before* it asks: a reader who was not told would experience a correct
      security decision as the app breaking. Two smaller things. The screen watches this device's
      **reader row** and asks `GetUser` once when it opens, writing the answer into that same
      row — so it shows something on a device that has been offline for a week, there is no
      third copy to disagree, and a refresh that failed costs a line rather than the screen. And
      the refusals a reader can act on are named out of the node's own codes: `wrong_password`,
      which is one code for all three credential calls on the other side, and `email_registered`
- [x] `feat: add account deletion` — with what it does and does not reach spelled out: this node,
      and not the replicas that already hold a copy. The screen is **two lists, and the second is
      the point**: a deletion screen that only said what it removes would invite the reader to
      believe it reaches further than it can. The peers are *named* rather than alluded to, which
      is why the screen reads the replica permissions — a reader deciding what deletion costs
      should not have to guess who has their library — and an empty list there means *not known*
      and never *none*, so the sentence stays and only the names come and go. **The local replica
      is left alone**, which the plan did not settle: the books and marks here are the reader's
      own copy, the export of phase 10 is how they take them elsewhere, and erasing them would
      destroy the only remaining copy of everything the node never received. So deletion ends the
      session and nothing else, which is what signing out already means one step further on. It
      is a location below the account and not a dialog on it, for the reason every irreversible
      screen here is one, and it points at the migration: the two calls exist separately on
      purpose, and the difference between them is what they cost when the caller was wrong about
      which they wanted

## Phase 13 — Delivery

- [x] `feat: add the application icon` — **a checkbox the plan did not have.** It sat inside the
      web one as *the icons*, and doing it there would have shipped a tagged release whose other
      five targets carried the Flutter sample's blue F. The mark is a lectern — which is what an
      *atril* is — and it is **geometry compiled by `tool/make_icons.dart`, not artwork**: six
      targets want it at twenty-nine sizes in three container formats, two of which disagree
      about the alpha channel, and a directory of exported PNGs is a set nobody can regenerate
      once the file the designer worked in is gone. So the PNGs, the `.ico` and the Android
      adaptive pair are all written by a program that owns a rasterizer, a PNG encoder and an ICO
      encoder, and CI regenerates and diffs them exactly as it does the contract and the
      localizations. Three details worth naming. The **iOS set is written without an alpha
      channel at all** rather than with an opaque one, because App Store Connect rejects a
      marketing icon that carries one and a constant channel is still a channel. The **spine down
      the desk is a hole and not a second colour** — it is wound against the shape that contains
      it — so it shows the ink behind the mark on five targets and the transparency of an Android
      foreground layer on the sixth, from one description. And Android gets **both** icons: the
      adaptive pair from API 26 and the legacy bitmap, because this app's `minSdk` is 24 and two
      of the versions it admits predate the adaptive format
- [x] `build: add the android release configuration` — signing, the application id, and the
      minimum SDK. The application id was already `dev.quire.atril` and carried the template's
      *specify your own* TODO; what this commit adds is the reason it is that string, which is
      the same one the iOS bundle identifier, the macOS one and the GTK application id are.
      **Signing is a keystore this repository does not have and a fallback that announces
      itself.** `android/key.properties` is gitignored, `key.properties.example` is committed and
      says what belongs in it, and its absence is not an error: the release build falls back to
      the debug key so that `flutter run --release` works on a machine with no keystore. The
      fallback logs a line, because an APK signed with the debug key that *looked* like a release
      is the single mistake this file exists to prevent. The minimum SDK is **pinned at 24 rather
      than tracking `flutter.minSdkVersion`**, which is 24 in this release. The floor the
      dependencies actually need is lower — `flutter_secure_storage` asks 23, `connectivity_plus`
      21, `flutter_inappwebview` 19 — so the pin is not about them: it is that a Flutter upgrade
      must not be able to silently drop the devices this app runs on. Raising the floor is a
      decision, and a decision belongs in a diff
- [x] `build: add the ios release configuration` — the bundle identifier, the capabilities, and
      the deployment target. Two of the three were already right and the check is what this
      commit is: the bundle identifier is `dev.quire.atril`, the same string as the Android
      application id and the GTK one, and the deployment target is **15.0 because that is what
      Flutter 3.47 itself asks for** — `packages/flutter_tools/bin/podhelper.rb` sets
      `s.ios.deployment_target = '15.0'` on the Flutter pod, and no dependency in this project
      asks for more. Reading it rather than accepting the template's number is the whole of that
      line. **The capabilities are one that was missing and one that is deliberately not taken.**
      `flutter_secure_storage` needs the keychain-access-group entitlement on iOS exactly as it
      does on macOS — its README says so of both — and this target had neither entitlements file:
      the store would have raised at its first write, which is the moment the reader signs in.
      The macOS pair got theirs in phase 6 and the iOS pair is now beside them, naming the same
      group. What is *not* there is a **background mode**, which is the capability a
      synchronizing app is expected to take: the schedule is foreground only on all six targets,
      and an entitlement for work this app does not do is a permission it cannot justify. Two
      more findings, both of which change behaviour and neither of which is signing. **iOS
      would never have offered this app in Portuguese.** The system decides an app's language
      from the localizations the *bundle* declares, a Flutter app declares none — the ARB files
      are compiled into Dart and the system never sees them — and the template leaves the
      development region as the Xcode variable, which resolves to `en`. So `pt_BR` being this
      project's default locale was true everywhere except the one place iOS reads. It is not
      cosmetic either: `share_plus` documents `CFBundleDevelopmentRegion` and
      `CFBundleAllowMixedLocalizations` as the fix for a share sheet that appears in the wrong
      language, and the share sheet is how the export of phase 10 leaves this target.
      And **`ITSAppUsesNonExemptEncryption` is deliberately absent**: the template's answer is
      `false`, which claims the app uses only the operating system's encryption, and this one
      does not — the native lane's TLS is BoringSSL inside the Dart runtime. Whether that is
      still exempt is a declaration the publisher makes, not a fact a build file asserts for
      them, so App Store Connect asks and a person answers. **None of this was built here**: the
      Apple targets need a macOS host, and the two jobs in `ci.yml` are what compile them
- [x] `build: add desktop packaging` — a Flatpak on Linux, a signed `.app` on macOS, an MSIX on
      Windows. **Flatpak and not AppImage, and the reason is the sandbox rather than the
      distribution.** `webview_cef` appends `--no-sandbox` to CEF's command line in
      `common/webview_app.cc` and its CMake leaves the setuid `chrome-sandbox` helper
      unprivileged, so Chromium's own sandbox is off on this target whatever ships it. An
      AppImage would then be an unsandboxed browser engine running with the reader's whole
      account; a Flatpak is one inside a sandbox that is *declared in a file somebody reviews*.
      What that file says is narrow on purpose: network, ipc, a display socket, a render node,
      and `org.freedesktop.secrets` for the keyring — and **no `--filesystem` at all**, because
      `file_selector_linux` opens a `GtkFileChooserNative`, which GTK routes through the portal
      inside a sandbox, so importing a book and saving an export each hand the app one file the
      reader chose. **The Linux bundle is three times the size this roadmap thought.**
      `flutter build linux --release` copies `libcef.so` exactly as CEF published it — 1311 MB
      unstripped, in a bundle of 1553 MB — and `architecture.md`'s "244 MB stripped" was the
      stripped size of a file that nothing was stripping. The strip is now a line in the
      manifest and the bundle is 486 MB; that document is corrected in the same commit.
      **macOS: one entitlement was missing and it broke both of UC02's ends.** A sandboxed app
      reaches a path the reader chose only through the powerbox, and
      `com.apple.security.files.user-selected.read-write` is what grants it — `file_selector`'s
      macOS README says so. Without it the picker opens and the file it returns cannot be read,
      so the import and the phase 10 export were both broken on a release build and on nothing
      else. `packaging/macos/package.sh` signs under the hardened runtime and notarizes **when
      the environment carries an identity**, and when it does not it signs ad hoc and names the
      artifact `-unsigned`, because a zip called `atril-macos` that Gatekeeper refuses is a bug
      report from somebody who was never told. **Windows: the `msix` package, and one setting
      that is not about this app.** `install_certificate: false` — the default is to install the
      signing certificate into the machine's trust store as a side effect of building a package,
      which is a convenience on a laptop and is not a thing a CI runner should do. There is
      deliberately no `msix_version`, so the installer's version is `version:` in the pubspec and
      not a second number to forget. **One correction fell out of reading what Linux actually
      links**: `libjsoncpp-dev` has been in this project's build instructions and in CI since
      phase 0, and nothing needs it — `flutter_secure_storage_linux` dropped it in 1.2.0 and this
      project has been on 3.x since phase 6. `ldd` over the built bundle names it nowhere. **What
      was not run here**: `flatpak-builder` is not installed on this machine and the two Apple
      steps need a macOS host, so the Linux *bundle* was built and measured and the manifest that
      wraps it was not; the release workflow is where all three are first executed
- [x] `build: add the web build` — the manifest, the icons, the offline service worker, and the
      renderer choice argued for in a comment. **The offline service worker this line asks for
      does not exist any more, and that is the finding of the phase.** Flutter's is deprecated
      (`flutter/flutter#156910`) and in 3.47.1 the file the tool generates is *thirty-one lines
      that call `registration.unregister()` and reload every client* — a tombstone. So the target
      whose whole promise is that the network is an optimization had nothing caching its own
      application, and taking the default `flutter_bootstrap.js` would have been worse than
      nothing: it registers that file, at the same scope Atril's worker wants, so the tombstone
      would have removed Atril's along with itself. `web/atril_service_worker.js` is this
      project's own, and it is reviewed in `web/` rather than generated whole:
      `tool/make_service_worker.dart` rewrites exactly two of its lines after a build, because
      which files a build produced and a version that changes when any of them does are the only
      parts that cannot be written by hand. Four decisions in it are places the obvious answer is
      wrong. It **caches the shell and never a book** — the books are phase 8's per-book opt-in
      in the origin-private file system, against a budget the reader can see, and a worker
      quietly caching them as they streamed is the one thing that decision forbids. It calls
      **neither `skipWaiting` nor `clients.claim`**, and the cost is stated where it is paid: the
      *first* visit is not offline-capable, and from the second load it is. The alternative is
      serving a running page the JavaScript of one build and the assets of another for the rest
      of the session. It **lets every non-GET and every cross-origin request past untouched**,
      which is not defensive — a cached `POST` response would be one device replaying another's
      answer to a synchronization request. And the version is a **digest over the sorted file
      list and each file's own digest**, so a moved asset and a changed one both produce a new
      cache, which a build number would not. Two flags carry the rest. `--no-web-resources-cdn`,
      because the default fetches CanvasKit from gstatic — a cold load on a train with nothing to
      render with. And `--pwa-strategy=none`, which does not omit Flutter's worker but *empties*
      it, so the tool deletes the zero-byte file rather than deploy a name somebody might
      register. **The renderer argument came out smaller than expected, and the measurement is in
      the comment rather than the belief.** `--wasm` does not replace the JavaScript build, it
      adds one and keeps the other as the fallback: 49.5 MB against 45.4 MB, nine percent, not
      the doubling it sounds like. CanvasKit stays because it is what every browser Flutter
      supports runs and what this project has been built against for twelve phases, and the note
      says to revisit it with a profile rather than an argument. The size actually worth knowing
      is not the renderer's: `--no-web-resources-cdn` copies the whole renderer directory out of
      the web SDK, **36.1 MB of the 45.4**, including variants a JavaScript build never loads and
      8.2 MB of `.symbols` files. Four fifths of the offline shell is renderers and one of them
      runs. The manifest loses the template's `portrait-primary` — this app runs on a desktop —
      and gains the ink the icon is drawn on, so the splash is the app's colour and not white
- [x] `ci: add the release workflow` — tagged builds for all six, with the artifacts attached.
      `.github/workflows/release.yml`, on `v*` and on a manual run. **Every signing step is
      conditional on a secret and says so in the artifact's name when it is absent**, which is
      the shape a project with no certificates needs: a tag pushed today produces six installable
      things, none of which can be mistaken for a signed release, and acquiring a certificate
      later changes a secret rather than this file. Four things in it are decisions. **The
      version is derived once, in a job of its own**, because six targets stamping their own
      would be six that can disagree — and it is `build-name` from the tag with `build-number`
      the run number, since Android's `versionCode` and Apple's `CFBundleVersion` both need a
      monotonic integer and a tag is not one. A manual run builds `0.0.0` and not something
      obviously fake like `0.0.0-dev`, because `CFBundleShortVersionString` has to be three
      numbers and failing a dry run on the name of the dry run is the least useful failure
      available. **Android ships both the bundle and the APK**, because a store takes one and a
      person installing from a release page takes the other. **Linux has no signed and unsigned
      case at all**: a Flatpak is trusted through a repository's GPG key and a single-file bundle
      carries none, so there is one artifact and installing it is `flatpak install ./atril-*.flatpak`.
      And the **Windows job spells out the two commands `make package-windows` runs**, because a
      Windows runner has no `make` and a job that installed one to save two lines would fail for
      a reason unrelated to this project. The release job `needs` all six: a commit that builds
      on five is not done, and a release that ships five is that rule one step out. **Nothing
      here has been executed** — it needs a tag, three runners and secrets this repository does
      not have — so it is reviewed and not proven, which is the honest state of every release
      workflow before its first tag
- [x] `docs: update the readme` — the status section stops saying *not started*, and the
      getting-started section says how to reach `make dev-up` from each target. **The difference
      turned out to be in two places rather than one.** The web is the target the checkbox
      predicted, and the difference there is the *transport*: a page cannot add to the browser's
      trust store, the certificate flag is ignored, and none of that matters because the gRPC-Web
      lane is plain HTTP on a loopback origin, which a browser treats as a secure context. The
      one the checkbox did not predict is the *address*, and it is worse because it fails
      silently: `Environment.development` names both nodes at `127.0.0.1`, which on an Android
      emulator or a connected device is the device itself. So Android needs
      `adb reverse tcp:$port tcp:$port` over all four ports before anything resolves, the iOS
      Simulator needs nothing because it shares the host's network stack, and an iOS device over
      a cable has no equivalent at all — reaching the federation from one is an edit to
      `environment.dart` and not a command, which the README says rather than leaves to be
      found. The status section also names the **two things it cannot claim**: the release
      workflow has never run, and the three desktop packages have never been built, both for want
      of a tag and of runners

## Phase 14 — The review

A pass over the finished plan rather than a feature. Four reviews were run over the tree on
2026-09-02 — the synchronization subsystem, the data layer, the presentation layer with the
EPUB hosts, and the delivery side — and every claim below was checked against the code before
it was written down. Three of them are release blockers: the reader's page is mounted only
after the book has opened, which is the moment both real hosts need it mounted; the schema
upgrade re-creates four indexes that `IF NOT EXISTS` does not cover; and one delivery the
replica cannot hold stalls synchronization at the same cursor forever. The rest is what a
thirteen-phase codebase accumulates: a leak on an error path, a timestamp written on the wrong
event, duplicated helpers, and the tests that would have caught each of these had they existed.

Each entry is a commit, each commit carries its own test, and the box is ticked in the commit
that lands it, as everywhere else in this file. The sub-sections are worked in parallel and
merged in order, which is why each fix names the section it belongs to and touches no other.

### The replica and the repositories

- [x] `fix: create indexes the upgrade can repeat` — `onUpgrade` calls `createAll` trusting
      that every statement is `IF NOT EXISTS`; drift adds the clause to tables and views and not
      to indexes, and all four indexes existed at version 1, so any real database moving to
      version 5 fails to open with *index already exists*. The migration test upgrades an empty
      database and never sees it. Issue the index statements with the clause, and test the
      upgrade from a database that holds the version 1 schema *and* its indexes. Checked against
      drift 2.34.3 before it was fixed: `Migrator.createIndex` is `_issueQueryByDialect` over the
      statement the generator wrote, with no clause added, and the four in `database.g.dart` had
      none. **The clause is written into the declarations rather than into `onUpgrade`**: the
      three indexes declared by column became `@TableIndex.sql` with `IF NOT EXISTS` spelled out,
      beside the one that already was, so `createAll` stays the whole of both hooks and the
      upgrade needs no second code path that lists indexes by hand and misses the next one.
      drift_dev parses the statement and re-emits it, and the regenerated file carries the
      clause on all four. The test reads the version-one tables and indexes out of a fresh
      replica's `sqlite_master`, replays them under `user_version = 1`, and opens — which, with
      the clause stripped from the generated file, fails with exactly the sentence a reader's
      device would have logged
- [x] `fix: import a work in one transaction` — `author.write` commits, and the cover and the
      transfer row are written after it. A failure between the two leaves a work the node is
      never owed: no upload, a duplicate on retry, and a release that removes the only copy. The
      three steps join one transaction, and a test fails the bookkeeping after authoring and
      asserts no row and no outbox entry remain. **The transaction is opened on the DAO the
      repository already holds** — `library.transaction`, which drift resolves through the zone
      so the author's own `database.transaction` inside it becomes a savepoint rather than a
      second commit — and nothing new is injected for it. The blob write stays outside on
      purpose: the bytes go first so that a device interrupted between the two holds a file
      nothing names, which the retry adopts through the digest, and the test asserts that too.
      The failing step in the test is `saveCover` on a `LibraryDao` subclass rather than `owe`,
      because `UploadQueue` is final and the DAO is not; the property is the same for either.
      Without the transaction the same test finds one `ebooks` row after the failed import
- [x] `fix: notice a download from the content watch` — `watchContent` recomputes *on this
      device* only when a transfer or a pin changes, and a completed download writes neither, so
      the book screen keeps saying the file is elsewhere until something unrelated moves. The
      blob store announces what it commits and removes, the watches merge that in, and a test
      downloads mid-stream and expects the flag to flip. `BlobStore.changes` is a broadcast
      stream of digests, fed by all three stores — the filesystem, the origin-private file
      system and the test's memory one — on a publish and on a removal, and deliberately not on
      a commit that found the object already there: the set of what is held did not move, and
      that is the fact a listener waits on. **The watches merge wake-ups and re-read, rather
      than combining latest values**: `StreamGroup.merge` over the transfer, the pin and the
      store's announcements, and two point queries per wake-up, which is what let the
      hand-rolled `Rx.combine` — two streams, no room for a third — go now rather than in the
      refactor below. `package:async` is promoted from transitive for it, with the pubspec
      saying why. `watchKeptEbooks` gets the same treatment, since a release changes that list
      and changes no row. The test runs the real downloader against the fake content service on
      a loopback port and watches the flag go from `false` to `true`; with the old watch it
      never does. The web store is compile-checked by `flutter build web`; the other five
      targets could not be built here
- [x] `fix: measure the file before extracting its cover` — `_keepCoverOf` passes the row's
      nullable size as zero, which `_describe` reads as *under the limit*, and a seeded work of
      unknown size is read whole into memory on a phone. Ask the blob store for the size it has.
      `BlobStore.sizeOf` already existed — the downloader uses it to skip a fetch — so nothing
      was added to the interface. **The store's measure replaces the row's entirely**, not only
      where the row is null: the row says what the importing device counted and the store says
      what this device holds, and the second is the one about to be read. A digest the store
      does not hold ends the extraction as well, since there is no file to open. The test wraps
      the memory store in one that reports a length past `metadataSizeLimit` and counts the
      reads, seeds a work with no size over it, downloads — which the downloader answers from
      the store without a node — and asserts the bytes were never asked for and no cover was
      saved; a second test with a true length asserts the cover still is
- [x] `fix: refuse a refresh that lands after sign-out` — `end()` does not invalidate a refresh
      in flight, so the late reply writes a live credential back and announces the device signed
      in. A generation bumped by `end()` and checked before adopting, with a test whose refresher
      completes after the sign-out. **The generation is checked on both sides of the store
      write**, which is what the obvious single check misses: `end()` clears the store, the
      clear and the write are two futures that can land in either order, and a clear that ran
      first would leave the refreshed credential as the newest thing in the store. So a refresh
      that finds the generation moved *after* its write clears the store again, and the outcome
      is the same whichever order they landed in. The counter is bumped before `end()` awaits
      anything, so a refresh is stale from that line rather than from whenever the store
      answers. Two tests: a refresher held open across a sign-out, which must answer `null`,
      leave the store empty and announce `[true, false]` and not a third transition — it
      answered `access-2` before — and its opposite, a refresh nothing outlived, which must
      still take
- [x] `fix: keep every failure inside the boundary` — three repositories catch `on Exception`
      where the others catch `on Object`, so a `StateError` from a DAO reaches a view model; in
      the federation repository it also skips the point-back and strands the device on the new
      node. `reader()` returns a raw stream for the same reason. Standardise the catch, return
      `Stream<Result<User?>>`, and test that an `Error` from below is a `Result`. **Five
      repositories and not three**: the server and sync repositories caught `on Exception` too,
      and the review had named the three it read — so all thirty-one catch clauses across
      `data/repositories` are now `on Object`, which `failureFrom` already accepted. Nothing
      about the failures changes shape; what changes is which ones are caught at all. `reader()`
      wraps its stream the way the other watches do, and the four view models that listen
      unwrap it — **a failure leaves the reader as they were rather than blanking the surface
      that names them**, since the row is still in the replica and the next answer carries it.
      The test hands the repository an `IdentityDao` whose `watchReader` fails with a
      `StateError`, which is precisely the class `on Exception` walked past, and asserts a
      `Result.error` arrives
- [x] `refactor: hoist the row mappers and the stream guard` — `library_repository_impl.dart` is
      994 lines and two features, and three of its helpers are reached into or copied by the
      annotation and reading repositories. The row mappers move to `data/model`, the guard
      becomes an extension in `utils`, the bytes half becomes its own file, the reading
      repository is handed the identity DAO instead of reaching through another one, and the
      hand-rolled stream combinator gives way to `package:async`. Nothing here changes
      behaviour: the whole suite passes untouched except where a constructor gained the DAO.
      `data/model/row_mappers.dart` is the row→domain direction beside the wire→domain
      mappers already there, and it took `descriptorOfRow` with it — written three times in the
      server repository and a fourth at the composition root. `Stream<T>.asResults(op)` in
      `utils/streams.dart` replaces the guard that was copied verbatim into the annotation
      repository and re-implemented as `_watch` in the reading one. **The bytes half is a mixin
      and not a second repository**, because a reader importing a book is not acting on a
      different thing than one renaming it: `LibraryBytes` declares the members it needs as
      getters and the class provides them, which splits 994 lines into 488 and 493 without
      either file reaching into the other — the one constant both report under moved to the
      interface rather than being imported across. `blankIsAbsent` in `utils/collation.dart` is
      the one rule the two duplicates spelled. The combinator was already gone with the
      previous commit, which needed three streams where it took two
- [x] `feat: reclaim the bytes of a deleted work` — a tombstoned work keeps its blob and its
      pin, the kept list hides it and the budget counts it, so the space is shown and never
      freed. A reclaim pass removes blobs no live work names once the transfer has retired.
      **It runs after a deletion and at the launch that builds the graph**, and the second is
      not belt-and-braces: a tombstone that arrived from another device is applied by the
      reconciler, and a reconciler that deleted a reader's files would put that one destructive
      gesture on the synchronization path — so the sync side touches nothing and the next
      launch is what frees the space. The launch pass is not awaited, since the library screen
      must not wait on a directory listing. Three digests are deliberately left: one a live
      work still names (two works over one file are one file), one the node has not received —
      `releaseEbook`'s rule, because that file is on this device and nowhere else — and one *no*
      work names at all, which is what an interrupted import leaves and what its retry adopts.
      The last of those is why `holdsContent` is asked as well as `readWorksNaming`; neither
      needed a new query, so no drift regeneration. The pin row survives on purpose: it is
      keyed by the digest, and a reader who restores the work should not have to say again that
      they keep it. Six tests, including the restore, which is what makes an undo a download
      rather than an import

### Synchronization

- [x] `fix: reject a delivery the replica cannot hold` — `_apply` caught `DeltaException`
      alone; an operation violating a CHECK — an unknown format, a note with no text, a percent
      past a hundred — threw out of the reconciler, the page aborted with the cursor unmoved, and
      the scheduler reconnected into the same operation for ever. `seed.dart` said the reconciler
      rejects such a delivery, and it did not; now it does. **The closed sets are checked by the
      delta readers first**, so that the refusal names the field: `requiredOneOf` for a format
      and the two kinds, `numberWithin` for the percent, and the note's text is read against the
      row the write would leave — an update that turns a highlight into a note without saying
      what it says is refused as an empty note is. Under the readers is a net for the constraints
      this build does not name, and it is narrower than *any sqlite failure*: only result code 19,
      a constraint, becomes a verdict, because a full disk or a locked file also arrives as a
      `SqliteException` and answering *rejected* to one of those would move the cursor past a
      change this device never applied. Two things the probe turned up. On the five native
      targets the replica runs on a background isolate and the exception arrives wrapped in
      `DriftRemoteException`, so the net unwraps it; and drift checks a column's declared length
      in Dart before the statement is built, so `InvalidDataException` is the same fact and is
      caught too. The transaction survives a failed statement, which the test proves by applying
      the next operation of the same batch
- [x] `fix: release the stream when a delivery fails` — a failure in `_handle` ended the channel
      with the subscription still held and the controller still open, and `close()` returned
      early because the commands sink was already null. **Being served and being held are now
      two different questions**: `_live` says whether the channel is serving and is what ending
      clears, and the sink and the subscription are resources only `close` releases. Keying the
      close on the subscription alone was not enough, which the test found: ending had already
      dropped the sink, so nothing hung up the outbound half and the node never learnt the
      device had gone. The other thing the test found is that **the half-close cannot be waited
      on** — a request stream whose transport has already failed never finishes closing, and
      awaiting it hung `close()` for the full timeout after every failed channel. It is sent,
      and what says it arrived is the node ending the stream, which is the wait that was already
      there. The fake node now records that the device hung up, because the leak is only visible
      from the other end
- [x] `fix: report a channel that ended before it was watched` — `done` returned a completed
      future when the completer was nulled before the scheduler subscribed, so a transport that
      failed during `open()` was an unhandled error and a clean end at once, and the status never
      said failure. **The completer now survives the end and is replaced by the next `open`**, on
      both channels. Two things came with it. The watch keyed `isOpen` on that same completer, so
      keeping it meant giving the watch the `_live` flag the stream had just grown — the two
      channels answer *am I open* the same way now. And keeping the completer is not by itself
      enough: a future completed with an error nobody is listening to is an unhandled error in
      Dart, and the loop above subscribes on the line *after* the open returns, so a no-op
      handler is attached where the completer is made and the real listener still receives what
      ended it. The tests were written to fail first — asking for `done` before the channel had
      ended passed against the old code too, so they wait until it has ended and only then ask
- [x] `fix: record an exchange only on evidence` — *last reached the node* was written right
      after `open()`, and `open()` does not reach the node: gRPC dials lazily and the stream's
      open only reads the database. A device whose node had been down a week said *just now*.
      **The three things that count as evidence are an event received, a push the node answered
      for, and a channel that lasted `settledFor`**, and where each is recorded follows from who
      can see it: the first two belong to the channels, because they are what receives them, and
      the third is the scheduler's, because it is the only one this layer can see for itself. The
      watch grew the injectable clock the stream already had, so that a test can name the instant
      rather than assert *not null*. Two cases are deliberately evidence: a notification about a
      position this device already holds, which asks for no pull and is still the node answering,
      and the verdicts for a push that moved no cursor. `pulled_at`'s own comment, the DAO's and
      `architecture.md` all said the column moves when a channel opens; all three now say what it
      does
- [x] `fix: keep an offer's failure inside the scheduler` — on the web `offer()` is a push RPC
      and rethrew the transport failure into `unawaited(nudge())` and out of `syncNow()`.
      **Both now go through one `_offer`, which publishes the failure as the status** rather than
      letting it out: the outbox listener is the path that matters, because nothing is holding
      the future it returns and the failure was an unhandled error rather than something the
      screen could say. The status keeps the activity, the wait and the attempt it already had —
      an offer that failed is news about a call and not about the channel, which on the web is a
      different call and may still be perfectly open. Both tests were run against the old code
      first, and both failed there
- [x] `fix: stand down a channel that was still opening` — a lifecycle or session event while
      `open()` was pending closed nothing, and `_connect` went on to publish *live* and wait on
      a channel nobody wanted, in an app that had gone into the background or signed out.
      **The conditions are re-read on the line after the open returns**, and the `finally` that
      was already there closes what has just opened — so the fix is a check and a `return`
      rather than a second close to keep in step with the first. The fake channel grew a
      completer a test holds the open on, which is the window the whole bug lives in and the
      only way to land an event inside it
- [x] `fix: let the scheduler start twice` — the lifecycle listener was a `late final` assigned
      in `onListen`, which a broadcast controller runs again for the subscription following a
      cancelled one. **A loop stopped and started again therefore threw a
      `LateInitializationError` from inside a stream callback**, which is the one place nothing
      is able to report it — and stopping and starting is what a sign-out and a sign-in do. It
      is nullable now, created in `onListen` and disposed and cleared in `onCancel`, so the
      lifecycle is watched again rather than watched twice. The test drives a real lifecycle
      message through the binding after re-subscribing, and reproduces the exact error against
      the old code
- [x] `feat: prune the applied operations` — the table grew by one row per pulled operation and
      nothing deleted one. **The window is thirty days**, and the judgement behind it is worth
      more than the number: the table makes a redelivery *free* rather than *safe*, because
      applying an operation twice is already harmless — the merge is idempotent and the second
      application loses to the version the first one wrote — so what a row buys is a decode
      avoided and a `duplicate` told apart from a `superseded`. It is therefore sized against the
      two redeliveries that really happen, a page re-read after a device died between the commit
      and the cursor, and an operation arriving by a second route from a peer that replicates the
      same reader; both are days at the outside. It runs where a channel settles, which is the
      same evidence the exchange is recorded on: connected, and in the middle of nothing. A
      failure to prune is logged and no more — a table that did not shrink is not a reason to end
      a channel that is working. No column was added, so the schema is untouched
- [x] `fix: report a peer whose clock is far ahead` — `observe` returns whether the peer is
      past `maxClockDrift` and documents that the caller's job is to report it; the reconciler
      discarded the answer, and it is the only caller. **It is a warning once per device**, held
      in a set that lives as long as the reconciler, because the next operation from that peer
      carries the same news and a line per operation is a log nobody reads. What the warning has
      to convey is why it matters rather than that it happened: a device stamping that far ahead
      wins *every* tie-break against this one, so a reader's edits keep losing to a wrong clock
      and nothing on any screen would ever say so. The operation itself is applied exactly as any
      other — the answer is about the clock and not about the change
- [x] `refactor: share the origin lookup and the revision reader` — three copies of the origin
      domain lookup, four of the row-to-revision body, and a set that was only ever asked whether
      it is empty. The lookup becomes `origin.dart`, an extension on the database taking the one
      thing that ever differed between the copies — the operation the refusal is reported under —
      and the three refusals become one sentence. **The four revision bodies needed a type before
      they could become one function**: drift generates four unrelated classes for four tables
      carrying the same mixin, so `HasRevision` is declared beside `RevisionColumns` and named in
      each `@DataClassName(implementing: ...)`. That is a change to what is generated and not to
      the schema — no column, no version, no migration — and `database.dart` had to import the
      interface for the generated part to see it. The set of offered identifiers is a `bool`: the
      verdicts name the operations they answer for, so the only question it was ever asked is
      whether another batch may go out
- [x] `test: cover the scheduler's backoff and syncNow` — the reset of the backoff by a channel
      that lasted `settledFor`, `syncNow` clearing a running backoff, and a channel that fails
      during `open()` had no test between them; each has one now, and the third made the fake
      channel attach the same no-op handler to its own completer that both real channels do,
      because a channel ending before the loop subscribes is the whole case being tested.
      **`fake_async` is deliberately not used**, which the plan suggested: these tests drive a
      real in-memory replica, and a zone that fakes every timer does not advance sqlite's
      futures, so the loop would deadlock rather than run fast. What the tests needed instead was
      a *wall clock* they could move, since `lasted` is measured against it and nothing else, and
      that is the clock the exchange tests already grew. The waits stay real and short —
      twenty milliseconds — and are polled for rather than slept through

### The reader and the shell

- [x] `fix: mount the page before the book opens` — the body showed the spinner while `open`
      ran and placed `host.view()` only afterwards, and both real hosts complete `open()` from a
      callback of the widget `view()` builds: the webview's `onEpubLoaded`, and on Linux the
      glue's `readyToLoad`, whose completer was created in the view's `initState`. So on five
      targets every book timed out after thirty seconds, on Linux `_sendBook` threw
      `epub_not_ready` at once, and the widget test passed because its fake opened synchronously.
      **The view is mounted from the first frame and the spinner and the refusal are opaque
      layers over it**, in a `Stack`: the tap that toggles the chrome still reaches the page, and
      the refusal is opaque so that a tap on it cannot hide the way back under a message that
      says the book is not coming. Two things moved in the desktop host on the way. Its `_ready`
      is created with the host and awaited under the open deadline, so an `open()` that arrives
      before the view is mounted waits instead of refusing and a CEF that never comes up is a
      timeout rather than a future nobody completes; and the host is handed the webview *before*
      the readiness event is dispatched, because the old order let `readyToLoad` race the
      assignment `_sendBook` refuses without. The test's fake host completes `open()` only once
      its view's `initState` has run, as the real ones do, and a new test holds the file open and
      looks at the first frame: the page is there under the spinner before the host has been
      asked. Neither real host was run on a device here
- [x] `fix: silence a command that was disposed mid-run` — `Command` notified in its `finally`
      with no disposed flag, so leaving a screen while a command ran — the reader while its book
      opened, the book screen while its file downloaded — reached `ChangeNotifier`'s
      `notifyListeners` after `dispose()`, which asserts in debug. **The command tracks its own
      disposal and both notifications go through a guard**, the one before the action as well as
      the one after, because a command disposed between `execute()` and its first `await` is the
      same case one frame earlier. The action still runs to its end and the result is still
      kept: what is silenced is the announcement to a listener list that is gone, not the work.
      The test starts a run, disposes the command, completes the action and asserts the listener
      heard the start and nothing after it
- [x] `fix: tell the reader why the book did not open, in their language` — the refusal's
      default branch rendered `AppException.message`, which `errors.dart` calls diagnostic, which
      names hosts and identifiers freely and which both hosts write in English: *the book did not
      open within 30s* under a Portuguese title. **Every sentence now comes out of the ARB and is
      chosen by the code**, which is what a code is for — it survives a rewording on either side
      of the wire, and the message goes to the log where it was always meant to. Six branches and
      not two: the file elsewhere and the unreadable format as before, a work another device
      deleted borrowing the two sentences the book's own screen already says, a file past the
      size this build reads whole, a file the engine refused, and a timeout. **Only the timeout
      offers a retry**, because it is the only one where reading the same bytes again can end
      differently. The codes those branch on were literals in four files and are now named
      constants beside the two that already were. Folded in from the data review, since it is the
      same boundary: the four `on Exception catch` clauses around the host are `on Object`, and a
      failure that is not an `Exception` — a `TypeError` from a bridge answering an unexpected
      shape — becomes an `AppException` carrying it as its cause instead of escaping the
      `Command` as an unhandled error over a book that had merely failed to open
- [x] `fix: announce a restore or a filing that failed` — the delete's *undo* awaited
      `restoreEbook` and announced *the book is back* whatever it answered, over a shelf that did
      not have it; and the shelves dialog checked `model.file.result` once, after it closed,
      which is both too late and wrong — the command clears its result on the next run, so a
      refusal followed by a mark that worked was reported as a success. **The undo is a
      `Command0` on the view model and the filing's refusal is shown beside the list that raised
      it**, while the dialog is still open, with the after-the-fact message kept as a second
      chance for a reader who closed on it. The undo's command is the one place this sub-section
      leans on another of its own fixes: it runs *after* the screen has gone, so the view model
      that owns it is already disposed, and that is sound exactly because a disposed command now
      finishes its action and keeps its result and only stops notifying. It also takes the
      repository out of the widget, which is what the screen was reaching for before
- [x] `fix: drop a bridge message the host does not understand` — four findings in the Linux
      host and its server, and the first is the one that matters: **everything crossing the
      bridge is a string somebody else's JavaScript wrote, and it arrives in a platform callback
      with no `await` above it**, so a `jsonDecode` that threw was an unhandled error in the zone
      rather than a message the host declined to read. The decode is now a pure function that
      logs and answers `null`, which also makes it the one part of this file a test can reach
      with no CEF; the handler name and the argument list are read rather than cast, and a
      `progress` that is not a number is a page whose location index has not finished generating
      rather than a `TypeError`. `_request` sent through a helper that **did nothing at all when
      there was no webview**, so `textOf` before the page existed waited the full thirty seconds
      for a reply nobody would send, where a page turn in the same state refused at once — both
      go through one precondition now, and the pending completer is registered after the send so
      a refusal leaves nothing in the map. The engine server said `no-cache` under a comment
      claiming the opposite: that directive asks for revalidation before every use, which is a
      conditional request per asset per book against a server that cannot answer 304. It is a
      lifetime now, and it cannot outlive what it describes — the port is chosen at bind time, so
      the next run is a different origin. The completed-`readyToLoad` guard landed with the mount
      fix above, since that is where the completer moved
- [x] `fix: keep the destination through onboarding` — a device whose credential expired while
      it was reading, and a book somebody shared as a link, both arrived at the library after
      signing in: the guard deflected to `/onboarding` and remembered nothing. **The destination
      is carried and honoured, and it is validated as a local path before it is** — it reaches
      the guard from the address bar, and an absolute URL admitted there would be this app
      forwarding a reader who has just typed their password to somebody else's site, with
      `//host/path` the same thing spelled to look like a path. The plan asked for a query
      parameter and that alone does not work, which is worth recording: the redirect writes
      `?from=` onto `/onboarding`, but a reader then walks to the sign-in screen and on to
      registration, and every one of those hops is a `go` to a bare path that keeps no query. So
      the parameter is what a browser reload restores and the guard **also remembers its own
      deflection** for the length of the sign-in it caused — which is the guard knowing about
      itself, rather than four onboarding screens forwarding a parameter none of them is about.
      The reset route is exempt from the signed-in-leaves-onboarding rule for a different reason:
      the credential arrives in a mail client, and a reader who already has a session here is
      still a reader changing their password
- [x] `perf: rebuild the chrome and not the page` — the reader wrapped its whole scaffold in one
      `ListenableBuilder` and called `host.view()` inside it, so **every page turn, every
      selection and every mark that arrived by synchronization asked the framework for a new
      platform view** — a webview on five targets, a CEF texture on the sixth — to move a
      progress bar four pixels. The view is built once in the state and handed down; the
      listeners moved inside the chrome, one for whether it is showing, one for the bar and one
      for the row that follows the page, and the column inside the chrome is passed as the
      builder's `child` because showing and hiding it does not change what is in it. The
      adaptive shell had the same shape for a smaller reason: its listener sat above the
      `Scaffold`, the navigation surface *and* the branch, so a number from the sync loop rebuilt
      whichever screen the reader was on — the reader included. It subscribes inside the badge
      now, which is the only thing that number changes. The test counts what the fake host's
      `view()` was asked for across a chrome toggle, a page turn and a selection, and the answer
      is once
- [x] `fix: let the shelves grow with the system text` — three fixed numbers and no test in the
      suite had ever set a text size, which is why they survived five phases. The continue-reading
      band was 116 pixels holding four lines and a bar; it is now that height with the text part
      scaled, and the card widens with the type up to half again, because a title at 200% in a
      240-pixel card is two words and an ellipsis. The shelf's `childAspectRatio: 0.52` was the
      more interesting one: **a cell is a cover, whose height follows its width, plus two lines,
      whose height follows the reader's type size, and one ratio cannot be right for both.** The
      grid counts its own columns the way the delegate does and gives each cell a computed
      `mainAxisExtent`. The failure it fixes is *not* an overflow, which is why the obvious test
      would have passed: the cover is an `Expanded`, so a cell that reserved too little for the
      text took the room out of the cover, and `AspectRatio` kept its proportions by narrowing —
      a paperback floating in a column of white rather than a yellow-and-black stripe. The test
      pins the cover to the cell's full width at 1.3× and 2×, and fails if the reserve stops
      following the scaler. **Semantics arrived at the same time and this app had none.** Both
      progress bars carry a label and a value, and the value is a bare percentage because the
      framework refuses to read one with a word in it as a number; the reader's page is a
      `Semantics(button:)` over a widget that is otherwise an unnamed tap target on top of
      somebody else's document; and Escape toggles the chrome, which was the one control
      reachable by nothing but a tap on the page
- [x] `refactor: split the reader and the library screens` — a pure move, with one thing lifted
      out of it. `reader_screen.dart` was 913 lines and is 156: the body and its two refusals,
      the chrome with the bar and the progress, the contents sheet, the selection's actions and
      the note dialog are each a file, and what is left is the screen — the view model it owns,
      the host's view built once, and the keyboard. `library_screen.dart` was 740 and is 186,
      beside the shelf and its two shapes, the work's tile and card with the cover, the filter
      row, the two menus and the body with its three emptinesses. The widgets that moved became
      public, which is what a split costs in Dart and is also what the file names now say. The
      lifted thing is **`MarkPainter`, which is the one part of the reader that is an algorithm
      rather than a screen**: it owns the map of what is on the page, the diff against it is the
      whole of the reconciliation, and a failure leaves it believing nothing is painted so that
      the next emission is a full redraw and not a diff against a lie. It had needed a host, a
      repository and a settings store to exist; it now needs a recorder, and its seven tests say
      things the screen's tests could only imply — that a bookmark paints nothing, that a
      highlight given words is erased and drawn again, that `forget` erases nothing
- [x] `perf: hand the desktop host one copy of the book` — base64, then JSON, then the source of
      the call: **three transient copies of a whole book, each larger than the file**, beside the
      one the view model holds — for a format whose files run to tens of megabytes, on the target
      that already carries a browser engine. The book is offered on the loopback socket that is
      already serving the engine, at an unguessable path that answers once, and what crosses the
      bridge is a URL the page fetches. The alternative the plan allowed — encoding once — was
      declined because it still puts the book in a string in a script. **The engine is not
      touched**: it is the same glue function called by the same name with the same options, and
      `loadBook` takes a byte array as it is, so a fetch feeding it one is an argument it already
      accepted. The offer is withdrawn when a host is disposed, since a reader who closed the
      screen before the page came up would otherwise leave a whole file on the server for the
      life of the process; and the host drops its own reference once the page has been told where
      to look, which is the fourth copy and the one nobody had counted. None of this was
      exercised against CEF here — the server half is, and it is the half this project wrote
- [x] `test: one fake per repository, and a contract they share` — the 1400-line file is nine
      files under `test/ui/fakes/` and a `fakeProviders()` that composes them, which is the dull
      half. The contract is the other half and it found three real disagreements, each of which
      had been holding up a screen test that proved nothing. **The library fake answered every
      query with the whole list**: the shelf's search, its format filter, its order and its
      exclusion of tombstoned works were exercised nowhere, because the fake handed back whatever
      a test had pushed. **The annotation fake answered `watchMarksIn` with every mark it had
      ever been given**, so a highlight from another book would have been painted over this one's
      page and no test would have minded. And **neither replayed its last answer to a watch that
      started afterwards**, which drift's own `watch` does — a difference that reads as a screen
      stuck on its spinner, and the reason the first run of the contract timed out rather than
      failing. The fakes now narrow, scope, order and replay as the repositories do, using the
      same collation for the search — sqlite's `LIKE` is ASCII-insensitive, which is why the real
      one matches in Dart and why a fake using `contains` would disagree exactly on *sertoes*.
      The contract is a mixin: a subject says only how it seeds, and twenty-two descriptions run
      against the fake and against the drift-backed repositories in one file
- [x] `fix: let the page say when it is there` — no book had ever opened on Linux, and three
      separate faults were each enough on their own. **Every message the page sent was dropped**:
      `webview_cef` implements a channel as `external.JavaScriptChannel`, which `JSON.stringify`s
      whatever it is handed before the message leaves the render process, and the shim was
      handing it a string it had already encoded — so `jsonDecode` answered a `String` rather
      than a map and the host declined `readyToLoad`, `rendered`, `relocated` and every reply
      alike. **The channel was installed into a document that no longer existed**: the plugin
      installs one by assigning a global in whatever context is current, and it was asked
      immediately after `initialize()`, which answers a *browser* fifty milliseconds after
      creation and long before it has navigated, so the assignment went into the context CEF was
      about to leave. And **the readiness event was dispatched before the glue could hear it** —
      `epubView.js` registers that listener at the end of nine hundred kilobytes of script, and
      the event went out two method calls after the browser was created. The reader saw an empty
      page and, thirty seconds later, a timeout. **The page now says when it is there**, over the
      loopback socket that is already serving it: a host takes an `EngineSession` whose
      identifier rides in the page URL's query, the server writes a `fetch` of `/ready` in
      immediately before `</body>` — after `epubView.js`, which is the ordering the dispatch
      needed — and completes that session when the request arrives. Only then does the host
      install the channel, publish the webview and dispatch the event. The two ends of the
      document are the two ends of the ordering, and neither is a delay any more. The session is
      closed with the host, as a book on offer already was. Confirmed against CEF on a device,
      which the three commits before it were not

### Delivery

- [x] `fix: cache the renderer that runs` — the worker precaches every file the build wrote,
      including the symbol maps and three renderers a JavaScript build never loads, and
      `addAll` is atomic, so one failed fetch of forty-five megabytes leaves the shell not
      offline at all. Exclude what never loads and record the new size. **The review's premise
      was half right, and the wrong half is the one that would have blanked a browser.** A
      JavaScript build does not load only `canvaskit/canvaskit.{js,wasm}`: in the default `auto`
      mode `flutter.js` picks `canvaskit/chromium/` on a Chromium browser and the full variant
      everywhere else, and the choice is the browser's at run time rather than the build's, so
      both pairs stay. What goes is what the loader cannot reach from this build — `skwasm`,
      `skwasm_heavy` and `wimp` are selected only from a `dart2wasm` entry in the build
      configuration and there is none; `webparagraph/` only under a `preferWebParagraph` the
      bootstrap never sets; and the six `.symbols` files are the profiler's. Measured against
      the build: **53 files and 44.4 MB before, 39 files and 20.5 MB after**, of which the two
      renderer pairs are 12.3. The renderer directory is a **whitelist and not a blacklist**,
      because the failure modes are not symmetric: a variant the engine grows and the list does
      not name is fetched from the network, which is the app online rather than a cache that
      never installed, where a blacklist would precache it and be back at the atomic `addAll`.
      Nothing is pruned from the build itself and the worker still passes any request outside
      the shell through, so a wrong guess costs offline for one file and never a page. The size
      notes in the Makefile and `architecture.md` now say what is cached rather than what is
      copied
- [x] `fix: stamp the tag's version on every artifact` — `msix:create` reads the pubspec and the
      Flatpak metainfo carries a literal, so two of six artifacts ship `1.0.0` whatever the tag
      says. Pass the derived version to both. Checked against the package rather than assumed:
      msix resolves its version as `--version`, then `msix_version`, then the pubspec's
      `major.minor.patch` with a zero appended, and refuses anything that is not four numbers,
      so **the workflow hands it `<tag>.0`** in both the signed and the test-certificate branch
      and the pubspec keeps no `msix_version` — a laptop's `make package-windows` still packages
      the pubspec's number, which is the right number for a package nobody tagged. **The
      metainfo is rewritten in the Linux job and not templated**, because a software centre
      reads that file and never the tag: a `sed` over the one `<release>` line, with the tag's
      version and the run's UTC date, followed by a `grep` for exactly the line it should have
      produced, since a substitution that matched nothing would be a Flatpak saying `1.0.0`
      forever. The committed literal stays and says what it is. Two things were noticed and
      left: neither the Linux bundle nor the web archive is versioned at all — `make
      package-linux` and `make build-web` run without `--build-name`, which is invisible
      because nothing in `lib/` reads the version — and a manual run's `0.0.0.0` passes msix's
      own check but whether `MakeAppx` accepts a zero major is not something this machine can
      answer. Nothing here was executed: both jobs run on hosts this machine is not
- [x] `fix: name the application the same on every target` — Android, Linux and Windows show
      `atril` where the other three show `Atril`. **Four, not three: macOS was lowercase too**, and
      the entry above was wrong about it. `PRODUCT_NAME = atril` is what `CFBundleName` expands
      to, which is the application menu and the About panel, and it is also the name of the
      bundle on disk, which is what Finder shows — so the fix there is the product name and not a
      plist key, and it moves `atril.app` to `Atril.app` through the Xcode project, the shared
      scheme and `packaging/macos/package.sh`, which named the path. iOS had `CFBundleName`
      lowercase under a capitalised `CFBundleDisplayName`; it is capitalised for the same reason
      even though the home screen never showed it. What deliberately **stays lowercase is every
      name that is a file**: `atril` the executable on Linux and Windows, `atril.exe` in
      `OriginalFilename`, `InternalName` beside it, `Exec=atril` in the desktop file and
      `command: atril` in the Flatpak manifest, because the desktop file's `StartupWMClass` and
      the manifest are matched by that name and a capital there is a launcher that finds nothing.
      Nothing was compiled for this commit on this machine: the Linux release build of the strip
      below is what exercises the GTK title, and Android, Windows, iOS and macOS are read and
      left to the four CI jobs — the macOS rename being the one of the five that can fail there
- [x] `fix: suffix the artifacts the same way` — Android puts *unsigned* before the target and
      macOS and Windows after it. The Android job folded the suffix into the version variable —
      `atril-1.0.0-unsigned-android.apk` — where the other two append it to the target, and the
      release page would have sorted the six by version, then by target, with the one exception
      breaking the run. **The suffix moves to the end**: `atril-<version>-android-unsigned.apk`
      and `.aab`, so every unsigned artifact of a release answers the one glob
      `atril-*-*-unsigned.*`, which is the check a person does before publishing. iOS already
      had it in that position and is untouched. Not executed here: the release workflow has
      never run and this is a `cp` inside it
- [x] `build: strip libcef in every release bundle` — the strip lives only in the Flatpak
      manifest, so `make build-linux` and the CI job still produce the 1.5 GB bundle, and the
      pubspec still quotes the size of a file nothing was stripping. Strip at install in CMake
      and correct the comment. **An `install(CODE …)` in `linux/CMakeLists.txt`, after the loop
      that copies the plugins' libraries**, which is the first moment `libcef.so` exists at its
      bundled path — so the size is a property of every release bundle rather than of whatever
      wraps one. It is guarded on `NOT CMAKE_BUILD_TYPE MATCHES "Debug"`, beside the rule that
      installs the AOT library on the same condition: a debug build is where a crash inside CEF
      is worth reading. Two smaller decisions. It is **fatal when `CMAKE_STRIP` is unset**, not
      skipped, because a release bundle three times its size with nothing saying so is the exact
      failure this rule exists to prevent; and `strip` over an already-stripped file exits zero,
      so the rule is idempotent and a rebuild is a no-op. **The Flatpak strip is now removed
      rather than kept**: `make package-linux` runs `flutter build linux --release` before
      flatpak-builder, so the bundle the manifest copies arrives stripped, and a second strip
      there would be a line whose only effect is to make the manifest look like the place this
      is decided. Measured on this machine, and one number of phase 13's does not reproduce:
      CEF publishes `libcef.so` at **1311 MB**, the rule leaves **244 MB** and `file` reports it
      `stripped`, and the bundle is **391 MB** rather than the 486 MB phase 13 recorded — that
      figure was read off the Flatpak's `/app` tree and not off `build/linux/x64/release/bundle`,
      which is what the pubspec and `architecture.md` now quote. Verified by
      `flutter build linux --release` from a deleted `build/linux`
- [x] `ci: build the android release` — the pull-request matrix builds debug, so the release
      configuration and the shrinker run only in a workflow that has never run. The debug-key
      fallback makes a release build safe on a runner with no keystore. **Android alone moves to
      `--release`, and the other five stay on debug deliberately**: on those, a release build
      adds tree shaking and signing to a check that is about whether the platform embedder still
      compiles and links, which is coverage of the toolchain rather than of this repository. On
      Android it is the opposite — `build.gradle.kts` is the one release configuration phase 13
      *wrote*, R8 runs only in that mode, and the signing branch that falls back to the debug key
      and announces it exists precisely so a runner with no keystore can take this path. Both had
      run nowhere: the only workflow that built a release APK is `release.yml`, and that has
      never run. `JAVA_TOOL_OPTIONS` is left exactly as it was — the `-Xlog:disable` this
      project needs is a local distrobox workaround and belongs to `release.yml`, not here. Not
      executed: an Android build needs the SDK and a runner, and this machine has neither ready
      — what is verified is that the workflow file still parses
- [x] `ci: pin the actions and enforce the lockfile` — two third-party actions run at mutable
      tags beside the signing secrets, and `pub get` may resolve differently from the lockfile.
      Pin to commits, add Dependabot for both ecosystems, and pass `--enforce-lockfile`.
      **All twenty-eight `uses:` are pinned, not just the two third-party ones**: a tag is a
      mutable pointer whoever owns the repository can move, and `actions/checkout` is as able to
      move `v7` as anyone — the argument for pinning is about who can change what runs beside
      `MACOS_CERTIFICATE_BASE64`, and that argument does not stop at the `actions` organisation.
      Every pin carries the version it was resolved from as a comment, which is what makes the
      diff of a bump readable. One of the six needed care: **`arduino/setup-protoc@v3` is a
      branch and not a tag**, so the pin is `c65c819`, the commit `v3.0.0` peels to and the head
      that branch currently points at — resolved with `git ls-remote`, not guessed. The others
      are `checkout` v7.0.1, `flutter-action` v2.23.0, `setup-java` v5.7.0, `upload-artifact`
      v4.6.2 and `download-artifact` v4.3.0. `.github/dependabot.yml` is what keeps a pin from
      quietly ageing: **github-actions weekly, pub monthly and grouped into one pull request**,
      because twenty-five packages already trail their latest release behind constraints this
      project set deliberately — `flutter_inappwebview` on a pre-release, `drift` matched to the
      committed web assets — and a pull request per package weekly would train everybody to
      ignore the one that matters. `--enforce-lockfile` goes on all eight resolves, and it was
      **run here rather than assumed**: `flutter pub get --enforce-lockfile` exits 0 in this
      worktree, path `dependency_overrides` and all, which was the thing worth checking before
      making it a gate. Verified locally: the resolve, and that all three YAML files parse
- [x] `ci: measure coverage and hold a floor` — `make coverage` runs nowhere, its filter keeps
      the generated localizations, and nothing fails when a phase drops coverage. The filter
      grows `lib/ui/core/localization/generated/`, which is the third generator and the only one
      whose output the old two patterns missed — it is neither under `data/services/api/generated`
      nor named `.g.dart`, so 2,500 lines of `gen-l10n` output were being counted as this
      project's tested code. **The floor is 85%, and it is a ratchet rather than a target**: the
      tree measures **87.5% of 9,266 lines across 174 files** with the three generators excluded,
      so 85 leaves two and a half points of room for a phase that adds code before it adds tests
      and still turns red on a real drop. Raising it is a decision that belongs in a diff, which
      is why it is `COVERAGE_FLOOR ?=` in the Makefile and not a literal in the workflow. The
      check is `tool/check_coverage.dart` — lcov's `LF`/`LH` records summed, and **an empty
      report is a failure**, because a filter that matched everything would otherwise be the
      greenest build this project ever had. In CI it **replaces** `flutter test` rather than
      following it: `--coverage` runs the same tests, and running them twice to measure the
      second pass would double the longest step in the job. The report is uploaded on
      `if: always()`, since the run that fails the floor is the one whose report somebody wants.
      The reviewer measured 86.5% at the branch point; the three sub-sections merged before this
      one are what moved it to 87.5. Verified by running it
- [x] `fix: declare the percent placeholder` — three messages use `{percent}` without declaring
      it, so the generated API takes an `Object` where everything else is typed. Declare it and
      assert in the ARB test that every placeholder is. **`int`, checked against the call sites
      rather than assumed**: all three are fed a `.round()`, so the generated
      `String readerProgress(int percent)` is what the callers were already passing — the two
      `{percent}` messages that *were* declared, `ebookFileSending` and `ebookDownloading`, are
      `String` and stay that way, because those are handed a formatted fraction and not a number.
      An undeclared placeholder is not an error to `gen-l10n`; it silently widens the parameter to
      `Object`, so the one kind of message that takes a number was the one kind whose argument
      nothing type-checked. The assertion in `arb_test.dart` is what stops the fourth one:
      `{name}` and `{name, plural, …}` both count as a use, and a **plural or select branch whose
      body is one bare word** — `other{livros}` — is skipped, since it is text. Run over the
      template it finds exactly the three the review named and nothing else across **460
      messages**, and removing one declaration was checked to fail it. Verified: `make gen-l10n`,
      the regenerated output committed, `make l10n-check`, the analyzer and 1,215 tests
- [x] `ci: surface outdated dependencies` — a non-blocking `pub outdated` on every pull request.
      **Reported, never enforced, and no dependency is bumped here.** This project pins
      deliberately in two places — `flutter_inappwebview` at an exact pre-release because the
      stable one does not build for Android, `drift` matched to the committed `sqlite3.wasm` and
      worker — so a step that went red on a newer release would be a red build for a decision
      somebody already made. Measured while writing it: **16 packages are held below a resolvable
      version by the lockfile and 6 by a constraint in the pubspec**, which is the shape of a
      project that pins on purpose and exactly why this is a summary and not a gate. It writes
      `$GITHUB_STEP_SUMMARY` rather than the log, since a report nobody opens is a report nobody
      reads, and it carries `continue-on-error` with `if: always()` so it is there precisely when
      a build is red and somebody is wondering whether a dependency is the reason. It sits beside
      Dependabot rather than duplicating it: Dependabot proposes one move at a time, this says
      what the whole tree looks like. Verified locally — the command exits 0 with everything
      current-as-constrained; the summary redirection is CI's and was not run
- [x] `ci: cache the pub cache on linux` — CEF is 658 MB and is fetched on every Linux job.
      **The pub cache was already being cached, which is why this needed reading rather than
      adding**: `cache: true` turns on the action's pub cache too, so the fix is not a cache but
      a *key*. `setup.sh` expands the default `flutter-pub-:os:-:channel:-:version:-:arch:-:hash:`
      with `:hash:` as the **Flutter release's** hash — nothing about this project — so every
      ubuntu job in a workflow shares one key. `check` runs before `build` and finishes first,
      and it never builds Linux, so what got saved under that key was a pub cache with no CEF in
      it; `actions/cache` does not re-save on an exact hit, so from then on every Linux job
      restored the CEF-less copy and downloaded CEF again, permanently. A key of its own carrying
      `hashFiles('pubspec.lock')` fixes both halves — nothing else writes it, and a `webview_cef`
      bump becomes a new key instead of a stale unpack. **Only Linux gets one**, in `ci.yml`
      through a `matrix.target == 'linux'` expression that falls back to the empty string, which
      the action reads as its default: for the other five, sharing the check job's cache is a hit
      and a saving, and five private copies of the same packages would spend a repository's 10 GB
      on nothing. What is being cached is not the 658 MB download but the **3.1 GB it unpacks
      to**, Debug and Release `libcef.so` together, which is the trade this makes: a larger
      restore against a bzip2 extraction that has to happen on every run. Reviewed, not measured
      — running it needs Actions
- [x] `style: add the lints the boundaries need` — `unawaited_futures`, `discarded_futures`,
      `cancel_subscriptions`, `avoid_dynamic_calls` and `only_throw_errors`, landed last so that
      they ran over the other three sections rather than over the tree that had the bugs in it.
      **`close_sinks` is not among them, and the configuration says why.** Every sink here is a
      field closed by its object's own `close`, and the rule only recognises a close in the
      function that opened the sink: on the merged tree it reported the blob write, the sync
      stream's command channel and the lifecycle broadcast, all three correct and none of them
      the leak phase 14 actually found — which was a subscription, and which `cancel_subscriptions`
      covers. A rule carried as a standing list of ignores records the decision worse than a
      paragraph does. `cancel_subscriptions` and `avoid_dynamic_calls` were already clean; the
      other three found **nineteen** places. Sixteen are a command run from a constructor or a
      submit handler, which is the pattern the architecture asks for — the screen listens to the
      command rather than awaiting it — and `unawaited()` now says so at each one instead of
      leaving a reader to infer it. Two were real: `Session.dispose` closes a sink and returns
      the future, and two teardowns dropped it, so a test could shut its connection down while
      the session was still closing. The last is a fake hanging up. The tests carry their own
      `test/analysis_options.yaml`, which includes this one and turns off `only_throw_errors`
      alone: a fake refuses with the `Object` it was handed on purpose, because the boundaries
      widened to `on Object` earlier in this phase and a fake that could only throw an `Error`
      could not exercise what they were widened for
- [x] `fix: let the page report the reader's taps and keys` — the reader freezes on the web
      target the moment it is clicked, and the two reasons are both about a platform view.
      **A `GestureDetector` over one receives nothing**: the browser hands the click to the
      engine's `<iframe>` and Flutter's glass pane is never told, so `reader_body.dart`'s tap
      target had never fired once on any of the five webview targets. **And that click takes the
      keyboard with it**: it moves DOM focus into the book's document, a key event fires in the
      document that has focus and does not cross into its parent, so `reader_screen.dart`'s
      `_onKey` — the arrow keys, space, PageUp/PageDown and Escape — goes silent from the first
      tap onwards and never comes back. On a browser, where the chevrons in the bar are the only
      other way to turn a page, that is a book that has stopped. Measured rather than reasoned:
      a Flutter 3.47.1 web build of the reader's own arrangement reports `taps=0 keys=1` before
      a click and `taps=0 keys=1` after one, with `document.activeElement` an `IFRAME`, and
      `keys` moves again only when focus is handed back to `flutter-view`.
      **The fix is that the page reports what happens on it**, over the bridge the hosts already
      run: `page_input.dart` holds one script, injected per book, that registers through
      `rendition.hooks.content` — the engine's own door for running something in each rendered
      document — and sends a tap and a key back as `EpubHost.pageEvents`. The view model
      dispatches those to the same commands the bar's buttons use, so a page turned from the
      page, from Flutter's keyboard and from the chrome is one path with three ways in.
      **It reports less than it sees, and that is the point**: a click on a link is the book's,
      and a click that ends a selection belongs to the selection, so neither is a tap — which is
      the argument the old gesture detector made for sitting outside the page, answered better
      from inside it. The detector is **gone** rather than kept for Linux: the pointer reaches
      both the CEF texture and Flutter there, so two sources would be a chrome that toggled
      twice and therefore not at all. **Keys are forwarded on five targets and not on Linux**,
      for the mirror of that reason — `webview_cef`'s own `Focus` returns `ignored` where the
      platform has native key support, so Flutter still gets the press and a page that also
      reported it would turn two pages for one. The script is evaluated through the controller's
      `callMethod('eval', …)`, which is a property lookup on the frame's window in a browser and
      an interpolated call on the four native targets — one door for all five, and the package's
      own. It costs `unsafe-eval` to any future CSP on the web target, which is named where it is
      spent. Nothing in the engine is patched: `engine.dart`'s digests still cover the bytes that
      produce a locator.
      **Verified against the pinned engine in a real browser**, driving the string this file
      actually generates rather than a sketch of it: a click reports one `atrilTap`; arrow,
      Escape and `a` with focus inside the book all report `atrilKey`, and `a` is then dropped by
      `epubPageEventOfKey`; a drag that selects reports the engine's `selection` and **no** tap;
      and a click on a footnote link reports **nothing at all**. The Linux premise — that
      `webview_cef`'s autofocusing `Focus` answers `ignored` and the reader's handler still fires
      above it, which is why keys are not forwarded there — is pinned by a test that reproduces
      that wrapper rather than describing it, since what decides it is Flutter's own focus
      traversal. **Android was not run**: the emulator demands 7.37 GB free and the machine had
      6.0, so the four native targets rest on the web measurement and on the package's shared
      code path rather than on a run of their own. Also: `flutter analyze`, and 1,232 tests
- [x] `fix: let the reader touch its own chrome on the web` — the tap fix above landed and the
      reader still could not be clicked, and the reason was the other half of the same sentence.
      **A platform view is a hole in Flutter's own surface.** The page is a webview, and on the
      web the browser hands a pointer event to the `<iframe>` that is really there rather than to
      the canvas Flutter paints above it — so *everything* the reader draws over the page was
      dead on that target: the bar, the progress and its chevrons, the actions on a selection,
      both sheets, the note dialog and the undo. Measured in a browser build of that arrangement:
      a button over the page counted **zero** clicks. Worse than dead, for the sheets — one
      opened over the page took no click on its own barrier and Escape never reached Flutter, so
      a reader who opened the contents could neither use it nor get rid of it, which is exactly
      what *cannot click* looked like from the outside.
      **`pointer_interceptor` is the answer and it is the Flutter team's own**, from
      `flutter/packages`: it puts a real DOM element over the region so the browser has something
      of Flutter's to deliver the event to. It declares an implementation for **web and iOS
      only** — the two platforms where a platform view swallows what is over it — and resolves to
      a widget that returns its child on the other four, so Android, Linux, macOS and Windows
      carry three transitive packages and none of the behaviour. The pubspec argues the
      alternative that was refused: laying the chrome out beside the page rather than over it is
      a different reader, not the same one fixed.
      **It is a named widget and not a call at six sites.** `OverThePage` says once why the
      wrapper is there, and the two things easy to get wrong are the reason it needs a name.
      *What is wrapped is the row and never the column*: an interceptor over the chrome's full
      height would take every tap on the book with it, which is the same bug facing the other
      way, so the bar and the progress are wrapped and the `Spacer` between them is not. *And it
      lets go when the chrome does*: `intercepting` follows `chromeVisible`, because a bar that
      kept the click after fading out would leave two strips across the page a reader could tap
      forever without the chrome coming back. The same care picks the `Material` and not the
      `Align` in the selection bar. The refusal and the spinner are wrapped **whole**, and that
      is the one place it is right — both are opaque over the page on purpose and are meant to
      take every tap. The undo travels **inside** the snackbar's content, because
      `SnackBar.action` is typed as a `SnackBarAction` and leaves nowhere to put a wrapper.
      **Verified in a browser, one build before and after**: bar, chevron, sheet and dialog each
      counted 0 clicks unwrapped and 1 wrapped, and the dialog could only be reached at all
      because the wrapped sheet could finally be dismissed. A widget test pins the two rows, that
      there are exactly two of them, and that both stop intercepting when the chrome goes. Also:
      `flutter analyze`, and 1,233 tests
- [x] `refactor: spell the glue's names once, and wait for the calls` — `EpubGlue` named every
      function the pinned glue exposes and lived in `desktop_epub_host.dart`, because Linux was
      the only host that called the glue by name; the webview host went through
      `EpubController`'s methods instead. **Those methods drop the future the bridge answers
      with**, so a refusal from the engine — a CFI it cannot resolve in the section on screen is
      the ordinary one — arrived as an unhandled asynchronous error rather than a rejected
      future. Nothing can catch that: it lands long after the call site returned, and on the web
      it takes the page down. The vocabulary moves to `engine.dart`, where the engine is already
      pinned by digest, and both hosts now spell it from there and `await` what they call — so a
      mark that will not draw is an exception where `ReaderViewModel`'s repaint already catches
      it, and the book stays on screen. One list to check rather than two, which is worth more
      than it sounds: no compiler catches a wrong name on either side, and
      `locator_round_trip_test.dart` checks every one of them against the glue the bundle holds.
- [x] `fix: serve the bridge shim in the page as well as injecting it` — the shim that gives the
      pinned glue its `window.flutter_inappwebview.callHandler` was injected at load start and
      nowhere else, and on Linux that is a dependency on a callback that may not arrive:
      `webview_cef` delivers `onLoadStart` — the callback it injects load-start user scripts
      from — off the platform thread, which Flutter warns about and which may drop the message.
      A dropped `onLoadStart` is a shim that never exists, so the glue's `callHandler` is
      undefined, `readyToLoad` is never sent, and the book never loads at all. `EngineServer`
      now inlines the same script into the host page it already serves, so it is there as soon
      as the document parses and before any script under it runs. **Both paths are kept and the
      script is idempotent** — it returns early when `window.flutter_inappwebview` is already
      set — so the injection is a no-op when the served copy got there first. The shim and its
      channel name move to `engine_server.dart` with the serving, since that is now where they
      are used, and the two tests that named them follow the move.
- [x] `fix: load the webview plugin's web support` — `flutter_inappwebview` reaches a native
      webview on the four native targets, and in a browser its Dart half registers against a
      `window.flutter_inappwebview_plugin` that a script in the page has to define. Nothing
      loaded it, so the registration printed **`window.flutter_inappwebview_plugin is not
      available!`** on every start of the web build. The script is the package's own asset and is
      loaded from `web/index.html`, **relative** so that it resolves against the `<base href>`:
      a build served from a sub-path with `--base-href` would not find an absolute
      `/assets/…`, and the reader would fail on the deployed site and nowhere else. It is the
      only line the browser target needs that the other five do not.
- [x] `fix: read the instants this device already wrote` — `84b5b49` corrected the writer to
      RFC 3339 and left the reader refusing everything written before it. The microseconds an
      earlier build emitted are still sitting in **this device's own log**, so a reader that
      threw on them would strand what came before the upgrade rather than a peer's mistake.
      `instant()` accepts an integer as microseconds since the epoch beside the text it now
      expects: one shape is written and both are read, which is the direction that has to be
      asymmetric. The test that asserted the refusal of a number becomes the test that asserts
      the number is read, and a map takes its place as the shape nothing can be made of.
- [x] `fix: let the session reach the client that refreshes it` — the composition root closed the
      session/auth cycle with `refresher: () => context.read<AuthApi>()`, and `provider` resolves
      **upwards**. `AuthApi` is declared under `SessionHolder` — it has to be, because it reads
      the holder — so the lookup searched the half of the graph the client is not in. Deferring
      the read defers *when* it runs and not *where* it looks, which is what the comment beside it
      and the phase 0 entry above both got wrong. It failed nowhere near itself: a
      `ProviderNotFoundError` at the first token refresh, caught by the gRPC layer and reported as
      `UNAVAILABLE`, so **every call the app makes** read as a node that could not be reached —
      `make run-linux` opened a channel to the local federation and then looped on a sync stream
      that ended as fast as it opened. A `late final` at the composition root closes it, assigned
      where `AuthApi` is built, and that provider becomes eager: the call that first meets a stale
      token is usually not its own, since `SyncScheduler` is already eager and starts making them
      before a screen is touched. Building it dials nothing — the channel is opened by the first
      call. `test/architecture/provider_order_test.dart` holds the whole list to the rule, over
      the shape this bug had; nothing had ever built the graph, which is why it shipped.
- [x] `fix: survive a radio the platform will not answer` — `NodeReachability` subscribed to
      `connectivity_plus` with no `onError`. The plugin reaches NetworkManager over the **system**
      D-Bus, which a Linux container does not have, so every launch there threw an unhandled
      `SocketException` — a crash report for the one signal this class is documented not to draw
      a conclusion from. The failure is logged and the conclusion is left where it was: the calls
      go on being the evidence, and the subscription survives to hear whatever the platform says
      next. ~~Which is the whole of it.~~ The handler was necessary and not sufficient — the
      commit below is the rest, and this entry claimed a crash was fixed that was still there.
- [x] `fix: bind again when the node has forgotten this device` — `signIn` presents the
      identifier the device already writes under, because omitting it is the mistake the design
      is most vulnerable to. The node answers `NOT_FOUND` / `device_not_found` for an identifier
      it has no record of, and nothing read that code: the sign-in failed, and the row survives a
      logout by design, so **every retry presented the same dead identifier**. A device in that
      state could never sign in again, on an account the reader reaches from every other device
      they own. Found on Linux against `make dev-up` after the federation's database was recreated
      — the web build signed in and the desktop one could not, on the same account, because
      browser storage was fresh and the replica was not. The identifier is dropped and the login
      made once more as a new device, and the replica is seeded as it is for a first binding:
      what its log can reconstruct is a history written under an identifier the node has never
      heard of. **Only for that code, and only once.** `device_revoked` is a device the node still
      holds and the reader deliberately unbound, so binding it again would be this client undoing
      their decision; a second `device_not_found` is a refusal.
- [x] `fix: build the radio where its failures can be caught` — `9c9d939` added an `onError` to
      the subscription and the `SocketException` went on being an unhandled crash on every Linux
      launch, because **the platform does not report this failure through its stream**.
      `connectivity_plus` opens its NetworkManager client from the `onListen` of its own broadcast
      controller, in an `async` callback whose future that controller discards, and rethrows into
      it: the error belongs to the zone the *controller* was built in, and no subscriber can see
      it. That controller is built lazily, on the first read of `onConnectivityChanged` — so the
      radio is now built and subscribed to inside one `runZonedGuarded`, and `overRadio` takes a
      *function* rather than a stream for exactly that reason: a stream handed over ready-made
      already belongs to somebody else's zone. The `onError` stays, because the two catch
      different things and a platform that does report through its stream is still handled. The
      test builds its controller inside the same factory, which is the only way to reproduce the
      shape; it was checked to fail without the zone, and the crash was checked to be gone from a
      real `make run-linux`.
- [x] `fix: say nothing where the engine cannot say how far through` — the bar and the percentage
      never moved, on a real book, for a whole session. The position itself was being written:
      the replica held one `progress` row at vector clock 12, every operation pushed. What was
      wrong was `percent`, stored as a confident `0.0`. **A percentage comes from epub.js's
      location index, and building that index means unzipping and parsing every section of the
      book** — measured at 121s and 8326 locations for the 1182-section work this was found on,
      by running the pinned engine against the reader's own file. Until it resolves,
      `locationFromCfi` answers -1, `percentageFromLocation` returns 0 for want of a total, and
      the glue reports that 0 in the same field it reports a real one. Both hosts wrote it down,
      and the row replicated that 0 to every other device the reader owns. **This entry claimed
      the index finishing raises no event. It does — `locationLoaded` — and the entry below is
      what listens for it.**
      `EpubPosition.percent` is nullable now and `epubPercentOf` is the one rule both hosts read
      it through — the column, `ReadingPlace` and the shelf's card were already built for an
      absence, and only the port fabricated the zero. **The engine reports the same 0 for the
      reader's first page**, and the payload the glue sends carries the percentage alone, so the
      two are not distinguishable without a second script injected into the page; reading both as
      *no answer* costs the first page a 0% the empty bar already shows. The chrome holds the
      line's space while there is no number, so it does not jump under a thumb when the index
      lands, and the bar stays empty rather than indeterminate — a bar sweeping over a book the
      reader is already reading reports a page still loading
- [x] `fix: ask again when the engine can finally say where the reader is` — the entry above
      stopped the app writing down a percentage it did not have and left it with no way to learn
      one: the bar stayed empty, which is what *still not working* meant. **The glue announces its
      location index on `locationLoaded`, and nothing in this app listened.** Measured by driving
      the pinned `swipe.html` and `epubView.js` through the sequence the Linux host uses — the
      readiness event, `readyToLoad`, `loadBook` with that host's own options — against the
      reader's own file: `readyToLoad`, `chapters`, `rendered`, `displayed`, one `relocated`
      carrying `progress: 0`, then nothing for 135 seconds, then 8325 locations and
      `locationLoaded`. **One `relocated`, for the whole two minutes.** The page does not move when
      the index lands, so no further report is coming on its own, and a reader who stopped to read
      a page would wait for a number that arrives only when they next turn one. Both hosts answer
      the message by asking where the reader is again — `getCurrentLocation` on Linux, the
      controller's own on the other five — and map the answer through `epubPositionOf`, because the
      edges and the percentage in a report belong to one reading. A failure is a log line: the book
      is on screen and what is lost is a number that was already missing. The round-trip test pins
      the message and the reply against the pinned glue, beside the function names it already
      pinned — the digest stops the engine moving, and this is what notices if a permitted upgrade
      renames the one signal the percentage now depends on

- [x] `fix: open a book where the reader left it` — the actual complaint behind the two entries
      above, and neither of them touched it: read to page ten, close, reopen, page one. **The
      position was recorded from the first commit of this feature and read by nothing.**
      `ReaderScreen.at` is documented as *`null` to resume where this device stopped* and the host
      port's `open` says [at] is *a CFI this reader's device or another one wrote* — the resume was
      designed at both ends and never wired between them. `ReadingDao.placeOf` had been sitting
      there since the reading tables landed with one caller, a test. `ReadingRepository.resumeAt`
      is the missing middle, and the view model asks for it when the location carries no locator;
      a mark the reader followed still wins, because that is a reader asking to go somewhere.
      **This device's own row and never the furthest or the most recent** (C05, RN01): a phone and
      a desktop are two true statements, and opening here at the page the phone reached would move
      the reader without being asked — which of them to *offer* is the shelf's decision, made from
      all of them. A place that cannot be read is not a refusal: the book opens at the beginning,
      which is where it opened before anything remembered a position, and refusing to show a
      reader their book because the app forgot their page would be the wrong way round. The
      locator is not checked against the format on the way through, because both hosts already
      refuse one they cannot resolve and open at the beginning instead

- [x] `fix: estimate the place from the spine until the index exists` — `b919d7f` stopped the app
      claiming a percentage it did not have and `db548e9` made it ask again when the engine could
      finally give one, and between them the number simply stopped appearing: on a book whose
      index takes over two minutes, a reading session shorter than that now has no percentage at
      all, which is honest and useless. **The engine knows which section the page is in before it
      has read a word of any of them.** `location.start.index` out of `book.spine.length` is a
      real measurement of how far through the book the reader is, available from the first
      relocation, and `page_place.dart` is the script that reports it — injected through the same
      door `page_input.dart` uses and argued the same way: the renderer is pinned by digest
      because a locator is produced by the glue and the engine together, and this reads two
      numbers the engine already computed rather than resolving anything. It parses no CFI. Every
      position carries the engine's own answer when there is one and the spine's when there is
      not, so the estimate is replaced the moment the index lands — and `locationLoaded` is what
      asks for a fresh position to replace it with. **The coarseness is self-correcting in the
      direction that matters**: a thousand-section book is where the index takes minutes and where
      one section is 0.08% of the whole; ten fat chapters is where a section is a tenth of the
      book and the index lands in about a second. Verified against the reader's own file by
      injecting the script into the pinned `swipe.html` under the sequence the Linux host uses —
      `{index: 0, spine: 1182}` on injection, `{index: 2, spine: 1182}` after twelve page turns,
      with the engine still answering 0. **Which is also the honest news about that book**: twelve
      turns is 0.17% of it, the display rounds to 0%, and a bar that barely moves there is the
      truth about a work of 1182 chapters rather than a fault in the measurement

- [x] `fix: ask again for a cover that arrived after the shelf did` — a shelf of placeholders over
      books this device had pictures of, on the web, after every sign-in. **The cover was never
      lost**: the replica held a 316 kB JPEG for the work on screen, the book's own screen drew
      it, and a cell built fresh — by narrowing the window until the grid becomes a list — drew it
      too. What was wrong is *when* the grid asked. A device that was just bound is seeded with
      the reader's whole collection and downloads the files after it, so the row reaches the shelf
      seconds before the bytes do; `_Cover` asked once, was told `null` — truthfully — and cached
      that answer for the life of the screen, which under a pushed route is never rebuilt. The
      work's own screen never had the bug, because `EbookViewModel` already asks again when the
      file lands. `LibraryRepository.coversExtracted` is the missing signal: identifiers and not
      pictures, one broadcast rather than a query per work, so a shelf of two hundred books is
      still two hundred listeners and not two hundred watches on the replica — which is what the
      tile's comment claimed to be protecting all along. **Found by attaching to the running
      `flutter run -d chrome`** over Chrome's debugging port and reading the web replica out of
      IndexedDB, which is how the picture was shown to be there before a line was changed

- [x] `fix: show one card per book in the strip, and the devices on the book's own screen` — seven
      identical *Circle of Inevitability* cards across the top of the library, each saying *em
      outro dispositivo*. Six of those devices were an artifact of `flutter run -d chrome` handing
      the app a fresh Chrome profile every launch, so the client correctly bound a new device each
      time and the node kept all seven — **but the pile-up is the design and not the accident**:
      one card per *device* is what the strip was written to do, and a reader with a phone, a
      tablet and a laptop in one novel would see it on their own machines.

      **This reverses the decision the entry above the reading section states**, and it is worth
      saying which half of it was wrong. *Where is each of my devices in this book* really is a
      question with one answer per device, and C05 is why: a position belongs to one work and one
      device and is written by that device alone, so a phone and a desktop are two true statements
      and nothing may merge them. What did not follow is that the *strip* is where they belong.
      The strip answers *what is there to carry on with*, which is a question about books — three
      appliances in the middle of one novel are one novel — and spending a band with room for
      twenty books on three views of one is the question being answered wrong, not carefully.

      So `watchContinueReading` is one row per work now, and the collapsing is in SQL where the
      ordering already was: `limit` counts books, and grouping by the work while asking for the
      newest instant leans on SQLite's documented rule that a bare column beside `max` comes from
      the row the maximum came from — the DAO test is what would notice the day that stopped being
      true. Nothing is merged: the row that survives is one some device actually wrote, and the
      card still says whether it was this one. **RN01 moves rather than goes**: `watchPlacesIn`
      existed from phase 7 and was called by nothing, and the book's own screen now lists every
      device's place under *Onde você parou* — which is where somebody asking that question
      already is. The card can still name a place this device will not open at, because `resumeAt`
      opens where *this* machine stopped, and that stays right for the reason it always was

- [x] `feat: let the reader look at the password they typed` — a password typed blind on a phone
      keyboard is the usual reason a reader is told their credentials are wrong when they are not,
      and the sign-in screen offered no way to check one. The control is inside the field, carries
      the tooltip a screen reader also announces, and names *what it does* rather than the state
      the field is in — `signInPasswordShow` and `signInPasswordHide`, in both locales. **It starts
      obscured on every visit and is never remembered**: the reason to reveal a password is to
      check a character that was just typed, and a screen that came back already showing one would
      put it on a display the reader has not looked at yet. It is disabled while a sign-in is in
      flight, like the field it sits in

- [x] `fix: read a selection's range and passage the way the glue sends them` — a highlight taken
      on Linux appeared in the annotations list as `epubcfi(/6/8!/4/80,/1:0,/1:108)`, in the yellow
      of a highlight, above the book's name. The card was showing exactly what was stored: the
      Linux host read the glue's `selection` arguments in the wrong order, so the CFI was saved as
      the passage and the passage as the CFI. `epubView.js` sends
      `callHandler('selection', cfiRange, text, rect, xpath)` at every one of its call sites, and
      `_onSelection` read `args[0]` as the words.

      **It could only ever have been this target.** The five webview hosts receive the same two
      values already named — `selection.selectionCfi` and `selection.selectedText` off the
      package's own model — while the Linux host reads a bridge message, which is a list with
      nothing named on it. Both values are strings, so nothing in Dart was ever going to notice;
      the compiler had no opinion and neither did the port's own type. So the reading moved out of
      the method into `epubSelectionOf`, which a test can reach without CEF, and the order is now
      pinned twice: once against that function and once against the pinned glue itself, in
      `locator_round_trip_test.dart`, beside the other claims about the one asymmetry this split
      introduced.

      The marks already written this way are wrong on the device that wrote them and wrong
      everywhere they replicated to — their locator is a sentence, so they open the book at the
      beginning, which is what an unresolvable CFI has always done. Repairing them is a separate
      question and is in *Open questions* below.

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

- ~~**A webview on Linux and Windows.**~~ Spiked before phase 9, as this entry asked, and both
  halves of it moved. **Windows never needed CEF**: `flutter_inappwebview` supports it and
  `flutter_epub_viewer` selects its native path on `dart.library.io` rather than on a platform
  list, so Windows runs the same host as Android, iOS and macOS with nothing written for it.
  **Linux holds**: `flutter build linux --debug` against `webview_cef` 0.6.2 and Flutter 3.47.1
  succeeds, and the fallback of shipping the target without a reader is not needed. What it costs
  is recorded in phase 9 — a 658 MB build-time download, a 244 MB stripped `libcef.so` in the
  bundle, and a small idempotent patch to the Linux runner that is committed rather than applied
  behind the build's back.
- **`flutter_inappwebview`'s stable release does not build for Android, and Atril is on a
  pre-release.** This was the entry that said the package's age was a thing to check rather than
  a risk to accept, and checking it found the risk. 6.1.5 — the stable release, October 2024 —
  fails `flutter build apk` against the Android Gradle plugin this Flutter ships:
  `flutter_inappwebview_android` 1.1.3 names `getDefaultProguardFile('proguard-android.txt')`,
  which AGP refuses because it carries `-dontoptimize`. It fails while Gradle is still evaluating
  that package's own build file, so nothing in this repository can patch around it.
  `6.2.0-beta.3`, February 2026, fixes exactly that line, and the pubspec asks for it by exact
  version because pub will not select a pre-release to satisfy somebody else's caret. The
  alternatives were five targets, a downgraded toolchain, or the one thing architecture.md
  forbids. It stays here rather than moving to *settled* because a pre-release under the reader
  on five of six targets is a thing to keep watching: drop the pin when a stable 6.2.0 exists.
  *Watch.*
- **The marks Linux wrote with their range and passage swapped are still swapped.** The bug is
  fixed and the records are not: a highlight taken on Linux before that commit holds a sentence in
  `annotations.locator` and a CFI in its text, on this device and on every device it reached. They
  are visible, they are removable, and they open the book at the beginning like any mark whose CFI
  no longer resolves — so nothing is broken, and nothing repairs itself either. A repair is
  identifiable with certainty (a text that begins `epubcfi(` beside a locator that does not) and is
  still a decision: it is a write authored locally and replicated, over records the reader made, on
  a heuristic. Decide whether it is worth doing before the marks are old enough to be worth
  keeping. *Ask.*

### Watching upstream

- **C21 is still open.** `internal/` has no outbox: a change made through the node's API writes
  the table and appends nothing to `sync.operations`. It is the reason Atril writes locally and
  pushes, the reason the twelve write RPCs are forbidden, and the reason phase 6 seeds a new
  device through the read calls. The day it closes, all three are revisited deliberately — the
  rule becomes a preference and the seeding step becomes unnecessary.
- **Flutter's service worker is deprecated and already gutted.** `flutter/flutter#156910`. In
  3.47.1 the generated `flutter_service_worker.js` is thirty-one lines that unregister the worker
  and reload every client; `--pwa-strategy=none` writes an empty file instead. Atril ships its
  own worker and deletes Flutter's, so the *removal* of the feature costs this project nothing —
  but the flag may go with it, and `make build-web` passes it. The day `--pwa-strategy` stops
  being accepted, drop it from the Makefile and from `tool/make_service_worker.dart`'s tombstone
  cleanup. *Watch.*
- **`--no-web-resources-cdn` ships every renderer, not the one in use.** 36.1 MB of a 45.4 MB
  build, including `skwasm`, `skwasm_heavy`, `wimp` and `webparagraph` — which a JavaScript build
  never loads — and 8.2 MB of `.symbols` files, which are symbol maps for the profiler. Four
  fifths of the offline shell is renderers and one of them runs. The flag is not the problem and
  must not be dropped: the default fetches CanvasKit from gstatic, which is a cold load with
  nothing to render with. What is worth watching is whether the tool grows a way to copy only the
  selected renderer, because pruning the directory by hand means guessing which variants the
  engine can ask for at run time, and guessing wrong is a blank page on somebody else's browser.
  *Watch.*
- ~~**C22 is still open.**~~ Settled in Quire on 2026-09-02: the origin admits the reader at the
  node it authorized, from the delivery pass and through a peer-facing `AdmitReplica` this client
  never calls. The note phase 12 put beside the grants stays, because the destination still
  records the admission only for an origin its own catalogue names, but its wording changed from
  *the other node cannot be told* to *it is told at delivery and listens only if someone there
  has added your server*. The phase 12 entry above describes the screen as it was written;
  [`architecture.md`](architecture.md) has the settled reading.

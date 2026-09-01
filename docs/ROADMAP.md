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
      dialling a node nobody has chosen, and the session/auth-client cycle is closed by resolving
      the refresher on first use rather than by a `late final`
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

### Watching upstream

- **C21 is still open.** `internal/` has no outbox: a change made through the node's API writes
  the table and appends nothing to `sync.operations`. It is the reason Atril writes locally and
  pushes, the reason the twelve write RPCs are forbidden, and the reason phase 6 seeds a new
  device through the read calls. The day it closes, all three are revisited deliberately — the
  rule becomes a preference and the seeding step becomes unnecessary.
- **C22 is still open.** Nothing in the contract can tell a node that it is a replica, so the
  authorization screen of phase 12 grants a permission it cannot act on. What the screen says
  about that is a wording question, not a technical one, and it should be answered by whoever
  writes the defence rather than by the app.

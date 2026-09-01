# Architecture

Atril follows the [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide):
MVVM, a strict UI/data split, one repository per feature, and a `Result` at every boundary that
can fail. This document is the working copy of that layout — what each layer holds, and the
places this project departs from the guide on purpose.

Read it before starting a phase. The separation is part of the architecture: a view that reaches
a service directly, or a view model that holds a generated protobuf message, is wrong even though
it compiles.

## Why the client cannot be thin

[`quire/internal/client`](../../quire/internal/client) is a device and keeps no copy of the
reader's collection — phase 10 of that roadmap says holding one "would be a second
implementation of the reconciler in this repository." That is the right call for a program that
prints what the node just said. It is not available to a reader who opens the app on a train.

Two findings in the backend decide the shape of this one.

**C21 — a change made through the API produces no operation.** `UpdateEbook` writes
`library.ebooks` and appends nothing to `sync.operations`, so the reader's other devices never
hear about it and neither does any authorized replica. The same change made offline and pushed
later reaches all of them. The correction records the fix as an outbox in the node and marks it
*open*, and says what makes that tolerable: "the client the specification describes writes to its
own SQLite first and pushes — the online path is the convenience, not the mechanism."

Atril is that client, so this is not a preference:

> **Every write to a replicable record is authored as an operation in the local database and
> reaches the node through `SyncService`. Atril never calls `CreateEbook`, `UpdateEbook`,
> `DeleteEbook`, `CreateCollection`, `UpdateCollection`, `DeleteCollection`,
> `AddEbookToCollection`, `RemoveEbookFromCollection`, `CreateAnnotation`, `UpdateAnnotation`,
> `DeleteAnnotation` or `UpdateReadingProgress`.**

Those twelve — eight on `LibraryService`, four on `ReadingService` — stay in the generated stubs
because the contract has them. Nothing in `lib/` calls them, and
`test/architecture/write_path_test.dart` asserts it by walking the tree, so the day C21 closes
the decision is revisited deliberately rather than discovered. The same test checks the twelve
names against the vendored `.proto` files: a pinned list that the contract has renamed out from
under it is a check that matches nothing and passes forever.

The read calls (`ListEbooks`, `ListCollections`, `ListAnnotations`, `ListReadingProgress`) are
used exactly once per record: to seed a freshly bound device before its first pull. After that
the local replica is the truth and the log is how it changes.

The seed writes what the node said. A work, a grouping and a mark carry their `Revision` on the
wire and a position its `Version`, so those four reconcile from the seeded row exactly as if they
had been pulled. The filing of a work under a grouping carries none — there is no
`ListEbookCollections` and no `EbookCollection` message, and the membership is visible only
through the filters on the two list calls — so it is seeded with no causal history at all, and
the first operation about it supersedes the row. It is there so that a reader's shelves are not
empty on a new device, and it yields to the first thing the log says about it.

**Holding a replica means owning a reconciler.** Applying a pulled operation to the local
database is the same computation `internal/shared/crdt` performs on the node: compare vector
clocks, and where they are concurrent, break the tie on `(updated_at, device_id)` per field. A
Dart port is unavoidable, and it is the part of this project most worth testing hard — the same
property tests, and a convergence suite that replays a shuffled operation log and asserts the
same final state.

## The layout

```
lib/
├── main.dart                     production entry point
├── main_development.dart         entry point pointed at `make dev-up`
├── config/
│   ├── dependencies.dart         the provider graph — one function, over one Environment
│   ├── environment.dart          the node address, the CA, the log level — one struct
│   └── window.dart               the desktop window's floor and the size it was left at
├── routing/                      go_router, the routes, and the session guard
├── domain/
│   ├── models/                   ebook · collection · annotation · progress · device · user · server
│   │                             operation · record key — what a change is and how it is addressed
│   ├── crdt/                     vector clock · hybrid timestamp · revision · the merge rules
│   └── use_cases/                only where a behaviour spans two repositories
├── data/
│   ├── repositories/<feature>/   the interface, and the implementation over local + remote
│   ├── services/
│   │   ├── api/                  one client per gRPC service, over the generated stubs
│   │   ├── channel/              the platform channel: native gRPC, or gRPC-Web
│   │   ├── discovery/            the `.well-known` lookup — the one call that is not gRPC
│   │   ├── epub/                 the OPF, read for the metadata an import claims
│   │   ├── files/                the file a reader named: the picker port, and what a name says
│   │   ├── local/                the drift database, its tables and its DAOs
│   │   ├── sync/                 the reconciler, the operation author, the sync loop
│   │   └── storage/              the session store, the e-book blob store, the window's size
│   └── model/                    the mappers between the wire and the domain
├── ui/
│   ├── core/{themes,localization,ui}
│   └── <feature>/{view_model,widgets}
└── utils/                        Result, Command, the logger

tool/check_hardcoded_strings.dart  the no-hardcoded-strings rule, since Dart has no lint for it
```

Four rules carry most of the weight.

**A view model never sees a generated message.** `lib/data/model/` maps `quire.v1.Ebook` to
`domain.Ebook` and back. The generated code is an implementation detail of one service client,
and a `Timestamp` or an `Int64` reaching a widget is that detail escaping. The one deliberate
exception is `VectorClock`, whose domain type is a hand-written `Map<String, int>` wrapper and
whose conversion lives in `domain/crdt` rather than in `data/model`, because the merge rule is
domain behaviour and not a mapping.

**A repository owns one feature and answers from the local database.** `LibraryRepository`
reads drift and returns a stream; it does not know whether the network is up. The sync loop is
what moves rows, and a view that shows a spinner while a book saves has been written against the
wrong layer.

**Every fallible call returns `Result<T>`.** The guide's sealed `Result.ok` / `Result.error`,
never a thrown exception across a layer boundary. gRPC's `GrpcError` is mapped once, in
`data/services/api`, onto the same vocabulary `internal/shared/errs` uses — the node already
answers `AlreadyExists` for a duplicate identifier and carries the fields that failed validation,
and throwing that away at the edge is throwing away the only thing that turns a rejected
registration into something a form can point at.

**A view model exposes `Command` objects, not methods.** The guide's `Command0`/`Command1`, which
carry `running`, `error` and `completed` so a button does not have to.

## Where Atril departs from the guide, and why

### `domain/crdt` is a layer the guide has no name for

The guide's `domain/` holds models and use cases. The vector clock, the hybrid timestamp and the
revision tie-break are none of those: they are pure values with behaviour, depended on by the
models, the reconciler and the operation author alike, and they are the one part of this app that
has a formal specification elsewhere. They get a package, no Flutter import, and property tests.

### The reconciler is a service, not a use case

Applying an operation is not something a view triggers, so it has no view model above it and does
not fit the guide's `use_cases/`. It lives in `data/services/sync/`, beside the loop that feeds
it, and it is one of *two* writers to the replicated tables. The other is the seed of a freshly
bound device, and it is the only one that runs once per device: `data/services/sync/seed.dart`
reads the four list calls into the replica before the first pull, and after it the reconciler is
the only writer there is.

The operation author is deliberately not a third. `data/services/sync/author.dart` decides the
version a change is stamped at, names the record the way every replica will resolve it, and
records what this device now owes — and then hands the operation to the reconciler like any
other. An author that wrote the row itself would be a second implementation of the merge, in
this repository, tested half as hard; the first divergence between the two would be a change
that looks applied on this device and reconciles differently on every other. So there are three
*authors* of a write and two writers, and the difference is the point.

### The EPUB engine is one file; only its host varies

The reader is epub.js on all six targets, bundled as an asset, behind an `EpubHost` port with
three implementations — a native webview, an `<iframe>`, and a CEF texture. This is a platform
split for the same reason the channel below is one, and it has a constraint the channel does
not: the `locator` a device writes is replicated to the reader's other devices, so a CFI
authored under one host has to resolve under another. Two CFI implementations would agree
almost always and disagree as annotations landing on the wrong paragraph after a sync, so there
is one engine and the split is only in what gives it a DOM.

### Four things are chosen by conditional export

`ClientChannel` over HTTP/2 does not exist in a browser and `GrpcWebClientChannel` does not exist
outside one. `data/services/channel/channel.dart` is a conditional export over `channel_io.dart`
and `channel_web.dart`, both exposing one factory.

The same shape is used twice more: `data/services/local/connection/`
opens a file on the five native targets and a WebAssembly build of sqlite over the
origin-private file system in a browser, and `data/services/storage/` holds the e-book bytes on
a filesystem or in that same origin-private store. All three are cases where the losing branch
*cannot be compiled at all* — a `dart:io` import does not parse for the web target and a
`package:web` one does not parse for the others — so an interface chosen at run time would not
help: both implementations would still have to compile.

There is a fourth, and it is of a different kind: `data/services/api/grpc_status.dart` exports
`GrpcError` and `StatusCode` from `package:grpc/grpc.dart` or from `package:grpc/grpc_web.dart`.
The two types are one class each in one file, and the package publishes them only through those
two libraries — one of which drags in `dart:io` and the other `dart:js_interop`. So the split has
nothing of this project's own on either side of it: it is the same constraint met inside a
dependency, and it is named here so that a future reader counts four and not a rule that was
broken.

Everything else that merely behaves differently per platform (the secure store, the storage
budget's units, the reader's host) differs behind an interface with two implementations, because
a `dart:io` import inside a repository is a repository that cannot be tested on web. The session
store is the one that has already landed, and it turned out to need a single implementation:
`flutter_secure_storage` is itself the platform split, and what the web target lacks is not a
store but secrecy — `SecureSessionStore.isSecure` is what says so, and the settings screen is
where it is said to the reader.

### There is no `main_staging.dart`

The guide's sample has three flavours. This app has two nodes it ever points at: a production one
and the local federation `make dev-up` starts. A third entry point would be a third
configuration nobody maintains.

## The shell

Three decisions from the shell are worth writing down, because each one is a place the obvious
answer is not the one this app took.

**The node this app talks to is one object, not a compile-time constant.** `NodeConnection`
holds the endpoint, opens a channel on the first call and closes it when the reader points
somewhere else; `providersFor` resolves the launch endpoint from the origin server in the local
catalogue, which is why the database is opened at the composition root. It is a supplier rather
than a `ClientChannel` that forwards, because `package:grpc` publishes `ClientCall` and
`ConnectionState` only through `grpc.dart` — the library that also drags in `dart:io` — so an
implementation of that interface could not name its own signatures on all six targets. The five
API clients therefore build their stub per call, which costs an object and is what lets the node
under them change.

**The provider graph is one function, not one per flavour.** The roadmap asked for a `providers`
function per environment, and building it showed the split belongs one layer up: what differs
between a shipped build and one pointed at `make dev-up` is entirely an `Environment`, so the
flavours are `Environment.production` and `Environment.development` and the graph is
`providersFor(environment)`. A second graph function would be a second thing to keep in step for
no second behaviour, and a graph that branched on the flavour would be a second app nobody runs.

The cycle between the session and the client that refreshes it is closed by resolving the
refresher on its first use rather than at construction. A device that has never been bound still
reaches onboarding without opening a channel to a node nobody has chosen, but that is no longer a
property of a lazy provider: `NodeConnection` dials on the first call, and there is no call until
the reader has chosen.

**No hardcoded strings is enforced by a program, because Dart ships no lint for it.** A grep
cannot tell `Text('Biblioteca')` from `Key('library')`, does not see a message wrapped across two
lines, and flags every asset path. `tool/check_hardcoded_strings.dart` parses `lib/ui` and
`lib/routing` and looks at where each literal *lands* — the first argument of a widget whose first
argument is text, or a named argument the framework renders — with `// l10n-ignore` as the escape
hatch. It is `make l10n-check`, `make analyze` depends on it, and it has its own test: a visitor
that stopped matching would report nothing, and nothing is what a clean tree looks like.

The ARB directory holds three files and not two. `flutter gen-l10n` refuses a locale carrying a
country code unless the bare language exists as its fallback, so `app_pt.arb` is there and is
empty: this app has one Portuguese, and what a generic file would hold is the Brazilian text an
untranslated message already falls back to.

**Not everything local belongs in the replica.** The drift database holds the records that
replicate, the log this device owes and the causal state that makes the next change correct. The
desktop window's size is none of those — it replicates to nobody, it means nothing on another
device, and it has to be read before `runApp`, which is before the database is opened — so it
lives in `shared_preferences` behind a `WindowStore`. The window's *position* is deliberately not
remembered at all: a window restored to coordinates that were on a second monitor is a window the
reader cannot find.

## Talking to a node

The node now translates for a browser itself. Quire's `deploy/k8s/istio` carries an
`EnvoyFilter` inserting `envoy.filters.http.grpc_web` into the gateway's chain on the terminated
port, a `corsPolicy` on the `/quire.v1.` route that allows any origin and exposes `grpc-status`,
`grpc-message` and `grpc-status-details-bin`, and a `ServiceEntry` declaring the API endpoint
HTTP/2. D10 in `tcc-corrections.md` is the reasoning; `test/e2e/grpcweb_kind_test.go` is the
proof. Nothing in `internal/` changed and the contract was not forked: it is the same methods in
a framing a browser can send.

| Surface | Native (Android, iOS, Linux, macOS, Windows) | Web |
|---|---|---|
| Unary + server streams | `ClientChannel`, HTTP/2, TLS, port 9090 | `GrpcWebClientChannel` through the gateway |
| Live updates | `Sync`, bidirectional | `WatchOperations`, a server stream |
| Content upload | `UploadEbookContent`, or the chunked calls | the chunked calls only |
| Discovery | `.well-known/quire/client` over HTTP | the same, and readable cross-origin — with two constraints below |
| Custom CA | `ChannelCredentials.secure(certificates:)` | not possible — the browser's trust store decides |

**gRPC-Web carries a unary call and a server stream and neither of the other two.** That removes
two RPCs from a browser, and the node grew a replacement for each rather than leaving the web
target degraded:

- `Sync` is bidirectional and unreachable. `WatchOperations` is the server stream that answers
  it, and it is a *notification and not a delivery*: it carries `last_position` and never an
  operation, so the caller learns this node's log has grown past what it has seen and answers
  with `PullOperations` like anybody else. There is no ack to match `SyncAck`, because the node
  holds nothing in flight for that caller.
- `UploadEbookContent` is a client stream and unreachable. `BeginEbookUpload` / `PutEbookChunk`
  / `FinishEbookUpload` / `DiscardEbookUpload` are the unary shape, and D11 keeps every property
  the stream had: the size is declared to `Begin` and refused there before a byte moves, and the
  node hashes what it receives and checks it against the digest declared. A chunk arriving at
  the wrong offset is not written and the reply carries the offset expected.

**Atril uses the chunked upload on all six targets, and never `UploadEbookContent`.** D11 notes
the property that decides it: an upload addressed by an offset is resumable and a client stream
is not — one that dies at nine tenths starts again from nothing. That is worth more on the
mobile network RNF01 and RNF07 are written about than one code path is worth avoiding, and it
means every platform exercises the path the browser has no alternative to.

`grpc_authority` from `ServerDescriptor` is what a native build dials. A web build dials the
gateway, which is a separate address the environment names, because the descriptor publishes the
authority a *peer* dials for replication and a browser is not a peer. Against `make dev-up` that
address is `http://127.0.0.1:18090` for the first node and `:28090` for the second — plain HTTP,
because a loopback origin is a secure context and the development certificates are self-signed.

### Three things the transport requires of this client

Each was found by checking a claim in the Quire repository rather than by reading it, and each
is a line of Atril's code rather than a note.

**The discovery lookup reads `quire/client`, not `quire/server`.** They are two documents and
the difference is who is asking: a peer reads `quire/server` and learns the key to pin for
mTLS; a reader's application reads `quire/client` and learns `base_url` and `grpc`. Atril is
the second — and that is *all* it learns. `internal/shared/wellknown/wellknown.go` puts
`jwks_uri` and `cert_fingerprint` in the server document alone, so a `ServerDescriptor` read
by this app carries three of its five fields absent. It is not a lookup that half-failed:
those two are values a peer checks a peer against, and this device is neither.

**The discovery lookup must stay a *simple* request.** The node answers both documents with
`Access-Control-Allow-Origin: *`, so they are readable cross-origin with no help from the
gateway — but the gateway's authorization policy admits `GET` on `/.well-known/*` and not
`OPTIONS`. A lookup carrying any header a browser would preflight is refused `403`, which reads
as an authorization failure and is really a request shape. So the fetch sends no custom header:
no `Accept`, no `X-Requested-With`, nothing. The constraint is recorded in
`deploy/k8s/istio/authorizationpolicy.yaml` at the rule that makes it.

**A watch stream may deliver no response headers for a long time.** gRPC sends none until the
handler sends its first message, and `WatchOperations` sends nothing while the head has not
moved past the caller's cursor. A browser opening a watch on a quiet log therefore has a fetch
that has not resolved — indistinguishable, in any client API, from a stream that is open and
idle. Atril must not treat "no headers yet" as a failed connection and reconnect on a timer;
the stream is fine and there is simply nothing to say. Asking from a position known to be
behind is what makes it resolve at once, and asking from zero on the first connection does
exactly that.

### Two things that only bite on the web

`DateTime.now().microsecondsSinceEpoch` has millisecond resolution in a browser, because it is a
JavaScript `Date`. The hybrid clock still holds: `t = max(wall, observed + 1µs)` is monotone
whatever the wall clock's granularity, and the step is what guarantees a causally later write
carries a later instant. The clock is never rendered to a reader, so the coarseness is invisible.

`int64` fields arrive as `fixnum.Int64`, not as `int`, and must stay that way until the mapper.
Microsecond epochs are around 1.7 × 10¹⁵ and survive a JavaScript double; a sync `position`
does too. Neither is a reason to relax the rule.

## What the node will not tell us

Recorded here because each one shapes a screen rather than a line of code.

- **C21**, above: the online write path replicates to nobody. Atril writes locally and pushes.
- **C18**: `ebook_collection` and `reading_progress` are identified across the federation by
  their natural key — `(ebook_id, collection_id)` and `(ebook_id, device_id)` — carried in the
  delta. The surrogate id is a local handle. Atril mints its own and remembers it, exactly as
  `client.Record` does, or it mints another on every write.
- **C05**: a reading position has exactly one writer, so its versions can never be concurrent. It
  carries a clock and a timestamp and neither tie-break field. A device never writes another
  device's position.
- **C17**: reconciliation is per *record*, not per field — there is one revision per row, so
  there is nowhere to record that the title came from one write and the author from another.
  Two concurrent writes claiming *different* fields of one record therefore settle differently
  depending on the order they arrive in, and Atril reproduces that deliberately: a client that
  resolved it another way would disagree with the node, which is worse than the case C17
  describes. `reconciler_convergence_test.dart` pins the boundary as behaviour, so that a
  change to it is a failing test rather than a discovery.
- **A node's own identifier is not something a new device can know.** The client discovery
  document publishes `base_url` and `grpc`; the id in `federation.servers` is reported only by
  `ListKnownServers`, which cannot be called before the device has signed in at the node it is
  trying to reach. So the local catalogue is keyed by the **domain** — what the reader typed,
  what the lookup was addressed to, what every federated identifier carries, and what
  `LoginResponse.User.origin_server_domain` answers with. The node's own id is a nullable
  `remote_id` that addresses nothing.
- **C22**: a node cannot be told through the API that it is a replica. The replica-authorization
  screen can grant the permission and cannot complete the federation; the roadmap says so where
  it lands.
- **D10**: the browser is a client the specification never described, and 4.2.4 has to record
  that its transport is gRPC-Web translated by the gateway, not by the node.
- **D11**: UC02 is served by two shapes that differ in how the bytes arrive and in nothing else.
  The chunked one makes the node stateful between calls, which is the second reason its
  deployment runs a single replica.
- **The device id survives logout.** A device that forgets it starts a second vector-clock entry
  that never merges with the first. It lives in the local database, not in the session store, and
  logging out clears the session and nothing else.

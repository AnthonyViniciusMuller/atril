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
`test/architecture/write_path_test.dart` asserts it, so the day C21 closes the decision is
revisited deliberately rather than discovered. The same test checks the twelve names against the
vendored `.proto` files: a pinned list that the contract has renamed out from under it is a check
that matches nothing and passes forever.

It walks the files that could be *making* a call — the ones under `data/services/api` and the
ones that import a client, the generated stubs or `package:grpc` — and not the whole tree. Phase
7 walked everything on the argument that a wrapper named `updateEbook` is a call by another name,
and phase 8 is where that stopped holding: the reader's vocabulary for UC01 and UC03 is the
contract's own, because they name the same operations, so `LibraryRepository.deleteEbook` spells
`DeleteEbook` and authors an operation. The narrowing is pinned too — every `*_api.dart` under
`data/services/api` is asserted to count as a client — so a sixth client is covered by this
project's naming rather than by somebody remembering the test.

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
│   │   ├── annotations/          what the reader marked, as a file they can take away
│   │   ├── api/                  one client per gRPC service, over the generated stubs
│   │   ├── channel/              the platform channel: native gRPC, or gRPC-Web
│   │   ├── content/              the chunked upload and the download of a work's bytes
│   │   ├── discovery/            the `.well-known` lookup — the one call that is not gRPC
│   │   ├── epub/                 the OPF, read for the metadata an import claims
│   │   ├── files/                the file a reader named and the file they save: two ports
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
wrong layer. Two repositories do not obey the second half of that sentence, and the section on
[the federation and the account](#the-federation-and-the-account) is where the exception is
argued: what they hold does not replicate, so there is no local truth for them to answer from.

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

The reader is epub.js on all six targets, behind an `EpubHost` port with two implementations —
`flutter_epub_viewer` on five, and a CEF texture on Linux. This is a platform split for the same
reason the channel below is one, and it has a constraint the channel does not: the `locator` a
device writes is replicated to the reader's other devices, so a CFI authored under one host has
to resolve under another. Two CFI implementations would agree almost always and disagree as
annotations landing on the wrong paragraph after a sync, so there is one engine and the split is
only in what gives it a DOM.

**The engine is pinned, not vendored.** `flutter_epub_viewer` ships epub.js, JSZip and the page
and glue that drive them as its own assets, published under
`packages/flutter_epub_viewer/lib/assets/webpage/…`, and every host loads *those* keys — the
webview hosts by handing the page to the platform's webview, the Linux host by serving the same
directory over a loopback socket. Committing a second copy for the desktop, which is what the
roadmap first asked for, would have put two engines in one application and left one target
running the file the other five do not.

What the bundling was for is a renderer that cannot change under a locator already written down
and replicated, and a version string cannot promise that. So the pubspec constrains the package
to an exact version and `data/services/epub/engine.dart` records the sha-256 of every asset the
host page reaches, with a test that hashes what the bundle actually holds. The digests cover the
closure rather than `epub.js` alone: `epubView.js` is what asks the renderer where the page
starts and hands the answer back across the bridge, so a change there moves the locator exactly
as a change to the renderer would.

There are three hosts in the earlier drafts of this section and there are two. `flutter_epub_viewer`
splits internally on `dart.library.io` — a webview on the four native targets it reaches, and a
same-origin `<iframe>` driven through `dart:js_interop` in a browser — so a second class over it
would have the same body. Windows is among the four and not on CEF, because
`flutter_inappwebview` supports it and the package selects on the library rather than on a
platform list; that leaves `webview_cef` carrying Linux alone, which is the one target whose
operating system ships no webview a Flutter plugin can embed.

Two facts about that target belong here rather than in a build file. Its `libcef.so` is 244 MB
stripped, and a stripped Linux bundle is 486 MB against a few megabytes elsewhere — the size an
Electron application ships, and the price of the sixth target having a reader at all.

That sentence used to end at *stripped*, and phase 13 is where the missing half turned up: it was
a claim about a step nobody was taking. `flutter build linux --release` copies `libcef.so`
exactly as CEF published it, which is **1311 MB**, in a bundle of **1553 MB**. The 244 MB was
always the stripped size of a file that shipped unstripped. Phase 13 put the strip in the Flatpak
manifest, which made the Flatpak the only release path that stripped it: `make build-linux`, the CI
job and a laptop's `flutter build linux --release` went on shipping the 1.5 GB. Phase 14 moved it
into the install step of `linux/CMakeLists.txt`, after the rule that copies the plugin's libraries,
so every non-debug bundle is 486 MB whether or not anything wraps it. And the
plugin's CMake step patches `linux/runner/main.cc` and `my_application.cc`: a CEF process
bootstrap runs before `g_application_run`, so on Linux `main` branches before the Flutter
application is constructed. The patch is idempotent and is committed, which makes it a diff
somebody reviewed instead of a mutation of tracked files that happens during a build.

### Five things are chosen by conditional export

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

The fifth is the reader's host. `data/services/epub/host/host_factory.dart` exports a native
branch or a browser one, and it meets the same rule for the same reason: the Linux host serves
the pinned engine over an `HttpServer`, which is `dart:io`, and a `dart:io` import does not parse
for the web target. It is the first of the five whose two sides are both this project's own code.

The split *inside* that native branch is a different kind and is deliberately not a conditional
export. Linux and the four other native targets can both be compiled, so which of the two hosts
to build is a question about the machine rather than about the language, and it is answered with
`defaultTargetPlatform` where the graph is composed — the same way `config/platform.dart` answers
what this device calls itself.

There is another, and it is of a different kind again: `data/services/api/grpc_status.dart`
exports `GrpcError` and `StatusCode` from `package:grpc/grpc.dart` or from
`package:grpc/grpc_web.dart`.
The two types are one class each in one file, and the package publishes them only through those
two libraries — one of which drags in `dart:io` and the other `dart:js_interop`. So the split has
nothing of this project's own on either side of it: it is the same constraint met inside a
dependency, and it is named here so that a future reader counts five and not a rule that was
broken.

A second one of that kind arrived with the export, and it is worth naming because it is the first
platform split in this project that is not about a *technology* being absent. `FileSaver` has two
implementations — `file_selector`'s save dialog on the three desktops and the browser, and the
share sheet through `share_plus` on Android and iOS — and it is chosen on `defaultTargetPlatform`
where the graph is composed. `file_selector` does not implement `getSaveLocation` on those two
targets, and that is not a gap in the package: those systems have no save dialog, and saving a
file there *is* the share sheet, which is where **Save to Files** and **Save to Drive** live. The
alternative was an export on four targets of six, or writing into the application's own documents
directory and telling the reader where it went — which is not *the reader chooses where their
data goes*, and that is the claim the export exists to make good on.

A third split of that kind arrived with synchronization, and it is the one where the *technology*
really is absent — it just is not absent from the language. `SyncChannel` has two
implementations: `Sync`, the bidirectional stream, on the five native targets, and
`WatchOperations` with a unary push and pull beside it in a browser. gRPC-Web carries a unary call
and a server stream and neither of the other two, so the browser cannot hold the stream open — but
both classes *compile* everywhere, because what a browser lacks is a framing and not a type. So
the choice is `devicePlatform` where the graph is composed, like the host and the file saver, and
not a sixth conditional export. Nothing above `data/services/sync` knows which one it got.

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

## What a mark is, and what it cannot be

### One text field carries two different things

An annotation in the contract has one nullable `text`, and UC05 needs it to do two jobs. A
**highlight** spends it on the passage it covers, captured from the selection that made it: the
engine had the words at that moment and no other layer ever will — the annotations screen lists
marks from books that are not open, and an export runs with no engine at all — so a highlight that
stored nothing could only ever be shown as a CFI. A **note** spends it on the reader's own words,
which the contract requires a note to carry. A **bookmark** spends it on nothing.

The consequence is that giving a highlight words makes it a note *and* takes the passage away,
because the two cannot both be in one field. That is not hidden: the dialog that offers it opens
with the passage already in the field, so what is stored is what the reader was looking at when
they pressed save.

### Nothing in Dart ever compares two CFIs

The rule about one engine has a second half that only became visible when the marks needed
ordering. A list of highlights in *reading order* is what a reader expects, and reaching it means
comparing two CFIs, which means parsing them — a partial CFI implementation in Dart, which is the
thing this project forbids outright. So the marks come back most recent first, everywhere, which
is an integer comparison that means the same thing on every target.

The same rule decides how the reader's screen knows whether the page it is on carries a bookmark:
by comparing the locator as *text*. What that costs is small and is stated where it is made — a
bookmark taken at one type size is not recognized as *this page* at another, so the control offers
to make a new one, and the old mark is still in the list and still navigates to the right passage.

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

## Synchronizing

Three services do the work and one loop decides when. `push.dart` drains the outbox,
`pull.dart` fills the replica, and the reconciler is what applies anything either of them
touches; `stream.dart` and `watch.dart` are the two live channels behind `SyncChannel`, and
`scheduler.dart` is the loop above them. Four decisions in that stack are worth having written
down, because each is a place the obvious answer is wrong.

**The acknowledgement goes after the commit.** `SyncAck` is what advances the *node's* idea of
where a device has got to, and the node keeps at most one page in flight until it arrives. So the
order in the stream is reconcile, move the cursor, then acknowledge. A client that acknowledged on
receipt would come back from a crash to a page it had never written, and nothing on either side
would report it. The unary pull has the same shape without the message: the cursor is written
after the batch, and re-reading a page costs a decode because `applied_operations` recognizes
every operation by the identifier its author minted.

**Reachability is a hint and never a gate.** `NodeReachability` concludes that a node answers only
from a call that answered. A loop that refused to connect while it believed otherwise could
therefore never learn it was wrong — nothing would call, so nothing would conclude — and the only
way out would be a network interface physically disappearing and coming back. Every device whose
network simply stayed up while the node was down for a minute would be stuck for ever. So an
unreachable node is what the bounded backoff is *for*, and reachability contributes the one thing
it can honestly contribute: a retry hint that clears the wait. The roadmap asked for the stream
*while the app is in the foreground and reachable*, and the second half of that is corrected in
`scheduler.dart` rather than implemented.

**The backoff is reset by a channel that lasted, not by one that opened.** gRPC dials lazily, so a
stream that failed before the node ever answered and one that opened and was closed a moment later
are the same two events in the same order. How long it stayed up is the only evidence this layer
has, and the heuristic is named as one where it is made.

**Foreground only, on all six.** The decision table in the roadmap always said so; the scheduler
is where it is honoured. A background policy is `WorkManager`, `BGTaskScheduler`, a service worker
and nothing at all on the three desktops — four mechanisms, a phase of its own, and not a line in
this one. What RNF09's periodic reconstruction asks for is met on launch, on resume, and while the
app is open.

**Nothing announces a write to the loop.** A change authored anywhere lands in
`pending_operations`, and the scheduler watches that table grow. It is `ApiClient`'s argument
about reachability one layer up: a caller that had to remember to announce a write would be a
caller that eventually did not, and the one that gets forgotten is always the one added last.

### A refusal is quarantined, and that is the local-first path's own failure

A node refusing an operation is the one outcome of a push that reaches a reader, and it exists
*because* this app writes locally and pushes: the reader watched the change land, it is in the
replica, and it will reach nobody. `refused_operations` is the response — a side table keyed by
the operation, carrying the node's own reason.

It is deliberately not a rollback. The write may have others built on top of it, and destroying
those to satisfy a refusal is the one outcome worse than the refusal. It is deliberately not
silence either, which would leave this device disagreeing with every replica and saying so to
nobody. A correct client should rarely produce one, so it is a flag, a list and a discard rather
than a merge interface — and the discard's confirmation carries the sentence the whole design
rests on: it undoes nothing the reader wrote.

Two mechanical consequences. A quarantined change **stops being offered**, which is what lets the
drain go on: the head of the outbox moves without retiring, so one refusal no longer stops every
change behind it from ever being pushed. And it is a **side table rather than a column**, which
keeps this schema's upgrade `createAll` — every version of it still only adds — and keeps the
outbox as dumb as its own comment asks for.

### `node_cursors.pulled_at` answers a reader's question, not the cursor's

It moves when the cursor does *and* whenever this device has evidence its node answered. A device
that is up to date exchanges no operations, so a timestamp that only moved on a pull would tell a
reader their last synchronization was whenever somebody last happened to write something. What the
sync surface shows is *when this device last reached its node*, and that is the fact the column
holds.

Evidence is the word that matters, and it is why this is not written when a channel opens. `open()`
does not reach the node — gRPC dials lazily, and the stream's own open only reads the cursor out of
the database — so a device whose node had been down for a week would say *just now*. The three
things that are evidence are an event received on the channel, a push the node answered for, and a
channel that stayed up as long as `settledFor`. The first two belong to the channels, because they
are what receives them; the third is the scheduler's, because it is the only one this layer can see
for itself.

## The federation and the account

Phase 12 adds two repositories that break the rule every other one keeps, and the break is the
point rather than an exception.

**`FederationRepository` and `AccountRepository` do not answer from the local replica.** Every
other repository holds records that *replicate*, so the truth is here and the node hears about it
later — that is C21 read forwards. A catalogue entry, a replica permission, a device row and an
account are none of those. They are what the node knows and enforces, they change on the reader's
other devices, and there is nothing a reader can do about any of them while the node cannot be
reached. A cached list would therefore be a peer that may already be gone, shown under controls
that would all fail — so each of those screens reads on open, says plainly when the node did not
answer, and offers to ask again.

The catalogue is still **mirrored** into `known_servers` as each answer arrives, and that is a
different job from showing it. The local row is what a launch dials, and `ListKnownServers` is the
only call that reports a node's own identifier — which is what a replica grant is addressed by,
and the reason that column has been a nullable `remote_id` since the table was written. The two
writers of that table keep opposite rules and both are right: a `.well-known` document carries
three of a descriptor's five fields and must not clear what it was never going to mention, while
the node's own answer carries all five and overwrites, absences included.

**Three lists are asked for in full where the contract hides half of them.** The deactivated
nodes, the revoked replica permissions and the unbound devices are all `include_inactive` on the
wire and all shown here, and each for the same shape of reason: the row is the only thing that
explains a state the reader can otherwise not account for. A catalogue that hid a deactivated node
would have no way back from its own switch; a sovereignty screen that hid a revoked permission
would answer *nobody* to a reader asking who holds their library; and a device list that hid an
unbound device would make the history that names it unreadable.

### A device cannot unbind itself, and this app is what refuses it

`RevokeDevice` naming the calling device is a request the node cannot tell apart from any other,
and it would carry it out — ending this session and every future one, on the device holding the
screen, with nothing left on it to undo the act. So the refusal is in `AccountRepository`, and the
row offers no control rather than an error the reader had to provoke.

### Migration: what travels, and what is deliberately not cleared

UC16 is the phase's centre and three of its decisions are places the obvious answer is wrong.

**The devices travel with their identifiers, and the identifiers survive a node that does not
answer.** C11 is why they have to travel at all. The names, though, are only the node being *left*
can give, and asking it would make UC16 depend on the availability that UC16 exists to remove — so
the wizard asks once, when it opens, and falls back to the device identifiers the replica's own
vector clocks name. A device carried under an invented name is a device the reader renames
afterwards; a device carried under a new identifier is a clock entry that never merges.

**This device goes first in the list, and the vendored contract does not say so.** C20: the
session comes back for the first device, `MigrateHomeServerRequest.devices` carries no field naming
the caller, and `tcc-corrections.md` records the sentence as still to be added to that comment. The
repository is what guarantees the order and deduplicates, and it says so where it does it.

**Nothing is cleared on the way through.** The outbox, the causal state and the replica are what
the devices then push to the new node; a client that emptied them would have completed the
migration by discarding what was being migrated. The one thing that *is* dropped is the cursor for
the new node, because a position is a number in that node's log and the log it is about to write
for this reader is empty.

The device is pointed at the new node at the **last step and not before**. Discovering the domain
early would validate it and would also leave the app talking to a node the reader has no account
on while they fill in a form, so committing and connecting are one act — and a migration that
fails points the device back, since a device holding a session for one node while dialling another
fails every call for a reason nothing on screen explains.

## Shipping it

Phase 13 is the first one whose work is mostly outside `lib/`, and four of its findings are
architecture rather than build configuration: each one is a place where something this project
already decided stops being true at a platform boundary.

### The application icon is a program, not artwork

Six targets want one mark at twenty-nine sizes, in three container formats, and two of them
disagree about the alpha channel — an Android adaptive foreground *is* one, and App Store Connect
rejects a marketing icon that carries one. A directory of exported PNGs answers that with
twenty-nine files nobody can regenerate once the file the designer worked in is gone.

So `tool/make_icons.dart` holds the geometry, a rasterizer, a PNG encoder and an ICO encoder, and
`make icons` rewrites every file. The output is committed, because a build must not depend on a
generator having been run, and CI regenerates and diffs it exactly as it does the contract, the
drift code and the localizations. That diff is only meaningful because `FLUTTER_VERSION` is
pinned and the deflate writing those files is the SDK's — the same argument the pinned `protoc`
makes about `.pbjson.dart` descriptors.

One detail generalizes. The spine down the lectern's desk is a **hole**, wound against the shape
that contains it, and not a second colour. That is what lets one description serve a mark drawn
on ink and a mark drawn on nothing: the five targets that get a background show the ink through
it, and the Android foreground layer shows transparency.

### Atril owns a service worker, because Flutter no longer does

`flutter_service_worker.js` is deprecated — `flutter/flutter#156910` — and in Flutter 3.47.1 the
file the tool generates is thirty-one lines that call `registration.unregister()` and reload every
client. It is a tombstone. So the target whose whole promise is that the network is an
optimization had nothing caching its own application, and the *default* `flutter_bootstrap.js` is
worse than nothing: it registers that file, at the same scope Atril's worker wants, so the
tombstone would remove Atril's along with itself.

`web/atril_service_worker.js` is this project's own, and `web/flutter_bootstrap.js` is written out
so that the loader is called with no `serviceWorkerSettings`. Four of the worker's decisions are
places the obvious answer is wrong, and all four follow from decisions this document already
records.

**It caches the shell and never a book.** The books are the per-book opt-in of phase 8, held in
the origin-private file system against a budget the reader can see. A worker that quietly cached
them as they streamed would be the one thing that decision forbids — storage spent without being
shown.

**It calls neither `skipWaiting` nor `clients.claim`**, and the cost is stated where it is paid:
the *first* visit to the app is not offline-capable, and every load after it is. The alternative
is a worker taking over a page already running and serving it the JavaScript of one build with the
assets of another for the rest of the session.

**Every non-`GET` and every cross-origin request goes past untouched.** That is not defensive.
A node is normally a different origin, so the origin check alone excludes every gRPC-Web call and
the `.well-known` lookup — but a build *served from its own node's origin* is legal, and a cached
`POST` response there would be one device replaying another's answer to a synchronization request.

**The cache version is a digest over the sorted file list and each file's own digest**, so an
asset that moved and an asset that changed both produce a new cache. A build number would produce
neither. `tool/make_service_worker.dart` computes it, and rewrites exactly two lines of a worker
that is otherwise reviewed as source.

The renderer stays CanvasKit, and the measurement is worth recording because it contradicts the
guess. `--wasm` does not replace the JavaScript build; it adds a WasmGC one and keeps the other as
the fallback, which is 49.5 MB against 45.4 MB — nine percent, not a doubling. What is worth
knowing is the other number: `--no-web-resources-cdn` copies the whole renderer directory out of
the web SDK, **36.1 MB of the 45.4**, including variants a JavaScript build never loads and 8.2 MB
of `.symbols` files. The flag is still right — the default fetches CanvasKit from gstatic, which is
a cold load on a train with nothing to render with — but its cost is not where anybody would look
for it.

The deployed build keeps all of it; the offline shell does not. Phase 14 found the worker
precaching every file the build wrote, and `cache.addAll` is atomic, so one failed fetch among
forty-four megabytes left the shell not cached at all. `tool/make_service_worker.dart` now holds a
whitelist for `canvaskit/` — the two pairs the loader can choose between at run time, `canvaskit.*`
and `chromium/canvaskit.*`, the choice being the browser's and not the build's — and excludes the
`.symbols` files everywhere. **39 files and 20.5 MB, against 53 and 44.4.** It is a whitelist and
not a blacklist because the failure modes differ: a variant the engine grows and the list does not
name is fetched from the network, which is the app online rather than a cache that never installed.
The build is not pruned and the worker passes any request outside the shell straight through, so a
wrong guess here is one file not offline, never a blank page.

### The locale is declared three times, and the ARB is none of them

`pt_BR` is this app's default locale and `en` is its second, and until phase 13 that was true
everywhere except at the boundary where it is read from outside. **A Flutter app declares no
localizations to the platform.** The ARB files are compiled into Dart; the operating system never
sees them, and the template leaves the development region as an Xcode variable that resolves to
`en`.

So the language is declared once for the framework, in `l10n.yaml` and the ARB directory, and
three more times for the systems that ask: `CFBundleLocalizations` and `CFBundleDevelopmentRegion`
in each of the two Apple `Info.plist` files, and `languages` in the `msix_config`. It is not
cosmetic on any of them. `share_plus` documents those two keys as the fix for a share sheet that
appears in the wrong language — and the share sheet is how the export of phase 10 leaves iOS and
Android.

### What each platform's sandbox has to be told

Three of the six run this application inside a sandbox, and each one had to be told something
different before code that already worked kept working.

**macOS: the picker opens and the file cannot be read.** A sandboxed app reaches a path the reader
chose only through the powerbox, and `com.apple.security.files.user-selected.read-write` is the
entitlement that grants it. Without it both ends of UC02 were broken on a release build and on
nothing else — the import could not read the book and the export could not write the file.

**iOS: the keychain needs a group.** `flutter_secure_storage` reaches the keychain through an
access group the app is entitled to, and this target had no entitlements files at all. The store
would have raised at its first write, which is the moment the reader signs in.

**Linux: the sandbox is the package's, because Chromium's is off.** `webview_cef` appends
`--no-sandbox` to CEF's command line and leaves the setuid helper unprivileged, so the engine is
unsandboxed whatever ships it. That is the argument for Flatpak over AppImage rather than a
packaging preference. And the Flatpak grants **no `--filesystem` at all**: `file_selector_linux`
opens a `GtkFileChooserNative`, which GTK routes through the desktop portal inside a sandbox, so
an import and an export each hand the app the one file the reader chose. The claim
`docs/architecture.md` makes about the export — that the reader chooses where their data goes — is
the same claim the sandbox makes, one layer down.

## What the node will not tell us

Recorded here because each one shapes a screen rather than a line of code.

- **C21**, above: the online write path replicates to nobody. Atril writes locally and pushes.
- **C16**: an upload carries a digest and no work, so the node has nothing to check it against
  but one thing — whether the calling reader already holds a work naming that digest. The flow
  the contract describes is `CreateEbook`, read `content_missing`, then upload, and **Atril never
  calls `CreateEbook`**: the work reaches the node when the log is pushed. So the bytes of a
  freshly imported book are refused with `unclaimed_content` until that push has happened, and
  that is a *not yet* rather than a failure — nothing about the file is wrong and the same call
  succeeds afterwards. The record does not wait for the bytes; the bytes wait for the record.
  `data/services/content/content_uploader.dart` states it where the call is made, and the queue
  beside it is what leaves such a transfer waiting instead of giving up on it.
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
- **C22**: settled in Quire on 2026-09-02 (`99fda3f`..`1d94973`), after phase 12 had shipped
  around it. `FederationService` now carries `AdmitReplica` and `WithdrawReplica`, both
  peer-facing and authenticated by the pinned certificate as `ReplicateOperations` is, so this
  client never calls either. The origin admits the reader from its delivery pass, immediately
  before it first offers their changes to a node, and the destination records the admission only
  for an origin its own catalogue already names. What the replica-authorization screen tells the
  reader changed with it: not that the other node cannot be told, but that it is told at
  delivery and listens only if someone with an account there has added the reader's server.
- **D10**: the browser is a client the specification never described, and 4.2.4 has to record
  that its transport is gRPC-Web translated by the gateway, not by the node.
- **The download is not resumable, and there is nothing to make it so with.**
  `DownloadEbookContentRequest` carries an e-book identifier and no offset and no range, so a
  node cannot be asked for the second half of a file — the upload's whole property, read the
  other way, is simply absent. What the stream does give is the description before the bytes, so
  a client knows the digest and the length in advance: `data/services/content` hashes what
  arrives and checks it before committing, since `BlobWrite.commit` names an object rather than
  checking one. Nothing partial is stored, which is what makes starting again all an
  interruption costs.
- **D11**: UC02 is served by two shapes that differ in how the bytes arrive and in nothing else.
  The chunked one makes the node stateful between calls, which is the second reason its
  deployment runs a single replica.
- **The device id survives logout.** A device that forgets it starts a second vector-clock entry
  that never merges with the first. It lives in the local database, not in the session store, and
  logging out clears the session and nothing else.

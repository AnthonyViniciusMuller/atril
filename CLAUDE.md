# Atril

The Flutter client for [Quire](../quire) — a federated, offline-first e-book library. Six
targets: Android, iOS, web, Linux, macOS, Windows.

The work is planned commit by commit in [`docs/ROADMAP.md`](docs/ROADMAP.md). The layout and the
reasoning behind it are in [`docs/architecture.md`](docs/architecture.md). **Read both before
writing code.** Each phase is normally worked in its own session, so the plan is how one session
knows what the last one decided.

## How to start a session

1. `git log --oneline` and the ticked boxes in `docs/ROADMAP.md` say where the work stopped.
2. Read the phase you are about to start, in full, and `docs/architecture.md`.
3. If the phase depends on something the backend does, check it against `../quire` rather than
   assuming — several entries in the roadmap exist because an assumption turned out wrong.

## Commits

- **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)**, in English, as
  Quire's own history does. The scope is omitted unless it disambiguates.
- **One commit per checkbox**, and tick the box in that same commit. A future session resumes by
  reading this file and `git log`, so an untick is a commit that did not happen.
- **Never add a `Co-Authored-By` or `Claude-Session` trailer.** No exceptions, whatever the
  default is.
- Small, and reviewed before landing. The body says *why*, not *what* — the diff already says
  what.

## Ask when it matters

Ask before choosing, not after building. A question costs a minute; a phase built on the wrong
assumption costs the phase. Ask when two readings of the task produce materially different work,
when a dependency has to be picked, when something the plan asserts turns out to be false, or
when a decision would be expensive to reverse. Routine judgement calls do not need asking —
make them and say so.

If something in the roadmap is wrong, say so and fix the roadmap in the same breath. It is a
working document, not a contract.

## Rules a session could plausibly break

These are the ones where the obvious thing is the wrong thing. All are argued in
`docs/architecture.md`.

- **Never call the node's write RPCs.** Not `CreateEbook`, `UpdateEbook`, `DeleteEbook`, the
  collection or membership calls, the annotation calls, or `UpdateReadingProgress`. Every change
  to a replicable record is authored locally and pushed through `SyncService`. C21 in
  `../quire/docs/tcc-corrections.md` is why: a change made through the API replicates to nobody.
  A test in phase 7 enforces this.
- **One EPUB engine, several hosts.** epub.js is bundled once and every platform runs the same
  file. Never write a second CFI implementation, in Dart or otherwise — locators are replicated
  between a reader's devices, and two implementations disagree as annotations landing on the
  wrong paragraph.
- **The device id survives logout.** It lives in the local database, not the session store. A
  device that forgets it starts a vector-clock entry that never merges with the first.
- **Discovery reads `/.well-known/quire/client`**, not `.../server`, and sends **no custom
  header** — the gateway admits `GET` and not `OPTIONS`, so anything that provokes a preflight
  is refused 403.
- **No hardcoded user-visible strings.** ARB from the first screen; `pt_BR` is the default
  locale and `en` the second.
- **`Result<T>` at every layer boundary**, never a thrown exception across one. View models
  expose `Command` objects, not methods. No generated protobuf type above `data/model`.
- **Six targets.** A commit that builds on five is not done.

## The backend

A sibling checkout at `../quire`. `make dev-up` there brings up two federated nodes:

| | Node A | Node B |
|---|---|---|
| gRPC (native) | `127.0.0.1:19090` | `127.0.0.1:29090` |
| gRPC-Web (browser) | `127.0.0.1:18090` | `127.0.0.1:28090` |
| Discovery documents | `127.0.0.1:18080` | `127.0.0.1:28080` |

The gRPC-Web lane is plain HTTP on the loopback address, which browsers treat as a secure
context; the native lane is TLS against a self-signed certificate in
`../quire/deploy/docker/certs`.

Do not change anything in `../quire` without being asked. If the client needs something the
contract does not offer, say so rather than working around it — two of the roadmap's decisions
came from the backend growing an RPC for exactly that reason.

## Commands

```bash
flutter analyze && flutter test
flutter run -d chrome    # needs ../quire `make dev-up` for the gRPC-Web lane
flutter run -d linux
```

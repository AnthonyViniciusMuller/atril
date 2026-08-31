# Atril

Flutter client for [Quire](../quire) — mobile, web and desktop.

An *atril* is the lectern a book rests on while it is being read. Quire gathers the folded
sheets; Atril is what holds them open in front of the reader, on whichever device is at hand.

## Status

Not started. The project is the stock `flutter create` scaffold — Android, iOS, web, Linux,
macOS and Windows targets, nothing built on top of them yet.

## What it will do

- **Read offline.** The library, reading positions and annotations live on the device; the
  network is an optimization, not a requirement.
- **Sync through a node.** Speaks the gRPC surface of `quired` — `AuthService`,
  `LibraryService`, `ReadingService`, `SyncService` — and reconciles with the same CRDT rules
  the backend uses: vector clocks for causality, per-field LWW registers for concurrent writes.
- **Follow the reader.** A user is `@local_name:server`; changing home servers keeps the
  library, the annotations and the page they were on.

## Getting started

```bash
flutter pub get
flutter run -d linux     # or chrome, or an attached device
```

The client needs a node to talk to. From the Quire checkout next door:

```bash
cd ../quire && make dev-up
```

That brings up two federated nodes on `127.0.0.1:19090` and `127.0.0.1:29090` with
self-signed certificates in `deploy/docker/certs/`.

## License

[MIT](LICENSE).

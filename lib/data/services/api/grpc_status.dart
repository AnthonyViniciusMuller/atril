/// `GrpcError` and `StatusCode`, from whichever entry point this target can
/// import.
///
/// The two types are one class each, in one file inside `package:grpc`, and
/// the package publishes them through two libraries: `grpc.dart`, which also
/// exports the HTTP/2 channel and therefore `dart:io`, and `grpc_web.dart`,
/// which also exports the browser channel and therefore `dart:js_interop`.
/// Neither library parses on the other's targets, and code that maps a failure
/// has to run on all six.
///
/// So this is a conditional export of two package URIs rather than of two
/// files of ours. It is the same shape as the three splits
/// [`architecture.md`](../../../../docs/architecture.md) records and the same
/// reason — the losing branch cannot be compiled — with nothing of this
/// project's own on either side of it.
library;

export 'package:grpc/grpc.dart'
    if (dart.library.js_interop) 'package:grpc/grpc_web.dart'
    show GrpcError, StatusCode;

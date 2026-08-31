/// The channel a node is dialled over, which is the one thing about talking to
/// it that differs per platform.
///
/// This is the third conditional export in the app, and it is the one
/// [`architecture.md`](../../../../docs/architecture.md) names first: a
/// `ClientChannel` over HTTP/2 does not exist in a browser and a
/// `GrpcWebClientChannel` does not exist outside one, so the losing branch
/// could not be compiled either way. Everything that merely *behaves*
/// differently per platform stays behind an interface with two
/// implementations; this is one of the three places where the losing branch
/// does not parse.
///
/// Both files expose one function, [openChannel], and nothing above this
/// directory knows which of them answered. What differs behind it is exactly
/// what the table in `architecture.md` says: the native lane speaks gRPC over
/// HTTP/2 and can be told which certificate authority to trust; the web lane
/// speaks gRPC-Web to the gateway that translates it, and its trust store is
/// the browser's.
library;

export 'channel_io.dart' if (dart.library.js_interop) 'channel_web.dart';
export 'endpoint.dart';
export 'node_connection.dart';

/// The bearer token, on every call that needs one.
///
/// It is a `ClientInterceptor` and not a wrapper around each stub, because the
/// generated clients take a list of them and there is exactly one rule to
/// apply: a call to an authenticated method carries the access token this
/// device holds, and a call to a public one carries nothing.
///
/// The credential is attached through a metadata provider rather than as
/// static metadata, and that is what makes it correct rather than convenient:
/// a provider runs when the call is about to be sent and may be asynchronous,
/// so a token that had gone stale between the client being built and the call
/// being made is refreshed before the request leaves rather than refused after
/// it arrives.
///
/// What this file cannot do is the other half of the session, and the reason
/// is worth recording. `interceptUnary` must return a `ResponseFuture`, which
/// can only be built around a `ClientCall`, so an interceptor cannot answer
/// with the result of a *second* call — a retry after a refresh has to live
/// where the call itself is made. It does, in [SessionHolder.retrying], and
/// the clients in this directory are what wrap the two together.
library;

import 'package:grpc/service_api.dart';

import 'session.dart';

/// The metadata key a bearer token travels under, and the scheme that precedes
/// it. Both are the names every gRPC library already uses, and the ones
/// `identity/infra/grpc/authn` reads on the other side.
const String authorizationHeader = 'authorization';

/// The scheme, spelled as the node spells it back.
const String bearerScheme = 'Bearer';

/// The methods that are answered to a caller with no session.
///
/// It is `authn.PublicMethods()` on the node, minus the one call this client
/// is never the caller of. Keeping the two lists equal matters in one
/// direction only: a method missing here is a method whose call would ask for
/// a token, and for the four that *obtain* a session that is either pointless
/// or a loop — `RefreshSession` in particular would refresh in order to
/// refresh.
///
/// `SyncService.ReplicateOperations` is deliberately absent. It is public on
/// the node because its caller is a peer node proving itself with a
/// certificate rather than a token, and a reader's device is never its caller.
///
/// `FederationService.DiscoverServer` is deliberately *not* here, because it
/// is not public: discovery through a node is a call like any other, and a
/// device that has no node to ask yet reads the `.well-known` document
/// directly instead.
const Set<String> publicMethods = <String>{
  '/quire.v1.AuthService/RegisterUser',
  '/quire.v1.AuthService/Login',
  '/quire.v1.AuthService/Logout',
  '/quire.v1.AuthService/RefreshSession',
  '/quire.v1.AuthService/RequestPasswordRecovery',
  '/quire.v1.AuthService/ResetPassword',
  '/quire.v1.FederationService/MigrateHomeServer',
};

/// Attaches this device's session to the calls that need one.
final class SessionInterceptor extends ClientInterceptor {
  /// The interceptor over the session [holder] holds.
  SessionInterceptor(this._holder);

  final SessionHolder _holder;

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) => invoker(method, request, _authorized(method, options));

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) => invoker(method, requests, _authorized(method, options));

  /// [options] with the credential provider added, where [method] needs one.
  ///
  /// The provider is merged into the options rather than replacing them, and
  /// in this direction rather than the other, because a browser's options are
  /// a `WebCallOptions` carrying two fields a plain merge would drop.
  CallOptions _authorized<Q, R>(
    ClientMethod<Q, R> method,
    CallOptions options,
  ) {
    if (publicMethods.contains(method.path)) {
      return options;
    }

    return options.mergedWith(
      CallOptions(providers: <MetadataProvider>[attach]),
    );
  }

  /// Writes the credential into [metadata], if this device holds one.
  ///
  /// It is public because it is the whole of what this class does, and the
  /// plumbing above it is two lines that no test can reach without a socket.
  ///
  /// A device that is signed out adds nothing rather than raising: the node
  /// answers `UNAUTHENTICATED` with a code that says which of the two happened,
  /// and a client that refused to send the call would be deciding on the
  /// node's behalf that it would have been refused.
  Future<void> attach(Map<String, String> metadata, String uri) async {
    final token = await _holder.accessToken();

    if (token != null) {
      metadata[authorizationHeader] = '$bearerScheme $token';
    }
  }
}

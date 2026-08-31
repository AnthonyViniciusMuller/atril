/// What every client in this directory shares: where a call's failure is
/// classified, and where a refused credential is retried.
///
/// The clients are thin on purpose. Each is one gRPC service, each method is
/// one RPC, and the only thing any of them does besides calling the stub is
/// map — the request from domain values, the reply back into them. Anything
/// that decides *when* to call belongs above: a repository reads the local
/// replica and the sync loop moves rows, and neither of them is here.
///
/// **Failures are thrown, not returned.** That is the same shape the blob
/// store and the DAOs have, and the `Result` boundary is the repository above
/// them: within `data/services` a failure travels as the [AppException] every
/// layer already speaks, and the repository is what turns it into a value a
/// view model can pattern-match. What matters at this layer is that the
/// classification happens exactly once, in [failureFrom], with the node's own
/// code and field violations kept.
library;

import 'package:grpc/service_api.dart' show ClientChannel, ClientInterceptor;

import 'errors.dart';
import 'session.dart';
import 'session_interceptor.dart';

/// The base of the five clients.
abstract base class ApiClient {
  /// A client dialling [channel] and authorized by [session].
  ApiClient({required this.channel, required this.session});

  /// The channel this node is reached over. Which lane it is — HTTP/2 or
  /// gRPC-Web — was decided by the conditional export in
  /// `data/services/channel`, and nothing here can tell.
  final ClientChannel channel;

  /// The session every call is made under.
  final SessionHolder session;

  /// What a stub is built with, so that the credential is attached to every
  /// call of every client and not to the ones somebody remembered.
  late final List<ClientInterceptor> interceptors = <ClientInterceptor>[
    SessionInterceptor(session),
  ];

  /// Runs one unary call, named [op] for the log.
  ///
  /// The two things wrapped here are the two that would otherwise be repeated
  /// in every method of every client: one retry after the node refuses the
  /// credential, and one translation of whatever was raised.
  ///
  /// A public method is passed through this as well, and costs nothing for it:
  /// nothing refuses it for a credential, so the retry never fires.
  Future<T> call<T>(String op, Future<T> Function() invoke) async {
    try {
      return await session.retrying(invoke);
    } on Exception catch (error) {
      throw failureFrom(error, op: op);
    }
  }

  /// Wraps a server stream, named [op] for the log.
  ///
  /// It classifies and does not retry, and the difference from [call] is not
  /// an oversight. A stream that fails has already delivered part of an
  /// answer, and what to do about that — reopen from the cursor, back off,
  /// give up — is a decision the sync loop makes with state this layer does
  /// not have.
  Stream<T> listen<T>(String op, Stream<T> responses) =>
      responses.handleError((Object error) => throw failureFrom(error, op: op));
}

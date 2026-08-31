/// What every client in this directory shares: where a call's failure is
/// classified, and where a refused credential is retried.
///
/// The clients are thin on purpose. Each is one gRPC service, each method is
/// one RPC, and the only thing any of them does besides calling the stub is
/// map — the request from domain values, the reply back into them. Anything
/// that decides *when* to call belongs above: a repository reads the local
/// replica and the sync loop moves rows, and neither of them is here.
///
/// **A stub is built per call.** The generated clients hold a channel, a set of
/// options and nothing else — their methods are `static final` — so building one
/// costs an object, and it is what lets the node a client talks to change under
/// it. A `late final` stub would be a stub bound to whichever node this app was
/// pointed at when the client was first read.
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

import '../channel/node_connection.dart';
import 'errors.dart';
import 'reachability.dart';
import 'session.dart';
import 'session_interceptor.dart';

/// The base of the five clients.
abstract base class ApiClient {
  /// A client dialling over [connection], authorized by [session], and
  /// reporting what it learns to [reachability].
  ApiClient({
    required this.connection,
    required this.session,
    this.reachability,
  });

  /// The node this device is talking to.
  ///
  /// It is the connection and not a channel because the node a client dials
  /// changes: the reader picks one during onboarding, and a launch points the
  /// app at the one the local catalogue records. A channel captured here at
  /// construction would be the node this app was pointed at when the graph was
  /// built, which on a fresh install is no node at all.
  final NodeConnection connection;

  /// The channel this node is reached over, as of now. Which lane it is —
  /// HTTP/2 or gRPC-Web — was decided by the conditional export in
  /// `data/services/channel`, and nothing here can tell.
  ClientChannel get channel => connection.channel;

  /// The session every call is made under.
  final SessionHolder session;

  /// What is told whether the node answered, where anything is listening.
  ///
  /// It is wired here rather than in each client because this is the one place
  /// every call passes through: a client that had to remember to report would
  /// be a client that eventually did not. It is nullable so that a test can
  /// build a client without one; the composition root passes the single
  /// instance every client shares.
  final NodeReachability? reachability;

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
      final answer = await session.retrying(invoke);

      reachability?.recordAnswer();

      return answer;
    } on Exception catch (error) {
      final failure = failureFrom(error, op: op);

      // A refusal is an answer: the node received the request and decided, so
      // it is evidence that the node is there. Only the two failures that mean
      // nothing arrived say otherwise, and NodeReachability is what knows
      // which two those are.
      reachability?.recordFailure(failure);

      throw failure;
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
      responses.handleError((Object error) {
        final failure = failureFrom(error, op: op);

        reachability?.recordFailure(failure);

        throw failure;
      });
}

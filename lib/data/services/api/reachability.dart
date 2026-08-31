/// Whether a node can be reached, as a stream.
///
/// The question looks like one the platform answers and is not. A connectivity
/// plugin reports the *radio*: whether this device has an interface that is
/// up. A device on a hotel wifi behind a captive portal reports `wifi` and
/// reaches nothing; a phone that has just handed over between two towers
/// reports a network it cannot yet route on. What a synchronizing client needs
/// to know is whether *this node* answered, and only a call to it can say.
///
/// So the signal is the call. Every answer is evidence that the node is there
/// — including a refusal, because a `NOT_FOUND` is a node that received the
/// request and decided — and the two failures that mean nothing arrived are
/// what mark it unreachable. `ApiClient` reports both, so every call in the
/// app is evidence without any of them having to remember to be.
///
/// The radio is still worth listening to, in the two ways it is honest:
///
/// **No interface at all is proof.** A device with no network will not reach a
/// node, and there is no point in spending a call to discover it.
///
/// **An interface appearing is a hint.** It does not prove a route, but it is
/// the moment a retry stopped being pointless — which is exactly what a device
/// that has been offline in a tunnel needs, and what it would otherwise
/// discover only at the next scheduled attempt.
///
/// The state starts optimistic, and that is deliberate: a device that has made
/// no call yet has no evidence, and refusing to try would be a conclusion
/// drawn from nothing.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../utils/errors.dart';
import '../../../utils/logging.dart';

final _log = loggerFor('data/api');

/// Whether the node this app is dialling can be reached.
final class NodeReachability {
  /// The state fed by calls, and hinted at by [radio] where one is given.
  ///
  /// [radio] carries `true` while this device has some network interface up.
  /// It is a plain `Stream<bool>` rather than the plugin's own type so that
  /// nothing below this file depends on the plugin, and so that a test can
  /// hand it a controller.
  NodeReachability({Stream<bool>? radio}) {
    _radio = radio?.listen(_onRadio);
  }

  /// The state over the platform's own connectivity reporting.
  factory NodeReachability.overPlatformRadio() =>
      NodeReachability(radio: platformRadio());

  /// Whether this device has any network interface up.
  ///
  /// The plugin answers with every interface it finds, and `none` is the only
  /// answer this app draws a conclusion from.
  static Stream<bool> platformRadio() =>
      Connectivity().onConnectivityChanged.map(
        (List<ConnectivityResult> interfaces) => interfaces.any(
          (ConnectivityResult interface) =>
              interface != ConnectivityResult.none,
        ),
      );

  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  final StreamController<void> _hints = StreamController<void>.broadcast();

  StreamSubscription<bool>? _radio;
  bool _reachable = true;

  /// The current conclusion.
  bool get isReachable => _reachable;

  /// The conclusion, now and whenever it changes.
  ///
  /// Each listener is given the current value first, so that a caller
  /// subscribing after the fact has something to show rather than a blank
  /// until the state next changes. It is built with [Stream.multi] rather than
  /// by yielding ahead of a broadcast stream, because the obvious
  /// `async*` version subscribes one microtask late and loses whatever was
  /// concluded in between.
  Stream<bool> get changes =>
      Stream<bool>.multi((MultiStreamController<bool> listener) {
        listener.add(_reachable);

        final subscription = _changes.stream.listen(
          listener.add,
          onDone: listener.close,
        );

        listener.onCancel = subscription.cancel;
      });

  /// The moments when a retry has become worth making.
  ///
  /// It fires when an interface appears while the node is believed
  /// unreachable, and never otherwise: it is a prompt to try, not a claim that
  /// trying will work.
  Stream<void> get retryHints => _hints.stream;

  /// Records that the node answered.
  void recordAnswer() => _conclude(true);

  /// Records what a call failed with.
  ///
  /// A failure the node itself produced is evidence that the node is there,
  /// and only the two that mean nothing arrived — the dependency being
  /// unreachable, and the deadline passing with no reply — mark it otherwise.
  void recordFailure(Object failure) => _conclude(
    !const <ErrorKind>{
      ErrorKind.unavailable,
      ErrorKind.deadlineExceeded,
    }.contains(AppException.kindOf(failure)),
  );

  /// Stops listening to the radio and closes both streams.
  Future<void> dispose() async {
    await _radio?.cancel();
    await _changes.close();
    await _hints.close();
  }

  void _onRadio(bool present) {
    if (!present) {
      // The one direction the radio is proof in.
      _conclude(false);

      return;
    }

    if (!_reachable) {
      _log.fine('an interface appeared; a retry is worth making');
      _hints.add(null);
    }
  }

  void _conclude(bool reachable) {
    if (reachable == _reachable || _changes.isClosed) {
      return;
    }

    _reachable = reachable;
    _log.info(
      reachable ? 'the node is answering' : 'the node is not answering',
    );
    _changes.add(reachable);
  }
}

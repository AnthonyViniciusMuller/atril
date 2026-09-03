/// Turning a stream that can fail into one that reports it.
///
/// Every fallible call in this app answers with a [Result] and never throws
/// across a layer boundary, and a stream is where that is easiest to lose: an
/// exception raised inside one is delivered as an error event, which either
/// throws into whatever is listening or ends the stream — and a list that
/// stopped arriving looks exactly like an empty one.
///
/// Three repositories had written the same guard three times, one of them
/// spelled differently. This is that guard, once.
library;

import 'dart:async';

import '../data/services/api/errors.dart';
import 'logging.dart';
import 'result.dart';

final _log = loggerFor('utils/streams');

/// Wrapping the values of a stream, and its failures with them.
extension ResultStream<T> on Stream<T> {
  /// This stream with every value wrapped and every failure reported as one,
  /// under [op].
  ///
  /// **The stream is not ended by a failure that reaches here.** What failed is
  /// one query and not the database: a screen told that its list could not be
  /// built should still be showing the next version of it when the reason goes
  /// away. drift's own stream does close after an error, which this cannot
  /// mend and is the reason the failure is reported rather than swallowed.
  Stream<Result<T>> asResults(String op) => transform(
    StreamTransformer<T, Result<T>>.fromHandlers(
      handleData: (T value, EventSink<Result<T>> sink) =>
          sink.add(Result<T>.ok(value)),
      handleError:
          (Object error, StackTrace stackTrace, EventSink<Result<T>> sink) {
            _log.warning('$op could not be read', error, stackTrace);

            sink.add(Result<T>.error(failureFrom(error, op: op)));
          },
    ),
  );
}

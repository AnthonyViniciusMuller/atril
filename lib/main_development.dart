/// The entry point pointed at the local federation `make dev-up` starts.
///
/// It differs from `main.dart` in the environment it builds and in one flag it
/// reads, and in nothing else — no screen, no service and no behaviour is
/// conditional on it.
///
/// **The certificate authority arrives as a flag, base64-encoded.** The local
/// federation answers under certificates that `make dev-certs` *generates*
/// before every `make dev-up`, and Quire does not commit them. A copy vendored
/// into this repository would therefore be stale the next time anybody started
/// the federation, and the failure would be a handshake error rather than a
/// missing file. So the PEM is passed in at build time, from wherever the
/// reader's Quire checkout is — `make run-linux` and `make run-web` do it — and
/// base64 is what keeps a multi-line PEM inside one `--dart-define`.
///
/// It is read *here*, in the entry point, and not in the channel: the rule the
/// roadmap states is that nothing below `main` reads a compile-time constant,
/// and the reason is that a value read where it is used cannot be set by a
/// test. Handing it to [Environment.development] is what keeps it a
/// configuration and not a fact about the platform.
///
/// The web build ignores it, and correctly: a page cannot add to the browser's
/// trust store, and against `make dev-up` it does not need to — the gRPC-Web
/// lane is plain HTTP on a loopback address, which is a secure context.
library;

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/environment.dart';
import 'config/window.dart';
import 'ui/core/ui/atril_app.dart';
import 'utils/logging.dart';

/// The PEM of the local federation's certificate authority, base64-encoded.
///
/// Empty where the build was not given one, which is a development build
/// against a node whose certificate the platform already trusts.
const String developmentCertificateAuthority = String.fromEnvironment(
  'ATRIL_DEV_CA',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final certificateAuthority = developmentCertificateAuthority.isEmpty
      ? null
      : base64.decode(developmentCertificateAuthority);

  final environment = Environment.development(
    certificateAuthority: certificateAuthority,
  );

  installLogging(level: environment.logLevel);
  loggerFor('main').info(
    'starting $environment, '
    '${certificateAuthority == null ? 'trusting the platform store' : 'trusting a pinned authority'}',
  );

  // A no-op on the three targets with no window to configure, so neither
  // entry point has to decide which platform it is.
  await configureDesktopWindow();

  runApp(
    MultiProvider(
      providers: await providersFor(environment),
      child: const AtrilApp(),
    ),
  );
}

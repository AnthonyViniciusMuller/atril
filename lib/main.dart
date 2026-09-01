/// The production entry point.
///
/// It does five things and nothing else: start the binding, decide what this
/// build is pointed at, install the one log sink, credit the code this app
/// vendors, and hand the graph to the app. Everything with an opinion in it
/// lives one directory over, in `config/`, so that the difference between this
/// file and `main_development.dart` is a single call and can be read at a
/// glance.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/environment.dart';
import 'config/window.dart';
import 'data/services/epub/engine.dart';
import 'ui/core/ui/atril_app.dart';
import 'utils/logging.dart';

Future<void> main() async {
  // The blob store asks the platform where its files go before the first
  // frame, so the binding has to exist before the graph is built.
  WidgetsFlutterBinding.ensureInitialized();

  final environment = Environment.production();

  installLogging(level: environment.logLevel);
  loggerFor('main').info('starting $environment');

  // The two libraries this app redistributes inside somebody else's package.
  // Flutter registers a resolved package's own LICENSE and knows nothing about
  // the files vendored into it, so epub.js and JSZip would otherwise ship
  // uncredited. It is lazy — nothing is read unless a reader opens the
  // licences page — which is why it costs nothing to do before the first
  // frame.
  EpubEngine.registerLicenses();

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

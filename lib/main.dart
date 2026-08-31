/// The production entry point.
///
/// It does four things and nothing else: start the binding, decide what this
/// build is pointed at, install the one log sink, and hand the graph to the
/// app. Everything with an opinion in it lives one directory over, in
/// `config/`, so that the difference between this file and
/// `main_development.dart` is a single call and can be read at a glance.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/environment.dart';
import 'ui/core/ui/atril_app.dart';
import 'utils/logging.dart';

Future<void> main() async {
  // The blob store asks the platform where its files go before the first
  // frame, so the binding has to exist before the graph is built.
  WidgetsFlutterBinding.ensureInitialized();

  final environment = Environment.production();

  installLogging(level: environment.logLevel);
  loggerFor('main').info('starting $environment');

  runApp(
    MultiProvider(
      providers: await providersFor(environment),
      child: const AtrilApp(),
    ),
  );
}

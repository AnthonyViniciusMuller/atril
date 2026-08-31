/// The route table and the one question asked before any of it is built.
///
/// Two things live here and nothing else does. The **table** maps the
/// locations in `routes.dart` onto the screens that answer them, with the
/// three shell destinations as branches of one `StatefulShellRoute` so that
/// each keeps its own navigator — a reader who scrolled the library, looked at
/// an annotation and came back should find the library where they left it,
/// which is a property of the branch and not of the screen.
///
/// The **guard** is the redirect. It asks whether this device holds a
/// credential it could still exchange, and it asks it in one place: a screen
/// that checked for itself would be a screen somebody eventually forgets to
/// write the check into, and the one that gets forgotten is always the one
/// added last.
///
/// Two directions, not one. A signed-out device is sent to onboarding, and a
/// signed-in device is sent *away* from it — otherwise the back button after a
/// login lands on the login screen of a session that already exists, which on
/// the web is one gesture away at all times.
///
/// The question is asked without a round trip. [SessionHolder.isSignedIn]
/// answers from the stored credential and its expiry, so a device that has
/// been offline for a month opens its library instead of a spinner, and one
/// whose credential expired while it was away is told so here rather than
/// discovering it at the first sync.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../data/services/api/session.dart';
import '../ui/annotations/widgets/annotations_screen.dart';
import '../ui/core/ui/not_found_screen.dart';
import '../ui/library/widgets/library_screen.dart';
import '../ui/onboarding/widgets/onboarding_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../utils/logging.dart';
import 'routes.dart';

final _log = loggerFor('routing');

/// Builds the shell around the branch [navigationShell] is currently showing.
///
/// It is a parameter so that this file holds the table and the guard and not a
/// navigation surface: the adaptive one lands in `ui/core/ui`, and a test can
/// pass something simpler to exercise a redirect without laying out a rail.
typedef ShellBuilder = Widget Function(
  BuildContext context,
  StatefulNavigationShell navigation,
);

/// The router of the app.
///
/// [session] is what the guard asks. [shellBuilder] wraps the three
/// destinations; where none is given the branch is shown on its own, which is
/// a working app reachable by location and no way to walk between the three.
///
/// [refresh] is what makes the router re-run the guard. It defaults to
/// [SessionHolder.signedIn], and its subscription lives as long as that stream
/// does — closing the holder is what ends it, since `GoRouter` does not
/// dispose the listenable it was given.
GoRouter atrilRouter({
  required SessionHolder session,
  ShellBuilder? shellBuilder,
  Listenable? refresh,
  String initialLocation = Routes.library,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh ?? SignalOf<bool>(session.signedIn),
    redirect: (BuildContext context, GoRouterState state) =>
        _guard(session, state),
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigation,
        ) => shellBuilder?.call(context, navigation) ?? navigation,
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.library,
                builder: (BuildContext context, GoRouterState state) =>
                    const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.annotations,
                builder: (BuildContext context, GoRouterState state) =>
                    const AnnotationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.settings,
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Where [state] should go instead, or `null` to let it through.
Future<String?> _guard(SessionHolder session, GoRouterState state) async {
  final signedIn = await session.isSignedIn;

  // A prefix and not an equality: phase 6 hangs registration, login and
  // password recovery below `/onboarding`, and every one of them is a screen a
  // signed-out device is allowed to be on.
  final onboarding = state.matchedLocation.startsWith(Routes.onboarding);

  if (!signedIn && !onboarding) {
    _log.fine('no session; ${state.matchedLocation} redirects to onboarding');

    return Routes.onboarding;
  }

  if (signedIn && onboarding) {
    _log.fine('a session exists; ${state.matchedLocation} redirects away');

    return Routes.library;
  }

  return null;
}

/// A [Listenable] that fires whenever [stream] emits.
///
/// `GoRouter` re-runs its redirect when the listenable it was given notifies,
/// and what this app has to offer it is a stream. The adapter is here rather
/// than in `data/` because `ChangeNotifier` is a Flutter type and
/// `SessionHolder` deliberately imports nothing that is.
///
/// It does not hold the value, only the fact that there is a new one: the
/// guard reads the session itself, and a listenable that carried an answer
/// would be a second copy of it to keep correct.
final class SignalOf<T> extends ChangeNotifier {
  /// A listenable over [stream].
  SignalOf(Stream<T> stream) {
    _subscription = stream.listen((T _) => notifyListeners());
  }

  late final StreamSubscription<T> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

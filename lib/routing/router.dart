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
import '../ui/core/ui/adaptive_scaffold.dart';
import '../ui/account/widgets/account_screen.dart';
import '../ui/account/widgets/delete_account_screen.dart';
import '../ui/account/widgets/devices_screen.dart';
import '../ui/core/ui/not_found_screen.dart';
import '../ui/federation/widgets/known_servers_screen.dart';
import '../ui/federation/widgets/migration_screen.dart';
import '../ui/federation/widgets/replicas_screen.dart';
import '../ui/library/widgets/ebook_edit_screen.dart';
import '../ui/library/widgets/ebook_screen.dart';
import '../ui/library/widgets/library_screen.dart';
import '../ui/library/widgets/shelves_screen.dart';
import '../ui/onboarding/widgets/password_reset_screen.dart';
import '../ui/onboarding/widgets/recovery_screen.dart';
import '../ui/onboarding/widgets/register_screen.dart';
import '../ui/onboarding/widgets/server_selection_screen.dart';
import '../ui/reader/widgets/reader_screen.dart';
import '../ui/onboarding/widgets/sign_in_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/sync/widgets/sync_screen.dart';
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
/// destinations and defaults to [AdaptiveScaffold]; a test that only cares
/// where a redirect lands passes something simpler rather than laying out a
/// rail it is not looking at.
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
  final _Deflected deflected = _Deflected();

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh ?? SignalOf<bool>(session.signedIn),
    redirect: (BuildContext context, GoRouterState state) =>
        _guard(session, state, deflected),
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const ServerSelectionScreen(),
        // Nested, so that a reader who reaches the sign-in screen has the
        // server selection behind it: the way back from *this is not my node*
        // is the screen that asked, and a browser's back button lands there
        // whether or not this app accounts for it.
        routes: <RouteBase>[
          GoRoute(
            path: Routes.signInSegment,
            builder: (BuildContext context, GoRouterState state) =>
                SignInScreen(
                  identifier:
                      state.uri.queryParameters[Routes.identifierParameter],
                  done: state.uri.queryParameters[Routes.doneParameter],
                ),
          ),
          GoRoute(
            path: Routes.registerSegment,
            builder: (BuildContext context, GoRouterState state) =>
                const RegisterScreen(),
          ),
          GoRoute(
            path: Routes.recoverSegment,
            builder: (BuildContext context, GoRouterState state) =>
                const RecoveryScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: Routes.resetPasswordSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    PasswordResetScreen(
                      token: state.uri.queryParameters[Routes.tokenParameter],
                    ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigation,
            ) =>
                shellBuilder?.call(context, navigation) ??
                AdaptiveScaffold(navigation: navigation),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.library,
                builder: (BuildContext context, GoRouterState state) =>
                    const LibraryScreen(),
                // One work, below the shelf it was opened from. The identifier
                // is in the path and not in an object handed over, which is
                // what makes the location survive a reload in a browser and a
                // link somebody pasted.
                routes: <RouteBase>[
                  // Before the parameter, deliberately: `go_router` matches in
                  // declaration order, and `:ebookId` would otherwise swallow
                  // this and try to show a book called *shelves*.
                  GoRoute(
                    path: Routes.shelvesSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const ShelvesScreen(),
                  ),
                  GoRoute(
                    path: Routes.ebookSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        EbookScreen(
                          ebookId:
                              state.pathParameters[Routes.ebookParameter] ?? '',
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: Routes.ebookEditSegment,
                        builder: (BuildContext context, GoRouterState state) =>
                            EbookEditScreen(
                              ebookId:
                                  state.pathParameters[Routes.ebookParameter] ??
                                  '',
                            ),
                      ),
                      GoRoute(
                        path: Routes.readSegment,
                        builder: (BuildContext context, GoRouterState state) =>
                            ReaderScreen(
                              ebookId:
                                  state.pathParameters[Routes.ebookParameter] ??
                                  '',
                              // Where a mark sends the reader back to. The
                              // book opens at the beginning without it, and at
                              // the beginning too when the locator no longer
                              // resolves — a book edited between two versions
                              // can legitimately have lost the passage.
                              at: state
                                  .uri
                                  .queryParameters[Routes.locatorParameter],
                            ),
                      ),
                      GoRoute(
                        path: Routes.marksSegment,
                        builder: (BuildContext context, GoRouterState state) =>
                            AnnotationsScreen(
                              ebookId:
                                  state.pathParameters[Routes.ebookParameter] ??
                                  '',
                            ),
                      ),
                    ],
                  ),
                ],
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
                // Below the settings, so that closing it lands on the screen
                // that led there — and so that a browser's back button does,
                // which is the same thing said twice on one target.
                routes: <RouteBase>[
                  GoRoute(
                    path: Routes.syncSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const SyncScreen(),
                  ),
                  GoRoute(
                    path: Routes.serversSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const KnownServersScreen(),
                  ),
                  GoRoute(
                    path: Routes.replicasSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReplicasScreen(),
                  ),
                  GoRoute(
                    path: Routes.accountSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const AccountScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: Routes.deleteAccountSegment,
                        builder: (BuildContext context, GoRouterState state) =>
                            const DeleteAccountScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.devicesSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const DevicesScreen(),
                  ),
                  GoRoute(
                    path: Routes.migrateSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const MigrationScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Where a signed-out device was going before it was sent to onboarding.
///
/// **It exists because the location cannot carry it the whole way.** The
/// redirect writes the destination onto `/onboarding` as a query parameter,
/// which is what a browser reload restores and what makes the deflection
/// visible; but a reader then walks from the server selection to the sign-in
/// screen and on to registration, and each of those is a `go` to a bare path
/// that keeps no query. Teaching four onboarding screens to forward a
/// parameter none of them is about would be four screens knowing about the
/// guard. This is the guard remembering its own deflection instead, for as long
/// as the sign-in it caused takes.
final class _Deflected {
  String? destination;
}

/// Where [state] should go instead, or `null` to let it through.
Future<String?> _guard(
  SessionHolder session,
  GoRouterState state,
  _Deflected deflected,
) async {
  final signedIn = await session.isSignedIn;

  // A prefix and not an equality: phase 6 hangs registration, login and
  // password recovery below `/onboarding`, and every one of them is a screen a
  // signed-out device is allowed to be on.
  final onboarding = state.matchedLocation.startsWith(Routes.onboarding);

  if (!signedIn && !onboarding) {
    final destination = state.uri.toString();

    _log.fine('no session; ${state.matchedLocation} redirects to onboarding');
    deflected.destination = destination;

    return Routes.onboardingFrom(destination);
  }

  if (signedIn && onboarding) {
    // The one onboarding screen a signed-in device is entitled to be on. The
    // credential arrives in a mail client, as often as not on another device,
    // and a reader who already has a session on this one is still a reader
    // changing their password — sending them to the library discards the token
    // in the link and leaves them at the screen they came from.
    if (state.matchedLocation == Routes.resetPassword) {
      return null;
    }

    final wanted =
        _localPath(state.uri.queryParameters[Routes.fromParameter]) ??
        _localPath(deflected.destination);

    deflected.destination = null;

    _log.fine('a session exists; ${state.matchedLocation} redirects away');

    return wanted ?? Routes.library;
  }

  return null;
}

/// [destination] if it is a location inside this app, and `null` otherwise.
///
/// The value reaches here from the address bar, so what it is allowed to be is
/// stated rather than assumed: one leading slash and no scheme and no
/// authority. `https://elsewhere.example` would be this app forwarding a reader
/// who has just typed their password to somebody else's site, and `//host/path`
/// is the same thing spelled so that it looks like a path.
///
/// A destination inside onboarding is refused too, for a duller reason: it is
/// the location the guard is redirecting *away* from, and honouring it would be
/// a loop.
String? _localPath(String? destination) {
  if (destination == null ||
      !destination.startsWith('/') ||
      destination.startsWith('//')) {
    return null;
  }

  final Uri? parsed = Uri.tryParse(destination);

  if (parsed == null ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.path.startsWith(Routes.onboarding)) {
    return null;
  }

  return destination;
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

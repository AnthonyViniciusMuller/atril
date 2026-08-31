/// Every location this app has, spelled once.
///
/// They are constants and not strings written at each call site for the reason
/// the ARB exists one directory over: a path is a value two places have to
/// agree on — the route that declares it and the navigation that goes there —
/// and two literals agree until one of them is edited.
///
/// The paths are in English, and that is not an oversight of the localization
/// rule. A URL is not read to a reader the way a label is: it is typed,
/// bookmarked, pasted into a bug report and matched by a redirect, and a
/// translated path would mean the same screen has a different address
/// depending on the language the reader's device is set to — which is a link
/// that breaks when somebody else opens it.
library;

/// The locations of the app.
abstract final class Routes {
  /// Where a device with no session is sent, and the only branch it may see.
  ///
  /// Phase 6 hangs the rest of onboarding below it — choosing a server,
  /// registering, signing in, recovering a password — which is why the guard
  /// tests it as a prefix rather than for equality.
  static const String onboarding = '/onboarding';

  /// Where a reader signs in, and where the onboarding of a device that has
  /// chosen a node continues.
  ///
  /// It is below [onboarding] and not beside it, so that the guard — which
  /// tests the prefix — lets a signed-out device reach the screen it is being
  /// sent to use.
  static const String signIn = '$onboarding/sign-in';

  /// The path segment [signIn] is declared under, which `go_router` wants
  /// relative to its parent.
  static const String signInSegment = 'sign-in';

  /// Where a reader with no account creates one.
  ///
  /// It is reached from [signIn] and returns to it, because `RegisterUser`
  /// answers with the reader and no session: what follows a registration is a
  /// login like anybody else's.
  static const String register = '$onboarding/register';

  /// The path segment [register] is declared under.
  static const String registerSegment = 'register';

  /// The query parameter [signIn] pre-fills its identifier from.
  ///
  /// It is how a registration hands the reader on without the two screens
  /// holding a shared object: a location carries what the next screen needs,
  /// which is also what makes the hand-off survive a reload in a browser.
  static const String identifierParameter = 'identifier';

  /// The reader's collection, and where a signed-in device starts.
  static const String library = '/library';

  /// Everything the reader has marked, across every book.
  static const String annotations = '/annotations';

  /// The account, the devices, the known servers and the state of the sync.
  static const String settings = '/settings';

  /// The destinations that share the shell, in the order the navigation
  /// surface shows them.
  ///
  /// It is a list and not three independent constants because the branches of
  /// the shell, the destinations of the navigation surface and the indices
  /// that tie the two together are one ordering, and three orderings written
  /// separately are three orderings that will disagree.
  static const List<String> shell = <String>[library, annotations, settings];
}

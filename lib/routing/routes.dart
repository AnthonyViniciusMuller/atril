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

  /// Where a reader asks for a recovery credential (UC08, first half).
  static const String recover = '$onboarding/recover';

  /// The path segment [recover] is declared under.
  static const String recoverSegment = 'recover';

  /// Where a reader spends a recovery credential and chooses a new password
  /// (UC08, second half).
  ///
  /// It is a location of its own and not a step inside [recover], because the
  /// code arrives in a mail client — as often as not on another device — and a
  /// reader coming back to this app has to be able to reach the second half
  /// without going through the first again.
  static const String resetPassword = '$recover/reset';

  /// The path segment [resetPassword] is declared under, relative to
  /// [recover].
  static const String resetPasswordSegment = 'reset';

  /// The query parameter [resetPassword] reads a credential from, so that a
  /// link in the mail can carry one.
  static const String tokenParameter = 'token';

  /// The query parameter [signIn] shows a confirmation from.
  ///
  /// A reader who has just reset their password is sent to sign in, and a
  /// screen that said nothing about why would look like one that had lost the
  /// reset.
  static const String doneParameter = 'done';

  /// The value [doneParameter] carries after a password reset.
  static const String passwordWasReset = 'password-reset';

  /// The reader's collection, and where a signed-in device starts.
  static const String library = '/library';

  /// The path segment one work is shown under, relative to [library].
  ///
  /// It is nested rather than a location of its own, so that a reader who
  /// opened a book from the shelf finds the shelf behind it — and a browser's
  /// back button lands there whether or not this app accounts for it.
  static const String ebookSegment = ':ebookId';

  /// The path parameter [ebookSegment] carries the work's identifier in.
  static const String ebookParameter = 'ebookId';

  /// Where one work is shown.
  static String ebook(String id) => '$library/$id';

  /// The path segment the form that edits a work is declared under, relative
  /// to [ebookSegment].
  ///
  /// It is a location and not a dialog, for the reason every other screen here
  /// is one: a reader who was editing a book and switched away comes back to
  /// the form, and a browser's back button leaves the form rather than the
  /// app.
  static const String ebookEditSegment = 'edit';

  /// Where one work is edited.
  static String editEbook(String id) => '${ebook(id)}/$ebookEditSegment';

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

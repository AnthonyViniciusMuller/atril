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

  /// The query parameter the onboarding redirect carries a destination in.
  ///
  /// A device sent to onboarding was going somewhere — a book someone shared,
  /// a screen it was on when its credential expired — and the location is the
  /// only thing that remembers it across a sign-in. It is validated before it
  /// is honoured: it comes from the address bar, and an absolute URL admitted
  /// here would be this app forwarding a reader to somebody else's site.
  static const String fromParameter = 'from';

  /// [location] with [destination] recorded on it, for the guard to honour
  /// once this device has a session.
  static String onboardingFrom(String destination) => Uri(
    path: onboarding,
    queryParameters: <String, String>{fromParameter: destination},
  ).toString();

  /// The reader's collection, and where a signed-in device starts.
  static const String library = '/library';

  /// The path segment the reader's groupings are shown under, relative to
  /// [library].
  ///
  /// It is declared **before** [ebookSegment] in the route table, and that
  /// ordering is the whole of why a literal segment can live beside a
  /// parameter: `go_router` matches routes in the order they are declared, and
  /// `:ebookId` would otherwise swallow this one and try to show a book called
  /// *shelves*.
  static const String shelvesSegment = 'shelves';

  /// Where the reader's groupings are managed.
  static const String shelves = '$library/$shelvesSegment';

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

  /// The path segment the reader is opened under, relative to
  /// [ebookSegment].
  ///
  /// It is below the work and not beside it, so that closing the reader lands
  /// on the book it came from — and so that a browser's back button does, which
  /// is the same thing said twice on one target and once on five.
  static const String readSegment = 'read';

  /// Where one work is read (UC04).
  ///
  /// [at] is a locator to open the book at — a CFI a mark carries, so that a
  /// highlight in the annotations screen leads back to the passage it is on.
  /// It is a query parameter and not a path segment because it is not part of
  /// the *identity* of the screen: the same reader, the same book, opened at a
  /// different place. It also has to survive being pasted, which is why it is
  /// encoded rather than written in.
  static String readEbook(String id, {String? at}) => at == null
      ? '${ebook(id)}/$readSegment'
      : '${ebook(id)}/$readSegment'
            '?$locatorParameter=${Uri.encodeQueryComponent(at)}';

  /// The query parameter [readEbook] carries a locator in.
  static const String locatorParameter = 'at';

  /// The path segment one work's marks are shown under, relative to
  /// [ebookSegment].
  ///
  /// It is *marks* and not *annotations* so that the two scopes of one screen
  /// do not look like two screens sharing a word: [annotations] is everything
  /// the reader has marked, and this is the same screen narrowed to one book.
  static const String marksSegment = 'marks';

  /// Where one work's marks are shown (UC05).
  static String ebookMarks(String id) => '${ebook(id)}/$marksSegment';

  /// Everything the reader has marked, across every book.
  static const String annotations = '/annotations';

  /// The account, the devices, the known servers and the state of the sync.
  static const String settings = '/settings';

  /// The path segment the state of the synchronization is shown under,
  /// relative to [settings].
  static const String syncSegment = 'sync';

  /// Where the state of the synchronization is shown.
  ///
  /// It is below the settings and not a fourth destination of the shell, and
  /// the difference is a claim about what synchronization *is*: a property of
  /// the app rather than a place a reader visits. What belongs in front of them
  /// at all times is one number — how much has not left this device — and the
  /// navigation surface carries that as a badge.
  static const String sync = '$settings/$syncSegment';

  /// The path segment the reader's catalogue of nodes is shown under,
  /// relative to [settings].
  static const String serversSegment = 'servers';

  /// Where the reader's catalogue of nodes is shown (UC12).
  ///
  /// It is below the settings for the reason the synchronization screen is:
  /// which nodes this reader federates with is a property of the app rather
  /// than a place they visit, and the shell has three destinations because
  /// three is what a reader navigates *between*.
  static const String servers = '$settings/$serversSegment';

  /// The path segment the replica permissions are shown under, relative to
  /// [settings].
  static const String replicasSegment = 'replicas';

  /// Where the reader says which nodes may hold a copy of their data (UC15).
  static const String replicas = '$settings/$replicasSegment';

  /// The path segment the home server migration is shown under, relative to
  /// [settings].
  static const String migrateSegment = 'migrate';

  /// Where a reader moves to another origin server (UC16).
  static const String migrate = '$settings/$migrateSegment';

  /// The path segment the reader's own record is shown under, relative to
  /// [settings].
  static const String accountSegment = 'account';

  /// Where the reader's own record is shown and changed (UC06).
  static const String account = '$settings/$accountSegment';

  /// The path segment account deletion is declared under, relative to
  /// [accountSegment].
  ///
  /// It is a location below the account and not a dialog on it, for the reason
  /// every irreversible screen in this app is one: what it says takes reading,
  /// a reader who switched away comes back to it, and a browser's back button
  /// leaves the screen rather than the app.
  static const String deleteAccountSegment = 'delete';

  /// Where the reader removes themselves from their node (UC06, delete).
  static const String deleteAccount = '$account/$deleteAccountSegment';

  /// The path segment the reader's devices are shown under, relative to
  /// [settings].
  static const String devicesSegment = 'devices';

  /// Where the reader's devices are shown (RF11).
  static const String devices = '$settings/$devicesSegment';

  /// The destinations that share the shell, in the order the navigation
  /// surface shows them.
  ///
  /// It is a list and not three independent constants because the branches of
  /// the shell, the destinations of the navigation surface and the indices
  /// that tie the two together are one ordering, and three orderings written
  /// separately are three orderings that will disagree.
  static const List<String> shell = <String>[library, annotations, settings];
}

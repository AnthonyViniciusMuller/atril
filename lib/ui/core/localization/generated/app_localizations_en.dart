// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Atril';

  @override
  String get navigationLibrary => 'Library';

  @override
  String get navigationAnnotations => 'Annotations';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get pageNotFoundTitle => 'Page not found';

  @override
  String pageNotFoundMessage(String location) {
    return 'The address $location does not match any screen in this application.';
  }

  @override
  String get pageNotFoundAction => 'Go to the library';

  @override
  String get onboardingServerTitle => 'Choose your server';

  @override
  String get onboardingServerExplanation =>
      'Your library lives on a Quire server. Its address is the second half of your identifier, as in @ana:quire.example.';

  @override
  String get onboardingServerFieldLabel => 'Server domain';

  @override
  String get onboardingServerFieldHint => 'quire.example';

  @override
  String get onboardingServerContinue => 'Continue';

  @override
  String get onboardingServerDevelopment => 'Development federation';

  @override
  String onboardingServerChosen(String domain) {
    return 'You will sign in at $domain.';
  }

  @override
  String onboardingServerNotQuire(String domain) {
    return '$domain does not publish a Quire discovery document.';
  }

  @override
  String onboardingServerUnreachable(String domain) {
    return '$domain did not answer. Check your connection and try again.';
  }

  @override
  String onboardingServerInsecure(String domain) {
    return 'The lookup of $domain was redirected to an unencrypted connection and was refused.';
  }

  @override
  String onboardingServerFailed(String domain) {
    return '$domain could not be used.';
  }

  @override
  String onboardingServerConfirm(String domain) {
    return 'Continue at $domain';
  }

  @override
  String get signInTitle => 'Sign in';

  @override
  String signInAt(String domain) {
    return 'Signing in at $domain.';
  }

  @override
  String get signInIdentifierLabel => 'Username or e-mail';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInPasswordShow => 'Show the password';

  @override
  String get signInPasswordHide => 'Hide the password';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get signInInvalidCredentials => 'Wrong username or password.';

  @override
  String get signInDeviceRevoked =>
      'This device was unbound from the account. Ask another device to bind it again.';

  @override
  String signInUnreachable(String domain) {
    return '$domain could not be reached. Check your connection and try again.';
  }

  @override
  String get signInFailed => 'Signing in did not work.';

  @override
  String deviceDefaultName(String platform) {
    return 'Atril on $platform';
  }

  @override
  String get signInRegister => 'Create an account';

  @override
  String get registerTitle => 'Create an account';

  @override
  String registerAt(String domain) {
    return 'The account will be created at $domain, and your identifier will be @name:$domain.';
  }

  @override
  String get registerLocalNameLabel => 'Username';

  @override
  String get registerDisplayNameLabel => 'Display name';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerLocalNameInvalid =>
      'Use only lower-case letters, digits and . - _, starting and ending with a letter or a digit.';

  @override
  String get registerLocalNameTaken =>
      'That name belongs to somebody else on this server. The same name on another server is free.';

  @override
  String get registerDisplayNameInvalid => 'The display name cannot be blank.';

  @override
  String get registerEmailInvalid => 'Enter a valid e-mail address.';

  @override
  String get registerEmailTaken =>
      'That address is already registered on this server.';

  @override
  String get registerPasswordInvalid =>
      'The password must be at least 8 characters long.';

  @override
  String get registerFailed => 'The account could not be created.';

  @override
  String registerUnreachable(String domain) {
    return '$domain could not be reached. Check your connection and try again.';
  }

  @override
  String get settingsAccountSection => 'Account';

  @override
  String settingsSignedInAs(String federatedId) {
    return 'You are signed in as $federatedId.';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutExplanation =>
      'Your library stays on this device. Signing out ends the session and deletes nothing.';

  @override
  String get signInForgot => 'I forgot my password';

  @override
  String get recoveryTitle => 'Recover your password';

  @override
  String recoveryExplanation(String domain) {
    return 'Enter the e-mail of your account at $domain. If there is an account with that address, we will send a code to reset the password.';
  }

  @override
  String get recoveryEmailLabel => 'E-mail address';

  @override
  String get recoverySubmit => 'Send code';

  @override
  String get recoverySent =>
      'If there is an account with that address, the code is on its way. Check the spam folder too.';

  @override
  String get recoveryHaveCode => 'I already have a code';

  @override
  String recoveryUnreachable(String domain) {
    return '$domain could not be reached. Check your connection and try again.';
  }

  @override
  String get recoveryFailed => 'The recovery could not be requested.';

  @override
  String get resetTitle => 'Set a new password';

  @override
  String get resetExplanation =>
      'Paste the code you received by e-mail and choose a new password. Every session on every one of your devices will be ended.';

  @override
  String get resetTokenLabel => 'Recovery code';

  @override
  String get resetPasswordLabel => 'New password';

  @override
  String get resetSubmit => 'Reset password';

  @override
  String get resetTokenInvalid =>
      'That code is not valid. It may have expired or already been used — ask for another.';

  @override
  String get resetDone => 'Password reset. Sign in with the new one.';

  @override
  String get resetFailed => 'The password could not be reset.';

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptyMessage =>
      'Import an EPUB, PDF, MOBI, DJVU or CBZ file. It is kept on this device and sent to your server when there is a network.';

  @override
  String get libraryFilterEmptyTitle => 'No books on this shelf';

  @override
  String get libraryFilterEmptyMessage =>
      'You have books, but none of them are filed here.';

  @override
  String get libraryShowAll => 'All books';

  @override
  String get librarySort => 'Sort';

  @override
  String get librarySortRecent => 'Recently added';

  @override
  String get librarySortTitle => 'Title';

  @override
  String get librarySortAuthor => 'Author';

  @override
  String get libraryUnknownAuthor => 'Unknown author';

  @override
  String get libraryReadFailed =>
      'Your library could not be read on this device.';

  @override
  String libraryBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
      zero: 'No books',
    );
    return '$_temp0';
  }

  @override
  String get libraryImport => 'Import a book';

  @override
  String get libraryImportUnsupported =>
      'This application imports EPUB, PDF, MOBI, DJVU and CBZ files.';

  @override
  String get libraryImportFailed => 'The file could not be imported.';

  @override
  String libraryImported(String title) {
    return '$title joined your library.';
  }

  @override
  String get settingsStorageSection => 'Storage';

  @override
  String storageUsed(String used) {
    return '$used kept on this device';
  }

  @override
  String storageUsedOfQuota(String used, String quota) {
    return '$used of $quota kept on this device';
  }

  @override
  String get storageKeptExplanationNative =>
      'Your books are kept here and open without a network. You can free the space of a book that has already reached the server; it comes back when you ask.';

  @override
  String get storageKeptExplanationWeb =>
      'In a browser a book is only kept if you ask. The others are read from the server and need a network.';

  @override
  String get storageNothingKept => 'No files are kept on this device.';

  @override
  String get storageRelease => 'Free the space';

  @override
  String get storageKeep => 'Keep on this device';

  @override
  String get storageNotYetSent =>
      'This book has not reached the server yet. It only exists here, so its space cannot be freed now.';

  @override
  String get storageReleaseFailed =>
      'The space of this book could not be freed.';

  @override
  String get storageKeepFailed => 'This book could not be kept on this device.';

  @override
  String bytesInKilobytes(String value) {
    return '$value kB';
  }

  @override
  String bytesInMegabytes(String value) {
    return '$value MB';
  }

  @override
  String bytesInGigabytes(String value) {
    return '$value GB';
  }

  @override
  String bytesExactly(String value) {
    return '$value B';
  }

  @override
  String get ebookNotFoundTitle => 'This book is no longer here';

  @override
  String get ebookNotFoundMessage =>
      'It was deleted on another device, and the deletion reached this one.';

  @override
  String get ebookMetadataSection => 'Details';

  @override
  String get ebookPublisher => 'Publisher';

  @override
  String get ebookLanguage => 'Language';

  @override
  String get ebookFormat => 'Format';

  @override
  String get ebookSize => 'Size';

  @override
  String get ebookImportedAt => 'Added on';

  @override
  String get ebookUnknownFormat => 'Unknown format';

  @override
  String get ebookShelvesSection => 'Shelves';

  @override
  String get ebookNoShelves => 'It is not on any shelf.';

  @override
  String get ebookFileSection => 'File';

  @override
  String get ebookFileHere =>
      'Kept on this device. It opens without a network.';

  @override
  String get ebookFileHereNotKept =>
      'It is on this device, but it is not marked to stay.';

  @override
  String get ebookFileOnServer =>
      'It is on the server. Download it to read without a network.';

  @override
  String get ebookFileWaiting =>
      'Not sent to the server yet. This device has the only copy.';

  @override
  String ebookFileSending(String percent) {
    return 'Sending to the server: $percent%';
  }

  @override
  String get ebookDownload => 'Download';

  @override
  String ebookDownloading(String percent) {
    return 'Downloading: $percent%';
  }

  @override
  String get ebookCancelDownload => 'Cancel';

  @override
  String get ebookDownloadFailed => 'This book could not be downloaded.';

  @override
  String get ebookNotOnServer => 'The server does not have this book\'s file.';

  @override
  String get ebookExtraSection => 'What the file carried';

  @override
  String get ebookEdit => 'Edit';

  @override
  String get ebookEditTitle => 'Edit details';

  @override
  String get ebookTitleLabel => 'Title';

  @override
  String get ebookAuthorLabel => 'Author';

  @override
  String get ebookTitleRequired => 'The title cannot be blank.';

  @override
  String get ebookEditSave => 'Save';

  @override
  String get ebookEditSaved => 'Details saved on this device.';

  @override
  String get ebookEditFailed => 'The details could not be saved.';

  @override
  String get ebookEditExtraExplanation =>
      'What the file carried beyond the details — series, ISBN, subjects. Each row is a name and a value.';

  @override
  String get ebookEditExtraName => 'Name';

  @override
  String get ebookEditExtraValue => 'Value';

  @override
  String get ebookEditExtraAdd => 'Add';

  @override
  String get ebookEditExtraRemove => 'Remove';

  @override
  String get ebookEditExtraNotText =>
      'This value is not text and was kept as it was.';

  @override
  String get ebookDelete => 'Delete';

  @override
  String get ebookDeleteConfirmTitle => 'Delete this book?';

  @override
  String get ebookDeleteConfirmMessage =>
      'It leaves your library on every one of your devices. You can undo this straight afterwards.';

  @override
  String ebookDeleted(String title) {
    return '$title was deleted.';
  }

  @override
  String get ebookDeleteUndo => 'Undo';

  @override
  String get ebookDeleteFailed => 'This book could not be deleted.';

  @override
  String ebookRestoreFailed(String title) {
    return '$title could not be brought back.';
  }

  @override
  String ebookRestored(String title) {
    return '$title is back in your library.';
  }

  @override
  String get shelvesTitle => 'Shelves';

  @override
  String get shelvesCollections => 'Shelves';

  @override
  String get shelvesCategories => 'Categories';

  @override
  String get shelvesEmpty => 'You have not made any shelves yet.';

  @override
  String get shelvesEmptyMessage =>
      'A shelf is a grouping you put together; a category is a subject. Both file the same works in different ways.';

  @override
  String get shelvesCreate => 'New shelf';

  @override
  String get shelvesEditTitle => 'Edit shelf';

  @override
  String get shelvesNameLabel => 'Name';

  @override
  String get shelvesNameRequired => 'The name cannot be blank.';

  @override
  String get shelvesDescriptionLabel => 'What it is for';

  @override
  String get shelvesKindCollection => 'Shelf';

  @override
  String get shelvesKindCategory => 'Category';

  @override
  String get shelvesSave => 'Save';

  @override
  String get shelvesSaveFailed => 'This shelf could not be saved.';

  @override
  String get shelvesDelete => 'Delete';

  @override
  String shelvesDeleted(String name) {
    return '$name was deleted. The books stay in your library.';
  }

  @override
  String get shelvesDeleteFailed => 'This shelf could not be deleted.';

  @override
  String shelvesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
      zero: 'No books',
    );
    return '$_temp0';
  }

  @override
  String get ebookShelvesEdit => 'Choose shelves';

  @override
  String get ebookShelvesDialogTitle => 'File under';

  @override
  String get ebookShelvesNone => 'You have not made any shelves yet.';

  @override
  String get ebookShelvesFailed => 'This book\'s shelves could not be changed.';

  @override
  String get librarySearch => 'Search';

  @override
  String get librarySearchHint => 'Search by title or author';

  @override
  String get librarySearchClear => 'Clear the search';

  @override
  String get libraryFilterFormat => 'Format';

  @override
  String get libraryAllFormats => 'All formats';

  @override
  String get libraryNoMatchesTitle => 'Nothing found';

  @override
  String get libraryNoMatchesMessage =>
      'No book in your library matches what you asked for.';

  @override
  String get libraryClearFilters => 'Clear the filters';

  @override
  String get readerOpen => 'Read';

  @override
  String get readerBack => 'Back to the book';

  @override
  String get readerContents => 'Contents';

  @override
  String get readerContentsEmptyTitle => 'No contents';

  @override
  String get readerContentsEmptyMessage =>
      'This file carries no navigable contents.';

  @override
  String get readerPreviousPage => 'Previous page';

  @override
  String get readerNextPage => 'Next page';

  @override
  String readerProgress(int percent) {
    return '$percent% read';
  }

  @override
  String readingPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get readingProgressLabel => 'Reading progress';

  @override
  String get readerToggleChrome => 'Show or hide the controls';

  @override
  String get readerOpening => 'Opening the book…';

  @override
  String get readerNotOnDeviceTitle => 'The file is not on this device';

  @override
  String get readerNotOnDeviceMessage =>
      'Download the file to read it offline.';

  @override
  String get readerFormatTitle => 'This format does not open here yet';

  @override
  String get readerFormatMessage =>
      'For now Atril opens EPUB only. This book stays in your library, synchronized, with its progress recorded.';

  @override
  String get readerFailedTitle => 'The book could not be opened';

  @override
  String get readerFailedMessage =>
      'The reader could not open this file. Try again; if it keeps happening, the file may be incomplete.';

  @override
  String get readerTimedOutMessage =>
      'The reader did not answer in time. That usually happens with very large files, or just after the app has started.';

  @override
  String get readerFileBrokenMessage =>
      'This file is an EPUB the reader could not display. It may be damaged or incomplete, and the book stays in your library.';

  @override
  String get readerTooLargeMessage =>
      'This file is too large to open on this device.';

  @override
  String get readerRetry => 'Try again';

  @override
  String get readerDownload => 'Download';

  @override
  String get readerSettings => 'Appearance';

  @override
  String get readerSettingsExplanation =>
      'Applies to this device. It is not synchronized.';

  @override
  String get readerFontSize => 'Type size';

  @override
  String readerFontSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get readerLineHeight => 'Line spacing';

  @override
  String get readerMargin => 'Margin';

  @override
  String get readerTheme => 'Theme';

  @override
  String get readerThemeSystem => 'System';

  @override
  String get readerThemeLight => 'Light';

  @override
  String get readerThemeSepia => 'Sepia';

  @override
  String get readerThemeDark => 'Dark';

  @override
  String get readerSpread => 'Two pages';

  @override
  String get libraryContinueReading => 'Continue reading';

  @override
  String get libraryContinueHere => 'On this device';

  @override
  String get libraryContinueElsewhere => 'On another device';

  @override
  String libraryContinuePercent(int percent) {
    return '$percent%';
  }

  @override
  String get readerHighlight => 'Highlight';

  @override
  String get readerSelectionDismiss => 'Dismiss the selection';

  @override
  String get readerHighlighted => 'Passage highlighted.';

  @override
  String get readerMarkUndo => 'Undo';

  @override
  String get readerMarkFailed => 'The mark could not be saved.';

  @override
  String get readerNote => 'Note';

  @override
  String get readerNoteTitle => 'Note';

  @override
  String get readerNoteLabel => 'What you want to record';

  @override
  String get readerNoteRequired => 'A note with no text is an empty note.';

  @override
  String get readerNoteCancel => 'Cancel';

  @override
  String get readerNoteSave => 'Save';

  @override
  String get readerNoted => 'Note saved.';

  @override
  String get readerBookmark => 'Bookmark this page';

  @override
  String get readerBookmarkRemove => 'Remove this bookmark';

  @override
  String get readerBookmarked => 'Page bookmarked.';

  @override
  String get readerBookmarkRemoved => 'Bookmark removed.';

  @override
  String get annotationsInThisBook => 'Marks in this book';

  @override
  String get annotationsAll => 'All';

  @override
  String get annotationsHighlights => 'Highlights';

  @override
  String get annotationsNotes => 'Notes';

  @override
  String get annotationsBookmarks => 'Bookmarks';

  @override
  String get annotationsHighlight => 'Highlight';

  @override
  String get annotationsNote => 'Note';

  @override
  String get annotationsBookmark => 'Bookmark';

  @override
  String get annotationsUnknownKind => 'Mark';

  @override
  String annotationsFromBook(String title, String date) {
    return '$title · $date';
  }

  @override
  String get annotationsEmptyTitle => 'Nothing marked yet';

  @override
  String get annotationsEmptyMessage =>
      'Highlights, notes and bookmarks made while reading appear here, and follow you to your other devices.';

  @override
  String get annotationsNoneOfThisKindTitle => 'No marks of that kind';

  @override
  String get annotationsNoneOfThisKindMessage =>
      'You have marks, but none of the kind you chose.';

  @override
  String get annotationsShowAll => 'Show all';

  @override
  String get annotationsFailedTitle => 'The marks could not be read';

  @override
  String get annotationsFailedMessage =>
      'They are stored on this device and the query for them failed. Nothing has been lost.';

  @override
  String get annotationsActions => 'What to do with this mark';

  @override
  String get annotationsEdit => 'Edit the note';

  @override
  String get annotationsAddNote => 'Add a note';

  @override
  String get annotationsRemove => 'Remove';

  @override
  String get annotationsRemoved => 'Mark removed.';

  @override
  String get annotationsUndo => 'Undo';

  @override
  String get annotationsSaved => 'Note saved.';

  @override
  String get annotationsNoteTitle => 'Note';

  @override
  String get annotationsPassageGivesWay =>
      'What stays here replaces the passage stored: the record has one text field, and on a note it is yours.';

  @override
  String get ebookMarksSection => 'Marks';

  @override
  String get ebookMarksOpen => 'See the marks';

  @override
  String get annotationsExport => 'Export the marks';

  @override
  String get annotationsExportMarkdown => 'Export as Markdown';

  @override
  String get annotationsExportJson => 'Export as JSON';

  @override
  String annotationsExportedAt(String date) {
    return 'Exported from Atril on $date';
  }

  @override
  String get annotationsExported => 'Marks exported.';

  @override
  String get annotationsNothingToExport => 'There is nothing marked to export.';

  @override
  String get annotationsExportFailed => 'The file could not be written.';

  @override
  String get syncTitle => 'Synchronization';

  @override
  String get syncOpen => 'See the state of the synchronization';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting',
      one: '1 change waiting',
      zero: 'Nothing waiting',
    );
    return '$_temp0';
  }

  @override
  String get syncPendingExplanation =>
      'They are held here and leave as soon as this device reaches the node. Nothing is lost in the meantime.';

  @override
  String get syncNothingPending =>
      'Everything you have done has left this device.';

  @override
  String get syncNever => 'This device has not reached the node yet.';

  @override
  String syncLastReached(String date, String time) {
    return 'Reached the node on $date, at $time';
  }

  @override
  String get syncActivityIdle => 'Stopped';

  @override
  String get syncActivityConnecting => 'Connecting…';

  @override
  String get syncActivityLive => 'Connected to the node';

  @override
  String get syncActivityWaiting => 'Will try again';

  @override
  String get syncNow => 'Synchronize now';

  @override
  String get syncFailedNow => 'It was not possible to synchronize now.';

  @override
  String get syncWaitingOnNode =>
      'The node did not answer. This device tries again on its own.';

  @override
  String syncSomethingWrong(String reason) {
    return 'Something went wrong last time: $reason';
  }

  @override
  String get syncStateSection => 'Now';

  @override
  String get syncChangesSection => 'What has not left yet';

  @override
  String get syncRefusedSection => 'Refused by the node';

  @override
  String get syncRefusedExplanation =>
      'The node did not accept these changes and will not accept them on another try. They still hold on this device and have reached no other.';

  @override
  String syncRefusedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count refused by the node',
      one: '1 refused by the node',
    );
    return '$_temp0';
  }

  @override
  String get syncRefusedNoReason => 'The node did not say why.';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardExplanation =>
      'Discarding does not undo what you did. It only stops this device from holding a delivery that is not going to happen.';

  @override
  String get syncDiscardTitle => 'Discard this change?';

  @override
  String get syncDiscarded => 'Change discarded.';

  @override
  String get syncDiscardFailed => 'It was not possible to discard it.';

  @override
  String get syncCancel => 'Cancel';

  @override
  String get syncRecordEbook => 'A book';

  @override
  String get syncRecordCollection => 'A shelf';

  @override
  String get syncRecordFiling => 'A book on a shelf';

  @override
  String get syncRecordProgress => 'Where you stopped';

  @override
  String get syncRecordAnnotation => 'A mark';

  @override
  String get settingsFederationSection => 'Federation';

  @override
  String get settingsKnownServers => 'Known servers';

  @override
  String get settingsKnownServersExplanation =>
      'The servers your node knows, and the ones it may replicate to.';

  @override
  String get federationServersExplanation =>
      'Nothing leaves your node for a server you have not named here. Each of these was discovered from the domain you typed, and the key it presented was pinned.';

  @override
  String get federationServersEmpty => 'You have not added any server yet.';

  @override
  String get federationServersFailed =>
      'The catalogue could not be read. The node did not answer.';

  @override
  String get federationRetry => 'Try again';

  @override
  String get federationAddLabel => 'Server domain';

  @override
  String get federationAddHint => 'quire-b.example';

  @override
  String get federationAdd => 'Add';

  @override
  String federationAdded(String domain) {
    return '$domain was added.';
  }

  @override
  String get federationAddInvalid => 'That is not a server domain.';

  @override
  String get federationAddAlreadyKnown =>
      'That server is already in your catalogue.';

  @override
  String get federationAddFailed =>
      'That server could not be added. It may publish no discovery document.';

  @override
  String get federationServerOrigin => 'Your node';

  @override
  String get federationServerActive => 'Takes part in replication';

  @override
  String get federationServerInactive => 'Not replicating';

  @override
  String federationServerBaseUrl(String url) {
    return 'Answers at $url';
  }

  @override
  String federationServerGrpc(String authority) {
    return 'gRPC at $authority';
  }

  @override
  String get federationServerGrpcAbsent =>
      'Publishes no gRPC address — nothing replicates to it.';

  @override
  String federationServerFingerprint(String fingerprint) {
    return 'Key $fingerprint';
  }

  @override
  String get federationServerFingerprintAbsent => 'No key pinned.';

  @override
  String federationServerDiscovered(String date, String time) {
    return 'Discovered on $date at $time';
  }

  @override
  String get federationServerNeverDiscovered => 'Not discovered yet.';

  @override
  String get federationRefresh => 'Refresh';

  @override
  String federationRefreshed(String domain) {
    return '$domain was refreshed and the key has not changed.';
  }

  @override
  String get federationRefreshFailed => 'That server could not be refreshed.';

  @override
  String get federationKeyChangedTitle =>
      'This server presents a different key';

  @override
  String federationKeyChangedExplanation(String domain) {
    return '$domain now presents a different key from the one on record. That happens when its operator rotates the certificate — and it is also what somebody answering in its place would look like. From here the two are indistinguishable.';
  }

  @override
  String get federationKeyChangedUnderstood => 'Understood';

  @override
  String get federationForget => 'Forget';

  @override
  String federationForgetTitle(String domain) {
    return 'Forget $domain?';
  }

  @override
  String get federationForgetExplanation =>
      'Nothing more travels to it. Whatever it already received stays there — forgetting does not reach into another operator’s database.';

  @override
  String federationForgotten(String domain) {
    return '$domain was forgotten.';
  }

  @override
  String get federationForgetRefused =>
      'That server holds a copy of your data. Revoke the replica before forgetting it.';

  @override
  String get federationForgetFailed => 'That server could not be forgotten.';

  @override
  String get federationActiveFailed =>
      'That server’s participation could not be changed.';

  @override
  String get federationCancel => 'Cancel';

  @override
  String get settingsReplicas => 'Authorized replicas';

  @override
  String get settingsReplicasExplanation => 'Who may hold a copy of your data.';

  @override
  String get replicasExplanation =>
      'Authorizing a server says it may keep a copy of your library. Only the servers named here receive anything.';

  @override
  String get replicasOutOfBand =>
      'The permission is recorded on your own server, which tells the other one the first time it has something to send. That server accepts only if it already knows yours: someone with an account there has to add your server under Known servers.';

  @override
  String get replicasNone => 'No server holds a copy of your data.';

  @override
  String get replicasFailed =>
      'The authorizations could not be read. The node did not answer.';

  @override
  String get replicasGrantedSection => 'Holding a copy';

  @override
  String get replicasRevokedSection => 'Used to hold a copy';

  @override
  String get replicasRevokedExplanation =>
      'Replication stopped. Whatever these servers already received is still with them: revoking does not reach into another operator’s database.';

  @override
  String get replicasWithFiles => 'Metadata and files';

  @override
  String get replicasWithoutFiles => 'Metadata only';

  @override
  String get replicasWithFilesExplanation =>
      'Everything, the e-book files included. It costs that server the space your library takes.';

  @override
  String get replicasWithoutFilesExplanation =>
      'Your books, shelves and marks — without the files. It is the cheap replica, and usually the one worth having on a server that is not yours.';

  @override
  String replicasGrantedAt(String date) {
    return 'Authorized on $date';
  }

  @override
  String get replicasAuthorize => 'Authorize a server';

  @override
  String get replicasChooseServer => 'Which server';

  @override
  String get replicasNoCandidates =>
      'Every server in your catalogue is already authorized. Add another under Known servers.';

  @override
  String get replicasCandidateUndialable =>
      'Publishes no gRPC address — nothing replicates to it.';

  @override
  String replicasChooseWhat(String domain) {
    return 'What $domain will hold';
  }

  @override
  String get replicasConfirm => 'Authorize';

  @override
  String replicasAuthorized(String domain) {
    return '$domain may hold a copy.';
  }

  @override
  String get replicasAuthorizeFailed => 'That server could not be authorized.';

  @override
  String get replicasRevoke => 'Revoke';

  @override
  String replicasRevokeTitle(String domain) {
    return 'Revoke $domain?';
  }

  @override
  String get replicasRevokeExplanation =>
      'Replication stops. Whatever that server already received stays with it — revoking erases nothing from another operator’s database, which is why the withdrawn permission stays in the list.';

  @override
  String replicasRevoked(String domain) {
    return '$domain receives nothing more.';
  }

  @override
  String get replicasRevokeFailed => 'That authorization could not be revoked.';

  @override
  String get settingsMigrate => 'Move to another server';

  @override
  String get settingsMigrateExplanation =>
      'Take your library to a different server.';

  @override
  String get migrationStepWhat => 'What this does';

  @override
  String get migrationExplanation =>
      'Your whole library is on this device, which is why it can move to another server without the current one agreeing — or even being up. Nothing is asked of it and nothing is lost there.';

  @override
  String migrationIdentifierChanges(String localName, String domain) {
    return 'Your identifier changes. Its second half is the server’s domain, so @$localName:$domain becomes a different name — one that holds the same history.';
  }

  @override
  String get migrationReauthorize =>
      'Servers that held a copy have to be authorized again, because their authorization names the old identifier.';

  @override
  String get migrationIrreversible => 'It cannot be undone.';

  @override
  String get migrationStepServer => 'Where to';

  @override
  String get migrationDomainLabel => 'New server domain';

  @override
  String get migrationConnectsAtTheEnd =>
      'This device only starts talking to the new server at the last step. Until then it stays on the current one.';

  @override
  String get migrationLocalNameLabel => 'Username at the new server';

  @override
  String get migrationDisplayNameLabel => 'Display name';

  @override
  String get migrationEmailLabel => 'Email';

  @override
  String get migrationPasswordLabel => 'Password at the new server';

  @override
  String get migrationInvalidDomain => 'That is not a server domain.';

  @override
  String get migrationInvalidLocalName =>
      'Use lower-case letters, digits, and . - _ between them.';

  @override
  String get migrationInvalidDisplayName => 'Enter a name.';

  @override
  String get migrationInvalidEmail => 'Enter a valid email address.';

  @override
  String get migrationInvalidPassword =>
      'The password needs at least 8 characters.';

  @override
  String get migrationStepDevices => 'What travels';

  @override
  String get migrationDevicesExplanation =>
      'All your devices travel, with the identifiers they already hold. It is what lets each of them go on from where it stopped: every change names the device that made it.';

  @override
  String get migrationThisDevice => 'This device';

  @override
  String migrationUnnamedDevice(String handle) {
    return 'Device $handle';
  }

  @override
  String get migrationDevicesUnnamed =>
      'The current server did not answer, so the names are gone. The identifiers came from the history kept on this device, which is the half that cannot be recreated — you can rename each device afterwards.';

  @override
  String get migrationDevicesFailed => 'Your devices could not be worked out.';

  @override
  String get migrationStepConfirm => 'Confirm';

  @override
  String migrationSummary(String localName, String domain, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return '@$localName:$domain becomes your account, with $_temp0 and your whole library.';
  }

  @override
  String get migrationNothingIsCleared =>
      'Nothing is erased from this device. Whatever has not been handed over yet stays queued and is sent to the new server.';

  @override
  String get migrationGo => 'Move';

  @override
  String get migrationBack => 'Back';

  @override
  String get migrationNext => 'Continue';

  @override
  String migrationDone(String federatedId) {
    return 'You are now $federatedId.';
  }

  @override
  String get migrationFailed =>
      'The migration did not happen. This device is still on the server it was on.';

  @override
  String get migrationNameTaken =>
      'That username already exists on that server.';

  @override
  String get settingsDevices => 'Your devices';

  @override
  String get settingsDevicesExplanation =>
      'Which devices may write on your account.';

  @override
  String get devicesExplanation =>
      'Every change to your library names the device that made it. That is why this list exists: without it a history would carry names nobody can resolve.';

  @override
  String get devicesFailed =>
      'Your devices could not be read. The node did not answer.';

  @override
  String get devicesThisOne => 'This device';

  @override
  String get devicesUnbound => 'Unbound';

  @override
  String get devicesUnboundExplanation =>
      'It may no longer write. The row stays, because the changes it made still name it.';

  @override
  String devicesLastSynced(String date) {
    return 'Last synchronized on $date';
  }

  @override
  String get devicesNeverSynced => 'Has not synchronized yet.';

  @override
  String get devicesRename => 'Rename';

  @override
  String get devicesRenameTitle => 'Rename device';

  @override
  String get devicesNameLabel => 'Device name';

  @override
  String get devicesNameInvalid => 'Enter a name.';

  @override
  String devicesRenamed(String name) {
    return 'It is now called $name.';
  }

  @override
  String get devicesRenameFailed => 'That device could not be renamed.';

  @override
  String get devicesRevoke => 'Unbind';

  @override
  String devicesRevokeTitle(String name) {
    return 'Unbind $name?';
  }

  @override
  String get devicesRevokeExplanation =>
      'It stops being able to write and its sessions end. Nothing it already wrote is erased, and its row stays in the list — it is what gives the device a name in the history of your changes.';

  @override
  String devicesRevoked(String name) {
    return '$name may no longer write.';
  }

  @override
  String get devicesRevokeFailed => 'That device could not be unbound.';

  @override
  String get devicesCannotRevokeThisOne =>
      'A device cannot unbind itself. Do it from another of your devices.';

  @override
  String get devicesSave => 'Save';

  @override
  String get settingsAccount => 'Your account';

  @override
  String get settingsAccountExplanation => 'Name, email and password.';

  @override
  String get accountIdentifier => 'Identifier';

  @override
  String get accountIdentifierExplanation =>
      'Its two halves are your username and the server you are registered at. It only changes by moving server.';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailExplanation =>
      'It is where password recovery goes, so changing it asks for your password.';

  @override
  String get accountEmailAbsent => 'No email on record.';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordExplanation =>
      'Changing the password ends your session on every device, this one included.';

  @override
  String accountCreated(String date) {
    return 'Account created on $date';
  }

  @override
  String get accountFailed =>
      'Your account could not be read. The node did not answer.';

  @override
  String get accountEditName => 'Change display name';

  @override
  String get accountNameInvalid => 'Enter a name.';

  @override
  String accountNameChanged(String name) {
    return 'You now appear as $name.';
  }

  @override
  String get accountNameFailed => 'The display name could not be changed.';

  @override
  String get accountEditEmail => 'Change email';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountEmailInvalid => 'Enter a valid email address.';

  @override
  String get accountEmailNotice =>
      'A notice goes to the previous address. That is how you find out if it was not you who changed it.';

  @override
  String accountEmailChanged(String email) {
    return 'Your email is now $email.';
  }

  @override
  String get accountEmailFailed => 'The email could not be changed.';

  @override
  String get accountEmailRegistered =>
      'That email is already registered on this server.';

  @override
  String get accountEditPassword => 'Change password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountPasswordInvalid =>
      'The password needs at least 8 characters.';

  @override
  String get accountPasswordEndsSessions =>
      'Every session of yours ends and you sign in again on each device. That is what you want when the reason for changing it is a suspicion.';

  @override
  String get accountPasswordChanged => 'Password changed. Sign in again.';

  @override
  String get accountPasswordFailed => 'The password could not be changed.';

  @override
  String get accountWrongPassword => 'That is not your current password.';

  @override
  String get accountSave => 'Save';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteExplanation =>
      'It removes you from this server, with everything tied to your account there: your devices, your credentials and your library on the server.';

  @override
  String get accountDeleteReaches => 'What deleting reaches';

  @override
  String get accountDeleteDoesNotReach => 'What it does not reach';

  @override
  String accountDeleteThisServer(String domain) {
    return 'Your account at $domain';
  }

  @override
  String get accountDeleteReplicas =>
      'The servers that already hold a copy of your data. Deleting does not reach into another operator’s database — revoking never did either.';

  @override
  String accountDeleteReplicaNames(String domains) {
    return 'Still holding a copy: $domains';
  }

  @override
  String get accountDeleteLocal =>
      'The books and the marks on this device. They are your own copy, and you can export the marks before you go.';

  @override
  String get accountDeleteIrreversible => 'It cannot be undone.';

  @override
  String get accountDeleteMigrateInstead =>
      'If what you want is to move server and keep your library, use Move to another server: they are different things.';

  @override
  String get accountDeleteConfirm => 'Delete my account';

  @override
  String get accountDeletePasswordLabel => 'Your password';

  @override
  String accountDeleted(String domain) {
    return 'Your account at $domain was deleted.';
  }

  @override
  String get accountDeleteFailed => 'The account could not be deleted.';
}

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
  String readerProgress(Object percent) {
    return '$percent% read';
  }

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
  String readerFontSizeValue(Object percent) {
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
  String libraryContinuePercent(Object percent) {
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
}

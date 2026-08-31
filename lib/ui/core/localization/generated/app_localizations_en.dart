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
}

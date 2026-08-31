// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Atril';

  @override
  String get navigationLibrary => 'Biblioteca';

  @override
  String get navigationAnnotations => 'Anotações';

  @override
  String get navigationSettings => 'Configurações';

  @override
  String get pageNotFoundTitle => 'Página não encontrada';

  @override
  String pageNotFoundMessage(String location) {
    return 'O endereço $location não corresponde a nenhuma tela deste aplicativo.';
  }

  @override
  String get pageNotFoundAction => 'Ir para a biblioteca';

  @override
  String get onboardingServerTitle => 'Escolha seu servidor';

  @override
  String get onboardingServerExplanation =>
      'Sua biblioteca fica em um servidor Quire. O endereço dele é a segunda metade do seu identificador, como em @ana:quire.exemplo.';

  @override
  String get onboardingServerFieldLabel => 'Domínio do servidor';

  @override
  String get onboardingServerFieldHint => 'quire.exemplo';

  @override
  String get onboardingServerContinue => 'Continuar';

  @override
  String get onboardingServerDevelopment => 'Federação de desenvolvimento';

  @override
  String onboardingServerChosen(String domain) {
    return 'Você vai entrar em $domain.';
  }

  @override
  String onboardingServerNotQuire(String domain) {
    return '$domain não publica um documento de descoberta do Quire.';
  }

  @override
  String onboardingServerUnreachable(String domain) {
    return '$domain não respondeu. Verifique sua conexão e tente de novo.';
  }

  @override
  String onboardingServerInsecure(String domain) {
    return 'A busca por $domain foi redirecionada para uma conexão sem criptografia e foi recusada.';
  }

  @override
  String onboardingServerFailed(String domain) {
    return 'Não foi possível usar $domain.';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Atril';

  @override
  String get navigationLibrary => 'Biblioteca';

  @override
  String get navigationAnnotations => 'Anotações';

  @override
  String get navigationSettings => 'Configurações';

  @override
  String get pageNotFoundTitle => 'Página não encontrada';

  @override
  String pageNotFoundMessage(String location) {
    return 'O endereço $location não corresponde a nenhuma tela deste aplicativo.';
  }

  @override
  String get pageNotFoundAction => 'Ir para a biblioteca';

  @override
  String get onboardingServerTitle => 'Escolha seu servidor';

  @override
  String get onboardingServerExplanation =>
      'Sua biblioteca fica em um servidor Quire. O endereço dele é a segunda metade do seu identificador, como em @ana:quire.exemplo.';

  @override
  String get onboardingServerFieldLabel => 'Domínio do servidor';

  @override
  String get onboardingServerFieldHint => 'quire.exemplo';

  @override
  String get onboardingServerContinue => 'Continuar';

  @override
  String get onboardingServerDevelopment => 'Federação de desenvolvimento';

  @override
  String onboardingServerChosen(String domain) {
    return 'Você vai entrar em $domain.';
  }

  @override
  String onboardingServerNotQuire(String domain) {
    return '$domain não publica um documento de descoberta do Quire.';
  }

  @override
  String onboardingServerUnreachable(String domain) {
    return '$domain não respondeu. Verifique sua conexão e tente de novo.';
  }

  @override
  String onboardingServerInsecure(String domain) {
    return 'A busca por $domain foi redirecionada para uma conexão sem criptografia e foi recusada.';
  }

  @override
  String onboardingServerFailed(String domain) {
    return 'Não foi possível usar $domain.';
  }
}

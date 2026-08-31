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

  @override
  String onboardingServerConfirm(String domain) {
    return 'Continuar em $domain';
  }

  @override
  String get signInTitle => 'Entrar';

  @override
  String signInAt(String domain) {
    return 'Entrando em $domain.';
  }

  @override
  String get signInIdentifierLabel => 'Nome de usuário ou e-mail';

  @override
  String get signInPasswordLabel => 'Senha';

  @override
  String get signInSubmit => 'Entrar';

  @override
  String get signInInvalidCredentials => 'Nome de usuário ou senha incorretos.';

  @override
  String get signInDeviceRevoked =>
      'Este dispositivo foi desvinculado da conta. Peça a outro dispositivo para vinculá-lo de novo.';

  @override
  String signInUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
  }

  @override
  String get signInFailed => 'Não foi possível entrar.';

  @override
  String deviceDefaultName(String platform) {
    return 'Atril em $platform';
  }

  @override
  String get signInRegister => 'Criar uma conta';

  @override
  String get registerTitle => 'Criar uma conta';

  @override
  String registerAt(String domain) {
    return 'A conta será criada em $domain, e seu identificador será @nome:$domain.';
  }

  @override
  String get registerLocalNameLabel => 'Nome de usuário';

  @override
  String get registerDisplayNameLabel => 'Nome exibido';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Senha';

  @override
  String get registerSubmit => 'Criar conta';

  @override
  String get registerLocalNameInvalid =>
      'Use apenas letras minúsculas, dígitos e . - _, começando e terminando com letra ou dígito.';

  @override
  String get registerLocalNameTaken =>
      'Esse nome já é de outra pessoa neste servidor. O mesmo nome em outro servidor está livre.';

  @override
  String get registerDisplayNameInvalid =>
      'O nome exibido não pode ficar em branco.';

  @override
  String get registerEmailInvalid => 'Digite um endereço de e-mail válido.';

  @override
  String get registerEmailTaken =>
      'Esse endereço já está cadastrado neste servidor.';

  @override
  String get registerPasswordInvalid =>
      'A senha precisa ter pelo menos 8 caracteres.';

  @override
  String get registerFailed => 'Não foi possível criar a conta.';

  @override
  String registerUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
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

  @override
  String onboardingServerConfirm(String domain) {
    return 'Continuar em $domain';
  }

  @override
  String get signInTitle => 'Entrar';

  @override
  String signInAt(String domain) {
    return 'Entrando em $domain.';
  }

  @override
  String get signInIdentifierLabel => 'Nome de usuário ou e-mail';

  @override
  String get signInPasswordLabel => 'Senha';

  @override
  String get signInSubmit => 'Entrar';

  @override
  String get signInInvalidCredentials => 'Nome de usuário ou senha incorretos.';

  @override
  String get signInDeviceRevoked =>
      'Este dispositivo foi desvinculado da conta. Peça a outro dispositivo para vinculá-lo de novo.';

  @override
  String signInUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
  }

  @override
  String get signInFailed => 'Não foi possível entrar.';

  @override
  String deviceDefaultName(String platform) {
    return 'Atril em $platform';
  }

  @override
  String get signInRegister => 'Criar uma conta';

  @override
  String get registerTitle => 'Criar uma conta';

  @override
  String registerAt(String domain) {
    return 'A conta será criada em $domain, e seu identificador será @nome:$domain.';
  }

  @override
  String get registerLocalNameLabel => 'Nome de usuário';

  @override
  String get registerDisplayNameLabel => 'Nome exibido';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Senha';

  @override
  String get registerSubmit => 'Criar conta';

  @override
  String get registerLocalNameInvalid =>
      'Use apenas letras minúsculas, dígitos e . - _, começando e terminando com letra ou dígito.';

  @override
  String get registerLocalNameTaken =>
      'Esse nome já é de outra pessoa neste servidor. O mesmo nome em outro servidor está livre.';

  @override
  String get registerDisplayNameInvalid =>
      'O nome exibido não pode ficar em branco.';

  @override
  String get registerEmailInvalid => 'Digite um endereço de e-mail válido.';

  @override
  String get registerEmailTaken =>
      'Esse endereço já está cadastrado neste servidor.';

  @override
  String get registerPasswordInvalid =>
      'A senha precisa ter pelo menos 8 caracteres.';

  @override
  String get registerFailed => 'Não foi possível criar a conta.';

  @override
  String registerUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
  }
}

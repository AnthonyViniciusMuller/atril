import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('pt'),
  ];

  /// O nome do aplicativo, como aparece na barra de título de uma janela, no seletor de aplicativos e na aba do navegador. É um nome próprio e não deve ser traduzido.
  ///
  /// In pt_BR, this message translates to:
  /// **'Atril'**
  String get appTitle;

  /// O destino de navegação que mostra o acervo do leitor. Rótulo curto, usado tanto na barra inferior de um celular quanto no trilho lateral de uma janela larga, e também como título da própria tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Biblioteca'**
  String get navigationLibrary;

  /// O destino de navegação que reúne os destaques, as notas e os marcadores que o leitor escreveu, de todos os livros. Rótulo curto, usado também como título da tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anotações'**
  String get navigationAnnotations;

  /// O destino de navegação que reúne a conta, os dispositivos, os servidores conhecidos e o estado da sincronização. Rótulo curto, usado também como título da tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações'**
  String get navigationSettings;

  /// Título da tela mostrada quando o endereço aberto não corresponde a nenhuma rota. Acontece sobretudo no navegador, onde o leitor pode digitar ou colar um endereço, ou voltar a um que não existe mais.
  ///
  /// In pt_BR, this message translates to:
  /// **'Página não encontrada'**
  String get pageNotFoundTitle;

  /// Corpo da tela de endereço inexistente. Mostra o endereço pedido para que o leitor reconheça o que digitou ou de onde veio o link.
  ///
  /// In pt_BR, this message translates to:
  /// **'O endereço {location} não corresponde a nenhuma tela deste aplicativo.'**
  String pageNotFoundMessage(String location);

  /// Botão da tela de endereço inexistente, que leva o leitor de volta ao acervo. É a única saída oferecida, porque um endereço inválido não tem histórico para onde voltar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ir para a biblioteca'**
  String get pageNotFoundAction;

  /// Título da primeira tela que uma instalação nova mostra. O leitor escolhe em qual servidor Quire sua biblioteca fica, o que é a metade do identificador dele que diz onde ele está — não é uma preferência que possa ser adiada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha seu servidor'**
  String get onboardingServerTitle;

  /// Parágrafo abaixo do título da tela de escolha de servidor. Explica por que a pergunta está sendo feita antes de qualquer outra, usando um identificador federado de exemplo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sua biblioteca fica em um servidor Quire. O endereço dele é a segunda metade do seu identificador, como em @ana:quire.exemplo.'**
  String get onboardingServerExplanation;

  /// Rótulo do campo onde o leitor digita o domínio do servidor, como quire.exemplo. É um domínio e não uma URL: o aplicativo descobre o resto lendo o documento que o servidor publica.
  ///
  /// In pt_BR, this message translates to:
  /// **'Domínio do servidor'**
  String get onboardingServerFieldLabel;

  /// Texto de exemplo dentro do campo de domínio, mostrado enquanto ele está vazio. É um domínio de exemplo e não deve ser traduzido para algo que pareça um endereço real.
  ///
  /// In pt_BR, this message translates to:
  /// **'quire.exemplo'**
  String get onboardingServerFieldHint;

  /// Botão que busca o documento de descoberta do domínio digitado e passa a usar aquele servidor. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar'**
  String get onboardingServerContinue;

  /// Título da lista de servidores que uma compilação de depuração já sabe alcançar — os dois nós que o `make dev-up` do Quire sobe ao lado. Não aparece em uma compilação de produção.
  ///
  /// In pt_BR, this message translates to:
  /// **'Federação de desenvolvimento'**
  String get onboardingServerDevelopment;

  /// Confirmação mostrada depois que a descoberta deu certo, nomeando o servidor que o aplicativo passou a usar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você vai entrar em {domain}.'**
  String onboardingServerChosen(String domain);

  /// Erro mostrado quando o domínio respondeu, mas com algo que não é um servidor Quire — inclusive um 404, que é um host que não é um nó. O leitor deve conferir o que digitou.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} não publica um documento de descoberta do Quire.'**
  String onboardingServerNotQuire(String domain);

  /// Erro mostrado quando o domínio não respondeu à busca: sem rota, sem resposta ou tempo esgotado. É o único dos erros desta tela em que tentar de novo pode dar certo sem mudar nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} não respondeu. Verifique sua conexão e tente de novo.'**
  String onboardingServerUnreachable(String domain);

  /// Erro mostrado quando a busca foi redirecionada para http simples. O documento vale exatamente o que vale o canal por onde ele chegou, então o aplicativo recusa em vez de seguir.
  ///
  /// In pt_BR, this message translates to:
  /// **'A busca por {domain} foi redirecionada para uma conexão sem criptografia e foi recusada.'**
  String onboardingServerInsecure(String domain);

  /// Erro genérico da tela de escolha de servidor, para uma falha que não é nenhuma das outras três. O detalhe fica no log, que é onde ele pode ser lido por quem investiga.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível usar {domain}.'**
  String onboardingServerFailed(String domain);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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

  /// Botão que leva o leitor da tela de escolha de servidor para a tela de entrada, nomeando o servidor escolhido. Só aparece depois que a descoberta deu certo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar em {domain}'**
  String onboardingServerConfirm(String domain);

  /// Título da tela de entrada, onde o leitor se autentica no servidor que escolheu. Também é o rótulo do botão que envia o formulário.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entrar'**
  String get signInTitle;

  /// Linha abaixo do título da tela de entrada, nomeando o servidor a que as credenciais serão enviadas. Está ali porque a senha vai para esse servidor e para nenhum outro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entrando em {domain}.'**
  String signInAt(String domain);

  /// Rótulo do campo onde o leitor se identifica. O contrato aceita as duas metades — o nome local ou o endereço — e é o cliente que decide qual foi digitado, porque um nome local não pode conter arroba e um endereço precisa.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome de usuário ou e-mail'**
  String get signInIdentifierLabel;

  /// Rótulo do campo de senha da tela de entrada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha'**
  String get signInPasswordLabel;

  /// Botão que envia as credenciais ao servidor escolhido. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entrar'**
  String get signInSubmit;

  /// Erro mostrado quando o servidor recusou as credenciais. É deliberadamente o mesmo texto para um leitor que não existe e para uma senha errada: dizer qual das duas falhou permitiria descobrir quem tem conta no servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome de usuário ou senha incorretos.'**
  String get signInInvalidCredentials;

  /// Erro mostrado quando o servidor reconheceu as credenciais mas recusou este dispositivo, porque ele foi desvinculado. O registro dele continua existindo, então a saída é vincular de novo a partir de um dispositivo já autenticado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este dispositivo foi desvinculado da conta. Peça a outro dispositivo para vinculá-lo de novo.'**
  String get signInDeviceRevoked;

  /// Erro mostrado quando o servidor não respondeu à tentativa de entrada. É o único erro desta tela em que tentar de novo pode dar certo sem mudar nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível falar com {domain}. Verifique sua conexão e tente de novo.'**
  String signInUnreachable(String domain);

  /// Erro genérico da tela de entrada, para uma falha que não é nenhuma das outras. O detalhe fica no log, que é onde quem investiga pode lê-lo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível entrar.'**
  String get signInFailed;

  /// O nome que este dispositivo recebe na lista de dispositivos do leitor quando ele é vinculado pela primeira vez. O parâmetro é o nome próprio da plataforma — Android, iOS, Web, Linux, macOS, Windows — que não se traduz; o que esta mensagem decide é a frase em volta dele.
  ///
  /// In pt_BR, this message translates to:
  /// **'Atril em {platform}'**
  String deviceDefaultName(String platform);

  /// Ação secundária da tela de entrada, para quem ainda não tem conta no servidor escolhido. Leva à tela de cadastro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Criar uma conta'**
  String get signInRegister;

  /// Título da tela de cadastro, onde o leitor cria uma conta no servidor que escolheu.
  ///
  /// In pt_BR, this message translates to:
  /// **'Criar uma conta'**
  String get registerTitle;

  /// Linha abaixo do título da tela de cadastro. Nomeia o servidor e explica que o domínio dele passa a ser a segunda metade do identificador do leitor — não é uma escolha que possa ser mudada depois sem migrar de servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'A conta será criada em {domain}, e seu identificador será @nome:{domain}.'**
  String registerAt(String domain);

  /// Rótulo do campo do nome local, a primeira metade do identificador federado. Só aceita letras minúsculas, dígitos e os separadores ponto, hífen e sublinhado, porque o valor vai embutido em URLs, em tokens e em buscas .well-known.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome de usuário'**
  String get registerLocalNameLabel;

  /// Rótulo do campo do nome que o leitor quer que apareça. É o único nome pensado para ser mostrado, e aceita qualquer texto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome exibido'**
  String get registerDisplayNameLabel;

  /// Rótulo do campo de endereço. É para onde a recuperação de senha é enviada, e é o único dado pessoal que não sai do servidor de origem.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail'**
  String get registerEmailLabel;

  /// Rótulo do campo de senha da tela de cadastro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha'**
  String get registerPasswordLabel;

  /// Botão que envia o cadastro ao servidor escolhido. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Criar conta'**
  String get registerSubmit;

  /// Erro do campo de nome de usuário quando ele não tem a forma que o servidor aceita. Diz a regra inteira em vez de qual parte foi quebrada, porque a regra é curta e o leitor precisa dela para corrigir.
  ///
  /// In pt_BR, this message translates to:
  /// **'Use apenas letras minúsculas, dígitos e . - _, começando e terminando com letra ou dígito.'**
  String get registerLocalNameInvalid;

  /// Erro do campo de nome de usuário quando o servidor recusou por já existir. A segunda frase não é consolo: em uma federação, o identificador só é único dentro de um servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esse nome já é de outra pessoa neste servidor. O mesmo nome em outro servidor está livre.'**
  String get registerLocalNameTaken;

  /// Erro do campo de nome exibido. É o único caso que o esquema não recusa sozinho, e um nome em branco deixaria o leitor sem nada para mostrar.
  ///
  /// In pt_BR, this message translates to:
  /// **'O nome exibido não pode ficar em branco.'**
  String get registerDisplayNameInvalid;

  /// Erro do campo de e-mail quando o endereço não tem a forma mínima que o servidor aceita: algo, uma arroba, algo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Digite um endereço de e-mail válido.'**
  String get registerEmailInvalid;

  /// Erro do campo de e-mail quando o servidor recusou por já existir.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esse endereço já está cadastrado neste servidor.'**
  String get registerEmailTaken;

  /// Erro do campo de senha. O piso de oito caracteres é o que a NIST SP 800-63B pede de um segredo memorizado; a mensagem não pede maiúsculas nem símbolos porque o mesmo documento retirou essa exigência.
  ///
  /// In pt_BR, this message translates to:
  /// **'A senha precisa ter pelo menos 8 caracteres.'**
  String get registerPasswordInvalid;

  /// Erro geral da tela de cadastro, para uma falha que nenhum campo explica. O detalhe fica no log.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível criar a conta.'**
  String get registerFailed;

  /// Erro geral da tela de cadastro quando o servidor não respondeu. É o único desta tela em que tentar de novo pode dar certo sem mudar nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível falar com {domain}. Verifique sua conexão e tente de novo.'**
  String registerUnreachable(String domain);

  /// Título da seção da tela de configurações que reúne o que diz respeito à conta do leitor. As demais seções — dispositivos, servidores conhecidos, sincronização — chegam nas fases seguintes.
  ///
  /// In pt_BR, this message translates to:
  /// **'Conta'**
  String get settingsAccountSection;

  /// Linha que nomeia o leitor conectado pelo identificador federado inteiro, com as duas metades. Está ali porque o identificador diz também em qual servidor a biblioteca está, e o leitor pode ter contas em mais de um.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você está em {federatedId}.'**
  String settingsSignedInAs(String federatedId);

  /// Ação que encerra a sessão neste dispositivo. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sair'**
  String get settingsSignOut;

  /// Explicação abaixo da ação de sair. Diz o que sair não faz, porque o leitor não tem como saber: o acervo, as anotações e as mudanças ainda não enviadas continuam no dispositivo, e é isso que faz com que entrar de novo devolva a biblioteca em vez de uma vazia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sua biblioteca continua neste dispositivo. Sair encerra a sessão e não apaga nada.'**
  String get settingsSignOutExplanation;

  /// Ação secundária da tela de entrada, para quem não lembra a senha. Leva à tela que pede o envio de um código de recuperação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esqueci minha senha'**
  String get signInForgot;

  /// Título da tela que pede o envio de um código de recuperação para o endereço cadastrado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Recuperar a senha'**
  String get recoveryTitle;

  /// Parágrafo da tela de recuperação. A frase é condicional de propósito: o servidor responde a mesma coisa exista ou não a conta, e uma tela que dissesse o contrário transformaria este formulário em uma forma de descobrir quem tem conta ali.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe o e-mail da sua conta em {domain}. Se houver uma conta com esse endereço, enviaremos um código para redefinir a senha.'**
  String recoveryExplanation(String domain);

  /// Rótulo do campo de endereço na tela de recuperação.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail'**
  String get recoveryEmailLabel;

  /// Botão que pede ao servidor o envio do código de recuperação. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Enviar código'**
  String get recoverySubmit;

  /// Confirmação mostrada depois do pedido. Diz o mesmo exista ou não a conta — é a mesma promessa que o servidor faz, e uma confirmação que só aparecesse para endereços cadastrados diria por omissão exatamente o que a tela não deve dizer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Se houver uma conta com esse endereço, o código já está a caminho. Confira também a caixa de spam.'**
  String get recoverySent;

  /// Ação que leva à tela de redefinição, para quem já recebeu o código por e-mail. Está aqui porque o código chega em outro dispositivo tão frequentemente quanto neste.
  ///
  /// In pt_BR, this message translates to:
  /// **'Já tenho um código'**
  String get recoveryHaveCode;

  /// Erro mostrado quando o servidor não respondeu ao pedido de recuperação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível falar com {domain}. Verifique sua conexão e tente de novo.'**
  String recoveryUnreachable(String domain);

  /// Erro geral da tela de recuperação, para uma falha que o campo de e-mail não explica.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível pedir a recuperação.'**
  String get recoveryFailed;

  /// Título da tela que troca a senha usando o código recebido por e-mail.
  ///
  /// In pt_BR, this message translates to:
  /// **'Definir uma nova senha'**
  String get resetTitle;

  /// Parágrafo da tela de redefinição. A segunda frase é um aviso e não um detalhe: quem redefine a senha perdeu o controle da anterior, e deixar vivas as sessões que ela abriu deixaria conectado quem a tomou.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cole o código que você recebeu por e-mail e escolha uma nova senha. Todas as sessões de todos os seus dispositivos serão encerradas.'**
  String get resetExplanation;

  /// Rótulo do campo onde o leitor cola o código recebido por e-mail.
  ///
  /// In pt_BR, this message translates to:
  /// **'Código de recuperação'**
  String get resetTokenLabel;

  /// Rótulo do campo da nova senha na tela de redefinição.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova senha'**
  String get resetPasswordLabel;

  /// Botão que gasta o código e grava a nova senha. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Redefinir senha'**
  String get resetSubmit;

  /// Erro do campo de código. O servidor responde a mesma coisa para um código que nunca existiu, um já gasto, um expirado e um de outra conta, porque distinguir seria contar algo sobre uma conta que quem pergunta não provou ser sua; a mensagem repete essa indistinção em vez de inventar uma explicação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esse código não vale. Ele pode ter expirado ou já ter sido usado — peça outro.'**
  String get resetTokenInvalid;

  /// Confirmação mostrada depois da redefinição, na tela de entrada para onde o leitor é levado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha redefinida. Entre com a nova senha.'**
  String get resetDone;

  /// Erro geral da tela de redefinição, para uma falha que nenhum dos dois campos explica.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível redefinir a senha.'**
  String get resetFailed;

  /// Título do estado vazio da tela da biblioteca, mostrado a quem ainda não importou nenhum livro. É a primeira tela que um leitor recém-cadastrado vê depois de entrar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sua biblioteca está vazia'**
  String get libraryEmptyTitle;

  /// Corpo do estado vazio da biblioteca. Diz o que fazer em seguida e, de passagem, a promessa central do aplicativo: o livro é gravado aqui primeiro e sincronizado depois, então importar sem rede funciona.
  ///
  /// In pt_BR, this message translates to:
  /// **'Importe um arquivo EPUB, PDF, MOBI, DJVU ou CBZ. Ele fica guardado neste dispositivo e é enviado ao seu servidor quando houver rede.'**
  String get libraryEmptyMessage;

  /// Título mostrado quando o leitor tem livros, mas nenhum deles está arquivado na estante escolhida. É diferente do estado vazio da biblioteca inteira: aqui o acervo não está vazio, o filtro é que não encontrou nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum livro nesta estante'**
  String get libraryFilterEmptyTitle;

  /// Corpo do estado vazio de uma estante, acompanhado do botão que volta para o acervo inteiro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você tem livros, mas nenhum está arquivado aqui.'**
  String get libraryFilterEmptyMessage;

  /// Rótulo do filtro que mostra o acervo inteiro, sem estante nenhuma escolhida. Aparece como o primeiro de uma fileira de estantes e também como o botão de saída do estado vazio de uma estante.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os livros'**
  String get libraryShowAll;

  /// Rótulo do menu que escolhe a ordem da lista de livros. Rótulo curto, usado como dica do botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ordenar'**
  String get librarySort;

  /// Opção de ordenação: o livro importado mais recentemente primeiro. É a ordem padrão, porque num acervo que cresce por importação a chegada mais nova é a mais procurada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionados recentemente'**
  String get librarySortRecent;

  /// Opção de ordenação: em ordem alfabética de título.
  ///
  /// In pt_BR, this message translates to:
  /// **'Título'**
  String get librarySortTitle;

  /// Opção de ordenação: em ordem alfabética de autor. Os livros cujo arquivo não disse o autor ficam no fim.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autor'**
  String get librarySortAuthor;

  /// Mostrado no lugar do autor quando o arquivo não disse qual é. É diferente de um autor em branco: um é ausência de informação e o outro seria uma afirmação de que não há autor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autor desconhecido'**
  String get libraryUnknownAuthor;

  /// Erro mostrado quando a consulta ao banco local falha. Não tem nada a ver com rede: o acervo é lido daqui, então uma falha aqui é do próprio dispositivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler sua biblioteca neste dispositivo.'**
  String get libraryReadFailed;

  /// Quantos livros a listagem atual tem. Aparece abaixo do título da tela e ao lado do nome de uma estante.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =0{Nenhum livro} =1{1 livro} other{{count} livros}}'**
  String libraryBookCount(int count);

  /// Ação que abre o seletor de arquivos do sistema para trazer um livro para o acervo. Aparece como botão flutuante na tela da biblioteca e como botão do estado vazio.
  ///
  /// In pt_BR, this message translates to:
  /// **'Importar um livro'**
  String get libraryImport;

  /// Erro mostrado quando o arquivo escolhido tem uma extensão que o aplicativo não sabe nomear. A lista é a mesma dos formatos que o contrato admite, e o formato é decidido pelo nome do arquivo porque o servidor guarda o que lhe dizem e nunca abre os bytes.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este aplicativo importa arquivos EPUB, PDF, MOBI, DJVU e CBZ.'**
  String get libraryImportUnsupported;

  /// Erro geral da importação, para uma falha que a extensão do arquivo não explica — o arquivo ficou ilegível no meio da cópia, ou não coube no dispositivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível importar o arquivo.'**
  String get libraryImportFailed;

  /// Confirmação mostrada depois de importar. Diz o nome com que o livro entrou, que é o que o arquivo dizia sobre si mesmo e pode não ser o que o leitor esperava — é a deixa para renomear.
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} entrou na sua biblioteca.'**
  String libraryImported(String title);

  /// Título da seção das configurações que mostra quanto espaço os livros guardados neste dispositivo ocupam e quais são eles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Armazenamento'**
  String get settingsStorageSection;

  /// Quanto os arquivos dos livros ocupam. Mostrado sozinho quando não há como saber o total disponível, que é o caso dos cinco alvos nativos.
  ///
  /// In pt_BR, this message translates to:
  /// **'{used} guardados neste dispositivo'**
  String storageUsed(String used);

  /// Quanto os arquivos ocupam do total que o navegador reservou para este aplicativo. Só aparece na web: nos alvos nativos não há como perguntar ao sistema quanto espaço resta, e um número inventado seria pior do que nenhum.
  ///
  /// In pt_BR, this message translates to:
  /// **'{used} de {quota} guardados neste dispositivo'**
  String storageUsedOfQuota(String used, String quota);

  /// Explicação da seção de armazenamento nos cinco alvos nativos, onde tudo é guardado por padrão e o controle serve para liberar espaço.
  ///
  /// In pt_BR, this message translates to:
  /// **'Seus livros ficam guardados aqui e abrem sem rede. Você pode liberar o espaço de um livro que já foi enviado ao servidor; ele volta quando você pedir.'**
  String get storageKeptExplanationNative;

  /// Explicação da seção de armazenamento na web, onde nada é guardado por padrão porque o navegador empresta o espaço e pode retomá-lo.
  ///
  /// In pt_BR, this message translates to:
  /// **'No navegador, um livro só fica guardado se você pedir. Os outros são lidos direto do servidor e precisam de rede.'**
  String get storageKeptExplanationWeb;

  /// Mostrado na seção de armazenamento quando o dispositivo não tem o arquivo de nenhum livro — o caso normal de uma instalação nova no navegador.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum arquivo guardado neste dispositivo.'**
  String get storageNothingKept;

  /// Ação que apaga o arquivo de um livro deste dispositivo, mantendo o registro dele na biblioteca. Nada é apagado do servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Liberar espaço'**
  String get storageRelease;

  /// Ação que baixa o arquivo de um livro e passa a guardá-lo, para que ele abra sem rede.
  ///
  /// In pt_BR, this message translates to:
  /// **'Guardar neste dispositivo'**
  String get storageKeep;

  /// Recusa mostrada quando o leitor tenta liberar o espaço de um livro cujo arquivo ainda está na fila de envio. É a única cópia que existe, e apagá-la seria perder o livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este livro ainda não chegou ao servidor. Ele só existe aqui, então não dá para liberar o espaço dele agora.'**
  String get storageNotYetSent;

  /// Erro geral ao liberar o espaço de um livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível liberar o espaço deste livro.'**
  String get storageReleaseFailed;

  /// Erro geral ao baixar e guardar o arquivo de um livro — sem rede, sem espaço, ou o servidor não tem o arquivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível guardar este livro neste dispositivo.'**
  String get storageKeepFailed;

  /// Um tamanho em quilobytes. O símbolo é o do SI e é o mesmo nos dois idiomas; o que muda é o separador decimal do número, que a formatação do idioma resolve.
  ///
  /// In pt_BR, this message translates to:
  /// **'{value} kB'**
  String bytesInKilobytes(String value);

  /// Um tamanho em megabytes.
  ///
  /// In pt_BR, this message translates to:
  /// **'{value} MB'**
  String bytesInMegabytes(String value);

  /// Um tamanho em gigabytes.
  ///
  /// In pt_BR, this message translates to:
  /// **'{value} GB'**
  String bytesInGigabytes(String value);

  /// Um tamanho em bytes, para um arquivo pequeno demais para um quilobyte.
  ///
  /// In pt_BR, this message translates to:
  /// **'{value} B'**
  String bytesExactly(String value);

  /// Título mostrado quando a tela de um livro é aberta e o livro não existe mais — outro dispositivo do leitor o apagou e a exclusão chegou aqui. É um estado e não um erro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este livro não está mais aqui'**
  String get ebookNotFoundTitle;

  /// Corpo da tela de um livro que não existe mais. Explica por que ele sumiu, para que o leitor não ache que o aplicativo perdeu alguma coisa.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ele foi apagado em outro dispositivo, e a exclusão chegou até aqui.'**
  String get ebookNotFoundMessage;

  /// Título da seção com os dados do livro — autor, editora, idioma, formato, tamanho e data de entrada no acervo. "Ficha" é o termo de biblioteca para o registro de uma obra.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ficha'**
  String get ebookMetadataSection;

  /// Rótulo do campo da editora, na ficha do livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editora'**
  String get ebookPublisher;

  /// Rótulo do campo do idioma, na ficha do livro. O valor é a etiqueta que o arquivo declarou, como pt-BR.
  ///
  /// In pt_BR, this message translates to:
  /// **'Idioma'**
  String get ebookLanguage;

  /// Rótulo do campo do formato do arquivo, na ficha do livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Formato'**
  String get ebookFormat;

  /// Rótulo do campo do tamanho do arquivo, na ficha do livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tamanho'**
  String get ebookSize;

  /// Rótulo da data em que o livro entrou no acervo do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionado em'**
  String get ebookImportedAt;

  /// Mostrado no lugar do formato quando o servidor conhece um formato que esta versão do aplicativo não sabe nomear. O livro continua listado e sincronizado; só não dá para dizer o que ele é.
  ///
  /// In pt_BR, this message translates to:
  /// **'Formato desconhecido'**
  String get ebookUnknownFormat;

  /// Título da seção que mostra em quais estantes e categorias o livro está arquivado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Estantes'**
  String get ebookShelvesSection;

  /// Mostrado na seção de estantes quando o livro não foi arquivado em nenhuma.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não está em nenhuma estante.'**
  String get ebookNoShelves;

  /// Título da seção que diz onde estão os bytes do livro: neste dispositivo, no servidor, ou ainda esperando para ser enviado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Arquivo'**
  String get ebookFileSection;

  /// Estado do arquivo quando este dispositivo tem os bytes e vai mantê-los.
  ///
  /// In pt_BR, this message translates to:
  /// **'Guardado neste dispositivo. Abre sem rede.'**
  String get ebookFileHere;

  /// Estado do arquivo quando os bytes estão aqui e o leitor não pediu para guardá-los — o caso do navegador, onde o arquivo foi baixado para leitura e não para ficar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Está neste dispositivo, mas não foi marcado para ficar.'**
  String get ebookFileHereNotKept;

  /// Estado do arquivo quando este dispositivo tem o registro do livro e não os bytes. É o estado normal de um livro que chegou por sincronização.
  ///
  /// In pt_BR, this message translates to:
  /// **'Está no servidor. Baixe para ler sem rede.'**
  String get ebookFileOnServer;

  /// Estado do arquivo quando ele ainda está na fila de envio. Diz ao leitor por que não dá para liberar o espaço dele: a cópia daqui é a única que existe.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ainda não enviado ao servidor. Este dispositivo tem a única cópia.'**
  String get ebookFileWaiting;

  /// Estado do arquivo enquanto o envio está em andamento, com a fração que o servidor já confirmou ter recebido.
  ///
  /// In pt_BR, this message translates to:
  /// **'Enviando ao servidor: {percent}%'**
  String ebookFileSending(String percent);

  /// Ação que traz os bytes do livro do servidor para este dispositivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixar'**
  String get ebookDownload;

  /// Rótulo do progresso enquanto o arquivo está sendo baixado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixando: {percent}%'**
  String ebookDownloading(String percent);

  /// Ação que desiste do download em andamento. O que já chegou é descartado, porque um pedaço de arquivo não tem nome em um repositório endereçado pelo conteúdo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get ebookCancelDownload;

  /// Erro geral de download.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível baixar este livro.'**
  String get ebookDownloadFailed;

  /// Resposta do servidor quando ele replica os registros do leitor sem os arquivos. É um estado legítimo — a cópia barata que um leitor mais provavelmente quer em um servidor que não é dele — e não uma falha.
  ///
  /// In pt_BR, this message translates to:
  /// **'O servidor não tem o arquivo deste livro.'**
  String get ebookNotOnServer;

  /// Título da seção com os metadados que o formato carregava e o contrato não nomeia — série, ISBN, assuntos. Fica separada da ficha porque o conteúdo varia de arquivo para arquivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que o arquivo trazia'**
  String get ebookExtraSection;

  /// Ação que abre o formulário de edição dos metadados de um livro. Rótulo curto, na barra da tela do livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar'**
  String get ebookEdit;

  /// Título da tela que edita os metadados de um livro. "Ficha" é o termo de biblioteca para o registro de uma obra.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar ficha'**
  String get ebookEditTitle;

  /// Rótulo do campo do título, no formulário de edição. É o único campo obrigatório: uma obra sem título é recusada pelo contrato e pelo banco.
  ///
  /// In pt_BR, this message translates to:
  /// **'Título'**
  String get ebookTitleLabel;

  /// Rótulo do campo do autor, no formulário de edição. Deixar em branco apaga o autor, o que é diferente de não mexer no campo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autor'**
  String get ebookAuthorLabel;

  /// Erro do campo do título quando o leitor o apaga. Uma obra sem título é recusada pelo contrato e pela restrição da coluna, então o formulário recusa antes.
  ///
  /// In pt_BR, this message translates to:
  /// **'O título não pode ficar em branco.'**
  String get ebookTitleRequired;

  /// Botão que grava as alterações da ficha. Grava neste dispositivo; o servidor fica sabendo na próxima sincronização.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get ebookEditSave;

  /// Confirmação depois de salvar. Diz onde a alteração foi gravada, porque é a promessa central do aplicativo: a alteração vale aqui agora e chega ao servidor depois.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ficha salva neste dispositivo.'**
  String get ebookEditSaved;

  /// Erro geral ao salvar a ficha de um livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível salvar a ficha.'**
  String get ebookEditFailed;

  /// Explicação da seção de metadados extras no formulário. Diz o que costuma aparecer ali, já que o conteúdo varia de arquivo para arquivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que o arquivo trazia além da ficha — série, ISBN, assuntos. Cada linha é um nome e um valor.'**
  String get ebookEditExtraExplanation;

  /// Rótulo do campo com o nome de um metadado extra — a chave, como "series" ou "isbn".
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome'**
  String get ebookEditExtraName;

  /// Rótulo do campo com o valor de um metadado extra.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get ebookEditExtraValue;

  /// Ação que acrescenta uma linha vazia à lista de metadados extras.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar'**
  String get ebookEditExtraAdd;

  /// Ação que apaga uma linha da lista de metadados extras.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover'**
  String get ebookEditExtraRemove;

  /// Mostrado no lugar do campo quando o valor de um metadado extra é uma lista ou um número — por exemplo os assuntos, que o EPUB traz como lista. O formulário edita texto; o resto é preservado sem ser tocado, em vez de ser transformado em texto e perder o que era.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este valor não é texto e foi mantido como estava.'**
  String get ebookEditExtraNotText;
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

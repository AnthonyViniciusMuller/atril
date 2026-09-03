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

  /// Ação que exclui um livro do acervo do leitor. Rótulo curto, no menu da tela do livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir'**
  String get ebookDelete;

  /// Título da confirmação de exclusão. Pergunta porque a exclusão vale em todos os dispositivos do leitor, não só neste.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir este livro?'**
  String get ebookDeleteConfirmTitle;

  /// Corpo da confirmação de exclusão. Diz as duas coisas que decidem se o leitor confirma: o alcance da exclusão e o fato de que desfazer é barato — internamente porque a exclusão é uma lápide e não uma remoção.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ele sai do seu acervo em todos os seus dispositivos. Dá para desfazer logo em seguida.'**
  String get ebookDeleteConfirmMessage;

  /// Confirmação mostrada depois de excluir, junto com a ação de desfazer.
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} foi excluído.'**
  String ebookDeleted(String title);

  /// Ação que traz o livro de volta logo depois de excluí-lo. Rótulo curto, no aviso da exclusão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desfazer'**
  String get ebookDeleteUndo;

  /// Erro geral ao excluir um livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível excluir este livro.'**
  String get ebookDeleteFailed;

  /// Erro mostrado quando desfazer uma exclusão falhou. Nomeia o livro porque a mensagem aparece sobre a biblioteca, longe da tela dele.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível trazer {title} de volta.'**
  String ebookRestoreFailed(String title);

  /// Confirmação mostrada depois de desfazer uma exclusão.
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} voltou para o acervo.'**
  String ebookRestored(String title);

  /// Título da tela que administra as estantes e as categorias do leitor. Aparece também como rótulo da ação que leva até ela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Estantes'**
  String get shelvesTitle;

  /// Cabeçalho da lista das estantes — os agrupamentos que o leitor montou. Fica separado das categorias porque as duas coisas são a mesma estrutura com significados diferentes, e misturá-las na tela seria apagar a diferença.
  ///
  /// In pt_BR, this message translates to:
  /// **'Estantes'**
  String get shelvesCollections;

  /// Cabeçalho da lista das categorias — os assuntos sob os quais o leitor arquivou obras. Uma estante é um agrupamento que o leitor montou; uma categoria é um assunto, e a tela não confunde os dois.
  ///
  /// In pt_BR, this message translates to:
  /// **'Categorias'**
  String get shelvesCategories;

  /// Estado vazio da tela de estantes, mostrado a quem não criou nenhum agrupamento.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você ainda não criou nenhuma estante.'**
  String get shelvesEmpty;

  /// Corpo do estado vazio da tela de estantes. Explica a diferença entre os dois tipos, que é a única decisão que o leitor precisa tomar ao criar um.
  ///
  /// In pt_BR, this message translates to:
  /// **'Uma estante é um agrupamento que você monta; uma categoria é um assunto. Os dois arquivam as mesmas obras de jeitos diferentes.'**
  String get shelvesEmptyMessage;

  /// Ação que abre o formulário de criação de uma estante ou categoria.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova estante'**
  String get shelvesCreate;

  /// Título do formulário quando ele está editando um agrupamento que já existe.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar estante'**
  String get shelvesEditTitle;

  /// Rótulo do campo do nome da estante. É o único campo obrigatório.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome'**
  String get shelvesNameLabel;

  /// Erro do campo do nome quando ele fica vazio. Um agrupamento sem nome é recusado pelo contrato e pela restrição da coluna, então o formulário recusa antes.
  ///
  /// In pt_BR, this message translates to:
  /// **'O nome não pode ficar em branco.'**
  String get shelvesNameRequired;

  /// Rótulo do campo opcional que descreve a estante — o que o leitor guarda nela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Para que serve'**
  String get shelvesDescriptionLabel;

  /// Opção do seletor de tipo: um agrupamento que o leitor montou.
  ///
  /// In pt_BR, this message translates to:
  /// **'Estante'**
  String get shelvesKindCollection;

  /// Opção do seletor de tipo: um assunto sob o qual o leitor arquiva obras.
  ///
  /// In pt_BR, this message translates to:
  /// **'Categoria'**
  String get shelvesKindCategory;

  /// Botão que grava a estante, criada ou editada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get shelvesSave;

  /// Erro geral ao criar ou editar uma estante.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível salvar esta estante.'**
  String get shelvesSaveFailed;

  /// Ação que exclui uma estante. Rótulo curto, no menu de cada linha da lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir'**
  String get shelvesDelete;

  /// Confirmação depois de excluir uma estante, junto com a ação de desfazer. Diz numa frase só que os livros ficam, porque é exatamente o medo que impede alguém de arrumar o próprio acervo — e porque duas mensagens juntadas com um espaço em Dart seriam uma frase montada fora do arquivo de tradução. A concordância é feminina porque "estante" é feminino em português; a mesma mensagem serve para uma categoria, que também é.
  ///
  /// In pt_BR, this message translates to:
  /// **'{name} foi excluída. Os livros continuam no acervo.'**
  String shelvesDeleted(String name);

  /// Erro geral ao excluir uma estante.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível excluir esta estante.'**
  String get shelvesDeleteFailed;

  /// Quantos livros estão arquivados em uma estante, mostrado abaixo do nome dela.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =0{Nenhum livro} =1{1 livro} other{{count} livros}}'**
  String shelvesCount(int count);

  /// Ação que abre a lista de estantes e categorias para marcar em quais o livro fica arquivado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolher estantes'**
  String get ebookShelvesEdit;

  /// Título da caixa que marca e desmarca as estantes de um livro. Cada marca vale imediatamente neste dispositivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Arquivar em'**
  String get ebookShelvesDialogTitle;

  /// Mostrado na caixa de estantes quando o leitor não tem nenhum agrupamento para escolher.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você ainda não criou nenhuma estante.'**
  String get ebookShelvesNone;

  /// Erro geral ao arquivar ou desarquivar um livro em uma estante.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível mudar as estantes deste livro.'**
  String get ebookShelvesFailed;

  /// Ação que abre o campo de busca na barra da biblioteca. Rótulo curto, usado como dica do botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar'**
  String get librarySearch;

  /// Dica dentro do campo de busca. Diz onde a busca procura: título e autor, que são as duas coisas de que um leitor se lembra. Editora e idioma ficam de fora de propósito — buscar por elas devolveria a casa inteira por causa de uma palavra.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar por título ou autor'**
  String get librarySearchHint;

  /// Ação que apaga o que foi digitado e fecha o campo de busca.
  ///
  /// In pt_BR, this message translates to:
  /// **'Limpar a busca'**
  String get librarySearchClear;

  /// Rótulo do menu que restringe a listagem a um formato de arquivo. Rótulo curto, usado como dica do botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Formato'**
  String get libraryFilterFormat;

  /// Opção do menu de formatos que desfaz a restrição e mostra o acervo inteiro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os formatos'**
  String get libraryAllFormats;

  /// Título mostrado quando o leitor tem livros e nenhum deles combina com a busca ou com o filtro de formato. É diferente do estado vazio da biblioteca e do de uma estante vazia: aqui foi o que se pediu que não achou nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nada encontrado'**
  String get libraryNoMatchesTitle;

  /// Corpo do estado sem resultados, acompanhado do botão que desfaz todos os filtros de uma vez.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum livro do seu acervo combina com o que você pediu.'**
  String get libraryNoMatchesMessage;

  /// Ação que desfaz de uma vez a busca, o formato e a estante escolhidos. É um botão só porque quem está olhando para uma lista vazia não deveria ter que desfazer três coisas uma a uma para descobrir qual delas era o problema.
  ///
  /// In pt_BR, this message translates to:
  /// **'Limpar os filtros'**
  String get libraryClearFilters;

  /// Ação que abre o leitor a partir da tela de um livro. Rótulo curto de botão; é o verbo da UC04.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ler'**
  String get readerOpen;

  /// Ação que fecha o leitor e volta para a tela do livro. Diz para onde vai, e não apenas «voltar», porque o leitor pode ter chegado aqui de mais de um lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Voltar ao livro'**
  String get readerBack;

  /// Ação que abre o sumário do livro. É o nome que a própria editoração usa em português; «índice» seria o remissivo, no fim do volume.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sumário'**
  String get readerContents;

  /// Título mostrado quando o arquivo não traz documento de navegação. Não é falha: há livros publicados assim.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem sumário'**
  String get readerContentsEmptyTitle;

  /// Corpo do estado sem sumário. Diz que a ausência é do arquivo e não do aplicativo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este arquivo não traz um sumário navegável.'**
  String get readerContentsEmptyMessage;

  /// Ação que volta uma página. Rótulo usado como dica do botão e como rótulo de acessibilidade.
  ///
  /// In pt_BR, this message translates to:
  /// **'Página anterior'**
  String get readerPreviousPage;

  /// Ação que avança uma página. Rótulo usado como dica do botão e como rótulo de acessibilidade.
  ///
  /// In pt_BR, this message translates to:
  /// **'Próxima página'**
  String get readerNextPage;

  /// Quanto do livro já foi percorrido, mostrado na barra inferior do leitor. O número vem do índice de localizações do próprio motor.
  ///
  /// In pt_BR, this message translates to:
  /// **'{percent}% lido'**
  String readerProgress(Object percent);

  /// Quanto do livro já foi lido, como valor de uma barra de progresso para leitores de tela. É só o número e o sinal: o framework exige que este valor seja lido como número, então nenhuma palavra entra aqui.
  ///
  /// In pt_BR, this message translates to:
  /// **'{percent}%'**
  String readingPercentValue(int percent);

  /// Nome da barra de progresso para quem usa leitor de tela. É o que a barra mede; quanto já foi lido vai à parte, como valor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Progresso da leitura'**
  String get readingProgressLabel;

  /// Descrição, para leitores de tela, do toque sobre a página. A página em si é do motor de leitura e não tem rótulo nenhum.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mostrar ou ocultar os controles'**
  String get readerToggleChrome;

  /// Mostrado enquanto o arquivo é lido e entregue ao motor. Um EPUB grande leva alguns segundos, e uma tela silenciosa nesse intervalo parece travada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Abrindo o livro…'**
  String get readerOpening;

  /// Título mostrado ao abrir um livro cujo registro está aqui e cujos bytes não. É o estado comum de um livro ainda não baixado, e no navegador de todo livro que o leitor não pediu para guardar.
  ///
  /// In pt_BR, this message translates to:
  /// **'O arquivo não está neste dispositivo'**
  String get readerNotOnDeviceTitle;

  /// Corpo do estado sem arquivo, acompanhado da ação que faz o download. Diz o que se ganha com isso, e não apenas o que fazer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixe o arquivo para poder ler offline.'**
  String get readerNotOnDeviceMessage;

  /// Título mostrado ao tentar ler um livro que não é EPUB. O «ainda» é deliberado: o formato é importado, listado e sincronizado, e só a leitura falta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este formato ainda não abre aqui'**
  String get readerFormatTitle;

  /// Corpo do estado de formato não suportado. Diz o que continua funcionando, porque o livro não está perdido — só não abre.
  ///
  /// In pt_BR, this message translates to:
  /// **'Por enquanto o Atril abre apenas EPUB. Este livro continua no seu acervo, sincronizado e com o progresso registrado.'**
  String get readerFormatMessage;

  /// Título mostrado quando o motor recusou o arquivo ou a leitura falhou por outro motivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível abrir o livro'**
  String get readerFailedTitle;

  /// Corpo padrão do estado de falha ao abrir um livro, quando o motivo não é nenhum dos que têm frase própria. Não repete a mensagem técnica do erro, que vai para o log.
  ///
  /// In pt_BR, this message translates to:
  /// **'O leitor não conseguiu abrir este arquivo. Tente de novo; se continuar, o arquivo pode estar incompleto.'**
  String get readerFailedMessage;

  /// Corpo mostrado quando o motor não respondeu dentro do prazo de abertura. É a única falha em que tentar de novo costuma resolver.
  ///
  /// In pt_BR, this message translates to:
  /// **'O leitor não respondeu a tempo. Isso costuma acontecer com arquivos muito grandes ou logo depois de abrir o aplicativo.'**
  String get readerTimedOutMessage;

  /// Corpo mostrado quando o motor recusou o arquivo em si, e não o formato. Diz que o registro do livro não se perde.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este arquivo é um EPUB que o leitor não conseguiu exibir. Ele pode estar corrompido ou incompleto, e o livro continua no seu acervo.'**
  String get readerFileBrokenMessage;

  /// Corpo mostrado quando o arquivo passa do tamanho que esta versão consegue ler inteiro na memória.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este arquivo é grande demais para ser aberto neste dispositivo.'**
  String get readerTooLargeMessage;

  /// Ação que repete a tentativa de abrir o livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tentar de novo'**
  String get readerRetry;

  /// Ação que traz o arquivo do livro para este dispositivo. Rótulo curto de botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Baixar'**
  String get readerDownload;

  /// Ação que abre os ajustes de leitura — tamanho da letra, entrelinha, margem e tema. Rótulo curto, usado como dica do botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aparência'**
  String get readerSettings;

  /// Dito uma vez no alto dos ajustes. O tamanho confortável num celular no ônibus não é o mesmo de um monitor a um braço de distância, e um ajuste que sincronizasse tornaria toda escolha errada no outro aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'Vale para este dispositivo. Não é sincronizado.'**
  String get readerSettingsExplanation;

  /// Rótulo do controle que aumenta e diminui a letra. Os valores são porcentagens do tamanho que o próprio livro pede.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tamanho da letra'**
  String get readerFontSize;

  /// O tamanho escolhido, mostrado ao lado do controle. É porcentagem porque o livro define o próprio corpo em unidades relativas.
  ///
  /// In pt_BR, this message translates to:
  /// **'{percent}%'**
  String readerFontSizeValue(Object percent);

  /// Rótulo do controle que afasta ou aproxima as linhas. É o termo tipográfico, e é o que um leitor brasileiro reconhece.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entrelinha'**
  String get readerLineHeight;

  /// Rótulo do controle que estreita ou alarga a mancha de texto na página.
  ///
  /// In pt_BR, this message translates to:
  /// **'Margem'**
  String get readerMargin;

  /// Rótulo do grupo que escolhe as cores da página.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tema'**
  String get readerTheme;

  /// Opção de tema que segue o modo claro ou escuro do aparelho. É o padrão: quem já pôs o aparelho no escuro à noite não deveria precisar dizer de novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Do sistema'**
  String get readerThemeSystem;

  /// Opção de tema: texto escuro sobre branco.
  ///
  /// In pt_BR, this message translates to:
  /// **'Claro'**
  String get readerThemeLight;

  /// Opção de tema: texto escuro sobre fundo quente. É pedido pelo nome e não corresponde a nada que o esquema de cores do aplicativo tenha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sépia'**
  String get readerThemeSepia;

  /// Opção de tema: texto claro sobre fundo quase preto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escuro'**
  String get readerThemeDark;

  /// Ajuste que permite mostrar duas páginas lado a lado quando há largura para isso. Numa janela estreita continua sendo uma só.
  ///
  /// In pt_BR, this message translates to:
  /// **'Duas páginas'**
  String get readerSpread;

  /// Título da faixa que reúne os livros em que a leitura já começou, no alto da biblioteca.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar lendo'**
  String get libraryContinueReading;

  /// Diz que a posição mostrada foi marcada aqui mesmo. Aparece junto com a porcentagem.
  ///
  /// In pt_BR, this message translates to:
  /// **'Neste dispositivo'**
  String get libraryContinueHere;

  /// Diz que a posição mostrada veio de outro aparelho do mesmo leitor. Não diz qual: nada aqui guarda os outros dispositivos ainda, e inventar um nome seria pior do que não dizer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Em outro dispositivo'**
  String get libraryContinueElsewhere;

  /// Quanto do livro foi percorrido, ao lado da barra na faixa de continuar lendo.
  ///
  /// In pt_BR, this message translates to:
  /// **'{percent}%'**
  String libraryContinuePercent(Object percent);

  /// Ação que grifa o trecho que o leitor acabou de selecionar na página. Aparece na barra que a seleção levanta, sobre o livro.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grifar'**
  String get readerHighlight;

  /// Ação que fecha a barra levantada por uma seleção sem marcar nada. Dica do botão; quem mudou de ideia não fez nada de errado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Dispensar a seleção'**
  String get readerSelectionDismiss;

  /// Aviso mostrado depois que um trecho é grifado. Vem acompanhado da ação de desfazer, porque grifar é o que o leitor veio fazer e perguntar antes seria duvidar do gesto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Trecho grifado.'**
  String get readerHighlighted;

  /// Ação que desfaz a marcação recém-feita, no aviso que a anuncia. Rótulo curto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desfazer'**
  String get readerMarkUndo;

  /// Erro mostrado quando uma marcação não pôde ser gravada na réplica local. Não é falha de rede: a marcação é escrita aqui e sincronizada depois.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível guardar a marcação.'**
  String get readerMarkFailed;

  /// Ação que anota o trecho selecionado — grifa e guarda o que o leitor escreveu sobre ele. Aparece na barra que a seleção levanta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anotar'**
  String get readerNote;

  /// Título da caixa em que o leitor escreve uma nota sobre o trecho selecionado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota'**
  String get readerNoteTitle;

  /// Rótulo do campo em que o leitor escreve a anotação. São as palavras dele, e não o trecho — o trecho está endereçado pelo localizador.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que você quer registrar'**
  String get readerNoteLabel;

  /// Dito abaixo do campo da nota. O contrato exige que uma nota tenha texto, e o leitor deve saber disso pelo campo e não por uma recusa depois.
  ///
  /// In pt_BR, this message translates to:
  /// **'Uma nota sem texto é uma nota vazia.'**
  String get readerNoteRequired;

  /// Ação que fecha a caixa da anotação sem guardar nada. Quem desistiu não fez nada de errado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get readerNoteCancel;

  /// Ação que guarda a anotação escrita. Fica desabilitada enquanto o campo estiver vazio.
  ///
  /// In pt_BR, this message translates to:
  /// **'Guardar'**
  String get readerNoteSave;

  /// Aviso mostrado depois que uma nota é guardada, acompanhado da ação de desfazer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota guardada.'**
  String get readerNoted;

  /// Ação que marca a página aberta para o leitor voltar a ela depois. Dica do botão na barra do leitor, quando a página ainda não está marcada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcar esta página'**
  String get readerBookmark;

  /// Ação que tira a marcação da página aberta. Dica do mesmo botão, quando a página já está marcada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desmarcar esta página'**
  String get readerBookmarkRemove;

  /// Aviso mostrado depois que a página é marcada. É dito porque o ícone acabou de mudar sob o dedo do leitor e as duas mudanças se parecem.
  ///
  /// In pt_BR, this message translates to:
  /// **'Página marcada.'**
  String get readerBookmarked;

  /// Aviso mostrado depois que a marcação da página é removida.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcação da página removida.'**
  String get readerBookmarkRemoved;

  /// Título da tela de marcações quando ela está restrita a um livro. A mesma tela sem restrição usa o rótulo da navegação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcações deste livro'**
  String get annotationsInThisBook;

  /// Filtro que mostra todas as marcações, de qualquer tipo. É o estado inicial da tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todas'**
  String get annotationsAll;

  /// Filtro que mostra só os grifos — trechos marcados sem nada escrito sobre eles.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grifos'**
  String get annotationsHighlights;

  /// Filtro que mostra só as notas — trechos sobre os quais o leitor escreveu algo. É *notas* e não *anotações* porque *Anotações* é o nome da tela inteira, que reúne os três tipos.
  ///
  /// In pt_BR, this message translates to:
  /// **'Notas'**
  String get annotationsNotes;

  /// Filtro que mostra só os marcadores de página — posições, sem trecho e sem texto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcadores'**
  String get annotationsBookmarks;

  /// Nome de um grifo, usado no cartão quando não há texto guardado para mostrar no lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grifo'**
  String get annotationsHighlight;

  /// Nome de uma nota, usado no cartão quando não há texto para mostrar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota'**
  String get annotationsNote;

  /// Nome de um marcador de página no cartão. Um marcador não tem texto: ele é um lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcador de página'**
  String get annotationsBookmark;

  /// Nome de uma marcação de um tipo que esta versão do aplicativo não sabe nomear — feita por uma versão mais nova e ainda assim do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcação'**
  String get annotationsUnknownKind;

  /// Rodapé do cartão na listagem de toda a biblioteca: o livro de onde a marcação veio e a data em que foi feita.
  ///
  /// In pt_BR, this message translates to:
  /// **'{title} · {date}'**
  String annotationsFromBook(String title, String date);

  /// Título do estado vazio da tela de marcações, quando o leitor ainda não marcou nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nada marcado ainda'**
  String get annotationsEmptyTitle;

  /// Explicação do estado vazio: diz para que servem as marcações e que elas acompanham o leitor entre aparelhos, que é o que a federação promete.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grifos, anotações e marcadores feitos durante a leitura aparecem aqui, e acompanham você para os seus outros aparelhos.'**
  String get annotationsEmptyMessage;

  /// Título mostrado quando existem marcações mas nenhuma do tipo escolhido no filtro. É frase diferente do vazio de verdade.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma marcação desse tipo'**
  String get annotationsNoneOfThisKindTitle;

  /// Explicação de que o vazio é do filtro e não do acervo, acompanhada da ação que devolve todas as marcações.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você tem marcações, mas nenhuma do tipo escolhido.'**
  String get annotationsNoneOfThisKindMessage;

  /// Ação que limpa o filtro por tipo e mostra todas as marcações de novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mostrar todas'**
  String get annotationsShowAll;

  /// Título mostrado quando a consulta às marcações falha. Elas estão neste aparelho, então não é falha de rede.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler as marcações'**
  String get annotationsFailedTitle;

  /// Explicação da falha de leitura das marcações, dizendo o que importa: nada foi perdido, só não pôde ser lido agora.
  ///
  /// In pt_BR, this message translates to:
  /// **'As marcações estão guardadas neste aparelho e a consulta a elas falhou. Nada foi perdido.'**
  String get annotationsFailedMessage;

  /// Dica do botão que abre o menu de ações de uma marcação — anotar, editar, remover.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que fazer com esta marcação'**
  String get annotationsActions;

  /// Ação que abre a caixa para mudar o texto de uma nota existente.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar a nota'**
  String get annotationsEdit;

  /// Ação que escreve algo sobre um grifo, o que o transforma em anotação. O campo já vem com o trecho guardado, para que nada suma sem o leitor ver.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anotar'**
  String get annotationsAddNote;

  /// Ação que remove uma marcação. Vem acompanhada de desfazer, porque a remoção é uma lápide e desfazê-la custa uma operação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover'**
  String get annotationsRemove;

  /// Aviso mostrado depois que uma marcação é removida, acompanhado da ação de desfazer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcação removida.'**
  String get annotationsRemoved;

  /// Ação que traz de volta a marcação recém-removida, no aviso que a anuncia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desfazer'**
  String get annotationsUndo;

  /// Aviso mostrado depois que o texto de uma marcação é guardado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota guardada.'**
  String get annotationsSaved;

  /// Título da caixa em que o texto de uma marcação é escrito ou alterado, na tela de marcações.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota'**
  String get annotationsNoteTitle;

  /// Dito abaixo do campo quando um grifo está virando anotação. O registro tem um único campo de texto e numa anotação ele é do leitor, então o trecho guardado dá lugar ao que ele escrever — e ele vê isso antes de guardar.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que ficar aqui substitui o trecho guardado: o registro tem um só campo de texto, e numa anotação ele é seu.'**
  String get annotationsPassageGivesWay;

  /// Título da seção da tela do livro que leva às marcações feitas nele.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcações'**
  String get ebookMarksSection;

  /// Ação, na tela de um livro, que abre a lista das marcações feitas nele.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ver as marcações'**
  String get ebookMarksOpen;

  /// Dica do botão que abre a escolha do formato de exportação. É a única ação da tela que trata de todas as marcações e não de uma.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar as marcações'**
  String get annotationsExport;

  /// Opção de exportação num arquivo para ler: títulos, citações e as palavras na ordem em que foram marcadas.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar em Markdown'**
  String get annotationsExportMarkdown;

  /// Opção de exportação num arquivo para um programa ler: o registro inteiro, com os nomes de campo do próprio contrato.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar em JSON'**
  String get annotationsExportJson;

  /// Linha escrita dentro do arquivo Markdown, logo abaixo do título, dizendo de onde e quando ele saiu.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportado do Atril em {date}'**
  String annotationsExportedAt(String date);

  /// Aviso mostrado depois que o arquivo de marcações é gravado onde o leitor escolheu.
  ///
  /// In pt_BR, this message translates to:
  /// **'Marcações exportadas.'**
  String get annotationsExported;

  /// Aviso mostrado quando o leitor pede a exportação sem ter marcado nada. Um arquivo com um título e nada embaixo não são os dados dele: é um arquivo para apagar depois.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não há nada marcado para exportar.'**
  String get annotationsNothingToExport;

  /// Erro mostrado quando o arquivo de marcações não pôde ser escrito no lugar escolhido.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível escrever o arquivo.'**
  String get annotationsExportFailed;

  /// Título da tela que mostra o estado da sincronização, e da seção das configurações que leva até ela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sincronização'**
  String get syncTitle;

  /// Ação, nas configurações, que abre a tela da sincronização.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ver o estado da sincronização'**
  String get syncOpen;

  /// Quantas alterações feitas aqui ainda não chegaram ao nó. É a resposta curta para a pergunta que a tela existe para responder: as minhas anotações estão só neste aparelho?
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =0{Nada esperando} =1{1 alteração esperando} other{{count} alterações esperando}}'**
  String syncPending(int count);

  /// Dito abaixo da contagem de alterações esperando. O leitor precisa saber que esperar não é perder.
  ///
  /// In pt_BR, this message translates to:
  /// **'Elas estão guardadas aqui e vão embora assim que este aparelho alcançar o nó. Nada se perde enquanto isso.'**
  String get syncPendingExplanation;

  /// Dito no lugar da explicação acima quando não há nada esperando.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tudo o que você fez já saiu daqui.'**
  String get syncNothingPending;

  /// Dito no lugar da data quando o aparelho nunca conseguiu falar com o nó — logo depois de entrar, ou depois de nunca ter havido rede.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este aparelho ainda não alcançou o nó.'**
  String get syncNever;

  /// Quando este aparelho alcançou o nó pela última vez. É uma data guardada, e não algo que se perde ao fechar o aplicativo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Falou com o nó em {date}, às {time}'**
  String syncLastReached(String date, String time);

  /// Estado do laço de sincronização quando ele não está tentando nem esperando para tentar: sem sessão, ou com o aplicativo em segundo plano.
  ///
  /// In pt_BR, this message translates to:
  /// **'Parado'**
  String get syncActivityIdle;

  /// Estado do laço de sincronização enquanto ele abre um canal.
  ///
  /// In pt_BR, this message translates to:
  /// **'Conectando…'**
  String get syncActivityConnecting;

  /// Estado do laço de sincronização com um canal aberto, que é quando o que se faz aqui sai na hora.
  ///
  /// In pt_BR, this message translates to:
  /// **'Conectado ao nó'**
  String get syncActivityLive;

  /// Estado do laço de sincronização depois que um canal caiu, enquanto ele espera para tentar outra vez.
  ///
  /// In pt_BR, this message translates to:
  /// **'Vai tentar de novo'**
  String get syncActivityWaiting;

  /// Ação que manda o aparelho tentar imediatamente, sem esperar o intervalo que ele mesmo tinha marcado. O leitor sabe algo que o aparelho não sabe — que a rede voltou.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sincronizar agora'**
  String get syncNow;

  /// Aviso mostrado quando o pedido de sincronizar agora não pôde ser feito.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível sincronizar agora.'**
  String get syncFailedNow;

  /// Dito quando a última falha foi de rede. É uma espera e não um problema para o leitor resolver.
  ///
  /// In pt_BR, this message translates to:
  /// **'O nó não respondeu. Este aparelho tenta de novo sozinho.'**
  String get syncWaitingOnNode;

  /// Dito quando a última falha não foi de rede, com o motivo que o nó deu. É escrito para quem der suporte, e não para o leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Algo deu errado da última vez: {reason}'**
  String syncSomethingWrong(String reason);

  /// Título da seção da tela de sincronização que mostra o que está acontecendo neste instante.
  ///
  /// In pt_BR, this message translates to:
  /// **'Agora'**
  String get syncStateSection;

  /// Título da seção da tela de sincronização que conta as alterações feitas aqui e ainda não entregues.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que ainda não saiu'**
  String get syncChangesSection;

  /// Título da seção que lista as alterações que o nó não aceitou. É a única coisa nesta tela que pede uma decisão do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Recusadas pelo nó'**
  String get syncRefusedSection;

  /// Dito acima da lista de alterações recusadas. O leitor precisa entender as duas metades: o que ele fez continua aqui, e não chegou a lugar nenhum.
  ///
  /// In pt_BR, this message translates to:
  /// **'O nó não aceitou estas alterações e não vai aceitar numa próxima tentativa. Elas continuam valendo neste aparelho e não vão chegar a nenhum outro.'**
  String get syncRefusedExplanation;

  /// Quantas alterações o nó recusou, dito na linha das configurações que leva a esta tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, =1{1 recusada pelo nó} other{{count} recusadas pelo nó}}'**
  String syncRefusedCount(int count);

  /// Dito no lugar do motivo quando o nó recusou sem explicar. O contrato permite, e um espaço em branco pareceria um erro desta tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'O nó não disse por quê.'**
  String get syncRefusedNoReason;

  /// Ação que faz o aparelho parar de guardar uma alteração recusada. Não desfaz nada do que o leitor escreveu: apaga o registro da entrega que não vai acontecer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descartar'**
  String get syncDiscard;

  /// Dito na confirmação do descarte. É a distinção que a tela inteira existe para deixar clara.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descartar não desfaz o que você fez. Só faz este aparelho parar de guardar uma entrega que não vai acontecer.'**
  String get syncDiscardExplanation;

  /// Título da confirmação do descarte de uma alteração recusada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descartar esta alteração?'**
  String get syncDiscardTitle;

  /// Aviso mostrado depois que uma alteração recusada deixa de ser guardada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Alteração descartada.'**
  String get syncDiscarded;

  /// Erro mostrado quando o descarte de uma alteração recusada não pôde ser feito.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível descartar.'**
  String get syncDiscardFailed;

  /// Ação que fecha a confirmação do descarte sem descartar nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get syncCancel;

  /// Como uma alteração recusada num livro é nomeada na lista. É o tipo de registro e não o título, porque o registro pode ser justamente o que o nó não conhece.
  ///
  /// In pt_BR, this message translates to:
  /// **'Um livro'**
  String get syncRecordEbook;

  /// Como uma alteração recusada numa estante é nomeada na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Uma estante'**
  String get syncRecordCollection;

  /// Como uma alteração recusada no arquivamento de um livro numa estante é nomeada na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Um livro numa estante'**
  String get syncRecordFiling;

  /// Como uma alteração recusada numa posição de leitura é nomeada na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Onde você parou'**
  String get syncRecordProgress;

  /// Como uma alteração recusada numa marcação é nomeada na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Uma marcação'**
  String get syncRecordAnnotation;

  /// Título da seção da tela de configurações que reúne os servidores conhecidos, as réplicas autorizadas e a mudança de servidor de origem. Palavra curta, usada como cabeçalho de seção.
  ///
  /// In pt_BR, this message translates to:
  /// **'Federação'**
  String get settingsFederationSection;

  /// Item da tela de configurações que leva ao catálogo de servidores que o leitor conhece. Também é o título dessa tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Servidores conhecidos'**
  String get settingsKnownServers;

  /// Subtítulo do item das configurações que leva ao catálogo de servidores. Uma frase dizendo o que o leitor vai encontrar lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os servidores que o seu servidor conhece e para os quais ele pode replicar.'**
  String get settingsKnownServersExplanation;

  /// Parágrafo de abertura da tela de servidores conhecidos, explicando o que o catálogo significa e por que a descoberta importa. RN03.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nada sai do seu servidor para um servidor que você não tenha nomeado aqui. Cada um destes foi descoberto pelo endereço que você digitou, e a chave que ele apresentou ficou registrada.'**
  String get federationServersExplanation;

  /// Mensagem mostrada na tela de servidores conhecidos quando o catálogo do servidor está vazio.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você ainda não adicionou nenhum servidor.'**
  String get federationServersEmpty;

  /// Mensagem mostrada na tela de servidores conhecidos quando a leitura do catálogo falhou. A tela lê direto do servidor, então não há uma lista antiga para mostrar no lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler o catálogo. O servidor não respondeu.'**
  String get federationServersFailed;

  /// Rótulo do botão que repete uma leitura do catálogo que falhou.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tentar de novo'**
  String get federationRetry;

  /// Rótulo do campo onde o leitor digita o domínio de um servidor que quer adicionar ao catálogo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Endereço do servidor'**
  String get federationAddLabel;

  /// Texto de exemplo dentro do campo de domínio, mostrando a forma esperada. É um domínio de exemplo e a palavra "exemplo" é o que muda entre os idiomas.
  ///
  /// In pt_BR, this message translates to:
  /// **'quire-b.exemplo'**
  String get federationAddHint;

  /// Rótulo do botão que descobre o domínio digitado e o adiciona ao catálogo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar'**
  String get federationAdd;

  /// Confirmação mostrada depois que um servidor entra no catálogo. O parâmetro é o domínio adicionado.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} foi adicionado.'**
  String federationAdded(String domain);

  /// Erro mostrado no campo de domínio quando o que foi digitado não tem a forma de um endereço, antes de qualquer requisição sair do aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'Isto não é um endereço de servidor.'**
  String get federationAddInvalid;

  /// Erro mostrado quando o servidor recusa a adição porque o domínio já consta do catálogo do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este servidor já está no seu catálogo.'**
  String get federationAddAlreadyKnown;

  /// Erro mostrado quando a adição falha por qualquer outro motivo — o servidor não respondeu, ou o domínio não publica o documento que o descobrimento lê.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível adicionar este servidor. Ele pode não publicar um documento de descobrimento.'**
  String get federationAddFailed;

  /// Marca mostrada na linha do servidor em que o leitor está registrado, para distingui-lo dos demais do catálogo.
  ///
  /// In pt_BR, this message translates to:
  /// **'O seu servidor'**
  String get federationServerOrigin;

  /// Rótulo do interruptor que diz se o servidor participa da replicação, no estado ligado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Participa da replicação'**
  String get federationServerActive;

  /// Subtítulo da linha de um servidor que o leitor desligou. Ele continua no catálogo e nada trafega para ele.
  ///
  /// In pt_BR, this message translates to:
  /// **'Fora da replicação'**
  String get federationServerInactive;

  /// Linha que mostra onde o servidor efetivamente responde, que pode ser um endereço diferente do domínio. O parâmetro é a URL base.
  ///
  /// In pt_BR, this message translates to:
  /// **'Responde em {url}'**
  String federationServerBaseUrl(String url);

  /// Linha que mostra o endereço gRPC que um par disca para replicar. O parâmetro é o par host:porta.
  ///
  /// In pt_BR, this message translates to:
  /// **'gRPC em {authority}'**
  String federationServerGrpc(String authority);

  /// Linha mostrada no lugar do endereço gRPC quando o servidor não publica nenhum. É um servidor que pode ser registrado e não pode receber replicação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não publica endereço gRPC — nada replica para ele.'**
  String get federationServerGrpcAbsent;

  /// Linha que mostra a impressão da chave pública fixada para o mTLS entre servidores. O parâmetro é a impressão inteira, na forma spki-sha256.
  ///
  /// In pt_BR, this message translates to:
  /// **'Chave {fingerprint}'**
  String federationServerFingerprint(String fingerprint);

  /// Linha mostrada no lugar da impressão da chave quando o servidor não publica nenhuma.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma chave fixada.'**
  String get federationServerFingerprintAbsent;

  /// Linha que diz quando o documento de descobrimento deste servidor foi lido pela última vez. Os dois parâmetros vêm da localização do sistema.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descoberto em {date}, às {time}'**
  String federationServerDiscovered(String date, String time);

  /// Linha mostrada no lugar da data de descobrimento quando o servidor nunca foi consultado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ainda não descoberto.'**
  String get federationServerNeverDiscovered;

  /// Rótulo da ação que lê de novo o documento de descobrimento de um servidor. É a única forma de a chave fixada mudar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Redescobrir'**
  String get federationRefresh;

  /// Confirmação mostrada depois de um redescobrimento em que nada mudou. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} foi redescoberto e a chave é a mesma.'**
  String federationRefreshed(String domain);

  /// Erro mostrado quando o redescobrimento falha — o servidor não respondeu, ou deixou de publicar o documento.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível redescobrir este servidor.'**
  String get federationRefreshFailed;

  /// Título do aviso mostrado quando um redescobrimento encontra uma chave diferente da que estava fixada.
  ///
  /// In pt_BR, this message translates to:
  /// **'A chave deste servidor mudou'**
  String get federationKeyChangedTitle;

  /// Corpo do aviso de chave trocada. Diz por que a decisão é do leitor: uma rotação e uma interceptação são idênticas vistas deste lado. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} apresenta agora uma chave diferente da que estava registrada. Isso acontece quando o operador troca o certificado — e é também o que se veria se alguém estivesse respondendo no lugar dele. Daqui não dá para saber qual dos dois é.'**
  String federationKeyChangedExplanation(String domain);

  /// Rótulo do botão que fecha o aviso de chave trocada. O aviso informa e não pede uma decisão, porque a nova chave já foi fixada pelo servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entendi'**
  String get federationKeyChangedUnderstood;

  /// Rótulo da ação que remove um servidor do catálogo do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esquecer'**
  String get federationForget;

  /// Título da confirmação de remoção de um servidor do catálogo. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'Esquecer {domain}?'**
  String federationForgetTitle(String domain);

  /// Corpo da confirmação de remoção. Diz o que a remoção alcança e o que não alcança, para que o leitor não a tome por um apagamento.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nada mais trafega para este servidor. O que ele já tiver recebido continua lá — esquecer não alcança o banco de outro operador.'**
  String get federationForgetExplanation;

  /// Confirmação mostrada depois que um servidor sai do catálogo. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} foi esquecido.'**
  String federationForgotten(String domain);

  /// Erro mostrado quando o servidor recusa a remoção porque uma autorização de réplica ainda nomeia esse servidor. Esquecer um par que ainda guarda uma cópia deixaria o leitor sem como revogá-la.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este servidor guarda uma cópia sua. Revogue a réplica antes de esquecê-lo.'**
  String get federationForgetRefused;

  /// Erro mostrado quando a remoção de um servidor falha por qualquer outro motivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível esquecer este servidor.'**
  String get federationForgetFailed;

  /// Erro mostrado quando o servidor recusa a mudança do interruptor que diz se um par participa da replicação.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível mudar a participação deste servidor.'**
  String get federationActiveFailed;

  /// Rótulo do botão que fecha uma confirmação da tela de federação sem fazer nada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get federationCancel;

  /// Item da tela de configurações que leva à tela onde o leitor autoriza um servidor a guardar uma cópia dos seus dados. Também é o título dessa tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Réplicas autorizadas'**
  String get settingsReplicas;

  /// Subtítulo do item das configurações que leva às réplicas autorizadas. Uma frase dizendo o que o leitor vai encontrar lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quem pode guardar uma cópia dos seus dados.'**
  String get settingsReplicasExplanation;

  /// Parágrafo de abertura da tela de réplicas autorizadas, dizendo o que uma autorização significa. RN03 e RF16.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autorizar um servidor é dizer que ele pode guardar uma cópia da sua biblioteca. Só os servidores nomeados aqui recebem alguma coisa.'**
  String get replicasExplanation;

  /// Nota permanente na tela de réplicas, dizendo o que a autorização alcança e o que não alcança. Desde a correção C22 o servidor de origem admite o leitor no outro nó ao entregar; o que continua fora do protocolo é o outro nó precisar ter a origem no próprio catálogo, e a tela diz isso em vez de parecer ter funcionado.
  ///
  /// In pt_BR, this message translates to:
  /// **'A permissão fica registrada no seu servidor, que avisa o outro na primeira vez que tiver algo a enviar. Aquele servidor só aceita se já conhecer o seu: alguém com conta lá precisa adicionar o seu servidor em Servidores conhecidos.'**
  String get replicasOutOfBand;

  /// Mensagem mostrada quando não há nenhuma autorização em vigor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum servidor guarda uma cópia dos seus dados.'**
  String get replicasNone;

  /// Mensagem mostrada quando a leitura das autorizações falhou. A tela lê direto do servidor, então não há uma lista antiga para mostrar no lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler as autorizações. O servidor não respondeu.'**
  String get replicasFailed;

  /// Cabeçalho da seção que lista as autorizações em vigor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Guardam uma cópia'**
  String get replicasGrantedSection;

  /// Cabeçalho da seção que lista as autorizações revogadas. Elas continuam visíveis porque são o que explica um servidor que ainda tem dados seus.
  ///
  /// In pt_BR, this message translates to:
  /// **'Guardaram uma cópia'**
  String get replicasRevokedSection;

  /// Parágrafo abaixo do cabeçalho das autorizações revogadas, dizendo por que elas continuam listadas e o que a revogação de fato faz.
  ///
  /// In pt_BR, this message translates to:
  /// **'A replicação parou. O que estes servidores já receberam continua com eles: revogar não alcança o banco de outro operador.'**
  String get replicasRevokedExplanation;

  /// Rótulo da autorização que cobre também os arquivos dos livros, na lista e na escolha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Metadados e arquivos'**
  String get replicasWithFiles;

  /// Rótulo da autorização que cobre apenas os registros — livros, estantes, marcações — e não os arquivos.
  ///
  /// In pt_BR, this message translates to:
  /// **'Só metadados'**
  String get replicasWithoutFiles;

  /// Frase que explica a opção de replicar também os arquivos, na escolha do que a réplica cobre.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tudo, inclusive os arquivos dos livros. Ocupa neste servidor o mesmo espaço que a sua biblioteca ocupa.'**
  String get replicasWithFilesExplanation;

  /// Frase que explica a opção de replicar só os metadados. Diz por que ela costuma ser a escolha certa num servidor de outro operador.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os seus livros, estantes e marcações — sem os arquivos. É a réplica barata, e costuma ser a que se quer num servidor que não é seu.'**
  String get replicasWithoutFilesExplanation;

  /// Linha que diz quando uma autorização foi concedida. O parâmetro vem da localização do sistema.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autorizado em {date}'**
  String replicasGrantedAt(String date);

  /// Rótulo da ação que abre a escolha de qual servidor conhecido passará a guardar uma cópia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autorizar um servidor'**
  String get replicasAuthorize;

  /// Título do diálogo em que o leitor escolhe, entre os servidores do catálogo, qual vai guardar uma cópia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Qual servidor'**
  String get replicasChooseServer;

  /// Mensagem mostrada no lugar da lista de candidatos quando não sobrou nenhum servidor para autorizar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os servidores do seu catálogo já estão autorizados. Adicione outro em Servidores conhecidos.'**
  String get replicasNoCandidates;

  /// Aviso na linha de um servidor candidato que não publica endereço gRPC. A autorização é aceita e nenhum dado chega lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não publica endereço gRPC — nada replica para ele.'**
  String get replicasCandidateUndialable;

  /// Título do diálogo em que o leitor escolhe se a réplica cobre os arquivos além dos metadados. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que {domain} vai guardar'**
  String replicasChooseWhat(String domain);

  /// Rótulo do botão que conclui a autorização de um servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Autorizar'**
  String get replicasConfirm;

  /// Confirmação mostrada depois que uma autorização é concedida. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} pode guardar uma cópia.'**
  String replicasAuthorized(String domain);

  /// Erro mostrado quando a concessão de uma autorização falha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível autorizar este servidor.'**
  String get replicasAuthorizeFailed;

  /// Rótulo da ação que retira de um servidor a permissão de guardar uma cópia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Revogar'**
  String get replicasRevoke;

  /// Título da confirmação de revogação de uma autorização. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'Revogar {domain}?'**
  String replicasRevokeTitle(String domain);

  /// Corpo da confirmação de revogação. Diz exatamente o que a revogação faz e o que ela não pode fazer, para que o leitor não a tome por um apagamento remoto.
  ///
  /// In pt_BR, this message translates to:
  /// **'A replicação para. O que este servidor já recebeu continua com ele — revogar não apaga nada do banco de outro operador, e é por isso que a autorização revogada continua na lista.'**
  String get replicasRevokeExplanation;

  /// Confirmação mostrada depois que uma autorização é revogada. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'{domain} não recebe mais nada.'**
  String replicasRevoked(String domain);

  /// Erro mostrado quando a revogação de uma autorização falha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível revogar esta autorização.'**
  String get replicasRevokeFailed;

  /// Item da tela de configurações que leva ao assistente de migração de servidor de origem. Também é o título dessa tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mudar de servidor de origem'**
  String get settingsMigrate;

  /// Subtítulo do item das configurações que leva à migração. Uma frase dizendo o que o leitor vai encontrar lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Levar a sua biblioteca para outro servidor.'**
  String get settingsMigrateExplanation;

  /// Título do primeiro passo do assistente de migração, o que explica a operação antes de pedir qualquer coisa.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que isto faz'**
  String get migrationStepWhat;

  /// Parágrafo principal do primeiro passo do assistente: por que a migração não depende do servidor de origem atual. RF17 e a independência que a correção C11 descreve.
  ///
  /// In pt_BR, this message translates to:
  /// **'A sua biblioteca inteira está neste aparelho, e é por isso que ela pode ir para outro servidor sem que o atual precise concordar — nem estar no ar. Nada é pedido a ele e nada se perde lá.'**
  String get migrationExplanation;

  /// Aviso do primeiro passo do assistente: a migração preserva os dados e não o nome. Os parâmetros são o nome local e o domínio atuais do leitor.
  ///
  /// In pt_BR, this message translates to:
  /// **'O seu identificador muda. A segunda metade dele é o domínio do servidor, então @{localName}:{domain} passa a ser outro nome — que guarda a mesma história.'**
  String migrationIdentifierChanges(String localName, String domain);

  /// Aviso do primeiro passo do assistente: as réplicas não seguem o leitor sozinhas. Correção C11.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os servidores que guardavam uma cópia sua precisam ser autorizados de novo, porque a autorização deles nomeia o identificador antigo.'**
  String get migrationReauthorize;

  /// Aviso do primeiro passo do assistente, dito sozinho e em uma frase curta, porque é a razão de a tela ser um assistente e não um botão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não dá para desfazer.'**
  String get migrationIrreversible;

  /// Título do passo do assistente em que o leitor informa o domínio do servidor de destino e cria a conta que terá lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Para onde'**
  String get migrationStepServer;

  /// Rótulo do campo onde o leitor digita o domínio do servidor para o qual está indo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Endereço do novo servidor'**
  String get migrationDomainLabel;

  /// Nota abaixo do campo de domínio, dizendo quando a conexão muda. Existe porque apontar o aparelho antes de o leitor confirmar o deixaria falando com um servidor onde ele não tem conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este aparelho só passa a falar com o novo servidor no último passo. Até lá ele continua no atual.'**
  String get migrationConnectsAtTheEnd;

  /// Rótulo do campo do nome local da conta que será criada no servidor de destino.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome de usuário no novo servidor'**
  String get migrationLocalNameLabel;

  /// Rótulo do campo do nome que o leitor usa para se apresentar na conta nova.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome exibido'**
  String get migrationDisplayNameLabel;

  /// Rótulo do campo do endereço de e-mail da conta nova, que é por onde a recuperação de senha passa a ser feita.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail'**
  String get migrationEmailLabel;

  /// Rótulo do campo da senha da conta nova. É uma credencial nova e não a senha antiga levada junto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha no novo servidor'**
  String get migrationPasswordLabel;

  /// Erro mostrado sob o campo de domínio do assistente quando o que foi digitado não tem a forma de um endereço.
  ///
  /// In pt_BR, this message translates to:
  /// **'Isto não é um endereço de servidor.'**
  String get migrationInvalidDomain;

  /// Erro mostrado sob o campo de nome de usuário do assistente quando ele não segue a regra do servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Use letras minúsculas, números e . - _ entre eles.'**
  String get migrationInvalidLocalName;

  /// Erro mostrado sob o campo de nome exibido do assistente quando ele está em branco ou é longo demais.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um nome.'**
  String get migrationInvalidDisplayName;

  /// Erro mostrado sob o campo de e-mail do assistente quando o endereço não tem a forma esperada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get migrationInvalidEmail;

  /// Erro mostrado sob o campo de senha do assistente quando ela é curta ou longa demais para o que o servidor aceita.
  ///
  /// In pt_BR, this message translates to:
  /// **'A senha precisa de pelo menos 8 caracteres.'**
  String get migrationInvalidPassword;

  /// Título do passo do assistente que lista os dispositivos levados na migração.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que vai junto'**
  String get migrationStepDevices;

  /// Parágrafo do passo dos dispositivos, explicando por que os identificadores viajam. Correção C11.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os seus aparelhos vão junto, com os identificadores que já têm. É o que permite que cada um continue de onde parou: toda alteração nomeia o aparelho que a fez.'**
  String get migrationDevicesExplanation;

  /// Marca na linha do dispositivo em que o assistente está sendo usado. É o primeiro da lista e o que recebe a sessão nova.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este aparelho'**
  String get migrationThisDevice;

  /// Nome dado a um dispositivo cujo nome o servidor atual não pôde informar. O parâmetro é o começo do identificador, para que dois deles possam ser distinguidos na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aparelho {handle}'**
  String migrationUnnamedDevice(String handle);

  /// Aviso do passo dos dispositivos quando o servidor de origem não respondeu e os identificadores foram recuperados dos relógios vetoriais guardados localmente.
  ///
  /// In pt_BR, this message translates to:
  /// **'O servidor atual não respondeu, então os nomes se perderam. Os identificadores vieram do histórico guardado aqui, que é a parte que não dá para recriar — você pode renomear cada aparelho depois.'**
  String get migrationDevicesUnnamed;

  /// Mensagem mostrada no passo dos dispositivos quando nem o servidor nem o histórico local puderam informar quais aparelhos existem.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível levantar os seus aparelhos.'**
  String get migrationDevicesFailed;

  /// Título do último passo do assistente, o que resume a operação e a executa.
  ///
  /// In pt_BR, this message translates to:
  /// **'Confirmar'**
  String get migrationStepConfirm;

  /// Resumo do último passo do assistente: qual identificador o leitor passa a ter e quantos aparelhos vão junto.
  ///
  /// In pt_BR, this message translates to:
  /// **'@{localName}:{domain} passa a ser a sua conta, com {count, plural, =1{1 aparelho} other{{count} aparelhos}} e toda a sua biblioteca.'**
  String migrationSummary(String localName, String domain, int count);

  /// Frase do último passo do assistente dizendo que a fila de envio e o histórico continuam. Limpá-los concluiria a migração descartando justamente o que está sendo migrado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nada é apagado deste aparelho. O que ainda não foi entregue continua na fila e é enviado ao novo servidor.'**
  String get migrationNothingIsCleared;

  /// Rótulo do botão que executa a migração, no último passo do assistente.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mudar de servidor'**
  String get migrationGo;

  /// Rótulo do botão que volta um passo no assistente.
  ///
  /// In pt_BR, this message translates to:
  /// **'Voltar'**
  String get migrationBack;

  /// Rótulo do botão que avança um passo no assistente.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar'**
  String get migrationNext;

  /// Confirmação mostrada quando a migração termina. O parâmetro é o identificador federado novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você agora é {federatedId}.'**
  String migrationDone(String federatedId);

  /// Erro mostrado quando a migração falha. Diz também que o aparelho voltou a apontar para o servidor anterior, que é o que evita um estado em que nenhuma chamada funciona.
  ///
  /// In pt_BR, this message translates to:
  /// **'A migração não aconteceu. Este aparelho continua no servidor de antes.'**
  String get migrationFailed;

  /// Erro mostrado quando o servidor de destino recusa a migração porque o nome local escolhido já pertence a outra pessoa lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este nome de usuário já existe naquele servidor.'**
  String get migrationNameTaken;

  /// Item da tela de configurações que leva à lista de dispositivos vinculados à conta. Também é o título dessa tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Seus aparelhos'**
  String get settingsDevices;

  /// Subtítulo do item das configurações que leva aos dispositivos. Uma frase dizendo o que o leitor vai encontrar lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quais aparelhos podem escrever na sua conta.'**
  String get settingsDevicesExplanation;

  /// Parágrafo de abertura da tela de dispositivos, dizendo por que a lista importa. RF11 e RN10: um relógio vetorial é indexado por identificador de dispositivo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cada alteração feita na sua biblioteca nomeia o aparelho que a fez. É por isso que esta lista existe: sem ela, um histórico teria nomes que ninguém consegue resolver.'**
  String get devicesExplanation;

  /// Mensagem mostrada quando a leitura dos dispositivos falhou. A tela lê direto do servidor, então não há uma lista antiga para mostrar no lugar.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler os seus aparelhos. O servidor não respondeu.'**
  String get devicesFailed;

  /// Marca na linha do aparelho em que a tela está sendo usada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este aparelho'**
  String get devicesThisOne;

  /// Estado de um aparelho que foi revogado. A palavra é deliberadamente "desvinculado" e não "excluído": a linha continua existindo, e é ela que dá nome ao identificador que aparece no histórico.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desvinculado'**
  String get devicesUnbound;

  /// Frase abaixo do estado de um aparelho revogado, explicando por que ele continua na lista.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não pode mais escrever. A linha fica, porque as alterações que ele fez continuam nomeando-o.'**
  String get devicesUnboundExplanation;

  /// Linha que diz quando um aparelho concluiu a última sincronização. É um diagnóstico: o que decide o que enviar é a posição no log, e não esta data.
  ///
  /// In pt_BR, this message translates to:
  /// **'Última sincronização em {date}'**
  String devicesLastSynced(String date);

  /// Linha mostrada no lugar da data de sincronização de um aparelho que nunca concluiu uma.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ainda não sincronizou.'**
  String get devicesNeverSynced;

  /// Rótulo da ação que muda o nome de um aparelho. É o único campo editável de um aparelho vinculado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Renomear'**
  String get devicesRename;

  /// Título do diálogo em que o leitor digita o novo nome de um aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'Renomear aparelho'**
  String get devicesRenameTitle;

  /// Rótulo do campo do novo nome de um aparelho, no diálogo de renomear.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome do aparelho'**
  String get devicesNameLabel;

  /// Erro mostrado no diálogo de renomear quando o nome está em branco ou é longo demais para a coluna do servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um nome.'**
  String get devicesNameInvalid;

  /// Confirmação mostrada depois que um aparelho é renomeado. O parâmetro é o nome novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Agora se chama {name}.'**
  String devicesRenamed(String name);

  /// Erro mostrado quando a renomeação de um aparelho falha no servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível renomear este aparelho.'**
  String get devicesRenameFailed;

  /// Rótulo da ação que retira de um aparelho o direito de escrever na conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desvincular'**
  String get devicesRevoke;

  /// Título da confirmação de revogação de um aparelho. O parâmetro é o nome do aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'Desvincular {name}?'**
  String devicesRevokeTitle(String name);

  /// Corpo da confirmação de revogação de um aparelho. Diz o que a revogação alcança e por que a linha continua existindo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ele deixa de poder escrever e as sessões dele acabam. Nada do que ele já escreveu é apagado, e a linha dele fica na lista — é ela que dá nome ao aparelho no histórico das suas alterações.'**
  String get devicesRevokeExplanation;

  /// Confirmação mostrada depois que um aparelho é desvinculado. O parâmetro é o nome do aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'{name} não pode mais escrever.'**
  String devicesRevoked(String name);

  /// Erro mostrado quando a revogação de um aparelho falha no servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível desvincular este aparelho.'**
  String get devicesRevokeFailed;

  /// Erro mostrado quando o leitor tenta desvincular o próprio aparelho em que está. Fazê-lo encerraria a sessão atual e todas as futuras, sem nada na tela para desfazer o ato.
  ///
  /// In pt_BR, this message translates to:
  /// **'Um aparelho não se desvincula sozinho. Faça isso a partir de outro aparelho seu.'**
  String get devicesCannotRevokeThisOne;

  /// Rótulo do botão que confirma o novo nome no diálogo de renomear um aparelho.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get devicesSave;

  /// Item da tela de configurações que leva à tela onde o leitor edita o nome exibido, o e-mail e a senha. Também é o título dessa tela.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sua conta'**
  String get settingsAccount;

  /// Subtítulo do item das configurações que leva à conta. Uma frase dizendo o que o leitor vai encontrar lá.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome, e-mail e senha.'**
  String get settingsAccountExplanation;

  /// Rótulo da linha que mostra o identificador federado completo do leitor, no formato @nome:servidor. Ele não é editável: as duas metades são o nome de usuário e o domínio do servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Identificador'**
  String get accountIdentifier;

  /// Frase abaixo do identificador federado, dizendo por que ele não pode ser editado ali. RN08.
  ///
  /// In pt_BR, this message translates to:
  /// **'As duas metades são o seu nome de usuário e o servidor onde você está registrado. Ele só muda mudando de servidor.'**
  String get accountIdentifierExplanation;

  /// Rótulo da linha e do campo do nome que o leitor usa para se apresentar. É o único campo da conta que se altera diretamente.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome exibido'**
  String get accountDisplayName;

  /// Rótulo da linha e do campo do endereço de e-mail da conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail'**
  String get accountEmail;

  /// Frase abaixo do e-mail, dizendo por que a troca exige senha. Correção C14: quem pode mudar o endereço pode receber a recuperação e depois definir a senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'É por aqui que a recuperação de senha passa, então mudá-lo pede a sua senha.'**
  String get accountEmailExplanation;

  /// Linha mostrada no lugar do endereço quando o servidor não informou nenhum. Acontece num nó que apenas replica o leitor, que guarda a linha sem endereço.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum e-mail registrado.'**
  String get accountEmailAbsent;

  /// Rótulo da linha que leva à troca de senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha'**
  String get accountPassword;

  /// Frase abaixo da senha, avisando o que a troca custa. O servidor encerra todas as sessões, e o contrato não diz isso — só o fluxo de recuperação diz.
  ///
  /// In pt_BR, this message translates to:
  /// **'Trocar a senha encerra a sua sessão em todos os aparelhos, inclusive neste.'**
  String get accountPasswordExplanation;

  /// Linha que diz quando a conta foi criada no servidor. O parâmetro vem da localização do sistema.
  ///
  /// In pt_BR, this message translates to:
  /// **'Conta criada em {date}'**
  String accountCreated(String date);

  /// Aviso mostrado quando a releitura da conta no servidor falha. O que está na tela veio do que este aparelho guardou no último acesso.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível ler a sua conta. O servidor não respondeu.'**
  String get accountFailed;

  /// Título do diálogo em que o leitor edita o nome exibido.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mudar o nome exibido'**
  String get accountEditName;

  /// Erro mostrado no diálogo do nome exibido quando ele está em branco ou é longo demais.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um nome.'**
  String get accountNameInvalid;

  /// Confirmação mostrada depois que o nome exibido muda. O parâmetro é o nome novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'Agora você aparece como {name}.'**
  String accountNameChanged(String name);

  /// Erro mostrado quando a troca do nome exibido falha no servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível mudar o nome exibido.'**
  String get accountNameFailed;

  /// Título do diálogo em que o leitor troca o endereço de e-mail, informando a senha atual.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mudar o e-mail'**
  String get accountEditEmail;

  /// Rótulo do campo da senha atual, usada como prova de que é o leitor e não apenas um aparelho destravado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha atual'**
  String get accountCurrentPassword;

  /// Erro mostrado no diálogo do e-mail quando o endereço não tem a forma esperada.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get accountEmailInvalid;

  /// Frase dentro do diálogo de troca de e-mail. O servidor avisa o endereço anterior, e essa é a parte que protege quem já teve a senha descoberta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Um aviso é enviado para o endereço antigo. É assim que você fica sabendo se não foi você quem trocou.'**
  String get accountEmailNotice;

  /// Confirmação mostrada depois que o endereço muda. O parâmetro é o endereço novo.
  ///
  /// In pt_BR, this message translates to:
  /// **'O e-mail agora é {email}.'**
  String accountEmailChanged(String email);

  /// Erro mostrado quando a troca de endereço falha no servidor por um motivo que não é a senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível mudar o e-mail.'**
  String get accountEmailFailed;

  /// Erro mostrado quando o servidor recusa o endereço novo porque ele já pertence a outra conta ali.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este e-mail já está registrado neste servidor.'**
  String get accountEmailRegistered;

  /// Título do diálogo em que o leitor troca a senha, informando a atual e a nova.
  ///
  /// In pt_BR, this message translates to:
  /// **'Trocar a senha'**
  String get accountEditPassword;

  /// Rótulo do campo da senha nova, no diálogo de troca de senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova senha'**
  String get accountNewPassword;

  /// Erro mostrado no diálogo de senha quando a nova senha é curta ou longa demais para o que o servidor aceita.
  ///
  /// In pt_BR, this message translates to:
  /// **'A senha precisa de pelo menos 8 caracteres.'**
  String get accountPasswordInvalid;

  /// Aviso dentro do diálogo de troca de senha, dizendo o que a troca custa e por que esse custo é o correto.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todas as suas sessões acabam, e você entra de novo em cada aparelho. É o que se quer quando se troca a senha por desconfiança.'**
  String get accountPasswordEndsSessions;

  /// Confirmação mostrada depois que a senha muda. A sessão deste aparelho acabou junto, então o leitor é levado de volta ao início.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha trocada. Entre de novo.'**
  String get accountPasswordChanged;

  /// Erro mostrado quando a troca de senha falha no servidor por um motivo que não é a senha atual.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível trocar a senha.'**
  String get accountPasswordFailed;

  /// Erro mostrado quando o servidor recusa a prova: a senha atual informada não confere. É a mesma recusa para a troca de e-mail, a troca de senha e a exclusão da conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Senha atual incorreta.'**
  String get accountWrongPassword;

  /// Rótulo do botão que confirma uma alteração num diálogo da tela da conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get accountSave;

  /// Item da tela da conta que leva à exclusão, e título da tela de exclusão.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir a conta'**
  String get accountDelete;

  /// Parágrafo principal da tela de exclusão da conta, dizendo o que a exclusão de fato remove.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remove você deste servidor, com tudo que está ligado à sua conta lá: os seus aparelhos, as suas credenciais e a sua biblioteca no servidor.'**
  String get accountDeleteExplanation;

  /// Cabeçalho da seção da tela de exclusão que lista o que é removido.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que a exclusão alcança'**
  String get accountDeleteReaches;

  /// Cabeçalho da seção da tela de exclusão que lista o que continua existindo depois dela. É a metade que costuma ser suposta errada.
  ///
  /// In pt_BR, this message translates to:
  /// **'O que ela não alcança'**
  String get accountDeleteDoesNotReach;

  /// Item da lista do que a exclusão alcança: a conta no servidor de origem. O parâmetro é o domínio.
  ///
  /// In pt_BR, this message translates to:
  /// **'A sua conta em {domain}'**
  String accountDeleteThisServer(String domain);

  /// Item da lista do que a exclusão não alcança: as réplicas autorizadas. RN03 é uma promessa sobre o que começa a ser replicado, não sobre o que já foi.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os servidores que já guardam uma cópia sua. Excluir não entra no banco de outro operador — nem revogar entrava.'**
  String get accountDeleteReplicas;

  /// Linha que nomeia os servidores que guardam uma cópia, quando o servidor conseguiu informá-los. O parâmetro é a lista de domínios separada por vírgula.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ainda com uma cópia: {domains}'**
  String accountDeleteReplicaNames(String domains);

  /// Item da lista do que a exclusão não alcança: a réplica local. A exclusão encerra a sessão e não apaga nada daqui, porque isso destruiria a única cópia do que o servidor nunca recebeu.
  ///
  /// In pt_BR, this message translates to:
  /// **'Os livros e as marcações neste aparelho. Eles são a sua cópia, e você pode exportar as marcações antes de sair.'**
  String get accountDeleteLocal;

  /// Aviso curto da tela de exclusão da conta, dito sozinho porque é a razão de a exclusão pedir a senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não dá para desfazer.'**
  String get accountDeleteIrreversible;

  /// Frase da tela de exclusão apontando para a migração. As duas chamadas existem separadas de propósito, e a diferença aparece quando quem chama se enganou sobre qual queria.
  ///
  /// In pt_BR, this message translates to:
  /// **'Se o que você quer é mudar de servidor levando a biblioteca, use Mudar de servidor de origem: são coisas diferentes.'**
  String get accountDeleteMigrateInstead;

  /// Rótulo do botão que executa a exclusão da conta.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir a minha conta'**
  String get accountDeleteConfirm;

  /// Rótulo do campo da senha na tela de exclusão. É a prova de que é o leitor e não apenas um aparelho destravado.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sua senha'**
  String get accountDeletePasswordLabel;

  /// Confirmação mostrada depois que a conta é excluída. O parâmetro é o domínio do servidor.
  ///
  /// In pt_BR, this message translates to:
  /// **'A sua conta em {domain} foi excluída.'**
  String accountDeleted(String domain);

  /// Erro mostrado quando a exclusão da conta falha no servidor por um motivo que não é a senha.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível excluir a conta.'**
  String get accountDeleteFailed;
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

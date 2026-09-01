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

  @override
  String get settingsAccountSection => 'Conta';

  @override
  String settingsSignedInAs(String federatedId) {
    return 'Você está em $federatedId.';
  }

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsSignOutExplanation =>
      'Sua biblioteca continua neste dispositivo. Sair encerra a sessão e não apaga nada.';

  @override
  String get signInForgot => 'Esqueci minha senha';

  @override
  String get recoveryTitle => 'Recuperar a senha';

  @override
  String recoveryExplanation(String domain) {
    return 'Informe o e-mail da sua conta em $domain. Se houver uma conta com esse endereço, enviaremos um código para redefinir a senha.';
  }

  @override
  String get recoveryEmailLabel => 'E-mail';

  @override
  String get recoverySubmit => 'Enviar código';

  @override
  String get recoverySent =>
      'Se houver uma conta com esse endereço, o código já está a caminho. Confira também a caixa de spam.';

  @override
  String get recoveryHaveCode => 'Já tenho um código';

  @override
  String recoveryUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
  }

  @override
  String get recoveryFailed => 'Não foi possível pedir a recuperação.';

  @override
  String get resetTitle => 'Definir uma nova senha';

  @override
  String get resetExplanation =>
      'Cole o código que você recebeu por e-mail e escolha uma nova senha. Todas as sessões de todos os seus dispositivos serão encerradas.';

  @override
  String get resetTokenLabel => 'Código de recuperação';

  @override
  String get resetPasswordLabel => 'Nova senha';

  @override
  String get resetSubmit => 'Redefinir senha';

  @override
  String get resetTokenInvalid =>
      'Esse código não vale. Ele pode ter expirado ou já ter sido usado — peça outro.';

  @override
  String get resetDone => 'Senha redefinida. Entre com a nova senha.';

  @override
  String get resetFailed => 'Não foi possível redefinir a senha.';

  @override
  String get libraryEmptyTitle => 'Sua biblioteca está vazia';

  @override
  String get libraryEmptyMessage =>
      'Importe um arquivo EPUB, PDF, MOBI, DJVU ou CBZ. Ele fica guardado neste dispositivo e é enviado ao seu servidor quando houver rede.';

  @override
  String get libraryFilterEmptyTitle => 'Nenhum livro nesta estante';

  @override
  String get libraryFilterEmptyMessage =>
      'Você tem livros, mas nenhum está arquivado aqui.';

  @override
  String get libraryShowAll => 'Todos os livros';

  @override
  String get librarySort => 'Ordenar';

  @override
  String get librarySortRecent => 'Adicionados recentemente';

  @override
  String get librarySortTitle => 'Título';

  @override
  String get librarySortAuthor => 'Autor';

  @override
  String get libraryUnknownAuthor => 'Autor desconhecido';

  @override
  String get libraryReadFailed =>
      'Não foi possível ler sua biblioteca neste dispositivo.';

  @override
  String libraryBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
      zero: 'Nenhum livro',
    );
    return '$_temp0';
  }

  @override
  String get libraryImport => 'Importar um livro';

  @override
  String get libraryImportUnsupported =>
      'Este aplicativo importa arquivos EPUB, PDF, MOBI, DJVU e CBZ.';

  @override
  String get libraryImportFailed => 'Não foi possível importar o arquivo.';

  @override
  String libraryImported(String title) {
    return '$title entrou na sua biblioteca.';
  }

  @override
  String get settingsStorageSection => 'Armazenamento';

  @override
  String storageUsed(String used) {
    return '$used guardados neste dispositivo';
  }

  @override
  String storageUsedOfQuota(String used, String quota) {
    return '$used de $quota guardados neste dispositivo';
  }

  @override
  String get storageKeptExplanationNative =>
      'Seus livros ficam guardados aqui e abrem sem rede. Você pode liberar o espaço de um livro que já foi enviado ao servidor; ele volta quando você pedir.';

  @override
  String get storageKeptExplanationWeb =>
      'No navegador, um livro só fica guardado se você pedir. Os outros são lidos direto do servidor e precisam de rede.';

  @override
  String get storageNothingKept => 'Nenhum arquivo guardado neste dispositivo.';

  @override
  String get storageRelease => 'Liberar espaço';

  @override
  String get storageKeep => 'Guardar neste dispositivo';

  @override
  String get storageNotYetSent =>
      'Este livro ainda não chegou ao servidor. Ele só existe aqui, então não dá para liberar o espaço dele agora.';

  @override
  String get storageReleaseFailed =>
      'Não foi possível liberar o espaço deste livro.';

  @override
  String get storageKeepFailed =>
      'Não foi possível guardar este livro neste dispositivo.';

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
  String get ebookNotFoundTitle => 'Este livro não está mais aqui';

  @override
  String get ebookNotFoundMessage =>
      'Ele foi apagado em outro dispositivo, e a exclusão chegou até aqui.';

  @override
  String get ebookMetadataSection => 'Ficha';

  @override
  String get ebookPublisher => 'Editora';

  @override
  String get ebookLanguage => 'Idioma';

  @override
  String get ebookFormat => 'Formato';

  @override
  String get ebookSize => 'Tamanho';

  @override
  String get ebookImportedAt => 'Adicionado em';

  @override
  String get ebookUnknownFormat => 'Formato desconhecido';

  @override
  String get ebookShelvesSection => 'Estantes';

  @override
  String get ebookNoShelves => 'Não está em nenhuma estante.';

  @override
  String get ebookFileSection => 'Arquivo';

  @override
  String get ebookFileHere => 'Guardado neste dispositivo. Abre sem rede.';

  @override
  String get ebookFileHereNotKept =>
      'Está neste dispositivo, mas não foi marcado para ficar.';

  @override
  String get ebookFileOnServer => 'Está no servidor. Baixe para ler sem rede.';

  @override
  String get ebookFileWaiting =>
      'Ainda não enviado ao servidor. Este dispositivo tem a única cópia.';

  @override
  String ebookFileSending(String percent) {
    return 'Enviando ao servidor: $percent%';
  }

  @override
  String get ebookDownload => 'Baixar';

  @override
  String ebookDownloading(String percent) {
    return 'Baixando: $percent%';
  }

  @override
  String get ebookCancelDownload => 'Cancelar';

  @override
  String get ebookDownloadFailed => 'Não foi possível baixar este livro.';

  @override
  String get ebookNotOnServer => 'O servidor não tem o arquivo deste livro.';

  @override
  String get ebookExtraSection => 'O que o arquivo trazia';

  @override
  String get ebookEdit => 'Editar';

  @override
  String get ebookEditTitle => 'Editar ficha';

  @override
  String get ebookTitleLabel => 'Título';

  @override
  String get ebookAuthorLabel => 'Autor';

  @override
  String get ebookTitleRequired => 'O título não pode ficar em branco.';

  @override
  String get ebookEditSave => 'Salvar';

  @override
  String get ebookEditSaved => 'Ficha salva neste dispositivo.';

  @override
  String get ebookEditFailed => 'Não foi possível salvar a ficha.';

  @override
  String get ebookEditExtraExplanation =>
      'O que o arquivo trazia além da ficha — série, ISBN, assuntos. Cada linha é um nome e um valor.';

  @override
  String get ebookEditExtraName => 'Nome';

  @override
  String get ebookEditExtraValue => 'Valor';

  @override
  String get ebookEditExtraAdd => 'Adicionar';

  @override
  String get ebookEditExtraRemove => 'Remover';

  @override
  String get ebookEditExtraNotText =>
      'Este valor não é texto e foi mantido como estava.';

  @override
  String get ebookDelete => 'Excluir';

  @override
  String get ebookDeleteConfirmTitle => 'Excluir este livro?';

  @override
  String get ebookDeleteConfirmMessage =>
      'Ele sai do seu acervo em todos os seus dispositivos. Dá para desfazer logo em seguida.';

  @override
  String ebookDeleted(String title) {
    return '$title foi excluído.';
  }

  @override
  String get ebookDeleteUndo => 'Desfazer';

  @override
  String get ebookDeleteFailed => 'Não foi possível excluir este livro.';

  @override
  String ebookRestored(String title) {
    return '$title voltou para o acervo.';
  }

  @override
  String get shelvesTitle => 'Estantes';

  @override
  String get shelvesCollections => 'Estantes';

  @override
  String get shelvesCategories => 'Categorias';

  @override
  String get shelvesEmpty => 'Você ainda não criou nenhuma estante.';

  @override
  String get shelvesEmptyMessage =>
      'Uma estante é um agrupamento que você monta; uma categoria é um assunto. Os dois arquivam as mesmas obras de jeitos diferentes.';

  @override
  String get shelvesCreate => 'Nova estante';

  @override
  String get shelvesEditTitle => 'Editar estante';

  @override
  String get shelvesNameLabel => 'Nome';

  @override
  String get shelvesNameRequired => 'O nome não pode ficar em branco.';

  @override
  String get shelvesDescriptionLabel => 'Para que serve';

  @override
  String get shelvesKindCollection => 'Estante';

  @override
  String get shelvesKindCategory => 'Categoria';

  @override
  String get shelvesSave => 'Salvar';

  @override
  String get shelvesSaveFailed => 'Não foi possível salvar esta estante.';

  @override
  String get shelvesDelete => 'Excluir';

  @override
  String shelvesDeleted(String name) {
    return '$name foi excluída. Os livros continuam no acervo.';
  }

  @override
  String get shelvesDeleteFailed => 'Não foi possível excluir esta estante.';

  @override
  String shelvesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
      zero: 'Nenhum livro',
    );
    return '$_temp0';
  }

  @override
  String get ebookShelvesEdit => 'Escolher estantes';

  @override
  String get ebookShelvesDialogTitle => 'Arquivar em';

  @override
  String get ebookShelvesNone => 'Você ainda não criou nenhuma estante.';

  @override
  String get ebookShelvesFailed =>
      'Não foi possível mudar as estantes deste livro.';

  @override
  String get librarySearch => 'Buscar';

  @override
  String get librarySearchHint => 'Buscar por título ou autor';

  @override
  String get librarySearchClear => 'Limpar a busca';

  @override
  String get libraryFilterFormat => 'Formato';

  @override
  String get libraryAllFormats => 'Todos os formatos';

  @override
  String get libraryNoMatchesTitle => 'Nada encontrado';

  @override
  String get libraryNoMatchesMessage =>
      'Nenhum livro do seu acervo combina com o que você pediu.';

  @override
  String get libraryClearFilters => 'Limpar os filtros';

  @override
  String get readerOpen => 'Ler';

  @override
  String get readerBack => 'Voltar ao livro';

  @override
  String get readerContents => 'Sumário';

  @override
  String get readerContentsEmptyTitle => 'Sem sumário';

  @override
  String get readerContentsEmptyMessage =>
      'Este arquivo não traz um sumário navegável.';

  @override
  String get readerPreviousPage => 'Página anterior';

  @override
  String get readerNextPage => 'Próxima página';

  @override
  String readerProgress(Object percent) {
    return '$percent% lido';
  }

  @override
  String get readerOpening => 'Abrindo o livro…';

  @override
  String get readerNotOnDeviceTitle => 'O arquivo não está neste dispositivo';

  @override
  String get readerNotOnDeviceMessage =>
      'Baixe o arquivo para poder ler offline.';

  @override
  String get readerFormatTitle => 'Este formato ainda não abre aqui';

  @override
  String get readerFormatMessage =>
      'Por enquanto o Atril abre apenas EPUB. Este livro continua no seu acervo, sincronizado e com o progresso registrado.';

  @override
  String get readerFailedTitle => 'Não foi possível abrir o livro';

  @override
  String get readerRetry => 'Tentar de novo';

  @override
  String get readerDownload => 'Baixar';

  @override
  String get readerSettings => 'Aparência';

  @override
  String get readerSettingsExplanation =>
      'Vale para este dispositivo. Não é sincronizado.';

  @override
  String get readerFontSize => 'Tamanho da letra';

  @override
  String readerFontSizeValue(Object percent) {
    return '$percent%';
  }

  @override
  String get readerLineHeight => 'Entrelinha';

  @override
  String get readerMargin => 'Margem';

  @override
  String get readerTheme => 'Tema';

  @override
  String get readerThemeSystem => 'Do sistema';

  @override
  String get readerThemeLight => 'Claro';

  @override
  String get readerThemeSepia => 'Sépia';

  @override
  String get readerThemeDark => 'Escuro';

  @override
  String get readerSpread => 'Duas páginas';

  @override
  String get libraryContinueReading => 'Continuar lendo';

  @override
  String get libraryContinueHere => 'Neste dispositivo';

  @override
  String get libraryContinueElsewhere => 'Em outro dispositivo';

  @override
  String libraryContinuePercent(Object percent) {
    return '$percent%';
  }

  @override
  String get readerHighlight => 'Grifar';

  @override
  String get readerSelectionDismiss => 'Dispensar a seleção';

  @override
  String get readerHighlighted => 'Trecho grifado.';

  @override
  String get readerMarkUndo => 'Desfazer';

  @override
  String get readerMarkFailed => 'Não foi possível guardar a marcação.';

  @override
  String get readerNote => 'Anotar';

  @override
  String get readerNoteTitle => 'Nota';

  @override
  String get readerNoteLabel => 'O que você quer registrar';

  @override
  String get readerNoteRequired => 'Uma nota sem texto é uma nota vazia.';

  @override
  String get readerNoteCancel => 'Cancelar';

  @override
  String get readerNoteSave => 'Guardar';

  @override
  String get readerNoted => 'Nota guardada.';

  @override
  String get readerBookmark => 'Marcar esta página';

  @override
  String get readerBookmarkRemove => 'Desmarcar esta página';

  @override
  String get readerBookmarked => 'Página marcada.';

  @override
  String get readerBookmarkRemoved => 'Marcação da página removida.';

  @override
  String get annotationsInThisBook => 'Marcações deste livro';

  @override
  String get annotationsAll => 'Todas';

  @override
  String get annotationsHighlights => 'Grifos';

  @override
  String get annotationsNotes => 'Notas';

  @override
  String get annotationsBookmarks => 'Marcadores';

  @override
  String get annotationsHighlight => 'Grifo';

  @override
  String get annotationsNote => 'Nota';

  @override
  String get annotationsBookmark => 'Marcador de página';

  @override
  String get annotationsUnknownKind => 'Marcação';

  @override
  String annotationsFromBook(String title, String date) {
    return '$title · $date';
  }

  @override
  String get annotationsEmptyTitle => 'Nada marcado ainda';

  @override
  String get annotationsEmptyMessage =>
      'Grifos, anotações e marcadores feitos durante a leitura aparecem aqui, e acompanham você para os seus outros aparelhos.';

  @override
  String get annotationsNoneOfThisKindTitle => 'Nenhuma marcação desse tipo';

  @override
  String get annotationsNoneOfThisKindMessage =>
      'Você tem marcações, mas nenhuma do tipo escolhido.';

  @override
  String get annotationsShowAll => 'Mostrar todas';

  @override
  String get annotationsFailedTitle => 'Não foi possível ler as marcações';

  @override
  String get annotationsFailedMessage =>
      'As marcações estão guardadas neste aparelho e a consulta a elas falhou. Nada foi perdido.';

  @override
  String get annotationsActions => 'O que fazer com esta marcação';

  @override
  String get annotationsEdit => 'Editar a nota';

  @override
  String get annotationsAddNote => 'Anotar';

  @override
  String get annotationsRemove => 'Remover';

  @override
  String get annotationsRemoved => 'Marcação removida.';

  @override
  String get annotationsUndo => 'Desfazer';

  @override
  String get annotationsSaved => 'Nota guardada.';

  @override
  String get annotationsNoteTitle => 'Nota';

  @override
  String get annotationsPassageGivesWay =>
      'O que ficar aqui substitui o trecho guardado: o registro tem um só campo de texto, e numa anotação ele é seu.';

  @override
  String get ebookMarksSection => 'Marcações';

  @override
  String get ebookMarksOpen => 'Ver as marcações';

  @override
  String get annotationsExport => 'Exportar as marcações';

  @override
  String get annotationsExportMarkdown => 'Exportar em Markdown';

  @override
  String get annotationsExportJson => 'Exportar em JSON';

  @override
  String annotationsExportedAt(String date) {
    return 'Exportado do Atril em $date';
  }

  @override
  String get annotationsExported => 'Marcações exportadas.';

  @override
  String get annotationsNothingToExport => 'Não há nada marcado para exportar.';

  @override
  String get annotationsExportFailed => 'Não foi possível escrever o arquivo.';

  @override
  String get syncTitle => 'Sincronização';

  @override
  String get syncOpen => 'Ver o estado da sincronização';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações esperando',
      one: '1 alteração esperando',
      zero: 'Nada esperando',
    );
    return '$_temp0';
  }

  @override
  String get syncPendingExplanation =>
      'Elas estão guardadas aqui e vão embora assim que este aparelho alcançar o nó. Nada se perde enquanto isso.';

  @override
  String get syncNothingPending => 'Tudo o que você fez já saiu daqui.';

  @override
  String get syncNever => 'Este aparelho ainda não alcançou o nó.';

  @override
  String syncLastReached(String date, String time) {
    return 'Falou com o nó em $date, às $time';
  }

  @override
  String get syncActivityIdle => 'Parado';

  @override
  String get syncActivityConnecting => 'Conectando…';

  @override
  String get syncActivityLive => 'Conectado ao nó';

  @override
  String get syncActivityWaiting => 'Vai tentar de novo';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncFailedNow => 'Não foi possível sincronizar agora.';

  @override
  String get syncWaitingOnNode =>
      'O nó não respondeu. Este aparelho tenta de novo sozinho.';

  @override
  String syncSomethingWrong(String reason) {
    return 'Algo deu errado da última vez: $reason';
  }

  @override
  String get syncStateSection => 'Agora';

  @override
  String get syncChangesSection => 'O que ainda não saiu';
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

  @override
  String get settingsAccountSection => 'Conta';

  @override
  String settingsSignedInAs(String federatedId) {
    return 'Você está em $federatedId.';
  }

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsSignOutExplanation =>
      'Sua biblioteca continua neste dispositivo. Sair encerra a sessão e não apaga nada.';

  @override
  String get signInForgot => 'Esqueci minha senha';

  @override
  String get recoveryTitle => 'Recuperar a senha';

  @override
  String recoveryExplanation(String domain) {
    return 'Informe o e-mail da sua conta em $domain. Se houver uma conta com esse endereço, enviaremos um código para redefinir a senha.';
  }

  @override
  String get recoveryEmailLabel => 'E-mail';

  @override
  String get recoverySubmit => 'Enviar código';

  @override
  String get recoverySent =>
      'Se houver uma conta com esse endereço, o código já está a caminho. Confira também a caixa de spam.';

  @override
  String get recoveryHaveCode => 'Já tenho um código';

  @override
  String recoveryUnreachable(String domain) {
    return 'Não foi possível falar com $domain. Verifique sua conexão e tente de novo.';
  }

  @override
  String get recoveryFailed => 'Não foi possível pedir a recuperação.';

  @override
  String get resetTitle => 'Definir uma nova senha';

  @override
  String get resetExplanation =>
      'Cole o código que você recebeu por e-mail e escolha uma nova senha. Todas as sessões de todos os seus dispositivos serão encerradas.';

  @override
  String get resetTokenLabel => 'Código de recuperação';

  @override
  String get resetPasswordLabel => 'Nova senha';

  @override
  String get resetSubmit => 'Redefinir senha';

  @override
  String get resetTokenInvalid =>
      'Esse código não vale. Ele pode ter expirado ou já ter sido usado — peça outro.';

  @override
  String get resetDone => 'Senha redefinida. Entre com a nova senha.';

  @override
  String get resetFailed => 'Não foi possível redefinir a senha.';

  @override
  String get libraryEmptyTitle => 'Sua biblioteca está vazia';

  @override
  String get libraryEmptyMessage =>
      'Importe um arquivo EPUB, PDF, MOBI, DJVU ou CBZ. Ele fica guardado neste dispositivo e é enviado ao seu servidor quando houver rede.';

  @override
  String get libraryFilterEmptyTitle => 'Nenhum livro nesta estante';

  @override
  String get libraryFilterEmptyMessage =>
      'Você tem livros, mas nenhum está arquivado aqui.';

  @override
  String get libraryShowAll => 'Todos os livros';

  @override
  String get librarySort => 'Ordenar';

  @override
  String get librarySortRecent => 'Adicionados recentemente';

  @override
  String get librarySortTitle => 'Título';

  @override
  String get librarySortAuthor => 'Autor';

  @override
  String get libraryUnknownAuthor => 'Autor desconhecido';

  @override
  String get libraryReadFailed =>
      'Não foi possível ler sua biblioteca neste dispositivo.';

  @override
  String libraryBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
      zero: 'Nenhum livro',
    );
    return '$_temp0';
  }

  @override
  String get libraryImport => 'Importar um livro';

  @override
  String get libraryImportUnsupported =>
      'Este aplicativo importa arquivos EPUB, PDF, MOBI, DJVU e CBZ.';

  @override
  String get libraryImportFailed => 'Não foi possível importar o arquivo.';

  @override
  String libraryImported(String title) {
    return '$title entrou na sua biblioteca.';
  }

  @override
  String get settingsStorageSection => 'Armazenamento';

  @override
  String storageUsed(String used) {
    return '$used guardados neste dispositivo';
  }

  @override
  String storageUsedOfQuota(String used, String quota) {
    return '$used de $quota guardados neste dispositivo';
  }

  @override
  String get storageKeptExplanationNative =>
      'Seus livros ficam guardados aqui e abrem sem rede. Você pode liberar o espaço de um livro que já foi enviado ao servidor; ele volta quando você pedir.';

  @override
  String get storageKeptExplanationWeb =>
      'No navegador, um livro só fica guardado se você pedir. Os outros são lidos direto do servidor e precisam de rede.';

  @override
  String get storageNothingKept => 'Nenhum arquivo guardado neste dispositivo.';

  @override
  String get storageRelease => 'Liberar espaço';

  @override
  String get storageKeep => 'Guardar neste dispositivo';

  @override
  String get storageNotYetSent =>
      'Este livro ainda não chegou ao servidor. Ele só existe aqui, então não dá para liberar o espaço dele agora.';

  @override
  String get storageReleaseFailed =>
      'Não foi possível liberar o espaço deste livro.';

  @override
  String get storageKeepFailed =>
      'Não foi possível guardar este livro neste dispositivo.';

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
  String get ebookNotFoundTitle => 'Este livro não está mais aqui';

  @override
  String get ebookNotFoundMessage =>
      'Ele foi apagado em outro dispositivo, e a exclusão chegou até aqui.';

  @override
  String get ebookMetadataSection => 'Ficha';

  @override
  String get ebookPublisher => 'Editora';

  @override
  String get ebookLanguage => 'Idioma';

  @override
  String get ebookFormat => 'Formato';

  @override
  String get ebookSize => 'Tamanho';

  @override
  String get ebookImportedAt => 'Adicionado em';

  @override
  String get ebookUnknownFormat => 'Formato desconhecido';

  @override
  String get ebookShelvesSection => 'Estantes';

  @override
  String get ebookNoShelves => 'Não está em nenhuma estante.';

  @override
  String get ebookFileSection => 'Arquivo';

  @override
  String get ebookFileHere => 'Guardado neste dispositivo. Abre sem rede.';

  @override
  String get ebookFileHereNotKept =>
      'Está neste dispositivo, mas não foi marcado para ficar.';

  @override
  String get ebookFileOnServer => 'Está no servidor. Baixe para ler sem rede.';

  @override
  String get ebookFileWaiting =>
      'Ainda não enviado ao servidor. Este dispositivo tem a única cópia.';

  @override
  String ebookFileSending(String percent) {
    return 'Enviando ao servidor: $percent%';
  }

  @override
  String get ebookDownload => 'Baixar';

  @override
  String ebookDownloading(String percent) {
    return 'Baixando: $percent%';
  }

  @override
  String get ebookCancelDownload => 'Cancelar';

  @override
  String get ebookDownloadFailed => 'Não foi possível baixar este livro.';

  @override
  String get ebookNotOnServer => 'O servidor não tem o arquivo deste livro.';

  @override
  String get ebookExtraSection => 'O que o arquivo trazia';

  @override
  String get ebookEdit => 'Editar';

  @override
  String get ebookEditTitle => 'Editar ficha';

  @override
  String get ebookTitleLabel => 'Título';

  @override
  String get ebookAuthorLabel => 'Autor';

  @override
  String get ebookTitleRequired => 'O título não pode ficar em branco.';

  @override
  String get ebookEditSave => 'Salvar';

  @override
  String get ebookEditSaved => 'Ficha salva neste dispositivo.';

  @override
  String get ebookEditFailed => 'Não foi possível salvar a ficha.';

  @override
  String get ebookEditExtraExplanation =>
      'O que o arquivo trazia além da ficha — série, ISBN, assuntos. Cada linha é um nome e um valor.';

  @override
  String get ebookEditExtraName => 'Nome';

  @override
  String get ebookEditExtraValue => 'Valor';

  @override
  String get ebookEditExtraAdd => 'Adicionar';

  @override
  String get ebookEditExtraRemove => 'Remover';

  @override
  String get ebookEditExtraNotText =>
      'Este valor não é texto e foi mantido como estava.';

  @override
  String get ebookDelete => 'Excluir';

  @override
  String get ebookDeleteConfirmTitle => 'Excluir este livro?';

  @override
  String get ebookDeleteConfirmMessage =>
      'Ele sai do seu acervo em todos os seus dispositivos. Dá para desfazer logo em seguida.';

  @override
  String ebookDeleted(String title) {
    return '$title foi excluído.';
  }

  @override
  String get ebookDeleteUndo => 'Desfazer';

  @override
  String get ebookDeleteFailed => 'Não foi possível excluir este livro.';

  @override
  String ebookRestored(String title) {
    return '$title voltou para o acervo.';
  }

  @override
  String get shelvesTitle => 'Estantes';

  @override
  String get shelvesCollections => 'Estantes';

  @override
  String get shelvesCategories => 'Categorias';

  @override
  String get shelvesEmpty => 'Você ainda não criou nenhuma estante.';

  @override
  String get shelvesEmptyMessage =>
      'Uma estante é um agrupamento que você monta; uma categoria é um assunto. Os dois arquivam as mesmas obras de jeitos diferentes.';

  @override
  String get shelvesCreate => 'Nova estante';

  @override
  String get shelvesEditTitle => 'Editar estante';

  @override
  String get shelvesNameLabel => 'Nome';

  @override
  String get shelvesNameRequired => 'O nome não pode ficar em branco.';

  @override
  String get shelvesDescriptionLabel => 'Para que serve';

  @override
  String get shelvesKindCollection => 'Estante';

  @override
  String get shelvesKindCategory => 'Categoria';

  @override
  String get shelvesSave => 'Salvar';

  @override
  String get shelvesSaveFailed => 'Não foi possível salvar esta estante.';

  @override
  String get shelvesDelete => 'Excluir';

  @override
  String shelvesDeleted(String name) {
    return '$name foi excluída. Os livros continuam no acervo.';
  }

  @override
  String get shelvesDeleteFailed => 'Não foi possível excluir esta estante.';

  @override
  String shelvesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
      zero: 'Nenhum livro',
    );
    return '$_temp0';
  }

  @override
  String get ebookShelvesEdit => 'Escolher estantes';

  @override
  String get ebookShelvesDialogTitle => 'Arquivar em';

  @override
  String get ebookShelvesNone => 'Você ainda não criou nenhuma estante.';

  @override
  String get ebookShelvesFailed =>
      'Não foi possível mudar as estantes deste livro.';

  @override
  String get librarySearch => 'Buscar';

  @override
  String get librarySearchHint => 'Buscar por título ou autor';

  @override
  String get librarySearchClear => 'Limpar a busca';

  @override
  String get libraryFilterFormat => 'Formato';

  @override
  String get libraryAllFormats => 'Todos os formatos';

  @override
  String get libraryNoMatchesTitle => 'Nada encontrado';

  @override
  String get libraryNoMatchesMessage =>
      'Nenhum livro do seu acervo combina com o que você pediu.';

  @override
  String get libraryClearFilters => 'Limpar os filtros';

  @override
  String get readerOpen => 'Ler';

  @override
  String get readerBack => 'Voltar ao livro';

  @override
  String get readerContents => 'Sumário';

  @override
  String get readerContentsEmptyTitle => 'Sem sumário';

  @override
  String get readerContentsEmptyMessage =>
      'Este arquivo não traz um sumário navegável.';

  @override
  String get readerPreviousPage => 'Página anterior';

  @override
  String get readerNextPage => 'Próxima página';

  @override
  String readerProgress(Object percent) {
    return '$percent% lido';
  }

  @override
  String get readerOpening => 'Abrindo o livro…';

  @override
  String get readerNotOnDeviceTitle => 'O arquivo não está neste dispositivo';

  @override
  String get readerNotOnDeviceMessage =>
      'Baixe o arquivo para poder ler offline.';

  @override
  String get readerFormatTitle => 'Este formato ainda não abre aqui';

  @override
  String get readerFormatMessage =>
      'Por enquanto o Atril abre apenas EPUB. Este livro continua no seu acervo, sincronizado e com o progresso registrado.';

  @override
  String get readerFailedTitle => 'Não foi possível abrir o livro';

  @override
  String get readerRetry => 'Tentar de novo';

  @override
  String get readerDownload => 'Baixar';

  @override
  String get readerSettings => 'Aparência';

  @override
  String get readerSettingsExplanation =>
      'Vale para este dispositivo. Não é sincronizado.';

  @override
  String get readerFontSize => 'Tamanho da letra';

  @override
  String readerFontSizeValue(Object percent) {
    return '$percent%';
  }

  @override
  String get readerLineHeight => 'Entrelinha';

  @override
  String get readerMargin => 'Margem';

  @override
  String get readerTheme => 'Tema';

  @override
  String get readerThemeSystem => 'Do sistema';

  @override
  String get readerThemeLight => 'Claro';

  @override
  String get readerThemeSepia => 'Sépia';

  @override
  String get readerThemeDark => 'Escuro';

  @override
  String get readerSpread => 'Duas páginas';

  @override
  String get libraryContinueReading => 'Continuar lendo';

  @override
  String get libraryContinueHere => 'Neste dispositivo';

  @override
  String get libraryContinueElsewhere => 'Em outro dispositivo';

  @override
  String libraryContinuePercent(Object percent) {
    return '$percent%';
  }

  @override
  String get readerHighlight => 'Grifar';

  @override
  String get readerSelectionDismiss => 'Dispensar a seleção';

  @override
  String get readerHighlighted => 'Trecho grifado.';

  @override
  String get readerMarkUndo => 'Desfazer';

  @override
  String get readerMarkFailed => 'Não foi possível guardar a marcação.';

  @override
  String get readerNote => 'Anotar';

  @override
  String get readerNoteTitle => 'Nota';

  @override
  String get readerNoteLabel => 'O que você quer registrar';

  @override
  String get readerNoteRequired => 'Uma nota sem texto é uma nota vazia.';

  @override
  String get readerNoteCancel => 'Cancelar';

  @override
  String get readerNoteSave => 'Guardar';

  @override
  String get readerNoted => 'Nota guardada.';

  @override
  String get readerBookmark => 'Marcar esta página';

  @override
  String get readerBookmarkRemove => 'Desmarcar esta página';

  @override
  String get readerBookmarked => 'Página marcada.';

  @override
  String get readerBookmarkRemoved => 'Marcação da página removida.';

  @override
  String get annotationsInThisBook => 'Marcações deste livro';

  @override
  String get annotationsAll => 'Todas';

  @override
  String get annotationsHighlights => 'Grifos';

  @override
  String get annotationsNotes => 'Notas';

  @override
  String get annotationsBookmarks => 'Marcadores';

  @override
  String get annotationsHighlight => 'Grifo';

  @override
  String get annotationsNote => 'Nota';

  @override
  String get annotationsBookmark => 'Marcador de página';

  @override
  String get annotationsUnknownKind => 'Marcação';

  @override
  String annotationsFromBook(String title, String date) {
    return '$title · $date';
  }

  @override
  String get annotationsEmptyTitle => 'Nada marcado ainda';

  @override
  String get annotationsEmptyMessage =>
      'Grifos, anotações e marcadores feitos durante a leitura aparecem aqui, e acompanham você para os seus outros aparelhos.';

  @override
  String get annotationsNoneOfThisKindTitle => 'Nenhuma marcação desse tipo';

  @override
  String get annotationsNoneOfThisKindMessage =>
      'Você tem marcações, mas nenhuma do tipo escolhido.';

  @override
  String get annotationsShowAll => 'Mostrar todas';

  @override
  String get annotationsFailedTitle => 'Não foi possível ler as marcações';

  @override
  String get annotationsFailedMessage =>
      'As marcações estão guardadas neste aparelho e a consulta a elas falhou. Nada foi perdido.';

  @override
  String get annotationsActions => 'O que fazer com esta marcação';

  @override
  String get annotationsEdit => 'Editar a nota';

  @override
  String get annotationsAddNote => 'Anotar';

  @override
  String get annotationsRemove => 'Remover';

  @override
  String get annotationsRemoved => 'Marcação removida.';

  @override
  String get annotationsUndo => 'Desfazer';

  @override
  String get annotationsSaved => 'Nota guardada.';

  @override
  String get annotationsNoteTitle => 'Nota';

  @override
  String get annotationsPassageGivesWay =>
      'O que ficar aqui substitui o trecho guardado: o registro tem um só campo de texto, e numa anotação ele é seu.';

  @override
  String get ebookMarksSection => 'Marcações';

  @override
  String get ebookMarksOpen => 'Ver as marcações';

  @override
  String get annotationsExport => 'Exportar as marcações';

  @override
  String get annotationsExportMarkdown => 'Exportar em Markdown';

  @override
  String get annotationsExportJson => 'Exportar em JSON';

  @override
  String annotationsExportedAt(String date) {
    return 'Exportado do Atril em $date';
  }

  @override
  String get annotationsExported => 'Marcações exportadas.';

  @override
  String get annotationsNothingToExport => 'Não há nada marcado para exportar.';

  @override
  String get annotationsExportFailed => 'Não foi possível escrever o arquivo.';

  @override
  String get syncTitle => 'Sincronização';

  @override
  String get syncOpen => 'Ver o estado da sincronização';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações esperando',
      one: '1 alteração esperando',
      zero: 'Nada esperando',
    );
    return '$_temp0';
  }

  @override
  String get syncPendingExplanation =>
      'Elas estão guardadas aqui e vão embora assim que este aparelho alcançar o nó. Nada se perde enquanto isso.';

  @override
  String get syncNothingPending => 'Tudo o que você fez já saiu daqui.';

  @override
  String get syncNever => 'Este aparelho ainda não alcançou o nó.';

  @override
  String syncLastReached(String date, String time) {
    return 'Falou com o nó em $date, às $time';
  }

  @override
  String get syncActivityIdle => 'Parado';

  @override
  String get syncActivityConnecting => 'Conectando…';

  @override
  String get syncActivityLive => 'Conectado ao nó';

  @override
  String get syncActivityWaiting => 'Vai tentar de novo';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncFailedNow => 'Não foi possível sincronizar agora.';

  @override
  String get syncWaitingOnNode =>
      'O nó não respondeu. Este aparelho tenta de novo sozinho.';

  @override
  String syncSomethingWrong(String reason) {
    return 'Algo deu errado da última vez: $reason';
  }

  @override
  String get syncStateSection => 'Agora';

  @override
  String get syncChangesSection => 'O que ainda não saiu';
}

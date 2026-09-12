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
  String get signInPasswordShow => 'Mostrar a senha';

  @override
  String get signInPasswordHide => 'Ocultar a senha';

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
  String get ebookPlacesSection => 'Onde você parou';

  @override
  String get ebookPlaceNoPercent => 'Sem porcentagem';

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
  String ebookRestoreFailed(String title) {
    return 'Não foi possível trazer $title de volta.';
  }

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
  String readerProgress(int percent) {
    return '$percent% lido';
  }

  @override
  String readingPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get readingProgressLabel => 'Progresso da leitura';

  @override
  String get readerToggleChrome => 'Mostrar ou ocultar os controles';

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
  String get readerFailedMessage =>
      'O leitor não conseguiu abrir este arquivo. Tente de novo; se continuar, o arquivo pode estar incompleto.';

  @override
  String get readerTimedOutMessage =>
      'O leitor não respondeu a tempo. Isso costuma acontecer com arquivos muito grandes ou logo depois de abrir o aplicativo.';

  @override
  String get readerFileBrokenMessage =>
      'Este arquivo é um EPUB que o leitor não conseguiu exibir. Ele pode estar corrompido ou incompleto, e o livro continua no seu acervo.';

  @override
  String get readerTooLargeMessage =>
      'Este arquivo é grande demais para ser aberto neste dispositivo.';

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
  String readerFontSizeValue(int percent) {
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
  String libraryContinuePercent(int percent) {
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

  @override
  String get syncRefusedSection => 'Recusadas pelo nó';

  @override
  String get syncRefusedExplanation =>
      'O nó não aceitou estas alterações e não vai aceitar numa próxima tentativa. Elas continuam valendo neste aparelho e não vão chegar a nenhum outro.';

  @override
  String syncRefusedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recusadas pelo nó',
      one: '1 recusada pelo nó',
    );
    return '$_temp0';
  }

  @override
  String get syncRefusedNoReason => 'O nó não disse por quê.';

  @override
  String get syncDiscard => 'Descartar';

  @override
  String get syncDiscardExplanation =>
      'Descartar não desfaz o que você fez. Só faz este aparelho parar de guardar uma entrega que não vai acontecer.';

  @override
  String get syncDiscardTitle => 'Descartar esta alteração?';

  @override
  String get syncDiscarded => 'Alteração descartada.';

  @override
  String get syncDiscardFailed => 'Não foi possível descartar.';

  @override
  String get syncCancel => 'Cancelar';

  @override
  String get syncRecordEbook => 'Um livro';

  @override
  String get syncRecordCollection => 'Uma estante';

  @override
  String get syncRecordFiling => 'Um livro numa estante';

  @override
  String get syncRecordProgress => 'Onde você parou';

  @override
  String get syncRecordAnnotation => 'Uma marcação';

  @override
  String get settingsFederationSection => 'Federação';

  @override
  String get settingsKnownServers => 'Servidores conhecidos';

  @override
  String get settingsKnownServersExplanation =>
      'Os servidores que o seu servidor conhece e para os quais ele pode replicar.';

  @override
  String get federationServersExplanation =>
      'Nada sai do seu servidor para um servidor que você não tenha nomeado aqui. Cada um destes foi descoberto pelo endereço que você digitou, e a chave que ele apresentou ficou registrada.';

  @override
  String get federationServersEmpty =>
      'Você ainda não adicionou nenhum servidor.';

  @override
  String get federationServersFailed =>
      'Não foi possível ler o catálogo. O servidor não respondeu.';

  @override
  String get federationRetry => 'Tentar de novo';

  @override
  String get federationAddLabel => 'Endereço do servidor';

  @override
  String get federationAddHint => 'quire-b.exemplo';

  @override
  String get federationAdd => 'Adicionar';

  @override
  String federationAdded(String domain) {
    return '$domain foi adicionado.';
  }

  @override
  String get federationAddInvalid => 'Isto não é um endereço de servidor.';

  @override
  String get federationAddAlreadyKnown =>
      'Este servidor já está no seu catálogo.';

  @override
  String get federationAddFailed =>
      'Não foi possível adicionar este servidor. Ele pode não publicar um documento de descobrimento.';

  @override
  String get federationServerOrigin => 'O seu servidor';

  @override
  String get federationServerActive => 'Participa da replicação';

  @override
  String get federationServerInactive => 'Fora da replicação';

  @override
  String get federationServerReplicate => 'Replicar com este servidor';

  @override
  String federationServerBaseUrl(String url) {
    return 'Responde em $url';
  }

  @override
  String federationServerGrpc(String authority) {
    return 'gRPC em $authority';
  }

  @override
  String get federationServerGrpcAbsent =>
      'Não publica endereço gRPC — nada replica para ele.';

  @override
  String federationServerFingerprint(String fingerprint) {
    return 'Chave $fingerprint';
  }

  @override
  String get federationServerFingerprintAbsent => 'Nenhuma chave fixada.';

  @override
  String federationServerDiscovered(String date, String time) {
    return 'Descoberto em $date, às $time';
  }

  @override
  String get federationServerNeverDiscovered => 'Ainda não descoberto.';

  @override
  String get federationRefresh => 'Redescobrir';

  @override
  String federationRefreshed(String domain) {
    return '$domain foi redescoberto e a chave é a mesma.';
  }

  @override
  String get federationRefreshFailed =>
      'Não foi possível redescobrir este servidor.';

  @override
  String get federationKeyChangedTitle => 'A chave deste servidor mudou';

  @override
  String federationKeyChangedExplanation(String domain) {
    return '$domain apresenta agora uma chave diferente da que estava registrada. Isso acontece quando o operador troca o certificado — e é também o que se veria se alguém estivesse respondendo no lugar dele. Daqui não dá para saber qual dos dois é.';
  }

  @override
  String get federationKeyChangedUnderstood => 'Entendi';

  @override
  String get federationForget => 'Esquecer';

  @override
  String federationForgetTitle(String domain) {
    return 'Esquecer $domain?';
  }

  @override
  String get federationForgetExplanation =>
      'Nada mais trafega para este servidor. O que ele já tiver recebido continua lá — esquecer não alcança o banco de outro operador.';

  @override
  String federationForgotten(String domain) {
    return '$domain foi esquecido.';
  }

  @override
  String get federationForgetRefused =>
      'Este servidor guarda uma cópia sua. Revogue a réplica antes de esquecê-lo.';

  @override
  String get federationForgetFailed =>
      'Não foi possível esquecer este servidor.';

  @override
  String get federationActiveFailed =>
      'Não foi possível mudar a participação deste servidor.';

  @override
  String get federationCancel => 'Cancelar';

  @override
  String get settingsReplicas => 'Réplicas autorizadas';

  @override
  String get settingsReplicasExplanation =>
      'Quem pode guardar uma cópia dos seus dados.';

  @override
  String get replicasExplanation =>
      'Autorizar um servidor é dizer que ele pode guardar uma cópia da sua biblioteca. Só os servidores nomeados aqui recebem alguma coisa.';

  @override
  String get replicasOutOfBand =>
      'A permissão fica registrada no seu servidor, que avisa o outro na primeira vez que tiver algo a enviar. Aquele servidor só aceita se já conhecer o seu: alguém com conta lá precisa adicionar o seu servidor em Servidores conhecidos.';

  @override
  String get replicasNone => 'Nenhum servidor guarda uma cópia dos seus dados.';

  @override
  String get replicasFailed =>
      'Não foi possível ler as autorizações. O servidor não respondeu.';

  @override
  String get replicasGrantedSection => 'Guardam uma cópia';

  @override
  String get replicasRevokedSection => 'Guardaram uma cópia';

  @override
  String get replicasRevokedExplanation =>
      'A replicação parou. O que estes servidores já receberam continua com eles: revogar não alcança o banco de outro operador.';

  @override
  String get replicasWithFiles => 'Metadados e arquivos';

  @override
  String get replicasWithoutFiles => 'Só metadados';

  @override
  String get replicasWithFilesExplanation =>
      'Tudo, inclusive os arquivos dos livros. Ocupa neste servidor o mesmo espaço que a sua biblioteca ocupa.';

  @override
  String get replicasWithoutFilesExplanation =>
      'Os seus livros, estantes e marcações — sem os arquivos. É a réplica barata, e costuma ser a que se quer num servidor que não é seu.';

  @override
  String replicasGrantedAt(String date) {
    return 'Autorizado em $date';
  }

  @override
  String get replicasAuthorize => 'Autorizar um servidor';

  @override
  String get replicasChooseServer => 'Qual servidor';

  @override
  String get replicasNoCandidates =>
      'Todos os servidores do seu catálogo já estão autorizados. Adicione outro em Servidores conhecidos.';

  @override
  String get replicasCandidateUndialable =>
      'Não publica endereço gRPC — nada replica para ele.';

  @override
  String replicasChooseWhat(String domain) {
    return 'O que $domain vai guardar';
  }

  @override
  String get replicasConfirm => 'Autorizar';

  @override
  String replicasAuthorized(String domain) {
    return '$domain pode guardar uma cópia.';
  }

  @override
  String get replicasAuthorizeFailed =>
      'Não foi possível autorizar este servidor.';

  @override
  String get replicasRevoke => 'Revogar';

  @override
  String replicasRevokeTitle(String domain) {
    return 'Revogar $domain?';
  }

  @override
  String get replicasRevokeExplanation =>
      'A replicação para. O que este servidor já recebeu continua com ele — revogar não apaga nada do banco de outro operador, e é por isso que a autorização revogada continua na lista.';

  @override
  String replicasRevoked(String domain) {
    return '$domain não recebe mais nada.';
  }

  @override
  String get replicasRevokeFailed =>
      'Não foi possível revogar esta autorização.';

  @override
  String get settingsMigrate => 'Mudar de servidor de origem';

  @override
  String get settingsMigrateExplanation =>
      'Levar a sua biblioteca para outro servidor.';

  @override
  String get migrationStepWhat => 'O que isto faz';

  @override
  String get migrationExplanation =>
      'A sua biblioteca inteira está neste aparelho, e é por isso que ela pode ir para outro servidor sem que o atual precise concordar — nem estar no ar. Nada é pedido a ele e nada se perde lá.';

  @override
  String migrationIdentifierChanges(String localName, String domain) {
    return 'O seu identificador muda. A segunda metade dele é o domínio do servidor, então @$localName:$domain passa a ser outro nome — que guarda a mesma história.';
  }

  @override
  String get migrationReauthorize =>
      'Os servidores que guardavam uma cópia sua precisam ser autorizados de novo, porque a autorização deles nomeia o identificador antigo.';

  @override
  String get migrationIrreversible => 'Não dá para desfazer.';

  @override
  String get migrationStepServer => 'Para onde';

  @override
  String get migrationDomainLabel => 'Endereço do novo servidor';

  @override
  String get migrationConnectsAtTheEnd =>
      'Este aparelho só passa a falar com o novo servidor no último passo. Até lá ele continua no atual.';

  @override
  String get migrationLocalNameLabel => 'Nome de usuário no novo servidor';

  @override
  String get migrationDisplayNameLabel => 'Nome exibido';

  @override
  String get migrationEmailLabel => 'E-mail';

  @override
  String get migrationPasswordLabel => 'Senha no novo servidor';

  @override
  String get migrationInvalidDomain => 'Isto não é um endereço de servidor.';

  @override
  String get migrationInvalidLocalName =>
      'Use letras minúsculas, números e . - _ entre eles.';

  @override
  String get migrationInvalidDisplayName => 'Informe um nome.';

  @override
  String get migrationInvalidEmail => 'Informe um e-mail válido.';

  @override
  String get migrationInvalidPassword =>
      'A senha precisa de pelo menos 8 caracteres.';

  @override
  String get migrationStepDevices => 'O que vai junto';

  @override
  String get migrationDevicesExplanation =>
      'Todos os seus aparelhos vão junto, com os identificadores que já têm. É o que permite que cada um continue de onde parou: toda alteração nomeia o aparelho que a fez.';

  @override
  String get migrationThisDevice => 'Este aparelho';

  @override
  String migrationUnnamedDevice(String handle) {
    return 'Aparelho $handle';
  }

  @override
  String get migrationDevicesUnnamed =>
      'O servidor atual não respondeu, então os nomes se perderam. Os identificadores vieram do histórico guardado aqui, que é a parte que não dá para recriar — você pode renomear cada aparelho depois.';

  @override
  String get migrationDevicesFailed =>
      'Não foi possível levantar os seus aparelhos.';

  @override
  String get migrationStepConfirm => 'Confirmar';

  @override
  String migrationSummary(String localName, String domain, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aparelhos',
      one: '1 aparelho',
    );
    return '@$localName:$domain passa a ser a sua conta, com $_temp0 e toda a sua biblioteca.';
  }

  @override
  String get migrationNothingIsCleared =>
      'Nada é apagado deste aparelho. O que ainda não foi entregue continua na fila e é enviado ao novo servidor.';

  @override
  String get migrationGo => 'Mudar de servidor';

  @override
  String get migrationBack => 'Voltar';

  @override
  String get migrationNext => 'Continuar';

  @override
  String migrationDone(String federatedId) {
    return 'Você agora é $federatedId.';
  }

  @override
  String get migrationFailed =>
      'A migração não aconteceu. Este aparelho continua no servidor de antes.';

  @override
  String get migrationNameTaken =>
      'Este nome de usuário já existe naquele servidor.';

  @override
  String get settingsDevices => 'Seus aparelhos';

  @override
  String get settingsDevicesExplanation =>
      'Quais aparelhos podem escrever na sua conta.';

  @override
  String get devicesExplanation =>
      'Cada alteração feita na sua biblioteca nomeia o aparelho que a fez. É por isso que esta lista existe: sem ela, um histórico teria nomes que ninguém consegue resolver.';

  @override
  String get devicesFailed =>
      'Não foi possível ler os seus aparelhos. O servidor não respondeu.';

  @override
  String get devicesThisOne => 'Este aparelho';

  @override
  String get devicesUnbound => 'Desvinculado';

  @override
  String get devicesUnboundExplanation =>
      'Não pode mais escrever. A linha fica, porque as alterações que ele fez continuam nomeando-o.';

  @override
  String devicesLastSynced(String date) {
    return 'Última sincronização em $date';
  }

  @override
  String get devicesNeverSynced => 'Ainda não sincronizou.';

  @override
  String get devicesRename => 'Renomear';

  @override
  String get devicesRenameTitle => 'Renomear aparelho';

  @override
  String get devicesNameLabel => 'Nome do aparelho';

  @override
  String get devicesNameInvalid => 'Informe um nome.';

  @override
  String devicesRenamed(String name) {
    return 'Agora se chama $name.';
  }

  @override
  String get devicesRenameFailed => 'Não foi possível renomear este aparelho.';

  @override
  String get devicesRevoke => 'Desvincular';

  @override
  String devicesRevokeTitle(String name) {
    return 'Desvincular $name?';
  }

  @override
  String get devicesRevokeExplanation =>
      'Ele deixa de poder escrever e as sessões dele acabam. Nada do que ele já escreveu é apagado, e a linha dele fica na lista — é ela que dá nome ao aparelho no histórico das suas alterações.';

  @override
  String devicesRevoked(String name) {
    return '$name não pode mais escrever.';
  }

  @override
  String get devicesRevokeFailed =>
      'Não foi possível desvincular este aparelho.';

  @override
  String get devicesCannotRevokeThisOne =>
      'Um aparelho não se desvincula sozinho. Faça isso a partir de outro aparelho seu.';

  @override
  String get devicesSave => 'Salvar';

  @override
  String get settingsAccount => 'Sua conta';

  @override
  String get settingsAccountExplanation => 'Nome, e-mail e senha.';

  @override
  String get accountIdentifier => 'Identificador';

  @override
  String get accountIdentifierExplanation =>
      'As duas metades são o seu nome de usuário e o servidor onde você está registrado. Ele só muda mudando de servidor.';

  @override
  String get accountDisplayName => 'Nome exibido';

  @override
  String get accountEmail => 'E-mail';

  @override
  String get accountEmailExplanation =>
      'É por aqui que a recuperação de senha passa, então mudá-lo pede a sua senha.';

  @override
  String get accountEmailAbsent => 'Nenhum e-mail registrado.';

  @override
  String get accountPassword => 'Senha';

  @override
  String get accountPasswordExplanation =>
      'Trocar a senha encerra a sua sessão em todos os aparelhos, inclusive neste.';

  @override
  String accountCreated(String date) {
    return 'Conta criada em $date';
  }

  @override
  String get accountFailed =>
      'Não foi possível ler a sua conta. O servidor não respondeu.';

  @override
  String get accountEditName => 'Mudar o nome exibido';

  @override
  String get accountNameInvalid => 'Informe um nome.';

  @override
  String accountNameChanged(String name) {
    return 'Agora você aparece como $name.';
  }

  @override
  String get accountNameFailed => 'Não foi possível mudar o nome exibido.';

  @override
  String get accountEditEmail => 'Mudar o e-mail';

  @override
  String get accountCurrentPassword => 'Senha atual';

  @override
  String get accountEmailInvalid => 'Informe um e-mail válido.';

  @override
  String get accountEmailNotice =>
      'Um aviso é enviado para o endereço antigo. É assim que você fica sabendo se não foi você quem trocou.';

  @override
  String accountEmailChanged(String email) {
    return 'O e-mail agora é $email.';
  }

  @override
  String get accountEmailFailed => 'Não foi possível mudar o e-mail.';

  @override
  String get accountEmailRegistered =>
      'Este e-mail já está registrado neste servidor.';

  @override
  String get accountEditPassword => 'Trocar a senha';

  @override
  String get accountNewPassword => 'Nova senha';

  @override
  String get accountPasswordInvalid =>
      'A senha precisa de pelo menos 8 caracteres.';

  @override
  String get accountPasswordEndsSessions =>
      'Todas as suas sessões acabam, e você entra de novo em cada aparelho. É o que se quer quando se troca a senha por desconfiança.';

  @override
  String get accountPasswordChanged => 'Senha trocada. Entre de novo.';

  @override
  String get accountPasswordFailed => 'Não foi possível trocar a senha.';

  @override
  String get accountWrongPassword => 'Senha atual incorreta.';

  @override
  String get accountSave => 'Salvar';

  @override
  String get accountDelete => 'Excluir a conta';

  @override
  String get accountDeleteExplanation =>
      'Remove você deste servidor, com tudo que está ligado à sua conta lá: os seus aparelhos, as suas credenciais e a sua biblioteca no servidor.';

  @override
  String get accountDeleteReaches => 'O que a exclusão alcança';

  @override
  String get accountDeleteDoesNotReach => 'O que ela não alcança';

  @override
  String accountDeleteThisServer(String domain) {
    return 'A sua conta em $domain';
  }

  @override
  String get accountDeleteReplicas =>
      'Os servidores que já guardam uma cópia sua. Excluir não entra no banco de outro operador — nem revogar entrava.';

  @override
  String accountDeleteReplicaNames(String domains) {
    return 'Ainda com uma cópia: $domains';
  }

  @override
  String get accountDeleteLocal =>
      'Os livros e as marcações neste aparelho. Eles são a sua cópia, e você pode exportar as marcações antes de sair.';

  @override
  String get accountDeleteIrreversible => 'Não dá para desfazer.';

  @override
  String get accountDeleteMigrateInstead =>
      'Se o que você quer é mudar de servidor levando a biblioteca, use Mudar de servidor de origem: são coisas diferentes.';

  @override
  String get accountDeleteConfirm => 'Excluir a minha conta';

  @override
  String get accountDeletePasswordLabel => 'Sua senha';

  @override
  String accountDeleted(String domain) {
    return 'A sua conta em $domain foi excluída.';
  }

  @override
  String get accountDeleteFailed => 'Não foi possível excluir a conta.';

  @override
  String get settingsAppearanceSection => 'Aparência';

  @override
  String get settingsAppearanceExplanation =>
      'Vale para este dispositivo. Não é sincronizado.';

  @override
  String get settingsAppearanceSystem => 'Do sistema';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceDark => 'Escuro';

  @override
  String get settingsAppearanceSystemColors => 'Usar as cores do sistema';

  @override
  String get settingsAppearanceSystemColorsExplanation =>
      'O aplicativo se pinta a partir do seu papel de parede ou da cor de destaque do sistema.';
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
  String get signInPasswordShow => 'Mostrar a senha';

  @override
  String get signInPasswordHide => 'Ocultar a senha';

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
  String get ebookPlacesSection => 'Onde você parou';

  @override
  String get ebookPlaceNoPercent => 'Sem porcentagem';

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
  String ebookRestoreFailed(String title) {
    return 'Não foi possível trazer $title de volta.';
  }

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
  String readerProgress(int percent) {
    return '$percent% lido';
  }

  @override
  String readingPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get readingProgressLabel => 'Progresso da leitura';

  @override
  String get readerToggleChrome => 'Mostrar ou ocultar os controles';

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
  String get readerFailedMessage =>
      'O leitor não conseguiu abrir este arquivo. Tente de novo; se continuar, o arquivo pode estar incompleto.';

  @override
  String get readerTimedOutMessage =>
      'O leitor não respondeu a tempo. Isso costuma acontecer com arquivos muito grandes ou logo depois de abrir o aplicativo.';

  @override
  String get readerFileBrokenMessage =>
      'Este arquivo é um EPUB que o leitor não conseguiu exibir. Ele pode estar corrompido ou incompleto, e o livro continua no seu acervo.';

  @override
  String get readerTooLargeMessage =>
      'Este arquivo é grande demais para ser aberto neste dispositivo.';

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
  String readerFontSizeValue(int percent) {
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
  String libraryContinuePercent(int percent) {
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

  @override
  String get syncRefusedSection => 'Recusadas pelo nó';

  @override
  String get syncRefusedExplanation =>
      'O nó não aceitou estas alterações e não vai aceitar numa próxima tentativa. Elas continuam valendo neste aparelho e não vão chegar a nenhum outro.';

  @override
  String syncRefusedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recusadas pelo nó',
      one: '1 recusada pelo nó',
    );
    return '$_temp0';
  }

  @override
  String get syncRefusedNoReason => 'O nó não disse por quê.';

  @override
  String get syncDiscard => 'Descartar';

  @override
  String get syncDiscardExplanation =>
      'Descartar não desfaz o que você fez. Só faz este aparelho parar de guardar uma entrega que não vai acontecer.';

  @override
  String get syncDiscardTitle => 'Descartar esta alteração?';

  @override
  String get syncDiscarded => 'Alteração descartada.';

  @override
  String get syncDiscardFailed => 'Não foi possível descartar.';

  @override
  String get syncCancel => 'Cancelar';

  @override
  String get syncRecordEbook => 'Um livro';

  @override
  String get syncRecordCollection => 'Uma estante';

  @override
  String get syncRecordFiling => 'Um livro numa estante';

  @override
  String get syncRecordProgress => 'Onde você parou';

  @override
  String get syncRecordAnnotation => 'Uma marcação';

  @override
  String get settingsFederationSection => 'Federação';

  @override
  String get settingsKnownServers => 'Servidores conhecidos';

  @override
  String get settingsKnownServersExplanation =>
      'Os servidores que o seu servidor conhece e para os quais ele pode replicar.';

  @override
  String get federationServersExplanation =>
      'Nada sai do seu servidor para um servidor que você não tenha nomeado aqui. Cada um destes foi descoberto pelo endereço que você digitou, e a chave que ele apresentou ficou registrada.';

  @override
  String get federationServersEmpty =>
      'Você ainda não adicionou nenhum servidor.';

  @override
  String get federationServersFailed =>
      'Não foi possível ler o catálogo. O servidor não respondeu.';

  @override
  String get federationRetry => 'Tentar de novo';

  @override
  String get federationAddLabel => 'Endereço do servidor';

  @override
  String get federationAddHint => 'quire-b.exemplo';

  @override
  String get federationAdd => 'Adicionar';

  @override
  String federationAdded(String domain) {
    return '$domain foi adicionado.';
  }

  @override
  String get federationAddInvalid => 'Isto não é um endereço de servidor.';

  @override
  String get federationAddAlreadyKnown =>
      'Este servidor já está no seu catálogo.';

  @override
  String get federationAddFailed =>
      'Não foi possível adicionar este servidor. Ele pode não publicar um documento de descobrimento.';

  @override
  String get federationServerOrigin => 'O seu servidor';

  @override
  String get federationServerActive => 'Participa da replicação';

  @override
  String get federationServerInactive => 'Fora da replicação';

  @override
  String get federationServerReplicate => 'Replicar com este servidor';

  @override
  String federationServerBaseUrl(String url) {
    return 'Responde em $url';
  }

  @override
  String federationServerGrpc(String authority) {
    return 'gRPC em $authority';
  }

  @override
  String get federationServerGrpcAbsent =>
      'Não publica endereço gRPC — nada replica para ele.';

  @override
  String federationServerFingerprint(String fingerprint) {
    return 'Chave $fingerprint';
  }

  @override
  String get federationServerFingerprintAbsent => 'Nenhuma chave fixada.';

  @override
  String federationServerDiscovered(String date, String time) {
    return 'Descoberto em $date, às $time';
  }

  @override
  String get federationServerNeverDiscovered => 'Ainda não descoberto.';

  @override
  String get federationRefresh => 'Redescobrir';

  @override
  String federationRefreshed(String domain) {
    return '$domain foi redescoberto e a chave é a mesma.';
  }

  @override
  String get federationRefreshFailed =>
      'Não foi possível redescobrir este servidor.';

  @override
  String get federationKeyChangedTitle => 'A chave deste servidor mudou';

  @override
  String federationKeyChangedExplanation(String domain) {
    return '$domain apresenta agora uma chave diferente da que estava registrada. Isso acontece quando o operador troca o certificado — e é também o que se veria se alguém estivesse respondendo no lugar dele. Daqui não dá para saber qual dos dois é.';
  }

  @override
  String get federationKeyChangedUnderstood => 'Entendi';

  @override
  String get federationForget => 'Esquecer';

  @override
  String federationForgetTitle(String domain) {
    return 'Esquecer $domain?';
  }

  @override
  String get federationForgetExplanation =>
      'Nada mais trafega para este servidor. O que ele já tiver recebido continua lá — esquecer não alcança o banco de outro operador.';

  @override
  String federationForgotten(String domain) {
    return '$domain foi esquecido.';
  }

  @override
  String get federationForgetRefused =>
      'Este servidor guarda uma cópia sua. Revogue a réplica antes de esquecê-lo.';

  @override
  String get federationForgetFailed =>
      'Não foi possível esquecer este servidor.';

  @override
  String get federationActiveFailed =>
      'Não foi possível mudar a participação deste servidor.';

  @override
  String get federationCancel => 'Cancelar';

  @override
  String get settingsReplicas => 'Réplicas autorizadas';

  @override
  String get settingsReplicasExplanation =>
      'Quem pode guardar uma cópia dos seus dados.';

  @override
  String get replicasExplanation =>
      'Autorizar um servidor é dizer que ele pode guardar uma cópia da sua biblioteca. Só os servidores nomeados aqui recebem alguma coisa.';

  @override
  String get replicasOutOfBand =>
      'A permissão fica registrada no seu servidor, que avisa o outro na primeira vez que tiver algo a enviar. Aquele servidor só aceita se já conhecer o seu: alguém com conta lá precisa adicionar o seu servidor em Servidores conhecidos.';

  @override
  String get replicasNone => 'Nenhum servidor guarda uma cópia dos seus dados.';

  @override
  String get replicasFailed =>
      'Não foi possível ler as autorizações. O servidor não respondeu.';

  @override
  String get replicasGrantedSection => 'Guardam uma cópia';

  @override
  String get replicasRevokedSection => 'Guardaram uma cópia';

  @override
  String get replicasRevokedExplanation =>
      'A replicação parou. O que estes servidores já receberam continua com eles: revogar não alcança o banco de outro operador.';

  @override
  String get replicasWithFiles => 'Metadados e arquivos';

  @override
  String get replicasWithoutFiles => 'Só metadados';

  @override
  String get replicasWithFilesExplanation =>
      'Tudo, inclusive os arquivos dos livros. Ocupa neste servidor o mesmo espaço que a sua biblioteca ocupa.';

  @override
  String get replicasWithoutFilesExplanation =>
      'Os seus livros, estantes e marcações — sem os arquivos. É a réplica barata, e costuma ser a que se quer num servidor que não é seu.';

  @override
  String replicasGrantedAt(String date) {
    return 'Autorizado em $date';
  }

  @override
  String get replicasAuthorize => 'Autorizar um servidor';

  @override
  String get replicasChooseServer => 'Qual servidor';

  @override
  String get replicasNoCandidates =>
      'Todos os servidores do seu catálogo já estão autorizados. Adicione outro em Servidores conhecidos.';

  @override
  String get replicasCandidateUndialable =>
      'Não publica endereço gRPC — nada replica para ele.';

  @override
  String replicasChooseWhat(String domain) {
    return 'O que $domain vai guardar';
  }

  @override
  String get replicasConfirm => 'Autorizar';

  @override
  String replicasAuthorized(String domain) {
    return '$domain pode guardar uma cópia.';
  }

  @override
  String get replicasAuthorizeFailed =>
      'Não foi possível autorizar este servidor.';

  @override
  String get replicasRevoke => 'Revogar';

  @override
  String replicasRevokeTitle(String domain) {
    return 'Revogar $domain?';
  }

  @override
  String get replicasRevokeExplanation =>
      'A replicação para. O que este servidor já recebeu continua com ele — revogar não apaga nada do banco de outro operador, e é por isso que a autorização revogada continua na lista.';

  @override
  String replicasRevoked(String domain) {
    return '$domain não recebe mais nada.';
  }

  @override
  String get replicasRevokeFailed =>
      'Não foi possível revogar esta autorização.';

  @override
  String get settingsMigrate => 'Mudar de servidor de origem';

  @override
  String get settingsMigrateExplanation =>
      'Levar a sua biblioteca para outro servidor.';

  @override
  String get migrationStepWhat => 'O que isto faz';

  @override
  String get migrationExplanation =>
      'A sua biblioteca inteira está neste aparelho, e é por isso que ela pode ir para outro servidor sem que o atual precise concordar — nem estar no ar. Nada é pedido a ele e nada se perde lá.';

  @override
  String migrationIdentifierChanges(String localName, String domain) {
    return 'O seu identificador muda. A segunda metade dele é o domínio do servidor, então @$localName:$domain passa a ser outro nome — que guarda a mesma história.';
  }

  @override
  String get migrationReauthorize =>
      'Os servidores que guardavam uma cópia sua precisam ser autorizados de novo, porque a autorização deles nomeia o identificador antigo.';

  @override
  String get migrationIrreversible => 'Não dá para desfazer.';

  @override
  String get migrationStepServer => 'Para onde';

  @override
  String get migrationDomainLabel => 'Endereço do novo servidor';

  @override
  String get migrationConnectsAtTheEnd =>
      'Este aparelho só passa a falar com o novo servidor no último passo. Até lá ele continua no atual.';

  @override
  String get migrationLocalNameLabel => 'Nome de usuário no novo servidor';

  @override
  String get migrationDisplayNameLabel => 'Nome exibido';

  @override
  String get migrationEmailLabel => 'E-mail';

  @override
  String get migrationPasswordLabel => 'Senha no novo servidor';

  @override
  String get migrationInvalidDomain => 'Isto não é um endereço de servidor.';

  @override
  String get migrationInvalidLocalName =>
      'Use letras minúsculas, números e . - _ entre eles.';

  @override
  String get migrationInvalidDisplayName => 'Informe um nome.';

  @override
  String get migrationInvalidEmail => 'Informe um e-mail válido.';

  @override
  String get migrationInvalidPassword =>
      'A senha precisa de pelo menos 8 caracteres.';

  @override
  String get migrationStepDevices => 'O que vai junto';

  @override
  String get migrationDevicesExplanation =>
      'Todos os seus aparelhos vão junto, com os identificadores que já têm. É o que permite que cada um continue de onde parou: toda alteração nomeia o aparelho que a fez.';

  @override
  String get migrationThisDevice => 'Este aparelho';

  @override
  String migrationUnnamedDevice(String handle) {
    return 'Aparelho $handle';
  }

  @override
  String get migrationDevicesUnnamed =>
      'O servidor atual não respondeu, então os nomes se perderam. Os identificadores vieram do histórico guardado aqui, que é a parte que não dá para recriar — você pode renomear cada aparelho depois.';

  @override
  String get migrationDevicesFailed =>
      'Não foi possível levantar os seus aparelhos.';

  @override
  String get migrationStepConfirm => 'Confirmar';

  @override
  String migrationSummary(String localName, String domain, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aparelhos',
      one: '1 aparelho',
    );
    return '@$localName:$domain passa a ser a sua conta, com $_temp0 e toda a sua biblioteca.';
  }

  @override
  String get migrationNothingIsCleared =>
      'Nada é apagado deste aparelho. O que ainda não foi entregue continua na fila e é enviado ao novo servidor.';

  @override
  String get migrationGo => 'Mudar de servidor';

  @override
  String get migrationBack => 'Voltar';

  @override
  String get migrationNext => 'Continuar';

  @override
  String migrationDone(String federatedId) {
    return 'Você agora é $federatedId.';
  }

  @override
  String get migrationFailed =>
      'A migração não aconteceu. Este aparelho continua no servidor de antes.';

  @override
  String get migrationNameTaken =>
      'Este nome de usuário já existe naquele servidor.';

  @override
  String get settingsDevices => 'Seus aparelhos';

  @override
  String get settingsDevicesExplanation =>
      'Quais aparelhos podem escrever na sua conta.';

  @override
  String get devicesExplanation =>
      'Cada alteração feita na sua biblioteca nomeia o aparelho que a fez. É por isso que esta lista existe: sem ela, um histórico teria nomes que ninguém consegue resolver.';

  @override
  String get devicesFailed =>
      'Não foi possível ler os seus aparelhos. O servidor não respondeu.';

  @override
  String get devicesThisOne => 'Este aparelho';

  @override
  String get devicesUnbound => 'Desvinculado';

  @override
  String get devicesUnboundExplanation =>
      'Não pode mais escrever. A linha fica, porque as alterações que ele fez continuam nomeando-o.';

  @override
  String devicesLastSynced(String date) {
    return 'Última sincronização em $date';
  }

  @override
  String get devicesNeverSynced => 'Ainda não sincronizou.';

  @override
  String get devicesRename => 'Renomear';

  @override
  String get devicesRenameTitle => 'Renomear aparelho';

  @override
  String get devicesNameLabel => 'Nome do aparelho';

  @override
  String get devicesNameInvalid => 'Informe um nome.';

  @override
  String devicesRenamed(String name) {
    return 'Agora se chama $name.';
  }

  @override
  String get devicesRenameFailed => 'Não foi possível renomear este aparelho.';

  @override
  String get devicesRevoke => 'Desvincular';

  @override
  String devicesRevokeTitle(String name) {
    return 'Desvincular $name?';
  }

  @override
  String get devicesRevokeExplanation =>
      'Ele deixa de poder escrever e as sessões dele acabam. Nada do que ele já escreveu é apagado, e a linha dele fica na lista — é ela que dá nome ao aparelho no histórico das suas alterações.';

  @override
  String devicesRevoked(String name) {
    return '$name não pode mais escrever.';
  }

  @override
  String get devicesRevokeFailed =>
      'Não foi possível desvincular este aparelho.';

  @override
  String get devicesCannotRevokeThisOne =>
      'Um aparelho não se desvincula sozinho. Faça isso a partir de outro aparelho seu.';

  @override
  String get devicesSave => 'Salvar';

  @override
  String get settingsAccount => 'Sua conta';

  @override
  String get settingsAccountExplanation => 'Nome, e-mail e senha.';

  @override
  String get accountIdentifier => 'Identificador';

  @override
  String get accountIdentifierExplanation =>
      'As duas metades são o seu nome de usuário e o servidor onde você está registrado. Ele só muda mudando de servidor.';

  @override
  String get accountDisplayName => 'Nome exibido';

  @override
  String get accountEmail => 'E-mail';

  @override
  String get accountEmailExplanation =>
      'É por aqui que a recuperação de senha passa, então mudá-lo pede a sua senha.';

  @override
  String get accountEmailAbsent => 'Nenhum e-mail registrado.';

  @override
  String get accountPassword => 'Senha';

  @override
  String get accountPasswordExplanation =>
      'Trocar a senha encerra a sua sessão em todos os aparelhos, inclusive neste.';

  @override
  String accountCreated(String date) {
    return 'Conta criada em $date';
  }

  @override
  String get accountFailed =>
      'Não foi possível ler a sua conta. O servidor não respondeu.';

  @override
  String get accountEditName => 'Mudar o nome exibido';

  @override
  String get accountNameInvalid => 'Informe um nome.';

  @override
  String accountNameChanged(String name) {
    return 'Agora você aparece como $name.';
  }

  @override
  String get accountNameFailed => 'Não foi possível mudar o nome exibido.';

  @override
  String get accountEditEmail => 'Mudar o e-mail';

  @override
  String get accountCurrentPassword => 'Senha atual';

  @override
  String get accountEmailInvalid => 'Informe um e-mail válido.';

  @override
  String get accountEmailNotice =>
      'Um aviso é enviado para o endereço antigo. É assim que você fica sabendo se não foi você quem trocou.';

  @override
  String accountEmailChanged(String email) {
    return 'O e-mail agora é $email.';
  }

  @override
  String get accountEmailFailed => 'Não foi possível mudar o e-mail.';

  @override
  String get accountEmailRegistered =>
      'Este e-mail já está registrado neste servidor.';

  @override
  String get accountEditPassword => 'Trocar a senha';

  @override
  String get accountNewPassword => 'Nova senha';

  @override
  String get accountPasswordInvalid =>
      'A senha precisa de pelo menos 8 caracteres.';

  @override
  String get accountPasswordEndsSessions =>
      'Todas as suas sessões acabam, e você entra de novo em cada aparelho. É o que se quer quando se troca a senha por desconfiança.';

  @override
  String get accountPasswordChanged => 'Senha trocada. Entre de novo.';

  @override
  String get accountPasswordFailed => 'Não foi possível trocar a senha.';

  @override
  String get accountWrongPassword => 'Senha atual incorreta.';

  @override
  String get accountSave => 'Salvar';

  @override
  String get accountDelete => 'Excluir a conta';

  @override
  String get accountDeleteExplanation =>
      'Remove você deste servidor, com tudo que está ligado à sua conta lá: os seus aparelhos, as suas credenciais e a sua biblioteca no servidor.';

  @override
  String get accountDeleteReaches => 'O que a exclusão alcança';

  @override
  String get accountDeleteDoesNotReach => 'O que ela não alcança';

  @override
  String accountDeleteThisServer(String domain) {
    return 'A sua conta em $domain';
  }

  @override
  String get accountDeleteReplicas =>
      'Os servidores que já guardam uma cópia sua. Excluir não entra no banco de outro operador — nem revogar entrava.';

  @override
  String accountDeleteReplicaNames(String domains) {
    return 'Ainda com uma cópia: $domains';
  }

  @override
  String get accountDeleteLocal =>
      'Os livros e as marcações neste aparelho. Eles são a sua cópia, e você pode exportar as marcações antes de sair.';

  @override
  String get accountDeleteIrreversible => 'Não dá para desfazer.';

  @override
  String get accountDeleteMigrateInstead =>
      'Se o que você quer é mudar de servidor levando a biblioteca, use Mudar de servidor de origem: são coisas diferentes.';

  @override
  String get accountDeleteConfirm => 'Excluir a minha conta';

  @override
  String get accountDeletePasswordLabel => 'Sua senha';

  @override
  String accountDeleted(String domain) {
    return 'A sua conta em $domain foi excluída.';
  }

  @override
  String get accountDeleteFailed => 'Não foi possível excluir a conta.';

  @override
  String get settingsAppearanceSection => 'Aparência';

  @override
  String get settingsAppearanceExplanation =>
      'Vale para este dispositivo. Não é sincronizado.';

  @override
  String get settingsAppearanceSystem => 'Do sistema';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceDark => 'Escuro';

  @override
  String get settingsAppearanceSystemColors => 'Usar as cores do sistema';

  @override
  String get settingsAppearanceSystemColorsExplanation =>
      'O aplicativo se pinta a partir do seu papel de parede ou da cor de destaque do sistema.';
}

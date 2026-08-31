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
}

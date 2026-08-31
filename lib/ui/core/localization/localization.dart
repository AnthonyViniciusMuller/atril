/// The strings, as everything above this directory sees them.
///
/// It exists so that `generated/` is a path nothing outside this directory
/// spells. The generated class is `flutter gen-l10n`'s output and is committed
/// like the protobuf stubs and drift's row classes are; a widget importing it
/// through here is a widget that does not have to be edited if the tool's
/// output ever moves.
library;

export 'generated/app_localizations.dart';

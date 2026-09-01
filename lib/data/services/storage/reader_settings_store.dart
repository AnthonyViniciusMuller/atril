/// Where the reader's typography is kept between two runs.
///
/// It is beside the window's size in `shared_preferences` and not in the local
/// database, for the reason `window_store.dart` draws the line: the replica
/// holds the records that replicate, the log this device owes and the causal
/// state that makes the next change correct, and how large somebody likes
/// their type is none of those.
///
/// **It is deliberately not replicated, and the contract has no field for it.**
/// That is not an omission upstream. Type size is about this screen, on this
/// device, held this far from a reader's face: a phone read on a train and a
/// desktop at arm's length want different answers, and a setting that synced
/// would make choosing one on either device the wrong choice on the other. The
/// locator syncs because a passage is the same passage everywhere; the size it
/// is printed at is not.
///
/// **A run that wrote half of it is not a state worth protecting.** Each field
/// is read on its own and falls back to the default, so a reader who is
/// interrupted mid-write comes back to a page that is mostly what they chose
/// rather than to nothing they chose. The session credential is the one thing
/// in this application that has to be whole; this is the opposite kind of
/// value.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/logging.dart';
import '../epub/epub_host.dart';

final _log = loggerFor('data/storage');

/// The key the type size is written under.
const String readerFontSizeKey = 'reader.fontSize';

/// The key the leading is written under.
const String readerLineHeightKey = 'reader.lineHeight';

/// The key the margin is written under.
const String readerMarginKey = 'reader.margin';

/// The key the reading theme is written under.
const String readerThemeKey = 'reader.theme';

/// The key the spread is written under.
const String readerSpreadKey = 'reader.spread';

/// The sizes the reader can choose between, as percentages.
///
/// A list and not a free slider. A slider over type size is a control that
/// invites a reader to hunt for a value they cannot name and cannot get back
/// to; eight steps from small to very large is what a reader actually wants,
/// and every one of them is a size somebody would choose on purpose.
const List<double> readerFontSizes = <double>[
  80,
  90,
  100,
  115,
  130,
  150,
  175,
  200,
];

/// The leadings the reader can choose between.
const List<double> readerLineHeights = <double>[1.2, 1.4, 1.5, 1.7, 2];

/// The margins the reader can choose between, as a percentage per side.
const List<double> readerMargins = <double>[0, 4, 8, 12, 16];

/// What remembers how a reader likes a page.
abstract interface class ReaderSettingsStore {
  /// The style this device was left at, or the default on a first run.
  Future<EpubStyle> read();

  /// Records [style].
  Future<void> write(EpubStyle style);
}

/// The store over the platform's own preferences.
final class PreferencesReaderSettingsStore implements ReaderSettingsStore {
  /// A store over [preferences], or over the platform's own.
  PreferencesReaderSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<EpubStyle> read() async {
    try {
      return EpubStyle(
        fontSize:
            await _preferences.getDouble(readerFontSizeKey) ??
            const EpubStyle().fontSize,
        lineHeight:
            await _preferences.getDouble(readerLineHeightKey) ??
            const EpubStyle().lineHeight,
        marginPercent:
            await _preferences.getDouble(readerMarginKey) ??
            const EpubStyle().marginPercent,
        theme: _themeOf(await _preferences.getString(readerThemeKey)),
        spread: _spreadOf(await _preferences.getString(readerSpreadKey)),
      );
    } on Exception catch (error) {
      // A preference store that cannot be read is a book opening at the
      // default size, which is a working reader. It is not worth refusing to
      // open a book over, and it is worth one line in the log.
      _log.warning('the reader settings could not be read', error);

      return const EpubStyle();
    }
  }

  @override
  Future<void> write(EpubStyle style) async {
    try {
      await _preferences.setDouble(readerFontSizeKey, style.fontSize);
      await _preferences.setDouble(readerLineHeightKey, style.lineHeight);
      await _preferences.setDouble(readerMarginKey, style.marginPercent);
      await _preferences.setString(readerThemeKey, style.theme.name);
      await _preferences.setString(readerSpreadKey, style.spread.name);
    } on Exception catch (error) {
      _log.warning('the reader settings could not be written', error);
    }
  }

  /// The theme [name] spells, or the default.
  ///
  /// An unknown name is a preference written by a later version of this
  /// application that has learned a theme this one has not. Falling back is
  /// what makes downgrading harmless; refusing would be a reader who cannot
  /// open a book because of a word in a preferences file.
  static EpubTheme _themeOf(String? name) {
    for (final EpubTheme theme in EpubTheme.values) {
      if (theme.name == name) {
        return theme;
      }
    }

    return const EpubStyle().theme;
  }

  /// As [_themeOf], for the spread.
  static EpubSpread _spreadOf(String? name) {
    for (final EpubSpread spread in EpubSpread.values) {
      if (spread.name == name) {
        return spread;
      }
    }

    return const EpubStyle().spread;
  }
}

/// A store that holds the style for as long as the process runs.
///
/// It is what a test uses and what a platform with no preference store would
/// fall back to: a reader whose choices last until they close the application
/// is worse than one whose choices last, and much better than one whose book
/// will not open.
final class MemoryReaderSettingsStore implements ReaderSettingsStore {
  /// A store holding [style].
  MemoryReaderSettingsStore([this.style = const EpubStyle()]);

  /// What it holds.
  EpubStyle style;

  @override
  Future<EpubStyle> read() async => style;

  @override
  Future<void> write(EpubStyle value) async => style = value;
}

/// Where the desktop window's size is kept between two runs.
///
/// It is not in the local database, and the line is worth drawing here rather
/// than arguing about later. `data/services/local` holds the reader's replica:
/// the records that replicate, the log this device owes and the causal state
/// that makes authoring the next change correct. How wide somebody left a
/// window on one machine is none of those — it never syncs, it means nothing
/// on another device, and it has to be readable before `runApp`, which is
/// before the database is opened.
///
/// The size is remembered and the *position* is not. A window restored to
/// coordinates that were on a second monitor is a window the reader cannot
/// find, and the platforms differ in whether they will move it back: the
/// failure is silent, total, and needs a settings reset to escape. What
/// restoring a size buys — not having to resize a window every morning — is
/// most of the value at none of that risk.
library;

import 'dart:ui' show Size;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/logging.dart';

final _log = loggerFor('data/storage');

/// The keys the size is written under.
///
/// Two of them, and unlike the session credential this is not a state worth
/// protecting: a run that wrote one and not the other reopens at a width it
/// was left at and a height it was not, which is a window slightly the wrong
/// shape rather than a value that has to be whole.
const String windowWidthKey = 'window.width';

/// The key the height is written under.
const String windowHeightKey = 'window.height';

/// What remembers the size of the window.
abstract interface class WindowStore {
  /// The size this window was last left at, or `null` on a first run.
  Future<Size?> read();

  /// Records [size].
  Future<void> write(Size size);
}

/// The store over the platform's own preferences.
final class PreferencesWindowStore implements WindowStore {
  /// A store over [preferences], or over the platform's own.
  PreferencesWindowStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Size?> read() async {
    try {
      final width = await _preferences.getDouble(windowWidthKey);
      final height = await _preferences.getDouble(windowHeightKey);

      if (width == null || height == null) {
        return null;
      }

      return Size(width, height);
    } on Exception catch (error) {
      // A preference store that cannot be read is a window opening at its
      // default size, which is a working app. It is not worth failing a
      // start-up over, and it is worth one line in the log.
      _log.warning('the window size could not be read', error);

      return null;
    }
  }

  @override
  Future<void> write(Size size) async {
    try {
      await _preferences.setDouble(windowWidthKey, size.width);
      await _preferences.setDouble(windowHeightKey, size.height);
    } on Exception catch (error) {
      _log.warning('the window size could not be written', error);
    }
  }
}

/// A store that holds the size for as long as the process runs.
final class MemoryWindowStore implements WindowStore {
  /// A store holding [size].
  MemoryWindowStore([this.size]);

  /// What was last written.
  Size? size;

  @override
  Future<Size?> read() async => size;

  @override
  Future<void> write(Size value) async => size = value;
}

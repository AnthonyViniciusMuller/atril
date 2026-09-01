/// How a reader likes a page, across two runs of the application.
///
/// The branch worth covering is a run that wrote some of it and not the rest,
/// which is the same reason `window_store_test.dart` exists — and the answer
/// here is deliberately the opposite of the session credential's. A half-written
/// preference is a page mostly the way somebody chose it, and refusing to open a
/// book over one would be this application protecting a value nothing depends
/// on.
library;

import 'package:atril/data/services/epub/epub_host.dart';
import 'package:atril/data/services/storage/reader_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The store over a preference backend that holds [initial].
PreferencesReaderSettingsStore _store([Map<String, Object>? initial]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(initial ?? <String, Object>{});

  return PreferencesReaderSettingsStore(preferences: SharedPreferencesAsync());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a first run', () {
    test('reads the defaults, which are decisions and not blanks', () async {
      final EpubStyle style = await _store().read();

      // The book keeps its own face and the page follows the device: both are
      // choices this application made on the reader's behalf and would have to
      // defend, which is why they are the values a fresh install gets.
      expect(style.fontFamily, isNull);
      expect(style.theme, EpubTheme.followSystem);
      expect(style.fontSize, 100);
    });
  });

  group('a run after a reader has chosen', () {
    test('reads back what was written', () async {
      final PreferencesReaderSettingsStore store = _store();
      const EpubStyle chosen = EpubStyle(
        fontSize: 130,
        lineHeight: 1.7,
        marginPercent: 4,
        theme: EpubTheme.sepia,
        spread: EpubSpread.none,
      );

      await store.write(chosen);

      expect(await store.read(), chosen);
    });

    test('every field survives on its own', () async {
      // Written one at a time rather than compared as a whole, so that a field
      // dropped from the write — or read under the wrong key — fails by name
      // instead of as one opaque inequality.
      final PreferencesReaderSettingsStore store = _store();

      await store.write(
        const EpubStyle(
          fontSize: 175,
          lineHeight: 2,
          marginPercent: 16,
          theme: EpubTheme.dark,
          spread: EpubSpread.none,
        ),
      );

      final EpubStyle read = await store.read();

      expect(read.fontSize, 175);
      expect(read.lineHeight, 2);
      expect(read.marginPercent, 16);
      expect(read.theme, EpubTheme.dark);
      expect(read.spread, EpubSpread.none);
    });
  });

  group('a store that was written by something else', () {
    test('a run that wrote half of it keeps the half it wrote', () async {
      // The branch this file exists for. A reader interrupted mid-write comes
      // back to a page mostly the way they chose it, not to nothing they chose.
      final EpubStyle style = await _store(<String, Object>{
        readerFontSizeKey: 150.0,
      }).read();

      expect(style.fontSize, 150);
      expect(style.lineHeight, const EpubStyle().lineHeight);
      expect(style.theme, const EpubStyle().theme);
    });

    test(
      'a theme a later version knows and this one does not falls back',
      () async {
        // Downgrading should be harmless. Refusing would be a reader who cannot
        // open a book because of a word in a preferences file.
        final EpubStyle style = await _store(<String, Object>{
          readerThemeKey: 'nocturne',
          readerFontSizeKey: 115.0,
        }).read();

        expect(style.theme, const EpubStyle().theme);
        // And the fields it *could* read are still read: one unknown value does
        // not throw the rest away.
        expect(style.fontSize, 115);
      },
    );

    test('a spread it cannot name falls back the same way', () async {
      final EpubStyle style = await _store(<String, Object>{
        readerSpreadKey: 'always',
      }).read();

      expect(style.spread, const EpubStyle().spread);
    });
  });

  group('the steps a reader chooses between', () {
    test('are ordered, distinct, and include the default', () {
      // A control that steps through them relies on both, and the default has
      // to be reachable or a reader cannot get back to it.
      for (final List<double> steps in <List<double>>[
        readerFontSizes,
        readerLineHeights,
        readerMargins,
      ]) {
        expect(steps.toSet(), hasLength(steps.length));

        for (int i = 1; i < steps.length; i++) {
          expect(steps[i], greaterThan(steps[i - 1]));
        }
      }

      expect(readerFontSizes, contains(const EpubStyle().fontSize));
      expect(readerLineHeights, contains(const EpubStyle().lineHeight));
      expect(readerMargins, contains(const EpubStyle().marginPercent));
    });
  });

  group('the memory store', () {
    test('holds a style for as long as it is asked to', () async {
      // What a test uses, and what a reader with no preference backend gets:
      // choices that last a session are worse than choices that last, and much
      // better than a book that will not open.
      final MemoryReaderSettingsStore store = MemoryReaderSettingsStore();

      expect(await store.read(), const EpubStyle());

      await store.write(const EpubStyle(fontSize: 90));

      expect((await store.read()).fontSize, 90);
    });
  });
}

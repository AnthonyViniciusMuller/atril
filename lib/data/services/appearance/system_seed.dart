/// The colour the platform draws itself with, behind a port.
///
/// **One colour and not a palette.** Android 12 and later hand back a whole
/// `CorePalette` derived from the wallpaper, and it is tempting to copy its
/// forty roles into a `ColorScheme` one by one — the `dynamic_color` package
/// has an extension that does exactly that. Atril takes the primary tone off
/// it instead and derives the rest, because `ui/core/themes/colors.dart` says
/// what this application's palette *is*: a seed, with Material naming the
/// roles and guaranteeing their contrast. A system palette spliced in role by
/// role would be the one scheme in the app that those guarantees had not been
/// applied to, and it would differ from the seeded one in ways no test here
/// could describe.
///
/// **It answers `null` rather than failing.** Two of the six targets have no
/// such API — iOS does not expose the tint and a browser has nothing to
/// expose — and on the other four it is absent below Android 12 and on a
/// desktop session that sets no accent. Those are not errors, and neither is
/// a platform channel nobody answered: `OptionalMethodChannel` is what the
/// plugin uses for that, so an unimplemented target completes with `null`
/// instead of throwing.
///
/// It is a port with three implementations for the usual reason: a widget test
/// has no platform channel, and a test that wants to know what happens when
/// the system *does* offer a colour cannot get one by asking the host it runs
/// on.
library;

import 'dart:ui' show Color;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../../utils/logging.dart';

final _log = loggerFor('data/appearance');

/// The tone of the wallpaper's palette that is taken as the seed.
///
/// 40 is the tone Material's own dynamic schemes use for `primary` at light
/// brightness, so it is the colour the platform would have drawn its own
/// primary in. Anything lighter seeds a scheme too pale to read the app's
/// chrome against; anything darker seeds one that no longer looks like the
/// wallpaper it came from.
const int systemSeedTone = 40;

/// What knows the colour the platform draws itself with.
abstract interface class SystemSeed {
  /// That colour, or `null` where the platform has none to give.
  Future<Color?> read();
}

/// The seed the platform itself answers with.
final class PlatformSystemSeed implements SystemSeed {
  /// A seed read from this device.
  const PlatformSystemSeed();

  @override
  Future<Color?> read() async {
    try {
      // Android 12 and later. The wallpaper's palette is the richer answer and
      // is asked for first; everywhere else this is `null` and costs one
      // absent platform call.
      //
      // The type is deprecated upstream and is still what the plugin's own
      // signature hands back, so it is named rather than inferred and the
      // deprecation is acknowledged where a reader of this file will see it:
      // it goes away when `dynamic_color` moves to `CorePalettes`, and nothing
      // on this side of the call can move first.
      // ignore: deprecated_member_use
      final CorePalette? palette = await DynamicColorPlugin.getCorePalette();

      if (palette != null) {
        return Color(palette.primary.get(systemSeedTone));
      }

      // The three desktops, and Android 8.1 through 11. One accent colour,
      // which is the whole of what those systems have decided.
      return await DynamicColorPlugin.getAccentColor();
    } on Exception catch (error) {
      // A platform that answers badly is an application drawn in its own
      // colours, which is what it is drawn in on iOS and in a browser anyway.
      // It is not worth failing a start-up over, and it is worth one line in
      // the log.
      _log.warning('the system colour could not be read', error);

      return null;
    }
  }
}

/// A platform with no colour to give.
///
/// It is what a test that is not about the system palette uses, and it is the
/// honest description of two of the six targets.
final class NoSystemSeed implements SystemSeed {
  /// A seed nobody offers.
  const NoSystemSeed();

  @override
  Future<Color?> read() async => null;
}

/// A seed fixed in advance.
///
/// What a test uses to be a device whose system *does* offer a colour, which
/// is the half of this that the host a test runs on cannot be asked for.
final class MemorySystemSeed implements SystemSeed {
  /// A platform offering [seed].
  const MemorySystemSeed(this.seed);

  /// What it offers.
  final Color? seed;

  @override
  Future<Color?> read() async => seed;
}

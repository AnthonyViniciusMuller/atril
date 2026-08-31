/// The desktop window: a floor to be correct at, and the size it was left at.
///
/// The adaptive scaffold decides its layout from the width it is given, which
/// makes the smallest width a window can *have* part of the design rather than
/// a platform detail. Flutter's three desktop embedders set an initial size in
/// C++, Swift and C++ before any Dart has run and impose no minimum at all, so
/// without this a reader can drag a window to eighty pixels and watch a
/// navigation bar overflow. [minimumWindowSize] is that floor, and it is
/// deliberately *below* the compact threshold: a narrow desktop window is
/// meant to become the phone layout, and a floor above 600 would be this app
/// refusing the case the layout was written for.
///
/// The size is restored and the position is not — `window_store.dart` argues
/// why — and neither is done anywhere but the three desktop targets. The guard
/// is [defaultTargetPlatform] and not `dart:io`, which does not parse for the
/// web build.
///
/// Saving is debounced. A drag delivers a resize per frame, and writing each
/// one would mean a hundred round trips to the platform's preference store for
/// one gesture that ends where the reader stops.
library;

import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../data/services/storage/window_store.dart';
import '../utils/logging.dart';

final _log = loggerFor('config/window');

/// The smallest a window may be dragged to.
///
/// 400 is narrower than the scaffold's `compactWidth` on purpose — the compact layout is a
/// legitimate desktop shape, and this is the width below which its app bar and
/// its content stop fitting rather than the width at which it starts.
const Size minimumWindowSize = Size(400, 600);

/// The size a window opens at when nothing was remembered.
///
/// It lands in the middle of the three layouts — a rail with its labels under
/// its icons — and it fits on a 1366×768 display, which is the smallest screen
/// this app is likely to be opened on.
const Size defaultWindowSize = Size(1024, 720);

/// How long the window must be still before its size is written.
const Duration windowSaveDelay = Duration(milliseconds: 500);

/// Whether this build runs in a window it can configure.
bool get hasConfigurableWindow =>
    !kIsWeb &&
    const <TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform);

/// Applies the floor, restores the remembered size, and shows the window.
///
/// It does nothing on the three targets that have no window to configure, so
/// both entry points call it unconditionally rather than each deciding for
/// itself which platform they are on.
///
/// The window is shown *here* and not by the embedder: `window_manager` hides
/// it until `waitUntilReadyToShow` so that a reader never sees it appear at
/// the default size and jump to the remembered one.
Future<void> configureDesktopWindow({WindowStore? store}) async {
  if (!hasConfigurableWindow) {
    return;
  }

  final windows = store ?? PreferencesWindowStore();

  await windowManager.ensureInitialized();

  final remembered = await windows.read();
  final size = remembered ?? defaultWindowSize;

  _log.fine(
    'opening at $size, ${remembered == null ? 'the default' : 'as it was left'}',
  );

  await windowManager.waitUntilReadyToShow(
    WindowOptions(size: size, minimumSize: minimumWindowSize),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  windowManager.addListener(WindowSizeRecorder(windows));
}

/// Writes the window's size once it has stopped changing.
final class WindowSizeRecorder extends WindowListener {
  /// A recorder writing to [store], no more often than [delay].
  ///
  /// [sizeOf] is how the current size is asked for, and it is a parameter so
  /// that this class can be tested without a window: everything worth testing
  /// about it is the debounce, and the debounce is the part that would
  /// otherwise need a hundred real resizes to exercise.
  WindowSizeRecorder(
    this.store, {
    this.delay = windowSaveDelay,
    Future<Size> Function()? sizeOf,
  }) : _sizeOf = sizeOf ?? windowManager.getSize;

  /// Where the size is kept.
  final WindowStore store;

  /// How long the window must be still first.
  final Duration delay;

  final Future<Size> Function() _sizeOf;

  Timer? _pending;

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  /// Writes the size the window has after [delay] with nothing further
  /// happening, replacing any write that was already waiting.
  void _scheduleSave() {
    _pending?.cancel();
    _pending = Timer(delay, () async {
      await store.write(await _sizeOf());
    });
  }

  /// Cancels a write that has not happened yet.
  void cancel() {
    _pending?.cancel();
    _pending = null;
  }
}

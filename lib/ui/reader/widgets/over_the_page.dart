/// What the reader draws on top of the engine, and can still be touched.
///
/// **A platform view is a hole in Flutter's own surface.** The page is a
/// webview on five targets and a CEF texture on the sixth, and on the web the
/// browser hands a pointer event to the `<iframe>` that is really there rather
/// than to the canvas Flutter paints above it. Everything this reader puts over
/// the page — the bar, the progress, the actions on a selection, the two sheets
/// and the note dialog — is therefore drawn where a click cannot reach it, and
/// on the web target every one of those controls was dead.
///
/// Measured rather than reasoned, in a browser build of exactly that
/// arrangement: a button painted over the page counted **zero** clicks; the
/// same button inside this wrapper counted every one. A modal sheet opened over
/// the page was worse than unusable — its own barrier took no click and Escape
/// never reached Flutter, so the reader could neither press anything in it nor
/// get rid of it.
///
/// **It is a wrapper and not a call at each site**, because what it does is not
/// obvious from its name at the sixth call and the argument for it is one
/// argument, not six. `PointerInterceptor` puts a real DOM element over the
/// region so that the browser has something of Flutter's to deliver the event
/// to; on Android, Linux, macOS and Windows the package resolves to a widget
/// that returns its child, so this costs those four targets a rebuild of one
/// element and nothing else.
///
/// **What it must not wrap is the page itself**, and [intercepting] is how the
/// chrome says so while it is out of the way. A tap on the book belongs to the
/// book — `page_input.dart` is how the reader's tap gets back out of it — and
/// this widget stops a click where it is drawn, whether or not the thing drawn
/// there can be seen. A bar that kept intercepting after it faded out would
/// leave two strips across the page that a reader could tap forever without the
/// chrome coming back, which is the bug this file exists to fix, moved four
/// centimetres.
library;

import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// [child], drawn over the engine's page and still able to be touched.
class OverThePage extends StatelessWidget {
  /// Puts [child] over the page without losing its pointer events.
  const OverThePage({required this.child, this.intercepting = true, super.key});

  /// The chrome, the sheet or the dialog that sits over the book.
  final Widget child;

  /// Whether the click belongs to [child] rather than to the book underneath.
  ///
  /// It is `true` for anything the reader can act on and `false` for chrome
  /// that is on screen but out of the way: what is faded out is not there, and
  /// the tap that lands on it is a tap on the page.
  final bool intercepting;

  @override
  Widget build(BuildContext context) =>
      PointerInterceptor(intercepting: intercepting, child: child);
}

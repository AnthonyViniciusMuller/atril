/// The page, and the two things that can stand in front of it.
///
/// **The host's view is mounted before the book is open, always**, because
/// both real hosts complete `open()` from a callback of the widget `view()`
/// builds. What the spinner and the refusal are, therefore, is layers over a
/// page that is already there.
///
/// **The three ways a book does not open are three sentences, not one.** The
/// file is not on this device; the format is one this build does not render;
/// something failed. The first is an offer, the second is a fact about the
/// build that leaves the rest of the book's life intact, and only the third is
/// an apology.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/reading/reading_repository.dart';
import '../../../data/services/epub/epub_host.dart';
import '../../../routing/routes.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';

/// The page, with whatever is standing in front of it.
///
/// **The host's view is mounted before the book is open, always.** Both real
/// hosts complete `open()` from a callback of the widget `view()` builds — the
/// webview's `onEpubLoaded`, the CEF view's `readyToLoad` — so a body that
/// showed a spinner *instead of* the view until `open` had completed was a body
/// waiting on an event only the widget it withheld could raise. On the webview
/// targets that was the thirty-second timeout on every book; on Linux it was a
/// refusal at once. The spinner and the refusal are layers over the page now,
/// and the page is underneath from the first frame.
class ReaderBody extends StatelessWidget {
  /// The page [page], under whatever the state of [model]'s open asks for.
  const ReaderBody({required this.model, required this.page, super.key});

  /// What the screen knows.
  final ReaderViewModel model;

  /// The host's view, built once by the screen above.
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // The host's own view, and **no gesture detector over it**. There was
        // one, and on five of the six targets it never fired once: the page is
        // a platform view, the browser or the webview takes the click, and
        // Flutter's glass pane is never told. What reports a tap now is the
        // page itself — `page_input.dart` is the argument and the measurement
        // — which also answers the reason the gesture was put here rather than
        // inside the page in the first place, and answers it better: the
        // engine's own document knows whether the reader hit a link or ended a
        // selection, and says nothing when they did.
        //
        // One source, and not a detector as well. On Linux the pointer reaches
        // both the texture and Flutter, so a detector kept "for the target
        // where it works" would be a chrome that toggled twice and therefore
        // not at all.
        //
        // The `Semantics` stays and is now the only thing here. Everything
        // inside the view belongs to the engine and is announced — or not — by
        // whatever the platform's webview does with it; this one control is the
        // app's, and without a label it is a tap target with no name on top of
        // somebody else's document.
        Semantics(
          button: true,
          label: AppLocalizations.of(context).readerToggleChrome,
          onTap: model.toggleChrome,
          child: page,
        ),
        ListenableBuilder(
          listenable: model.open,
          builder: (BuildContext context, Widget? _) {
            if (model.open.running) {
              return const _ReaderOpening();
            }

            if (model.open.result case Error<void>(:final Exception error)) {
              return _ReaderRefusal(model: model, error: error);
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// What is shown while the file is read and handed over.
class _ReaderOpening extends StatelessWidget {
  const _ReaderOpening();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.readerOpening,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why the book is not on screen, and what can be done about it.
///
/// **Every sentence here comes out of the ARB and none out of the exception.**
/// `errors.dart` says what an [AppException]'s message is for: it is
/// diagnostic, it names hosts and identifiers freely, it is written in the
/// language whoever raised it happened to be writing in — the hosts write
/// theirs in English — and it goes to the log. What a reader is shown is
/// chosen from the code, which is exactly what a code is for: it survives a
/// rewording on either side of the wire.
///
/// The codes are named constants and not literals, so that a failure this
/// screen has a sentence for cannot be renamed where it is raised without the
/// two going out of step visibly.
class _ReaderRefusal extends StatelessWidget {
  const _ReaderRefusal({required this.model, required this.error});

  final ReaderViewModel model;
  final Exception error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? code = error is AppException
        ? (error as AppException).code
        : null;

    final Widget retry = FilledButton(
      onPressed: model.open.execute,
      child: Text(l10n.readerRetry),
    );

    final (String title, String message, Widget? action) = switch (code) {
      codeContentNotOnDevice => (
        l10n.readerNotOnDeviceTitle,
        l10n.readerNotOnDeviceMessage,
        // The way out is the book's own screen, which already owns downloading
        // and knows how to show a transfer running. A second download button
        // here would be a second implementation of a progress bar.
        FilledButton(
          onPressed: () => context.go(Routes.ebook(model.ebookId)),
          child: Text(l10n.readerDownload),
        ),
      ),
      codeFormatNotReadable => (
        l10n.readerFormatTitle,
        l10n.readerFormatMessage,
        null,
      ),
      // The same two sentences the book's own screen says, because it is the
      // same event: another device deleted this work and the tombstone
      // arrived. A second wording for one fact would be two explanations of
      // one thing.
      codeEbookNotFound => (
        l10n.ebookNotFoundTitle,
        l10n.ebookNotFoundMessage,
        null,
      ),
      // No retry on either of these: reading the same bytes again cannot make
      // the file smaller or make the engine like it, and a button that does
      // nothing is worse than none.
      codeEbookTooLarge => (
        l10n.readerFailedTitle,
        l10n.readerTooLargeMessage,
        null,
      ),
      codeEpubDisplayFailed => (
        l10n.readerFailedTitle,
        l10n.readerFileBrokenMessage,
        null,
      ),
      // The one failure where trying again is the whole answer: a webview that
      // had not come up, a CEF still starting.
      codeEpubOpenTimeout => (
        l10n.readerFailedTitle,
        l10n.readerTimedOutMessage,
        retry,
      ),
      _ => (l10n.readerFailedTitle, l10n.readerFailedMessage, retry),
    };

    // Opaque, like the spinner: it covers whatever the engine left on the page
    // and takes the tap that would otherwise hide the chrome — and with it the
    // way back — under a message that says the book is not coming.
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: 20),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

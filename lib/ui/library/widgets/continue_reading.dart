/// The books this reader has already started, and where each device left them.
///
/// **It shows every device's place and not one per book.** RN01 asks for that
/// and C05 makes it correct: a position belongs to one work and one device and
/// is written by that device alone, so a phone and a desktop disagreeing about
/// where the reader is are not in conflict — they are two true statements about
/// two devices. Collapsing them would be this application deciding which of a
/// reader's devices counts, which is a decision nobody asked it to make.
///
/// **It says *another device* and never which one.** Nothing in this
/// application stores the reader's other devices: `ListDevices` is in the
/// contract and phase 12 is what calls it. Until then the honest answer is that
/// some other device of theirs got here, and inventing a name would be worse
/// than the shorter sentence.
///
/// **It appears only when there is something in it.** A reader who has imported
/// books and opened none should see their shelf, not an empty band above it
/// explaining what would go there.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/reading/reading_repository.dart';
import '../../../routing/routes.dart';
import '../../core/localization/localization.dart';

/// How tall the strip is at the system's ordinary text size.
///
/// Enough for a title, a device and a progress bar, and no more: this is a way
/// back into a book somebody is already reading, and a band that took a third
/// of the shelf would be one the reader scrolls past every time.
///
/// It is a floor and not the height. What is in the card is four lines of text
/// and a bar, so a reader who has turned their type size up needs a taller
/// band — and a fixed one is where a `RenderFlex` overflow comes from, which is
/// this app telling somebody with poor eyesight that their setting is
/// unsupported.
const double continueReadingHeight = 116;

/// How much of [continueReadingHeight] is padding rather than text.
///
/// The card's own padding and the progress bar under it: the part of the band
/// that is the same height whatever the reader has set their type size to.
const double continueReadingPadding = 36;

/// How wide one card is at the ordinary text size.
///
/// It widens with the type size too, up to half again: a title at 200% in a
/// 240-pixel card is two words and an ellipsis.
const double continueReadingCardWidth = 240;

/// The strip of places to carry on from.
class ContinueReading extends StatelessWidget {
  /// The strip over [places].
  const ContinueReading({required this.places, super.key});

  /// Where each of this reader's devices stopped, most recent first.
  final List<ReadingPlace> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.libraryContinueReading,
            style: theme.textTheme.titleMedium,
          ),
        ),
        SizedBox(
          // The band grows with the reader's type size, because everything in
          // it is text. The bar and the padding do not, which is why the
          // scaler is applied to the height rather than the height being
          // multiplied by it.
          height:
              continueReadingPadding +
              MediaQuery.textScalerOf(context)
                  .scale(continueReadingHeight - continueReadingPadding),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: places.length,
            separatorBuilder: (BuildContext context, int _) =>
                const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) =>
                _PlaceCard(place: places[index]),
          ),
        ),
      ],
    );
  }
}

/// One device's place in one book.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final ReadingPlace place;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width:
          continueReadingCardWidth *
          MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          // Straight into the reader, which is what *continue* means. The book's
          // own screen is one tap further and is where somebody goes to look at
          // a book rather than to read it.
          onTap: () => context.go(Routes.readEbook(place.work.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  place.work.title, // l10n-ignore
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Icon(
                      place.onThisDevice
                          ? Icons.phone_android
                          : Icons.devices_other,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.onThisDevice
                            ? l10n.libraryContinueHere
                            : l10n.libraryContinueElsewhere,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // Absent rather than zero where nothing could compute one:
                    // a device that cannot open the format still records where
                    // it stopped, and a confident 0% would be a claim.
                    if (place.percent case final double percent)
                      Text(
                        l10n.libraryContinuePercent(percent.round()),
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: place.fraction,
                  minHeight: 3,
                  // A bar says nothing to a screen reader without these: the
                  // label is what it is a bar *of*, and the value is the one
                  // fact it carries. The percentage is the same sentence the
                  // card shows, which is deliberate — two wordings for one
                  // number would be two answers to *how far in am I*.
                  semanticsLabel: l10n.readingProgressLabel,
                  semanticsValue: l10n.readingPercentValue(
                    (place.percent ?? 0).round(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The row of groupings above the shelf.
///
/// The count rides on a chip as a badge rather than inside its label: a shelf
/// is chosen by how much is on it as often as by what it is called, and a label
/// built by interpolating a number into a name is a sentence in no language's
/// word order.
library;

import 'package:flutter/material.dart';

import '../../../domain/models/collection.dart';
import '../../core/localization/localization.dart';

/// The row of groupings above the shelf.
class ShelfFilter extends StatelessWidget {
  /// The row of [collections], with [counts] on them and [selected] chosen.
  const ShelfFilter({
    required this.collections,
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The reader's groupings.
  final List<Collection> collections;

  /// How many works are filed under each.
  final Map<String, int> counts;

  /// The one being shown, or `null` for all of them.
  final String? selected;

  /// What to do when the reader chooses one.
  final void Function(String? collectionId) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ChoiceChip(
              label: Text(l10n.libraryShowAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              // The count rides on the chip as a badge rather than inside its
              // label. A shelf is chosen by how much is on it as often as by
              // what it is called, and a label built by interpolating a number
              // into a name is a sentence in no language's word order.
              child: Badge.count(
                count: counts[collection.id] ?? 0,
                isLabelVisible: (counts[collection.id] ?? 0) > 0,
                child: ChoiceChip(
                  label: Text(collection.name),
                  tooltip: l10n.libraryBookCount(counts[collection.id] ?? 0),
                  selected: selected == collection.id,
                  onSelected: (_) => onSelected(collection.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

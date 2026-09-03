/// The works, as a grid or as a list, and the numbers that shape one.
///
/// **A grid on a wide window and a list on a narrow one**, decided by the width
/// the shelf was given and never by the platform — a desktop window dragged to
/// a third of the screen is a phone, and a browser is whatever the reader has
/// made it this second. The threshold is the navigation surface's own, so that
/// the two changes happen together rather than at two widths a reader would
/// notice separately.
///
/// **A cell's height is computed and not declared as a ratio.** It is a cover,
/// whose height follows its width, plus two lines of text, whose height follows
/// the reader's type size, and one ratio cannot be right for both.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/ebook.dart';
import '../../core/ui/adaptive_scaffold.dart';
import 'work_card.dart';

/// The width from which the shelf is a grid.
///
/// It is [compactWidth] deliberately. Below it the navigation goes under the
/// content and there is one column of room; above it there is space beside a
/// cover for a second one. Two thresholds a few pixels apart would be two
/// reflows as a window is dragged.
const double gridWidth = compactWidth;

/// How wide a cover is allowed to be before the grid adds a column.
///
/// A cover is taller than it is wide, and a shelf of them is read by scanning
/// across; a cell much wider than this stops looking like a book.
const double coverExtent = 180;

/// The proportions of a cover, which are roughly those of a paperback.
const double coverAspect = 2 / 3;

/// How much room the two lines under a cover need at the ordinary text size.
///
/// A title over two lines and an author over one, in `bodyMedium` and
/// `bodySmall`. It is the part of a grid cell that grows when a reader turns
/// their type size up, and reserving it is what a fixed `childAspectRatio`
/// could not do: at 200% the same cell had a cover of the same height and half
/// the text hanging out of the bottom of it.
const double coverLabelHeight = 56;

/// The gap between a cover and the lines under it, which is not text.
const double coverLabelGap = 8;

/// How much padding the grid has around it, per side.
const double shelfPadding = 16;

/// The gap between two cells, in both directions.
const double shelfSpacing = 16;

/// The works, as a grid or as a list.
class Shelf extends StatelessWidget {
  /// The shelf holding [works].
  const Shelf({required this.works, super.key});

  /// The works on it, in the order the reader asked for.
  final List<Ebook> works;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) =>
        constraints.maxWidth < gridWidth
        ? ListView.builder(
            itemCount: works.length,
            itemBuilder: (BuildContext context, int index) =>
                WorkTile(work: works[index]),
          )
        : _grid(context, constraints),
  );

  /// The shelf as a grid, with a cell tall enough for what is in it.
  ///
  /// **The height is computed rather than declared as a ratio.** A cell is a
  /// cover, whose height follows its width, plus two lines of text, whose
  /// height follows the reader's type size — and one number cannot be right for
  /// both. `childAspectRatio: 0.52` was right at 100% and overflowed at 130%.
  ///
  /// The columns are counted here the way the delegate counts them, so that the
  /// width this arithmetic is about is the width a cell actually gets.
  Widget _grid(BuildContext context, BoxConstraints constraints) {
    final available = constraints.maxWidth - shelfPadding * 2;
    // At least one, for a window narrower than a single cover: the delegate
    // refuses a count of zero, and a shelf is still a shelf at 200 pixels.
    final columns = math.max(
      1,
      (available / (coverExtent + shelfSpacing)).ceil(),
    );
    final cellWidth = (available - shelfSpacing * (columns - 1)) / columns;
    final labels = MediaQuery.textScalerOf(context).scale(coverLabelHeight);

    return GridView.builder(
      padding: const EdgeInsets.all(shelfPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: shelfSpacing,
        crossAxisSpacing: shelfSpacing,
        mainAxisExtent: cellWidth / coverAspect + coverLabelGap + labels,
      ),
      itemCount: works.length,
      itemBuilder: (BuildContext context, int index) =>
          WorkCard(work: works[index]),
    );
  }
}

/// How a reader likes a page.
///
/// **Every change applies as it is made.** There is no *apply* and no *cancel*,
/// because the thing being changed is visible behind the sheet: a reader turns
/// the size up, sees the page reflow, and turns it up again. A dialog that
/// collected the choices and applied them on dismissal would be asking somebody
/// to imagine the result of a decision they can simply look at.
///
/// **The sizes are steps and not a slider.** A slider over type size invites a
/// reader to hunt for a value they cannot name and cannot get back to. Eight
/// steps from small to very large is what anybody actually wants, and each one
/// is a size somebody would choose on purpose.
///
/// **It says once that this is local.** A reader who has set up a phone and
/// then opens the desktop should know why it did not follow — and the reason is
/// a good one rather than a missing feature, so it is stated rather than left
/// to be discovered.
library;

import 'package:flutter/material.dart';

import '../../../data/services/epub/epub_host.dart';
import '../../../data/services/storage/reader_settings_store.dart';
import '../../core/localization/localization.dart';
import '../view_model/reader_view_model.dart';
import 'over_the_page.dart';

/// Opens the appearance sheet over the page.
Future<void> showReaderSettings(BuildContext context, ReaderViewModel model) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // Wrapped for the reason `contents_sheet.dart` gives at the same line.
      builder: (BuildContext context) =>
          OverThePage(child: _ReaderSettingsSheet(model: model)),
    );

class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet({required this.model});

  final ReaderViewModel model;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? _) {
        final EpubStyle style = model.style;

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.readerSettingsExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _Stepped(
                    label: l10n.readerFontSize,
                    value: l10n.readerFontSizeValue(style.fontSize.round()),
                    steps: readerFontSizes,
                    current: style.fontSize,
                    onChanged: (double size) =>
                        model.restyle(style.copyWith(fontSize: size)),
                  ),
                  _Stepped(
                    label: l10n.readerLineHeight,
                    value: style.lineHeight.toStringAsFixed(1), // l10n-ignore
                    steps: readerLineHeights,
                    current: style.lineHeight,
                    onChanged: (double height) =>
                        model.restyle(style.copyWith(lineHeight: height)),
                  ),
                  _Stepped(
                    label: l10n.readerMargin,
                    value: l10n.readerFontSizeValue(
                      style.marginPercent.round(),
                    ),
                    steps: readerMargins,
                    current: style.marginPercent,
                    onChanged: (double margin) =>
                        model.restyle(style.copyWith(marginPercent: margin)),
                  ),

                  const SizedBox(height: 16),
                  Text(l10n.readerTheme, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<EpubTheme>(
                    segments: <ButtonSegment<EpubTheme>>[
                      ButtonSegment<EpubTheme>(
                        value: EpubTheme.followSystem,
                        label: Text(l10n.readerThemeSystem),
                      ),
                      ButtonSegment<EpubTheme>(
                        value: EpubTheme.light,
                        label: Text(l10n.readerThemeLight),
                      ),
                      ButtonSegment<EpubTheme>(
                        value: EpubTheme.sepia,
                        label: Text(l10n.readerThemeSepia),
                      ),
                      ButtonSegment<EpubTheme>(
                        value: EpubTheme.dark,
                        label: Text(l10n.readerThemeDark),
                      ),
                    ],
                    selected: <EpubTheme>{style.theme},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<EpubTheme> chosen) =>
                        model.restyle(style.copyWith(theme: chosen.first)),
                  ),

                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.readerSpread),
                    value: style.spread == EpubSpread.auto,
                    onChanged: (bool two) => model.restyle(
                      style.copyWith(
                        spread: two ? EpubSpread.auto : EpubSpread.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One setting, moved between the values it is allowed to take.
///
/// The two buttons step through [steps] rather than adding a constant, so that
/// a reader cannot land between two sizes and so that the smallest and the
/// largest are reachable and final — a control that keeps responding after it
/// has stopped changing anything is a control that lies.
class _Stepped extends StatelessWidget {
  const _Stepped({
    required this.label,
    required this.value,
    required this.steps,
    required this.current,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<double> steps;
  final double current;
  final ValueChanged<double> onChanged;

  /// Where [current] sits, or the nearest step to it.
  ///
  /// The nearest and not an exact match, because a preference written by an
  /// older build — or by a later one with a different list — is still a size
  /// this reader chose, and snapping to the closest is kinder than resetting.
  int get _index {
    int nearest = 0;

    for (int i = 1; i < steps.length; i++) {
      if ((steps[i] - current).abs() < (steps[nearest] - current).abs()) {
        nearest = i;
      }
    }

    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final int index = _index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          IconButton(
            onPressed: index == 0 ? null : () => onChanged(steps[index - 1]),
            icon: const Icon(Icons.remove),
            tooltip: label,
          ),
          SizedBox(
            width: 56,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: index == steps.length - 1
                ? null
                : () => onChanged(steps[index + 1]),
            icon: const Icon(Icons.add),
            tooltip: label,
          ),
        ],
      ),
    );
  }
}

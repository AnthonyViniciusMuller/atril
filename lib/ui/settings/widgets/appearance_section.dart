/// Light or dark, and whose colours.
///
/// **It is first on the screen and it is the only section that needs no
/// account.** Everything else here is about a reader, a node or a replica;
/// this is about the window in front of somebody, and it is the one thing on
/// this screen whose effect is visible while it is being changed — which is
/// why it applies as it is chosen and there is no *apply*, exactly as the
/// reader's own appearance sheet does it.
///
/// **The system's colours are offered only where there are any.** Android
/// below 12 has no wallpaper palette, iOS exposes no tint at all, a browser
/// has nothing to expose, and a desktop session may set no accent. The switch
/// is drawn when the platform actually answered with a colour rather than when
/// a list of targets says it should have: a control that is shown, moves, and
/// changes nothing is worse than a control that is not there.
///
/// **It says once that this is local.** The choice does not replicate, and a
/// reader who set a phone to dark and then opened the desktop should learn
/// that it is a decision and not a missing feature — the same sentence the
/// reading settings make about type size, for the same reason.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/localization.dart';
import '../../core/themes/appearance_view_model.dart';

/// The appearance section of the settings screen.
class AppearanceSection extends StatelessWidget {
  /// Creates the appearance section.
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final AppearanceViewModel model = context.watch<AppearanceViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.settingsAppearanceSection,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.settingsAppearanceExplanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              // The three the framework has, in the order a reader reasons
              // about them: the answer they have already given their device,
              // and then the two ways of overriding it.
              SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsAppearanceSystem),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsAppearanceLight),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsAppearanceDark),
                  ),
                ],
                selected: <ThemeMode>{model.mode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<ThemeMode> chosen) =>
                    model.choose(chosen.first),
              ),
            ],
          ),
        ),
        if (model.systemColorsOffered)
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsAppearanceSystemColors),
            subtitle: Text(l10n.settingsAppearanceSystemColorsExplanation),
            value: model.systemColors,
            onChanged: (bool use) => model.useSystemColors(use: use),
          ),
      ],
    );
  }
}

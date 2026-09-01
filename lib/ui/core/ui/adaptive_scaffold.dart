/// One navigation surface, expressed three ways.
///
/// The three are Material's own — a bar across the bottom, a rail down the
/// side, and a rail wide enough to carry its labels — and which one appears is
/// decided by **width and never by platform**. That is the whole point of the
/// widget. A desktop window dragged to a third of the screen is a phone; a
/// tablet in landscape is not; a browser is whatever the reader has made it
/// this second and may be something else before the next frame. A layout keyed
/// on `Platform.isAndroid` gets all three wrong, and it gets them wrong on the
/// target where the reader can see it happen.
///
/// The two thresholds are Material 3's window size classes, at the two places
/// this app has a reason to change:
///
/// * below [compactWidth] there is no room beside the content, so the surface
///   goes under it;
/// * from there to [expandedWidth] a rail costs eighty pixels of width and
///   buys back a bar's worth of height, which is the better trade when the
///   content is a list;
/// * above it there is room for the labels to sit beside their icons, and an
///   icon with its label read together is one glance rather than two.
///
/// It measures the space it was given rather than the window. On a phone those
/// are the same number; in a desktop window with something else beside it they
/// are not, and the one that decides whether a rail fits is this one.
///
/// **One destination carries a badge, and it is the only state this surface
/// shows.** How much this device has authored and not handed over is the one
/// fact a reader is entitled to have in front of them at all times — a reader
/// who cannot tell whether their notes are only on this phone has not been
/// given the guarantee the app makes — and it is a number on *Settings* rather
/// than a fourth destination, because synchronization is a property of the app
/// and not a place to visit. It is absent at zero, which is the ordinary state
/// and not news.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/sync/sync_repository.dart';
import '../../../routing/routes.dart';
import '../../sync/view_model/sync_view_model.dart';
import '../localization/localization.dart';

/// The width below which the navigation goes under the content.
///
/// Material 3 calls everything under it *compact*, and it is the width of a
/// phone held upright.
const double compactWidth = 600;

/// The width from which the rail carries its labels.
///
/// Material 3 calls everything from here up *large*. It is wider than the
/// *expanded* class starts, deliberately: an extended rail is 256 pixels, and
/// spending that out of 840 leaves a catalogue less room than the rail saved.
const double expandedWidth = 1200;

/// One destination of the shell.
final class Destination {
  /// A destination labelled [label], shown as [icon] and as [selectedIcon]
  /// while it is the one being looked at.
  const Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgesPendingChanges = false,
  });

  /// The icon of the destination.
  final IconData icon;

  /// Its icon while it is selected, which is the filled twin of [icon].
  final IconData selectedIcon;

  /// Its label, resolved against the strings of the current locale.
  ///
  /// It is a function and not a string because a destination is `const` and a
  /// translation is not: the label depends on the locale, which depends on the
  /// context, which does not exist where this list is written.
  final String Function(AppLocalizations l10n) label;

  /// Whether this destination shows the count of what has not been handed over.
  final bool badgesPendingChanges;
}

/// The destinations, in the order the branches of the router are declared.
///
/// The order is [Routes.shell]'s, and it has to stay that way: a navigation
/// surface reports the index it was tapped at and `StatefulNavigationShell`
/// resolves that index against its branches, so two orderings written
/// separately are two orderings that will disagree — silently, as a tap on
/// *Settings* opening the annotations.
const List<Destination> destinations = <Destination>[
  Destination(
    icon: Icons.local_library_outlined,
    selectedIcon: Icons.local_library,
    label: _library,
  ),
  Destination(
    icon: Icons.bookmarks_outlined,
    selectedIcon: Icons.bookmarks,
    label: _annotations,
  ),
  Destination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: _settings,
    badgesPendingChanges: true,
  ),
];

String _library(AppLocalizations l10n) => l10n.navigationLibrary;

String _annotations(AppLocalizations l10n) => l10n.navigationAnnotations;

String _settings(AppLocalizations l10n) => l10n.navigationSettings;

/// The shell around the destination the reader is looking at.
class AdaptiveScaffold extends StatefulWidget {
  /// The shell around [navigation], which is the branch currently shown and
  /// the thing that knows how to switch to another.
  const AdaptiveScaffold({required this.navigation, super.key});

  /// The router's shell: the current branch, its index, and `goBranch`.
  final StatefulNavigationShell navigation;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  late final SyncViewModel _sync = SyncViewModel(
    sync: context.read<SyncRepository>(),
  );

  StatefulNavigationShell get navigation => widget.navigation;

  @override
  void dispose() {
    _sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _sync,
    builder: (BuildContext context, Widget? _) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < compactWidth) {
          return _bar(context);
        }

        return _rail(context, extended: constraints.maxWidth >= expandedWidth);
      },
    ),
  );

  /// [icon], with the count of what has not left this device on it where
  /// [destination] is the one that carries it.
  ///
  /// Nothing is drawn at zero. A badge showing a nought would be a permanent
  /// mark reporting that everything is fine, which is the state a reader
  /// already assumes and the one thing a badge must not be spent on.
  Widget _badged(Destination destination, Widget icon) {
    if (!destination.badgesPendingChanges || _sync.state.isHandedOver) {
      return icon;
    }

    // What is counted is everything this device holds and no node does, which
    // includes what a node refused: both halves are still only here, and only
    // the screen behind the badge has room to say why they differ.
    return Badge.count(count: _sync.state.notHandedOver, child: icon);
  }

  /// Goes to the destination at [index].
  ///
  /// Tapping the destination already being looked at returns its branch to
  /// where it started, which is the behaviour every navigation bar has and the
  /// only way back out of a book from the bar that opened it.
  void _go(int index) => navigation.goBranch(
    index,
    initialLocation: index == navigation.currentIndex,
  );

  /// The compact layout: the destinations under the content.
  Widget _bar(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigation,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.currentIndex,
        onDestinationSelected: _go,
        destinations: <Widget>[
          for (final destination in destinations)
            NavigationDestination(
              icon: _badged(destination, Icon(destination.icon)),
              selectedIcon: _badged(
                destination,
                Icon(destination.selectedIcon),
              ),
              label: destination.label(l10n),
            ),
        ],
      ),
    );
  }

  /// The medium and large layouts: the destinations beside the content, with
  /// their labels under the icons or next to them.
  Widget _rail(BuildContext context, {required bool extended}) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Row(
        children: <Widget>[
          // The rail is inside the safe area and the content is not: the rail
          // must clear a notch or a home indicator, and a list that stopped
          // short of the bottom edge would look like it had ended.
          SafeArea(
            right: false,
            child: NavigationRail(
              selectedIndex: navigation.currentIndex,
              onDestinationSelected: _go,
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: _badged(destination, Icon(destination.icon)),
                    selectedIcon: _badged(
                      destination,
                      Icon(destination.selectedIcon),
                    ),
                    label: Text(destination.label(l10n)),
                  ),
              ],
            ),
          ),
          Expanded(child: navigation),
        ],
      ),
    );
  }
}

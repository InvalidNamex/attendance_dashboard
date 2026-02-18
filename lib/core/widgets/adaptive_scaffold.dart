import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../utils/responsive.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  List<NavDestination> _destinations(AppLocalizations l10n) {
    return [
      NavDestination(
        label: l10n.dashboard,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      NavDestination(
        label: l10n.users,
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
      ),
      NavDestination(
        label: l10n.transactions,
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
      NavDestination(
        label: l10n.reports,
        icon: Icons.assessment_outlined,
        selectedIcon: Icons.assessment,
      ),
      NavDestination(
        label: l10n.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = _destinations(l10n);
    final screenSize = Responsive.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return _MobileScaffold(
          currentIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          body: body,
          l10n: l10n,
        );
      case ScreenSize.tablet:
        return _TabletScaffold(
          currentIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          body: body,
          l10n: l10n,
        );
      case ScreenSize.desktop:
        return _DesktopScaffold(
          currentIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          body: body,
          l10n: l10n,
        );
    }
  }
}

// Mobile: Scaffold with hamburger drawer
class _MobileScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget body;
  final AppLocalizations l10n;

  const _MobileScaffold({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(destinations[currentIndex].label)),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final selected = index == currentIndex;
                  return ListTile(
                    leading: Icon(
                      selected ? dest.selectedIcon : dest.icon,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(
                      dest.label,
                      style: TextStyle(
                        color: selected ? theme.colorScheme.primary : null,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDestinationSelected(index);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: body,
    );
  }
}

// Tablet: NavigationRail (collapsed)
class _TabletScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget body;
  final AppLocalizations l10n;

  const _TabletScaffold({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.admin_panel_settings,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: l10n.logout,
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
              ),
            ),
            destinations: destinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: Text(dest.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// Desktop: Expanded sidebar with icons + labels
class _DesktopScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget body;
  final AppLocalizations l10n;

  const _DesktopScaffold({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Material(
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.appTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final dest = destinations[index];
                        final selected = index == currentIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            leading: Icon(
                              selected ? dest.selectedIcon : dest.icon,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              dest.label,
                              style: TextStyle(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: selected,
                            selectedTileColor: theme
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () => onDestinationSelected(index),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.logout),
                    onTap: () => _showLogoutDialog(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.logout),
      content: Text(l10n.logoutConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuthBloc>().add(const LogoutRequested());
          },
          child: Text(l10n.logout),
        ),
      ],
    ),
  );
}

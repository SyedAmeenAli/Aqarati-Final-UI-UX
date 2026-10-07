import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Bottom nav with a raised center action button — matches the Figma home
/// screen exactly (Home / Explore / [+ create] / Messages / Profile).
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (route: '/home', icon: AppIcons.home, selectedIcon: AppIcons.homeSelected, label: 'Home'),
    (route: '/explore', icon: AppIcons.explore, selectedIcon: AppIcons.exploreSelected, label: 'Explore'),
    (route: '/messages', icon: AppIcons.messages, selectedIcon: AppIcons.messagesSelected, label: 'Messages'),
    (route: '/profile', icon: AppIcons.profile, selectedIcon: Icons.person_rounded, label: 'Profile'),
  ];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((t) => location.startsWith(t.route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    // Center FAB splits the 4 real tabs into two pairs either side of it.
    final left = _tabs.sublist(0, 2);
    final right = _tabs.sublist(2, 4);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: AppIconSize.md),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: AppSpacing.sm,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final tab in left) _NavItem(tab: tab, selected: _tabs.indexOf(tab) == currentIndex),
            const SizedBox(width: AppSpacing.xxl), // room for the notch
            for (final tab in right) _NavItem(tab: tab, selected: _tabs.indexOf(tab) == currentIndex),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.home_work_outlined, color: AppColors.primary),
                title: const Text('List a property'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.design_services_outlined, color: AppColors.primary),
                title: const Text('Request a service'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ({String route, IconData icon, IconData selectedIcon, String label}) tab;
  final bool selected;

  const _NavItem({required this.tab, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.mist;
    return InkWell(
      onTap: () => context.go(tab.route),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: AppIconSize.md),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

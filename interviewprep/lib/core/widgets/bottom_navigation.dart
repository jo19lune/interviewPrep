import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

// Use the browser/engine URL for current location to avoid go_router API mismatch

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  bool _isSelected(String currentLocation, String itemRoute) {
    if (currentLocation == itemRoute) return true;
    if (itemRoute == '/dashboard' && currentLocation == '/') return true;
    return currentLocation.startsWith(itemRoute);
  }

  @override
  Widget build(BuildContext context) {
    final location = Uri.base.path;
    final items = [
      _NavItem(route: '/dashboard', icon: Icons.dashboard, label: 'Dashboard'),
      _NavItem(route: '/exercises', icon: Icons.quiz, label: 'Exercises'),
      _NavItem(route: '/simulation', icon: Icons.mic, label: 'Simulation'),
      _NavItem(route: '/statistics', icon: Icons.bar_chart, label: 'Insights'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: AppTheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              final selected = _isSelected(location, item.route);
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!selected) {
                      GoRouter.of(context).go(item.route);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.secondaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 22, color: selected ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;

  const _NavItem({required this.route, required this.icon, required this.label});
}

import 'package:flutter/material.dart';
import 'package:tunely/core/themes/app_colors.dart';

/// Bottom navigation bar reutilizable para toda la app.
/// Úsalo en tu ShellRoute de go_router para que persista entre pantallas.
class TunelyBottomNav extends StatelessWidget {
  final int    currentIndex;
  final void Function(int) onTap;

  const TunelyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded,         label: 'Home'),
    _NavItem(icon: Icons.search_rounded,        label: 'Add'),
    _NavItem(icon: Icons.notifications_outlined,label: 'Activity'),
    _NavItem(icon: Icons.person_outline_rounded,label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navBarDark : cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final isSelected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[i].icon,
                        size: 24,
                        color: isSelected
                            ? AppColors.primary
                            : cs.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

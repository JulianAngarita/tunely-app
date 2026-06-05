import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: tt.titleLarge?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

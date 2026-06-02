import 'package:flutter/material.dart';
import 'package:tunely/core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../home_screen.dart';

class ActivityItem extends StatelessWidget {
  final ActivityModel activity;
  const ActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: isDark
          ? BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            )
          : null, // en light no hay card, es solo texto sobre fondo
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _UserAvatar(
            initial: activity.initial,
            color:   activity.avatarColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RichActivityText(activity: activity),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initial;
  final Color  color;
  const _UserAvatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RichActivityText extends StatelessWidget {
  final ActivityModel activity;
  const _RichActivityText({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final baseStyle = tt.bodyMedium?.copyWith(
      color: cs.onSurface,
      fontSize: 14,
    );

    final parts = activity.richText.split('  ');
    final hasEmoji = activity.emoji != null && parts.length > 1;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '${activity.boldName} ',
            style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (!hasEmoji)
            TextSpan(text: activity.richText),
          if (hasEmoji) ...[
            TextSpan(text: parts[0]),
            TextSpan(text: ' ${activity.emoji!} '),
            TextSpan(text: parts[1]),
          ],
        ],
      ),
    );
  }
}

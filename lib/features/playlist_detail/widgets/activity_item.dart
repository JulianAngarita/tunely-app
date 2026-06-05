import 'package:flutter/material.dart';
import 'package:tunely/features/playlist_detail/models/playlist_activity_model.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ActivityItem extends StatelessWidget {
  final PlaylistActivityModel activity;
  const ActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _UserAvatar(initial: activity.userInitial, color: activity.userColor),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      activity.icon,
                      size: 14,
                      color: activity.iconColor(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.description,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.4),
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

// ─── USER AVATAR ───────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  const _UserAvatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

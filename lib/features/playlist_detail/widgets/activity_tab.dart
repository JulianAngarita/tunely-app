import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/features/playlist_detail/providers/playlist_activity_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'activity_item.dart';

class ActivityTab extends ConsumerWidget {
  final String playlistId;
  const ActivityTab({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(playlistActivityProvider(playlistId));

    return activityAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(playlistActivityProvider(playlistId)),
      ),
      data: (activities) => activities.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: activities.length,
              itemBuilder: (_, i) => ActivityItem(activity: activities[i]),
            ),
    );
  }
}

// ─── ERROR STATE ───────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Could not load activity',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No activity yet',
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Activity will appear here when\nsomeone adds or removes songs',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}

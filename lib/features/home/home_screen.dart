import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/themes/app_colors.dart';
import 'package:tunely/features/home/create_playlist_screen.dart';
import '../../core/constants/app_spacing.dart';
import 'providers/playlists_provider.dart';
import 'providers/activity_provider.dart';
import 'widgets/playlist_card.dart';
import 'widgets/activity_item.dart';
import 'widgets/section_header.dart';
import 'package:go_router/go_router.dart';
// ─── SCREEN ────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = ref.watch(playlistsProvider);
    final activity = ref.watch(activityProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            // Pull to refresh invalida ambos providers
            onRefresh: () async {
              ref.invalidate(playlistsProvider);
              ref.invalidate(activityProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HomeAppBar(
                    onAddTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.92,
                          maxChildSize: 0.92,
                          minChildSize: 0.5,
                          builder: (_, controller) => CreatePlaylistScreen(
                            onCreated: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Shared Playlists ────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Shared Playlists',
                    actionLabel: 'See All',
                    onActionTap: () {
                      // TODO: navegar a todas las playlists
                    },
                  ),
                ),

                // Estado de playlists: loading / error / data
                playlists.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: _PlaylistsShimmer()),
                  error: (err, _) => SliverToBoxAdapter(
                    child: _ErrorRetry(
                      message: 'Could not load playlists',
                      onRetry: () => ref.invalidate(playlistsProvider),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? const SliverToBoxAdapter(child: _EmptyPlaylists())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ).copyWith(bottom: AppSpacing.sm),
                              child: PlaylistCard(
                                playlist: list[i],
                                onTap: () =>
                                    context.push('/playlist/${list[i].id}'),
                              ),
                            ),
                            childCount: list.length,
                          ),
                        ),
                ),

                // ── Recent Activity ─────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Recent Activity',
                    actionLabel: 'View All',
                    onActionTap: () {
                      // TODO: navegar a actividad completa
                    },
                  ),
                ),

                // Estado de activity: loading / error / data
                activity.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: _ActivityShimmer()),
                  error: (err, _) => SliverToBoxAdapter(
                    child: _ErrorRetry(
                      message: 'Could not load activity',
                      onRetry: () => ref.invalidate(activityProvider),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? const SliverToBoxAdapter(child: _EmptyActivity())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ).copyWith(bottom: AppSpacing.sm),
                              child: ActivityItem(activity: list[i]),
                            ),
                            childCount: list.length,
                          ),
                        ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── APP BAR ───────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final VoidCallback onAddTap;
  const _HomeAppBar({required this.onAddTap});

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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tunely',
                  style: tt.displayLarge?.copyWith(color: cs.onSurface),
                ),
                Text(
                  'Music together',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOADING SHIMMER ───────────────────────────────────────────

class _PlaylistsShimmer extends StatelessWidget {
  const _PlaylistsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: _ShimmerBox(height: 88, radius: AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _ActivityShimmer extends StatelessWidget {
  const _ActivityShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: _ShimmerBox(height: 64, radius: AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── ERROR STATE ───────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 40,
            color: cs.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: tt.bodyMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATES ──────────────────────────────────────────────

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 48,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No playlists yet',
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap + to create your first shared playlist',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Text(
        'No activity yet — invite someone to collaborate!',
        textAlign: TextAlign.center,
        style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3)),
      ),
    );
  }
}

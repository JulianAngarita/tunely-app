import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/core/themes/app_colors.dart';
import 'package:tunely/core/providers/auth_provider.dart';
import 'package:tunely/features/home/create_playlist_screen.dart';
import '../../core/constants/app_spacing.dart';
import 'providers/playlists_provider.dart';
import 'providers/activity_provider.dart';
import 'widgets/playlist_card.dart';
import 'widgets/activity_item.dart';
import 'widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = ref.watch(playlistsProvider);
    final activity = ref.watch(activityProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'there';
    final greeting = _greeting();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
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
                    greeting: greeting,
                    userName: userName,
                    onAddTap: () => _showCreatePlaylist(context),
                  ),
                ),

                // ── Shared Playlists ────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Shared Playlists',
                    actionLabel: 'See All',
                    onActionTap: () {},
                  ),
                ),

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
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
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
                ),

                // ── Recent Activity ─────────────────────────────
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Recent Activity',
                    actionLabel: 'View All',
                    onActionTap: () {},
                  ),
                ),

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
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: ActivityItem(
                                  activity: list[i],
                                  onTap: list[i].playlistId != null
                                      ? () => context.push(
                                          '/playlist/${list[i].playlistId}',
                                        )
                                      : null,
                                ),
                              ),
                              childCount: list.length,
                            ),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _showCreatePlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, __) =>
            CreatePlaylistScreen(onCreated: () => Navigator.of(context).pop()),
      ),
    );
  }
}

// ─── APP BAR ───────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final String greeting;
  final String userName;
  final VoidCallback onAddTap;

  const _HomeAppBar({
    required this.greeting,
    required this.userName,
    required this.onAddTap,
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
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  userName,
                  style: tt.displayLarge?.copyWith(
                    color: cs.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Botón crear playlist
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHIMMER ───────────────────────────────────────────────────

class _PlaylistsShimmer extends StatelessWidget {
  const _PlaylistsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ShimmerBox(height: 80, radius: AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _ActivityShimmer extends StatelessWidget {
  const _ActivityShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ShimmerBox(height: 64, radius: AppSpacing.radiusLg),
          ),
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
      width: double.infinity,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
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

// ─── EMPTY PLAYLISTS ───────────────────────────────────────────

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No playlists yet',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create your first shared playlist\nand invite friends to collaborate',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create playlist'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EMPTY ACTIVITY ────────────────────────────────────────────

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSurface.withOpacity(0.06),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 20,
              color: cs.onSurface.withOpacity(0.25),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'No activity yet — invite someone to collaborate!',
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }
}

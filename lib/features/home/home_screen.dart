import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tunely/core/themes/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'widgets/playlist_card.dart';
import 'widgets/activity_item.dart';
import 'widgets/section_header.dart';

// ─── MODELS ────────────────────────────────────────────────────

enum SyncStatus { synced, syncing, error }

class PlaylistModel {
  final String id;
  final String name;
  final int trackCount;
  final List<Color> coverGradient;
  final List<String> memberInitials;
  final List<Color> memberColors;
  final SyncStatus syncStatus;
  final String syncLabel;   // "2 hours ago", "1 day ago", etc.

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.coverGradient,
    required this.memberInitials,
    required this.memberColors,
    required this.syncStatus,
    required this.syncLabel,
  });
}

class ActivityModel {
  final String id;
  final String initial;
  final Color  avatarColor;
  final String richText;    // e.g. "Sarah added Blinding Lights"
  final String boldName;    // e.g. "Sarah" — se pone en bold
  final String subtitle;    // e.g. "The Weeknd · 2h ago"
  final String? emoji;      // opcional, e.g. "❤️"

  const ActivityModel({
    required this.id,
    required this.initial,
    required this.avatarColor,
    required this.richText,
    required this.boldName,
    required this.subtitle,
    this.emoji,
  });
}

// ─── MOCK DATA (reemplazar con datos reales del provider) ───────

final _mockPlaylists = [
  PlaylistModel(
    id: '1',
    name: 'Our Summer Vibes',
    trackCount: 42,
    coverGradient: [const Color(0xFFFF6B9D), const Color(0xFFFF8E6E)],
    memberInitials: ['S', 'Y'],
    memberColors: [const Color(0xFFE91E8C), const Color(0xFF7C4DFF)],
    syncStatus: SyncStatus.synced,
    syncLabel: '2 hours ago',
  ),
  PlaylistModel(
    id: '2',
    name: 'Road Trip Mix',
    trackCount: 87,
    coverGradient: [const Color(0xFF4DD0E1), const Color(0xFF26C6DA)],
    memberInitials: ['A', 'J', 'Y'],
    memberColors: [
      const Color(0xFF4CAF50),
      const Color(0xFFE91E8C),
      const Color(0xFF7C4DFF),
    ],
    syncStatus: SyncStatus.synced,
    syncLabel: '1 day ago',
  ),
  PlaylistModel(
    id: '3',
    name: 'Study Sessions',
    trackCount: 23,
    coverGradient: [const Color(0xFF7C4DFF), const Color(0xFF9C6FFF)],
    memberInitials: ['M', 'Y'],
    memberColors: [const Color(0xFFE91E8C), const Color(0xFF7C4DFF)],
    syncStatus: SyncStatus.syncing,
    syncLabel: '3 days ago',
  ),
];

final _mockActivity = [
  ActivityModel(
    id: '1',
    initial: 'S',
    avatarColor: const Color(0xFFFFB3C6),
    richText: 'added Blinding Lights',
    boldName: 'Sarah',
    subtitle: 'The Weeknd · 2h ago',
  ),
  ActivityModel(
    id: '2',
    initial: 'A',
    avatarColor: const Color(0xFF80DEEA),
    richText: 'reacted  to Levitating',
    boldName: 'Alex',
    subtitle: 'Dua Lipa · 5h ago',
    emoji: '❤️',
  ),
];

// ─── SCREEN ────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _HomeAppBar(
                  onAddTap: () {
                    // TODO: navegar a crear playlist
                  },
                ),
              ),

              // ── Shared Playlists ──────────────────────────────
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Shared Playlists',
                  actionLabel: 'See All',
                  onActionTap: () {
                    // TODO: navegar a todas las playlists
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ).copyWith(bottom: AppSpacing.sm),
                    child: PlaylistCard(
                      playlist: _mockPlaylists[i],
                      onTap: () {
                        // TODO: navegar a detalle de playlist
                      },
                    ),
                  ),
                  childCount: _mockPlaylists.length,
                ),
              ),

              // ── Recent Activity ───────────────────────────────
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent Activity',
                  actionLabel: 'View All',
                  onActionTap: () {
                    // TODO: navegar a actividad completa
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ).copyWith(bottom: AppSpacing.sm),
                    child: ActivityItem(activity: _mockActivity[i]),
                  ),
                  childCount: _mockActivity.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
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
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Title + subtitle
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

          // FAB circular
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

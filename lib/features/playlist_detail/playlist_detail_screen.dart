import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/features/add_song/add_song_screen.dart';
import 'package:tunely/features/home/providers/playlists_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'providers/playlist_detail_provider.dart';
import 'models/playlist_detail_model.dart';
import 'widgets/song_card.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showOptionsMenu(PlaylistDetailModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(
        playlist: playlist,
        canDelete: playlist.userRole == 'owner',
        canEdit: playlist.userRole == 'owner' || playlist.userRole == 'admin',
        onDelete: () => _deletePlaylist(playlist),
        onShare: () {
          Navigator.pop(context);
          _showShareSheet(playlist);
        },
        onEdit: () {
          Navigator.pop(context); /* TODO */
        },
        onAddSong: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSongScreen(
                playlistId: playlist.id,
                playlistName: playlist.name,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showShareSheet(PlaylistDetailModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        playlistName: playlist.name,
        inviteCode: playlist.inviteCode,
      ),
    );
  }

  Future<void> _deletePlaylist(PlaylistDetailModel playlist) async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete playlist'),
        content: Text('Delete "${playlist.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(deletePlaylistProvider(widget.playlistId).future);
        ref.invalidate(playlistsProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistDetailProvider(widget.playlistId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: playlistAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: AppSpacing.md),
                const Text('Could not load playlist'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(playlistDetailProvider(widget.playlistId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (playlist) => _Body(
            playlist: playlist,
            tabController: _tabController,
            onBack: () => context.pop(),
            onShare: () => _showShareSheet(playlist),
            onOptions: () => _showOptionsMenu(playlist),
          ),
        ),
      ),
    );
  }
}

// ─── BODY ──────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final PlaylistDetailModel playlist;
  final TabController tabController;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onOptions;

  const _Body({
    required this.playlist,
    required this.tabController,
    required this.onBack,
    required this.onShare,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete =
        playlist.userRole == 'owner' || playlist.userRole == 'admin';

    return Column(
      children: [
        // ── Gradient header ─────────────────────────────────
        _GradientHeader(
          playlist: playlist,
          onBack: onBack,
          onShare: onShare,
          onOptions: onOptions,
        ),
        const SizedBox(height: 24),
        // ── Tab bar pill ────────────────────────────────────
        _PillTabBar(controller: tabController),

        // ── Tab content ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _SongsTab(playlist: playlist, canDelete: canDelete),
              _ActivityTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── GRADIENT HEADER ───────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final PlaylistDetailModel playlist;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onOptions;

  const _GradientHeader({
    required this.playlist,
    required this.onBack,
    required this.onShare,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: playlist.coverGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nav row
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: onBack,
                      ),
                      const Spacer(),
                      _CircleButton(icon: Icons.share_rounded, onTap: onShare),
                      const SizedBox(width: AppSpacing.sm),
                      _CircleButton(
                        icon: Icons.more_vert_rounded,
                        onTap: onOptions,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Playlist name
                  Text(
                    playlist.name,
                    style: tt.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Members + song count
                  Row(
                    children: [
                      // Overlapping member avatars
                      SizedBox(
                        width:
                            28.0 +
                            20.0 * (playlist.members.length - 1).clamp(0, 3),
                        height: 28,
                        child: Stack(
                          children: playlist.members
                              .take(3)
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                                return Positioned(
                                  left: e.key * 20.0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: e.value.color,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      e.value.initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${playlist.songs.length} songs · ${playlist.totalDurationLabel}',
                        style: tt.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play FAB flotando en la esquina inferior derecha
            Positioned(
              right: AppSpacing.md,
              bottom: -24,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.2),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── PILL TAB BAR ──────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  final TabController controller;
  const _PillTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: isDark ? AppColors.backgroundDark : cs.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: cs.onSurface,
          unselectedLabelColor: cs.onSurface.withOpacity(0.4),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
    );
  }
}

// ─── SONGS TAB ─────────────────────────────────────────────────

class _SongsTab extends StatelessWidget {
  final PlaylistDetailModel playlist;
  final bool canDelete;
  const _SongsTab({required this.playlist, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: 80, // espacio para el botón Add a song,
          ),
          children: [
            // Sync banner
            _SyncBanner(),
            if (playlist.songs.isEmpty)
              Padding(
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
                      'No songs yet',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...playlist.songs.map(
                (song) => SongCard(
                  song: song,
                  canDelete: canDelete,
                  onDelete: () {
                    /* TODO */
                  },
                ),
              ),
          ],
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: cs.onSurface.withOpacity(0.08)),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSongScreen(
                      playlistId: playlist.id,
                      playlistName: playlist.name,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: cs.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Add a song',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SYNC BANNER ───────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.synced.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.synced.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.synced,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Synced across platforms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.synced,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.sync_rounded, color: AppColors.synced, size: 18),
        ],
      ),
    );
  }
}

// ─── ACTIVITY TAB ──────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
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
            'Activity coming soon',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OPTIONS SHEET ─────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  final PlaylistDetailModel playlist;
  final bool canDelete;
  final bool canEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onAddSong;

  const _OptionsSheet({
    required this.playlist,
    required this.canDelete,
    required this.canEdit,
    required this.onDelete,
    required this.onShare,
    required this.onEdit,
    required this.onAddSong,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _OptionItem(
            icon: Icons.person_add_rounded,
            label: 'Invite collaborators',
            color: AppColors.primary,
            onTap: onShare,
          ),
          _OptionItem(
            icon: Icons.queue_music_rounded,
            label: 'Add songs',
            color: cs.onSurface,
            onTap: onAddSong,
          ),
          if (canEdit)
            _OptionItem(
              icon: Icons.edit_rounded,
              label: 'Edit playlist',
              color: cs.onSurface,
              onTap: onEdit,
            ),
          if (canDelete) ...[
            Divider(
              color: cs.onSurface.withOpacity(0.1),
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
            _OptionItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete playlist',
              color: Colors.red,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}

// ─── SHARE SHEET ───────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  final String playlistName;
  final String inviteCode;

  const _ShareSheet({required this.playlistName, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Invite to "$playlistName"',
            style: tt.titleLarge?.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Share this code with your friends',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              inviteCode.toUpperCase(),
              textAlign: TextAlign.center,
              style: tt.displayLarge?.copyWith(
                color: AppColors.primary,
                letterSpacing: 8,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Code copied!')));
              },
              icon: const Icon(Icons.copy_rounded, color: Colors.white),
              label: Text(
                'Copy code',
                style: tt.labelLarge?.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

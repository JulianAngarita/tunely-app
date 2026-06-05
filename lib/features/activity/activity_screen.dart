import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';

// ─── MODEL ─────────────────────────────────────────────────────

class GlobalActivityModel {
  final String id;
  final String action;
  final String userName;
  final String userInitial;
  final Color userColor;
  final String? playlistId;
  final String? playlistName;
  final String timeAgo;
  final String description;
  final String? songTitle;
  final String? songArtist;
  final String? comment;

  const GlobalActivityModel({
    required this.id,
    required this.action,
    required this.userName,
    required this.userInitial,
    required this.userColor,
    this.playlistId,
    this.playlistName,
    required this.timeAgo,
    required this.description,
    this.songTitle,
    this.songArtist,
    this.comment,
  });

  static final _colors = [
    const Color(0xFFE91E8C),
    const Color(0xFF7C4DFF),
    const Color(0xFF4CAF50),
    const Color(0xFF4DD0E1),
    const Color(0xFFFF9800),
  ];

  IconData get actionIcon {
    switch (action) {
      case 'song_added':
        return Icons.music_note_rounded;
      case 'song_removed':
        return Icons.remove_rounded;
      case 'member_joined':
        return Icons.person_add_outlined;
      case 'playlist_edited':
        return Icons.edit_outlined;
      case 'sync_completed':
        return Icons.sync_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get actionIconColor {
    switch (action) {
      case 'song_added':
      case 'member_joined':
      case 'sync_completed':
        return AppColors.synced;
      case 'song_removed':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  factory GlobalActivityModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final playlist = json['playlists'] as Map<String, dynamic>?;
    final name = (user?['name'] as String?) ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colorIdx = name.codeUnitAt(0) % _colors.length;
    final action = (json['action'] as String?) ?? '';
    final details = json['details'] as Map<String, dynamic>?;
    final songTitle = details?['title'] as String?;
    final songArtist = details?['artist'] as String?;

    final timeAgo = _formatTimeAgo(
      json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );

    final description = _buildDescription(action, name, songTitle);

    return GlobalActivityModel(
      id: (json['id'] as String?) ?? '',
      action: action,
      userName: name,
      userInitial: initial,
      userColor: _colors[colorIdx],
      playlistId: json['playlist_id'] as String?,
      playlistName: playlist?['name'] as String?,
      timeAgo: timeAgo,
      description: description,
      songTitle: songTitle,
      songArtist: songArtist,
    );
  }

  static String _buildDescription(
    String action,
    String name,
    String? songTitle,
  ) {
    switch (action) {
      case 'song_added':
        return songTitle != null
            ? '$name added $songTitle'
            : '$name added a song';
      case 'song_removed':
        return songTitle != null
            ? '$name removed $songTitle'
            : '$name removed a song';
      case 'member_joined':
        return '$name joined the playlist';
      case 'playlist_edited':
        return '$name edited the playlist';
      case 'sync_completed':
        return 'Playlist synced successfully';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  static String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ─── PROVIDER ──────────────────────────────────────────────────

final globalActivityProvider =
    FutureProvider.autoDispose<List<GlobalActivityModel>>((ref) async {
      final router = ref.watch(routerProvider);
      final client = ref.watch(apiClientProvider(router));

      final response = await client.get('/users/me/activity');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final list = data['activity'] as List<dynamic>? ?? [];

      return list
          .map((e) => GlobalActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });

// ─── SCREEN ────────────────────────────────────────────────────

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final activityAsync = ref.watch(globalActivityProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: tt.displayLarge?.copyWith(
                        color: cs.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What\'s happening with your music',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: cs.onSurface.withOpacity(0.06), height: 1),

              // ── Content ─────────────────────────────────
              Expanded(
                child: activityAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: cs.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Could not load activity',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(globalActivityProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(globalActivityProvider),
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: list.length,
                            itemBuilder: (_, i) => _ActivityItem(
                              activity: list[i],
                              onTap: list[i].playlistId != null
                                  ? () => context.push(
                                      '/playlist/${list[i].playlistId}',
                                    )
                                  : null,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ACTIVITY ITEM ─────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final GlobalActivityModel activity;
  final VoidCallback? onTap;

  const _ActivityItem({required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar with action icon badge ──────────
            _AvatarWithBadge(activity: activity),
            const SizedBox(width: AppSpacing.md),

            // ── Content ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description (bold name + action)
                  _ActivityRichText(activity: activity),
                  const SizedBox(height: 2),

                  // Playlist name
                  if (activity.playlistName != null)
                    Text(
                      'in ${activity.playlistName}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),

                  // Comment bubble if exists
                  if (activity.comment != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        activity.comment!,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    activity.timeAgo,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── Chevron if tappable ──────────────────────
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurface.withOpacity(0.2),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── AVATAR WITH BADGE ─────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  final GlobalActivityModel activity;
  const _AvatarWithBadge({required this.activity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activity.userColor.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Text(
              activity.userInitial,
              style: TextStyle(
                color: activity.userColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Action badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activity.actionIconColor.withOpacity(0.15),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                activity.actionIcon,
                size: 10,
                color: activity.actionIconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RICH TEXT ─────────────────────────────────────────────────

class _ActivityRichText extends StatelessWidget {
  final GlobalActivityModel activity;
  const _ActivityRichText({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final base = tt.bodyMedium?.copyWith(color: cs.onSurface, fontSize: 14);

    // Separar el nombre del resto de la descripción
    final desc = activity.description;
    final nameEnd = activity.userName.length;
    final afterName = desc.length > nameEnd ? desc.substring(nameEnd) : '';

    // Si hay artista, añadirlo en gris
    final hasSongInfo =
        activity.songArtist != null && activity.songArtist!.isNotEmpty;

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(
            text: activity.userName,
            style: base?.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: afterName),
          if (hasSongInfo)
            TextSpan(
              text: ' by ${activity.songArtist}',
              style: base?.copyWith(color: cs.onSurface.withOpacity(0.5)),
            ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSurface.withOpacity(0.06),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 36,
              color: cs.onSurface.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No activity yet',
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Activity will appear here when\nyou or your collaborators add songs',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

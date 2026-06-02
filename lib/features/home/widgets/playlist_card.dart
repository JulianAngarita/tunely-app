import 'package:flutter/material.dart';
import 'package:tunely/core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../home_screen.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback?  onTap;

  const PlaylistCard({super.key, required this.playlist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // ── Cover ────────────────────────────────────────
              _PlaylistCover(gradient: playlist.coverGradient),
              const SizedBox(width: AppSpacing.md),

              // ── Name + members + tracks ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: tt.titleMedium?.copyWith(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MemberAvatars(
                          initials: playlist.memberInitials,
                          colors:   playlist.memberColors,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${playlist.trackCount} tracks',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Sync status ───────────────────────────────────
              _SyncBadge(
                syncStatus: playlist.syncStatus,
                timeLabel: playlist.syncLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── COVER ─────────────────────────────────────────────────────

class _PlaylistCover extends StatelessWidget {
  final List<Color> gradient;
  const _PlaylistCover({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

// ─── MEMBER AVATARS (overlapping) ──────────────────────────────

class _MemberAvatars extends StatelessWidget {
  final List<String> initials;
  final List<Color>  colors;
  const _MemberAvatars({required this.initials, required this.colors});

  static const _size   = 22.0;
  static const _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // ancho total: primer avatar + cada siguiente desplazado
      width: _size + (_size - _overlap) * (initials.length - 1),
      height: _size,
      child: Stack(
        children: List.generate(initials.length, (i) {
          return Positioned(
            left: i * (_size - _overlap),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i % colors.length],
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── SYNC BADGE ────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  final SyncStatus syncStatus;
  final String     timeLabel;
  const _SyncBadge({required this.syncStatus, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isSynced  = syncStatus == SyncStatus.synced;
    final isSyncing = syncStatus == SyncStatus.syncing;

    final statusColor = isSynced
        ? AppColors.synced
        : cs.onSurface.withOpacity(0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Punto o ícono de reloj
            isSyncing
                ? Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: statusColor,
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
            const SizedBox(width: 4),
            Text(
              isSynced ? 'Synced' : 'Syncing',
              style: tt.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          timeLabel,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

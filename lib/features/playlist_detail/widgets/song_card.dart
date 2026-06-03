import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/playlist_detail_model.dart';

class _Reaction {
  final String emoji;
  final int count;
  const _Reaction(this.emoji, this.count);
}

// ─── SONG CARD ─────────────────────────────────────────────────

class SongCard extends StatelessWidget {
  final SongModel song;
  final bool canDelete;
  final VoidCallback? onDelete;

  const SongCard({
    super.key,
    required this.song,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main content ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    // Music note
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: song.coverUrl != null
                          ? Image.network(
                              song.coverUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _MusicNoteIcon(),
                            )
                          : _MusicNoteIcon(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const SizedBox(width: AppSpacing.sm),

                    // Title + artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: tt.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Duration + delete
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.durationLabel,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                        if (canDelete) ...[
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Colors.red.withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Added by + platform
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: song.addedByColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        song.addedByInitial ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Added by ${song.addedByName ?? 'Unknown'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _PlatformDot(status: song.availabilityStatus),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Reactions row
                // Row(
                //   children: [
                //     // Existing reactions
                //     ...reactions.map((r) => _ReactionChip(reaction: r)),

                //     // Add reaction button
                //     GestureDetector(
                //       onTap: () {}, // visual only
                //       child: Container(
                //         width: 28,
                //         height: 28,
                //         margin: const EdgeInsets.only(left: 4),
                //         decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           color: cs.onSurface.withOpacity(0.08),
                //         ),
                //         child: Icon(
                //           Icons.add_rounded,
                //           size: 14,
                //           color: cs.onSurface.withOpacity(0.4),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),

          // ── Comment (si existe) ────────────────────────────
          // if (comment != null)
          //   Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(
          //       horizontal: AppSpacing.md,
          //       vertical: AppSpacing.sm,
          //     ),
          //     decoration: BoxDecoration(
          //       color: isDark
          //           ? Colors.white.withOpacity(0.04)
          //           : Colors.black.withOpacity(0.04),
          //       borderRadius: const BorderRadius.vertical(
          //         bottom: Radius.circular(AppSpacing.radiusLg),
          //       ),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           Icons.chat_bubble_outline_rounded,
          //           size: 14,
          //           color: cs.onSurface.withOpacity(0.4),
          //         ),
          //         const SizedBox(width: 8),
          //         Expanded(
          //           child: Text(
          //             comment,
          //             style: tt.bodySmall?.copyWith(
          //               color: cs.onSurface.withOpacity(0.6),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }
}

// ─── REACTION CHIP ─────────────────────────────────────────────

class _ReactionChip extends StatelessWidget {
  final _Reaction reaction;
  const _ReactionChip({required this.reaction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {}, // visual only
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '${reaction.count}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PLATFORM DOT ──────────────────────────────────────────────

class _PlatformDot extends StatelessWidget {
  final String status;
  const _PlatformDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (status == 'both' || status == 'spotify_only') {
      color = const Color(0xFF1DB954); // Spotify green
    } else if (status == 'youtube_only') {
      color = const Color(0xFFFF0000); // YouTube red
    }

    if (color == null) {
      return Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange);
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MusicNoteIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: cs.onSurface.withOpacity(0.3),
        size: 24,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/search_result_model.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResultModel song;
  final bool isAdding;
  final VoidCallback? onAdd;

  const SearchResultCard({
    super.key,
    required this.song,
    this.isAdding = false,
    this.onAdd,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          // Music note icon
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

          // Info
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
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Album · duration + platform
                Row(
                  children: [
                    if (song.album != null) ...[
                      Flexible(
                        child: Text(
                          song.album!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (song.durationLabel != null &&
                          song.durationLabel!.isNotEmpty)
                        Text(
                          ' · ${song.durationLabel}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                    ] else if (song.durationLabel != null &&
                        song.durationLabel!.isNotEmpty)
                      Text(
                        song.durationLabel!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Platform dots
                _PlatformDots(platform: song.platform),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Add button / Added state
          song.isAdded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Added',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: isAdding ? null : onAdd,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAdding
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.primary,
                    ),
                    child: isAdding
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── PLATFORM DOTS ─────────────────────────────────────────────

class _PlatformDots extends StatelessWidget {
  final SearchPlatform platform;
  const _PlatformDots({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (platform == SearchPlatform.spotify)
          _Dot(color: const Color(0xFF1DB954)),
        if (platform == SearchPlatform.youtube)
          _Dot(color: const Color(0xFFFF0000)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 4),
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

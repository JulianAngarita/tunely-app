import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tunely/features/add_song/models/add_song_result_model.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class MatchSuggestionsSheet extends StatelessWidget {
  final String songTitle;
  final List<MatchSuggestion> suggestions;
  final Future<void> Function(MatchSuggestion) onConfirm;
  final VoidCallback onSkip;

  const MatchSuggestionsSheet({
    super.key,
    required this.songTitle,
    required this.suggestions,
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Agrupar por plataforma
    final spotify = suggestions.where((s) => s.platform == 'spotify').toList();
    final youtube = suggestions.where((s) => s.platform == 'youtube').toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'No confident match found',
            style: tt.titleLarge?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We couldn\'t find a confident match for "$songTitle" on all platforms. Pick the best option or skip.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Spotify suggestions
          if (spotify.isNotEmpty) ...[
            _PlatformHeader(platform: 'spotify'),
            const SizedBox(height: AppSpacing.sm),
            ...spotify.map(
              (s) => _SuggestionCard(suggestion: s, onTap: () => onConfirm(s)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // YouTube suggestions
          if (youtube.isNotEmpty) ...[
            _PlatformHeader(platform: 'youtube'),
            const SizedBox(height: AppSpacing.sm),
            ...youtube.map(
              (s) => _SuggestionCard(suggestion: s, onTap: () => onConfirm(s)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Skip button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip — add without syncing to this platform',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PLATFORM HEADER ───────────────────────────────────────────

class _PlatformHeader extends StatelessWidget {
  final String platform;
  const _PlatformHeader({required this.platform});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSpotify = platform == 'spotify';

    return Row(
      children: [
        Icon(FontAwesomeIcons.spotify),
        const SizedBox(width: AppSpacing.sm),
        Text(
          isSpotify ? 'Spotify' : 'YouTube Music',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── SUGGESTION CARD ───────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final MatchSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: suggestion.coverUrl != null
                  ? Image.network(
                      suggestion.coverUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderCover(),
                    )
                  : _PlaceholderCover(),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    suggestion.artist,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.album != null)
                    Text(
                      suggestion.album!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.35),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Score badge + select icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PLACEHOLDER COVER ─────────────────────────────────────────

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: cs.onSurface.withOpacity(0.3),
        size: 22,
      ),
    );
  }
}

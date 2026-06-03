import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/features/add_song/widgets/match_suggestions_sheet.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'providers/search_provider.dart';
import 'providers/add_song_provider.dart';
import 'models/search_result_model.dart';
import 'widgets/search_result_card.dart';

class AddSongScreen extends ConsumerStatefulWidget {
  /// Si viene desde el detalle de una playlist, se pasa el id y nombre
  final String? playlistId;
  final String? playlistName;

  const AddSongScreen({super.key, this.playlistId, this.playlistName});

  @override
  ConsumerState<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends ConsumerState<AddSongScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Limpiar búsqueda anterior al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).clear();
      ref.read(searchFilterProvider.notifier).state = SearchFilter.all;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addSong(SearchResultModel song) async {
    if (widget.playlistId == null) return;
    try {
      final result = await ref
          .read(addSongProvider(widget.playlistId!).notifier)
          .addSong(song);

      if (!mounted) return;

      // Si hay sugerencias pendientes de confirmación
      if (result.matchStatus == 'pending_confirmation' &&
          result.suggestions.isNotEmpty) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => MatchSuggestionsSheet(
            songTitle: song.title,
            suggestions: result.suggestions,
            onConfirm: (suggestion) async {
              Navigator.pop(context);
              await ref
                  .read(addSongProvider(widget.playlistId!).notifier)
                  .confirmMatch(
                    songId: result.songId,
                    playlistId: widget.playlistId!,
                    match: suggestion,
                  );
            },
            onSkip: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final search = ref.watch(searchProvider);
    final filter = ref.watch(searchFilterProvider);
    final filtered = search.filtered(filter);

    // Track which songs are being added
    final addState = widget.playlistId != null
        ? ref.watch(addSongProvider(widget.playlistId!))
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.onSurface.withOpacity(0.08),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: cs.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Song',
                          style: tt.titleLarge?.copyWith(color: cs.onSurface),
                        ),
                        if (widget.playlistName != null)
                          Text(
                            'to ${widget.playlistName}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Search bar ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: (q) =>
                      ref.read(searchProvider.notifier).onQueryChanged(q),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, or albums...',
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.35),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                    suffixIcon: search.query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(searchProvider.notifier).clear();
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.cardDark
                        : cs.onSurface.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),

              // ── Filter chips ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: SearchFilter.values.map((f) {
                    final isSelected = filter == f;
                    final label = switch (f) {
                      SearchFilter.all => 'All',
                      SearchFilter.spotify => 'Spotify',
                      SearchFilter.youtube => 'YouTube Music',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(searchFilterProvider.notifier).state = f,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : cs.onSurface.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          child: Text(
                            label,
                            style: tt.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : cs.onSurface.withOpacity(0.6),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Results ───────────────────────────────────
              Expanded(
                child: _SearchResults(
                  search: search,
                  filtered: filtered,
                  playlistId: widget.playlistId,
                  onAdd: _addSong,
                  addState: addState,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SEARCH RESULTS ────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final SearchState search;
  final List<SearchResultModel> filtered;
  final String? playlistId;
  final Future<void> Function(SearchResultModel) onAdd;
  final AsyncValue<void>? addState;

  const _SearchResults({
    required this.search,
    required this.filtered,
    required this.playlistId,
    required this.onAdd,
    this.addState,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Empty query
    if (search.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 56,
              color: cs.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Search for a song',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    // Loading
    if (search.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error
    if (search.error != null) {
      return Center(
        child: Text(
          'Search failed — try again',
          style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
        ),
      );
    }

    // No results
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 48,
              color: cs.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No results for "${search.query}"',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final song = filtered[i];
        final isAdding = addState?.isLoading == true;

        return SearchResultCard(
          song: song,
          isAdding: isAdding,
          onAdd: playlistId != null ? () => onAdd(song) : null,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import 'package:tunely/features/home/create_playlist_screen.dart';
import 'package:tunely/features/home/providers/playlists_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';

// ─── PROVIDER ──────────────────────────────────────────────────

final _joinLoadingProvider = StateProvider<bool>((_) => false);
final _joinErrorProvider = StateProvider<String?>((_) => null);

// ─── SCREEN ────────────────────────────────────────────────────

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openCreatePlaylist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, __) => CreatePlaylistScreen(
          onCreated: () {
            Navigator.of(context).pop();
            ref.invalidate(playlistsProvider);
          },
        ),
      ),
    );
  }

  void _openJoinSheet() {
    ref.read(_joinErrorProvider.notifier).state = null;
    ref.read(_joinLoadingProvider.notifier).state = false;
    _codeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _JoinSheet(
          controller: _codeController,
          focusNode: _focusNode,
          onJoin: _joinByCode,
        ),
      ),
    );
  }

  Future<void> _joinByCode(String code) async {
    if (code.trim().isEmpty) return;

    ref.read(_joinLoadingProvider.notifier).state = true;
    ref.read(_joinErrorProvider.notifier).state = null;

    try {
      final router = ref.read(routerProvider);
      final client = ref.read(apiClientProvider(router));

      await client.post(
        '/playlists/join',
        data: {'inviteCode': code.trim().toLowerCase()},
      );

      ref.invalidate(playlistsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You joined the playlist!'),
            backgroundColor: AppColors.synced,
          ),
        );
      }
    } catch (e) {
      ref.read(_joinErrorProvider.notifier).state =
          'Invalid code — check it and try again';
    } finally {
      ref.read(_joinLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── Header ──────────────────────────────────
                Text(
                  'Add',
                  style: tt.displayLarge?.copyWith(
                    color: cs.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create or join a shared playlist',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Action cards ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Create\nPlaylist',
                        description: 'Start a new shared playlist',
                        gradient: AppColors.brandGradient,
                        onTap: _openCreatePlaylist,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.group_add_outlined,
                        title: 'Join a\nPlaylist',
                        description: 'Enter an invite code',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: _openJoinSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── How it works ────────────────────────────
                Text(
                  'How it works',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _HowItWorksItem(
                  step: '1',
                  title: 'Create a playlist',
                  body: 'Give it a name and choose your cover color',
                ),
                _HowItWorksItem(
                  step: '2',
                  title: 'Invite friends',
                  body: 'Share the invite code from the playlist detail',
                ),
                _HowItWorksItem(
                  step: '3',
                  title: 'Add songs together',
                  body:
                      'Tunely syncs everything across Spotify and YouTube Music',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ACTION CARD ───────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: tt.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: tt.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOW IT WORKS ITEM ─────────────────────────────────────────

class _HowItWorksItem extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  final bool isLast;

  const _HowItWorksItem({
    required this.step,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator + line
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
              alignment: Alignment.center,
              child: Text(
                step,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 32,
                color: cs.onSurface.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── JOIN SHEET ────────────────────────────────────────────────

class _JoinSheet extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function(String) onJoin;

  const _JoinSheet({
    required this.controller,
    required this.focusNode,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(_joinLoadingProvider);
    final error = ref.watch(_joinErrorProvider);

    // Autofocus al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Join a Playlist',
            style: tt.titleLarge?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the invite code shared by a friend',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Code input
          TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: tt.displayLarge?.copyWith(
              color: AppColors.primary,
              fontSize: 28,
              letterSpacing: 6,
              fontWeight: FontWeight.w700,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'XXXXXXXX',
              hintStyle: tt.displayLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.15),
                fontSize: 28,
                letterSpacing: 6,
              ),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
            ),
            onSubmitted: (v) => onJoin(v),
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Text(error, style: tt.bodySmall?.copyWith(color: Colors.red)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Join button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : () => onJoin(controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Join Playlist',
                        style: tt.labelLarge?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

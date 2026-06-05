import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/features/home/providers/activity_provider.dart';
import 'package:tunely/features/home/providers/playlists_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ─── Forzar refresh al entrar ──────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama cada vez que la ruta se vuelve activa
    Future.microtask(() {
      if (mounted) {
        ref.invalidate(profileProvider);
        ref.invalidate(connectedAccountsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final accounts = ref.watch(connectedAccountsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: profile.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) =>
                const Center(child: Text('Could not load profile')),
            data: (user) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _ProfileHeader(user: user)),
                SliverToBoxAdapter(child: _StatsRow(user: user)),
                SliverToBoxAdapter(child: _SectionTitle('Connected Accounts')),
                SliverToBoxAdapter(
                  child: accounts.when(
                    loading: () => const SizedBox(height: 120),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (accs) => _ConnectedAccounts(accounts: accs),
                  ),
                ),
                SliverToBoxAdapter(child: _SectionTitle('Appearance')),
                const SliverToBoxAdapter(child: _AppearanceSection()),
                SliverToBoxAdapter(child: _SectionTitle('Playback')),
                SliverToBoxAdapter(
                  child: accounts.when(
                    loading: () => const SizedBox(height: 60),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (accs) => _PlaybackSection(
                      accounts: accs,
                      preferredPlatform: user.preferredPlatform,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SignOutButton(onTap: _confirmSignOut),
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

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.invalidate(profileProvider);
      ref.invalidate(connectedAccountsProvider);
      ref.invalidate(playlistsProvider);
      ref.invalidate(activityProvider);

      await ref.read(authProvider.notifier).logout();

      if (mounted) context.go('/login');
    }
  }
}

// ─── HEADER ────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserProfile user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Profile',
                style: tt.displayLarge?.copyWith(color: cs.onSurface),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onSurface.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: cs.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: user.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.avatarUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarInitial(initial: user.initial),
                    ),
                  )
                : _AvatarInitial(initial: user.initial),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.name,
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Music enthusiast',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;
  const _AvatarInitial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── STATS ROW ─────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserProfile user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.queue_music_rounded,
              value: '${user.playlistCount}',
              label: 'Playlists',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              icon: Icons.music_note_rounded,
              value: '${user.songsAdded}',
              label: 'Songs\nAdded',
              color: const Color(0xFFE91E8C),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              icon: Icons.group_rounded,
              value: '${user.collaborators}',
              label: 'Collaborators',
              color: AppColors.synced,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION TITLE ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(title, style: tt.titleLarge?.copyWith(color: cs.onSurface)),
    );
  }
}

// ─── CONNECTED ACCOUNTS ────────────────────────────────────────

class _ConnectedAccounts extends StatelessWidget {
  final List<ConnectedAccount> accounts;
  const _ConnectedAccounts({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final hasSpotify = accounts.any((a) => a.provider == 'spotify');
    final hasGoogle = accounts.any((a) => a.provider == 'google');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _AccountCard(
            name: 'Spotify',
            bgColor: const Color(0xFF1DB954),
            faIcon: FontAwesomeIcons.spotify,
            isConnected: hasSpotify,
            provider: 'spotify',
          ),
          const SizedBox(height: AppSpacing.sm),
          _AccountCard(
            name: 'YouTube Music',
            bgColor: const Color(0xFFFF0000),
            faIcon: FontAwesomeIcons.youtube,
            isConnected: hasGoogle,
            provider: 'google',
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final String name;
  final Color bgColor;
  final IconData faIcon;
  final bool isConnected;
  final String provider;

  const _AccountCard({
    required this.name,
    required this.bgColor,
    required this.faIcon,
    required this.isConnected,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isConnected ? null : () => _connect(context),
      child: Container(
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
            // Logo de la plataforma
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: FaIcon(faIcon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                name,
                style: tt.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isConnected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.synced,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.synced,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Connect',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final uri = Uri.parse('${AppConfig.backendUrl}/api/auth/$provider');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─── APPEARANCE ────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Icon(
              Icons.dark_mode_rounded,
              color: cs.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Dark Mode',
                style: tt.titleMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (val) => ref
                  .read(themeModeProvider.notifier)
                  .setTheme(val ? ThemeMode.dark : ThemeMode.light),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PLAYBACK ──────────────────────────────────────────────────

class _PlaybackSection extends ConsumerStatefulWidget {
  final List<ConnectedAccount> accounts;
  final String? preferredPlatform;

  const _PlaybackSection({
    required this.accounts,
    required this.preferredPlatform,
  });

  @override
  ConsumerState<_PlaybackSection> createState() => _PlaybackSectionState();
}

class _PlaybackSectionState extends ConsumerState<_PlaybackSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasSpotify = widget.accounts.any((a) => a.provider == 'spotify');
    final hasYoutube = widget.accounts.any((a) => a.provider == 'google');

    if (!hasSpotify && !hasYoutube) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          'Connect a platform to enable playback',
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.4)),
        ),
      );
    }

    final current =
        widget.preferredPlatform ?? (hasSpotify ? 'spotify' : 'youtube');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Play music using',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                // Loader cuando se está guardando
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (hasSpotify)
                  Expanded(
                    child: _PlatformOption(
                      label: 'Spotify',
                      color: const Color(0xFF1DB954),
                      faIcon: FontAwesomeIcons.spotify,
                      isSelected: current == 'spotify',
                      isDisabled: _isLoading || !hasYoutube,
                      onTap: () => _select('spotify'),
                    ),
                  ),
                if (hasSpotify && hasYoutube)
                  const SizedBox(width: AppSpacing.sm),
                if (hasYoutube)
                  Expanded(
                    child: _PlatformOption(
                      label: 'YouTube',
                      color: const Color(0xFFFF0000),
                      faIcon: FontAwesomeIcons.youtube,
                      isSelected: current == 'youtube',
                      isDisabled: _isLoading || !hasSpotify,
                      onTap: () => _select('youtube'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(String platform) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(updatePreferredPlatformProvider(platform).future);
      ref.invalidate(profileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update playback preference')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PlatformOption extends StatelessWidget {
  final String label;
  final Color color;
  final IconData faIcon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PlatformOption({
    required this.label,
    required this.color,
    required this.faIcon,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? Icon(Icons.check_circle_rounded, color: color, size: 18)
                : FaIcon(faIcon, color: color.withOpacity(0.4), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: isSelected ? color : color.withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIGN OUT BUTTON ───────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        0,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sign Out',
                style: tt.titleMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

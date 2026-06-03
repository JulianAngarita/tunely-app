import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/features/home/providers/activity_provider.dart';
import 'package:tunely/features/home/providers/playlists_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            error: (err, _) => Center(child: Text('Could not load profile')),
            data: (user) => CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(child: _ProfileHeader(user: user)),

                // ── Stats ───────────────────────────────────
                SliverToBoxAdapter(child: _StatsRow(user: user)),

                // ── Connected Accounts ───────────────────────
                SliverToBoxAdapter(child: _SectionTitle('Connected Accounts')),
                SliverToBoxAdapter(
                  child: accounts.when(
                    loading: () => const SizedBox(height: 120),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (accs) => _ConnectedAccounts(accounts: accs),
                  ),
                ),

                // ── Appearance ───────────────────────────────
                SliverToBoxAdapter(child: _SectionTitle('Appearance')),
                SliverToBoxAdapter(child: _AppearanceSection()),

                // ── Settings ─────────────────────────────────
                SliverToBoxAdapter(child: _SectionTitle('Settings')),
                SliverToBoxAdapter(child: _SettingsSection()),

                // ── Sign Out ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _SignOutButton(
                    onTap: () => _confirmSignOut(context, ref),
                  ),
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

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false), // ← dialogContext
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true), // ← dialogContext
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ref.invalidate(profileProvider);
      ref.invalidate(connectedAccountsProvider);
      ref.invalidate(playlistsProvider);
      ref.invalidate(activityProvider);

      await ref.read(authProvider.notifier).logout();

      if (context.mounted) context.go('/login');
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
          // Title row
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

          // Avatar
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

          // Name
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

    final spotifyUsername = accounts
        .where((a) => a.provider == 'spotify')
        .map((a) => a.providerUserId)
        .firstOrNull;
    final googleUsername = accounts
        .where((a) => a.provider == 'google')
        .map((a) => a.providerUserId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _AccountCard(
            name: 'Spotify',
            username: hasSpotify
                ? '@${spotifyUsername ?? 'yourspotify'}'
                : 'Connect your account',
            bgColor: const Color(0xFF1DB954),
            icon: Icons.music_note_rounded,
            isConnected: hasSpotify,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AccountCard(
            name: 'YouTube Music',
            username: hasGoogle
                ? '@${googleUsername ?? 'yourytmusic'}'
                : 'Connect your account',
            bgColor: const Color(0xFFFF0000),
            icon: Icons.play_arrow_rounded,
            isConnected: hasGoogle,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final String username;
  final Color bgColor;
  final IconData icon;
  final bool isConnected;

  const _AccountCard({
    required this.name,
    required this.username,
    required this.bgColor,
    required this.icon,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  username,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
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
    );
  }
}

// ─── APPEARANCE ────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
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

// ─── SETTINGS ──────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            _SettingsItem(
              icon: Icons.settings_rounded,
              label: 'Account Settings',
              onTap: () {}, // TODO
            ),
            _Divider(),
            _SettingsItem(
              icon: Icons.security_rounded,
              label: 'Privacy & Security',
              onTap: () {}, // TODO
            ),
            _Divider(),
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {}, // TODO
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurface.withOpacity(0.5), size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: tt.titleMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.md + 20 + AppSpacing.md,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
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

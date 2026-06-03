import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tunely/core/constants/app_config.dart';
import 'package:tunely/core/themes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_spacing.dart';

// ─── SCREEN ────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final void Function(String accessToken, String refreshToken)? onAuthenticated;

  const LoginScreen({super.key, this.onAuthenticated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingSpotify = false;
  bool _loadingGoogle = false;

  Future<void> _loginWith(String provider) async {
    setState(() {
      if (provider == 'spotify') {
        _loadingSpotify = true;
      } else {
        _loadingGoogle = true;
      }
    });

    try {
      final uri = Uri.parse('${AppConfig.backendUrl}/api/auth/$provider');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not connect to $provider'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSpotify = false;
          _loadingGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ──────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Tunely',
                  style: tt.displayLarge?.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Music together',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Buttons ───────────────────────────────────
                Text(
                  'Continue with your music service',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                _OAuthButton(
                  label: 'Continue with Spotify',
                  icon: FontAwesomeIcons.spotify,
                  iconBg: const Color(0xFF1DB954),
                  isLoading: _loadingSpotify,
                  onTap: () => _loginWith('spotify'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _OAuthButton(
                  label: 'Continue with YouTube Music',
                  icon: FontAwesomeIcons.youtube,
                  iconBg: const Color(0xFFFF0000),
                  isLoading: _loadingGoogle,
                  onTap: () => _loginWith('google'),
                ),

                const Spacer(),

                // ── Terms ─────────────────────────────────────
                Text(
                  'By continuing you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.35),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── OAUTH BUTTON ──────────────────────────────────────────────

class _OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBg;
  final bool isLoading;
  final VoidCallback onTap;

  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: cs.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                // Ícono de la plataforma
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: FaIcon(icon, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: tt.titleMedium?.copyWith(color: cs.onSurface),
                  ),
                ),

                // Loading indicator
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

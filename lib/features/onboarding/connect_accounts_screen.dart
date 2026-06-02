import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tunely/core/constants/app_spacing.dart';
import 'package:tunely/core/themes/app_colors.dart';

// ─── MODEL ─────────────────────────────────────────────────────
class _ServiceData {
  final String name;
  final String logoAsset; // e.g. 'assets/icons/spotify.png'
  final Color  logoBg;
  final bool   isConnected;

  const _ServiceData({
    required this.name,
    required this.logoAsset,
    required this.logoBg,
    required this.isConnected,
  });
}

// ─── SCREEN ────────────────────────────────────────────────────
class ConnectAccountsScreen extends StatefulWidget {
  /// Called when the user taps Continue (at least one connected)
  final VoidCallback? onContinue;

  const ConnectAccountsScreen({super.key, this.onContinue});

  @override
  State<ConnectAccountsScreen> createState() => _ConnectAccountsScreenState();
}

class _ConnectAccountsScreenState extends State<ConnectAccountsScreen> {
  // En producción este estado vendrá de tu auth provider/bloc
  final Map<String, bool> _connected = {
    'spotify': false,
    'youtube': false,
  };

  bool get _canContinue => _connected.values.any((v) => v);

  void _toggle(String key) {
    // Aquí dispararás el OAuth real; por ahora toggleamos localmente
    setState(() => _connected[key] = !(_connected[key] ?? false));
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
                const SizedBox(height: AppSpacing.xxl),

                // ── Logo icon ──────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Title ──────────────────────────────────────
                Text(
                  'Connect Your Music',
                  style: tt.displayLarge?.copyWith(color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Subtitle ───────────────────────────────────
                Text(
                  'Link at least one music service to start creating collaborative playlists',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Service cards ──────────────────────────────
                _ServiceCard(
                  name: 'Spotify',
                  subtitle: _connected['spotify']! ? 'Connected' : 'Connect your account',
                  logoAsset: 'assets/icons/spotify.png',
                  logoBg: const Color(0xFF1DB954),
                  isConnected: _connected['spotify']!,
                  onTap: () => _toggle('spotify'),
                ),
                const SizedBox(height: AppSpacing.md),
                _ServiceCard(
                  name: 'YouTube Music',
                  subtitle: _connected['youtube']! ? 'Connected' : 'Connect your account',
                  logoAsset: 'assets/icons/youtube.png',
                  logoBg: const Color(0xFFFF0000),
                  isConnected: _connected['youtube']!,
                  onTap: () => _toggle('youtube'),
                ),

                const Spacer(),

                // ── Continue button ────────────────────────────
                _ContinueButton(
                  enabled: _canContinue,
                  onTap: _canContinue ? widget.onContinue : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Footer hint ────────────────────────────────
                Text(
                  'You can connect additional services later in settings',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
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

// ─── SERVICE CARD ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final String   name;
  final String   subtitle;
  final String   logoAsset;
  final Color    logoBg;
  final bool     isConnected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.subtitle,
    required this.logoAsset,
    required this.logoBg,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fondo del card: tinte primario suave en ambos temas
    final cardBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.07);

    // Borde: más visible cuando está conectado
    final borderColor = isConnected
        ? AppColors.primary.withOpacity(0.7)
        : AppColors.primary.withOpacity(0.25);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Logo
                _ServiceLogo(asset: logoAsset, bg: logoBg),
                const SizedBox(width: AppSpacing.md),

                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Check icon animado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isConnected
                      ? Icon(
                          Icons.check_circle_outline_rounded,
                          key: const ValueKey('connected'),
                          color: AppColors.primary,
                          size: 24,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey('disconnected'),
                          color: cs.onSurface.withOpacity(0.25),
                          size: 24,
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

// ─── SERVICE LOGO ──────────────────────────────────────────────
// Usa Image.asset si tienes los logos; si no, muestra la inicial como fallback
class _ServiceLogo extends StatelessWidget {
  final String asset;
  final Color  bg;
  const _ServiceLogo({required this.asset, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          // Si el asset no existe aún, muestra ícono de placeholder
          errorBuilder: (_, __, ___) => const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ─── CONTINUE BUTTON ───────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  const _ContinueButton({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1.0 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: Text(
              'Continue',
              style: tt.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
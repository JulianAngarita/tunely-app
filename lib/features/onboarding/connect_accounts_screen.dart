import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/themes/app_colors.dart';

class ConnectAccountsScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const ConnectAccountsScreen({super.key, this.onContinue});

  @override
  State<ConnectAccountsScreen> createState() => _ConnectAccountsScreenState();
}

class _ConnectAccountsScreenState extends State<ConnectAccountsScreen>
    with TickerProviderStateMixin {
  final Map<String, bool> _connected = {'spotify': false, 'youtube': false};
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool get _canContinue => _connected.values.any((v) => v);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect(String provider) async {
    final uri = Uri.parse('${AppConfig.backendUrl}/api/auth/$provider');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // El deep link actualizará el estado al volver
    // Por ahora marcamos como conectado visualmente
    setState(() => _connected[provider] = true);
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Illustration ───────────────────────────
                  _Illustration(),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Headline ───────────────────────────────
                  Text(
                    'Connect Your\nMusic',
                    style: tt.displayLarge?.copyWith(
                      color: cs.onSurface,
                      height: 1.1,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Link at least one music service to start\ncreating collaborative playlists',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // ── Platform cards ─────────────────────────
                  _PlatformCard(
                    name: 'Spotify',
                    description: 'Stream and sync your music',
                    faIcon: FontAwesomeIcons.spotify,
                    color: const Color(0xFF1DB954),
                    isConnected: _connected['spotify']!,
                    onTap: () => _connect('spotify'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PlatformCard(
                    name: 'YouTube Music',
                    description: 'Connect your YouTube account',
                    faIcon: FontAwesomeIcons.youtube,
                    color: const Color(0xFFFF0000),
                    isConnected: _connected['youtube']!,
                    onTap: () => _connect('google'),
                  ),

                  const Spacer(flex: 1),

                  // ── Continue ───────────────────────────────
                  _ContinueButton(
                    enabled: _canContinue,
                    onTap: _canContinue ? widget.onContinue : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You can connect more services later in Settings',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.35),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ILLUSTRATION ──────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Main circle
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          // Spotify badge
          Positioned(
            right: 4,
            top: 8,
            child: _PlatformBadge(
              color: const Color(0xFF1DB954),
              icon: FontAwesomeIcons.spotify,
            ),
          ),
          // YouTube badge
          Positioned(
            left: 4,
            bottom: 8,
            child: _PlatformBadge(
              color: const Color(0xFFFF0000),
              icon: FontAwesomeIcons.youtube,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _PlatformBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: FaIcon(icon, color: Colors.white, size: 13)),
    );
  }
}

// ─── PLATFORM CARD ─────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData faIcon;
  final Color color;
  final bool isConnected;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.name,
    required this.description,
    required this.faIcon,
    required this.color,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark
            ? (isConnected ? color.withOpacity(0.12) : AppColors.cardDark)
            : (isConnected ? color.withOpacity(0.06) : AppColors.cardLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isConnected ? color.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
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
                // Platform icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: isConnected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: FaIcon(faIcon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + description
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
                      const SizedBox(height: 2),
                      Text(
                        isConnected ? 'Connected ✓' : description,
                        style: tt.bodySmall?.copyWith(
                          color: isConnected
                              ? color
                              : cs.onSurface.withOpacity(0.4),
                          fontWeight: isConnected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: isConnected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('on'),
                          color: color,
                          size: 24,
                        )
                      : Icon(
                          Icons.add_circle_outline_rounded,
                          key: const ValueKey('off'),
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
        duration: const Duration(milliseconds: 300),
        opacity: enabled ? 1.0 : 0.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.brandGradient
                : const LinearGradient(colors: [Colors.grey, Colors.grey]),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
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
              style: tt.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

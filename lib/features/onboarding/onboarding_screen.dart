import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/core/constants/app_spacing.dart';
import 'package:tunely/core/themes/app_colors.dart';


// ─── DATA MODEL ────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final String title;
  final String subtitle;
  final String buttonLabel;

  const _SlideData({
    required this.icon,
    this.solidColor,
    this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });
}

const _slides = [
  _SlideData(
    icon:        Icons.music_note_rounded,
    solidColor:   AppColors.primary,
    title:       'Your Music, Together',
    subtitle:    'Create shared playlists that sync between\nSpotify and YouTube Music',
    buttonLabel: 'Continue',
  ),
  _SlideData(
    icon:        Icons.group_rounded,
    solidColor:  Color(0xFFF48FB1), // pink — solo para onboarding
    title:       'Connect Through Sound',
    subtitle:    'Invite friends, partners, and loved ones to\ncollaborate on the perfect soundtrack',
    buttonLabel: 'Continue',
  ),
  _SlideData(
    icon:        Icons.favorite_border_rounded,
    solidColor:  AppColors.synced, // cyan ya está en AppColors
    title:       'Build Memories',
    subtitle:    'Every song tells a story. See who added\nwhat and relive those moments',
    buttonLabel: 'Continue',
  ),
  _SlideData(
    icon:        Icons.auto_awesome_rounded,
    gradientColors: [AppColors.gradientStart, AppColors.gradientEnd],
    title:       'Discover Together',
    subtitle:    'Share musical discoveries and explore new\nsounds with the people you care about',
    buttonLabel: 'Get Started',
  ),
];

// ─── SCREEN ────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;
  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onFinished?.call();
  } 

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _PageIndicator(
                          count: _slides.length,
                          current: _currentPage,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PrimaryButton(
                          label: _slides[_currentPage].buttonLabel,
                          onTap: _next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AnimatedOpacity(
                          opacity: _currentPage < _slides.length - 1 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: _currentPage < _slides.length - 1
                                ? _finish
                                : null,
                            child: Text(
                              'Skip',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
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

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SlideIcon(slide: slide),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            // displayLarge definido en AppTypography
            style: tt.displayLarge?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            // bodyMedium del tema, con opacidad reducida como en el diseño
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideIcon extends StatelessWidget {
  final _SlideData slide;
  const _SlideIcon({required this.slide});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey(slide.title),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: slide.solidColor,
          gradient: slide.gradientColors != null
              ? LinearGradient(
                  colors: slide.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Icon(Icons.music_note, color: Colors.white, size: 52),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width:  isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              // Activo: color primary del tema. Inactivo: surface del tema
              color: isActive
                  ? primary
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: tt.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
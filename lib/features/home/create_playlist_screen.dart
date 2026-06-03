import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/features/home/providers/create_playlist_provider.dart';
import 'package:tunely/features/home/providers/playlists_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

// ─── SCREEN ────────────────────────────────────────────────────

class CreatePlaylistScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  const CreatePlaylistScreen({super.key, this.onCreated});

  @override
  ConsumerState<CreatePlaylistScreen> createState() =>
      _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends ConsumerState<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;

  // Gradientes disponibles para el cover
  static const _gradients = [
    [Color(0xFFFF6B9D), Color(0xFFFF8E6E)],
    [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
    [Color(0xFF7C4DFF), Color(0xFF9C6FFF)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFF4481EB), Color(0xFF04BEFE)],
  ];
  int _selectedGradient = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(createPlaylistProvider.notifier)
          .create(
            name: _nameController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            isPublic: _isPublic,
            gradientIndex: _selectedGradient,
          );

      if (mounted) {
        // Invalidar para refrescar el home
        ref.invalidate(playlistsProvider);
        widget.onCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
              _Header(onClose: () => Navigator.of(context).pop()),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        // ── Cover preview ──────────────────────
                        Center(
                          child: _CoverPreview(
                            gradient: _gradients[_selectedGradient],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ── Gradient picker ────────────────────
                        Center(
                          child: _GradientPicker(
                            gradients: _gradients,
                            selectedIndex: _selectedGradient,
                            onSelect: (i) =>
                                setState(() => _selectedGradient = i),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Name field ─────────────────────────
                        Text(
                          'Playlist name',
                          style: tt.titleMedium?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _TunelyTextField(
                          controller: _nameController,
                          hint: 'e.g. Our Summer Vibes',
                          maxLength: 50,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Description field ──────────────────
                        Text(
                          'Description',
                          style: tt.titleMedium?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _TunelyTextField(
                          controller: _descController,
                          hint: 'What\'s this playlist about? (optional)',
                          maxLength: 200,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Public toggle ──────────────────────
                        _PublicToggle(
                          value: _isPublic,
                          onChange: (v) => setState(() => _isPublic = v),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // ── Create button ──────────────────────
                        _CreateButton(isLoading: _isLoading, onTap: _submit),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HEADER ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onSurface.withOpacity(0.08),
              ),
              child: Icon(Icons.close_rounded, color: cs.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'New Playlist',
            style: tt.titleLarge?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

// ─── COVER PREVIEW ─────────────────────────────────────────────

class _CoverPreview extends StatelessWidget {
  final List<Color> gradient;
  const _CoverPreview({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 52,
      ),
    );
  }
}

// ─── GRADIENT PICKER ───────────────────────────────────────────

class _GradientPicker extends StatelessWidget {
  final List<List<Color>> gradients;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _GradientPicker({
    required this.gradients,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(gradients.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isSelected ? 28 : 22,
            height: isSelected ? 28 : 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradients[i],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradients[i][0].withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ─── TEXT FIELD ────────────────────────────────────────────────

class _TunelyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TunelyTextField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(
          color: cs.onSurface.withOpacity(0.35),
        ),
        counterStyle: tt.bodySmall?.copyWith(
          color: cs.onSurface.withOpacity(0.3),
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.cardDark
            : AppColors.primary.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

// ─── PUBLIC TOGGLE ─────────────────────────────────────────────

class _PublicToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChange;

  const _PublicToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.public_rounded : Icons.lock_outline_rounded,
            color: value ? AppColors.primary : cs.onSurface.withOpacity(0.4),
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ? 'Public playlist' : 'Private playlist',
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                ),
                Text(
                  value
                      ? 'Anyone can find and join this playlist'
                      : 'Only people you invite can join',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeColor: AppColors.primary,
            inactiveThumbColor: cs.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ─── CREATE BUTTON ─────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CreateButton({required this.isLoading, required this.onTap});

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
          onPressed: isLoading ? null : onTap,
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Create Playlist',
                  style: tt.labelLarge?.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

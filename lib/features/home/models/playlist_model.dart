import 'package:flutter/material.dart';

enum SyncStatus { synced, syncing, error }

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final int trackCount;
  final List<Color> coverGradient;
  final List<String> memberInitials;
  final List<Color> memberColors;
  final SyncStatus syncStatus;
  final String syncLabel;
  final bool isPublic;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.trackCount,
    required this.coverGradient,
    required this.memberInitials,
    required this.memberColors,
    required this.syncStatus,
    required this.syncLabel,
    this.isPublic = false,
  });

  /// Convierte la respuesta del backend en un PlaylistModel
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final members = (json['playlist_members'] as List<dynamic>?) ?? [];
    final memberInitials = members.map((m) {
      final name = (m['users']?['name'] as String?) ?? '?';
      return name.isNotEmpty ? name[0].toUpperCase() : '?';
    }).toList();

    final avatarColors = [
      const Color(0xFFE91E8C),
      const Color(0xFF7C4DFF),
      const Color(0xFF4CAF50),
      const Color(0xFF4DD0E1),
      const Color(0xFFFF9800),
    ];
    final memberColors = List.generate(
      memberInitials.length,
      (i) => avatarColors[i % avatarColors.length],
    );

    final gradients = [
      // Rosa → Naranja
      [const Color(0xFFFF2D6B), const Color(0xFFFF8C00)],
      // Cyan → Azul eléctrico
      [const Color(0xFF00E5FF), const Color(0xFF2979FF)],
      // Púrpura → Rosa fuerte
      [const Color(0xFF7C4DFF), const Color(0xFFFF2D96)],
      // Verde lima → Turquesa
      [const Color(0xFF76FF03), const Color(0xFF00BCD4)],
      // Amarillo → Rojo
      [const Color(0xFFFFD600), const Color(0xFFFF1744)],
    ];

    final id = (json['id'] as String?) ?? '';
    final gradientIndex =
        ((json['cover_gradient_index'] as int?) ??
            (id.isNotEmpty ? id.codeUnitAt(0) % gradients.length : 0)) %
        gradients.length;

    final updatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null;

    final songs = (json['playlist_songs'] as List<dynamic>?) ?? [];

    return PlaylistModel(
      id: id,
      name: (json['name'] as String?) ?? 'Untitled',

      description: (json['description'] as String?),
      trackCount: songs.length,
      coverGradient: gradients[gradientIndex],
      memberInitials: memberInitials,
      memberColors: memberColors,
      syncStatus: SyncStatus.synced,
      syncLabel: _formatTimeAgo(updatedAt),
      isPublic: (json['is_public'] as bool?) ?? false,
    );
  }

  static String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }
}

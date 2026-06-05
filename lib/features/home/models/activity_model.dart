import 'package:flutter/material.dart';

class ActivityModel {
  final String id;
  final String initial;
  final Color avatarColor;
  final String richText;
  final String boldName;
  final String subtitle;
  final String? emoji;
  final String? playlistId; // ← nuevo

  const ActivityModel({
    required this.id,
    required this.initial,
    required this.avatarColor,
    required this.richText,
    required this.boldName,
    required this.subtitle,
    this.emoji,
    this.playlistId, // ← nuevo,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final name = (user?['name'] as String?) ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final action = json['action'] as String? ?? '';
    final details = json['details'] as Map<String, dynamic>?;

    // Construir richText según el tipo de acción
    String richText;
    String? emoji;

    switch (action) {
      case 'song_added':
        richText = 'added ${details?['title'] ?? 'a song'}';
      case 'song_removed':
        richText = 'removed ${details?['title'] ?? 'a song'}';
      case 'member_joined':
        richText = 'joined the playlist';
      case 'playlist_edited':
        richText = 'edited the playlist';
      case 'sync_completed':
        richText = 'playlist synced';
        emoji = '✓';
      default:
        richText = action.replaceAll('_', ' ');
    }

    // Timestamp
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null;
    final timeAgo = _formatTimeAgo(createdAt);

    // Subtítulo
    final playlistName = (json['playlists']?['name'] as String?) ?? '';
    final subtitle = playlistName.isNotEmpty
        ? '$playlistName · $timeAgo'
        : timeAgo;

    // Colores de avatar
    final colors = [
      const Color(0xFFFFB3C6),
      const Color(0xFF80DEEA),
      const Color(0xFFA5D6A7),
      const Color(0xFFCE93D8),
      const Color(0xFFFFCC80),
    ];
    final colorIndex = name.codeUnitAt(0) % colors.length;

    return ActivityModel(
      id: json['id'] as String,
      initial: initial,
      avatarColor: colors[colorIndex],
      richText: richText,
      boldName: name,
      subtitle: subtitle,
      emoji: emoji,
      playlistId: json['playlist_id'] as String?,
    );
  }

  static String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

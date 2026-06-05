import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class PlaylistActivityModel {
  final String   id;
  final String   action;
  final String   userName;
  final String   userInitial;
  final Color    userColor;
  final String   timeAgo;
  final String   description;

  const PlaylistActivityModel({
    required this.id,
    required this.action,
    required this.userName,
    required this.userInitial,
    required this.userColor,
    required this.timeAgo,
    required this.description,
  });

  // ─── HELPERS ─────────────────────────────────────────────────

  static final _colors = [
    const Color(0xFFE91E8C),
    const Color(0xFF7C4DFF),
    const Color(0xFF4CAF50),
    const Color(0xFF4DD0E1),
    const Color(0xFFFF9800),
  ];

  static String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static String _buildDescription(
    String action,
    Map<String, dynamic>? details,
    String userName,
  ) {
    switch (action) {
      case 'song_added':
        return '$userName added "${details?['title'] ?? 'a song'}"';
      case 'song_removed':
        return '$userName removed "${details?['title'] ?? 'a song'}"';
      case 'member_joined':
        return '$userName joined the playlist';
      case 'member_removed':
        return '$userName was removed';
      case 'playlist_edited':
        return '$userName edited the playlist';
      case 'sync_completed':
        return 'Playlist synced successfully';
      case 'sync_failed':
        return 'Sync failed — check your connections';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  // ─── COMPUTED ────────────────────────────────────────────────

  IconData get icon {
    switch (action) {
      case 'song_added':      return Icons.add_circle_outline_rounded;
      case 'song_removed':    return Icons.remove_circle_outline_rounded;
      case 'member_joined':   return Icons.person_add_outlined;
      case 'member_removed':  return Icons.person_remove_outlined;
      case 'playlist_edited': return Icons.edit_outlined;
      case 'sync_completed':  return Icons.sync_rounded;
      case 'sync_failed':     return Icons.sync_problem_rounded;
      default:                return Icons.info_outline_rounded;
    }
  }

  Color iconColor(BuildContext context) {
    switch (action) {
      case 'song_added':
      case 'member_joined':
      case 'sync_completed':
        return AppColors.synced;
      case 'song_removed':
      case 'member_removed':
      case 'sync_failed':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    }
  }

  // ─── FACTORY ─────────────────────────────────────────────────

  factory PlaylistActivityModel.fromJson(Map<String, dynamic> json) {
    final user     = json['users']   as Map<String, dynamic>?;
    final name     = (user?['name'] as String?) ?? 'Unknown';
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colorIdx = name.codeUnitAt(0) % _colors.length;
    final action   = (json['action'] as String?) ?? '';
    final details  = json['details'] as Map<String, dynamic>?;
    final timeAgo  = _formatTimeAgo(
      json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );

    return PlaylistActivityModel(
      id:          (json['id'] as String?) ?? '',
      action:      action,
      userName:    name,
      userInitial: initial,
      userColor:   _colors[colorIdx],
      timeAgo:     timeAgo,
      description: _buildDescription(action, details, name),
    );
  }
}

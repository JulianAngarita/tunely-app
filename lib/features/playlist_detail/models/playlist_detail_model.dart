import 'package:flutter/material.dart';

// ─── SONG ──────────────────────────────────────────────────────

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? durationMs;
  final String? spotifyTrackId;
  final String? youtubeVideoId;
  final String availabilityStatus;
  final String? addedByName;
  final String? addedByInitial;
  final Color addedByColor;
  final String addedAt;
  final int position;
  final String? coverUrl;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.spotifyTrackId,
    this.youtubeVideoId,
    required this.availabilityStatus,
    this.addedByName,
    this.addedByInitial,
    required this.addedByColor,
    required this.addedAt,
    required this.position,
    required this.coverUrl,
  });

  String get durationLabel {
    if (durationMs == null) return '';
    final total = durationMs! ~/ 1000;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final song = json['songs'] as Map<String, dynamic>?;
    final addedBy = json['users'] as Map<String, dynamic>?;
    final name = (addedBy?['name'] as String?) ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final avatarColors = [
      const Color(0xFFE91E8C),
      const Color(0xFF7C4DFF),
      const Color(0xFF4CAF50),
      const Color(0xFF4DD0E1),
      const Color(0xFFFF9800),
    ];
    final colorIndex = name.codeUnitAt(0) % avatarColors.length;
    final addedAt = (json['added_at'] as String?) ?? '';
    final timeLabel = _formatTimeAgo(
      addedAt.isNotEmpty ? DateTime.tryParse(addedAt) : null,
    );

    return SongModel(
      id: (song?['id'] as String?) ?? '',
      title: (song?['title'] as String?) ?? 'Unknown',
      artist: (song?['artist'] as String?) ?? '',
      album: song?['album'] as String?,
      durationMs: song?['duration_ms'] as int?,
      spotifyTrackId: song?['spotify_track_id'] as String?,
      youtubeVideoId: song?['youtube_video_id'] as String?,
      availabilityStatus: (song?['availability_status'] as String?) ?? 'both',
      addedByName: name,
      addedByInitial: initial,
      addedByColor: avatarColors[colorIndex],
      addedAt: timeLabel,
      position: (json['position'] as int?) ?? 0,
      coverUrl: (song?['cover_url'] as String?) ?? '',
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

// ─── MEMBER ────────────────────────────────────────────────────

class MemberModel {
  final String userId;
  final String name;
  final String initial;
  final Color color;
  final String role;

  const MemberModel({
    required this.userId,
    required this.name,
    required this.initial,
    required this.color,
    required this.role,
  });

  static final _colors = [
    const Color(0xFFE91E8C),
    const Color(0xFF7C4DFF),
    const Color(0xFF4CAF50),
    const Color(0xFF4DD0E1),
    const Color(0xFFFF9800),
  ];

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final name = (user?['name'] as String?) ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colorIndex = name.codeUnitAt(0) % _colors.length;

    return MemberModel(
      userId: (json['user_id'] as String?) ?? '',
      name: name,
      initial: initial,
      color: _colors[colorIndex],
      role: (json['role'] as String?) ?? 'member',
    );
  }
}

// ─── PLAYLIST DETAIL ───────────────────────────────────────────

class PlaylistDetailModel {
  final String id;
  final String name;
  final String? description;
  final bool isPublic;
  final String inviteCode;
  final String ownerId;
  final List<Color> coverGradient;
  final List<SongModel> songs;
  final List<MemberModel> members;
  final String userRole;

  const PlaylistDetailModel({
    required this.id,
    required this.name,
    this.description,
    required this.isPublic,
    required this.inviteCode,
    required this.ownerId,
    required this.coverGradient,
    required this.songs,
    required this.members,
    required this.userRole,
  });

  String get totalDurationLabel {
    final totalMs = songs.fold<int>(0, (s, song) => s + (song.durationMs ?? 0));
    final minutes = totalMs ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '${minutes}m ${seconds}s';
  }

  static final _gradients = [
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

  factory PlaylistDetailModel.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final id = (json['id'] as String?) ?? '';
    final gradientIndex =
        ((json['cover_gradient_index'] as int?) ??
            (id.isNotEmpty ? id.codeUnitAt(0) % _gradients.length : 0)) %
        _gradients.length;

    final rawSongs = (json['playlist_songs'] as List<dynamic>?) ?? [];
    final rawMembers = (json['playlist_members'] as List<dynamic>?) ?? [];

    final songs = rawSongs
        .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final members = rawMembers
        .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final currentMember = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final userRole = currentMember?.role ?? 'member';

    return PlaylistDetailModel(
      id: id,
      name: (json['name'] as String?) ?? 'Untitled',
      description: json['description'] as String?,
      isPublic: (json['is_public'] as bool?) ?? false,
      inviteCode: (json['invite_code'] as String?) ?? '',
      ownerId: (json['owner_id'] as String?) ?? '',
      coverGradient: _gradients[gradientIndex],
      songs: songs,
      members: members,
      userRole: userRole,
    );
  }
}

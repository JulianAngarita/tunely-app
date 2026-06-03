class AddSongResult {
  final String songId;
  final String matchStatus;
  final List<MatchSuggestion> suggestions;

  const AddSongResult({
    required this.songId,
    required this.matchStatus,
    this.suggestions = const [],
  });

  factory AddSongResult.fromJson(Map<String, dynamic> json) {
    final song = json['song'] as Map<String, dynamic>?;
    final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];

    final suggestions = <MatchSuggestion>[];
    for (final group in rawSuggestions) {
      final g = group as Map<String, dynamic>;
      final platform = g['platform'] as String? ?? '';
      final results = g['results'] as List<dynamic>? ?? [];

      for (final r in results) {
        final item = r as Map<String, dynamic>;
        suggestions.add(
          MatchSuggestion.fromJson({
            ...item,
            'platform': platform, // inyectar el platform del grupo,
          }),
        );
      }
    }

    return AddSongResult(
      songId: (song?['id'] as String?) ?? '',
      matchStatus: (json['matchStatus'] as String?) ?? 'auto',
      suggestions: suggestions,
    );
  }
}

class MatchSuggestion {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final String platform;
  final int score;

  const MatchSuggestion({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    required this.platform,
    required this.score,
  });

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) {
    return MatchSuggestion(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      artist: (json['artist'] as String?) ?? '',
      album: json['album'] as String?,
      coverUrl: json['cover_url'] as String?,
      platform: (json['platform'] as String?) ?? '',
      score: (json['score'] as int?) ?? 0,
    );
  }
}

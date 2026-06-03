enum SearchPlatform { spotify, youtube }

class SearchResultModel {
  final String         id;
  final String         title;
  final String         artist;
  final String?        album;
  final String?        durationLabel;
  final int?           durationMs;
  final SearchPlatform platform;
  final String?        spotifyTrackId;
  final String?        youtubeVideoId;
  final String?        coverUrl;
  bool                 isAdded;

  SearchResultModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationLabel,
    this.durationMs,
    required this.platform,
    this.spotifyTrackId,
    this.youtubeVideoId,
    this.coverUrl,
    this.isAdded = false,
  });

  static String _msToLabel(int? ms) {
    if (ms == null) return '';
    final total   = ms ~/ 1000;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory SearchResultModel.fromSpotify(Map<String, dynamic> json) {
    return SearchResultModel(
      id:             (json['id']     as String?) ?? '',
      title:          (json['title']  as String?) ?? 'Unknown',
      artist:         (json['artist'] as String?) ?? '',
      album:          json['album']   as String?,
      durationMs:     json['duration_ms'] as int?,
      durationLabel:  _msToLabel(json['duration_ms'] as int?),
      platform:       SearchPlatform.spotify,
      spotifyTrackId: json['id']      as String?,
      coverUrl:       json['cover_url'] as String?,
    );
  }

  factory SearchResultModel.fromYoutube(Map<String, dynamic> json) {
    return SearchResultModel(
      id:             (json['id']     as String?) ?? '',
      title:          (json['title']  as String?) ?? 'Unknown',
      artist:         (json['artist'] as String?) ?? '',
      platform:       SearchPlatform.youtube,
      youtubeVideoId: json['id']      as String?,
      coverUrl:       json['cover_url'] as String?,
    );
  }
}

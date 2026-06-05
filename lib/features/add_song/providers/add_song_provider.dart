import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import 'package:tunely/features/add_song/models/add_song_result_model.dart';
import 'package:tunely/features/playlist_detail/providers/playlist_detail_provider.dart';
import '../../../core/network/api_client.dart';
import '../models/search_result_model.dart';
import 'search_provider.dart';

class AddSongNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final String _playlistId;

  AddSongNotifier(this._ref, this._playlistId)
    : super(const AsyncValue.data(null));

  Future<AddSongResult> addSong(SearchResultModel song) async {
    state = const AsyncValue.loading();
    try {
      final router = _ref.read(routerProvider);
      final client = _ref.read(apiClientProvider(router));

      final response = await client.post(
        '/playlists/$_playlistId/songs/add',
        data: {
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'duration_ms': song.durationMs,
          'cover_url': song.coverUrl,
          if (song.spotifyTrackId != null)
            'spotify_track_id': song.spotifyTrackId,
          if (song.youtubeVideoId != null)
            'youtube_video_id': song.youtubeVideoId,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final result = AddSongResult.fromJson(data);

      _ref.read(searchProvider.notifier).markAsAdded(song.id);
      _ref.invalidate(playlistDetailProvider(_playlistId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> confirmMatch({
    required String songId,
    required String playlistId,
    required MatchSuggestion match,
  }) async {
    try {
      final router = _ref.read(routerProvider);
      final client = _ref.read(apiClientProvider(router));

      await client.post(
        '/playlists/$playlistId/songs/confirm',
        data: {
          'song': {'id': songId},
          'match': {
            'id': match.id,
            'title': match.title,
            'artist': match.artist,
            'platform': match.platform,
            'score': match.score,
          },
        },
      );
      _ref.invalidate(playlistDetailProvider(_playlistId));
    } catch (e) {
      rethrow;
    }
  }
}

final addSongProvider =
    StateNotifierProvider.family<AddSongNotifier, AsyncValue<void>, String>((
      ref,
      playlistId,
    ) {
      return AddSongNotifier(ref, playlistId);
    });

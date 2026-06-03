import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/playlist_detail_model.dart';

// Provider con family para recibir el playlistId
final playlistDetailProvider =
    FutureProvider.family<PlaylistDetailModel, String>((ref, playlistId) async {
      final router = ref.watch(routerProvider);
      final client = ref.watch(apiClientProvider(router));
      final currentUserId = ref.watch(authProvider).userId ?? '';

      final response = await client.get('/playlists/$playlistId');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final playlist = data['playlist'] as Map<String, dynamic>;

      return PlaylistDetailModel.fromJson(playlist, currentUserId);
    });

// Provider para eliminar playlist
final deletePlaylistProvider = FutureProvider.family<void, String>((
  ref,
  playlistId,
) async {
  final router = ref.watch(routerProvider);
  final client = ref.watch(apiClientProvider(router));
  await client.delete('/playlists/$playlistId');
});

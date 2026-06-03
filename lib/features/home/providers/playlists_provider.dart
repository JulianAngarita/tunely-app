import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';
import '../models/playlist_model.dart';

/// Obtiene las playlists del usuario autenticado
/// GET /api/playlists
final playlistsProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  try {
    final router = ref.watch(routerProvider);
    final client = ref.watch(apiClientProvider(router));

    final response = await client.get('/playlists');

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final list = data['playlists'] as List<dynamic>;

    return list.map((e) {
      final item = e as Map<String, dynamic>;
      final playlistData = item['playlists'] as Map<String, dynamic>;
      return PlaylistModel.fromJson(playlistData);
    }).toList();
  } catch (e, stack) {
    rethrow;
  }
});

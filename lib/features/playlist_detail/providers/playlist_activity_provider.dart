import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import 'package:tunely/features/playlist_detail/models/playlist_activity_model.dart';
import '../../../core/network/api_client.dart';

final playlistActivityProvider =
    FutureProvider.family<List<PlaylistActivityModel>, String>((
      ref,
      playlistId,
    ) async {
      final router = ref.watch(routerProvider);
      final client = ref.watch(apiClientProvider(router));

      final response = await client.get('/playlists/$playlistId/activity');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final list = data['activity'] as List<dynamic>? ?? [];

      return list
          .map((e) => PlaylistActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';
import '../models/activity_model.dart';

/// Obtiene la actividad reciente del usuario
/// GET /api/users/me/activity
final activityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final router = ref.watch(routerProvider);
  final client = ref.watch(apiClientProvider(router));

  final response = await client.get<Map<String, dynamic>>('/users/me/activity');
  final data = response.data?['data'] as Map<String, dynamic>?;
  final list = data?['activity'] as List<dynamic>? ?? [];

  return list
      .take(5)
      .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

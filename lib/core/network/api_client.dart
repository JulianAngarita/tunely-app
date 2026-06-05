import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../constants/app_config.dart';

final apiClientProvider = Provider.family<ApiClient, GoRouter>((ref, router) {
  final token = ref.watch(authProvider).accessToken;
  return ApiClient(token: token, ref: ref, router: router);
});

class ApiClient {
  late final Dio _dio;

  ApiClient({String? token, Ref? ref, GoRouter? router}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.backendUrl}/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     LogInterceptor(requestBody: true, responseBody: true),
    //   );
    // }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              ref != null &&
              router != null) {
            await ref.read(authProvider.notifier).logout();
            router.go('/login');
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete(path);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: params);
  }
}

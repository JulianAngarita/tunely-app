import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/core/constants/app_config.dart';

// ─── STATE ─────────────────────────────────────────────────────

class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? userId;
  final String? userName; // ← nuevo

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.userId,
    this.userName,
  });

  bool get isLoggedIn => accessToken != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? userId,
    String? userName,
  }) => AuthState(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    isLoading: isLoading ?? this.isLoading,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
  );
}

// ─── NOTIFIER ──────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access_token');
    final refresh = prefs.getString('refresh_token');
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name'); // ← nuevo

    if (access != null) {
      state = state.copyWith(
        accessToken: access,
        refreshToken: refresh,
        userId: userId,
        userName: userName, // ← nuevo
      );
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    String? userId;
    String? userName;
    try {
      final parts = accessToken.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      userId = data['id'] as String?;
      userName = data['name'] as String?;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    if (userId != null) await prefs.setString('user_id', userId);
    if (userName != null) await prefs.setString('user_name', userName);

    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userName: userName, // ← nuevo
    );
  }

  Future<void> logout({bool deleteAccount = false}) async {
    try {
      if (deleteAccount) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          await Dio().delete(
            '${AppConfig.backendUrl}/api/users/me',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
      }
    } catch (_) {
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      state = const AuthState();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── STATE ─────────────────────────────────────────────────────

class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? userId;

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.userId,
  });

  bool get isLoggedIn => accessToken != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? userId,
  }) => AuthState(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    isLoading: isLoading ?? this.isLoading,
    userId: userId ?? this.userId,
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

    if (access != null) {
      state = state.copyWith(
        accessToken: access,
        refreshToken: refresh,
        userId: userId,
      );
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    String? userId;
    try {
      final parts = accessToken.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      userId = data['id'] as String?;
      debugPrint('JWT decoded userId: $userId'); // ← agregar
      debugPrint('JWT payload: $data'); // ← agregar
    } catch (e) {
      debugPrint('JWT decode error: $e'); // ← agregar
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    if (userId != null) await prefs.setString('user_id', userId);

    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

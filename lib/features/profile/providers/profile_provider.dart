import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';

// ─── MODELS ────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int playlistCount;
  final int songsAdded;
  final int collaborators;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.playlistCount = 0,
    this.songsAdded = 0,
    this.collaborators = 0,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'You',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ConnectedAccount {
  final String provider;
  final String providerUserId;
  final String expiresAt;

  const ConnectedAccount({
    required this.provider,
    required this.providerUserId,
    required this.expiresAt,
  });

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) {
    return ConnectedAccount(
      provider: (json['provider'] as String?) ?? '',
      providerUserId: (json['provider_user_id'] as String?) ?? '',
      expiresAt: (json['expires_at'] as String?) ?? '',
    );
  }
}

// ─── PROVIDERS ─────────────────────────────────────────────────

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final router = ref.watch(routerProvider);
  final client = ref.watch(apiClientProvider(router));

  final response = await client.get('/users/me');
  final body = response.data as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>;

  return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
});

final connectedAccountsProvider = FutureProvider<List<ConnectedAccount>>((
  ref,
) async {
  final router = ref.watch(routerProvider);
  final client = ref.watch(apiClientProvider(router));

  final response = await client.get('/users/me/accounts');
  final body = response.data as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>;
  final list = data['accounts'] as List<dynamic>? ?? [];

  return list
      .map((e) => ConnectedAccount.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── THEME MODE PROVIDER ───────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'light') state = ThemeMode.light;
    if (saved == 'system') state = ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

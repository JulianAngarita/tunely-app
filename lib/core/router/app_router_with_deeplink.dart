import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/features/auth/login_screen.dart';
import 'package:tunely/features/home/home_screen.dart';
import 'package:tunely/features/home/widgets/main_shell.dart';
import 'package:tunely/features/onboarding/onboarding_screen.dart';

// ─── AUTH STATE (simple, sin provider por ahora) ───────────────

class AuthState {
  static String? _accessToken;
  static String? _refreshToken;

  static Future<void> save(String access, String refresh) async {
    _accessToken  = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> clear() async {
    _accessToken  = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static bool get isLoggedIn => _accessToken != null;
  static String? get accessToken => _accessToken;
}


class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  /// Llama esto en main() antes de runApp
  static Future<void> init(GoRouter router) async {
    // Deep link que abrió la app en frío
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri, router);
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, router);
    });
  }

  static void _handleUri(Uri uri, GoRouter router) {
    // tunely://auth/callback?accessToken=xxx&refreshToken=xxx&provider=spotify
    if (uri.scheme == 'tunely' && uri.host == 'auth' && uri.path == '/callback') {
      final accessToken  = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        AuthState.save(accessToken, refreshToken).then((_) {
          router.go('/home');
        });
      }
    }
  }

  static void dispose() => _sub?.cancel();
}

// ─── ROUTER ────────────────────────────────────────────────────

GoRouter buildRouter(SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: _resolveInitialRoute(prefs),
    redirect: (context, state) {
      final isLoggedIn       = AuthState.isLoggedIn;
      final isAuthRoute      = state.matchedLocation == '/login' ||
                               state.matchedLocation == '/onboarding';

      // Si está logueado y va a auth, mandarlo al home
      if (isLoggedIn && isAuthRoute) return '/home';

      // Si no está logueado y va a una ruta protegida, mandarlo al login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      return null;
    },
    routes: [
      // ── Onboarding (solo primera vez) ──────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onFinished: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_done', true);
            if (context.mounted) context.go('/login');
          },
        ),
      ),

      // ── Login ───────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── App principal con bottom nav ────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/add',      builder: (_, __) => const Placeholder()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (_, __) => const Placeholder()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile',  builder: (_, __) => const Placeholder()),
          ]),
        ],
      ),
    ],
  );

  return router;
}

String _resolveInitialRoute(SharedPreferences prefs) {
  final hasSeenOnboarding = prefs.getBool('onboarding_done') ?? false;
  if (!hasSeenOnboarding) return '/onboarding';
  if (AuthState.isLoggedIn)  return '/home';
  return '/login';
}

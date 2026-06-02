
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/features/home/home_screen.dart';
import 'package:tunely/features/home/widgets/main_shell.dart';
import 'package:tunely/features/onboarding/connect_accounts_screen.dart';
import 'package:tunely/features/onboarding/onboarding_screen.dart';

GoRouter appRouter(SharedPreferences prefs) =>  GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        onFinished: () => context.go('/connect-accounts'),
      ),
    ),
    GoRoute(
      path: '/connect-accounts',
      builder: (context, state) => ConnectAccountsScreen(
        onContinue: () => context.go('/home'),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        // StatefulShellBranch(routes: [
        //   GoRoute(path: '/add', builder: (_, __) => const AddScreen()),
        // ]),
        // StatefulShellBranch(routes: [
        //   GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
        // ]),
        // StatefulShellBranch(routes: [
        //   GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        // ]), 
      ]
    )
  ],
  redirect: (context, state) {
    final hasSeenOnboarding = prefs.getBool('onboarding_done') ?? false;
    if (hasSeenOnboarding) return '/home';
    return null;
  },
);
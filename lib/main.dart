import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import 'package:tunely/core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthState.load();

  final prefs = await SharedPreferences.getInstance();
  final router = buildRouter(prefs);

  await DeepLinkService.init(router);

  runApp(TunelyApp(router: router));
}

class TunelyApp extends StatelessWidget {
  final GoRouter router;
  const TunelyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tunely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

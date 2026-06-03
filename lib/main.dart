import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunely/core/providers/auth_provider.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import 'package:tunely/core/themes/app_theme.dart';
import 'package:tunely/features/profile/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Crear el router primero sin container
  final router = buildRouter(prefs);

  // Crear el container con el override del router
  final container = ProviderContainer(
    overrides: [routerProvider.overrideWithValue(router)],
  );

  // Cargar tokens guardados
  await container.read(authProvider.notifier).loadFromStorage();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TunelyApp(prefs: prefs, container: container),
    ),
  );
}

class TunelyApp extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  final ProviderContainer container;
  const TunelyApp({super.key, required this.prefs, required this.container});

  @override
  ConsumerState<TunelyApp> createState() => _TunelyAppState();
}

class _TunelyAppState extends ConsumerState<TunelyApp> {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _router = widget.container.read(routerProvider);
    DeepLinkService.init(_router, ref);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Tunely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

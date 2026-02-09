import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/router/app_router.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/core/utils/url_strategy_stub.dart'
    if (dart.library.html) 'package:wow_companion/core/utils/url_strategy_web.dart';

void main() async {
  configureUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WoW Companion',
      debugShowCheckedModeBanner: false,
      theme: WowTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

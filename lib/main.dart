import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/router/app_router.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

void main() async {
  usePathUrlStrategy();
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

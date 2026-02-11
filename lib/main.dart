import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/router/app_router.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/core/utils/url_strategy_stub.dart'
    if (dart.library.html) 'package:wow_companion/core/utils/url_strategy_web.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';

void main() async {
  configureUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _localeNotifier = sl<LocaleNotifier>();

  @override
  void initState() {
    super.initState();
    _localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeNotifier.removeListener(_onLocaleChanged);

    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WoW Companion',
      debugShowCheckedModeBanner: false,
      theme: WowTheme.darkTheme,
      routerConfig: appRouter,
      locale: _localeNotifier.locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
    );
  }
}

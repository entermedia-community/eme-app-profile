import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioUtil.init();

  const isRelease = kReleaseMode;
  const defaultSiteRoot = isRelease
      ? 'https://eme.world'
      : 'http://localhost.com:8080';
  const siteRoot = String.fromEnvironment('SITEROOT', defaultValue: defaultSiteRoot);
  const mediaDb = String.fromEnvironment(
    'MEDIADB',
    defaultValue: '$siteRoot/site/mediadb',
  );

  await OpenI().initialize({
    'mediadb': mediaDb,
    'siteroot': siteRoot,
    'catalogid': 'site/catalog',
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: EmeWorldApp()));
}

class EmeWorldApp extends ConsumerWidget {
  const EmeWorldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'EME World',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

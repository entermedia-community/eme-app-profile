import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/deep_link_handler.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioUtil.init();

  const isRelease = kReleaseMode;
  const defaultSiteRoot = isRelease
      ? 'https://eme.world'
      : 'http://localhost:8080';
  const siteRoot = String.fromEnvironment(
    'SITEROOT',
    defaultValue: defaultSiteRoot,
  );
  const mediaDb = String.fromEnvironment(
    'MEDIADB',
    defaultValue: '$siteRoot/site/mediadb',
  );

  await OpenI().initialize({
    'mediadb': mediaDb,
    'siteroot': siteRoot,
    'catalogid': 'site/catalog',
  });

  // Initialize Firebase Push Notifications
  await PushNotificationService.instance.initialize(
    onNotificationTap: (PushNotificationMessage message) {
      debugPrint(
        '[Main] Notification tapped: ${message.title} (data: ${message.data})',
      );
      final user = message.userId ?? message.data['username']?.toString();
      if (user != null && user.isNotEmpty) {
        DeepLinkHandler.instance.handleDeepLink(
          DeepLinkPayload(
            rawUri: Uri.parse('emeworld://chat/$user'),
            type: DeepLinkType.chat,
            username: user,
            channelId: message.channelId,
          ),
        );
      }
    },
  );

  // Initialize Deep Linking
  await DeepLinkService.instance.initialize(
    onDeepLinkReceived: (DeepLinkPayload payload) {
      DeepLinkHandler.instance.handleDeepLink(payload);
    },
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: EmeWorldApp()));
}

/// Keeps the UI from stretching on wide viewports (e.g. Chrome).
const double _maxAppWidth = 600;

class EmeWorldApp extends ConsumerWidget {
  const EmeWorldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'EME World',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => ColoredBox(
        color: Color(
          ref.watch(themeModeProvider) == ThemeMode.dark
              ? 0xff1c1c1c
              : 0xffefefef,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxAppWidth),
            // Clip so route transitions don't slide outside the max width.
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

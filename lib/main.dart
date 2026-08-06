import 'package:eme_world/l10n/app_localizations.dart';
import 'package:eme_world/providers/auth_provider.dart';
import 'package:eme_world/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/workspace_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkspaceService.init();
  await AuthService.init();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'Catalog Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1319),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38B6FF),
          secondary: Color(0xFF8A2387),
          surface: Color(0xFF0F1319),
          error: Color(0xFFF50057),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: Color(0xFF90A4AE),
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFF78909C),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();

    DeepLinkService.init(
      onWorkspaceOpened: (workspace) {
        if (mounted) {
          ref.read(authProvider.notifier).refresh();
          ref.read(workspaceProvider.notifier).refresh();
        }
      },
      onParametersReceived: (parameters) {
        if (mounted) {
          ref.read(authProvider.notifier).refresh();
          ref.read(workspaceProvider.notifier).refresh();
        }
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  void _handleLogin(String email) {
    ref.read(authProvider.notifier).refresh();
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
  }

  void _handleWorkspaceChanged() {
    ref.read(authProvider.notifier).refresh();
    ref.read(workspaceProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn) {
      return SelectionArea(
        child: DashboardScreen(
          fullName: authState.fullName,
          onLogout: _handleLogout,
          onWorkspaceChanged: _handleWorkspaceChanged,
        ),
      );
    } else {
      return SelectionArea(
        child: LoginScreen(
          onLoginSuccess: _handleLogin,
          onWorkspaceChanged: _handleWorkspaceChanged,
        ),
      );
    }
  }
}


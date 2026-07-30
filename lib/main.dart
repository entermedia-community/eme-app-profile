import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/workspace_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkspaceService.init();
  await AuthService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late bool _isLoggedIn;
  late String _username;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = AuthService.isLoggedIn;
    _username = AuthService.userId ?? '';

    DeepLinkService.init(
      onWorkspaceOpened: (workspace) {
        if (mounted) {
          _handleWorkspaceChanged();
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
    setState(() {
      _isLoggedIn = true;
      _username = AuthService.userId ?? email;
    });
  }

  void _handleLogout() async {
    await AuthService.logout();
    setState(() {
      _isLoggedIn = false;
      _username = '';
    });
  }

  void _handleWorkspaceChanged() {
    setState(() {
      _isLoggedIn = AuthService.isLoggedIn;
      _username = AuthService.userId ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return SelectionArea(
        child: DashboardScreen(
          username: _username,
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

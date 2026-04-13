import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'providers/template_provider.dart';
import 'providers/user_provider.dart';
import 'providers/generation_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().loadFromPrefs();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  runApp(const FaceSwapApp());
}

class FaceSwapApp extends StatefulWidget {
  const FaceSwapApp({super.key});

  @override
  State<FaceSwapApp> createState() => _FaceSwapAppState();
}

class _FaceSwapAppState extends State<FaceSwapApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GenerationProvider()),
        ChangeNotifierProvider(create: (_) {
          final svc = SubscriptionService();
          svc.initialize();
          return svc;
        }),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Handles theme mode binding without rebuilding the entire widget tree on every notification.
/// Only MaterialApp rebuilds when themeMode changes, and Flutter's internal theme system
/// efficiently propagates color changes to child widgets via inheritedTheme.
class _ThemedApp extends StatefulWidget {
  const _ThemedApp();

  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> {
  UserProvider? _userProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      final themeProvider = context.read<ThemeProvider>();
      _userProvider = userProvider;
      if (userProvider.user != null) {
        themeProvider.initFromUser(userProvider.user?.theme);
      }
      userProvider.addListener(_onUserChanged);
    });
  }

  void _onUserChanged() {
    if (!mounted) return;
    final user = _userProvider?.user;
    if (user != null) {
      context.read<ThemeProvider>().initFromUser(user.theme);
    }
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );

    return MaterialApp(
      title: 'AI FaceSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _EntryPoint(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/email-login': (_) => const EmailLoginScreen(),
      },
    );
  }
}

/// Entry point — check if onboarding needed
class _EntryPoint extends StatefulWidget {
  const _EntryPoint();

  @override
  State<_EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<_EntryPoint> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !done;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return _showOnboarding
        ? const OnboardingScreen()
        : const HomeScreen();
  }
}

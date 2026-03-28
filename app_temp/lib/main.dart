import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/template_provider.dart';
import 'providers/user_provider.dart';
import 'providers/generation_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

/// AI换图应用入口
class FaceSwapApp extends StatelessWidget {
  const FaceSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GenerationProvider()),
      ],
      child: MaterialApp(
        title: 'AI FaceSwap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _EntryPoint(),
        routes: {
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/email-login': (_) => const EmailLoginScreen(),
        },
      ),
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
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return _showOnboarding
        ? const OnboardingScreen()
        : const HomeScreen();
  }
}

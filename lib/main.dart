import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // إذا استعملتي FlutterFire CLI
import 'screens/splash_screen.dart';

import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard/intern_dashboard.dart';
import 'screens/dashboard/supervisor_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/fintech_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ضروري قبل أي async
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // تهيئة Firebase
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const NoRaApp(),
    ),
  );
}

class NoRaApp extends StatelessWidget {
  const NoRaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'path finders platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: appState.locale,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardRouter(),
        '/fintech': (context) => const ModernFintechDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/supervisor-dashboard': (context) => const SupervisorDashboard(),
        '/intern-dashboard': (context) => const InternDashboard(),
      },
      builder: (context, child) {
        return Directionality(
          textDirection: appState.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String userRole = appState.userRole ?? 'Intern';

    switch (userRole.toLowerCase()) {
      case 'supervisor':
        return const SupervisorDashboard();
      case 'admin':
        return const AdminDashboard();
      case 'intern':
      default:
        return const InternDashboard();
    }
  }
}

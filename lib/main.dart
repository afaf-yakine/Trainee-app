import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard/intern_dashboard.dart';
import 'screens/dashboard/supervisor_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
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
      title: 'NoRa Internship Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: appState.locale,

      // The directionality is automatically handled by Flutter's Locale setting
      // but we can wrap parts of the UI if specific RTL overrides are needed.
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardRouter(),
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

    switch (userRole) {
      case 'Supervisor':
        return const SupervisorDashboard();
      case 'Admin':
        return const AdminDashboard();
      case 'Intern':
      default:
        return const InternDashboard();
    }
  }
}

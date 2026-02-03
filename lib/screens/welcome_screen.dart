import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/language_switcher.dart';
import '../widgets/theme_toggle.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              right: appState.isRTL ? null : 20,
              left: appState.isRTL ? 20 : null,
              child: Row(
                children: [
                  const LanguageSwitcher(),
                  const SizedBox(width: 10),
                  const ThemeToggle(),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Trainee',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.translate('welcome to trainee'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // زر Login
                  CustomButton(
                    text: appState.translate('login'),
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    backgroundColor: Colors.blue, // نفس اللون للزرين
                    textColor: Colors.white,
                    width: 200, // نفس العرض للزرين
                    height: 50, // نفس الطول
                  ),
                  const SizedBox(height: 16),
                  // زر SignUp
                  CustomButton(
                    text: appState.translate('signup'),
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    backgroundColor: Colors.blue, // نفس اللون للزرين
                    textColor: Colors.white,
                    width: 200, // نفس العرض
                    height: 50, // نفس الطول
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

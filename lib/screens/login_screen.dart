import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/language_switcher.dart';
import '../widgets/theme_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Intern';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isNarrow ? double.infinity : 450,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LanguageSwitcher(),
                              ThemeToggle(),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            appState.translate('login'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 32),
                          CustomInput(
                            label: appState.translate('email'),
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),
                          CustomInput(
                            label: appState.translate('password'),
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 20),
                          // Role Selection Dropdown for Demo Simulation
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: appState.translate('role'),
                              prefixIcon: const Icon(Icons.badge_outlined,
                                  color: AppTheme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                ['Intern', 'Supervisor', 'Admin'].map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(
                                    appState.translate(role.toLowerCase())),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: appState.isRTL
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/forgot-password',
                              ),
                              child: Text(
                                appState.translate('forgot_password'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: appState.translate('login'),
                              onPressed: () {
                                appState.setUserRole(_selectedRole);
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Demo: Default to selected role even for Google Sign-In
                              appState.setUserRole(_selectedRole);
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            },
                            icon: const Icon(Icons.g_mobiledata, size: 32),
                            label: Text(
                              appState.translate('google_sign_in'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(appState.translate('dont_have_account')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                child: Text(
                                  appState.translate('signup'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

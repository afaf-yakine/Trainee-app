import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/language_switcher.dart';
import '../widgets/theme_toggle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _selectedRole = 'Intern';

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();

  Future<void> handleSignUp() async {
    final appState = Provider.of<AppState>(context, listen: false);

    String name = '${firstNameController.text} ${lastNameController.text}';
    String email = emailController.text.trim();
    String password = passwordController.text;
    String specialty = specialtyController.text.trim();
    String role = _selectedRole;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        specialty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'specialty': specialty,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ تحديث AppState فورًا بعد التسجيل
        appState.setCurrentUser(name, email, role, specialty);
      }

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
  }

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
                    maxWidth: isNarrow ? double.infinity : 500,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              LanguageSwitcher(),
                              ThemeToggle(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            appState.translate('signup'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 24),
                          if (isNarrow) ...[
                            CustomInput(
                              label: appState.translate('first_name'),
                              icon: Icons.person_outline,
                              controller: firstNameController,
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              label: appState.translate('last_name'),
                              icon: Icons.person_outline,
                              controller: lastNameController,
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(
                                  child: CustomInput(
                                    label: appState.translate('first_name'),
                                    icon: Icons.person_outline,
                                    controller: firstNameController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomInput(
                                    label: appState.translate('last_name'),
                                    icon: Icons.person_outline,
                                    controller: lastNameController,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          CustomInput(
                            label: appState.translate('email'),
                            icon: Icons.email_outlined,
                            controller: emailController,
                          ),
                          const SizedBox(height: 16),
                          CustomInput(
                            label: appState.translate('password'),
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: passwordController,
                          ),
                          const SizedBox(height: 16),
                          CustomInput(
                            label: appState.translate('specialty'),
                            icon: Icons.work_outline,
                            controller: specialtyController,
                          ),
                          const SizedBox(height: 24),
                          if (isNarrow)
                            Column(
                              children: [
                                _buildRoleOption('Intern', appState, true),
                                const SizedBox(height: 12),
                                _buildRoleOption('Supervisor', appState, true),
                                const SizedBox(height: 12),
                                _buildRoleOption('Admin', appState, true),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _buildRoleOption('Intern', appState, false),
                                const SizedBox(width: 12),
                                _buildRoleOption('Supervisor', appState, false),
                                const SizedBox(width: 12),
                                _buildRoleOption('Admin', appState, false),
                              ],
                            ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: appState.translate('signup'),
                              onPressed: handleSignUp,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(appState.translate('already_have_account')),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(appState.translate('login')),
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

  Widget _buildRoleOption(String role, AppState appState, bool isMobile) {
    final bool isSelected = _selectedRole == role;
    final Widget card = GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            appState.translate(role.toLowerCase()),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );

    return isMobile ? card : Expanded(child: card);
  }
}

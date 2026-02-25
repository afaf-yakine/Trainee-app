import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? selectedSpecialization;
  final List<String> specializations = ['Accounting', 'IT', 'HR', 'Marketing'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // Find supervisor with same specialization
      final supervisorQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'supervisor')
          .where('specialization', isEqualTo: selectedSpecialization)
          .limit(1)
          .get();

      String assignedSupervisorId = '';
      if (supervisorQuery.docs.isNotEmpty) {
        assignedSupervisorId = supervisorQuery.docs.first.id;
      }

      final UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userData = {
          'uid': credential.user!.uid,
          'firstName': firstName,
          'lastName': lastName,
          'name': '$firstName $lastName',
          'email': email,
          'role': 'intern',
          'specialization': selectedSpecialization,
          'assignedSupervisorId': assignedSupervisorId,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData);

        appState.setCurrentUser(
            '$firstName $lastName', email, 'intern', selectedSpecialization!);
        appState.setUserRole('intern');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Signup failed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final user = await AuthService.signInWithGoogle(context);
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final userData = doc.data()!;
          appState.setCurrentUser(
            userData['name'] ?? '',
            userData['email'] ?? '',
            userData['role'] ?? 'intern',
            userData['specialization'] ?? '',
          );
          appState.setUserRole(userData['role'] ?? 'intern');
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1F44), Color(0xFF1E3C72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Top Right: Language Capsule
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: PopupMenuButton<String>(
                      onSelected: (String code) {
                        appState.setLocale(code);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'ar',
                          child: Row(
                            children: [
                              Text('🇸🇦', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 10),
                              Text('Arabic'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'fr',
                          child: Row(
                            children: [
                              Text('🇫🇷', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 10),
                              Text('French'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'en',
                          child: Row(
                            children: [
                              Text('🇬🇧', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 10),
                              Text('English'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              appState.locale.languageCode.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Title (Centered above card)
                Center(
                  child: Text(
                    appState.translate('create_account'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // White Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // First & Last Name row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: appState.translate('first_name'),
                                prefixIcon: const Icon(Icons.person,
                                    color: Color(0xFF0A1F44)),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: appState.translate('last_name'),
                                prefixIcon: const Icon(Icons.person,
                                    color: Color(0xFF0A1F44)),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Email Field
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: appState.translate('email'),
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF0A1F44)),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Specialization Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSpecialization,
                            hint: Text(appState.translate('specialization'),
                                style: const TextStyle(color: Colors.black54)),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF0A1F44)),
                            items: specializations.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                    appState.translate(value.toLowerCase()),
                                    style:
                                        const TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedSpecialization = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: appState.translate('password'),
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF0A1F44)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: appState.translate('confirm_password'),
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF0A1F44)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Signup Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1F44),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  appState.translate('signup'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(appState.translate('or'),
                                style: const TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google button
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                appState.translate('google_sign_in'),
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appState.translate('already_have_account'),
                            style: const TextStyle(color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/login'),
                            child: Text(
                              appState.translate('login'),
                              style: const TextStyle(
                                  color: Color(0xFF0A1F44),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

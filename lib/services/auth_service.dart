import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  // This is a stub for future backend integration (Firebase, API, etc.)

  static Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required String specialty,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(
        '$firstName $lastName',
      );

      await UserService.createUserProfile(role: role);

      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ==============================================
  // Firebase Google Sign-In added safely
  // ==============================================
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // المستخدم ألغى تسجيل الدخول

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // بعد تسجيل الدخول الناجح
      Navigator.pushNamed(context, '/traineeDashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with Google: $e')));
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// إنشاء أو تحديث ملف المستخدم في Firestore
  static Future<void> createUserProfile({
    required String role,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user');
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

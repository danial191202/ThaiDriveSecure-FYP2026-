import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// LOGIN
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// REGISTER / SIGN UP
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'userId': user.uid,
            'email': email,
            'fullName': '',
            'phone': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}

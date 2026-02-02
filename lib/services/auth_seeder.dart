import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSeeder {
  AuthSeeder({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> seedAdminAndModerator({required String password}) async {
    await _seedUser(
      email: 'admin@docin.com',
      alias: 'Admin Supremo',
      role: 'admin',
      password: password,
    );

    await _seedUser(
      email: 'moderador@docin.com',
      alias: 'El Vigilante',
      role: 'moderator',
      password: password,
    );

    await _auth.signOut();
  }

  Future<void> _seedUser({
    required String email,
    required String alias,
    required String role,
    required String password,
  }) async {
    User? user;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
      } else {
        rethrow;
      }
    }

    if (user == null) {
      throw Exception('No se pudo crear o autenticar $email');
    }

    await user.updateDisplayName(alias);

    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'alias': alias,
      'role': role,
      'baseRole': role,
      'canChangeRole': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

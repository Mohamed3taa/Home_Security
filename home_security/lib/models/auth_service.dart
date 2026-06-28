// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? lastError;

  /// Getter for external access to GoogleSignIn instance
  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Handles Google Sign-In with callbacks for incomplete profile and success
  Future<void> signInWithGoogle({
    required VoidCallback onIncompleteProfile,
    required VoidCallback onSuccess,
  }) async {
    try {
      // Sign out any existing user to ensure a fresh login
      if (_firebaseAuth.currentUser != null) {
        await signOut();
      }

      // Initiate Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        lastError = "Google Sign-In was cancelled.";
        return;
      }

      // Obtain Google authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Check if user data exists in the 'Users' collection
        DocumentReference userDoc = _firestore
            .collection('Users')
            .doc(user.uid);
        DocumentSnapshot docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // Profile is incomplete, trigger onIncompleteProfile callback
          onIncompleteProfile();
          return;
        }

        // Check for required fields (adjust based on your data model)
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        if (data == null || data['name'] == null || data['phone'] == null) {
          // Profile is incomplete, trigger onIncompleteProfile callback
          onIncompleteProfile();
          return;
        }

        // Profile is complete, trigger onSuccess callback
        onSuccess();
      }
    } catch (e) {
      lastError = "Google Sign-In failed: $e";
    }
  }

  /// Signs out the current user from Firebase and Google
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_login_screen.dart';
import 'profile_setup_screen.dart';
import 'swipe_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ NOT LOGGED IN → LOGIN SCREEN
        if (!snapshot.hasData) {
          return const EmailLoginScreen();
        }

        // ✅ LOGGED IN → CHECK PROFILE
        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                profileSnap.data?.data() as Map<String, dynamic>?;

            // ❌ PROFILE NOT COMPLETE → PROFILE SETUP
            if (data == null ||
                data["name"] == null ||
                data["age"] == null ||
                data["gender"] == null ||
                data["bio"] == null) {
              return const ProfileSetupScreen();
            }

            // ✅ PROFILE COMPLETE → SWIPE SCREEN
            return const SwipeScreen();
          },
        );
      },
    );
  }
}
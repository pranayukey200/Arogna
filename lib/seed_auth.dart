import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> seedDatabase(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding database...')));
  
  final roles = {
    'admin@arogna.com': 'admin',
    'responder@arogna.com': 'responder',
    'hospital@arogna.com': 'hospital',
  };

  for (var entry in roles.entries) {
    String email = entry.key;
    String role = entry.value;
    String password = 'password123';

    try {
      // Try to create user
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      // Update Firestore role
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
      });

    } catch (e) {
      debugPrint('Error seeding user $email: $e');
    }
  }
  
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database seeded! Try logging in.')));
}

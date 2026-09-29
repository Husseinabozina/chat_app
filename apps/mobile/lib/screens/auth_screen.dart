import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> _submitUserForm({
    required String email,
    required String username,
    required String password,
    required bool isLogin,
    XFile? image,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return;
      }

      final selectedImage = image;
      if (selectedImage == null) {
        throw StateError('A profile image is required to create an account.');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) {
        throw StateError('Firebase did not return a user after sign up.');
      }

      final imageReference = FirebaseStorage.instance
          .ref()
          .child('User_Image')
          .child('${user.uid}.jpg');

      await imageReference.putFile(File(selectedImage.path));
      final imageUrl = await imageReference.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'imageUrl': imageUrl,
      });
    } on FirebaseAuthException catch (error) {
      _showError(
        error.message ?? 'Authentication failed. Please check your details.',
      );
    } catch (error, stackTrace) {
      debugPrint('Authentication flow failed: $error\n$stackTrace');
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[700],
      body: AuthForm(isLoading: _isLoading, onSubmit: _submitUserForm),
    );
  }
}

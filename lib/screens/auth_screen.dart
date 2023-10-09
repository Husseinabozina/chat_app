import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/auth_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isloading = false;
  final _auth = FirebaseAuth.instance;
  void _submitUserForm(String email, String username, String password,
      bool isLogin, BuildContext ctx,
      [XFile? image]) async {
    UserCredential result;
    try {
      setState(() {
        _isloading = true;
      });

      if (isLogin) {
        result = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        result = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        final ref = FirebaseStorage.instance
            .ref()
            .child('User_Image')
            .child(result.user!.uid + '.jpg');
        await ref.putFile(File(image!.path));
        final url = await ref.getDownloadURL();

        FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set({'username': username, 'email': email, 'imageUrl': url});
      }

      setState(() {
        _isloading = false;
      });
    } on PlatformException catch (error) {
      var message = 'An error occured please check your credential!!';
      if (error.message != null) {
        message = error.message!;
      }
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.black54,
      ));
      setState(() {
        _isloading = false;
      });
    } catch (error) {
      setState(() {
        _isloading = false;
      });
      print(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[700],
      body: AuthWidget(_submitUserForm, _isloading),
    );
  }
}

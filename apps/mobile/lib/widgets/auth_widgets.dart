import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:image_picker/image_picker.dart';

import 'pickers/imagepicker.dart';

class AuthWidget extends StatefulWidget {
  void Function(String email, String userName, String password, bool isLogin,
      BuildContext ctx,
      [XFile image]) submitUser;
  bool isloading;
  AuthWidget(this.submitUser, this.isloading);

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  final _formKey = GlobalKey<FormState>();
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';
  bool isLogin = false;
  XFile? uploudimage;
  void imagePicked(XFile image) {
    uploudimage = image;
  }

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();
    if (uploudimage == null && !isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).accentColor,
          content: Text(' you should uploud an image')));

      return;
    }
    if (isValid && !isLogin) {
      _formKey.currentState!.save();
      widget.submitUser(_userEmail.trim(), _userName.trim(),
          _userPassword.trim(), isLogin, context, uploudimage!);
    } else {
      _formKey.currentState!.save();
      widget.submitUser(_userEmail.trim(), _userName.trim(),
          _userPassword.trim(), isLogin, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLogin) Image_Picker(imagePicked),
                TextFormField(
                  key: ValueKey('Email'),
                  validator: (value) {
                    if (value!.isEmpty || !value!.contains('@')) {
                      return 'please enter a valid Email';
                    }

                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email address'),
                  onSaved: (value) {
                    _userEmail = value!;
                  },
                ),
                if (!isLogin)
                  TextFormField(
                    key: ValueKey('userName'),
                    validator: (value) {
                      if (value!.isEmpty || value!.length < 4) {
                        return 'User name must be at least 4 characters';
                      }
                    },
                    decoration: InputDecoration(labelText: 'user name'),
                    onSaved: (value) {
                      _userName = value!;
                    },
                  ),
                TextFormField(
                  key: ValueKey('password'),
                  validator: (value) {
                    if (value!.isEmpty || value!.length < 7) {
                      return 'User name must be at least 7 characters';
                    }
                  },
                  decoration: InputDecoration(labelText: 'passward'),
                  obscureText: true,
                  onSaved: (value) {
                    _userPassword = value!;
                  },
                ),
                if (widget.isloading) CircularProgressIndicator(),
                if (!widget.isloading)
                  ElevatedButton(
                    onPressed: _trySubmit,
                    child: Text(
                      isLogin ? 'Login' : 'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin ? 'create new account' : 'already have an account',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

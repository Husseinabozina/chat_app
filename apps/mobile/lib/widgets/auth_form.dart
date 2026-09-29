import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'pickers/image_picker_input.dart';

typedef SubmitAuthForm = Future<void> Function({
  required String email,
  required String username,
  required String password,
  required bool isLogin,
  XFile? image,
});

class AuthForm extends StatefulWidget {
  const AuthForm({required this.onSubmit, required this.isLoading, super.key});

  final SubmitAuthForm onSubmit;
  final bool isLoading;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();

  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';
  bool _isLogin = false;
  XFile? _selectedImage;

  void _onImagePicked(XFile image) {
    _selectedImage = image;
  }

  Future<void> _trySubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (!_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          content: const Text('Please add a profile image.'),
        ),
      );
      return;
    }

    form.save();

    await widget.onSubmit(
      email: _userEmail.trim(),
      username: _userName.trim(),
      password: _userPassword,
      isLogin: _isLogin,
      image: _selectedImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isLogin) ImagePickerInput(onImagePicked: _onImagePicked),
                TextFormField(
                  key: const ValueKey('email'),
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userEmail = value ?? '';
                  },
                ),
                if (!_isLogin)
                  TextFormField(
                    key: const ValueKey('username'),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.length < 4) {
                        return 'Username must be at least 4 characters.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _userName = value ?? '';
                    },
                  ),
                TextFormField(
                  key: const ValueKey('password'),
                  autofillHints: const [AutofillHints.password],
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if ((value ?? '').length < 7) {
                      return 'Password must be at least 7 characters.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!widget.isLoading) {
                      _trySubmit();
                    }
                  },
                  onSaved: (value) {
                    _userPassword = value ?? '';
                  },
                ),
                const SizedBox(height: 8),
                if (widget.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _trySubmit,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                TextButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                  child: Text(
                    _isLogin
                        ? 'Create a new account'
                        : 'I already have an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

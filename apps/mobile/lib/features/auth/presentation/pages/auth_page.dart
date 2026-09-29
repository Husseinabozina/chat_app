import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_form.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.authRepository,
    super.key,
  });

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthFormState>(
      listenWhen: (_, current) => current is AuthFormFailed,
      listener: (context, state) {
        if (state case AuthFormFailed(:final failure)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_failureMessage(failure)),
              backgroundColor: Colors.black87,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.orange[700],
          body: AuthForm(
            isLoading: state is AuthFormSubmitting,
            onSubmit: ({
              required email,
              required username,
              required password,
              required isLogin,
              profileImagePath,
            }) {
              return context.read<AuthCubit>().submit(
                email: email,
                username: username,
                password: password,
                isLogin: isLogin,
                profileImagePath: profileImagePath,
              );
            },
          ),
        );
      },
    );
  }

  String _failureMessage(AppFailure failure) {
    return switch (failure.kind) {
      FailureKind.unauthorized =>
        'We could not sign you in with those credentials.',
      FailureKind.validation =>
        'Please check the information you entered and try again.',
      FailureKind.conflict =>
        'An account already exists for that email address.',
      FailureKind.network =>
        'The network is unavailable. Please check your connection and retry.',
      FailureKind.unknown =>
        'Something went wrong. Please try again.',
    };
  }
}

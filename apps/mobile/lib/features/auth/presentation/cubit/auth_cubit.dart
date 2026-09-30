import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthFormState {
  const AuthFormState();
}

final class AuthFormIdle extends AuthFormState {
  const AuthFormIdle();
}

final class AuthFormSubmitting extends AuthFormState {
  const AuthFormSubmitting();
}

final class AuthFormFailed extends AuthFormState {
  const AuthFormFailed(this.failure);

  final AppFailure failure;
}

final class AuthCubit extends Cubit<AuthFormState> {
  AuthCubit(this._repository) : super(const AuthFormIdle());

  final AuthRepository _repository;

  Future<void> submit({
    required String email,
    required String username,
    required String password,
    required bool isLogin,
    String? profileImagePath,
  }) async {
    emit(const AuthFormSubmitting());

    try {
      if (isLogin) {
        await _repository.signIn(email: email, password: password);
      } else {
        final imagePath = profileImagePath;
        if (imagePath == null) {
          throw const AppFailure(
            kind: FailureKind.validation,
            debugMessage: 'Profile image is required.',
          );
        }

        await _repository.register(
          email: email,
          username: username,
          password: password,
          profileImagePath: imagePath,
        );
      }

      emit(const AuthFormIdle());
    } on AppFailure catch (failure) {
      emit(AuthFormFailed(failure));
    } catch (error) {
      emit(
        AuthFormFailed(
          AppFailure(kind: FailureKind.unknown, debugMessage: error.toString()),
        ),
      );
    }
  }
}

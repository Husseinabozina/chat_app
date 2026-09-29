import 'package:chat_app/core/failures/app_failure.dart';
import 'package:chat_app/features/auth/domain/entities/auth_user.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthCubit delegates sign in to repository', () async {
    final repository = _FakeAuthRepository();
    final cubit = AuthCubit(repository);

    await cubit.submit(
      email: 'user@example.com',
      username: '',
      password: 'password123',
      isLogin: true,
    );

    expect(repository.lastSignedInEmail, 'user@example.com');
    expect(cubit.state, isA<AuthFormIdle>());

    await cubit.close();
  });

  test('AuthCubit exposes typed failures', () async {
    final repository = _FakeAuthRepository(
      signInFailure: const AppFailure(kind: FailureKind.unauthorized),
    );
    final cubit = AuthCubit(repository);

    await cubit.submit(
      email: 'wrong@example.com',
      username: '',
      password: 'bad-password',
      isLogin: true,
    );

    final state = cubit.state;
    expect(state, isA<AuthFormFailed>());
    expect(
      (state as AuthFormFailed).failure.kind,
      FailureKind.unauthorized,
    );

    await cubit.close();
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.signInFailure,
  });

  final AppFailure? signInFailure;
  String? lastSignedInEmail;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String profileImagePath,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final failure = signInFailure;
    if (failure != null) {
      throw failure;
    }

    lastSignedInEmail = email;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthUser?> watchAuthState() => const Stream.empty();
}

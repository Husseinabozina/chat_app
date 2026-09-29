import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  AuthUser? get currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String profileImagePath,
  });

  Future<void> signOut();
}

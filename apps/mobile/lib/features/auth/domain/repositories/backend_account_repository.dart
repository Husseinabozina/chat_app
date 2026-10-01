import '../entities/auth_user.dart';

/// Email/password account contract for the new backend product. Profile and
/// media setup are separate from account creation.
abstract interface class BackendAccountRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watchAuthState();
  Future<void> initialize();
  Future<void> login({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> logout();
}

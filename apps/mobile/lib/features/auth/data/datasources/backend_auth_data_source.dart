import '../../../../core/network/api_session.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../domain/entities/auth_user.dart';

/// Backend auth for the direct-conversation product. The legacy Firebase form
/// also requires an image upload, which is outside the current REST contract.
final class BackendAuthDataSource {
  const BackendAuthDataSource(this._api);

  final RestApiClient _api;

  Future<AuthUser> login({required String email, required String password}) =>
      _authenticate('/auth/login', email: email, password: password);

  Future<AuthUser> register({
    required String email,
    required String password,
  }) => _authenticate('/auth/register', email: email, password: password);

  Future<ApiSession?> currentSession() => _api.currentSession();

  Future<void> logout() async {
    final session = await _api.currentSession();
    await _api.clearSession();
    if (session != null) {
      await _api.request(
        'POST',
        '/auth/logout',
        authenticated: false,
        body: {'refreshToken': session.refreshToken},
      );
    }
  }

  Future<AuthUser> _authenticate(
    String path, {
    required String email,
    required String password,
  }) async {
    final revision = _api.sessionRevision;
    final data = await _api.request(
      'POST',
      path,
      authenticated: false,
      body: {'email': email, 'password': password},
    );
    final session = sessionFromAuthResponse(data);
    try {
      await _api.saveSession(session, expectedRevision: revision);
    } catch (_) {
      _api.discardSession(session.refreshToken);
      rethrow;
    }

    final user = data['user'] as Map<String, dynamic>;
    return AuthUser(id: session.userId, email: user['email'] as String?);
  }
}

import 'dart:async';

import '../../../../core/network/api_session.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../../conversations/data/repositories/api_conversations_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/backend_account_repository.dart';
import '../datasources/backend_auth_data_source.dart';

/// Separate from the legacy image-required Firebase registration contract.
/// Owns account-scoped repository/socket lifetime, not presentation state.
final class BackendSessionController implements BackendAccountRepository {
  BackendSessionController(this._auth, this._api, this._conversations) {
    _subscription = _api.sessionChanges.listen(_sessionChanged);
  }

  final BackendAuthDataSource _auth;
  final RestApiClient _api;
  final ApiConversationsRepository _conversations;
  final _users = StreamController<AuthUser?>.broadcast();
  StreamSubscription<ApiSession?>? _subscription;
  AuthUser? _user;
  int _generation = 0;
  bool _closed = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watchAuthState() => Stream.multi((controller) {
    final subscription = _users.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.add(_user);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> initialize() async {
    final generation = ++_generation;
    final session = await _auth.currentSession();
    if (session == null || generation != _generation || _closed) return;
    final data = await _api.request('GET', '/users/me');
    await _activate(
      AuthUser(id: data['id'] as String, email: data['email'] as String?),
      generation,
    );
  }

  @override
  Future<void> login({required String email, required String password}) async {
    final generation = await _beginAuthentication();
    _checkGeneration(generation);
    final user = await _auth.login(email: email, password: password);
    await _activate(user, generation);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final generation = await _beginAuthentication();
    _checkGeneration(generation);
    final user = await _auth.register(email: email, password: password);
    await _activate(user, generation);
  }

  Future<int> _beginAuthentication() async {
    if (_closed) throw StateError('Session controller is closed.');
    final generation = ++_generation;
    _user = null;
    _users.add(null);
    await _conversations.stop();
    await _api.clearSession();
    return generation;
  }

  void _checkGeneration(int generation) {
    if (_closed || generation != _generation) {
      throw StateError('Authentication was cancelled.');
    }
  }

  Future<void> _activate(AuthUser user, int generation) async {
    if (_closed || generation != _generation) return;
    _user = user;
    _users.add(user);
    // Auth remains successful if realtime is temporarily offline. The transport
    // owns reconnect retries; REST failures remain visible in repository state.
    try {
      await _conversations.start(user.id);
    } catch (error) {
      if (!_closed && generation == _generation) _users.addError(error);
    }
  }

  void _sessionChanged(ApiSession? session) {
    if (_closed || session != null) return;
    if (_user == null) return;
    _generation++;
    _user = null;
    _users.add(null);
    unawaited(_conversations.stop());
  }

  @override
  Future<void> logout() async {
    _generation++;
    _user = null;
    _users.add(null);
    await _conversations.stop();
    await _auth.logout();
  }

  Future<void> close() async {
    _generation++;
    _closed = true;
    await _subscription?.cancel();
    await _conversations.stop();
    await _users.close();
  }
}

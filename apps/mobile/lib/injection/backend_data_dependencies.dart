import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_session.dart';
import '../core/network/rest_api_client.dart';
import '../features/auth/data/datasources/backend_auth_data_source.dart';
import '../features/auth/data/repositories/backend_session_controller.dart';
import '../features/conversations/data/datasources/realtime_chat_data_source.dart';
import '../features/conversations/data/datasources/rest_conversations_data_source.dart';
import '../features/conversations/data/repositories/api_conversations_repository.dart';

/// Prepared for the direct-conversation UI rollout. The current app still
/// composes its legacy single-room Firebase repositories in AppDependencies.
final class BackendDataDependencies {
  BackendDataDependencies._({
    required this.auth,
    required this.conversations,
    required this.realtime,
    required this._httpClient,
    required this._api,
    required this.repository,
    required this.session,
  });

  factory BackendDataDependencies.fromEnvironment() {
    const raw = String.fromEnvironment('CHAT_API_BASE_URL');
    if (raw.isEmpty) {
      throw StateError('CHAT_API_BASE_URL is required for backend data mode.');
    }

    final serverUrl = Uri.parse(raw);
    if (!serverUrl.hasAuthority ||
        (serverUrl.scheme != 'https' && serverUrl.scheme != 'http')) {
      throw StateError('CHAT_API_BASE_URL must be an HTTP(S) origin.');
    }

    final httpClient = http.Client();
    final api = RestApiClient(
      baseUrl: serverUrl.resolve('/v1'),
      httpClient: httpClient,
      sessionStore: SecureApiSessionStore(const FlutterSecureStorage()),
    );

    final auth = BackendAuthDataSource(api);
    final conversations = RestConversationsDataSource(api);
    final realtime = RealtimeChatDataSource(serverUrl: serverUrl, api: api);
    final repository = ApiConversationsRepository(conversations, realtime);
    return BackendDataDependencies._(
      auth: auth,
      conversations: conversations,
      realtime: realtime,
      repository: repository,
      session: BackendSessionController(auth, api, repository),
      api: api,
      httpClient: httpClient,
    );
  }

  final BackendAuthDataSource auth;
  final RestConversationsDataSource conversations;
  final RealtimeChatDataSource realtime;
  final ApiConversationsRepository repository;
  final BackendSessionController session;
  final RestApiClient _api;
  final http.Client _httpClient;

  Future<void> close() async {
    await session.close();
    await repository.close();
    await realtime.close();
    await _api.close();
    _httpClient.close();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../app/backend_app_services.dart';
import '../core/network/api_session.dart';
import '../core/network/rest_api_client.dart';
import '../core/preferences/app_preferences.dart';
import '../core/preferences/secure_preferences_store.dart';
import '../features/auth/data/datasources/backend_auth_data_source.dart';
import '../features/auth/data/repositories/backend_session_controller.dart';
import '../features/conversations/data/datasources/realtime_chat_data_source.dart';
import '../features/conversations/data/datasources/rest_conversations_data_source.dart';
import '../features/conversations/data/repositories/api_conversations_repository.dart';
import '../features/media/data/api_media_repository.dart';
import '../features/push/data/fcm_push_repository.dart';
import '../features/push/domain/push_repository.dart';
import '../features/users/data/api_users_repository.dart';

/// Backend composition for the direct-conversation product entrypoint.
final class BackendDataDependencies {
  BackendDataDependencies._({
    required this.auth,
    required this.conversations,
    required this.realtime,
    required this._httpClient,
    required this._api,
    required this.repository,
    required this.session,
    required this.preferences,
    required this.push,
  });

  factory BackendDataDependencies.fromEnvironment() {
    const configured = String.fromEnvironment('CHAT_API_BASE_URL');
    final raw = configured.isNotEmpty
        ? configured
        : kDebugMode
        ? defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:55418'
              : 'http://127.0.0.1:55418'
        : '';

    if (raw.isEmpty) {
      throw StateError(
        'Release/profile builds require CHAT_API_BASE_URL. Debug builds use the local development server.',
      );
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
      push: FcmPushRepository(api, const FlutterSecureStorage()),
      auth: auth,
      conversations: conversations,
      realtime: realtime,
      repository: repository,
      session: BackendSessionController(auth, api, repository),
      preferences: AppPreferences(
        const SecurePreferencesStore(FlutterSecureStorage()),
      ),
      api: api,
      httpClient: httpClient,
    );
  }

  BackendAppServices get appServices => BackendAppServices(
    account: session,
    push: push,
    conversations: repository,
    users: ApiUsersRepository(_api),
    media: ApiMediaRepository(_api, _httpClient),
    pause: repository.pauseRealtime,
    resume: repository.resumeRealtime,
    preferences: preferences,
  );

  final BackendAuthDataSource auth;
  final RestConversationsDataSource conversations;
  final RealtimeChatDataSource realtime;
  final ApiConversationsRepository repository;
  final BackendSessionController session;
  final AppPreferences preferences;
  final PushRepository push;
  final RestApiClient _api;
  final http.Client _httpClient;

  Future<void> close() async {
    await push.close();
    await session.close();
    await repository.close();
    await realtime.close();
    await _api.close();
    _httpClient.close();
    preferences.dispose();
  }
}

import 'dart:convert';

import 'package:chat_app/core/network/api_session.dart';
import 'package:chat_app/core/network/rest_api_client.dart';
import 'package:chat_app/features/auth/data/datasources/backend_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final class MemorySessionStore implements ApiSessionStore {
  ApiSession? session;

  @override
  Future<ApiSession?> read() async => session;

  @override
  Future<void> write(ApiSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

void main() {
  test('login saves backend tokens and user identity', () async {
    final store = MemorySessionStore();
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/auth/login');
      expect(jsonDecode(request.body), {
        'email': 'alice@example.com',
        'password': 'password-12345',
      });
      return http.Response(
        jsonEncode(_sessionResponse('access-1', 'refresh-1')),
        200,
      );
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );

    final user = await BackendAuthDataSource(api)
        .login(email: 'alice@example.com', password: 'password-12345');

    expect(user.id, 'user-1');
    expect(user.email, 'alice@example.com');
    expect(store.session?.accessToken, 'access-1');
    expect(store.session?.refreshToken, 'refresh-1');
    client.close();
  });

  test('expired access token is refreshed before protected request', () async {
    final store = MemorySessionStore()
      ..session = ApiSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        userId: 'user-1',
      );
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/v1/auth/refresh') {
        expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
        return http.Response(
          jsonEncode(_sessionResponse('new-access', 'new-refresh')),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer new-access');
      return http.Response(
        '{"items":[],"hasMore":false,"nextCursor":null}',
        200,
      );
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );

    final result = await api.request('GET', '/conversations');

    expect(result['items'], isEmpty);
    expect(paths, ['/v1/auth/refresh', '/v1/conversations']);
    expect(store.session?.refreshToken, 'new-refresh');
    client.close();
  });

  test('logout clears local credentials after a network error', () async {
    final store = MemorySessionStore()
      ..session = ApiSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
        userId: 'user-1',
      );
    final client = MockClient(
      (_) async => throw http.ClientException('offline'),
    );
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );

    await expectLater(BackendAuthDataSource(api).logout(), throwsException);
    expect(store.session, isNull);
    client.close();
  });
}

Map<String, Object> _sessionResponse(String access, String refresh) => {
  'accessToken': access,
  'refreshToken': refresh,
  'expiresIn': 900,
  'user': {'id': 'user-1', 'email': 'alice@example.com'},
};

import 'dart:async';
import 'dart:convert';

import 'package:chat_app/core/failures/app_failure.dart';
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
  test('in-flight refresh cannot restore credentials after logout', () async {
    final store = MemorySessionStore()..session = _storedSession('old');
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final client = MockClient((request) {
      if (request.url.path.endsWith('/auth/logout')) {
        return Future.value(http.Response('', 204));
      }
      started.complete();
      return response.future;
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    final refreshing = api.refreshSession();
    final rejected = expectLater(refreshing, throwsA(isA<AppFailure>()));
    await started.future;
    await api.clearSession();
    response.complete(
      http.Response(jsonEncode(_sessionResponse('late', 'late-refresh')), 200),
    );
    await rejected;
    expect(store.session, isNull);
    await api.close();
    client.close();
  });

  test('old refresh rejection cannot clear a replacement account', () async {
    final store = MemorySessionStore()..session = _storedSession('old');
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final client = MockClient((request) {
      if (request.url.path.endsWith('/auth/logout')) {
        return Future.value(http.Response('', 204));
      }
      started.complete();
      return response.future;
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    final rejected = expectLater(
      api.refreshSession(),
      throwsA(isA<AppFailure>()),
    );
    await started.future;
    await api.saveSession(_storedSession('new'));
    response.complete(http.Response('{}', 401));
    await rejected;
    expect(store.session?.accessToken, 'new');
    await api.close();
    client.close();
  });

  test('delayed login response is cancelled by clearing the session', () async {
    final store = MemorySessionStore();
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final client = MockClient((request) {
      if (request.url.path.endsWith('/auth/logout')) {
        return Future.value(http.Response('', 204));
      }
      started.complete();
      return response.future;
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    final rejected = expectLater(
      BackendAuthDataSource(api)
          .login(email: 'alice@example.com', password: 'password'),
      throwsA(isA<AppFailure>()),
    );
    await started.future;
    await api.clearSession();
    response.complete(
      http.Response(jsonEncode(_sessionResponse('late-login', 'refresh')), 200),
    );
    await rejected;
    expect(store.session, isNull);
    await api.close();
    client.close();
  });

  test('concurrent refreshes share one rotating-token request', () async {
    final store = MemorySessionStore()..session = _storedSession('old');
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response(jsonEncode(_sessionResponse('new', 'refresh')), 200);
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    await Future.wait([
      api.refreshSession(),
      api.refreshSession(),
      api.refreshSession(),
    ]);
    expect(calls, 1);
    await api.close();
    client.close();
  });

  test('late 401 reuses an already refreshed access token', () async {
    final store = MemorySessionStore()..session = _storedSession('old');
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    var refreshes = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        refreshes++;
        return http.Response(
          jsonEncode(_sessionResponse('new', 'refresh')),
          200,
        );
      }
      if (request.headers['authorization'] == 'Bearer old') {
        started.complete();
        return delayed.future;
      }
      return http.Response('{}', 200);
    });
    final api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    final request = api.request('GET', '/users/me');
    await started.future;
    await api.refreshSession();
    delayed.complete(http.Response('{}', 401));
    await request;
    expect(refreshes, 1);
    await api.close();
    client.close();
  });
}

Map<String, Object> _sessionResponse(String access, String refresh) => {
  'accessToken': access,
  'refreshToken': refresh,
  'expiresIn': 900,
  'user': {'id': 'user-1', 'email': 'alice@example.com'},
};

ApiSession _storedSession(String token) => ApiSession(
  accessToken: token,
  refreshToken: 'refresh-$token',
  expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  userId: 'user-1',
);

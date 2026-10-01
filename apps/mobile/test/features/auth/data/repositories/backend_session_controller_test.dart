import 'dart:async';
import 'dart:convert';

import 'package:chat_app/core/network/api_session.dart';
import 'package:chat_app/core/network/rest_api_client.dart';
import 'package:chat_app/features/auth/data/datasources/backend_auth_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/backend_session_controller.dart';
import 'package:chat_app/features/conversations/data/repositories/api_conversations_repository.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../support/conversation_fakes.dart';

final class Store implements ApiSessionStore {
  ApiSession? value;
  @override
  Future<ApiSession?> read() async => value;
  @override
  Future<void> write(ApiSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  late Store store;
  late FakeRest rest;
  late FakeRealtime realtime;
  late ApiConversationsRepository conversations;
  late RestApiClient api;
  late BackendSessionController session;
  late http.Client client;
  late Future<http.Response> Function(http.Request) handle;

  setUp(() {
    store = Store();
    rest = FakeRest();
    realtime = FakeRealtime();
    conversations = ApiConversationsRepository(rest, realtime);
    handle = (request) async => http.Response(
      jsonEncode({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresIn': 900,
        'user': {'id': 'alice', 'email': 'alice@example.com'},
      }),
      200,
    );
    client = MockClient((request) => handle(request));
    api = RestApiClient(
      baseUrl: Uri.parse('https://api.example.com/v1'),
      httpClient: client,
      sessionStore: store,
    );
    session = BackendSessionController(
      BackendAuthDataSource(api),
      api,
      conversations,
    );
  });
  tearDown(() async {
    await session.close();
    await conversations.close();
    await realtime.controller.close();
    await api.close();
    client.close();
  });

  test(
    'login starts account repository; offline logout clears it immediately',
    () async {
      await session.login(email: 'alice@example.com', password: 'password');
      expect(session.currentUser?.id, 'alice');
      expect(realtime.connects, 1);
      handle = (_) async => throw http.ClientException('offline');
      await expectLater(session.logout(), throwsException);
      expect(session.currentUser, isNull);
      expect(store.value, isNull);
      expect(conversations.currentState.conversations.items, isEmpty);
      expect(
        conversations.currentState.connection,
        ConversationConnection.stopped,
      );
    },
  );

  test(
    'refresh rejection clears auth and disconnects account resources',
    () async {
      await session.login(email: 'alice@example.com', password: 'password');
      handle = (_) async => http.Response('{}', 401);
      final signedOut = session.watchAuthState().firstWhere(
        (user) => user == null,
      );
      await expectLater(api.refreshSession(), throwsException);
      await signedOut;
      expect(session.currentUser, isNull);
      expect(conversations.currentState.messages, isEmpty);
      expect(
        conversations.currentState.connection,
        ConversationConnection.stopped,
      );
    },
  );

  test('logout cancels a login response still in flight', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    handle = (request) {
      if (request.url.path.endsWith('/auth/logout')) {
        return Future.value(http.Response('', 204));
      }
      started.complete();
      return response.future;
    };
    final rejected = expectLater(
      session.login(email: 'alice@example.com', password: 'password'),
      throwsException,
    );
    await started.future;
    await session.logout();
    response.complete(
      http.Response(
        jsonEncode({
          'accessToken': 'late',
          'refreshToken': 'late',
          'expiresIn': 900,
          'user': {'id': 'alice'},
        }),
        200,
      ),
    );
    await rejected;
    expect(store.value, isNull);
    expect(session.currentUser, isNull);
    expect(realtime.connects, 0);
  });

  test(
    'socket network failure does not undo a successful REST login',
    () async {
      realtime.failConnect = true;
      await session.login(email: 'alice@example.com', password: 'password');
      expect(session.currentUser?.id, 'alice');
      expect(
        conversations.currentState.connection,
        ConversationConnection.offline,
      );
      expect(conversations.currentState.conversations.items, hasLength(1));
    },
  );

  test(
    'initialization validates a stored account through REST before connect',
    () async {
      store.value = ApiSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        userId: 'alice',
      );
      handle = (request) async {
        expect(request.url.path, '/v1/users/me');
        return http.Response('{"id":"alice","email":"alice@example.com"}', 200);
      };
      await session.initialize();
      expect(session.currentUser?.id, 'alice');
      expect(realtime.connects, 1);
    },
  );
}

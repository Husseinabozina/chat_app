import 'dart:async';
import 'dart:io';

import 'package:chat_app/core/failures/app_failure.dart';
import 'package:chat_app/core/network/api_session.dart';
import 'package:chat_app/core/network/rest_api_client.dart';
import 'package:chat_app/features/auth/data/datasources/backend_auth_data_source.dart';
import 'package:chat_app/features/auth/data/repositories/backend_session_controller.dart';
import 'package:chat_app/features/conversations/data/datasources/realtime_chat_data_source.dart';
import 'package:chat_app/features/conversations/data/datasources/rest_conversations_data_source.dart';
import 'package:chat_app/features/conversations/data/repositories/api_conversations_repository.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:chat_app/features/users/data/api_users_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _MemoryStore implements ApiSessionStore {
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

/// A real REST commit succeeds but its response is lost, as on a broken network.
class _ResponseLossClient extends http.BaseClient {
  final inner = http.Client();
  bool loseNextSendResponse = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner.send(request);
    if (loseNextSendResponse &&
        request.method == 'POST' &&
        request.url.path.endsWith('/messages')) {
      loseNextSendResponse = false;
      await response.stream.drain<void>();
      throw http.ClientException('Test response interruption');
    }
    return response;
  }

  @override
  void close() => inner.close();
}

class _Client {
  _Client(Uri origin) {
    api = RestApiClient(
      baseUrl: origin.resolve('/v1'),
      httpClient: httpClient,
      sessionStore: store,
    );
    socket = RealtimeChatDataSource(serverUrl: origin, api: api);
    repo = ApiConversationsRepository(RestConversationsDataSource(api), socket);
    account = BackendSessionController(BackendAuthDataSource(api), api, repo);
    users = ApiUsersRepository(api);
  }
  final store = _MemoryStore();
  final httpClient = _ResponseLossClient();
  late final RestApiClient api;
  late final RealtimeChatDataSource socket;
  late final ApiConversationsRepository repo;
  late final BackendSessionController account;
  late final ApiUsersRepository users;
  Future<void> close() async {
    await account.close();
    await repo.close();
    await socket.close();
    await api.close();
    httpClient.close();
  }
}

Future<void> _until(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 12));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Live backend state did not converge.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  const base = String.fromEnvironment('CHAT_INTEGRATION_URL');
  test(
    'two real backend accounts reconcile retries, read/edit/delete, history, reconnect and logout',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      final a = _Client(Uri.parse(base));
      final b = _Client(Uri.parse(base));
      addTearDown(() async {
        try {
          await a.account.logout();
        } catch (_) {}
        try {
          await b.account.logout();
        } catch (_) {}
        await a.close();
        await b.close();
      });
      final unique = DateTime.now().microsecondsSinceEpoch;
      await a.account.register(
        email: 'ui-a-$unique@example.com',
        password: 'checkpointPassword123',
      );
      await b.account.register(
        email: 'ui-b-$unique@example.com',
        password: 'checkpointPassword123',
      );
      final alice = a.account.currentUser!.id;
      final bob = b.account.currentUser!.id;
      await a.users.updateMe(
        username: 'a_$unique',
        displayName: 'Alice عربي',
        bio: 'First account',
      );
      await b.users.updateMe(
        username: 'b_$unique',
        displayName: 'Bob',
        bio: 'Second account',
      );
      expect((await a.users.search('b_$unique')).items.single.id, bob);
      expect((await a.users.getProfile(bob)).email, isNull);
      final chat = await a.repo.openDirect(bob);
      expect((await b.repo.openDirect(alice)).id, chat.id);
      await b.repo.loadMessages(chat.id);
      await _until(() => a.socket.isConnected && b.socket.isConnected);

      a.repo.pauseRealtime();
      a.httpClient.loseNextSendResponse = true;
      final pending = a.repo.prepareMessage(chat.id, 'مرحبا hello');
      await expectLater(
        a.repo.sendOutgoing(pending.clientMessageId),
        throwsA(isA<AppFailure>()),
      );
      expect(a.repo.currentState.outgoing.single.status, OutgoingStatus.failed);
      final sent = await a.repo.sendOutgoing(pending.clientMessageId);
      expect(sent.clientMessageId, pending.clientMessageId);
      expect(
        (await RestConversationsDataSource(a.api).listMessages(chat.id))
            .items
            .length,
        1,
      );
      await a.repo.resumeRealtime();
      await _until(
        () => b.repo.currentState.messages[chat.id]!.items.any(
          (m) => m.id == sent.id,
        ),
      );
      await b.repo.markRead(chat.id, sent.id);
      await _until(
        () => a.repo.currentState.readPointers.any(
          (p) => p.userId == bob && p.lastReadMessageId == sent.id,
        ),
      );
      await a.repo.editMessage(chat.id, sent.id, 'Edited عربي');
      await _until(
        () => b.repo.currentState.messages[chat.id]!.items.any(
          (m) => m.id == sent.id && m.text == 'Edited عربي',
        ),
      );

      b.repo.pauseRealtime();
      final second = await a.repo.sendOutgoing(
        a.repo.prepareMessage(chat.id, 'While you were away').clientMessageId,
      );
      await a.repo.deleteMessage(chat.id, sent.id);
      await b.repo.resumeRealtime();
      await _until(
        () =>
            b.repo.currentState.messages[chat.id]!.items.any(
              (m) => m.id == sent.id && m.isDeleted,
            ) &&
            b.repo.currentState.messages[chat.id]!.items.any(
              (m) => m.id == second.id,
            ),
      );
      a.repo.pauseRealtime();
      await b.repo.markRead(chat.id, second.id);
      await a.repo.resumeRealtime();
      expect(
        a.repo.currentState.readPointers.any(
          (p) => p.userId == bob && p.lastReadMessageId == second.id,
        ),
        isTrue,
      );
      await b.repo.setTyping(chat.id, typing: true);
      await _until(
        () => a.repo.currentState.typing.any((t) => t.userId == bob),
      );
      await b.repo.setTyping(chat.id, typing: false);
      await _until(() => a.repo.currentState.typing.isEmpty);
      for (var i = 0; i < 42; i++) {
        await a.repo.sendOutgoing(
          a.repo.prepareMessage(chat.id, 'History $i').clientMessageId,
        );
      }
      await b.repo.loadMessages(chat.id);
      expect(b.repo.currentState.messages[chat.id]!.hasMore, isTrue);
      await b.repo.loadMessages(chat.id, older: true);
      final history = b.repo.currentState.messages[chat.id]!.items;
      expect(history.length, 44);
      expect(history.map((m) => m.id).toSet().length, 44);

      final session = await a.api.currentSession();
      await a.api.saveSession(
        ApiSession(
          accessToken: session!.accessToken,
          refreshToken: session.refreshToken,
          expiresAt: DateTime.utc(2000),
          userId: session.userId,
        ),
      );
      expect((await a.users.getMe()).id, alice);
      expect(
        (await a.api.currentSession())!.refreshToken,
        isNot(session.refreshToken),
      );
      await a.account.logout();
      expect(a.account.currentUser, isNull);
      expect(a.repo.currentState.messages, isEmpty);
      expect(a.socket.isConnected, isFalse);
      expect(await a.api.currentSession(), isNull);
    },
    skip: base.isEmpty
        ? 'Set CHAT_INTEGRATION_URL for real PostgreSQL/REST/Socket.IO integration.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

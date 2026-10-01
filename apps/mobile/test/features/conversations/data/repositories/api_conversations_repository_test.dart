import 'dart:async';

import 'package:chat_app/core/failures/app_failure.dart';
import 'package:chat_app/features/conversations/data/repositories/api_conversations_repository.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation_event.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/conversation_fakes.dart';

void main() {
  late FakeRest rest;
  late FakeRealtime realtime;
  late ApiConversationsRepository repository;

  setUp(() async {
    rest = FakeRest();
    realtime = FakeRealtime();
    repository = ApiConversationsRepository(rest, realtime);
    await repository.start('alice');
  });
  tearDown(() async {
    await repository.close();
    await realtime.controller.close();
  });

  List<ConversationMessage> messages() =>
      repository.currentState.messages['chat']!.items;

  test('duplicates and stale creates cannot overwrite an edit', () {
    realtime.emit(changed('edit', message('m', text: 'edited', edit: 20)));
    realtime.emit(changed('old-create', message('m')));
    realtime.emit(
      changed('edit', message('m', text: 'duplicate corruption', edit: 25)),
    );
    expect(messages().single.text, 'edited');
  });

  test(
    'delete before create stays a tombstone across REST and events',
    () async {
      realtime.emit(
        MessageDeleted(
          eventId: 'delete',
          occurredAt: time(30),
          conversationId: 'chat',
          messageId: 'm',
          deletedAt: time(30),
        ),
      );
      rest.history.add(message('m'));
      await repository.loadMessages('chat');
      realtime.emit(
        changed('late-edit', message('m', text: 'older edit', edit: 20)),
      );
      expect(messages().single.text, isNull);
      expect(messages().single.deletedAt, time(30));
    },
  );

  test(
    'send retry preserves client id and merges socket-before-REST',
    () async {
      final outgoing = repository.prepareMessage('chat', 'hello');
      rest.failSend = true;
      await expectLater(
        repository.sendOutgoing(outgoing.clientMessageId),
        throwsA(isA<AppFailure>()),
      );
      expect(
        repository.currentState.outgoing.single.status,
        OutgoingStatus.failed,
      );
      rest.failSend = false;
      final persisted = await repository.sendOutgoing(outgoing.clientMessageId);
      realtime.emit(changed('socket-copy', persisted));
      await repository.resynchronize();
      expect(rest.sentIds, [
        outgoing.clientMessageId,
        outgoing.clientMessageId,
      ]);
      expect(repository.currentState.outgoing, isEmpty);
      expect(messages(), hasLength(1));
    },
  );

  test(
    'socket confirmation survives a failed duplicate REST request',
    () async {
      final outgoing = repository.prepareMessage('chat', 'hello');
      realtime.emit(
        changed('confirmed', message('m', clientId: outgoing.clientMessageId)),
      );
      final persisted = await repository.sendOutgoing(outgoing.clientMessageId);
      expect(persisted.id, 'm');
      expect(rest.sentIds, isEmpty);
      expect(repository.currentState.outgoing, isEmpty);
    },
  );

  test(
    'reconnect buffers mutations while stale REST history is pending',
    () async {
      rest.history.add(message('m'));
      await repository.loadMessages('chat');
      final gate = Completer<CursorPage<ConversationMessage>>();
      rest.historyGate = gate;
      final queried = repository.watchState().firstWhere(
        (s) => s.connection == ConversationConnection.syncing,
      );
      realtime.emit(
        RealtimeReady(
          eventId: 'reconnect',
          occurredAt: time(0),
          isReconnect: true,
        ),
      );
      await queried;
      // Wait for the query to consume the gate using a deterministic signal.
      while (rest.historyGate != null) {
        await Future<void>.value();
      }
      realtime.emit(
        changed('edit-during-resync', message('m', text: 'new', edit: 20)),
      );
      gate.complete(CursorPage(items: [message('m')], hasMore: false));
      await repository.resynchronize();
      expect(messages().single.text, 'new');
      expect(repository.currentState.connection, ConversationConnection.live);
    },
  );

  test(
    'ambiguous summary events refetch counts instead of regressing them',
    () async {
      rest.unread = 7;
      final gate = Completer<CursorPage<ConversationSummary>>();
      rest.listGate = gate;
      final calls = rest.listCalls;
      final syncing = repository.resynchronize();
      realtime.emit(
        ConversationChanged(
          eventId: 'stale-summary',
          occurredAt: time(0),
          conversation: summary(1),
        ),
      );
      gate.complete(CursorPage(items: [summary(3)], hasMore: false));
      await syncing;
      expect(rest.listCalls, calls + 2);
      expect(repository.currentState.conversations.items.single.unreadCount, 7);
    },
  );

  test('read advancement uses canonical order even if timestamp is newer', () {
    realtime.emit(changed('first', message('a', created: 1)));
    realtime.emit(changed('second', message('b', created: 2)));
    realtime.emit(
      ReadChanged(
        eventId: 'new-read',
        occurredAt: time(10),
        pointer: pointer('b', 10),
      ),
    );
    realtime.emit(
      ReadChanged(
        eventId: 'old-read',
        occurredAt: time(20),
        pointer: pointer('a', 20),
      ),
    );
    expect(repository.currentState.readPointers.single.lastReadMessageId, 'b');
  });

  test(
    'history pagination sorts and reconnect refetches all loaded pages',
    () async {
      rest.pageSize = 1;
      rest.history.addAll([
        message('a', created: 1),
        message('b', created: 2),
        message('c', created: 3),
      ]);
      await repository.loadMessages('chat');
      await repository.loadMessages('chat', older: true);
      await repository.loadMessages('chat', older: true);
      expect(messages().map((m) => m.id), ['a', 'b', 'c']);
      rest.history[0] = message(
        'a',
        text: 'offline edit',
        created: 1,
        edit: 20,
      );
      await repository.resynchronize();
      expect(messages().first.text, 'offline edit');
      expect(repository.currentState.messages['chat']!.hasMore, false);
    },
  );

  test('logout drops late REST results and clears all account state', () async {
    final gate = Completer<CursorPage<ConversationMessage>>();
    rest.historyGate = gate;
    final loading = repository.loadMessages('chat');
    final rejected = expectLater(loading, throwsA(isA<AppFailure>()));
    await repository.stop();
    gate.complete(CursorPage(items: [message('private')], hasMore: false));
    await rejected;
    expect(repository.currentState.messages, isEmpty);
    expect(repository.currentState.conversations.items, isEmpty);
    realtime.emit(changed('after-logout', message('private')));
    expect(repository.currentState.messages, isEmpty);
  });

  test('typing expires locally and stop wins over an older start', () async {
    await repository.close();
    var clock = DateTime.utc(2026, 10, 1);
    repository = ApiConversationsRepository(rest, realtime, now: () => clock);
    await repository.start('alice');
    final now = clock;
    realtime.emit(
      TypingChanged(
        eventId: 'typing-start',
        occurredAt: now,
        conversationId: 'chat',
        userId: 'bob',
        isTyping: true,
        expiresAt: now.add(const Duration(milliseconds: 50)),
      ),
    );
    expect(repository.currentState.typing, hasLength(1));
    clock = now.add(const Duration(milliseconds: 51));
    await repository
        .watchState()
        .firstWhere((state) => state.typing.isEmpty)
        .timeout(const Duration(seconds: 3));
    realtime.emit(
      TypingChanged(
        eventId: 'typing-stop',
        occurredAt: now.add(const Duration(seconds: 1)),
        conversationId: 'chat',
        userId: 'bob',
        isTyping: false,
      ),
    );
    realtime.emit(
      TypingChanged(
        eventId: 'late-start',
        occurredAt: now,
        conversationId: 'chat',
        userId: 'bob',
        isTyping: true,
        expiresAt: now.add(const Duration(seconds: 7)),
      ),
    );
    expect(repository.currentState.typing, isEmpty);
  });

  test('typing start commands are throttled and stop is immediate', () async {
    await Future.wait([
      repository.setTyping('chat', typing: true),
      repository.setTyping('chat', typing: true),
    ]);
    await repository.setTyping('chat', typing: false);
    expect(realtime.typingCommands, [true, false]);
  });

  test(
    'background disconnect keeps REST state and foreground resyncs',
    () async {
      rest.history.add(message('m'));
      await repository.loadMessages('chat');
      repository.pauseRealtime();
      expect(
        repository.currentState.connection,
        ConversationConnection.offline,
      );
      expect(messages().single.id, 'm');
      rest.history[0] = message('m', deletion: 30);
      await repository.resumeRealtime();
      expect(messages().single.deletedAt, time(30));
      expect(repository.currentState.connection, ConversationConnection.live);
    },
  );
  test(
    'read snapshot restores a missed receipt outside the loaded history',
    () async {
      rest.history.add(message('recent', created: 100));
      await repository.loadMessages('chat');
      rest.reads.add(
        ReadPointer(
          conversationId: 'chat',
          userId: 'bob',
          lastReadMessageId: 'outside-window',
          lastReadAt: time(150),
          lastReadMessageCreatedAt: time(90),
        ),
      );
      await repository.resynchronize();
      expect(
        repository.currentState.readPointers.single.lastReadMessageId,
        'outside-window',
      );
      realtime.emit(
        ReadChanged(
          eventId: 'late-older-read',
          occurredAt: time(200),
          pointer: ReadPointer(
            conversationId: 'chat',
            userId: 'bob',
            lastReadMessageId: 'old',
            lastReadAt: time(200),
            lastReadMessageCreatedAt: time(80),
          ),
        ),
      );
      expect(
        repository.currentState.readPointers.single.lastReadMessageId,
        'outside-window',
      );
    },
  );

  test(
    'REST-confirmed deletion stays successful when summary refresh fails',
    () async {
      rest.history.add(message('m'));
      await repository.loadMessages('chat');
      rest.failList = true;
      await repository.deleteMessage('chat', 'm');
      expect(messages().single.isDeleted, true);
      expect(messages().single.text, isNull);
      // No fabricated deletedAt is exposed for a 204 response.
      expect(messages().single.deletedAt, isNull);
    },
  );
  test(
    'socket-before-REST merges once and confirms an interrupted response',
    () async {
      final outgoing = repository.prepareMessage('chat', 'hello');
      final gate = Completer<ConversationMessage>();
      rest.sendGate = gate;
      final sending = repository.sendOutgoing(outgoing.clientMessageId);
      expect(
        identical(sending, repository.sendOutgoing(outgoing.clientMessageId)),
        true,
      );
      realtime.emit(
        changed(
          'socket-first',
          message(
            'persisted',
            text: 'hello',
            clientId: outgoing.clientMessageId,
          ),
        ),
      );
      gate.completeError(const AppFailure(kind: FailureKind.network));
      final canonical = await sending;
      expect(canonical.id, 'persisted');
      expect(repository.currentState.outgoing, isEmpty);
      expect(messages(), hasLength(1));
      expect(rest.sentIds, [outgoing.clientMessageId]);
    },
  );
  test(
    'equal edit timestamps with conflicting text resolve through REST',
    () async {
      final canonical = message('m', text: 'current', edit: 20);
      rest.history.add(canonical);
      realtime.emit(changed('latest', canonical));
      realtime.emit(
        changed('tied-old-edit', message('m', text: 'old', edit: 20)),
      );
      await repository.resynchronize();
      expect(messages().single.text, 'current');
    },
  );
}

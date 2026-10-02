import 'dart:async';

import 'package:chat_app/core/failures/app_failure.dart';
import 'package:chat_app/features/conversations/data/datasources/conversation_sources.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation_event.dart';

final class FakeRest implements ConversationsRestSource {
  final history = <ConversationMessage>[];
  int unread = 0;
  final reads = <ReadPointer>[];
  int listCalls = 0;
  int historyCalls = 0;
  bool failSend = false;
  bool failList = false;
  final sentIds = <String>[];
  final readIds = <String>[];
  String? lastReply;
  Completer<ConversationMessage>? sendGate;
  Completer<CursorPage<ConversationSummary>>? listGate;
  Completer<CursorPage<ConversationMessage>>? historyGate;
  int pageSize = 40;

  @override
  Future<CursorPage<ConversationSummary>> listConversations({
    String? cursor,
    int limit = 20,
  }) async {
    listCalls++;
    if (failList) throw const AppFailure(kind: FailureKind.network);
    if (listGate != null) {
      final gate = listGate!;
      listGate = null;
      return gate.future;
    }
    return summaryPage();
  }

  CursorPage<ConversationSummary> summaryPage() =>
      CursorPage(items: [summary(unread)], hasMore: false);

  @override
  Future<List<ReadPointer>> getReadState(String conversationId) async => reads;

  @override
  Future<ConversationSummary> openDirect(String userId) async =>
      summary(unread);

  @override
  Future<CursorPage<ConversationMessage>> listMessages(
    String conversationId, {
    String? before,
    int limit = 40,
  }) async {
    historyCalls++;
    if (historyGate != null) {
      final gate = historyGate!;
      historyGate = null;
      return gate.future;
    }
    final start = before == null ? 0 : int.parse(before);
    final slice = history.reversed.skip(start).take(pageSize).toList();
    final next = start + slice.length;
    return CursorPage(
      items: slice,
      hasMore: next < history.length,
      nextCursor: next < history.length ? '$next' : null,
    );
  }

  @override
  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text, {
    String? clientMessageId,
    String? replyToMessageId,
    String? imageMediaId,
  }) async {
    sentIds.add(clientMessageId!);
    lastReply = replyToMessageId;
    if (sendGate != null) return sendGate!.future;
    if (failSend) throw const AppFailure(kind: FailureKind.network);
    final value = message('sent', text: text, clientId: clientMessageId);
    history.add(value);
    return value;
  }

  @override
  Future<ConversationMessage> editMessage(
    String messageId,
    String text,
  ) async => message(messageId, text: text, edit: 20);

  @override
  Future<void> deleteMessage(String messageId) async {
    history.removeWhere((m) => m.id == messageId);
    history.add(message(messageId, deletion: 30));
  }

  @override
  Future<ReadPointer> markRead(
    String conversationId,
    String upToMessageId,
    String userId,
  ) async {
    readIds.add(upToMessageId);
    return pointer(upToMessageId, 40, userId: userId);
  }
}

final class FakeRealtime implements ConversationsRealtimeSource {
  final controller = StreamController<ConversationEvent>.broadcast(sync: true);
  int connects = 0;
  int disconnects = 0;
  bool failConnect = false;
  final typingCommands = <bool>[];
  @override
  Stream<ConversationEvent> get events => controller.stream;
  @override
  Future<void> connect() async {
    connects++;
    if (failConnect) throw const AppFailure(kind: FailureKind.network);
    emit(
      RealtimeReady(
        eventId: 'ready-$connects',
        occurredAt: time(0),
        isReconnect: connects > 1,
      ),
    );
  }

  @override
  void disconnect() {
    disconnects++;
  }

  @override
  Future<void> setTyping(String conversationId, {required bool typing}) async {
    typingCommands.add(typing);
  }

  void emit(ConversationEvent event) => controller.add(event);
}

DateTime time(int seconds) =>
    DateTime.utc(2026, 10, 1).add(Duration(seconds: seconds));
ConversationSummary summary(int unread) => ConversationSummary(
  id: 'chat',
  otherUser: const ConversationParticipant(id: 'bob'),
  unreadCount: unread,
  updatedAt: time(0),
);
ConversationMessage message(
  String id, {
  String? text = 'original',
  String? clientId,
  int created = 0,
  int? edit,
  int? deletion,
}) => ConversationMessage(
  id: id,
  clientMessageId: clientId ?? 'client-$id',
  conversationId: 'chat',
  senderId: 'alice',
  createdAt: time(created),
  text: deletion == null ? text : null,
  editedAt: edit == null ? null : time(edit),
  deletedAt: deletion == null ? null : time(deletion),
);
ReadPointer pointer(String id, int at, {String userId = 'bob'}) => ReadPointer(
  conversationId: 'chat',
  userId: userId,
  lastReadMessageId: id,
  lastReadAt: time(at),
);
MessageChanged changed(String eventId, ConversationMessage value) =>
    MessageChanged(eventId: eventId, occurredAt: time(0), message: value);

import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_event.dart';

abstract interface class ConversationsRestSource {
  Future<CursorPage<ConversationSummary>> listConversations({
    String? cursor,
    int limit = 20,
  });
  Future<List<ReadPointer>> getReadState(String conversationId);
  Future<ConversationSummary> openDirect(String userId);
  Future<CursorPage<ConversationMessage>> listMessages(
    String conversationId, {
    String? before,
    int limit = 40,
  });
  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text, {
    String? clientMessageId,
    String? replyToMessageId,
  });
  Future<ConversationMessage> editMessage(String messageId, String text);
  Future<void> deleteMessage(String messageId);
  Future<ReadPointer> markRead(
    String conversationId,
    String upToMessageId,
    String userId,
  );
}

abstract interface class ConversationsRealtimeSource {
  Stream<ConversationEvent> get events;
  Future<void> connect();
  void disconnect();
  Future<void> setTyping(String conversationId, {required bool typing});
}

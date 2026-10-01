import '../../../../core/failures/app_failure.dart';
import '../entities/conversation.dart';

enum ConversationConnection { stopped, connecting, syncing, live, offline }

enum OutgoingStatus { pending, sending, failed }

final class OutgoingMessage {
  const OutgoingMessage({
    required this.clientMessageId,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.status,
    this.replyToMessageId,
  });
  final String clientMessageId;
  final String conversationId;
  final String senderId;
  final String text;
  final String? replyToMessageId;
  final OutgoingStatus status;

  OutgoingMessage withStatus(OutgoingStatus status) => OutgoingMessage(
    clientMessageId: clientMessageId,
    conversationId: conversationId,
    senderId: senderId,
    text: text,
    replyToMessageId: replyToMessageId,
    status: status,
  );
}

final class ConversationsState {
  const ConversationsState({
    required this.connection,
    required this.conversations,
    required this.messages,
    required this.outgoing,
    required this.readPointers,
    required this.typing,
    this.failure,
  });
  final ConversationConnection connection;
  final CursorPage<ConversationSummary> conversations;
  final Map<String, CursorPage<ConversationMessage>> messages;
  final List<OutgoingMessage> outgoing;
  final List<ReadPointer> readPointers;
  final List<TypingIndicator> typing;
  final AppFailure? failure;
}

final class TypingIndicator {
  const TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.expiresAt,
  });
  final String conversationId;
  final String userId;
  final DateTime expiresAt;
}

/// Presentation consumes snapshots and durable commands without socket types.
abstract interface class ConversationsRepository {
  ConversationsState get currentState;
  Stream<ConversationsState> watchState();
  Future<void> resynchronize();
  Future<void> loadMoreConversations();
  Future<ConversationSummary> openDirect(String userId);
  Future<void> loadMessages(String conversationId, {bool older = false});
  OutgoingMessage prepareMessage(
    String conversationId,
    String text, {
    String? replyToMessageId,
  });
  Future<ConversationMessage> sendOutgoing(String clientMessageId);
  Future<ConversationMessage> editMessage(
    String conversationId,
    String messageId,
    String text,
  );
  Future<void> deleteMessage(String conversationId, String messageId);
  Future<ReadPointer> markRead(String conversationId, String messageId);
  Future<void> setTyping(String conversationId, {required bool typing});
}

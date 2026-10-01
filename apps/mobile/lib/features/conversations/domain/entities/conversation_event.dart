import 'conversation.dart';

sealed class ConversationEvent {
  const ConversationEvent({required this.eventId, required this.occurredAt});

  final String eventId;
  final DateTime occurredAt;
}

final class RealtimeReady extends ConversationEvent {
  const RealtimeReady({
    required super.eventId,
    required super.occurredAt,
    required this.isReconnect,
  });

  final bool isReconnect;
}

final class MessageChanged extends ConversationEvent {
  const MessageChanged({
    required super.eventId,
    required super.occurredAt,
    required this.message,
  });

  final ConversationMessage message;
}

final class MessageDeleted extends ConversationEvent {
  const MessageDeleted({
    required super.eventId,
    required super.occurredAt,
    required this.conversationId,
    required this.messageId,
    required this.deletedAt,
  });

  final String conversationId;
  final String messageId;
  final DateTime deletedAt;
}

final class ConversationChanged extends ConversationEvent {
  const ConversationChanged({
    required super.eventId,
    required super.occurredAt,
    required this.conversation,
  });

  final ConversationSummary conversation;
}

final class ReadChanged extends ConversationEvent {
  const ReadChanged({
    required super.eventId,
    required super.occurredAt,
    required this.pointer,
  });

  final ReadPointer pointer;
}

final class TypingChanged extends ConversationEvent {
  const TypingChanged({
    required super.eventId,
    required super.occurredAt,
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    this.expiresAt,
  });

  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime? expiresAt;
}

final class RealtimeDisconnected extends ConversationEvent {
  const RealtimeDisconnected({
    required super.eventId,
    required super.occurredAt,
  });
}

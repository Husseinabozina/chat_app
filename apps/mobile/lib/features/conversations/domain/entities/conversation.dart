final class ConversationParticipant {
  const ConversationParticipant({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
}

final class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.clientMessageId,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.text,
    this.replyToMessageId,
    this.editedAt,
    this.deletedAt,
  });

  final String id;
  final String clientMessageId;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? replyToMessageId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
}

final class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherUser,
    required this.unreadCount,
    required this.updatedAt,
    this.lastMessage,
  });

  final String id;
  final ConversationParticipant otherUser;
  final ConversationLastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
}

final class ConversationLastMessage {
  const ConversationLastMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.text,
    this.deletedAt,
  });

  final String id;
  final String senderId;
  final String type;
  final String? text;
  final DateTime createdAt;
  final DateTime? deletedAt;
}

final class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}

final class ReadPointer {
  const ReadPointer({
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
    required this.lastReadAt,
  });

  final String conversationId;
  final String userId;
  final String lastReadMessageId;
  final DateTime lastReadAt;
}

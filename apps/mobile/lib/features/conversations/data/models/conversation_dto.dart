import '../../domain/entities/conversation.dart';

Map<String, dynamic> asObject(Object? value) => value as Map<String, dynamic>;

DateTime asDate(Object? value) => DateTime.parse(value as String).toUtc();

DateTime? asNullableDate(Object? value) => value == null ? null : asDate(value);

ConversationMessage messageFromJson(Map<String, dynamic> json) =>
    ConversationMessage(
      id: json['id'] as String,
      clientMessageId: json['clientMessageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
      createdAt: asDate(json['createdAt']),
      editedAt: asNullableDate(json['editedAt']),
      deletedAt: asNullableDate(json['deletedAt']),
    );

ConversationSummary conversationFromJson(Map<String, dynamic> json) {
  final otherUser = asObject(json['otherUser']);
  final lastMessage = json['lastMessage'];

  return ConversationSummary(
    id: json['id'] as String,
    otherUser: ConversationParticipant(
      id: otherUser['id'] as String,
      username: otherUser['username'] as String?,
      displayName: otherUser['displayName'] as String?,
      avatarUrl: otherUser['avatarUrl'] as String?,
    ),
    unreadCount: (json['unreadCount'] as num).toInt(),
    updatedAt: asDate(json['updatedAt']),
    lastMessage: lastMessage == null
        ? null
        : _summaryMessage(asObject(lastMessage)),
  );
}

ConversationLastMessage _summaryMessage(Map<String, dynamic> json) =>
    ConversationLastMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      type: json['type'] as String,
      text: json['text'] as String?,
      createdAt: asDate(json['createdAt']),
      deletedAt: asNullableDate(json['deletedAt']),
    );

CursorPage<T> pageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) parse,
) => CursorPage<T>(
  items: (json['items'] as List<dynamic>)
      .map((item) => parse(asObject(item)))
      .toList(growable: false),
  hasMore: json['hasMore'] as bool,
  nextCursor: json['nextCursor'] as String?,
);

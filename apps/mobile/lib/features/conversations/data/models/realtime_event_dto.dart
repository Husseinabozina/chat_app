import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_event.dart';
import 'conversation_dto.dart';

ConversationEvent eventFromEnvelope(String eventName, Object? raw) {
  final envelope = asObject(raw);
  if (envelope['protocolVersion'] != 1 || envelope['type'] != eventName) {
    throw const FormatException('Unsupported realtime event envelope.');
  }

  final id = envelope['eventId'] as String;
  final occurredAt = asDate(envelope['occurredAt']);
  final data = asObject(envelope['data']);

  return switch (eventName) {
    'message.created' || 'message.updated' => MessageChanged(
      eventId: id,
      occurredAt: occurredAt,
      message: messageFromJson(asObject(data['message'])),
    ),
    'message.deleted' => MessageDeleted(
      eventId: id,
      occurredAt: occurredAt,
      conversationId: data['conversationId'] as String,
      messageId: data['messageId'] as String,
      deletedAt: asDate(data['deletedAt']),
    ),
    'conversation.updated' => ConversationChanged(
      eventId: id,
      occurredAt: occurredAt,
      conversation: conversationFromJson(asObject(data['conversation'])),
    ),
    'read.updated' => ReadChanged(
      eventId: id,
      occurredAt: occurredAt,
      pointer: ReadPointer(
        conversationId: data['conversationId'] as String,
        userId: data['userId'] as String,
        lastReadMessageId: data['lastReadMessageId'] as String,
        lastReadAt: asDate(data['lastReadAt']),
        lastReadMessageCreatedAt: asNullableDate(
          data['lastReadMessageCreatedAt'],
        ),
      ),
    ),
    'typing.started' || 'typing.stopped' => TypingChanged(
      eventId: id,
      occurredAt: occurredAt,
      conversationId: data['conversationId'] as String,
      userId: data['userId'] as String,
      isTyping: eventName == 'typing.started',
      expiresAt: asNullableDate(data['expiresAt']),
    ),
    _ => throw FormatException('Unknown realtime event: $eventName'),
  };
}
